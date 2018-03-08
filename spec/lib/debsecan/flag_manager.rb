# frozen_string_literal: true

require 'spec_helper'
require 'timecop'
RSpec.describe Debsecan::FlagManager do
  let(:user1) { double('user1') }
  let(:user2) { double('user2') }
  let(:ticket) { double('ticket') }
  let(:dummy_time) { Time.local(2017) }
  let(:yaml) do
    {
      whitelist: whitelist_entries,
      allowed: allowed_entries
    }
  end

  let(:whitelist_entries) do
    {
      'FAKE-1' => { by: user1, on: 1, ticket: 'TRY-1' },
      'FAKE-2' => { by: user2, on: 1, ticket: 'TRY-2' }
    }
  end

  let(:allowed_entries) do
    {
      'FAKE-3' => { by: user1, on: dummy_time, ticket: 'TRY-3' }
    }
  end

  before do
    Timecop.freeze(Time.local(2017))
    allow(Psych).to receive(:load_file).and_return(yaml)
  end

  after do
    Timecop.return
  end

  subject { Debsecan::FlagManager.new(double('file'), user1) }

  describe '.add' do
    shared_examples_for 'inserts items into a specific flag' do |flag|
      it "adds FAKE-4 to @flags[#{flag}]" do
        expect(subject.flags[flag]).not_to include('FAKE-4')
        expect(subject.add(flag, 'FAKE-4', ticket)).to be_truthy
        expect(subject.flags[flag]['FAKE-4']).to eq(
          by: user1, on: dummy_time, ticket: ticket
        )
      end
    end

    it_behaves_like 'inserts items into a specific flag', :whitelist
    it_behaves_like 'inserts items into a specific flag', :allowed

    it 'returns false if the given id already exists for the given flag' do
      expect(subject.add(:whitelist, 'FAKE-1', ticket)).to eq(false)
    end
  end

  describe '.remove' do
    let(:flag) { :whitelist }
    let(:id) { 'FAKE-1' }
    it 'removes the specified flag if it exists' do
      expect(subject.flags[flag]).to include(id)
      subject.remove(flag, id)
      expect(subject.flags[flag]).not_to include(id)
    end

    it 'returns false if the specific id does not exist for the given flag' do
      expect(subject.remove(flag, 'FAKE-5')).to eq(false)
    end
  end

  describe '.move' do
    let(:src) { :whitelist }
    let(:dst) { :allowed }
    let(:id) { 'FAKE-1' }

    it 'moves the specified item between two flags' do
      expect(subject.flags[src]).to include(id)
      expect(subject.flags[dst]).not_to include(id)
      subject.move(src, dst, id)
      expect(subject.flags[src]).not_to include(id)
      expect(subject.flags[dst]).to include(id)
    end
  end
end

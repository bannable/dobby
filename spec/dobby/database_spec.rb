# frozen_string_literal: true

require 'spec_helper'
RSpec.describe Dobby::Database do
  let(:strategy) { double('strategy') }
  let(:response) { double('response') }
  let(:defects) do
    { 'fake' => [
      instance_double('Dobby::Defect'),
      instance_double('Dobby::Defect')
    ] }
  end

  before(:each) do
    allow(response).to receive(:changed?) { true }
    allow(response).to receive(:content) { defects }
    allow(strategy).to receive(:update) { response }
  end

  subject { Dobby::Database.new(strategy) }

  context '#initialize' do
    it 'has the expected number of packages' do
      expect(subject.count).to eq(1)
    end

    it 'has the expected number of defects for each package' do
      expect(subject['fake'].count).to eq(2)
    end

    it 'errors if the strategy returns no content' do
      allow(response).to receive(:changed?) { false }
      expect { subject }.to raise_error(Dobby::Database::InitializationError)
    end
  end
end

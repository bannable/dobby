# frozen_string_literal: true

RSpec.describe Debsecan::Package do
  let(:package_args) do
    {
      name:    'locales-all',
      version: '2.13-38+deb7u10',
      release: 'test'
    }
  end

  let(:newer_package_args) do
    {
      name:    'locales-all',
      version: '2.13-38+deb7u11',
      release: 'test'
    }
  end

  let(:package) { Debsecan::Package.new(package_args) }
  let(:newer_package) { Debsecan::Package.new(newer_package_args) }

  subject { package }

  context 'with all required fields' do
    it 'initializes sanely' do
      expect(subject.name).to eq('locales-all')
      expect(subject.version).to eq('2.13-38+deb7u10')
      expect(subject.release).to eq('test')
    end

    it 'has a string representation' do
      expect(subject.to_s).to eq('locales-all 2.13-38+deb7u10')
    end
  end

  context 'with missing fields' do
    shared_examples_for 'missing a required field raises an error' do |field|
      it "raises FieldRequiredError when #{field} is missing" do
        package_args[field] = nil
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Debsecan::Package::FieldRequiredError)
          expect(error.field).to eq(field.to_s)
          expect(error.message).to eq("Missing required field '#{field}'")
        end
      end
    end

    include_examples 'missing a required field raises an error', :name
    include_examples 'missing a required field raises an error', :version
    include_examples 'missing a required field raises an error', :release
  end

  context 'package version comparisons' do
    let(:old) { package }
    let(:new) { newer_package }

    # Package has a custom ==() method, and the below spec ensures that
    # it behaves as expected. Rubocop complains about the self comparison,
    # so Lint/UselessComparison is disabled for this spec.
    # rubocop:disable Lint/UselessComparison
    it 'old == old should eq true' do
      expect(old == old).to  eq(true)
    end
    # rubocop:enable Lint/UselessComparison

    # rubocop:disable Style/CaseEquality
    it 'old === new should eq true' do
      expect(old === new).to eq(true)
    end
    # rubocop:enable Style/CaseEquality

    it 'old <= new should eq true' do
      expect(old <= new).to  eq(true)
    end

    it 'old < new should eq true' do
      expect(old < new).to   eq(true)
    end

    it 'new >= old should eq true' do
      expect(new >= old).to  eq(true)
    end

    it 'new > old should eq true' do
      expect(new > old).to   eq(true)
    end

    it 'old == new should eq false' do
      expect(old == new).to  eq(false)
    end

    it 'old >= new should eq false' do
      expect(old >= new).to  eq(false)
    end

    it 'old > new should eq false' do
      expect(old > new).to   eq(false)
    end

    it 'new <= old should eq false' do
      expect(new <= old).to  eq(false)
    end

    it 'new < old should eq false' do
      expect(new < old).to   eq(false)
    end
  end
end

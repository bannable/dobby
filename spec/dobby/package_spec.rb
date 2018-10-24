# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dobby::Package do
  let(:package_args) do
    {
      name:    'locales-all',
      version: package_version,
      target:  target_version,
      release: 'test'
    }
  end

  let(:newer_package_args) do
    {
      name:    'locales-all',
      version: newer_version,
      release: new_rel
    }
  end

  let(:package_version) { '2.13-38+deb7u10' }
  let(:newer_version) { '2.13-38+deb7u12' }
  let(:target_version) { package_version }
  let(:new_rel) { 'test' }

  let(:package) { Dobby::Package.new(package_args) }
  let(:newer_package) { Dobby::Package.new(newer_package_args) }

  subject { package }

  context 'with all required fields' do
    it 'initializes sanely' do
      expect(subject.name).to eq('locales-all')
      expect(subject.version).to eq('2.13-38+deb7u10')
      expect(subject.release).to eq('test')
    end
  end

  describe '#apt_name' do
    context 'when multiarch is not same' do
      it 'has a string representation' do
        expect(subject.to_s).to eq('locales-all 2.13-38+deb7u10')
      end

      it 'does not include the arch' do
        expect(subject.apt_name).to eq('locales-all')
      end
    end

    context 'when multiarch is same' do
      before(:each) do
        package_args[:multiarch] = 'same'
        package_args[:arch] = 'foobar'
      end

      it 'raises a FieldRequiredError if arch is nil' do
        package_args[:arch] = nil
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Dobby::Package::FieldRequiredError)
          expect(error.field).to eq('arch')
          expect(error.message).to eq("Missing required field 'arch'")
        end
      end

      it 'includes the arch' do
        expect(subject.apt_name).to eq('locales-all:foobar')
      end

      it 'has a string representation' do
        expect(subject.to_s).to eq('locales-all:foobar 2.13-38+deb7u10')
      end
    end
  end

  describe '#filtered?' do
    subject { package.filtered?(newer_package, filter) }

    context ':default filter' do
      let(:filter) { :default }

      context 'the package and other releases match' do
        context 'version is less than other version' do
          it { is_expected.to be false }
        end

        context 'version is equal to other version' do
          let(:package_version) { newer_version }
          it { is_expected.to be true }
        end
        context 'version is greater than other version' do
          let(:package_version) { '3' }
          it { is_expected.to be true }
        end
      end

      context 'the package and other releases do not match' do
        let(:new_rel) { 'foo' }

        it { is_expected.to be true }
      end
    end

    context ':target filter' do
      let(:filter) { :target }
      context 'the package and other releases do not match' do
        let(:new_rel) { 'foo' }
        it { is_expected.to be true }
      end

      context 'package and other releases match' do
        context 'target is at least the fix version' do
          let(:target_version) { newer_version }
          it { is_expected.to be true }
        end

        context 'target is not at least the fix version' do
          it { is_expected.to be false }
        end

        context 'version is >= fix version' do
          let(:package_version) { newer_version }
          it { is_expected.to be true }
        end
      end
    end
  end

  context 'with missing fields' do
    shared_examples_for 'missing a required field raises an error' do |field|
      it "raises FieldRequiredError when #{field} is nil" do
        package_args[field] = nil
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(Dobby::Package::FieldRequiredError)
          expect(error.field).to eq(field.to_s)
          expect(error.message).to eq("Missing required field '#{field}'")
        end
      end

      it "raises ArgumentError when #{field} is missing" do
        package_args.delete(field)
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(ArgumentError)
          expect(error.message).to eq("missing keyword: #{field}")
        end
      end
    end

    include_examples 'missing a required field raises an error', :name
    include_examples 'missing a required field raises an error', :version
    include_examples 'missing a required field raises an error', :release
  end

  describe '#target_at_least?' do
    let(:target) { '2' }
    let(:new_ver) { '2' }
    let(:old) { Dobby::Package.new(name: 'foo', version: '1', release: 'test', target: target) }
    let(:new) { Dobby::Package.new(name: 'foo', version: new_ver, release: 'test') }

    shared_examples_for 'targets at least' do |first, second|
      it "returns #{first} for old->new" do
        expect(old.target_at_least?(new)).to be first
      end

      it "returns #{second} for new->old" do
        expect(new.target_at_least?(old)).to be second
      end
    end

    context 'target version matches new version' do
      include_examples 'targets at least', true, false
    end

    context 'target version is less than new version' do
      let(:new_ver) { '3' }

      include_examples 'targets at least', false, false
    end

    context 'target version is greater than new version' do
      let(:target) { '3' }

      include_examples 'targets at least', true, false
    end

    context 'target version is empty' do
      let(:target) { '' }

      include_examples 'targets at least', false, false
    end

    context 'target version is nil' do
      let(:target) { nil }

      include_examples 'targets at least', false, false
    end
  end

  describe 'package version comparisons' do
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

    it 'old === new should eq true' do
      expect(old === new).to eq(true)
    end

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

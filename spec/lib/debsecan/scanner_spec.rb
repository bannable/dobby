# frozen_string_literal: true

RSpec.describe Debsecan::Scanner do
  let(:package) { double('Package', name: 'foo', version: 1, target: target, source: nil) }
  let(:package_source) { double('Package', name: 'bar', version: 1, target: target, source: 'baz') }
  let(:packages) { [package] }

  let(:db) { double('Debsecan::Database') }
  let(:defect) { double('Debsecan::Defect', identifier: 'one', fix_available?: true) }

  let(:scanner) { Debsecan::Scanner.new(packages, db) }

  let(:whitelisted_defect) do
    double('Debsecan::Defect', identifier: 'FAKE-VULN-1')
  end

  let(:allowed_defect) do
    double('Debsecan::Defect', identifier: 'FAKE-VULN-2')
  end

  let(:flags) do
    {
      whitelist: {
        'FAKE-VULN-1' => {
          reason: 'Lorum',
          by: 'Ipsum',
          on: 'Dolor'
        }
      },
      allowed: {
        'FAKE-VULN-2' => {
          reason: 'Lorum',
          by: 'Ipsum',
          on: 'Dolor'
        }
      }
    }
  end

  let(:filter) { :default }
  let(:only_fixed) { false }
  let(:scan_args) { { filter: filter, only_fixed: only_fixed } }
  let(:release_matches) { true }
  let(:fixed_in) { [package] }
  let(:defects) { [defect] }
  let(:target) { double('target') }

  before(:each) do
    allow(db).to receive(:defects_for).and_return(defects)
    allow(package).to receive(:release) { release_matches }
    allow(defect).to receive(:fixed_in) { fixed_in }
    allow(Psych).to receive(:load_file).and_return(flags)
  end

  shared_examples_for 'reports the defect' do
    it 'reports the expected package-defect Hash' do
      is_expected.to be_a Hash
      is_expected.not_to be_empty
      is_expected.to eq(package => [defect])
    end
  end

  shared_examples_for 'does not report the defect' do
    it 'returns an empty Hash' do
      is_expected.to be_a Hash
      is_expected.to be_empty
    end
  end

  describe '#scan' do
    let(:vulnerable) { true }

    before(:each) do
      allow(package).to receive(:<) { vulnerable }
    end

    subject { scanner.scan(scan_args) }

    context 'package has defects' do
      context 'and refers to a source that is not known' do
        let(:package) { package_source }
        include_examples 'reports the defect'
      end

      context 'only_fixed is false' do
        include_examples 'reports the defect'
      end

      context 'only_fixed is true' do
        let(:only_fixed) { true }

        context 'and the defect is fixed' do
          include_examples 'reports the defect'
        end

        context 'the defect is not fixed' do
          let(:fixed_in) { [] }
          include_examples 'does not report the defect'
        end
      end
    end

    context 'package has no defects' do
      let(:defects) { [] }
      include_examples 'does not report the defect'
    end

    describe 'filter' do
      before do
        allow(whitelisted_defect).to receive(:fixed_in) { fixed_in }
        allow(allowed_defect).to receive(:fixed_in) { fixed_in }
      end

      let(:defects) { [defect, whitelisted_defect, allowed_defect] }

      shared_examples_for 'filtered results' do |expect_result|
        it "returns only #{expect_result}" do
          expect(subject[package].count).to eq 1
          expect(subject[package][0].identifier).to eq expect_result
        end
      end

      context 'is :default' do
        let(:filter) { :default }

        include_examples 'filtered results', 'one'
      end

      context 'is :allowed' do
        let(:filter) { :allowed }

        include_examples 'filtered results', 'FAKE-VULN-2'
      end

      context 'is :whitelisted' do
        let(:filter) { :whitelisted }

        include_examples 'filtered results', 'FAKE-VULN-1'
      end
    end
  end

  describe '#fixed_by_target' do
    let(:not_affected) { false }
    let(:compare_result) { true }

    subject { scanner.fixed_by_target }

    context 'package has defects' do
      before(:each) do
        allow(package).to receive(:>=) { not_affected }
        allow(package).to receive(:target_at_least?) { compare_result }
      end

      context 'and refers to a source that is not known' do
        let(:package) { package_source }
        include_examples 'reports the defect'
      end

      context 'but no target version' do
        let(:target) { nil }

        include_examples 'does not report the defect'
      end

      context 'fixed in the target version' do
        include_examples 'reports the defect'
      end

      context 'fixed in an earlier version' do
        let(:not_affected) { true }

        include_examples 'does not report the defect'
      end

      context 'fixed after the target version' do
        let(:compare_result) { false }

        include_examples 'does not report the defect'
      end
    end

    context 'package has no defects' do
      let(:defects) { [] }
      include_examples 'does not report the defect'
    end
  end
end

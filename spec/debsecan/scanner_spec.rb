# frozen_string_literal: true

RSpec.describe Debsecan::Scanner do
  let(:package) do
    instance_double('Package',
                    name: 'foo',
                    version: 1,
                    target: target,
                    source: nil,
                    release: 'a',
                    filtered?: package_filtered)
  end

  let(:package_source) do
    instance_double('Package',
                    name: 'bar',
                    version: 1,
                    target: target,
                    source: 'baz',
                    release: 'a',
                    filtered?: package_source_filtered)
  end

  let(:packages) { [package] }

  let(:defect) do
    instance_double('Debsecan::Defect',
                    identifier: 'one',
                    fix_available?: true,
                    fixed_in: fixed_in,
                    filtered?: default_filtered)
  end

  let(:filtered) { false }
  let(:package_filtered) { filtered }
  let(:package_source_filtered) { filtered }
  let(:default_filtered) { filtered }

  let(:db) { instance_double('Debsecan::Database', defects_for: defects) }

  let(:scanner) { Debsecan::Scanner.new(packages, db) }

  let(:filter) { :default }
  let(:flag_filter) { :default }
  let(:scan_args) { { defect_filter: filter, flag_filter: flag_filter } }
  let(:fixed_in) { [package] }
  let(:defects) { [defect] }
  let(:target) { double('target') }

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
    subject { scanner.scan(scan_args) }

    context 'package has defects' do
      context 'and refers to a source that is not known' do
        let(:package) { package_source }
        include_examples 'reports the defect'
      end

      context 'with :only_fixed filter' do
        context 'and the defect is fixed' do
          include_examples 'reports the defect'
        end

        context 'and the defect is not fixed' do
          let(:fixed_in) { [] }
          include_examples 'does not report the defect'
        end
      end
    end

    context 'package has no defects' do
      let(:defects) { [] }
      include_examples 'does not report the defect'
    end

    describe 'filtered results' do
      let(:whitelisted_defect) do
        instance_double('Debsecan::Defect',
                        identifier: 'FAKE-VULN-1',
                        fixed_in: fixed_in,
                        filtered?: whitelist_filtered)
      end

      let(:allowed_defect) do
        instance_double('Debsecan::Defect',
                        identifier: 'FAKE-VULN-2',
                        fixed_in: fixed_in,
                        filtered?: allowed_filtered)
      end

      let(:filtered) { true }
      let(:whitelist_filtered) { filtered }
      let(:allowed_filtered) { filtered }
      let(:package_filtered) { false }
      let(:defects) { [defect, whitelisted_defect, allowed_defect] }

      shared_examples_for 'filtered results' do |expect_result|
        it "returns only #{expect_result}" do
          expect(subject[package].count).to eq 1
          expect(subject[package][0].identifier).to eq expect_result
        end
      end

      context 'is :default' do
        let(:default_filtered) { false }
        include_examples 'filtered results', 'one'
      end

      context 'is :allowed' do
        let(:allowed_filtered) { false }
        let(:flag_filter) { :allowed }

        include_examples 'filtered results', 'FAKE-VULN-2'
      end

      context 'is :whitelisted' do
        let(:whitelist_filtered) { false }
        let(:flag_filter) { :whitelisted }

        include_examples 'filtered results', 'FAKE-VULN-1'
      end
    end
  end

  describe '#scan_by_target' do
    subject { scanner.scan_by_target }

    context 'package has defects' do
      include_examples 'reports the defect'
    end

    context 'package has no defects' do
      let(:defects) { [] }
      include_examples 'does not report the defect'
    end
  end
end

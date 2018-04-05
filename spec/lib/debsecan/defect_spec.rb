# frozen_string_literal: true

RSpec.describe Debsecan::Defect do
  Fixed = Struct.new(:version)
  let(:fixed_package) { Fixed.new(1) }
  let(:unfixed_package) { Fixed.new(Debsecan::Package::MAX_VERSION) }
  let(:package) { double('package') }
  let(:defect_hash) do
    {
      identifier: 'Lorum',
      description: 'Ipsum',
      severity: 'Dolor',
      fixed_in: [package]
    }
  end

  let(:defect) { Debsecan::Defect.new(defect_hash) }

  describe '#fix_available?' do
    subject { defect }

    context 'when there is no fix' do
      let(:package) { unfixed_package }
      it 'returns false' do
        expect(subject.fix_available?).to be_falsey
      end
    end

    context 'when there is a fix' do
      let(:package) { fixed_package }
      it 'returns true' do
        expect(subject.fix_available?).to be_truthy
      end
    end
  end

  describe '#flag_filtered?' do
    subject { defect.flag_filtered?(filter) }

    context 'filter is :default' do
      let(:filter) { :default }

      context 'with no flag set' do
        it { is_expected.to be false }
      end

      context 'with a flag set' do
        before { defect.flag = :foo }
        it { is_expected.to be true }
      end
    end

    context 'filter is :allowed' do
      let(:filter) { :allowed }

      context 'with no flag' do
        it { is_expected.to be true }
      end

      context 'flag is :allowed' do
        before { defect.flag = :allowed }
        it { is_expected.to be false }
      end

      context 'flag is :foo' do
        before { defect.flag = :foo }
        it { is_expected.to be true }
      end
    end

    context 'filter is :whitelisted' do
      let(:filter) { :whitelisted }

      context 'with no flag' do
        it { is_expected.to be true }
      end

      context 'flag is :whitelisted' do
        before { defect.flag = :whitelisted }
        it { is_expected.to be false }
      end

      context 'flag is :foo' do
        before { defect.flag = :foo }
        it { is_expected.to be true }
      end
    end
  end

  describe '#filtered?' do
    subject { defect.filtered?(filter: filter) }
    let(:filter) { :default }

    context 'when flag filtered' do
      before { defect.flag = :foo }
      it { is_expected.to be true }
    end

    context 'when not flag filtered' do
      context 'filter is :default' do
        it { is_expected.to be false }
      end

      context 'filter is :only_fixed' do
        let(:filter) { :only_fixed }

        context 'when there is no fix' do
          let(:package) { unfixed_package }
          it { is_expected.to be true }
        end

        context 'when there is a fix' do
          let(:package) { fixed_package }
          it { is_expected.to be false }
        end
      end

      context 'filter is not recognized' do
        let(:filter) { :foo }
        it 'raises an UnknownFilterError' do
          expect { subject }.to raise_error(Debsecan::UnknownFilterError, 'foo')
        end
      end
    end
  end
end

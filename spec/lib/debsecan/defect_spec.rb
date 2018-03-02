# frozen_string_literal: true

RSpec.describe Debsecan::Defect do
  Fixed = Struct.new(:version)
  let(:fixed_package) { Fixed.new(1) }
  let(:unfixed_package) { Fixed.new(Debsecan::Package::MAX_VERSION) }
  let(:defect_hash) do
    {
      identifier: 'Lorum',
      description: 'Ipsum',
      severity: 'Dolor',
      fixed_in: [package]
    }
  end

  describe '#fix_available?' do
    subject { Debsecan::Defect.new(defect_hash) }
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
end

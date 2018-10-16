# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dobby::Formatter::SimpleFormatter do
  subject(:formatter) { described_class.new(output) }

  let(:output) { StringIO.new }

  let(:package) { instance_double('Dobby::Package', to_s: 'PKG') }

  let(:low_defect) do
    instance_double('Dobby::Defect',
                    severity: Dobby::Severity::Low,
                    identifier: 'FAKE-LOW')
  end

  let(:medium_defect) do
    instance_double('Dobby::Defect',
                    severity: Dobby::Severity::Medium,
                    identifier: 'FAKE-MEDIUM')
  end

  let(:critical_defect) do
    instance_double('Dobby::Defect',
                    severity: Dobby::Severity::Critical,
                    identifier: 'FAKE-CRITICAL')
  end

  let(:unknown_defect) do
    instance_double('Dobby::Defect',
                    severity: Dobby::Severity::Unknown,
                    identifier: 'FAKE-UNKNOWN')
  end

  describe '#file_finished' do
    before do
      formatter.file_finished(nil, results)
    end

    context 'with no results' do
      let(:results) { [] }
      it 'prints nothing' do
        expect(output.string).to be_empty
      end
    end

    context 'with a low severity result' do
      let(:results) { [[package, [low_defect]]] }

      it 'prints a low severity result' do
        expect(output.string).to include('PKG')
        expect(output.string).to include('FAKE-LOW                  Low')
      end
    end

    context 'when a single package has multiple defects' do
      let(:results) { [[package, [low_defect, medium_defect]]] }
      it 'prints all results' do
        # rubocop:disable Layout/TrailingWhitespace
        expect(output.string).to eq(<<-RESULT.strip_indent)

          PKG
          \tFAKE-MEDIUM               Medium    
          \tFAKE-LOW                  Low       
        RESULT
        # rubocop:enable Layout/TrailingWhitespace
        expect(output.string).to include('PKG')
        expect(output.string).to include('FAKE-MEDIUM               Medium')
        expect(output.string).to include('FAKE-LOW                  Low')
      end
    end

    context 'when multiple packages have defects' do
      let(:results) { [[package, [critical_defect]], [package, [unknown_defect]]] }
      it 'prints all results' do
        # rubocop:disable Layout/TrailingWhitespace
        expect(output.string).to eq(<<-RESULT.strip_indent)

          PKG
          \tFAKE-CRITICAL             Critical  
          
          PKG
          \tFAKE-UNKNOWN              Unknown   
        RESULT
        # rubocop:enable Layout/TrailingWhitespace
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Debsecan::Runner do
  let(:formatter_output_path) { 'formatter_output.txt' }
  let(:formatter_output) { File.read(formatter_output_path) }
  let(:package_source_file) { File.join(__dir__, '..', 'fixtures', 'dpkg_status_vulnerable') }

  let(:runner) { described_class.new(options) }

  def in_tmpdir
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) { yield tmp }
    end
  end

  describe '#run' do
    let(:options) do
      {
        formatters: [['simple', formatter_output_path]],
        file: File.join(__dir__, '..', 'fixtures', 'debian_vuln_src.json')
      }
    end

    subject { runner.run([package_source_file]) }

    context 'if there are no vulnerable packages' do
      let(:package_source_file) { File.join(__dir__, '..', 'fixtures', 'dpkg_status') }

      it 'returns true' do
        in_tmpdir do
          expect(subject).to be true
        end
      end
    end

    context 'if there are vulnerable packages' do
      it 'returns false' do
        in_tmpdir do
          expect(subject).to be false
        end
      end
    end
  end
end

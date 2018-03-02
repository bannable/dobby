# frozen_string_literal: true

RSpec.describe Debsecan::Options do
  subject(:options) { described_class.new }

  before do
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  after do
    $stdout = STDOUT
    $stderr = STDERR
  end

  describe 'option' do
    describe '--help' do
      it 'exits cleanly' do
        expect { options.parse ['-h'] }.to exit_with_code(0)
        expect { options.parse ['--help'] }.to exit_with_code(0)
      end

      it 'shows help text' do
        skip 'determine what features to support first'
        expected_help = <<-HELP.strip_indent
          Usage:
            debsecan scan
            debsecan flag
        HELP

        begin
          options.parse(['--help'])
        rescue SystemExit # rubocop:disable Lint/HandleExceptions
        end
        expect($stdout.string).to eq(expected_help)
      end
    end
  end
end

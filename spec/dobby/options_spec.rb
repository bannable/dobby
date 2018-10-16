# frozen_string_literal: true

RSpec.describe Dobby::Options do
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
        expected_help = <<~HELP
          Usage: dobby [options] [file1, file2, ...]
                 dobby -o file [file1, file2, ...]
                 dobby -f simple -f json -o bar [file1, file2, ...]

                  --debug
                  --fail-fast                  Exit as soon as a defect is discovered.
                  --list-target-files          List the package source files that would be inspected
                                               and then exit.
              -v, --version                    Display version.
              -V, --verbose-version            Display verbose verison.
                  --[no-]color                 Force colored output on or off.
                  --[no-]fixed-only            Only report vulnerabilities which have a fix
                                               version noted in the vulnerability source.
              -f, --format FORMATTER           Choose an output formatter. This option
                                               can be specified multiple times to enable
                                               multiple formatters at the same time.
                                                 [s]imple (default)
                                                 [j]son
                                                 custom formatter class name
              -o, --out FILE                   Use with --format to instruct the previous formatter
                                               to output to the specified path instead of to stdout.
              -P PACKAGE-SOURCE,               Choose a package source.
                  --package-source               [d]pkg (default)
                                                 custom package source class name
              -s, --vuln-source-file FILE      Specify a local file to be used by the vulnerability
                                               source instead of using the default behavior. For
                                               Debian and Ubuntu, the default behavior is to fetch
                                               the source from their respective security trackers.
                                               Warning: Not compatible with Ubuntu source
              -S, --vuln-source VULN-SOURCE    Choose a vulnerability source.
                                                 [d]ebian (default)
                                                 custom vulnerability source class name
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

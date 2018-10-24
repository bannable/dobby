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
        expected_help = <<-HELP.strip_indent
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
              -S, --vuln-source VULN-SOURCE    Choose a vulnerability source.
                                                 [d]ebian (default)
                                                 custom vulnerability source class name
                  --release NAME               Release code name for package definitions.
                                               Defaults to the code name of the current system.
                  --dist DIST                  The full name of the distribution for package definitions.
                                               Defaults to "Debian".
                  --dst-json-uri URI           VulnSource::Debian -- specify a URI to the
                                               Debian Security Tracker's JSON file.
                  --dst-local-file PATH        VulnSource::Debian -- If provided, read from
                                               the specified file instead of requesting the
                                               DST json file from a remote.
                  --releases ONE,TWO           Limit the packages returned by a VulnSource to
                                               these releases. Default vaires with selected
                                               VulnSource.
                  --bzr-bin PATH               VulnSource::Ubuntu - Path to the "bzr" binary.
                  --tracker-repo URI           VulnSource::Ubuntu - Path to the security tracker
                                               bazaar repository remote.
                  --cve-url-prefix URL         URI prefix used for building CVE links.
        HELP

        begin
          options.parse(['--help'])
        rescue SystemExit # rubocop:disable Lint/HandleExceptions
        end
        expect($stdout.string).to eq(expected_help)
      end
    end
  end

  describe 'files' do
    it 'uses /var/lib/dpkg/status by default' do
      _, files = options.parse []
      expect(files).to eq(['/var/lib/dpkg/status'])
    end
  end
end

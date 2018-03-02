# frozen_string_literal: true

RSpec.describe Debsecan::CLI do
  include_context 'cli context'

  subject(:cli) { described_class.new }

  let(:source_json) { File.join('spec', 'fixtures', 'debian_vuln_src.json') }
  let(:status_file) { File.join('spec', 'fixtures', 'dpkg_status') }
  let(:status_file_vulnerable) { File.join('spec', 'fixtures', 'dpkg_status_vulnerable') }

  let(:options) do
    %W[
      --file
      #{source_json}
      #{status_file}
    ]
  end

  context 'when interrupted' do
    it 'returns 1' do
      allow_any_instance_of(Debsecan::Runner)
        .to receive(:aborting?).and_return(true)
      expect(cli.run(options)).to eq(1)
    end
  end

  context 'when inspecting a secure package set' do
    it 'returns 0' do
      expect(cli.run(options)).to eq(0)
      expect($stdout.string).to eq('')
    end
  end

  context 'when inspecting an insecure package set' do
    let(:status_file) { status_file_vulnerable }

    it 'returns 1' do
      expect(cli.run(options)).to eq(1)
      expect($stdout.string).to eq(
        "\nasterisk 0.5.55\n\tCVE-2003-0779             High      \n"
      )
    end
  end

  describe 'option parsing' do
    describe 'option is invalid' do
      it 'suggests to use the help flag' do
        invalid_option = '--invalid-option'
        expect(cli.run([invalid_option])).to eq(2)
        expect($stderr.string).to eq(<<-RESULT.strip_indent)
          invalid option: #{invalid_option}
          For usage information, use --help
        RESULT
      end
    end

    describe '--version' do
      it 'exits 0' do
        expect(cli.run(['-v'])).to eq(0)
        expect(cli.run(['--version'])).to eq(0)
        expect($stdout.string).to eq((Debsecan::Version::STRING + "\n") * 2)
      end
    end

    describe '--format' do
      let(:status_file) { File.expand_path(status_file_vulnerable) }

      describe 'builtin formatters' do
        it 'outputs with simple format' do
          cli.run(['--format', 'simple'] | options)
          expect($stdout.string).to include('CVE-2003-0779')
        end

        it 'outputs with json format'
      end

      describe 'custom formatter' do
        context 'when specifying a class name' do
          it 'uses that class as a formatter' do
            module ExampleTestTool
              class GenericFormatter < Debsecan::Formatter::AbstractFormatter
                def started(all_files)
                  output.puts "started: #{all_files.join(',')}"
                end

                def file_started(file)
                  output.puts "file_started: #{file}"
                end

                def file_finished(file, _offenses)
                  output.puts "file_finished: #{file}"
                end

                def finished(processed_files)
                  output.puts "finished: #{processed_files.join(',')}"
                end
              end
            end

            cli.run(['--format', 'ExampleTestTool::GenericFormatter'] | options)
            expect($stdout.string).to eq(<<-RESULT.strip_indent)
              started: #{status_file}
              file_started: #{status_file}
              file_finished: #{status_file}
              finished: #{status_file}
            RESULT
          end
        end

        context 'when an unknown class name is specified'
      end
    end
  end
end

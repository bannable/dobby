# frozen_string_literal: true

module Debsecan
  class Runner
    attr_reader :errors, :aborting
    alias aborting? aborting

    def initialize(options)
      @options = options
      @errors = []
      @aborting = false
    end

    def run(paths)
      target_files = resolve_paths(paths)
      return list_files(target_files) if @options[:list_target_files]
      load_scanner
      load_package_sources(paths)
      inspect_files(target_files)
    end

    private

    def inspect_files(files)
      inspected = []

      formatter_set.started(files)

      each_inspected_file(files) { |file| inspected << file }
    ensure
      formatter_set.finished(inspected.freeze)
      formatter_set.close_output_files
    end

    def resolve_paths(target_files)
      target_files.map { |f| File.expand_path(f) }.freeze
    end

    def each_inspected_file(files)
      files.reduce(true) do |passed, file|
        break false if aborting?

        results = process_file(file)

        yield file

        if results.any?
          break false if @options[:fail_fast]
          next false
        end

        passed
      end
    end

    def formatter_set
      @formatter_set ||= begin
        set = Formatter::FormatterSet.new(@options)
        pairs = @options[:formatters] || [['simple']]
        pairs.each do |formatter_key, output_path|
          set.add_formatter(formatter_key, output_path)
        end
        set
      end
    end

    def load_package_sources(files)
      @package_source = Debsecan::PackageSource::DpkgStatusFile.new(
        file_path: files[0]
      )
    end

    def load_scanner
      vuln_source = Debsecan::VulnSource::Debian.new(
        test_mode: true,
        source: @options[:file]
      )
      @database = Debsecan::Database.new(vuln_source)
      @scanner = Scanner.new(nil, @database)
    end

    def process_file(file = nil)
      formatter_set.file_started(file)
      source = PackageSource::DpkgStatusFile.new(file_path: file)
      packages = source.parse
      results = run_scanner(packages)
      formatter_set.file_finished(file, results)
      results
    end

    def run_scanner(packages)
      @scanner.packages = packages
      @scanner.scan(defect_filter: Scanner::DEFECT_FILTER_FIXED)
    end
  end
end

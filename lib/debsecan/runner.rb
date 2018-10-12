# frozen_string_literal: true

module Debsecan
  # TODO: Document me.
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
      load_vuln_source(@options[:vuln_source])
      load_package_source(@options[:package_source])
      load_scanner
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
        pairs = @options[:formatters] || [['simple', @options[:output_path]]]
        pairs.each do |formatter_key, output_path|
          set.add_formatter(formatter_key, output_path)
        end
        set
      end
    end

    def load_package_source(selected)
      selected ||= 'dpkg'
      @package_source = package_source_loader(selected)
    end

    def load_vuln_source(selected)
      selected ||= 'debian'
      @vuln_source = vuln_source_loader(selected)
    end

    def load_scanner
      vuln_source = if @options[:vuln_source_file]
                      @vuln_source.new(
                        test_mode: true,
                        source: @options[:vuln_source_file]
                      )
                    else
                      @vuln_source.new
                    end
      @database = Debsecan::Database.new(vuln_source)
      @scanner = Scanner.new(nil, @database)
    end

    def process_file(file = nil)
      formatter_set.file_started(file)
      source = @package_source.new(file_path: file)
      packages = source.parse
      results = run_scanner(packages)
      formatter_set.file_finished(file, results)
      results
    end

    def run_scanner(packages)
      @scanner.packages = packages
      @scanner.scan(defect_filter: Scanner::DEFECT_FILTER_FIXED)
    end

    BUILTIN_PACKAGE_SOURCES = {
      'dpkg' => PackageSource::DpkgStatusFile
    }.freeze

    BUILTIN_VULN_SOURCES = {
      'debian' => VulnSource::Debian,
      'ubuntu' => VulnSource::Ubuntu
    }.freeze

    def builtin_package_source_class(specified)
      matching = BUILTIN_PACKAGE_SOURCES.keys.select do |key|
        key.start_with?(specified)
      end

      raise %(No package source for "#{specified}") if matching.empty?
      raise %(Ambiguous package source for "#{specified}") if matching.size > 1

      BUILTIN_PACKAGE_SOURCES[matching.first]
    end

    # TODO: DRY
    def builtin_vuln_source_class(specified)
      matching = BUILTIN_VULN_SOURCES.keys.select do |key|
        key.start_with?(specified)
      end

      raise %(No vulnerability source for "#{specified}") if matching.empty?
      raise %(Ambiguous vulnerability source for "#{specified}") if matching.size > 1

      BUILTIN_VULN_SOURCES[matching.first]
    end

    def vuln_source_loader(specifier)
      case specifier
      when Class
        specifier
      when /\A[A-Z]/
        custom_class(specifier)
      else
        builtin_vuln_source_class(specifier)
      end
    end

    def package_source_loader(specifier)
      case specifier
      when Class
        specifier
      when /\A[A-Z]/
        custom_class(specifier)
      else
        builtin_package_source_class(specifier)
      end
    end

    def custom_class(name)
      constant_names = name.split('::')
      constant_names.shift if constant_names.first.empty?
      constant_names.reduce(Object) do |namespace, constant_name|
        namespace.const_get(constant_name, false)
      end
    end
  end
end

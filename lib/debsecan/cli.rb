# frozen_string_literal: true

module Debsecan
  # The meraki-debsecan CLI.
  class CLI
    STATUS_SUCCESS = 0
    STATUS_WARNING = 1
    STATUS_ERROR   = 2

    class Finished < RuntimeError; end

    attr_reader :options

    def initialize
      @options = {}
    end

    def run(args = ARGV)
      @options, files = Options.new.parse(args)
      act_on_options
      execute_runner(files)
    rescue Finished
      STATUS_SUCCESS
    rescue OptionParser::InvalidOption => e
      warn e.message
      warn 'For usage information, use --help'
      STATUS_ERROR
    rescue StandardError, SyntaxError, LoadError => e
      warn e.message
      warn e.backtrace
      STATUS_ERROR
    end

    private

    def act_on_options
      handle_exiting_options
      # TODO: handle incompatible options (ubuntu source with source file specified)

      if @options[:color]
        Rainbow.enabled = true
      elsif @options[:color] == false
        Rainbow.enabled = false
      end
    end

    def handle_exiting_options
      return unless Options::EXITING_OPTIONS.any? { |o| @options.key? o }
      puts Debsecan::Version.version(true) if @options[:verbose_version]
      puts Debsecan::Version.version(false) if @options[:version]
      raise Finished
    end

    def execute_runner(paths)
      runner = Runner.new(@options)
      all_passed = runner.run(paths) && !runner.aborting? && runner.errors.empty?

      return STATUS_SUCCESS if all_passed
      STATUS_WARNING
    end
  end
end

# frozen_string_literal: true

# Adapted from rubocop's Options:
# Copyright (c) 2012-18 Bozhidar Batsov
# Additional modifications Copyright (c) 2018 Joe Truba
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

module Dobby
  # Parsing of command line options and arguments.
  class Options
    EXITING_OPTIONS = %i[version verbose_version].freeze

    def initialize
      @options = {}
    end

    def parse(cli_args)
      args = args_from_file.concat(args_from_env).concat(cli_args)
      define_options.parse!(args)
      args << '/var/lib/dpkg/status' if args.empty?
      [@options, args]
    end

    private

    def args_from_file
      if File.exist?('.dobby') && !File.directory?('.dobby')
        IO.readlines('.dobby').map(&:strip)
      else
        []
      end
    end

    def args_from_env
      Shellwords.split(ENV.fetch('DEBSECAN_OPTS', ''))
    end

    def define_options
      OptionParser.new do |opts|
        opts.program_name = 'meraki-dobby'
        opts.banner = <<-BANNER.strip_indent
          Usage: dobby [options] [file1, file2, ...]
                 dobby -o file [file1, file2, ...]
                 dobby -f simple -f json -o bar [file1, file2, ...]

        BANNER

        add_boolean_options(opts)
        add_formatting_options(opts)
        add_configuration_options(opts)
        add_strategy_options(opts)
      end
    end

    # Sets a value in the @options hash, based on the given long option and its
    # value, in addition to calling the block if a block is given.
    def option(opts, *args)
      long_opt_symbol = long_opt_symbol(args)
      args += Array(OptionsHelp::TEXT[long_opt_symbol])
      opts.on(*args) do |arg|
        @options[long_opt_symbol] = arg
        yield arg if block_given?
      end
    end

    # Finds the option in `args` starting with -- and converts it to a symbol,
    # e.g. [..., '--auto-correct', ...] to :auto_correct.
    def long_opt_symbol(args)
      long_opt = args.find { |arg| arg.start_with?('--') }
      raise "unable to find long option from '#{args}'" unless long_opt
      long_opt[2..-1].sub('[no-]', '').sub(/ .*/, '')
                     .tr('-', '_').gsub(/[\[\]]/, '').to_sym
    end

    def add_formatting_options(opts)
      option(opts, '-f', '--format FORMATTER') do |f|
        @options[:formatters] ||= []
        @options[:formatters] << [f]
      end

      option(opts, '-o', '--out FILE') do |path|
        if @options[:formatters]
          @options[:formatters].last << path
        else
          @options[:output_path] = path
        end
      end
    end

    def add_boolean_options(opts)
      option(opts, '--debug')
      option(opts, '--fail-fast')
      option(opts, '--list-target-files')
      option(opts, '-v', '--version')
      option(opts, '-V', '--verbose-version')
      option(opts, '--[no-]color')
      option(opts, '--[no-]fixed-only')
    end

    def add_configuration_options(opts)
      option(opts, '-P', '--package-source PACKAGE-SOURCE')
      option(opts, '-S', '--vuln-source VULN-SOURCE')
    end

    def add_strategy_options(opts)
      Builtins::ALL.each do |strategy|
        strategy.cli_options.each do |opt|
          option(opts, *opt)
        end
      end
    end
  end

  module OptionsHelp
    TEXT = {
      color:                 'Force colored output on or off.',
      format:               ['Choose an output formatter. This option',
                             'can be specified multiple times to enable',
                             'multiple formatters at the same time.',
                             '  [s]imple (default)',
                             '  [j]son',
                             '  custom formatter class name'],
      fail_fast:             'Exit as soon as a defect is discovered.',
      fixed_only:           ['Only report vulnerabilities which have a fix',
                             'version noted in the vulnerability source.'],
      list_target_files:    ['List the package source files that would be inspected',
                             'and then exit.'],
      out:                  ['Use with --format to instruct the previous formatter',
                             'to output to the specified path instead of to stdout.'],
      package_source:       ['Choose a package source.',
                             '  [d]pkg (default)',
                             '  custom package source class name'],
      vuln_source:          ['Choose a vulnerability source.',
                             '  [d]ebian (default)',
                             '  custom vulnerability source class name'],
      version:               'Display version.',
      verbose_version:       'Display verbose verison.'
    }.freeze
  end
end

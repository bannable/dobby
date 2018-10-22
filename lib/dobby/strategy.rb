# frozen_string_literal: true

module Dobby
  # The Strategy provides base functionality for defining how Dobby takes in
  # the data it needs to do its job. Each strategy should include this mixin
  # to ensure compatibility with the rest of the library.
  #
  # In particular, the mixin provides a DSL for configuring strategies and
  # standardizes some strategy behavior (such as #inspect).
  #
  # Much of this borrowed from Omniauth::Strategy
  #   https://github.com/omniauth/omniauth/blob/master/lib/omniauth/strategy.rb
  #
  # @abstract Include as a mixin to implement a Strategy compatible with the
  #   library
  module Strategy
    class Options < Hashie::Mash; end

    def self.included(base)
      Dobby.strategies << base

      base.extend ClassMethods
      base.class_eval do
        option :setup, false
        option :test_mode, false
      end
    end

    # Extensible configuration for implementers.
    module ClassMethods
      # An inherited set of default options set at the class-level
      # for each strategy.
      #
      # @return [Options]
      def default_options
        existing = begin
                     superclass.default_options
                   rescue StandardError
                     {}
                   end
        @default_options ||= Dobby::Strategy::Options.new(existing)
      end

      # This allows for more declarative subclassing of strategies by allowing
      # default options to be set using a simple configure call.
      #
      # @param options [Hash] If supplied, these will be the default options
      #   (deep-merged into the superclass's default options).
      # @yield [Options] The options Mash that allows you to set your defaults
      #   as you'd like.
      #
      # @example Using a yield to configure the default options.
      #
      #   class MyStrategy
      #     include Dobby::Strategy
      #
      #     configure do |c|
      #       c.foo = 'bar'
      #     end
      #   end
      #
      # @example Using a hash to configure the default options.
      #
      #   class MyStrategy
      #     include Dobby::Strategy
      #     configure foo: 'bar'
      def configure(options = nil)
        if block_given?
          yield default_options
        else
          default_options.deep_merge!(options)
        end
      end

      # Directly declare a default option for your class. This is a useful from
      # a documentation perspective as it provides a simple line-by-line analysis
      # of the kinds of options your strategy provides by default.
      #
      # @param name [Symbol] The key of the default option in your configuration hash.
      # @param value [Object] The value your object defaults to. Nil if not provided.
      #
      # @example
      #
      #   class MyStrategy
      #     include Dobby::Strategy
      #
      #     option :foo, 'bar'
      #   end
      def option(name, value = nil)
        default_options[name] = value
      end

      # Sets (and retrieves) option key names for initializer arguments to be
      # recorded as. This takes care of 90% of the use cases for overriding
      # the initializer in Dobby Strategies. Dobby::Options will also use
      # this, via #cli_options, to configure any command line options.
      def args(args = nil)
        if args
          @args = Array(args)
          return
        end
        existing = begin
                     superclass.args
                   rescue StandardError
                     []
                   end
        (instance_variable_defined?(:@args) && @args) || existing
      end

      # By default, all args are automatically built out as k/v CLI options. For
      # more advanced behavior, override cli_options in the implementing class.
      # The return of this method is passed directly to Dobby::Options#options
      def cli_options
        args.map { |arg| "--#{arg.to_s.tr('_', '-')} VALUE" }
      end
    end

    attr_reader :options

    # Initialize the strategy, creating an [Options] hash if the last
    # argument is a Hash.
    #
    # @param args [Hash]
    #
    # @yield [Options]
    def initialize(*args)
      @options = self.class.default_options.dup
      options.deep_merge!(args.pop) if args.last.is_a?(Hash)
      options[:name] ||= self.class.to_s.split('::').last.downcase

      self.class.args.each do |arg|
        break if args.empty?

        options[arg] = args.shift
      end

      raise ArgumentError, "Received too many arguments. #{args.inspect}" unless args.empty?

      setup

      yield options if block_given?
    end

    # Callback placeholder so that 'super' during initialize is unnecessary in
    # implementing classes. This is the other 10% of the use case for overriding
    # initialize.
    def setup; end

    # @return [String]
    def inspect
      "#<#{self.class}>"
    end

    # Access to the Dobby logger, automatically prefixed with the
    # strategy's name.
    #
    # @param level [Symbol] syslog level
    # @param message [String]
    #
    # @example
    #   log :fatal, 'This is a fatal error.'
    #   log :error, 'This is an error.'
    #   log :warn, 'This is a warning.'
    def log(level, message)
      Dobby.logger.send(level, "(#{self.class.name}) #{message}")
    end
  end
end

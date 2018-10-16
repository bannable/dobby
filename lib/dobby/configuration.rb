# frozen_string_literal: true

module Dobby
  # All available Package and Database strategies available to the library.
  #
  # @return [Array<Object>]
  def self.strategies
    @strategies ||= []
  end

  def self.config
    Configuration.instance
  end

  def self.configure
    yield config
  end

  def self.logger
    config.logger
  end

  # Gem configuration.
  class Configuration
    include Singleton

    def self.default_logger
      logger = Logger.new(STDOUT)
      logger.progname = 'dobby'
      logger
    end

    def self.defaults
      @defaults ||= {}
    end

    def initialize
      self.class.defaults.each_pair { |k, v| send("#{k}=", v) }
    end

    ###########
    # Callbacks
    #
    #
    # def on_failure(&block)
    #   if block_given?
    #     @on_failure = block
    #   else
    #     @on_failure
    #   end
    # end
    #
    # attr_writer :on_failure
    # #########

    attr_accessor :logger
  end
end

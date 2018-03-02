# frozen_string_literal: true

require 'singleton'
module Debsecan
  # Gem configuration.
  class Configuration
    include Singleton

    def self.default_logger
      logger = Logger.new(STDOUT)
      logger.progname = 'debsecan'
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

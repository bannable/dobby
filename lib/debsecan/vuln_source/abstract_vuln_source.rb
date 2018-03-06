# frozen_string_literal: true

module Debsecan
  module VulnSource
    # @abstract Subclass and override {#update} and #{clean} to implement a
    # custom Database source.
    class AbstractVulnSource
      include Debsecan::Strategy

      # Retrieve a source database (if necessary) and parse it.
      #
      # @return [UpdateResponse]
      def update
        raise NotImplementedError
      end

      # Instruct a strategy to clean up after itself, removing any files it
      # may have created.
      #
      # @return [void]
      def clean
        raise NotImplementedError
      end
    end
  end
end

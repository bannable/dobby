# frozen_string_literal: true

module Dobby
  module PackageSource
    # @abstract Subclass and override {#parse} to implement a custom Package
    #   source.
    class AbstractPackageSource
      include Dobby::Strategy

      # All logic for creating an Array<Package>]
      # @return [Array<Package>]
      def parse
        raise NotImplementedError
      end
    end
  end
end

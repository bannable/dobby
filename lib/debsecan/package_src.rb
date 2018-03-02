# frozen_string_literal: true

module Debsecan
  # @abstract Subclass and override {#parse} to implement a custom Package
  #   source.
  class PackageSrc
    include Debsecan::Strategy

    # All logic for creating an Array<Package>]
    # @return [Array<Package>]
    def parse
      raise NotImplementedError
    end
  end
end

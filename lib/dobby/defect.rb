# frozen_string_literal: true

module Dobby
  # A vulnerability which affects a particular {Package}
  class Defect
    # @return [String] unique identifier for this defect, usually a CVE ID
    attr_reader :identifier

    # @return [String] a description of the defect
    attr_reader :description

    # Set of Packages representing the minimum fix version
    # @return [Array<Package>]
    attr_reader :fixed_in

    # @return [String] (low, medium, high) the priority category assigned to
    #   this Defect
    attr_reader :severity

    attr_reader :link

    attr_accessor :flag

    # Simple hash serializer for a Defect
    # @return [Hash]
    def to_hash
      {
        identifier: identifier,
        description: description,
        severity: severity.to_s,
        fixed_in: fixed_in.map(&:to_s)
      }
    end

    # @param identifier [String]
    # @param description [String]
    # @param severity [Severity]
    # @param fixed_in [Array<Package>]
    # @param link [String] External reference for the defect
    def initialize(identifier:, description:, severity:, link: nil, fixed_in: [])
      @identifier = identifier
      @description = description
      @severity = severity
      @fixed_in = fixed_in
      @link = link
    end

    # The Defect has at least one released fix version
    #
    # @return [Boolean]
    def fix_available?
      fixed_in.any? { |v| v.version != Package::MAX_VERSION }
    end

    def filtered?(filter: :default, flag_filter: :default)
      return true if flag_filtered?(flag_filter)
      return false if filter == :default
      return !fix_available? if filter == :only_fixed

      raise UnknownFilterError, filter
    end

    def flagged?
      !flag.nil?
    end

    def flag_filtered?(filter)
      return !flag.nil? if filter == :default
      return false if flag == filter

      true
    end
  end
end

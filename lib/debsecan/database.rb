# frozen_string_literal: true

module Debsecan
  # A set of Defects that knows how to update itself.
  class Database
    include Enumerable

    class InitializationError < DebsecanError; end

    def initialize(strategy)
      @records = Hash.new { |h, k| h[k] = [] }
      @strategy = strategy
      raise InitializationError, 'Strategy did not update at initialize!' unless update
    end

    # @param key [String] Package name
    #
    # @return [Array<Debsecan::Defect>] if the package has any, an array of {Defect}s
    # @return [nil] if the package has no {Defect}s
    def [](key)
      @records[key]
    end

    # @param key [String] Package name
    #
    # @return [Boolean] true if at least one {Defect} exists for key
    def contains?(key)
      @records.key? key
    end

    # Iterate over all {Package}s in the database and their associated {Defect}s
    #
    # @yield [Iterator]
    def each(&block)
      @records.each(&block)
    end

    # @return [true] if strategy reports it has new content
    def update
      response = @strategy.update
      return false unless response.changed?
      @records.clear
      @records.merge!(response.content)
      true
    end
  end
end

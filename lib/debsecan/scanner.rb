# frozen_string_literal: true

require 'psych'

module Debsecan
  # Compares a {Database} and {Array<Package>} to discover what defects
  #   affect a system.
  class Scanner
    attr_reader :database, :packages, :results

    # @param packages [Array<Package>]
    # @param database [Database]
    def initialize(packages, database)
      @packages = packages
      @database = database

      file = File.join(File.expand_path(__dir__), 'flags.yml')
      @flags = Psych.load_file(file)
      @results = Hash.new { |h, k| h[k] = [] }
    end

    def packages=(arr)
      @results.clear
      @packages = arr
    end

    # Determine which packages are affected by which defects.
    #
    # @option [Symbol] :filter (:default) Flag filter to apply to results
    # @option [Boolean] :only_fixed (false) Check only defects which have
    #   fix versions available.
    #
    # @note Valid filters are:
    #   - :all to apply no filter at all to the results
    #   - :default to ignore results marked with any flag
    #   - :allowed to include only results flagged allowed
    #   - :whitelisted to include only results flagged whitelisted
    def scan(filter: :default, only_fixed: false)
      @results.clear
      packages.each do |package|
        @results.merge! scan_one(package, filter, only_fixed)
      end
      results
    end

    # For a given package, determine which packages affect it, if any.
    def scan_one(package, filter = :default, only_fixed = false)
      res = Hash.new { |h, k| h[k] = [] }
      defects_for(package).each do |defect|
        next if scan_filtered?(defect, filter, only_fixed)
        defect.fixed_in.each do |v|
          next unless defect_applies_for_scan?(package, v)
          res[package] << defect
        end
      end
      res
    end

    # Determine which defects are resolved by upgrading to a target version.
    #
    # Given:
    #   - A Package at version 1 and a target version of 3
    #   - A Defect, D1, with a fix version of 2
    #   - A Defect, D2, with a fix version of 3
    #   - A Defect, D3, with a fix version of 4
    #
    # Returns D1 and D2, but not D3.
    #
    # @note Packages that do not have a target version set are skipped.
    def fixed_by_target
      @results.clear
      packages.each do |package|
        next unless package.target
        @results.merge! one_fixed_by_target(package)
      end
      results
    end

    # For a specific package, determine which defects are resolved by upgrading
    # to its' target version.
    def one_fixed_by_target(package)
      res = Hash.new { |h, k| h[k] = [] }
      defects_for(package).each do |defect|
        next unless defect.fix_available?
        defect.fixed_in.each do |fix_version|
          next if target_filtered?(package, fix_version)
          res[package] << defect
        end
      end
      res
    end

    private

    def target_filtered?(package, fix_version)
      return true unless package.release == fix_version.release
      return true if package >= fix_version
      return true unless package.target_at_least?(fix_version)
    end

    FLAG_FILTERS = {
      all: ->(_d) { true },
      default: ->(d) { !flagged?(d) },
      allowed: ->(d) { defect_has_flag(d, :allowed) },
      whitelisted: ->(d) { defect_has_flag(d, :whitelist) }
    }.freeze

    def scan_filtered?(defect, filter, only_fixed)
      return true if only_fixed && !defect.fix_available?
      filter = select_filter(filter)
      !instance_exec(defect, &filter)
    end

    def defect_applies_for_scan?(package, fixed_version)
      package.release == fixed_version.release && package < fixed_version
    end

    def select_filter(filter)
      FLAG_FILTERS[filter] || FLAG_FILTERS[:default]
    end

    def flagged?(defect)
      @flags.map { |_k, v| v.key?(defect.identifier) }.reduce(&:|)
    end

    def defect_has_flag(defect, flag)
      return false unless @flags.key?(flag)
      @flags[flag].key?(defect.identifier)
    end

    def defects_for(package)
      @database.defects_for(package)
    end
  end
end

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
      filter = FLAG_FILTERS[filter] || FLAG_FILTERS[:default]
      @results.clear
      @packages.each do |package|
        pkg = source_or_package(package)

        name = package.name
        next unless @database.contains?(name)
        @database[name].each do |defect|
          next if only_fixed && !defect.fix_available?
          next unless instance_exec(defect, &filter)
          defect.fixed_in.each do |v|
            @results[package] << defect if pkg.release == v.release && pkg < v
          end
        end
      end
      @results
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
      @packages.each do |package|
        pkg = source_or_package(package)
        next unless pkg.target

        name = package.name
        next unless @database.contains?(name)
        @database[name].each do |defect|
          next unless defect.fix_available?

          defect.fixed_in.each do |fix_version|
            next unless pkg.release == fix_version.release
            next if pkg >= fix_version
            fixed_in_target = (fix_version.compare_to(pkg.target) <= 0)
            @results[package] << defect if fixed_in_target
          end
        end
      end
      @results
    end

    private

    FLAG_FILTERS = {
      all: ->(_d) { true },
      default: ->(d) { !flagged?(d) },
      allowed: ->(d) { defect_has_flag(d, :allowed) },
      whitelisted: ->(d) { defect_has_flag(d, :whitelist) }
    }.freeze

    def flagged?(defect)
      @flags.map { |_k, v| v.key?(defect.identifier) }.reduce(&:|)
    end

    def defect_has_flag(defect, flag)
      return false unless @flags.key?(flag)
      @flags[flag].key?(defect.identifier)
    end

    def source_or_package(package)
      return package unless package.source
      @packages.find { |p| p.name == package.source && p.release == package.release }
    end
  end
end

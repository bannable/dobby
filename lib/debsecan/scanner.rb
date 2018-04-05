# frozen_string_literal: true

module Debsecan
  # Compares a {Database} and {Array<Package>} to discover what defects
  #   affect a system.
  class Scanner
    attr_reader :database, :packages, :results

    FLAG_FILTER_ALL         = :all
    FLAG_FILTER_ALLOWED     = :allowed
    FLAG_FILTER_WHITELISTED = :whitelisted
    FLAG_FILTER_DEFAULT     = :default

    DEFECT_FILTER_DEFAULT   = :default
    DEFECT_FILTER_FIXED     = :only_fixed

    VERSION_FILTER_TARGET   = :target
    VERSION_FILTER_DEFAULT  = :default

    # @param packages [Array<Package>]
    # @param database [Database]
    def initialize(packages, database)
      @packages = packages
      @database = database

      @results = Hash.new { |h, k| h[k] = [] }
    end

    # Whenever the package set the scanner is configured with change,
    # the stored results will be wiped.
    def packages=(arr)
      @results.clear
      @packages = arr
    end

    # Determine which packages are affected by which defects.
    #
    # @option [Symbol] :defect_filter {DEFECT_FILTER_DEFAULT}
    #   - {DEFECT_FILTER_DEFAULT}
    #       Apply no special filters to defects in the database
    #   - {DEFECT_FILTER_FIXED}
    #       Only include defects that have a fix available
    # @option [Symbol] :flag_filter {FLAG_FILTER_DEFAULT}
    #   - {FLAG_FILTER_ALL}
    #       Apply no filter at all to the results
    #   - {FLAG_FILTER_DEFAULT}
    #       Ignore results marked with any flag
    #   - {FLAG_FILTER_ALLOWED}
    #       Include only results flagged allowed
    #   - {FLAG_FILTER_WHITELISTED}
    #       Include only results flagged whitelisted
    # @option [Symbol] :version_filter {VERSION_FILTER_DEFAULT}
    #   - {VERSION_FILTER_DEFAULT}
    #       For a given package and defect, ensure that the release of the defect's
    #       fix versions match the package and that the version of the package
    #       is less than the fix version
    #   - {VERSION_FILTER_TARGET}
    #       See {#scan_by_target} for more information on how this complex filter behaves.
    #
    # Order of filter processing, from first to last:
    #   1. Flag
    #   2. Defect
    #   3. Version
    def scan(defect_filter: DEFECT_FILTER_DEFAULT,
             flag_filter: FLAG_FILTER_DEFAULT,
             version_filter: VERSION_FILTER_DEFAULT)
      @results.clear
      packages.each do |package|
        scan_results = scan_one(package: package,
                                defect_filter: defect_filter,
                                flag_filter: flag_filter,
                                version_filter: version_filter)
        @results.merge! scan_results
      end
      results
    end

    # For a given package, determine which packages affect it, if any.
    def scan_one(package:,
                 defect_filter: DEFECT_FILTER_DEFAULT,
                 flag_filter: FLAG_FILTER_DEFAULT,
                 version_filter: VERSION_FILTER_DEFAULT)
      res = Hash.new { |h, k| h[k] = [] }
      database.defects_for(package).each do |defect|
        next if defect.filtered?(filter: defect_filter, flag_filter: flag_filter)
        defect.fixed_in.each do |v|
          next if package.filtered?(v, version_filter)
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
    # This is a use-specific wrapper around {#scan}
    #
    # @note Packages that do not have a target version set are skipped.
    def scan_by_target
      scan(defect_filter: DEFECT_FILTER_FIXED,
           flag_filter: FLAG_FILTER_DEFAULT,
           version_filter: VERSION_FILTER_TARGET)
    end

    # For a specific package, determine which defects are resolved by upgrading
    # to its' target version.
    #
    # This is a use-specific wrapper around {scan_one}
    #
    # @param [Package]
    def scan_one_by_target(package)
      scan_one(package: package,
               defect_filter: DEFECT_FILTER_FIXED,
               flag_filter: FLAG_FILTER_DEFAULT,
               version_filter: VERSION_FILTER_TARGET)
    end
  end
end

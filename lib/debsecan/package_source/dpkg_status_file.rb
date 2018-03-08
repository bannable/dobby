# frozen_string_literal: true

module Debsecan
  module PackageSource
    # Defines a strategy for creating a {Package} array from /var/lib/dpkg/status
    # or a similarly formatted file.
    class DpkgStatusFile < AbstractPackageSource
      args %(file_path dist release)

      option :file_path, '/var/lib/dpkg/status'
      option :dist, 'Debian'
      option :release, Dpkg.code_name

      # A Dpkg section has unexpected formatting
      class DpkgFormatError < DebsecanError; end

      # @return [Array<Package>]
      def parse
        packages = []
        File.read(options.file_path).split("\n\n").each do |section|
          begin
            packages << package_from_section(section)
          rescue Package::FieldRequiredError => e
            # If the Version field is missing, this is probably a virtual
            # or meta-package (e.g. little-table-dev) - Skip it. Name and
            # release should never be missing, so reraise the error in those
            # cases.
            next if e.field == 'version'
            raise
          end
        end
        packages
      end

      private

      # @param section [String]
      # @return [Package]
      # @raise [FormatError]
      def package_from_section(section)
        pkg = {}
        field = nil

        section.each_line do |line|
          line.chomp!
          if /^\s/ =~ line
            raise FormatError, "Unexpected whitespace at start of line: '#{line}'" unless field
            pkg[field] += "\n" + line
          elsif /(^\S+):\s*(.*)/ =~ line
            field = Regexp.last_match(1).capitalize
            if pkg.key?(field)
              raise FormatError, "Unexpected duplicate field '#{field}' in line '#{line}'"
            end
            value = Regexp.last_match(2).strip
            value = value.split[0] if field == 'Source'
            pkg[field] = value
          end
        end
        Package.new(
          name: pkg['Package'],
          version: pkg['Version'],
          dist: options.dist,
          release: options.release,
          arch: pkg['Architecture'],
          source: pkg['Source'],
          multiarch: pkg['Multi-Arch']
        )
      end
    end
  end
end

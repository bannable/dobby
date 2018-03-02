# frozen_string_literal: true

module Debsecan
  # A Package describes a particular Debian package installation.
  # Debsecan::Package is adapted from Debian::Deb and Debian::Field
  #   source: https://anonscm.debian.org/cgit/pkg-ruby-extras/ruby-debian.git/tree/lib/debian.rb
  class Package
    # MaxVersion is a special value which is always sorted first.
    MAX_VERSION = '|MAX|'

    # MinVersion is a special value which is always sorted last.
    MIN_VERSION = '|MIN|'

    # A required field was missing during initialization
    class FieldRequiredError < DebsecanError
      attr_reader :args, :field
      def initialize(field)
        super("Missing required field '#{field}'")
        @field = field
      end
    end

    attr_reader :name
    attr_reader :version
    attr_reader :source
    attr_reader :dist
    attr_reader :release
    attr_reader :arch
    attr_reader :target

    # Set up a new Debian Package
    #
    # @param name [String] Package name
    # @param version [String] Package version
    # @param source [String] Name of the source package, if applicable
    #
    # @raise [FieldRequiredError] if initialized without name or version
    def initialize(name:, version:, release:, dist: nil, arch: nil, source: nil, target: nil)
      raise FieldRequiredError, 'name' unless name
      raise FieldRequiredError, 'version' unless version
      raise FieldRequiredError, 'release' unless release

      @name = name
      @version = version
      @source = source
      @dist = dist
      @release = release
      @arch = arch
      @target = target
    end

    # @return [String] String representation of the package.
    def to_s
      "#{@name} #{@version}"
    end

    # rubocop:disable Style/CaseEquality

    # @param other [Package]
    #
    # @return [Boolean] True if other is present and other.package is the same as self.package
    def ===(other)
      other && name == other.name
    end

    # @param other [Package]
    # @return [Boolean] True if self === other and self.version is less than other.version
    def <(other)
      self === other && compare_to(other.version) < 0
    end

    # @param other [Package]
    # @return [Boolean] True if self === other and self.version is less than or
    #   equal to other.version
    def <=(other)
      self === other && compare_to(other.version) <= 0
    end

    # @param other [Package]
    # @return [Boolean] True if self === other and self.version equals other.version
    def ==(other)
      self === other && compare_to(other.version) == 0
    end

    # @param other [Package]
    # @return [Boolean] True if self === other and self.version is greater than or
    #   equal to other.version
    def >=(other)
      self === other && compare_to(other.version) >= 0
    end

    # @param other [Package]
    # @return [Boolean] True if self === other and self.version is greater than other.version
    def >(other)
      self === other && compare_to(other.version) > 0
    end

    # @param other [Package]
    # @return [Boolean] True if self === other and self.version does not equal other.version
    def !=(other)
      self === other && compare_to(other.version) != 0
    end

    # rubocop:enable Style/CaseEquality

    # This method is wrapped by the standard comparison operators, but is provided for cases where
    #   it is not practical to compare two Package objects.
    #
    # @param other [String] Version string
    # @return [Integer]
    def compare_to(other)
      return 0 if version == other
      return -1 if version == MIN_VERSION || other == MAX_VERSION
      return 1 if version == MAX_VERSION || other == MIN_VERSION
      Debian::AptPkg.cmp_version(version, other)
    end
  end
end

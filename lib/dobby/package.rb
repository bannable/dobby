# frozen_string_literal: true

module Dobby
  # A Package describes a particular Debian package installation.
  # Dobby::Package is adapted from Debian::Deb and Debian::Field
  #   source: https://anonscm.debian.org/cgit/pkg-ruby-extras/ruby-debian.git/tree/lib/debian.rb
  class Package
    # MaxVersion is a special value which is always sorted first.
    MAX_VERSION = '|MAX|'

    # MinVersion is a special value which is always sorted last.
    MIN_VERSION = '|MIN|'

    # A required field was missing during initialization
    class FieldRequiredError < Error
      attr_reader :args, :field
      def initialize(field)
        super("Missing required field '#{field}'")
        @field = field
      end
    end

    attr_reader :name
    attr_reader :version
    attr_reader :release
    attr_reader :source
    attr_reader :dist
    attr_reader :arch
    attr_reader :target
    attr_reader :multiarch

    # Set up a new Debian Package
    #
    # @param name [String] Package name
    # @param version [String] Package version
    # @param source [String] Name of the source package, if applicable
    #
    # @raise [FieldRequiredError] if initialized without name or version
    def initialize(name:, version:, release:, dist: nil, arch: nil, source: nil,
                   target: nil, multiarch: nil)
      raise FieldRequiredError, 'name' unless name
      raise FieldRequiredError, 'version' unless version
      raise FieldRequiredError, 'release' unless release
      raise FieldRequiredError, 'arch' if arch.nil? && multiarch == 'same'

      @name = name
      @version = version
      @source = source
      @dist = dist
      @release = release
      @arch = arch
      @target = target
      @multiarch = multiarch
    end

    # When a package has multiarch set to same, dpkg and apt will know of it by
    # a name such as 'libquadmath0:amd64' instead of 'libquadmath0'. In these cases,
    # return the name alongside the architecture to make it easier to act on results.
    def apt_name
      return name unless multiarch == 'same'

      "#{name}:#{arch}"
    end

    # Compared to some other {Package}, should this Package be filtered from results?
    #
    # If filter is set to :default, return true if releases do not match or if my
    # version is at least the other package's version.
    #
    # If filter is set to :target, addtionally return true if my target version is
    # at least the other's version.
    #
    # @param other [Package]
    # @param filter [Symbol]
    #
    # @raise [UnknownFilterError] when given an unknown value for filter
    def filtered?(other, filter = :default)
      return true if release != other.release || self >= other
      return target_at_least?(other) if filter == :target
      return false if filter == :default

      raise UnknownFilterError, filter
    end

    # @return [String] String representation of the package.
    def to_s
      "#{apt_name} #{version}"
    end

    # @param version [Package]
    #
    # @return [Boolean] True if the target version meets or exceeds the provided
    #   package version
    def target_at_least?(version)
      !target.nil? && version.compare_to(target.to_s) <= 0
    end

    # @param other [Package]
    #
    # @return [Boolean] True if other is present and other.package is the same as self.package
    def ===(other)
      other && (name == other.name || source == other.name || name == other.source)
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
      self === other && compare_to(other.version).zero?
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

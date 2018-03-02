# frozen_string_literal: true

module Debsecan
  # Standardized definitions for severity categories
  module Severity
    # Implements a custom <=> method so that severities can be sorted as
    # we see fit. In particular, these objects sort based on their index
    # in the {SEVERITIES} array.
    class Severity
      attr_reader :value
      def initialize(value)
        @value = value
      end

      def to_s
        @value
      end

      def ==(other)
        value == other.value
      end

      def <=>(other)
        return 0 if other == self
        return -1 if SEVERITIES.index(self) < SEVERITIES.index(other)
        1
      end

      def <(other)
        SEVERITIES.index(self) < SEVERITIES.index(other)
      end
    end

    # A defect which has not yet been assigned a priority or we do not have
    # a translation for.
    Unknown = Severity.new('Unknown')

    # Technically a security issue, but has no real damage, extremely strict
    # requirements, or other constraints that nullify impact.
    Negligible = Severity.new('Negligible')

    # Security problem, but difficult to exploit, requires user assistance
    # or does very little damage.
    Low = Severity.new('Low')

    # "Real" security problem that is generally exploitable.
    Medium = Severity.new('Medium')

    # Real "problem", that is generally exploitable in a default configuration.
    High = Severity.new('High')

    # The world is on fire, send help!
    Critical = Severity.new('Critical')

    # All severities in an ordered list
    SEVERITIES = [
      Unknown,
      Negligible,
      Low,
      Medium,
      High,
      Critical
    ].freeze
  end
end

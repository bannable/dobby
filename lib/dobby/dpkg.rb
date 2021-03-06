# frozen_string_literal: true

module Dobby
  # Generic Debian dpkg helper methods
  module Dpkg
    # Default location of the dpkg binary
    DPKG = '/usr/bin/dpkg'
    # Default location of the lsb_release binary
    LSBR = '/usr/bin/lsb_release'

    # @return [String] Debian codename for this system
    def self.code_name
      `#{LSBR} -sc`.chomp!
    end

    # @return [String] System architecture
    def self.architecture
      `#{DPKG} --print-architecture`.chomp!
    end
  end
end

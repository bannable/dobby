# frozen_string_literal: true

module Dobby
  # Dobby version information.
  module Version
    STRING = '0.1.0'
    MSG = '%<version>s (AptPkg %<aptpkg_version>s Apt %<apt_version>s '\
          'libapt %<libapt_version>s) running on %<linux_version>s '\
          '%<ruby_engine>s %<ruby_version>s %<ruby_platform>s'

    def self.version(debug = false)
      if debug
        format(MSG, version: STRING, aptpkg_version: Debian::AptPkg::VERSION,
                    apt_version: Debian::AptPkg::APT_VERSION,
                    libapt_version: Debian::AptPkg::LIBAPT_PKG_VERSION,
                    linux_version: Etc.uname[:version],
                    ruby_engine: RUBY_ENGINE, ruby_version: RUBY_VERSION,
                    ruby_platform: RUBY_PLATFORM)
      else
        STRING
      end
    end
  end
end

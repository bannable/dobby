# frozen_string_literal: true

module Dobby
  # Contains information about dobby-provided strategies.
  module Builtins
    PACKAGE_SOURCES = {
      'dpkg' => PackageSource::DpkgStatusFile
    }.freeze

    VULN_SOURCES = {
      'debian' => VulnSource::Debian,
      'ubuntu' => VulnSource::Ubuntu
    }.freeze

    ALL = PACKAGE_SOURCES.values | VULN_SOURCES.values
  end
end

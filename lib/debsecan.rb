# frozen_string_literal: true

require 'debsecan/version'

# Library for injesting descriptions of dpkg based systems (primarily Debian
# and Ubuntu), vulnerability databases for those distributions and identfying
# which installed packages are subject to which vulnerability defects (if any).
module Debsecan
  autoload :Configuration,  'debsecan/configuration'
  autoload :FlagManager,    'debsecan/flag_manager'
  autoload :Database,       'debsecan/database'
  autoload :Strategy,       'debsecan/strategy'
  autoload :Severity,       'debsecan/severity'
  autoload :Package,        'debsecan/package'
  autoload :Scanner,        'debsecan/scanner'
  autoload :Defect,         'debsecan/defect'
  autoload :Dpkg,           'debsecan/dpkg'

  module PackageSource
    autoload :AbstractPackageSource, 'debsecan/package_source/abstract_package_source'
    autoload :DpkgStatusFile,        'debsecan/package_source/dpkg_status_file'
  end

  module VulnSource
    autoload :AbstractVulnSource,    'debsecan/vuln_source/abstract_vuln_source'
    autoload :Debian,                'debsecan/vuln_source/debian'
    autoload :Ubuntu,                'debsecan/vuln_source/ubuntu'
  end

  class DebsecanError < StandardError; end

  # A generic response format.
  class UpdateResponse
    attr_reader :content
    # @param changed [Boolean]
    # @param content [Hash]
    def initialize(changed, content = nil)
      @changed = changed
      @content = content
    end

    # @return [Boolean]
    def changed?
      @changed == true
    end
  end

  # All available Package and Database strategies available to the library.
  #
  # @return [Array<Object>]
  def self.strategies
    @strategies ||= []
  end

  def self.config
    Configuration.instance
  end

  def self.configure
    yield config
  end

  def self.logger
    config.logger
  end

  WHEEZY = 'wheezy'
  XENIAL = 'xenial'
end

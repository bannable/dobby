# frozen_string_literal: true

module Dobby
  module VulnSource
    # Vulnerability database source for Debian systems. This uses the JSON file
    # provided by the Debian Security Tracker as its' remote source.
    class Debian < AbstractVulnSource
      DEFAULT_RELEASE = 'jessie'

      args %i[releases source url_prefix]

      option :test_mode, false
      option :releases, [DEFAULT_RELEASE]
      option :source, 'https://security-tracker.debian.org/tracker/data/json'
      option :url_prefix, 'https://security-tracker.debian.org/tracker/'

      # Map of DST-provided urgencies to a common severity format
      URGENCY_MAP = Hash.new(Severity::Unknown).merge(
        'not-yet-assigned' => Severity::Unknown,
        'end-of-life'      => Severity::Negligible,
        'unimportant'      => Severity::Negligible,
        'low'              => Severity::Low,
        'low*'             => Severity::Low,
        'low**'            => Severity::Low,
        'medium'           => Severity::Medium,
        'medium*'          => Severity::Medium,
        'medium**'         => Severity::Medium,
        'high'             => Severity::High,
        'high*'            => Severity::High,
        'high**'           => Severity::Critical
      )

      # Unable to retrieve or load a dobby database
      class NoDataError < Error; end

      # Received a non-200 response from the Security Tracker
      class BadResponseError < Error
        attr_accessor :curl

        def initialize(curl)
          url = curl.url
          url_path_only = url =~ /\A([^?]*)\?/ ? Regexp.last_match(1) : url
          super("Bad response code (#{curl.response_code.to_i} for #{url_path_only})")
          @curl = curl
        end

        # @return [Hash{resp_code=>Integer, url=>String, resp=>String}]
        def context
          { resp_code: @curl.response_code, url: @curl.url, resp: @curl.body_str }
        end
      end
      ###

      def initialize(*args)
        @last_hash = nil
        super
      end

      # Provide an UpdateResponse sourced from the Debian Security Tracker's
      # JSON. If the SHA256 of the returned JSON matches the last attempt,
      # UpdateResponse.changed? will be false. Otherwise, UpdateResponse.content
      # will be a Hash{package_name=>Array<Defect>}
      #
      # @return [UpdateResponse]
      def update
        data = fetch_from_remote(options.source)

        hash = Digest::SHA256.hexdigest(data)
        return UpdateResponse.new(false) if hash == @last_hash

        debian_vulns = Oj.load(data)

        vuln_entries = Hash.new { |h, k| h[k] = [] }
        debian_vulns.each do |package, vulns|
          vulns.each do |identifier, vuln|
            # If a permanent ID has not been assigned to the vuln, skip it
            next unless identifier.start_with?('CVE-', 'OVE-')

            severity = Severity::Unknown
            fixed_versions = []

            vuln['releases'].each do |release, info|
              next unless options.releases.include?(release)

              version = choose_version(info['fixed_version'], info['status'])
              next unless version

              # For a given Defect, it may have differing severities across
              # different Debian releases. Set the severity of the Defect to
              # the highest value.
              new_severity = URGENCY_MAP[info['urgency']]
              severity = new_severity if severity < new_severity

              fixed_versions << Package.new(
                name: package,
                version: version,
                release: release
              )
            end

            vuln_entries[package] << Defect.new(
              identifier: identifier,
              description: vuln['description'],
              severity: severity,
              fixed_in: fixed_versions,
              link: options.url_prefix + identifier
            )
          end
        end
        @last_hash = hash
        UpdateResponse.new(true, vuln_entries)
      end

      # Given a 'fixed in' version and a defect status, determine what version
      # represents the status for comparison.
      #
      # @param fixed [String] version that the vuln src says a defect is fixed in
      # @param status [String] the current status of the defect
      #
      # @return [String] version string
      def choose_version(fixed, status)
        return unless status
        return Package::MIN_VERSION if fixed == '0'
        return Package::MAX_VERSION if status == 'open'
        return fixed if status == 'resolved'

        nil
      end

      # Retrieve the DST json file
      #
      # @param url [String]
      #
      # @return [String]
      #
      # @raise [BadResponseError] if url returns something other than 200
      # @raise [NoDataError] if url returns no data
      def fetch_from_remote(url)
        return File.read(url) if options.test_mode

        curl = Curl::Easy.perform(url)
        raise BadResponseError, curl unless curl.response_code.to_i == 200
        raise NoDataError unless curl.body_str

        curl.body_str
      end
    end
  end
end

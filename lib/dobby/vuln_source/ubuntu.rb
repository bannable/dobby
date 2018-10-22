# frozen_string_literal: true

module Dobby
  module VulnSource
    # Vulnerability source for Ubuntu systems. This class uses the Ubuntu CVE
    # Tracker as its' remote source by checking out the bazaar repository.
    #
    # @note This requires bazaar to be installed at /usr/bin/bzar unless
    #   configured with a different path via the bzr option.
    class Ubuntu < AbstractVulnSource
      DEFAULT_RELEASE = 'xenial'
      args %i[releases local_repo_path url_prefix bzr tracker_uri tracker_repo]

      option :releases, [DEFAULT_RELEASE]

      # The actual repository
      option :bzr, '/usr/bin/bzr'
      option :url_prefix, 'http://people.ubuntu.com/~ubuntu-security/cve/'
      option :tracker_uri, 'https://launchpad.net/ubuntu-cve-tracker'
      option :tracker_repo, 'https://launchpad.net/ubuntu-cve-tracker'

      # Map of Canonical-provided urgencies to a common severity format
      URGENCY_MAP = Hash.new(Severity::Unknown).merge(
        'untriaged'  => Severity::Unknown,
        'negligible' => Severity::Negligible,
        'low'        => Severity::Low,
        'medium'     => Severity::Medium,
        'high'       => Severity::High,
        'critical'   => Severity::Critical
      )

      # An array of defect states that we are interested in. Skips e.g. ignored/DNE
      RELEVANT_STATUSES = %w[needed active deferred not-affected released].freeze

      # Line prefixes which indicate the end of a defect description
      DESC_STOP_FIELDS = %w[
        Ubuntu-Description:
        Priority:
        Discovered-By:
        Notes:
        Bugs:
        Assigned-to:
      ].freeze

      # A hash with DeepMerge
      class VulnerabilityHash < Hash
        include Hashie::Extensions::DeepMerge
      end

      def initialize(*args)
        @last_revno = nil
        super
      end

      # Provide an UpdateReponse sourced from Canoncial's Ubuntu CVE Tracker
      # repository. This is a bazaar repository, and thus this strategy depends
      # on the bzr binary being available. The strategy will avoid descending
      # the repository if the repo's revno matches a previous revno.
      #
      # @return [UpdateResponse]
      def update
        branch_or_pull
        revno = bzr_revno
        return UpdateResponse.new(false) if revno == @last_revno

        vuln_entries = VulnerabilityHash.new
        modified_entries.each do |file|
          data = parse_ubuntu_cve_file(File.readlines(file))
          vuln_entries.deep_merge!(data)
        end
        @last_revno = revno
        UpdateResponse.new(true, vuln_entries)
      end

      # Delete the bzr repository
      def clean
        Dir.rmdir(options.local_repo_path)
      end

      private

      # Determine whether the repo needs to be branched (because it doesn't
      # exist) or pulled (because it already exists), and then do that.
      #
      # @return [Boolean]
      def branch_or_pull
        if Dir.exist?(options.local_repo_path)
          pull(options.local_repo_path)
        else
          branch(options.local_repo_path)
        end
      end

      def branch(path)
        FileUtils.mkdir_p path
        Dir.chdir(path) do
          return system(options.bzr.to_s, 'branch', '--use-existing-dir',
                        options.tracker_repo.to_s, '.')
        end
      end

      def pull(path)
        Dir.chdir(path) do
          return system(options.bzr.to_s, 'pull', '--overwrite')
        end
      end

      # Retrieve bazaar revision number
      #
      # @return [String]
      def bzr_revno
        stdout, = Open3.capture2(options.bzr, 'revno', options.local_repo_path)
        stdout.strip
      end

      # Returns a list of all interesting files in the bazaar repository.
      #
      # @note The library cannot currently support differential updates :(
      #
      # @return [Array<String>]
      def modified_entries
        search = File.join(options.local_repo_path, '{active,retired}', '**', 'CVE*')
        Dir.glob(search)
      end

      def parse_ubuntu_cve_file(file_lines)
        entries = Hash.new { |h, k| h[k] = {} }
        fixed_versions = Hash.new { |h, k| h[k] = [] }
        severity = Severity::Unknown

        identifier = description = link = nil
        more = false

        file_lines.each do |line|
          line.chomp!
          next if line.start_with?('#') || line.empty?

          if line.start_with?('Candidate:')
            identifier = line.split[1]
            link = options.url_prefix + identifier
            next
          elsif line.start_with?('Priority:')
            severity = URGENCY_MAP[line.split[1]]
            next
          elsif line.start_with?('Description:')
            more = true
            check = line.split(' ', 2)
            description = check[1] if check.count > 1
            next
          elsif more
            if line.start_with?(*DESC_STOP_FIELDS)
              description.strip!
              more = false
            else
              description = description + ' ' + line.strip
            end
            next
          end

          # Separate release, package status and version information out of a
          # defect detail line.
          #
          # Example line -
          #   xenial_linux: released (4.4.0-81.104)

          # rubocop:disable Metrics/LineLength
          next unless /(?<release>.*)_(?<package>.*): (?<status>[^\s]*)( \(+(?<note>[^()]*)\)+)?/ =~ line
          # rubocop:enable Metrics/LineLength

          next unless RELEVANT_STATUSES.include?(status)

          release = release.split('/')[0]
          next unless options.releases.include?(release)

          version = choose_version(note, status)
          fixed_versions[package] << Package.new(
            name: package,
            version: version,
            release: release
          )
        end

        fixed_versions.each do |package, versions|
          entries[package] = Defect.new(
            identifier: identifier,
            description: description,
            severity: severity,
            fixed_in: versions,
            link: link
          )
        end
        entries
      end

      # Given a 'fixed in' version and a defect status, determine what version
      # represents the status for comparison.
      #
      # If status is released, this simply returns the fixed argument.
      # If status is not-affected, {Package::MIN_VERSION} is returned.
      # If status is some other value, {Package::MAX_VERSION} is returned and the
      #   defect is considered to apply to all versions.
      #
      # @param fixed [String] version that the vuln src says a defect is fixed in
      # @param status [String] the current status of the defect
      #
      # @return [String] version string
      def choose_version(fixed, status)
        return fixed if status == 'released'
        return Package::MIN_VERSION if status == 'not-affected'

        Package::MAX_VERSION
      end
    end
  end
end

# frozen_string_literal: true

require File.expand_path('lib/debsecan/version', __dir__)

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |spec|
  spec.name          = 'debsecan'
  spec.version       = Debsecan::Version::STRING
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Joe Truba']
  spec.email         = ['jtruba@meraki.net', 'joe@bannable.net']

  spec.summary       = 'Vulnerability reporter for dpkg systems'
  spec.description   = <<-DESCRIPTION
    Library for injesting descriptions of dpkg based systems (primarily
    Debian and Ubuntu), vulnerability database for those distributions and identifying
    which installed packages are impacted by which vulnerability defects, if any.
  DESCRIPTION

  spec.homepage      = 'https://github.com/meraki/debsecan/'
  spec.license       = 'MIT'

  spec.required_ruby_version = ['~> 2', '>= 2.2']

  spec.metadata = {
    'changelog_uri' => 'https://github.com/meraki/debsecan/blob/master/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/meraki/debsecan/',
    'bug_tracker_uri' => 'https://github.com/meraki/debsecan/issues'
  }

  spec.bindir        = 'exe'
  spec.executables   = 'debsecan'
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.52'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'timecop', '~> 0.9'
  spec.add_development_dependency 'webmock', '~> 3.4'

  spec.add_runtime_dependency 'apt-pkg', ['~> 0.4', '>= 0.2']
  spec.add_runtime_dependency 'curb', '~> 0.9'
  spec.add_runtime_dependency 'hashie', '~> 3.5'
  spec.add_runtime_dependency 'oj'
  spec.add_runtime_dependency 'parallel', '~> 1.12'
  spec.add_runtime_dependency 'powerpack', '~> 0.1'
  spec.add_runtime_dependency 'pry'
  spec.add_runtime_dependency 'pry-byebug'
  spec.add_runtime_dependency 'rainbow', '~> 3'
  spec.add_runtime_dependency 'ruby-progressbar', '~> 1.10'
  spec.add_runtime_dependency 'yard', '~> 0.9.16'

  spec.requirements << 'libapt-pkg-dev > 1.0'
  spec.requirements << 'bzr (when using VulnSource::Ubuntu)'
end
# rubocop:enable Metrics/BlockLength

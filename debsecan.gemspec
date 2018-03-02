# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'debsecan/version'

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |spec|
  spec.name          = 'debsecan'
  spec.version       = Debsecan::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Joe Truba']

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

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'awesome_print', '~> 1.8'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.52'
  spec.add_development_dependency 'timecop', '~> 0.9'

  spec.add_dependency 'apt-pkg', ['~> 0.4', '>= 0.2']
  spec.add_dependency 'curb', '~> 0.9'
  spec.add_dependency 'hashie', '~> 3.5'
  spec.add_dependency 'psych', '~> 3.0'
  spec.add_dependency 'yard', '~> 0.9'

  spec.requirements << 'libapt-pkg-dev > 1.0'
  spec.requirements << 'bzr (when using VulnSrcUbuntu)'
end
# rubocop:enable Metrics/BlockLength

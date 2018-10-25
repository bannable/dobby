# Dobby

Static analyzer library for DPKG-versioned packages.

This tool takes a set of versioned packages and compares those versions against
a source of version vulnerability information. The tool can implement arbitrary
strategies to this end, and at Meraki helps to answer these questions:

>On the current system or across all of our servers, which packages on those servers
>are impacted by published vulnerabilities?

>Of the packages with published vulnerabilities, which have fix versions currently
>available in the repository upstream, and what are those fix versions for each
>distribution?

>If a process is running version 1 of a service, and version 2 is installed
>on the system, which vulnerabilities (if any) are addressed by a service restart?

For building the package set, included is `DpkgStatusFile`, which by default builds
a package set from `/var/lib/dpkg/status`, but can read and parase any similarly
formatted file.

For vulnerability information source, two strategies are included:
* `VulnSource::Debian`: Retrieve CVE/etc information from the Debian Security Tracker.
* `VulnSource::Ubuntu`: Checkout and parse the Ubuntu Security Tracker using bzr.

Initializing the vulnerability database can be expensive in time, bandwidth
and space. It is recommended that you initialize only a single vulnerability
database for processing multiple package sets.

## Usage

As a gem:
```ruby
require 'dobby'
package_set = []
[file1, file2].each do |f|
  package_set << Dobby::PackageSource::DpkgStatusFile.new(file_path: f)
end

strategy = Dobby::VulnSource::Debian.new
database = Dobby::Database.new(strategy)
scanner = Dobby::Scanner.new(nil, database)

package_set.each do |package_source|
  packages = package_source.parse
  scanner.packages = packages
  puts scanner.scan
end
```

From the command line:
```
# Output issues for the current system as pretty text to stdout
dobby /var/lib/dpkg/status

# ... and also write issues as JSON to file.json
dobby -f simple -f json -o file.json /var/lib/dpkg/status

# Show issues for multiple files
dobby file1 file2 file3
```

As a gem with a custom output formatter:
```ruby
# my_custom_executor.rb
require 'dobby'
require 'my/custom/formatter'

cli = Dobby::CLI.new
cli.run

# CLI:
my_custom_executor.rb -f My::Custom::Formatter /var/lib/dpkg/status
```

## Compatibility

Dobby supports the following Ruby implementations:

* MRI 2.2
* MRI 2.3
* MRI 2.4
* MRI 2.5
* MRI trunk

## Building

```
rake build
```

## Contributing

If you have found a bug or have a feature idea, take a look at the [contribution guidelines](CONTRIBUTING.md).

## Changelog

The changelog is available [here](CHANGELOG.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

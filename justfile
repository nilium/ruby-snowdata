[positional-arguments]
install *args: build
    gem uninstall snow-data --version "$(just version)"
    gem install "$@" "snow-data-$(just version).gem"

build:
    rm -fv "snow-data-$(just version).gem"
    gem build

version:
    #!/usr/bin/env ruby
    require File.expand_path('lib/snow-data/version.rb', Dir.pwd)
    $stdout.write Snow::SNOW_DATA_VERSION

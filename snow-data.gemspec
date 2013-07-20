# This file is part of ruby-snowdata.
# Copyright (c) 2013 Noel Raymond Cower. All rights reserved.
# See COPYING for license details.

require File.expand_path('../lib/snow-data/version.rb', __FILE__)

Gem::Specification.new { |s|
  s.name        = 'snow-data'
  s.version     = Snow::SNOW_DATA_VERSION
  s.date        = '2013-07-20'
  s.summary     = "Snow-Data: for working with memory like you've got nothing to lose."
  s.description = <<-EOS
Snow-Data is a gem for allocating memory and working with existing blocks of
memory in a moderately safe but still technically really, really unsafe way. It
also provides functionality for defining C-struct classes, including those with
other structs as members.
  EOS
  s.authors     = [ 'Noel Raymond Cower' ]
  s.email       = 'ncower@gmail.com'
  s.files       = Dir.glob('lib/**/*.rb') +
                  Dir.glob('ext/**/*.{c,h,rb}') +
                  [ 'COPYING', 'README.md' ]
  s.extensions << 'ext/extconf.rb'
  s.homepage    = 'https://github.com/nilium/ruby-snowdata'
  s.license     = 'Simplified BSD'
  s.has_rdoc    = true
  s.extra_rdoc_files = [
      'ext/snow-data/snow-data.c',
      'README.md',
      'COPYING'
  ]
  s.rdoc_options << '--title' << 'snow-data -- C Data Types' <<
                    '--main' << 'README.md' <<
                    '--markup=markdown' <<
                    '--line-numbers'
  s.required_ruby_version = '>= 2.0.0'
}

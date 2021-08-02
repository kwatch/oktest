#!/usr/bin/ruby
# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $License: MIT License $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
###

require 'rubygems'

Gem::Specification.new do |s|
  ## package information
  s.name        = "oktest"
  s.author      = "kwatch"
  s.email       = "kwatch@gmail.com"
  s.version     = "$Release: 0.0.0 $".split()[1]
  s.license     = "MIT"
  s.platform    = Gem::Platform::RUBY
  s.homepage    = "https://github.com/kwatch/oktest/tree/ruby"
  s.summary     = "new style testing library"
  s.description = <<'END'
Oktest.rb is a new-style testing library for Ruby.

* `ok {actual} == expected` style assertion
* smart fixture similar to dependency injection
* structured test specifications
END

  ## files
  files = Dir['lib/oktest.rb', 'test/*.rb']
  files += ['README.md', 'MIT-LICENSE', 'oktest.gemspec', 'Rakefile.rb']
  s.files       = files
  s.executables = ['oktest']
  s.bindir      = 'bin'
  s.test_file   = 'test/run_all.rb'
end

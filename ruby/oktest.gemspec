# -*- coding: utf-8 -*-

###
### $Release: 1.2.1 $
### $License: MIT License $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
###

require 'rubygems'

Gem::Specification.new do |s|
  ## package information
  s.name        = "oktest"
  s.author      = "kwatch"
  s.email       = "kwatch@gmail.com"
  s.version     = "$Release: 1.2.1 $".split()[1]
  s.license     = "MIT"
  s.platform    = Gem::Platform::RUBY
  s.homepage    = "https://github.com/kwatch/oktest/tree/ruby"
  s.summary     = "new style testing library"
  s.description = <<'END'
Oktest.rb is a new-style testing library for Ruby.

* `ok {actual} == expected` style assertion.
* **Fixture injection** inspired by dependency injection.
* Structured test specifications like RSpec.
* Filtering testcases by pattern or tags.
* Blue/red color instead of green/red for accesability.
* Small code size (about 2300 lines) and good performance.

See https://github.com/kwatch/oktest/tree/ruby/ruby for details.
END
  s.required_ruby_version = ">= 2.0"
  s.add_dependency "diff-lcs", "~> 1.0"
  s.add_dependency "benry-recorder", "~> 1.0"

  ## files
  files = Dir['lib/oktest.rb', 'test/*.rb']
  files += ['README.md', 'MIT-LICENSE', 'oktest.gemspec', 'Rakefile.rb']
  files += ['benchmark/Rakefile.rb', 'benchmark/run_all.rb']
  s.files       = files
  s.executables = ['oktest']
  s.bindir      = 'bin'
  s.test_file   = 'test/run_all.rb'
end

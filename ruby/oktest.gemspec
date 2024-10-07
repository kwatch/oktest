# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $License: MIT License $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
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
  s.homepage    = "https://github.com/kwatch/oktest/tree/ruby/ruby"
  s.summary     = "a new style testing library"
  s.description = <<'END'
Oktest.rb is a new-style testing library for Ruby.
You can write `ok {1+1} == 2` instead of `assert_equal 2, 1+1` or
`expect(1+1).to eq 2`.

In addition, Oktest.rb supports **Fixture injection** feature
inspired by dependency injection and **JSON Matcher** feature
similar to JSON schema.

See https://github.com/kwatch/oktest/tree/ruby/ruby for details.
END
  s.required_ruby_version = ">= 2.4"
  s.add_dependency "diff-lcs", "~> 1.0"
  s.add_dependency "benry-cmdopt", "~> 2.3"
  s.add_dependency "benry-recorder", "~> 1.0"

  ## files
  files = Dir['lib/oktest.rb', 'test/*.rb']
  files += ['README.md', 'MIT-LICENSE', 'oktest.gemspec', 'Rakefile.rb']
  files += ['benchmark/Rakefile.rb', 'benchmark/run_all.rb']
  s.files       = files
  s.executables = ['oktest']
  s.bindir      = 'bin'
  s.test_file   = 'test/all.rb'
end

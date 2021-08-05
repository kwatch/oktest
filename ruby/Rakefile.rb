# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

PROJECT   = "oktest"
RELEASE   = ENV['RELEASE'] || "0.0.0"
COPYRIGHT = "copyright(c) 2011-2021 kuwata-lab.com all rights reserved"
LICENSE   = "MIT License"

$ruby_versions ||= %w[2.4 2.5 2.6 2.7 3.0]

desc "show release guide"
task :guide do
  RELEASE != '0.0.0'  or abort "rake help: required 'RELEASE=X.X.X'"
  rel, proj = RELEASE, PROJECT
  rel =~ /(\d+\.\d+)/
  branch = "ruby-#{$1}"
  puts <<END
How to release:

  $ git diff .
  $ git status .
  $ which ruby
  $ rake test
  $ rake test:all
  $ rake readme:execute             # optional
  $ rake readme:toc                 # optional
  $ git checkout -b #{branch}
  $ git edit RELASE=#{rel}
  $ git add -u
  $ git commit -m "ruby: preparation for release #{rel}"
  $ vim CHANGES.md
  $ git add -p CHANGES.md
  $ git commit -m "ruby: upte 'CHANGES.md'"
  $ git log -1
  $ rake package RELEASE=#{rel}
  $ rake package:extract            # confirm files in gem file
  $ (cd #{proj}-#{rel}/data; find . -type f)
  $ gem install #{proj}-#{rel}.gem  # confirm gem package
  $ gem uninstall #{proj}
  $ gem push #{proj}-#{rel}.gem     # publish gem to rubygems.org
  $ git tag rb-#{rel}
  $ git push -u origin #{branch}
  $ git push --tags
  $ rake clean
  $ git checkout ruby
  $ git cherry-pick xxxxxxxxx       # cherry-pick update of CHANGES.md
END
end

README_EXTRACT  = /^(test\/.*_test\.rb):/

Dir.glob("./task/*.rb").each {|x| require_relative x }

def readme_extract_callback(filename, str)
  return str
end

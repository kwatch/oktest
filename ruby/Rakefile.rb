# -*- coding: utf-8 -*-

###
### $Release: 1.2.1 $
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

  $ which ruby
  $ rake test
  $ rake test:all
  $ rake readme:execute             # optional
  $ rake readme:toc                 # optional
  $ git diff .
  $ git status .
  $ git checkout -b #{branch}
  $ rake edit RELEASE=#{rel}
  $ git add -u
  $ git commit -m "ruby: preparation for release #{rel}"
  $ vim CHANGES.md
  $ git add -p CHANGES.md
  $ git commit -m "ruby: update 'CHANGES.md'"
  $ git log -1
  $ cid=$(git log -1 | awk 'NR==1{print $2}')
  $ echo $cid
  $ rake package RELEASE=#{rel}
  $ rake package:extract            # confirm files in gem file
  $ pushd #{proj}-#{rel}/data; find . -type f; popd
  $ gem install #{proj}-#{rel}.gem  # confirm gem package
  $ gem uninstall #{proj}
  $ gem push #{proj}-#{rel}.gem     # publish gem to rubygems.org
  $ git tag rb-#{rel}
  $ git push -u origin #{branch}
  $ git push --tags
  $ rake clean
  $ git checkout ruby
  $ git log -1 $cid
  $ git cherry-pick $cid            # cherry-pick update of CHANGES.md
END
end

README_EXTRACT  = /^(test\/.*_test\.rb):/

Dir.glob("./task/*.rb").each {|x| require_relative x }

def readme_extract_callback(filename, str)
  return str
end

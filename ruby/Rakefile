###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

task :default => :test

desc "do test"
task :test do
  ruby "test/run_all.rb"
end

desc "retrieve scripts from README.txt"
task :retrieve do
  mkdir 'tmp' unless File.directory?('tmp')
  mkdir 'tmp/readme.d' unless File.directory?('tmp/readme.d')
  sh "retrieve -d tmp/readme.d README.txt"
end

desc "retrieve test scripts and execute them"
task :test2 => :retrieve do
  Dir.glob('tmp/readme.d/*').each do |fpath|
    sh "ruby -I lib #{fpath}"
  end
end

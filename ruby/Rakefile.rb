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

if ENV['VS_HOME']
  desc "do test for different ruby versions"
  task :'test:all' do
    ruby_versions = %w[2.4 2.5 2.6 2.7 3.0]
    vs_home = ENV['VS_HOME'].split(/:/).first
    ENV['TC_QUIET'] = "Y"
    comp = proc {|x, y| x.to_s.split('.').map(&:to_i) <=> y.to_s.split('.').map(&:to_i) }
    ruby_versions.each do |ver|
      dir = Dir.glob("#{vs_home}/ruby/#{ver}.*").sort_by(&comp).last
      next unless dir
      puts "==== ruby #{ver} (#{dir}) ===="
      sh "#{dir}/bin/ruby test/run_all.rb" do |ok, res|
        $stderr.puts "** test failed" unless ok
      end
    end
  end
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

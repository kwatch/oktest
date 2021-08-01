###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

$project   = "oktest"
$release   = ENV['RELEASE'] || "0.0.0"
$copyright = "copyright(c) 2011-2021 kuwata-lab.com all rights reserved"
$license   = "MIT License"

require 'rake/clean'
CLEAN << "build"
CLOBBER << Dir.glob("#{$project}-*.gem")


task :default => :help


desc "show help"
task :help do
  puts "rake help                   # help"
  puts "rake test                   # run test"
  puts "rake test:all               # run test for each ruby versions"
  puts "rake package RELEASE=X.X.X  # create gem file"
  puts "rake publish RELEASE=X.X.X  # upload gem file"
  puts "rake clean                  # remove files"
end

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

def target_files()
  $_target_files ||= begin
    spec_src = File.read("#{$project}.gemspec", encoding: 'utf-8')
    spec = eval spec_src
    spec.files
  end
  return $_target_files
end

def edit_file(filename)
  File.open(filename, 'rb+') do |f|
    s1 = f.read()
    s2 = yield s1
    if s1 != s2
      f.rewind()
      f.truncate(0)
      f.write(s2)
      true
    else
      false
    end
  end
end

desc "edit metadata in files"
task :edit do
  target_files().each do |fname|
    changed = edit_file(fname) do |s|
      #s = s.gsub(/\$Release[:].*?\$/,   "$"+"Release: #{$release} $")
      s = s.gsub(/\$Copyright[:].*?\$/, "$"+"Copyright: #{$copyright} $")
      s = s.gsub(/\$License[:].*?\$/,   "$"+"License: #{$license} $")
      s
    end
    puts "[changed] #{fname}" if changed
  end
end

desc "create package"
task :package do
  $release != "0.0.0"  or
    raise "specify $RELEASE"
  ## copy
  dir = "build"
  rm_rf dir if File.exist?(dir)
  mkdir dir
  target_files().each do |file|
    dest = File.join(dir, File.dirname(file))
    mkdir_p dest, :verbose=>false unless File.exist?(dest)
    cp file, "#{dir}/#{file}"
  end
  ## edit
  Dir.glob("#{dir}/**/*").each do |file|
    next unless File.file?(file)
    edit_file(file) do |s|
      s = s.gsub(/\$Release[:].*?\$/,   "$"+"Release: #{$release} $")
      s = s.gsub(/\$Copyright[:].*?\$/, "$"+"Copyright: #{$copyright} $")
      s = s.gsub(/\$License[:].*?\$/,   "$"+"License: #{$license} $")
      s
    end
  end
  ## build
  chdir dir do
    sh "gem build #{$project}.gemspec"
  end
  mv "#{dir}/#{$project}-#{$release}.gem", "."
end

desc "upload gem file to rubygems.org"
task :publish do
  release != "0.0.0"  or
    raise "specify $RELEASE"
  #
  gemfile = "#{$project}-#{$release}.gem"
  print "** Are you sure to publish #{gemfile}? [y/N]: "
  answer = $stdin.gets().strip()
  if answer.downcase == "y"
    sh "gem push #{gemfile}"
    sh "git tag ruby-#{$project}-#{$release}"
    sh "git push --tags"
  end
end


namespace :readme do

  desc "retrieve scripts from README.txt"
  task :retrieve do
    dir = "tmp/test"
    rm_rf dir if File.exist?(dir)
    mkdir_p dir
    #sh "retrieve -d #{dir} README.txt"
    s = File.read('README.md', encoding: 'utf-8')
    filename = nil
    buf = nil
    s.each_line do |line|
      case line
      when /test\/(.*_test\.rb):/
        filename = $1
        next
      when /^```ruby/
        if filename
          buf = []
        end
        next
      when /^```/
        if filename && buf
          File.write("#{dir}/#{filename}", buf.join, encoding: 'utf-8')
          puts "[retrieve] #{dir}/#{filename}"
        end
        filename = nil
        buf = nil
        next
      end
      #
      if buf
        buf << line
      end
    end
  end

  desc "retrieve test scripts and execute them"
  task :test => :retrieve do
    Dir.glob('tmp/test/*').sort.each do |fpath|
      puts "========================================"
      sh "ruby -I lib #{fpath}" do end
    end
  end

end

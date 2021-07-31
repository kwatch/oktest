###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

File.class_eval do
  $: << join(dirname(dirname(expand_path(__FILE__))), 'lib')
end

require_relative './tc'

require 'oktest'
Oktest::Config.system_exit = false


if __FILE__ == $0
  puts "********** RUBY_VERSION: #{RUBY_VERSION} **********"
  filenames = ARGV.collect {|x| x }
  ARGV.clear
  filenames.each {|fname| load fname }
end

###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

File.class_eval do
  $: << join(dirname(dirname(expand_path(__FILE__))), 'lib')
end

require 'test/unit'
#Test::Unit::Runner.class_variable_set(:@@stop_auto_run, false)
require 'section9/unittest'

require 'oktest'
Oktest::Config.system_exit = false


if __FILE__ == $0
  if defined?(Test::Unit::Runner)
    Test::Unit::Runner.class_variable_set(:@@stop_auto_run, false)
  end
  puts "********** RUBY_VERSION: #{RUBY_VERSION} **********"
  filenames = ARGV.collect {|x| x }
  ARGV.clear
  filenames.each {|fname| load fname }
end

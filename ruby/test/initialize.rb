###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

File.class_eval do
  $LOAD_PATH << join(dirname(dirname(expand_path(__FILE__))), 'lib')
end

require_relative './tc'
require 'oktest'
Oktest::Config.system_exit = false

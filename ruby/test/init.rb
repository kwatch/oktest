# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

File.class_eval do
  $LOAD_PATH << join(dirname(dirname(expand_path(__FILE__))), 'lib')
end

require_relative './tc'
require 'oktest'


# for Ruby 2.4 or older
require 'set'
unless Set.instance_methods(false).include?(:===)
  class Set; alias === include?; end
end

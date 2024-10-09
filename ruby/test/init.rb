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

require_relative './nt'
require 'oktest'


module NanoTest
  module_function

  def test_when(desc, &b)
    yield desc
  end

  alias capture capture_output!

  def plain2colored(str)
    str = str.gsub(/<R>(.*?)<\/R>/) { Oktest::Color.red($1) }
    str = str.gsub(/<G>(.*?)<\/G>/) { Oktest::Color.green($1) }
    str = str.gsub(/<B>(.*?)<\/B>/) { Oktest::Color.blue($1) }
    str = str.gsub(/<C>(.*?)<\/C>/) { Oktest::Color.cyan($1) }
    str = str.gsub(/<M>(.*?)<\/M>/) { Oktest::Color.magenta($1) }
    str = str.gsub(/<Y>(.*?)<\/Y>/) { Oktest::Color.yellow($1) }
    str = str.gsub(/<b>(.*?)<\/b>/) { Oktest::Color.bold($1) }
    str = str.gsub(/<E>(.*?)<\/E>/) { Oktest::Color.red_b($1) }
    return str
  end

end


# for Ruby 2.4 or older
require 'set'
unless Set.instance_methods(false).include?(:===)
  class Set; alias === include?; end
end

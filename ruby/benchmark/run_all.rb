# coding: utf-8
# frozen_string_literal: true

Dir.glob(File.join(File.dirname(__FILE__), '*_test.rb')).each do |x|
  #load x
  require_relative x
end

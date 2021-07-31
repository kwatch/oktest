# -*- coding: utf-8 -*-

#Dir.chdir File.dirname(__FILE__) do
#  Dir.glob("**/*_test.rb") do |x|
#    require_relative "./#{x}"
#  end
#end

Dir.glob(File.join(File.dirname(__FILE__), '**/*_test.rb')).each do |x|
  #require x
  #require File.absolute_path(x)
  load x
end

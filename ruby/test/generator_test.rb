# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: 1.5.0 $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './init'

require 'stringio'


class TestGenerator__Test
  extend NanoTest

  INPUT_3 = <<'END'
class Hello
  def hello(name=nil)
    #; default name is 'world'.
    if name.nil?
      name = "world"
    end
    #; returns greeting message.
    return "Hello, #{name}!"
  end
end
END

  test_target 'Oktest::TestGenerator#parse()' do
    test_subject "[!5mzd3] parses ruby code." do
      g = Oktest::TestGenerator.new()
      tree = g.parse(StringIO.new(INPUT_3))
      expected = [
        ["", "class", "Hello", [
          ["  ", "def", "#hello", [
            ["    ", "spec", "default name is 'world'."],
            ["    ", "spec", "returns greeting message."],
          ]]
        ]]
      ]
      test_eq? tree, expected
    end
  end

  test_target 'Oktest::TestGenerator#transform()' do
    test_subject "[!te7zw] converts tree into test code." do
      g = Oktest::TestGenerator.new()
      tree = g.parse(StringIO.new(INPUT_3))
      code = g.transform(tree, 1)
      expected = <<'END'

  topic Hello do


    topic '#hello()' do

      spec "default name is 'world'."

      spec "returns greeting message."

    end


  end  # Hello
END
      test_eq? code, expected
    end
    test_subject "[!q5duk] supports 'unaryop' style option." do
      g = Oktest::TestGenerator.new('unaryop')
      tree = g.parse(StringIO.new(INPUT_3))
      code = g.transform(tree, 1)
      expected = <<'END'

+ topic(Hello) do


  + topic('#hello()') do

    - spec("default name is 'world'.")

    - spec("returns greeting message.")

    end


  end  # Hello
END
      test_eq? code, expected
    end
  end

  test_target 'Oktest::TestGenerator#generate()' do
    test_subject "[!5hdw4] generates test code." do
      g = Oktest::TestGenerator.new()
      code = g.generate(StringIO.new(INPUT_3))
      expected = <<'END'
# coding: utf-8

require 'oktest'

Oktest.scope do


  topic Hello do


    topic '#hello()' do

      spec "default name is 'world'."

      spec "returns greeting message."

    end


  end  # Hello


end
END
      test_eq? code, expected
    end
  end

end

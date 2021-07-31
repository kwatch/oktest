###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'

require 'stringio'


class TestGenerator_TC < TC

  INPUT = <<END
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

  describe '#parse()' do
    it "parses ruby code." do
      g = Oktest::TestGenerator.new()
      tree = g.parse(StringIO.new(INPUT))
      expected = [
        ["", "class", "Hello", [
          ["  ", "def", "#hello", [
            ["    ", "spec", "default name is 'world'."],
            ["    ", "spec", "returns greeting message."],
          ]]
        ]]
      ]
      assert_eq tree, expected
    end
  end

  describe '#transform()' do
    it "converts tree into test code." do
      g = Oktest::TestGenerator.new()
      tree = g.parse(StringIO.new(INPUT))
      code = g.transform(tree, 1)
      expected = <<'END'

  topic Hello do


    topic '#hello' do
      spec "default name is 'world'."
      spec "returns greeting message."
    end


  end # Hello
END
      assert_eq code, expected
    end
  end

  describe '#generate()' do
    it "generates test code." do
      g = Oktest::TestGenerator.new()
      code = g.generate(StringIO.new(INPUT))
      expected = <<'END'
# coding: utf-8

require 'oktest'

Oktest.scope do


  topic Hello do


    topic '#hello' do
      spec "default name is 'world'."
      spec "returns greeting message."
    end


  end # Hello


end
END
      assert_eq code, expected
    end
  end

end

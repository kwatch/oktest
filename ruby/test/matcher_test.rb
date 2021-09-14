# -*- coding: utf-8 -*-

###
### $Release: 1.1.1 $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'
require 'set'


class Matcher_TC < TC

  describe '#===' do
    it "[!spybn] raises NotImplementedError." do
      errmsg = "Oktest::Matcher#===(): not implemented yet."
      assert_exc(NotImplementedError, errmsg) do
        Oktest::Matcher.new(nil) === nil
      end
    end
  end

  describe '#==' do
    it "[!ymt1b] raises OktestError." do
      errmsg = "JSON(): use `===` instead of `==`."
      assert_exc(Oktest::OktestError, errmsg) do
        Oktest::Matcher.new(nil) == nil
      end
    end
  end

  describe '#fail()' do
    it "[!8qpsd] raises assertion error." do
      errmsg = "<<errmsg>>"
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        Oktest::Matcher.new(nil).fail("<<errmsg>>")
      end
    end
  end

end


class JsonMatcher_TC < TC

  def JSON(x)
    return Oktest::JsonMatcher.new(x)
  end

  def OR(*args)
    return Oktest::JsonMatcher::OR.new(*args)
  end

  def AND(*args)
    return Oktest::JsonMatcher::AND.new(*args)
  end

  def ANY()
    return Oktest::JsonMatcher::Any.new
  end

  describe '#===' do
    it "[!4uf1o] raises assertion error when JSON not matched." do
      assert_exc(Oktest::FAIL_EXCEPTION) do
        JSON({"status": "ok"}) === {"status": "OK"}
      end
    end
    it "[!0g0u4] returns true when JSON matched." do
      result = JSON({"status": "ok"}) === {"status": "ok"}
      assert_eq result, true
    end
    it "[!1ukbv] scalar value matches to integer, string, bool, and so son." do
      actual = {"name": "Alice", "age": 20, "deleted": false}
      result = JSON(actual) === {"name": "Alice", "age": 20, "deleted": false}
      assert_eq result, true
      #
      errmsg = ("$<JSON>[\"name\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"Alice\"\n"\
                "    $<expected>: \"alice\"\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {"name": "alice", "age": 20, "deleted": false}
      end
    end
    it "[!8o55d] class object matches to instance object." do
      actual = {"name": "Alice", "age": 20, "deleted": false}
      result = JSON(actual) === {"name": String, "age": Integer, "deleted": FalseClass}
      assert_eq result, true
      #
      errmsg = ("$<JSON>[\"deleted\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   false\n"\
                "    $<expected>: TrueClass\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {"name": String, "age": Integer, "deleted": TrueClass}
      end
    end
    it "[!s625d] regexp object matches to string value." do
      actual = {"email": "alice@example.com"}
      result = JSON(actual) === {"email": /^\w[-.\w]+@example\.(com|net|org)$/}
      assert_eq result, true
      #
      errmsg = ("$<JSON>[\"email\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"alice@example.com\"\n"\
                "    $<expected>: /^\\w[-.\\w]+@example\\.org$/\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {"email": /^\w[-.\w]+@example\.org$/}
      end
    end
    it "[!aqkk0] range object matches to scalar value." do
      actual = {"int": 5, "float": 3.14, "str": "abc"}
      result = JSON(actual) === {"int": 1..10, "float": 3.1..3.2, "str": "aaa".."zzz"}
      assert_eq result, true
      #
      errmsg = ("$<JSON>[\"int\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   5\n"\
                "    $<expected>: 1...5\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {"int": 1...5, "float": 3.1..3.2, "str": "aaa".."zzz"}
      end
    end
    it "[!4ymj2] fails when actual value is not matched to item class of range object." do
      actual = {"val": 1.5}
      errmsg = ("$<JSON>[\"val\"]: expected #{1.class.name} value, but got Float value.\n"\
                "    $<actual>:   1.5\n"\
                "    $<expected>: 1..10\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {"val": 1..10}
      end
    end
    it "[!a7bfs] Set object matches to enum value." do
      actual = {"gender": "female"}
      result = JSON(actual) === {"gender": Set.new(["male", "female"])}
      assert_eq result, true
      #
      errmsg = ("$<JSON>[\"gender\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"female\"\n"\
                "    $<expected>: #<Set: {\"M\", \"F\"}>\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {"gender": Set.new(["M", "F"])}
      end
    end
    it "[!sh5cg] Enumerator object matches to repeat of rule." do
      actual = {"tags": ["foo", "bar", "baz"]}
      result = JSON(actual) === {"tags": [String].each}
      assert_eq result, true
      #
      errmsg = ("$<JSON>[\"tags\"][0]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"foo\"\n"\
                "    $<expected>: Integer\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {"tags": [Integer].each}
      end
    end
    it "[!ljrmc] fails when expected is an Enumerator object and actual is not an array." do
      actual = {"tags": "foo"}
      errmsg = ("$<JSON>[\"tags\"]: Array value expected but got String value.\n"\
                "    $<actual>:   \"foo\"\n"\
                "    $<expected>: [String].each\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {"tags": [String].each}
      end
    end
    it "[!lh6d6] compares array items recursively." do
      actual = {"items": [{"name": "Alice", "id": 101}, {"name": "Bob"}]}
      result = JSON(actual) === {
        "items": [{"name": String, "id?": 100..999}].each
      }
      assert_eq result, true
      #
      errmsg = ("$<JSON>[\"items\"][0][\"id\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   101\n"\
                "    $<expected>: 1000..9999\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {
          "items": [{"name": String, "id?": 1000..9999}].each
        }
      end
    end
    it "[!bz74w] fails when array lengths are different." do
      actual = {"arr": ["A", "B", "C"]}
      errmsg = ("$<JSON>[\"arr\"]: $<actual>.length == $<expected>.length : failed.\n"\
                "    $<actual>.length:   3\n"\
                "    $<expected>.length: 4\n"\
                "    $<actual>:   [\"A\", \"B\", \"C\"]\n"\
                "    $<expected>: [\"A\", \"B\", \"C\", \"D\"]\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {"arr": ["A", "B", "C", "D"]}
      end
    end
    it "[!fmxyg] compares hash objects recursively." do
      actual = {
        "owner": {"name": "Alice", "age": 20},
        "item": {"id": 10001, "name": "Something", "price": 500},
      }
      result = JSON(actual) === {
        "owner": {"name": String, "age": 0..100},
        "item": {"id": 1..99999, "name": String, "price?": Numeric},
      }
      assert_eq result, true
      #
      errmsg = ("$<JSON>[\"item\"][\"price\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   500\n"\
                "    $<expected>: Float\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {
          "owner": {"name": String, "age": 0..100},
          "item": {"id": 1..99999, "name": String, "price?": Float},
        }
      end
    end
    it "[!rkv0z] compares two hashes with converting keys into string." do
      actual1 = {k1: "A", k2: "B"}
      result  = JSON(actual1) === {"k1"=>"A", "k2"=>"B"}
      assert_eq result, true
      #
      actual2 = {"k1"=>"A", "k2"=>"B"}
      result  = JSON(actual2) === {k1: "A", k2: "B"}
      assert_eq result, true
    end
    it "[!jbyv6] key 'aaa?' represents optional key." do
      actual1 = {"name": "alice", "birth": "2000-01-01"}
      result  = JSON(actual1) === {"name": "alice", "birth?": "2000-01-01"}
      assert_eq result, true
      #
      actual2 = {"name": "alice"}
      result  = JSON(actual2) === {"name": "alice", "birth?": "2000-01-01"}
      assert_eq result, true
      #
      actual3 = {"name": "alice", "birth": nil}
      result  = JSON(actual3) === {"name": "alice", "birth?": "2000-01-01"}
      assert_eq result, true
      #
      actual4 = {"name": "alice", "birth?": "2000-01-01"}     # TODO
      result  = JSON(actual4) === {"name": "alice", "birth?": "2000-01-01"}
      assert_eq result, true
    end
    it "[!mpbvu] fails when unexpected key exists in actual hash." do
      actual = {"id": 101, "name": "Alice"}
      errmsg = ("$<JSON>: key \"gender\" expected but not found.\n"\
                "    $<actual>.keys:   \"id\", \"name\"\n"\
                "    $<expected>.keys: \"gender\", \"id\", \"name\"\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {"id": Integer, "name": String, "gender": String}
      end
    end
    it "[!4oasq] fails when expected key not exist in actual hash." do
      actual = {"id": 101, "name": "Alice"}
      errmsg = ("$<JSON>[\"id\"]: unexpected key.\n"\
                "    $<actual>:   101\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON(actual) === {"name": String}
      end
    end
    it "[!eqr3b] `OR()` matches to any of arguments." do
      result = JSON({"val": 123}) === {"val": OR(String, Integer)}
      assert_eq result, true
      result = JSON({"val": "123"}) === {"val": OR(String, Integer)}
      assert_eq result, true
      #
      errmsg = ("$<JSON>[\"val\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   3.14\n"\
                "    $<expected>: OR(String, Integer)\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON({"val": 3.14}) === {"val": OR(String, Integer)}
      end
    end
    it "[!4hk96] `AND()` matches to all of arguments." do
      result = JSON({"val": "alice"}) === {"val": AND(String, /^[a-z]+$/)}
      assert_eq result, true
      #
      errmsg = ("$<JSON>[\"val\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"Alice\"\n"\
                "    $<expected>: AND(/^[a-z]+$/)\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON({"val": "Alice"}) === {"val": AND(String, /^[a-z]+$/)}
      end
    end
    it "[!5ybfg] `OR()` can contain `AND()`." do
      expected = {"val": OR(AND(String, /^\d+$/), AND(Integer, 100..999))}
      result = JSON({"val": "123"}) === expected
      assert_eq result, true
      result = JSON({"val": 123}) === expected
      assert_eq result, true
      #
      errmsg = ("$<JSON>[\"val\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"abc\"\n"\
                "    $<expected>: OR(AND(String, /^\\d+$/), AND(Integer, 100..999))\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON({"val": "abc"}) === expected
      end
      errmsg = ("$<JSON>[\"val\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   99\n"\
                "    $<expected>: OR(AND(String, /^\\d+$/), AND(Integer, 100..999))\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON({"val": 99}) === expected
      end
    end
    it "[!scx22] `AND()` can contain `OR()`." do
      expected = {"val": AND(OR(String, Integer), OR(/^\d{3}$/, 100..999))}
      result = JSON({"val": "123"}) === expected
      assert_eq result, true
      result = JSON({"val": 123}) === expected
      assert_eq result, true
      #
      errmsg = ("$<JSON>[\"val\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"1\"\n"\
                "    $<expected>: AND(OR(/^\\d{3}$/, 100..999))\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON({"val": "1"}) === expected
      end
      errmsg = ("$<JSON>[\"val\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   0\n"\
                "    $<expected>: AND(OR(/^\\d{3}$/, 100..999))\n")
      assert_exc(Oktest::FAIL_EXCEPTION, errmsg) do
        JSON({"val": 0}) === expected
      end
    end
    it "[!uc4ag] key '*' matches to any key name." do
      actual = {"name": "Alice", "age": 20}
      result = JSON(actual) === {"name": String, "*": Integer}
      assert_eq result, true
      result = JSON(actual) === {"name": String, "*": ANY()}
      assert_eq result, true
    end
  end

  describe '#_compare?()' do
    it "[!nkvqo] returns true when nothing raised." do
      result = JSON(nil).instance_eval { _compare?([], "abc", /^\w+$/) }
      assert_eq result, true
    end
    it "[!57m2j] returns false when assertion error raised." do
      result = JSON(nil).instance_eval { _compare?([], "abc", /^\d+$/) }
      assert_eq result, false
    end
  end

end


class OR_TC < TC

  describe '#inspect()' do
    it "[!2mu33] returns 'OR(...)' string." do
      o = Oktest::JsonMatcher::OR.new('A', 'B', 'C')
      assert_eq o.inspect(), 'OR("A", "B", "C")'
    end
  end

end


class AND_TC < TC

  describe '#inspect()' do
    it "[!w43ag] returns 'AND(...)' string." do
      o = Oktest::JsonMatcher::AND.new('A', 'B', 'C')
      assert_eq o.inspect(), 'AND("A", "B", "C")'
    end
  end

end


class Enum_TC < TC

  describe '#inspect()' do
    it "[!fam11] returns 'Enum(...)' string." do
      o = Oktest::JsonMatcher::Enum.new(['A', 'B', 'C'])
      assert_eq o.inspect(), 'Enum("A", "B", "C")'
    end
  end

end


class Length_TC < TC

  describe '#===' do
    it "[!03ozi] compares length of actual value with expected value." do
      o1 = Oktest::JsonMatcher::Length.new(3)
      assert_eq (o1 === "abc"), true
      assert_eq (o1 === "abcd"), false
      assert_eq (o1 === [1,2,3]), true
      assert_eq (o1 === [1, 2]), false
      o2 = Oktest::JsonMatcher::Length.new(1..3)
      assert_eq (o2 === "a"), true
      assert_eq (o2 === "abc"), true
      assert_eq (o2 === ""), false
      assert_eq (o2 === "abcd"), false
    end
  end

  describe '#inspect()' do
    it "[!nwv3e] returns 'Length(n)' string." do
      o = Oktest::JsonMatcher::Length.new(1..3)
      assert_eq o.inspect, "Length(1..3)"
    end
  end

end


class Any_TC < TC

  describe '#===' do
    it "[!mzion] returns true in any case." do
      o = Oktest::JsonMatcher::Any.new()
      assert_eq (o === nil)  , true
      assert_eq (o === true) , true
      assert_eq (o === false), true
      assert_eq (o === 123)  , true
      assert_eq (o === "abc"), true
    end
  end

  describe '#inspect()' do
    it "[!6f0yv] returns 'Any()' string." do
      o = Oktest::JsonMatcher::Any.new()
      assert_eq o.inspect, "Any()"
    end
  end

end

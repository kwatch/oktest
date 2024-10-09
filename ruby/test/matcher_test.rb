# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './init'
require 'set'


Object.new.instance_eval do   # Oktest::Matcher
  extend NanoTest
  extend Oktest::SpecHelper

  test_target 'Oktest::Matcher#===' do
    test_subject "[!spybn] raises NotImplementedError." do
      errmsg = "Oktest::Matcher#===(): not implemented yet."
      exc = test_exception? NotImplementedError do
        Oktest::Matcher.new(nil) === nil
      end
      test_eq? exc.message, errmsg
    end
  end

  test_target 'Oktest::Matcher#==' do
    test_subject "[!ymt1b] raises OktestError." do
      errmsg = "JSON(): use `===` instead of `==`."
      exc = test_exception? Oktest::OktestError do
        Oktest::Matcher.new(nil) == nil
      end
      test_eq? exc.message, errmsg
    end
  end

  test_target 'Oktest::Matcher#fail()' do
    test_subject "[!8qpsd] raises assertion error." do
      errmsg = "<<errmsg>>"
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        Oktest::Matcher.new(nil).fail("<<errmsg>>")
      end
      test_eq? exc.message, errmsg
    end
  end

end


Object.new.instance_eval do   # Oktest::JsonMatcher
  extend NanoTest

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

  test_target 'Oktest::JsonMatcher#===' do
    test_subject "[!4uf1o] raises assertion error when JSON not matched." do
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON({"status": "ok"}) === {"status": "OK"}
      end
    end
    test_subject "[!0g0u4] returns true when JSON matched." do
      result = JSON({"status": "ok"}) === {"status": "ok"}
      test_eq? result, true
    end
    test_subject "[!1ukbv] scalar value matches to integer, string, bool, and so son." do
      actual = {"name": "Alice", "age": 20, "deleted": false}
      result = JSON(actual) === {"name": "Alice", "age": 20, "deleted": false}
      test_eq? result, true
      #
      errmsg = ("$<JSON>[\"name\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"Alice\"\n"\
                "    $<expected>: \"alice\"\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {"name": "alice", "age": 20, "deleted": false}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!8o55d] class object matches to instance object." do
      actual = {"name": "Alice", "age": 20, "deleted": false}
      result = JSON(actual) === {"name": String, "age": Integer, "deleted": FalseClass}
      test_eq? result, true
      #
      errmsg = ("$<JSON>[\"deleted\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   false\n"\
                "    $<expected>: TrueClass\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {"name": String, "age": Integer, "deleted": TrueClass}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!s625d] regexp object matches to string value." do
      actual = {"email": "alice@example.com"}
      result = JSON(actual) === {"email": /^\w[-.\w]+@example\.(com|net|org)$/}
      test_eq? result, true
      #
      errmsg = ("$<JSON>[\"email\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"alice@example.com\"\n"\
                "    $<expected>: /^\\w[-.\\w]+@example\\.org$/\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {"email": /^\w[-.\w]+@example\.org$/}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!aqkk0] range object matches to scalar value." do
      actual = {"int": 5, "float": 3.14, "str": "abc"}
      result = JSON(actual) === {"int": 1..10, "float": 3.1..3.2, "str": "aaa".."zzz"}
      test_eq? result, true
      #
      errmsg = ("$<JSON>[\"int\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   5\n"\
                "    $<expected>: 1...5\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {"int": 1...5, "float": 3.1..3.2, "str": "aaa".."zzz"}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!4ymj2] fails when actual value is not matched to item class of range object." do
      actual = {"val": 1.5}
      errmsg = ("$<JSON>[\"val\"]: expected #{1.class.name} value, but got Float value.\n"\
                "    $<actual>:   1.5\n"\
                "    $<expected>: 1..10\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {"val": 1..10}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!a7bfs] Set object matches to enum value." do
      actual = {"gender": "female"}
      result = JSON(actual) === {"gender": Set.new(["male", "female"])}
      test_eq? result, true
      #
      errmsg = ("$<JSON>[\"gender\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"female\"\n"\
                "    $<expected>: #<Set: {\"M\", \"F\"}>\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {"gender": Set.new(["M", "F"])}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!sh5cg] Enumerator object matches to repeat of rule." do
      actual = {"tags": ["foo", "bar", "baz"]}
      result = JSON(actual) === {"tags": [String].each}
      test_eq? result, true
      #
      errmsg = ("$<JSON>[\"tags\"][0]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"foo\"\n"\
                "    $<expected>: Integer\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {"tags": [Integer].each}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!ljrmc] fails when expected is an Enumerator object and actual is not an array." do
      actual = {"tags": "foo"}
      errmsg = ("$<JSON>[\"tags\"]: Array value expected but got String value.\n"\
                "    $<actual>:   \"foo\"\n"\
                "    $<expected>: [String].each\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {"tags": [String].each}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!lh6d6] compares array items recursively." do
      actual = {"items": [{"name": "Alice", "id": 101}, {"name": "Bob"}]}
      result = JSON(actual) === {
        "items": [{"name": String, "id?": 100..999}].each
      }
      test_eq? result, true
      #
      errmsg = ("$<JSON>[\"items\"][0][\"id\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   101\n"\
                "    $<expected>: 1000..9999\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {
          "items": [{"name": String, "id?": 1000..9999}].each
        }
      test_es exc.message, errmsg
      end
    end
    test_subject "[!bz74w] fails when array lengths are different." do
      actual = {"arr": ["A", "B", "C"]}
      errmsg = ("$<JSON>[\"arr\"]: $<actual>.length == $<expected>.length : failed.\n"\
                "    $<actual>.length:   3\n"\
                "    $<expected>.length: 4\n"\
                "    $<actual>:   [\"A\", \"B\", \"C\"]\n"\
                "    $<expected>: [\"A\", \"B\", \"C\", \"D\"]\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {"arr": ["A", "B", "C", "D"]}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!fmxyg] compares hash objects recursively." do
      actual = {
        "owner": {"name": "Alice", "age": 20},
        "item": {"id": 10001, "name": "Something", "price": 500},
      }
      result = JSON(actual) === {
        "owner": {"name": String, "age": 0..100},
        "item": {"id": 1..99999, "name": String, "price?": Numeric},
      }
      test_eq? result, true
      #
      errmsg = ("$<JSON>[\"item\"][\"price\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   500\n"\
                "    $<expected>: Float\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {
          "owner": {"name": String, "age": 0..100},
          "item": {"id": 1..99999, "name": String, "price?": Float},
        }
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!rkv0z] compares two hashes with converting keys into string." do
      actual1 = {k1: "A", k2: "B"}
      result  = JSON(actual1) === {"k1"=>"A", "k2"=>"B"}
      test_eq? result, true
      #
      actual2 = {"k1"=>"A", "k2"=>"B"}
      result  = JSON(actual2) === {k1: "A", k2: "B"}
      test_eq? result, true
    end
    test_subject "[!jbyv6] key 'aaa?' represents optional key." do
      actual1 = {"name": "alice", "birth": "2000-01-01"}
      result  = JSON(actual1) === {"name": "alice", "birth?": "2000-01-01"}
      test_eq? result, true
      #
      actual2 = {"name": "alice"}
      result  = JSON(actual2) === {"name": "alice", "birth?": "2000-01-01"}
      test_eq? result, true
      #
      actual3 = {"name": "alice", "birth": nil}
      result  = JSON(actual3) === {"name": "alice", "birth?": "2000-01-01"}
      test_eq? result, true
      #
      actual4 = {"name": "alice", "birth?": "2000-01-01"}     # TODO
      result  = JSON(actual4) === {"name": "alice", "birth?": "2000-01-01"}
      test_eq? result, true
    end
    test_subject "[!mpbvu] fails when unexpected key exists in actual hash." do
      actual = {"id": 101, "name": "Alice"}
      errmsg = ("$<JSON>: key \"gender\" expected but not found.\n"\
                "    $<actual>.keys:   \"id\", \"name\"\n"\
                "    $<expected>.keys: \"gender\", \"id\", \"name\"\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {"id": Integer, "name": String, "gender": String}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!4oasq] fails when expected key not exist in actual hash." do
      actual = {"id": 101, "name": "Alice"}
      errmsg = ("$<JSON>[\"id\"]: unexpected key.\n"\
                "    $<actual>:   101\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON(actual) === {"name": String}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!eqr3b] `OR()` matches to any of arguments." do
      result = JSON({"val": 123}) === {"val": OR(String, Integer)}
      test_eq? result, true
      result = JSON({"val": "123"}) === {"val": OR(String, Integer)}
      test_eq? result, true
      #
      errmsg = ("$<JSON>[\"val\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   3.14\n"\
                "    $<expected>: OR(String, Integer)\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON({"val": 3.14}) === {"val": OR(String, Integer)}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!4hk96] `AND()` matches to all of arguments." do
      result = JSON({"val": "alice"}) === {"val": AND(String, /^[a-z]+$/)}
      test_eq? result, true
      #
      errmsg = ("$<JSON>[\"val\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"Alice\"\n"\
                "    $<expected>: AND(/^[a-z]+$/)\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON({"val": "Alice"}) === {"val": AND(String, /^[a-z]+$/)}
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!5ybfg] `OR()` can contain `AND()`." do
      expected = {"val": OR(AND(String, /^\d+$/), AND(Integer, 100..999))}
      result = JSON({"val": "123"}) === expected
      test_eq? result, true
      result = JSON({"val": 123}) === expected
      test_eq? result, true
      #
      errmsg = ("$<JSON>[\"val\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"abc\"\n"\
                "    $<expected>: OR(AND(String, /^\\d+$/), AND(Integer, 100..999))\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON({"val": "abc"}) === expected
      end
      test_eq? exc.message, errmsg
      errmsg = ("$<JSON>[\"val\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   99\n"\
                "    $<expected>: OR(AND(String, /^\\d+$/), AND(Integer, 100..999))\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON({"val": 99}) === expected
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!scx22] `AND()` can contain `OR()`." do
      expected = {"val": AND(OR(String, Integer), OR(/^\d{3}$/, 100..999))}
      result = JSON({"val": "123"}) === expected
      test_eq? result, true
      result = JSON({"val": 123}) === expected
      test_eq? result, true
      #
      errmsg = ("$<JSON>[\"val\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   \"1\"\n"\
                "    $<expected>: AND(OR(/^\\d{3}$/, 100..999))\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON({"val": "1"}) === expected
      end
      test_eq? exc.message, errmsg
      errmsg = ("$<JSON>[\"val\"]: $<expected> === $<actual> : failed.\n"\
                "    $<actual>:   0\n"\
                "    $<expected>: AND(OR(/^\\d{3}$/, 100..999))\n")
      exc = test_exception? Oktest::FAIL_EXCEPTION do
        JSON({"val": 0}) === expected
      end
      test_eq? exc.message, errmsg
    end
    test_subject "[!uc4ag] key '*' matches to any key name." do
      actual = {"name": "Alice", "age": 20}
      result = JSON(actual) === {"name": String, "*": Integer}
      test_eq? result, true
      result = JSON(actual) === {"name": String, "*": ANY()}
      test_eq? result, true
    end
  end

  test_target 'Oktest::JsonMatcher#_compare?()' do
    test_subject "[!nkvqo] returns true when nothing raised." do
      result = JSON(nil).instance_eval { _compare?([], "abc", /^\w+$/) }
      test_eq? result, true
    end
    test_subject "[!57m2j] returns false when assertion error raised." do
      result = JSON(nil).instance_eval { _compare?([], "abc", /^\d+$/) }
      test_eq? result, false
    end
  end

end


Object.new.instance_eval do   # Oktest::JsonMatcher::OR
  extend NanoTest

  test_target 'Oktest::JsonMatcher::OR#inspect()' do
    test_subject "[!2mu33] returns 'OR(...)' string." do
      o = Oktest::JsonMatcher::OR.new('A', 'B', 'C')
      test_eq? o.inspect(), 'OR("A", "B", "C")'
    end
  end

end


Object.new.instance_eval do   # Oktest::JsonMatcher::AND
  extend NanoTest

  test_target 'Oktest::JsonMatcher::AND#inspect()' do
    test_subject "[!w43ag] returns 'AND(...)' string." do
      o = Oktest::JsonMatcher::AND.new('A', 'B', 'C')
      test_eq? o.inspect(), 'AND("A", "B", "C")'
    end
  end

end


Object.new.instance_eval do   # Oktest::JsonMatcher::Enum
  extend NanoTest

  test_target 'Oktest::JsonMatcher::Enum#inspect()' do
    test_subject "[!fam11] returns 'Enum(...)' string." do
      o = Oktest::JsonMatcher::Enum.new(['A', 'B', 'C'])
      test_eq? o.inspect(), 'Enum("A", "B", "C")'
    end
  end

end


Object.new.instance_eval do   # Oktest::JsonMatcher::Length
  extend NanoTest

  test_target 'Oktest::JsonMatcher::Length#===' do
    test_subject "[!03ozi] compares length of actual value with expected value." do
      o1 = Oktest::JsonMatcher::Length.new(3)
      test_eq? (o1 === "abc"), true
      test_eq? (o1 === "abcd"), false
      test_eq? (o1 === [1,2,3]), true
      test_eq? (o1 === [1, 2]), false
      o2 = Oktest::JsonMatcher::Length.new(1..3)
      test_eq? (o2 === "a"), true
      test_eq? (o2 === "abc"), true
      test_eq? (o2 === ""), false
      test_eq? (o2 === "abcd"), false
    end
  end

  test_target 'Oktest::JsonMatcher::Length#inspect()' do
    test_subject "[!nwv3e] returns 'Length(n)' string." do
      o = Oktest::JsonMatcher::Length.new(1..3)
      test_eq? o.inspect, "Length(1..3)"
    end
  end

end


Object.new.instance_eval do   # Oktest::JsonMatcher::Any
  extend NanoTest

  test_target 'Oktest::JsonMatcher::Any#===' do
    test_subject "[!mzion] returns true in any case." do
      o = Oktest::JsonMatcher::Any.new()
      test_eq? (o === nil)  , true
      test_eq? (o === true) , true
      test_eq? (o === false), true
      test_eq? (o === 123)  , true
      test_eq? (o === "abc"), true
    end
  end

  test_target 'Oktest::JsonMatcher::Any#inspect()' do
    test_subject "[!6f0yv] returns 'Any()' string." do
      o = Oktest::JsonMatcher::Any.new()
      test_eq? o.inspect, "Any()"
    end
  end

end

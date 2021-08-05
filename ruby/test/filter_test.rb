# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class Filter_TC < TC

  def prepare()
    Oktest.scope do
      topic 'Hello' do
        spec "hello spec", tag: 'new' do ok {"hello"} == "hello" end
      end
      topic 'Topic 832795' do
        topic Integer do
          spec "spec example #1" do ok {1+1} == 2 end
          spec "spec example #2", tag: 'new' do ok {1-1} == 0 end
        end
        topic Float, tag: 'exp' do
          spec "spec example #3" do ok {1.0+1.0} == 2.0 end
          spec "spec example #4" do ok {1.0-1.0} == 0.0 end
        end
        spec "spec example #5", tag: ['exp', 'new'] do ok {1%1} == 0 end
      end
    end
  end

  def run_filter(topic_pattern, spec_pattern, tag_pattern, negative: false)
    prepare()
    filter = Oktest::Filter.new(topic_pattern, spec_pattern, tag_pattern, negative: negative)
    Oktest::TOPLEVEL_SCOPES.each {|x| filter.filter_toplevel_scope!(x) }
    reporter = Oktest::VerboseReporter.new()
    sout, serr = capture('', tty: false) do
      Oktest::Runner.new(reporter).run_all()
    end
    assert_eq serr, ""
    return sout.sub(/^## total:.*\n/, '')
  end

  def uncolor(s)
    return s.gsub(/\x1b.*?m/, '')
  end


  describe '#filter_toplevel_scope!()' do

    it "[!osoq2] can filter topics by full name." do
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter('Hello', nil, nil)
      assert_eq uncolor(sout), expected
    end

    it "[!wzcco] can filter topics by pattern." do
      expected = <<END
* Topic 832795
  * Integer
    - [pass] spec example #1
    - [pass] spec example #2
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
  - [pass] spec example #5
END
      sout = run_filter('*832795*', nil, nil)
      assert_eq uncolor(sout), expected
    end

    it "[!mz6id] can filter nested topics." do
      expected = <<END
* Topic 832795
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
END
      sout = run_filter('*loat*', nil, nil)
      assert_eq uncolor(sout), expected
    end

    it "[!0kw9c] can filter specs by full name." do
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter(nil, 'hello spec', nil)
      assert_eq uncolor(sout), expected
    end

    it "[!fd8wt] can filter specs by pattern." do
      expected = <<END
* Topic 832795
  - [pass] spec example #5
END
      sout = run_filter(nil, '*#5', nil)
      assert_eq uncolor(sout), expected
      #
      expected = <<END
* Topic 832795
  * Integer
    - [pass] spec example #1
    - [pass] spec example #2
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
  - [pass] spec example #5
END
      sout = run_filter(nil, 'spec example*', nil)
      assert_eq uncolor(sout), expected
    end

    it "[!1jphf] can filter specs from nested topics." do
      expected = <<END
* Topic 832795
  * Float
    - [pass] spec example #4
END
      sout = run_filter(nil, '*#4', nil)
      assert_eq uncolor(sout), expected
    end

    it "[!eirmu] can filter topics by tag name." do
      expected = <<END
* Topic 832795
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
  - [pass] spec example #5
END
      sout = run_filter(nil, nil, 'exp')
      assert_eq uncolor(sout), expected
    end

    it "[!6sq7g] can filter specs by tag name." do
      expected = <<END
* Hello
  - [pass] hello spec
* Topic 832795
  * Integer
    - [pass] spec example #2
  - [pass] spec example #5
END
      sout = run_filter(nil, nil, 'new')
      assert_eq uncolor(sout), expected
    end

    it "[!6to6n] can filter by multiple tag name." do
      expected = <<END
* Hello
  - [pass] hello spec
* Topic 832795
  * Integer
    - [pass] spec example #2
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
  - [pass] spec example #5
END
      sout = run_filter(nil, nil, '{new,exp}')
      assert_eq uncolor(sout), expected
    end

    it "[!r6g6a] supports negative filter by topic." do
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter('Topic 832795', nil, nil, negative: true)
      assert_eq uncolor(sout), expected
      #
      expected = <<END
* Hello
  - [pass] hello spec
* Topic 832795
  - [pass] spec example #5
END
      sout = run_filter('{Integer,Float}', nil, nil, negative: true)
      assert_eq uncolor(sout), expected
    end

    it "[!doozg] supports negative filter by spec." do
      expected = <<END
* Topic 832795
  * Integer
    - [pass] spec example #1
    - [pass] spec example #2
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
  - [pass] spec example #5
END
      sout = run_filter(nil, '*hello*', nil, negative: true)
      assert_eq uncolor(sout), expected
      #
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter(nil, 'spec example #[1-5]', nil, negative: true)
      assert_eq uncolor(sout), expected
    end

    it "[!ntv44] supports negative filter by tag name." do
      expected = <<END
* Topic 832795
  * Integer
    - [pass] spec example #1
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
END
      sout = run_filter(nil, nil, 'new', negative: true)
      assert_eq uncolor(sout), expected
      #
      expected = <<END
* Hello
  - [pass] hello spec
* Topic 832795
  * Integer
    - [pass] spec example #1
    - [pass] spec example #2
END
      sout = run_filter(nil, nil, 'exp', negative: true)
      assert_eq uncolor(sout), expected
      #
      expected = <<END
* Topic 832795
  * Integer
    - [pass] spec example #1
END
      sout = run_filter(nil, nil, '{exp,new}', negative: true)
      assert_eq uncolor(sout), expected
    end

  end

  describe '.create_from()' do
    def parse_filter_str(str)
      return Oktest::Filter.create_from(str)
    end
    def filter_attrs(ft)
      #return ft.topic_pattern, ft.spec_pattern, ft.tag_pattern, ft.negative
      return ft.instance_eval {
        [@topic_pattern, @spec_pattern, @tag_pattern, @negative]
      }
    end
    #
    it "[!9dzmg] returns filter object." do
      ft = parse_filter_str("topic=*pat*")
      assert ft.is_a?(Oktest::Filter), "should be a filter object."
    end
    it "[!xt364] parses 'topic=...' as filter pattern for topic." do
      ft = parse_filter_str("topic=*pat*")
      assert_eq filter_attrs(ft), ['*pat*', nil, nil, false]
    end
    it "[!53ega] parses 'spec=...' as filter pattern for spec." do
      ft = parse_filter_str("spec=*pat*")
      assert_eq filter_attrs(ft), [nil, '*pat*', nil, false]
    end
    it "[!go6us] parses 'tag=...' as filter pattern for tag." do
      ft = parse_filter_str("tag={exp,old}")
      assert_eq filter_attrs(ft), [nil, nil, '{exp,old}', false]
    end
    it "[!gtpt1] parses 'sid=...' as filter pattern for spec." do
      ft = parse_filter_str("sid=abc123")
      assert_eq filter_attrs(ft), [nil, '\[!abc123\]*', nil, false]
    end
    it "[!cmp6e] raises ArgumentError when invalid argument." do
      begin
        parse_filter_str("abc123")
      rescue Exception => exc
        assert_eq exc.class, ArgumentError
        assert_eq exc.message, '"abc123": unexpected pattern string.'
      else
        assert false, "ArgumentError expected"
      end
    end
    it "[!5hl7z] parses 'xxx!=...' as negative filter pattern." do
      ft = parse_filter_str("topic!=*pat*")
      assert_eq filter_attrs(ft), ['*pat*', nil, nil, true]
      ft = parse_filter_str("spec!=*pat*")
      assert_eq filter_attrs(ft), [nil, '*pat*', nil, true]
      ft = parse_filter_str("tag!={exp,old}")
      assert_eq filter_attrs(ft), [nil, nil, '{exp,old}', true]
      ft = parse_filter_str("sid!=abc123")
      assert_eq filter_attrs(ft), [nil, '\[!abc123\]*', nil, true]
    end
  end

end

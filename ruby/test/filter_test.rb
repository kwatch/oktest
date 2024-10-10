# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './init'


Object.new.instance_eval do   # Oktest::Filter
  extend NanoTest

  test_target 'Oktest::Filter.create_from()' do
    def self.parse_filter_str(str)
      return Oktest::Filter.create_from(str)
    end
    def self.filter_attrs(ft)
      #return ft.topic_pattern, ft.spec_pattern, ft.tag_pattern, ft.negative
      return ft.instance_eval {
        [@topic_pattern, @spec_pattern, @tag_pattern, @negative]
      }
    end
    #
    test_subject "[!9dzmg] returns filter object." do
      ft = parse_filter_str("topic=*pat*")
      test_ok? ft.is_a?(Oktest::Filter), msg: "should be a filter object."
    end
    test_subject "[!xt364] parses 'topic=...' as filter pattern for topic." do
      ft = parse_filter_str("topic=*pat*")
      test_eq? filter_attrs(ft), ['*pat*', nil, nil, false]
    end
    test_subject "[!53ega] parses 'spec=...' as filter pattern for spec." do
      ft = parse_filter_str("spec=*pat*")
      test_eq? filter_attrs(ft), [nil, '*pat*', nil, false]
    end
    test_subject "[!go6us] parses 'tag=...' as filter pattern for tag." do
      ft = parse_filter_str("tag={exp,old}")
      test_eq? filter_attrs(ft), [nil, nil, '{exp,old}', false]
    end
    test_subject "[!gtpt1] parses 'sid=...' as filter pattern for spec." do
      ft = parse_filter_str("sid=abc123")
      test_eq? filter_attrs(ft), [nil, '\[!abc123\]*', nil, false]
    end
    test_subject "[!cmp6e] raises ArgumentError when invalid argument." do
      exc = test_exception? ArgumentError do
        parse_filter_str("abc123")
      end
      test_eq? exc.message, '"abc123": unexpected pattern string.'
    end
    test_subject "[!5hl7z] parses 'xxx!=...' as negative filter pattern." do
      ft = parse_filter_str("topic!=*pat*")
      test_eq? filter_attrs(ft), ['*pat*', nil, nil, true]
      ft = parse_filter_str("spec!=*pat*")
      test_eq? filter_attrs(ft), [nil, '*pat*', nil, true]
      ft = parse_filter_str("tag!={exp,old}")
      test_eq? filter_attrs(ft), [nil, nil, '{exp,old}', true]
      ft = parse_filter_str("sid!=abc123")
      test_eq? filter_attrs(ft), [nil, '\[!abc123\]*', nil, true]
    end
  end

  def self.new_filter(topic_pat=nil, spec_pat=nil, tag_pat=nil, negative: false)
    ft = Oktest::Filter.new(topic_pat, spec_pat, tag_pat, negative: negative)
    return ft
  end

  test_target 'Oktest::Filter#_match?()' do
    test_subject "[!h90x3] returns true if str matched to pattern." do
      ft = new_filter()
      test_eq? ft.instance_eval { _match?('foo', 'foo') }, true
      test_eq? ft.instance_eval { _match?('foo', 'f*') }, true
      test_eq? ft.instance_eval { _match?('foo', '*o*') }, true
      test_eq? ft.instance_eval { _match?('foo', '{foo,bar}') }, true
      #
      test_eq? ft.instance_eval { _match?('foo', 'bar') }, false
      test_eq? ft.instance_eval { _match?('foo', 'F*') }, false
      test_eq? ft.instance_eval { _match?('foo', '*x*') }, false
      test_eq? ft.instance_eval { _match?('foo', '{x,y}') }, false
    end
  end

  test_target 'Oktest::Filter#_match_tag?()' do
    test_subject "[!lyo18] returns false if tag is nil." do
      ft = new_filter()
      test_eq? ft.instance_eval { _match_tag?(nil, '*') }, false
    end
    test_subject "[!8lxin] returns true if tag matched to pattern." do
      ft = new_filter()
      test_eq? ft.instance_eval { _match_tag?('foo', 'foo') }, true
      test_eq? ft.instance_eval { _match_tag?('foo', 'f*') }, true
      test_eq? ft.instance_eval { _match_tag?('foo', '*o*') }, true
      test_eq? ft.instance_eval { _match_tag?('foo', '{foo,bar}') }, true
      #
      test_eq? ft.instance_eval { _match_tag?('foo', 'bar') }, false
      test_eq? ft.instance_eval { _match_tag?('foo', 'F*') }, false
      test_eq? ft.instance_eval { _match_tag?('foo', '*x*') }, false
      test_eq? ft.instance_eval { _match_tag?('foo', '{x,y}') }, false
    end
    test_subject "[!7wxmh] supports multiple tag names." do
      ft = new_filter()
      tag = ['foo', 'bar']
      test_eq? ft.instance_eval { _match_tag?(tag, 'foo') }, true
      test_eq? ft.instance_eval { _match_tag?(tag, 'f*') }, true
      test_eq? ft.instance_eval { _match_tag?(tag, '*o*') }, true
      test_eq? ft.instance_eval { _match_tag?(tag, '{fooooo,bar,baz}') }, true
      #
      test_eq? ft.instance_eval { _match_tag?(tag, 'foooo') }, false
      test_eq? ft.instance_eval { _match_tag?(tag, 'F*') }, false
      test_eq? ft.instance_eval { _match_tag?(tag, '*x*') }, false
      test_eq? ft.instance_eval { _match_tag?(tag, '{x,y}') }, false
    end
  end

  test_target 'Oktest::Filter#scope_match?()' do
    test_subject "[!zkq6r] returns true only if tag name matched to pattern." do
      sc = Oktest::ScopeNode.new(nil, 'file.rb', tag: 'foo')
      test_eq? new_filter('*', '*', 'foo').scope_match?(sc), true
      test_eq? new_filter('*', '*', 'f*' ).scope_match?(sc), true
      test_eq? new_filter('*', '*', 'x*' ).scope_match?(sc), false
      #
      sc = Oktest::ScopeNode.new(nil, 'file.rb', tag: nil)
      test_eq? new_filter('*', '*', 'foo').scope_match?(sc), false
      test_eq? new_filter('*', '*', '*'  ).scope_match?(sc), false
    end
  end

  test_target 'Oktest::Filter#topic_match?()' do
    test_subject "[!jpycj] returns true if topic target name matched to pattern." do
      to = Oktest::TopicNode.new(nil, Time)
      test_eq? new_filter('Time' , nil, nil).topic_match?(to), true
      test_eq? new_filter('*ime*', nil, nil).topic_match?(to), true
      test_eq? new_filter('*xy*' , nil, nil).topic_match?(to), false
    end
    test_subject "[!6lfp1] returns true if tag name matched to pattern." do
      to = Oktest::TopicNode.new(nil, Time, tag: 'foo')
      [nil, '*bar*'].each do |pat|
        test_eq? new_filter(pat, nil, 'foo'      ).topic_match?(to), true
        test_eq? new_filter(pat, nil, 'f*'       ).topic_match?(to), true
        test_eq? new_filter(pat, nil, '{foo,bar}').topic_match?(to), true
        test_eq? new_filter(pat, nil, 'fooooo'   ).topic_match?(to), false
      end
    end
  end

  test_target 'Oktest::Filter#spec_match?()' do
    test_subject "[!k45p3] returns true if spec description matched to pattern." do
      sp = Oktest::SpecLeaf.new(nil, "sample", tag: 'foo')
      test_eq? new_filter(nil, 'sample', nil).spec_match?(sp), true
      test_eq? new_filter(nil, '*samp*', nil).spec_match?(sp), true
      test_eq? new_filter(nil, '*abc*' , nil).spec_match?(sp), false
    end
    test_subject "[!li3pd] returns true if tag name matched to pattern." do
      sp = Oktest::SpecLeaf.new(nil, "sample", tag: 'foo')
      [nil, '*bar*'].each do |pat|
        test_eq? new_filter(nil, pat, 'foo'      ).spec_match?(sp), true
        test_eq? new_filter(nil, pat, 'f*'       ).spec_match?(sp), true
        test_eq? new_filter(nil, pat, '{foo,bar}').spec_match?(sp), true
        test_eq? new_filter(nil, pat, 'fooooo'   ).spec_match?(sp), false
      end
    end
  end

  def self.prepare()
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

  def self.run_filter(topic_pattern, spec_pattern, tag_pattern, negative: false)
    self.prepare()
    filter = Oktest::Filter.new(topic_pattern, spec_pattern, tag_pattern, negative: negative)
    Oktest.filter(filter)
    reporter = Oktest::VerboseReporter.new()
    sout, serr = capture_output! '', tty: false do
      Oktest::Runner.new(reporter).start()
    end
    test_eq? serr, ""
    return sout.sub(/^## total:.*\n/, '').sub(/^## test\d?\/filter_test\.rb\n/, '')
  end

  def self.uncolor(s)
    return s.gsub(/\e\[.*?m/, '')
  end

  test_target 'Oktest::Filter#filter_children!()' do
    test_subject "[!osoq2] can filter topics by full name." do
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter('Hello', nil, nil)
      test_eq? uncolor(sout), expected
    end
    test_subject "[!wzcco] can filter topics by pattern." do
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
      test_eq? uncolor(sout), expected
    end
    test_subject "[!mz6id] can filter nested topics." do
      expected = <<END
* Topic 832795
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
END
      sout = run_filter('*loat*', nil, nil)
      test_eq? uncolor(sout), expected
    end
    test_subject "[!0kw9c] can filter specs by full name." do
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter(nil, 'hello spec', nil)
      test_eq? uncolor(sout), expected
    end
    test_subject "[!fd8wt] can filter specs by pattern." do
      expected = <<END
* Topic 832795
  - [pass] spec example #5
END
      sout = run_filter(nil, '*#5', nil)
      test_eq? uncolor(sout), expected
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
      test_eq? uncolor(sout), expected
    end
    test_subject "[!1jphf] can filter specs from nested topics." do
      expected = <<END
* Topic 832795
  * Float
    - [pass] spec example #4
END
      sout = run_filter(nil, '*#4', nil)
      test_eq? uncolor(sout), expected
    end
    test_subject "[!eirmu] can filter topics by tag name." do
      expected = <<END
* Topic 832795
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
  - [pass] spec example #5
END
      sout = run_filter(nil, nil, 'exp')
      test_eq? uncolor(sout), expected
    end
    test_subject "[!6sq7g] can filter specs by tag name." do
      expected = <<END
* Hello
  - [pass] hello spec
* Topic 832795
  * Integer
    - [pass] spec example #2
  - [pass] spec example #5
END
      sout = run_filter(nil, nil, 'new')
      test_eq? uncolor(sout), expected
    end
    test_subject "[!6to6n] can filter by multiple tag name." do
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
      test_eq? uncolor(sout), expected
    end
    test_subject "[!r6g6a] supports negative filter by topic." do
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter('Topic 832795', nil, nil, negative: true)
      test_eq? uncolor(sout), expected
      #
      expected = <<END
* Hello
  - [pass] hello spec
* Topic 832795
  - [pass] spec example #5
END
      sout = run_filter('{Integer,Float}', nil, nil, negative: true)
      test_eq? uncolor(sout), expected
    end
    test_subject "[!doozg] supports negative filter by spec." do
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
      test_eq? uncolor(sout), expected
      #
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter(nil, 'spec example #[1-5]', nil, negative: true)
      test_eq? uncolor(sout), expected
    end
    test_subject "[!ntv44] supports negative filter by tag name." do
      expected = <<END
* Topic 832795
  * Integer
    - [pass] spec example #1
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
END
      sout = run_filter(nil, nil, 'new', negative: true)
      test_eq? uncolor(sout), expected
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
      test_eq? uncolor(sout), expected
      #
      expected = <<END
* Topic 832795
  * Integer
    - [pass] spec example #1
END
      sout = run_filter(nil, nil, '{exp,new}', negative: true)
      test_eq? uncolor(sout), expected
    end

  end

end

# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class Filter_TC < TC

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

  def new_filter(topic_pat=nil, spec_pat=nil, tag_pat=nil, negative: false)
    ft = Oktest::Filter.new(topic_pat, spec_pat, tag_pat, negative: negative)
    return ft
  end

  describe '#_match?()' do
    it "[!h90x3] returns true if str matched to pattern." do
      ft = new_filter()
      assert_eq ft.instance_eval { _match?('foo', 'foo') }, true
      assert_eq ft.instance_eval { _match?('foo', 'f*') }, true
      assert_eq ft.instance_eval { _match?('foo', '*o*') }, true
      assert_eq ft.instance_eval { _match?('foo', '{foo,bar}') }, true
      #
      assert_eq ft.instance_eval { _match?('foo', 'bar') }, false
      assert_eq ft.instance_eval { _match?('foo', 'F*') }, false
      assert_eq ft.instance_eval { _match?('foo', '*x*') }, false
      assert_eq ft.instance_eval { _match?('foo', '{x,y}') }, false
    end
  end

  describe '#_match_tag?()' do
    it "[!lyo18] returns false if tag is nil." do
      ft = new_filter()
      assert_eq ft.instance_eval { _match_tag?(nil, '*') }, false
    end
    it "[!8lxin] returns true if tag matched to pattern." do
      ft = new_filter()
      assert_eq ft.instance_eval { _match_tag?('foo', 'foo') }, true
      assert_eq ft.instance_eval { _match_tag?('foo', 'f*') }, true
      assert_eq ft.instance_eval { _match_tag?('foo', '*o*') }, true
      assert_eq ft.instance_eval { _match_tag?('foo', '{foo,bar}') }, true
      #
      assert_eq ft.instance_eval { _match_tag?('foo', 'bar') }, false
      assert_eq ft.instance_eval { _match_tag?('foo', 'F*') }, false
      assert_eq ft.instance_eval { _match_tag?('foo', '*x*') }, false
      assert_eq ft.instance_eval { _match_tag?('foo', '{x,y}') }, false
    end
    it "[!7wxmh] supports multiple tag names." do
      ft = new_filter()
      tag = ['foo', 'bar']
      assert_eq ft.instance_eval { _match_tag?(tag, 'foo') }, true
      assert_eq ft.instance_eval { _match_tag?(tag, 'f*') }, true
      assert_eq ft.instance_eval { _match_tag?(tag, '*o*') }, true
      assert_eq ft.instance_eval { _match_tag?(tag, '{fooooo,bar,baz}') }, true
      #
      assert_eq ft.instance_eval { _match_tag?(tag, 'foooo') }, false
      assert_eq ft.instance_eval { _match_tag?(tag, 'F*') }, false
      assert_eq ft.instance_eval { _match_tag?(tag, '*x*') }, false
      assert_eq ft.instance_eval { _match_tag?(tag, '{x,y}') }, false
    end
  end

  describe '#scope_match?()' do
    it "[!zkq6r] returns true only if tag name matched to pattern." do
      sc = Oktest::ScopeNode.new(nil, 'file.rb', tag: 'foo')
      assert_eq new_filter('*', '*', 'foo').scope_match?(sc), true
      assert_eq new_filter('*', '*', 'f*' ).scope_match?(sc), true
      assert_eq new_filter('*', '*', 'x*' ).scope_match?(sc), false
      #
      sc = Oktest::ScopeNode.new(nil, tag: nil)
      assert_eq new_filter('*', '*', 'foo').scope_match?(sc), false
      assert_eq new_filter('*', '*', '*'  ).scope_match?(sc), false
    end
  end

  describe '#topic_match?()' do
    it "[!jpycj] returns true if topic target name matched to pattern." do
      to = Oktest::TopicNode.new(nil, Time)
      assert_eq new_filter('Time' , nil, nil).topic_match?(to), true
      assert_eq new_filter('*ime*', nil, nil).topic_match?(to), true
      assert_eq new_filter('*xy*' , nil, nil).topic_match?(to), false
    end
    it "[!6lfp1] returns true if tag name matched to pattern." do
      to = Oktest::TopicNode.new(nil, Time, tag: 'foo')
      [nil, '*bar*'].each do |pat|
        assert_eq new_filter(pat, nil, 'foo'      ).topic_match?(to), true
        assert_eq new_filter(pat, nil, 'f*'       ).topic_match?(to), true
        assert_eq new_filter(pat, nil, '{foo,bar}').topic_match?(to), true
        assert_eq new_filter(pat, nil, 'fooooo'   ).topic_match?(to), false
      end
    end
  end

  describe '#spec_match?()' do
    it "[!k45p3] returns true if spec description matched to pattern." do
      sp = Oktest::SpecLeaf.new("sample", tag: 'foo')
      assert_eq new_filter(nil, 'sample', nil).spec_match?(sp), true
      assert_eq new_filter(nil, '*samp*', nil).spec_match?(sp), true
      assert_eq new_filter(nil, '*abc*' , nil).spec_match?(sp), false
    end
    it "[!li3pd] returns true if tag name matched to pattern." do
      sp = Oktest::SpecLeaf.new("sample", tag: 'foo')
      [nil, '*bar*'].each do |pat|
        assert_eq new_filter(nil, pat, 'foo'      ).spec_match?(sp), true
        assert_eq new_filter(nil, pat, 'f*'       ).spec_match?(sp), true
        assert_eq new_filter(nil, pat, '{foo,bar}').spec_match?(sp), true
        assert_eq new_filter(nil, pat, 'fooooo'   ).spec_match?(sp), false
      end
    end
  end

end

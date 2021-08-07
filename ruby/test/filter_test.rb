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

end

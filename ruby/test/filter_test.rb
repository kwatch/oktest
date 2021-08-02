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

  def run_filter(topic_pattern, spec_pattern, tag_pattern)
    prepare()
    filter = Oktest::Filter.new(topic_pattern, spec_pattern, tag_pattern)
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

    it "can filter topics by full name." do
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter('Hello', nil, nil)
      assert_eq uncolor(sout), expected
    end

    it "can filter topics by pattern." do
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

    it "can filter nested topics." do
      expected = <<END
* Topic 832795
  * Float
    - [pass] spec example #3
    - [pass] spec example #4
END
      sout = run_filter('*loat*', nil, nil)
      assert_eq uncolor(sout), expected
    end

    it "can filter specs by full name." do
      expected = <<END
* Hello
  - [pass] hello spec
END
      sout = run_filter(nil, 'hello spec', nil)
      assert_eq uncolor(sout), expected
    end

    it "can filter specs by pattern." do
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

    it "can filter specs from nested topics." do
      expected = <<END
* Topic 832795
  * Float
    - [pass] spec example #4
END
      sout = run_filter(nil, '*#4', nil)
      assert_eq uncolor(sout), expected
    end

    it "can filter topics and specs by tag name." do
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
      #
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

    it "can filter by multiple tag name." do
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

  end

end

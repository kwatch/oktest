# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './init'


Object.new.instance_eval do   # Oktest::UtilHelper
  extend NanoTest

  test_target 'Oktest::UtilHelper#partial_regexp!()' do
    pat = <<'END'
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{12} ==}
END
    test_subject "[!9drtn] is available in both topic and spec blocks." do
      r1 = nil; r2 = nil
      Oktest.scope do
        topic "topic" do
          r1 = partial_regexp!(pat, '\A', '\z')
          spec "spec" do
            r2 = partial_regexp!(pat, "", "")
          end
        end
      end
      capture { Oktest.run() }
      test_eq? r1.class, Oktest::Util::PartialRegexp
      test_eq? r2.class, Oktest::Util::PartialRegexp
      test_eq? r1.inspect, <<'END'
partial_regexp(<<PREXP, '\A', '\z')
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{12} ==}
PREXP
END
      test_eq? r2.inspect, <<'END'
partial_regexp(<<PREXP, "", "")
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{12} ==}
PREXP
END
    end
  end

  test_target 'Oktest::UtilHelper#partial_regexp()' do
    test_subject "[!wo4hp] is available in both topic and spec blocks." do
    pat = <<'END'
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{12} ==}
END
      r1 = nil; r2 = nil
      Oktest.scope do
        topic "topic" do
          r1 = partial_regexp(pat, '\A', '\z')
          spec "spec" do
            r2 = partial_regexp(pat, "", "")
          end
        end
      end
      capture { Oktest.run() }
      test_eq? r1.class, Oktest::Util::PartialRegexp
      test_eq? r2.class, Oktest::Util::PartialRegexp
      test_eq? r1.inspect, <<'END'.chomp
/\A
\*\ \[Date\]\ \ \ \ \d\d\d\d-\d\d-\d\d\n
\*\ \[Secret\]\ \ [0-9a-f]{12}\n
\z/x
END
      test_eq? r2.inspect, <<'END'.chomp
/
\*\ \[Date\]\ \ \ \ \d\d\d\d-\d\d-\d\d\n
\*\ \[Secret\]\ \ [0-9a-f]{12}\n
/x
END
    end
  end

end

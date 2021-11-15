# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class UtilHelper_TC < TC

  describe Oktest::UtilHelper do

    describe '#partial_regexp()' do
      pat = <<'END'
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{12} ==}
END
      it "[!9drtn] is available in both topic and spec blocks." do
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
        assert_eq r1.class, Oktest::Util::PartialRegexp
        assert_eq r2.class, Oktest::Util::PartialRegexp
        assert_eq r1.inspect, <<'END'
partial_regexp(<<PREXP, '\A', '\z')
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{12} ==}
PREXP
END
        assert_eq r2.inspect, <<'END'
partial_regexp(<<PREXP, "", "")
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{12} ==}
PREXP
END
      end
    end

    describe '#partial_regexp!()' do
      it "[!wo4hp] is available in both topic and spec blocks." do
      pat = <<'END'
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{12} ==}
END
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
        assert_eq r1.class, Oktest::Util::PartialRegexp
        assert_eq r2.class, Oktest::Util::PartialRegexp
        assert_eq r1.inspect, <<'END'.chomp
/\A
\*\ \[Date\]\ \ \ \ \d\d\d\d-\d\d-\d\d\n
\*\ \[Secret\]\ \ [0-9a-f]{12}\n
\z/x
END
        assert_eq r2.inspect, <<'END'.chomp
/
\*\ \[Date\]\ \ \ \ \d\d\d\d-\d\d-\d\d\n
\*\ \[Secret\]\ \ [0-9a-f]{12}\n
/x
END
      end
    end

  end

end

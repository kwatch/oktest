# -*- coding: utf-8 -*-

###
### $Release: 1.2.0 $
### $Copyright: copyright(c) 2011-2021 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './initialize'


class Util_TC < TC
  include Oktest::Util

  describe Oktest::Util do

    describe '.file_line()' do
      it "[!4z65g] returns nil if file not exist or not a file." do
        assert_eq Oktest::Util.file_line("not-exist-file", 1), nil
        assert_eq Oktest::Util.file_line(".", 1), nil
      end
      it "[!162e1] returns line string." do
        lineno = __LINE__ + 2
        _ = <<END
U6XYR-SH08J
END
        assert_eq Oktest::Util.file_line(__FILE__, lineno), "U6XYR-SH08J\n"
      end
      it "[!4a2ji] caches recent file content for performance reason." do
        _ = Oktest::Util.file_line(__FILE__, 1)
        c = Oktest::Util.instance_variable_get('@__cache')
        assert c.is_a?(Array), "array object expected."
        assert_eq c[0], __FILE__
        assert_eq c[1][0], "# -*- coding: utf-8 -*-\n"
        assert_eq c[1][11], "class Util_TC < TC\n"
        #
        data1 = c[1]
        _ = Oktest::Util.file_line(__FILE__, 1)
        c2 = Oktest::Util.instance_variable_get('@__cache')
        assert c2[1].equal?(data1), "cache object changed unexpectedly."
      end
      it "[!wtrl5] recreates cache data if other file requested." do
        _ = Oktest::Util.file_line(__FILE__, 1)
        c = Oktest::Util.instance_variable_get('@__cache')
        data1 = c[1]
        #
        otherfile = File.join(File.dirname(__FILE__), "initialize.rb")
        _ = Oktest::Util.file_line(otherfile, 1)
        c3 = Oktest::Util.instance_variable_get('@__cache')
        assert_eq c3[0], otherfile
        assert ! c3[1].equal?(data1), "cache object should be recreated, but not."
      end
    end

    describe '.required_param_names_of_block()' do
      it "[!a9n46] returns nil if argument is nil." do
        assert_eq required_param_names_of_block(nil), nil
      end
      it "[!7m81p] returns empty array if block has no parameters." do
        pr = proc { nil }
        assert_eq required_param_names_of_block(pr), []
      end
      it "[!n3g63] returns parameter names of block." do
        pr = proc {|x, y, z| nil }
        assert_eq required_param_names_of_block(pr), [:x, :y, :z]
      end
      it "[!d5kym] collects only normal parameter names." do
        pr = proc {|x, y, z=1, *rest, a: 1, b: 2, &blk| nil }
        assert_eq required_param_names_of_block(pr), [:x, :y]
        pr = proc {|a: 1, b: 2, &blk| nil }
        assert_eq required_param_names_of_block(pr), []
        pr = proc {|*rest, &blk| nil }
        assert_eq required_param_names_of_block(pr), []
      end
    end

    describe '.keyword_param_names_of_block()' do
      it "[!p6qqp] returns keyword param names of proc object." do
        pr = proc {|a, b=nil, c: nil, d: 1| nil }
        assert_eq keyword_param_names_of_block(pr), [:c, :d]
        pr = proc {|a, b=nil| nil }
        assert_eq keyword_param_names_of_block(pr), []
      end
    end

    describe '.strfold()' do
      it "[!wb7m8] returns string as it is if string is not long." do
        s = "*" * 79
        assert_eq strfold(s, 80), s
        s = "*" * 80
        assert_eq strfold(s, 80), s
      end
      it "[!a2igb] shorten string if it is enough long." do
        expected = "*" * 77 + "..."
        s = "*" * 81
        assert_eq strfold(s, 80), expected
      end
      it "[!0gjye] supports non-ascii characters." do
        expected = "あ" * 38 + "..."
        s = "あ" * 41
        assert_eq strfold(s, 80), expected
        #
        expected = "x" + "あ" * 37 + "..."
        s = "x" + "あ" * 40
        assert_eq strfold(s, 80), expected
      end
    end

    describe '.hhmmss()' do
      it "[!shyl1] converts 400953.444 into '111:22:33.4'." do
        x = 111*60*60 + 22*60 + 33.444
        assert_eq x, 400953.444
        assert_eq hhmmss(x), "111:22:33.4"
      end
      it "[!vyi2v] converts 5025.678 into '1:23:45.7'." do
        x = 1*60*60 + 23*60 + 45.678
        assert_eq x, 5025.678
        assert_eq hhmmss(x), "1:23:45.7"
      end
      it "[!pm4xf] converts 754.888 into '12:34.9'." do
        x = 12*60 + 34.888
        assert_eq x, 754.888
        assert_eq hhmmss(x), "12:34.9"
      end
      it "[!lwewr] converts 83.444 into '1:23.4'." do
        x = 1*60 + 23.444
        assert_eq x, 83.444
        assert_eq hhmmss(x), "1:23.4"
      end
      it "[!ijx52] converts 56.8888 into '56.9'." do
        x = 56.8888
        assert_eq hhmmss(x), "56.9"
      end
      it "[!2kra2] converts 9.777 into '9.78'." do
        x = 9.777
        assert_eq hhmmss(x), "9.78"
      end
      it "[!4aomb] converts 0.7777 into '0.778'." do
        x = 0.7777
        assert_eq hhmmss(x), "0.778"
      end
    end

    describe '.hhmmss()' do
      it "[!wf4ns] calculates unified diff from two text strings." do
        s1 = <<'END'
Haruhi
Mikuru
Yuki
END
        s2 = <<'END'
Haruhi
Michiru
Yuki
END
        expected = <<'END'
--- old
+++ new
@@ -1,4 +1,4 @@
 Haruhi
-Mikuru
+Michiru
 Yuki
END
        diff = Oktest::Util.unified_diff(s1, s2)
        assert_eq diff, expected
      end
    end

    describe '.unified_diff()' do
      it "[!rnx4f] checks whether text string ends with newline char." do
        s1 = <<'END'
Haruhi
Mikuru
Yuki
END
        s2 = s1
        #
        expected1 = <<'END'
--- old
+++ new
@@ -1,4 +1,4 @@
 Haruhi
 Mikuru
-Yuki\ No newline at end of string
+Yuki
END
        diff = Oktest::Util.unified_diff(s1.chomp, s2)
        assert_eq diff, expected1
        #
        expected2 = <<'END'
--- old
+++ new
@@ -1,4 +1,4 @@
 Haruhi
 Mikuru
-Yuki
+Yuki\ No newline at end of string
END
        diff = Oktest::Util.unified_diff(s1, s2.chomp)
        assert_eq diff, expected2
      end
    end

    describe '.diff_unified()' do
      it "[!ulyq5] returns unified diff string of two text strings." do
        s1 = <<'END'
Haruhi
Mikuru
Yuki
END
        s2 = <<'END'
Haruhi
Michiru
Yuki
END
        expected = <<'END'
--- old
+++ new
@@ -1,3 +1,3 @@
 Haruhi
-Mikuru
+Michiru
 Yuki
END
        diff = Oktest::Util.diff_unified(s1, s2)
        assert_eq diff, expected
      end
      it "[!6tgum] detects whether char at end of file is newline or not." do
        s1 = <<'END'
Haruhi
Mikuru
Yuki
END
        s2 = s1
        #
        expected1 = <<'END'
--- old
+++ new
@@ -1,3 +1,3 @@
 Haruhi
 Mikuru
-Yuki
\ No newline at end of file
+Yuki
END
        diff = Oktest::Util.diff_unified(s1.chomp, s2)
        assert_eq diff, expected1
        #
        expected2 = <<'END'
--- old
+++ new
@@ -1,3 +1,3 @@
 Haruhi
 Mikuru
-Yuki
+Yuki
\ No newline at end of file
END
        diff = Oktest::Util.diff_unified(s1, s2.chomp)
        assert_eq diff, expected2
      end
    end

    describe '.partial_regexp!()' do
      it "[!peyu4] returns PartialRegexp object which inspect string is function call styel." do
        pattern_str = <<'HEREDOC'
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{8} ==}
HEREDOC
        prexp = Oktest::Util.partial_regexp!(pattern_str)
        assert_eq prexp.class, Oktest::Util::PartialRegexp
        assert_eq prexp.pattern_string, pattern_str
      end
    end

    describe '.partial_regexp()' do
      it "[!ostkw] raises error if mark has no space or has more than two spaces." do
        assert_exc(ArgumentError, "\"{====}\": mark should contain only one space (ex: `{== ==}`).") do
          Oktest::Util.partial_regexp("xxx", '\A', '\z', "{====}")
        end
        assert_exc(ArgumentError, "\"{= == =}\": mark should contain only one space (ex: `{== ==}`).") do
          Oktest::Util.partial_regexp("xxx", '', '', "{= == =}")
        end
      end
      it "[!wn524] returns PartialRegexp object which inspect string is regexp literal style." do
        pattern_str = <<'HEREDOC'
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{8} ==}
HEREDOC
        prexp = Oktest::Util.partial_regexp(pattern_str)
        assert_eq prexp.class, Oktest::Util::PartialRegexp
        assert_eq prexp.pattern_string, nil
      end
    end

  end

  describe Oktest::Util::PartialRegexp do
    describe '#inspect()' do
      it "[!uyh31] returns function call style string if @pattern_string is set." do
        prexp = Oktest::Util.partial_regexp!(<<'HEREHERE')
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{8} ==}
HEREHERE
        assert_eq prexp.inspect, <<'HEREHERE'
partial_regexp(<<PREXP, '\A', '\z')
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{8} ==}
PREXP
HEREHERE
      end
      it "[!ts9v4] returns regexp literal style string if @pattern_string is not set." do
        prexp = Oktest::Util.partial_regexp(<<'HEREHERE')
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{8} ==}
HEREHERE
        assert_eq prexp.inspect, <<'HEREHERE'.chomp
/\A
\*\ \[Date\]\ \ \ \ \d\d\d\d-\d\d-\d\d\n
\*\ \[Secret\]\ \ [0-9a-f]{8}\n
\z/x
HEREHERE
      end
    end
  end

end

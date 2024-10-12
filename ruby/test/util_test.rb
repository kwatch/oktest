# -*- coding: utf-8 -*-
# frozen_string_literal: true

###
### $Release: 1.5.0 $
### $Copyright: copyright(c) 2011-2024 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

require_relative './init'


class Util__Test
  extend NanoTest
  extend Oktest::Util

  test_target 'Oktest::Util.file_line()' do
    test_subject "[!4z65g] returns nil if file not exist or not a file." do
      test_eq? Oktest::Util.file_line("not-exist-file", 1), nil
      test_eq? Oktest::Util.file_line(".", 1), nil
    end
    test_subject "[!162e1] returns line string." do
      lineno = __LINE__ + 2
      _ = <<END
U6XYR-SH08J
END
      test_eq? Oktest::Util.file_line(__FILE__, lineno), "U6XYR-SH08J\n"
    end
    test_subject "[!4a2ji] caches recent file content for performance reason." do
      _ = Oktest::Util.file_line(__FILE__, 1)
      c = Oktest::Util.instance_variable_get('@__cache')
      test_ok? c.is_a?(Array), msg: "array object expected."
      test_eq? c[0], __FILE__
      test_eq? c[1][0], "# -*- coding: utf-8 -*-\n"
      test_eq? c[1][16], "  test_target 'Oktest::Util.file_line()' do\n"
      #
      data1 = c[1]
      _ = Oktest::Util.file_line(__FILE__, 1)
      c2 = Oktest::Util.instance_variable_get('@__cache')
      test_ok? c2[1].equal?(data1), msg: "cache object changed unexpectedly."
    end
    test_subject "[!wtrl5] recreates cache data if other file requested." do
      _ = Oktest::Util.file_line(__FILE__, 1)
      c = Oktest::Util.instance_variable_get('@__cache')
      data1 = c[1]
      #
      otherfile = File.join(File.dirname(__FILE__), "init.rb")
      _ = Oktest::Util.file_line(otherfile, 1)
      c3 = Oktest::Util.instance_variable_get('@__cache')
      test_eq? c3[0], otherfile
      test_ok? ! c3[1].equal?(data1), msg: "cache object should be recreated, but not."
    end
  end

  test_target 'Oktest::Util.required_param_names_of_block()' do
    test_subject "[!a9n46] returns nil if argument is nil." do
      test_eq? required_param_names_of_block(nil), nil
    end
    test_subject "[!7m81p] returns empty array if block has no parameters." do
      pr = proc { nil }
      test_eq? required_param_names_of_block(pr), []
    end
    test_subject "[!n3g63] returns parameter names of block." do
      pr = proc {|x, y, z| nil }
      test_eq? required_param_names_of_block(pr), [:x, :y, :z]
    end
    test_subject "[!d5kym] collects only normal parameter names." do
      pr = proc {|x, y, z=1, *rest, a: 1, b: 2, &blk| nil }
      test_eq? required_param_names_of_block(pr), [:x, :y]
      pr = proc {|a: 1, b: 2, &blk| nil }
      test_eq? required_param_names_of_block(pr), []
      pr = proc {|*rest, &blk| nil }
      test_eq? required_param_names_of_block(pr), []
    end
  end

  test_target 'Oktest::Util.keyword_param_names_of_block()' do
    test_subject "[!p6qqp] returns keyword param names of proc object." do
      pr = proc {|a, b=nil, c: nil, d: 1| nil }
      test_eq? keyword_param_names_of_block(pr), [:c, :d]
      pr = proc {|a, b=nil| nil }
      test_eq? keyword_param_names_of_block(pr), []
    end
  end

  test_target 'Oktest::Util.strfold()' do
    test_subject "[!wb7m8] returns string as test_subject is if string is not long." do
      s = "*" * 79
      test_eq? strfold(s, 80), s
      s = "*" * 80
      test_eq? strfold(s, 80), s
    end
    test_subject "[!a2igb] shorten string if test_subject is enough long." do
      expected = "*" * 77 + "..."
      s = "*" * 81
      test_eq? strfold(s, 80), expected
    end
    test_subject "[!0gjye] supports non-ascii characters." do
      expected = "あ" * 38 + "..."
      s = "あ" * 41
      test_eq? strfold(s, 80), expected
      #
      expected = "x" + "あ" * 37 + "..."
      s = "x" + "あ" * 40
      test_eq? strfold(s, 80), expected
    end
  end

  test_target 'Oktest::Util.hhmmss()' do
    test_subject "[!shyl1] converts 400953.444 into '111:22:33.4'." do
      x = 111*60*60 + 22*60 + 33.444
      test_eq? x, 400953.444
      test_eq? hhmmss(x), "111:22:33.4"
    end
    test_subject "[!vyi2v] converts 5025.678 into '1:23:45.7'." do
      x = 1*60*60 + 23*60 + 45.678
      test_eq? x, 5025.678
      test_eq? hhmmss(x), "1:23:45.7"
    end
    test_subject "[!pm4xf] converts 754.888 into '12:34.9'." do
      x = 12*60 + 34.888
      test_eq? x, 754.888
      test_eq? hhmmss(x), "12:34.9"
    end
    test_subject "[!lwewr] converts 83.444 into '1:23.4'." do
      x = 1*60 + 23.444
      test_eq? x, 83.444
      test_eq? hhmmss(x), "1:23.4"
    end
    test_subject "[!ijx52] converts 56.8888 into '56.9'." do
      x = 56.8888
      test_eq? hhmmss(x), "56.9"
    end
    test_subject "[!2kra2] converts 9.777 into '9.78'." do
      x = 9.777
      test_eq? hhmmss(x), "9.78"
    end
    test_subject "[!4aomb] converts 0.7777 into '0.778'." do
      x = 0.7777
      test_eq? hhmmss(x), "0.778"
    end
  end

  test_target 'Oktest::Util.hhmmss()' do
    test_subject "[!wf4ns] calculates unified diff from two text strings." do
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
      test_eq? diff, expected
    end
  end

  test_target 'Oktest::Util.unified_diff()' do
    test_subject "[!rnx4f] checks whether text string ends with newline char." do
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
      test_eq? diff, expected1
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
      test_eq? diff, expected2
    end
  end

  test_target 'Oktest::Util.diff_unified()' do
    test_subject "[!ulyq5] returns unified diff string of two text strings." do
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
      test_eq? diff, expected
    end
    test_subject "[!6tgum] detects whether char at end of file is newline or not." do
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
      test_eq? diff, expected1
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
      test_eq? diff, expected2
    end
  end

  test_target 'Oktest::Util.partial_regexp!()' do
    test_subject "[!peyu4] returns PartialRegexp object which inspect string is function call styel." do
        pattern_str = <<'HEREDOC'
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{8} ==}
HEREDOC
      prexp = Oktest::Util.partial_regexp!(pattern_str)
      test_eq? prexp.class, Oktest::Util::PartialRegexp
      test_eq? prexp.pattern_string, pattern_str
    end
  end

  test_target 'Oktest::Util.partial_regexp()' do
    test_subject "[!ostkw] raises error if mark has no space or has more than two spaces." do
      exc = test_exception? ArgumentError do
        Oktest::Util.partial_regexp("xxx", '\A', '\z', "{====}")
      end
      test_eq? exc.message, "\"{====}\": mark should contain only one space (ex: `{== ==}`)."
      exc = test_exception? ArgumentError do
        Oktest::Util.partial_regexp("xxx", '', '', "{= == =}")
      end
      test_eq? exc.message, "\"{= == =}\": mark should contain only one space (ex: `{== ==}`)."
    end
    test_subject "[!wn524] returns PartialRegexp object which inspect string is regexp literal style." do
      pattern_str = <<'HEREDOC'
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{8} ==}
HEREDOC
      prexp = Oktest::Util.partial_regexp(pattern_str)
      test_eq? prexp.class, Oktest::Util::PartialRegexp
      test_eq? prexp.pattern_string, nil
    end
  end

end


class Util_PartialRegexp__Test
  extend NanoTest

  test_target 'Oktest::Util::PartialRegexp#inspect()' do
    test_subject "[!uyh31] returns function call style string if @pattern_string is set." do
      prexp = Oktest::Util.partial_regexp!(<<'HEREHERE')
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{8} ==}
HEREHERE
      test_eq? prexp.inspect, <<'HEREHERE'
partial_regexp(<<PREXP, '\A', '\z')
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{8} ==}
PREXP
HEREHERE
    end
    test_subject "[!ts9v4] returns regexp literal style string if @pattern_string is not set." do
      prexp = Oktest::Util.partial_regexp(<<'HEREHERE')
* [Date]    {== \d\d\d\d-\d\d-\d\d ==}
* [Secret]  {== [0-9a-f]{8} ==}
HEREHERE
      test_eq? prexp.inspect, <<'HEREHERE'.chomp
/\A
\*\ \[Date\]\ \ \ \ \d\d\d\d-\d\d-\d\d\n
\*\ \[Secret\]\ \ [0-9a-f]{8}\n
\z/x
HEREHERE
    end
  end

end

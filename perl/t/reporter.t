###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

use strict;
use warnings;

use Test::More tests => 19;

use Oktest;


sub TARGET { return undef; }

sub _run_with_capture {
    my %opts = @_;
    my $output = Oktest::Util::capture_stdout {
        Oktest::run(%opts);
    };
    $output =~ s/elapsed: (\d\.\d\d\d)/elapsed: 0.000/;
    return $output;
}


sub _setup_successful_test {
    Oktest::__clear();
    topic "ClassName", sub {
        topic "#method()", sub {
            spec "spec1", sub { OK (1+1) == 2 };
            spec "spec2", sub { OK (1-1) == 0 };
        };
        topic "#method2()", sub {
            spec "spec3", sub { OK (1*1) == 1 };
        };
    };
}


sub _setup_failure_test {
    Oktest::__clear();
    topic "ClassName", sub {
        topic "#methodA()", sub {
            spec "spec1", sub { OK (1+1) == 2 };
            spec "spec2", sub { OK (1+1) == 1 };
            spec "spec3", sub { OK (1-1) == 0 };
        };
        topic "#methodB()", sub {
            spec "spec4", sub { OK (1+1) == 0 };
            spec "spec5", sub { die "<ERROR>\n" };
        };
    };
}


sub _setup_casewhen_test {
    Oktest::__clear();
    topic "Class", sub {
        topic "#method()", sub {
            spec "S1", sub { OK(1+1) == 2 };
            case_when "value is positive...", sub {
                spec "S2", sub { OK(1+1) == 2 };
            };
            case_when "value is negative...", sub {
                spec "S3", sub { OK(1+1) == 2 };
            };
        };
    };
}


sub _setup_misc_test {
    Oktest::__clear();
    topic "ClassName", sub {
        topic "#methodA()", sub {
            spec "spec1", sub { OK (1+1) == 2 };
            spec "spec2", sub { skip_when 1==1, "not supported" };
            spec "spec3", sub { TODO "not implemented yet" };
        };
    };
}


for (TARGET('Oktest::Runner::TapReporter')) {

    #: prints test plan for TAP.
    #: prints topic names.
    #: prints spec descriptions.
    #: prints elapsed time.
    {
        my $expected =
            "1..3\n" .
            "## * ClassName\n" .
            "##   * #method()\n" .
            "ok 1 - spec1\n" .
            "ok 2 - spec2\n" .
            "##   * #method2()\n" .
            "ok 3 - spec3\n" .
            "## ok:3, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
            "";
        _setup_successful_test();
        my $actual = _run_with_capture();
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports error message when assertion failed.
    {
        my $expected =
            "1..5\n" .
            "## * ClassName\n" .
            "##   * #methodA()\n" .
            "ok 1 - spec1\n" .
            "not ok 2 - spec2\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [Failed] * ClassName > #methodA() > spec2\n" .
            "# Assertion: \$actual == \$expected : failed.\n" .
            "#   \$actual:   2\n" .
            "#   \$expected: 1\n" .
            "# File 't/reporter.t', line 46:\n" .
            "#     spec \"spec2\", sub { OK (1+1) == 1 };\n" .
            "# ----------------------------------------------------------------------\n" .
            "ok 3 - spec3\n" .
            "##   * #methodB()\n" .
            "not ok 4 - spec4\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [Failed] * ClassName > #methodB() > spec4\n" .
            "# Assertion: \$actual == \$expected : failed.\n" .
            "#   \$actual:   2\n" .
            "#   \$expected: 0\n" .
            "# File 't/reporter.t', line 50:\n" .
            "#     spec \"spec4\", sub { OK (1+1) == 0 };\n" .
            "# ----------------------------------------------------------------------\n" .
            "not ok 5 - spec5\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [ERROR] * ClassName > #methodB() > spec5\n" .
            "# <ERROR>\n" .
            "# ----------------------------------------------------------------------\n" .
            "## ok:2, failed:2, error:1, skipped:0, todo:0  (elapsed: 0.000)\n" .
            "";
        _setup_failure_test();
        my $actual = _run_with_capture();
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports 'case_when'.
    {
        my $expected =
            "1..3\n" .
            "## * Class\n" .
            "##   * #method()\n" .
            "ok 1 - S1\n" .
            "##     - When value is positive...\n" .
            "ok 2 - S2\n" .
            "##     - When value is negative...\n" .
            "ok 3 - S3\n" .
            "## ok:3, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
            "";
        _setup_casewhen_test();
        my $actual = _run_with_capture(style=>'tap');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports skipped and TODO items.
    {
        my $expected =
            "1..3\n" .
            "## * ClassName\n" .
            "##   * #methodA()\n" .
            "ok 1 - spec1\n" .
            "ok 2 - spec2 # skip - not supported\n" .
            "not ok 3 - spec3 # TODO - not implemented yet\n" .
            "## ok:1, failed:0, error:0, skipped:1, todo:1  (elapsed: 0.000)\n" .
            "";
        _setup_misc_test();
        my $actual = _run_with_capture();
        is($actual, $expected);
        #
        Oktest::__clear();
    }

}


for (TARGET('Oktest::Runner::VerboseReporter')) {

    #: reports topic names and spec descriptions.
    {
        my $expected =
            "* ClassName\n" .
            "  * #method()\n" .
            "    - [ok] spec1\n" .
            "    - [ok] spec2\n" .
            "  * #method2()\n" .
            "    - [ok] spec3\n" .
            "## ok:3, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
            "";
        _setup_successful_test();
        my $actual = _run_with_capture(style=>'verbose');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports error message when assertion failed.
    {
        my $expected =
            "* ClassName\n" .
            "  * #methodA()\n" .
            "    - [ok] spec1\n" .
            "    - [Failed] spec2\n" .
            "    - [ok] spec3\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [Failed] * ClassName > #methodA() > spec2\n" .
            "# Assertion: \$actual == \$expected : failed.\n" .
            "#   \$actual:   2\n" .
            "#   \$expected: 1\n" .
            "# File 't/reporter.t', line 46:\n" .
            "#     spec \"spec2\", sub { OK (1+1) == 1 };\n" .
            "# ----------------------------------------------------------------------\n" .
            "  * #methodB()\n" .
            "    - [Failed] spec4\n" .
            "    - [ERROR] spec5\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [Failed] * ClassName > #methodB() > spec4\n" .
            "# Assertion: \$actual == \$expected : failed.\n" .
            "#   \$actual:   2\n" .
            "#   \$expected: 0\n" .
            "# File 't/reporter.t', line 50:\n" .
            "#     spec \"spec4\", sub { OK (1+1) == 0 };\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [ERROR] * ClassName > #methodB() > spec5\n" .
            "# <ERROR>\n" .
            "# ----------------------------------------------------------------------\n" .
            "## ok:2, failed:2, error:1, skipped:0, todo:0  (elapsed: 0.000)\n" .
            "";
        _setup_failure_test();
        my $actual = _run_with_capture(style=>'verbose');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports 'case_when'.
    {
        my $expected =
            "* Class\n" .
            "  * #method()\n" .
            "    - [ok] S1\n" .
            "    - When value is positive...\n" .
            "      - [ok] S2\n" .
            "    - When value is negative...\n" .
            "      - [ok] S3\n" .
            "## ok:3, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
            "";
        _setup_casewhen_test();
        my $actual = _run_with_capture(style=>'verbose');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports skipped and TODO items.
    {
        my $expected =
            "* ClassName\n" .
            "  * #methodA()\n" .
            "    - [ok] spec1\n" .
            "    - [Skipped] spec2 ## not supported\n" .
            "    - [TODO] spec3 ## not implemented yet\n" .
            "## ok:1, failed:0, error:0, skipped:1, todo:1  (elapsed: 0.000)\n" .
            "";
        _setup_misc_test();
        my $actual = _run_with_capture(style=>'verbose');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports details of skipped and/or TODO items.
    {
        my $expected =
            "* ClassName\n" .
            "  * #methodA()\n" .
            "    - [ok] spec1\n" .
            "    - [Skipped] spec2 ## not supported\n" .
            "    - [TODO] spec3 ## not implemented yet\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [Skipped] * ClassName > #methodA() > spec2\n" .
            "# Reason: not supported\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [TODO] * ClassName > #methodA() > spec3\n" .
            "# Description: not implemented yet\n" .
            "# ----------------------------------------------------------------------\n" .
            "## ok:1, failed:0, error:0, skipped:1, todo:1  (elapsed: 0.000)\n" .
            "";
        _setup_misc_test();
        my $actual = _run_with_capture(style=>'verbose', report_skipped=>1, report_todo=>1);
        is($actual, $expected);
        #
        Oktest::__clear();
    }

}


for (TARGET('Oktest::Runner::SimpleReporter')) {

    #: reports topic names.
    {
        my $expected =
            "* ClassName\n" .
            "  * #method(): ..\n" .
            "  * #method2(): .\n" .
            "## ok:3, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
            "";
        _setup_successful_test();
        my $actual = _run_with_capture(style=>'simple');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports error message when assertion failed.
    {
        my $expected =
            "* ClassName\n" .
            "  * #methodA(): .f.\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [Failed] * ClassName > #methodA() > spec2\n" .
            "# Assertion: \$actual == \$expected : failed.\n" .
            "#   \$actual:   2\n" .
            "#   \$expected: 1\n" .
            "# File 't/reporter.t', line 46:\n" .
            "#     spec \"spec2\", sub { OK (1+1) == 1 };\n" .
            "# ----------------------------------------------------------------------\n" .
            "  * #methodB(): fE\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [Failed] * ClassName > #methodB() > spec4\n" .
            "# Assertion: \$actual == \$expected : failed.\n" .
            "#   \$actual:   2\n" .
            "#   \$expected: 0\n" .
            "# File 't/reporter.t', line 50:\n" .
            "#     spec \"spec4\", sub { OK (1+1) == 0 };\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [ERROR] * ClassName > #methodB() > spec5\n" .
            "# <ERROR>\n" .
            "# ----------------------------------------------------------------------\n" .
            "## ok:2, failed:2, error:1, skipped:0, todo:0  (elapsed: 0.000)\n" .
            "";
        _setup_failure_test();
        my $actual = _run_with_capture(style=>'simple');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: ignores 'case_when'.
    {
        my $expected =
            "* Class\n" .
            "  * #method(): ...\n" .
            "## ok:3, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
            "";
        _setup_casewhen_test();
        my $actual = _run_with_capture(style=>'simple');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports skipped and TODO items.
    {
        my $expected =
            "* ClassName\n" .
            "  * #methodA(): .st\n" .
            "## ok:1, failed:0, error:0, skipped:1, todo:1  (elapsed: 0.000)\n" .
            "";
        _setup_misc_test();
        my $actual = _run_with_capture(style=>'simple');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports details of skipped and/or TODO items.
    {
        my $expected =
            "* ClassName\n" .
            "  * #methodA(): .st\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [Skipped] * ClassName > #methodA() > spec2\n" .
            "# Reason: not supported\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [TODO] * ClassName > #methodA() > spec3\n" .
            "# Description: not implemented yet\n" .
            "# ----------------------------------------------------------------------\n" .
            "## ok:1, failed:0, error:0, skipped:1, todo:1  (elapsed: 0.000)\n" .
            "";
        _setup_misc_test();
        my $actual = _run_with_capture(style=>'simple', report_skipped=>1, report_todo=>1);
        is($actual, $expected);
        #
        Oktest::__clear();
    }

}


for (TARGET('Oktest::Runner::PlainReporter')) {

    #: reports topic names.
    {
        my $expected =
            "...\n" .
            "## ok:3, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
            "";
        _setup_successful_test();
        my $actual = _run_with_capture(style=>'plain');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports error message when assertion failed.
    {
        my $expected =
            ".f.fE\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [Failed] * ClassName > #methodA() > spec2\n" .
            "# Assertion: \$actual == \$expected : failed.\n" .
            "#   \$actual:   2\n" .
            "#   \$expected: 1\n" .
            "# File 't/reporter.t', line 46:\n" .
            "#     spec \"spec2\", sub { OK (1+1) == 1 };\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [Failed] * ClassName > #methodB() > spec4\n" .
            "# Assertion: \$actual == \$expected : failed.\n" .
            "#   \$actual:   2\n" .
            "#   \$expected: 0\n" .
            "# File 't/reporter.t', line 50:\n" .
            "#     spec \"spec4\", sub { OK (1+1) == 0 };\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [ERROR] * ClassName > #methodB() > spec5\n" .
            "# <ERROR>\n" .
            "# ----------------------------------------------------------------------\n" .
            "## ok:2, failed:2, error:1, skipped:0, todo:0  (elapsed: 0.000)\n" .
            "";
        _setup_failure_test();
        my $actual = _run_with_capture(style=>'plain');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: ignores 'case_when'.
    {
        my $expected =
            "...\n" .
            "## ok:3, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
            "";
        _setup_casewhen_test();
        my $actual = _run_with_capture(style=>'plain');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports skipped and TODO items.
    {
        my $expected =
            ".st\n" .
            "## ok:1, failed:0, error:0, skipped:1, todo:1  (elapsed: 0.000)\n" .
            "";
        _setup_misc_test();
        my $actual = _run_with_capture(style=>'plain');
        is($actual, $expected);
        #
        Oktest::__clear();
    }

    #: reports details of skipped and/or TODO items.
    {
        my $expected =
            ".st\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [Skipped] * ClassName > #methodA() > spec2\n" .
            "# Reason: not supported\n" .
            "# ----------------------------------------------------------------------\n" .
            "# [TODO] * ClassName > #methodA() > spec3\n" .
            "# Description: not implemented yet\n" .
            "# ----------------------------------------------------------------------\n" .
            "## ok:1, failed:0, error:0, skipped:1, todo:1  (elapsed: 0.000)\n" .
            "";
        _setup_misc_test();
        my $actual = _run_with_capture(style=>'plain', report_skipped=>1, report_todo=>1);
        is($actual, $expected);
        #
        Oktest::__clear();
    }

}

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

use strict;
use warnings;
use Test::More tests => 29;


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



for (TARGET('Oktest::Runner::DefaultRunner')) {


    for (TARGET('::new()')) {

        #: returns a runner object.
        {
            my $runner = Oktest::Runner::DefaultRunner->new();
            isa_ok($runner, 'Oktest::Runner::DefaultRunner');
        }

    }


    for (TARGET('#run_all()')) {

        #: finds and runs specs recursively.
        {
            Oktest::__clear();
            #
            my @called = ();
            target "ClassName", sub {
                target "#method()", sub {
                    spec "spec1", sub { push(@called, 'spec1') };
                    spec "spec2", sub { push(@called, 'spec2') };
                };
                target "#method2()", sub {
                    spec "spec3", sub { push(@called, 'spec3') };
                };
            };
            is($#called, -1);
            #
            _run_with_capture();
            is($#called, 2);
            is_deeply(\@called, ['spec1', 'spec2', 'spec3']);
        }

    }


    for (TARGET('#run_target()')) {

        #: calls 'before_all' and 'after_all' blocks.
        {
            Oktest::__clear();
            #
            target "Parent", sub {
                before_all { print "[Parent] before_all()\n" };
                after_all  { print "[Parent] after_all()\n" };
                before     { print "[Parent] before()\n" };
                after      { print "[Parent] after()\n" };
                #
                target "Child1", sub {
                    before_all { print "[Child1] before_all()\n" };
                    after_all  { print "[Child1] after_all()\n" };
                    before     { print "[Child1] before()\n" };
                    after      { print "[Child1] after()\n" };
                    spec "spec1", sub { OK (1+1) == 2 };
                    spec "spec2", sub { OK ('a') eq 'a' };
                };
                #
            };
            #
            my $expected =
                '1..2\n' .
                '## * Parent\n' .
                '[Parent] before_all()\n' .
                '##   * Child1\n' .
                '[Child1] before_all()\n' .
                '[Parent] before()\n' .
                '[Child1] before()\n' .
                '[Child1] after()\n' .
                '[Parent] after()\n' .
                'ok 1 - spec1\n' .
                '[Parent] before()\n' .
                '[Child1] before()\n' .
                '[Child1] after()\n' .
                '[Parent] after()\n' .
                'ok 2 - spec2\n' .
                '[Child1] after_all()\n' .
                '[Parent] after_all()\n' .
                '## ok:2, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n' .
                '';
            $expected =~ s/\\n/\n/g;
            my $actual = _run_with_capture();
            is($actual, $expected);
        }

        #: calls 'after_all' even when errors happened in specs or child targets.
        {
            Oktest::__clear();
            #
            target "Parent", sub {
                before_all { print "[Parent] before_all()\n" };
                after_all  { print "[Parent] after_all()\n" };
                #
                target "Child1", sub {
                    before_all { print "[Child1] before_all()\n" };
                    after_all  { print "[Child1] after_all()\n" };
                    spec "spec1", sub { OK (1+1) == 1 };
                };
                #
                target "Child2", sub {
                    before_all { print "[Child2] before_all()\n" };
                    after_all  { print "[Child2] after_all()\n" };
                    spec "spec2", sub { OK ('a') eq 'b' };
                };
                #
            };
            #
            my $expected =
                '1..2\n' .
                '## * Parent\n' .
                '[Parent] before_all()\n' .
                '##   * Child1\n' .
                '[Child1] before_all()\n' .
                'not ok 1 - spec1\n' .
                '# ----------------------------------------------------------------------\n' .
                '# [Failed] * Parent > Child1 > spec1\n' .
                '# Assertion: $actual == $expected : failed.\n' .
                '#   $actual:   2\n' .
                '#   $expected: 1\n' .
                '# File \'t/runner.t\', line 127:\n' .
                '#     spec "spec1", sub { OK (1+1) == 1 };\n' .
                '# ----------------------------------------------------------------------\n' .
                '[Child1] after_all()\n' .
                '##   * Child2\n' .
                '[Child2] before_all()\n' .
                'not ok 2 - spec2\n' .
                '# ----------------------------------------------------------------------\n' .
                '# [Failed] * Parent > Child2 > spec2\n' .
                '# Assertion: $actual eq $expected : failed.\n' .
                '#   $actual:   \'a\'\n' .
                '#   $expected: \'b\'\n' .
                '# File \'t/runner.t\', line 133:\n' .
                '#     spec "spec2", sub { OK (\'a\') eq \'b\' };\n' .
                '# ----------------------------------------------------------------------\n' .
                '[Child2] after_all()\n' .
                '[Parent] after_all()\n' .
                '## ok:0, failed:2, error:0, skipped:0, todo:0  (elapsed: 0.000)\n' .
                '';
            $expected =~ s/\\n/\n/g;
            my $actual = _run_with_capture();
            is($actual, $expected);
        }

#        #: calls targes and specs in mixed order
#        {
#            Oktest::__clear();
#            target "Example", sub {
#                target "T1", sub {
#                    spec "S1", sub { OK(1+1) == 2 };
#                };
#                spec "S2", sub { OK(1+1) == 2 };
#                target "T3", sub {
#                    spec "S3", sub { OK(1+1) == 2 };
#                };
#                spec "S4", sub { OK(1+1) == 2 };
#            };
#            my $expected =
#                "1..4\n" .
#                "## * Example\n" .
#                "##   * T1\n" .
#                "ok 1 - S1\n" .
#                "ok 2 - S2\n" .
#                "##   * T3\n" .
#                "ok 3 - S3\n" .
#                "ok 4 - S4\n" .
#                "## ok:4, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
#                "";
#            my $actual = _run_with_capture();
#            use Data::Dumper;
#            print STDERR "\033[0;31m*** debug: ".__LINE__.': $actual=', Dumper($actual), "\033[0m";
#            is($actual, $expected);
#        }

    }


    for (TARGET('#run_spec()')) {

        #: calls 'before' and 'after' blocks in ancestor's targets.
        {
            Oktest::__clear();
            #
            target "Parent", sub {
                my ($this) = @_;
                before     { print "[Parent] before()\n" };
                after      { print "[Parent] after()\n" };
                #
                target "Child1", sub {
                    my ($this) = @_;
                    before     { print "[Child1] before()\n" };
                    after      { print "[Child1] after()\n" };
                    spec "spec1", sub { OK (1+1) == 2 };
                    spec "spec2", sub { OK ('a') eq 'a' };
                };
                #
                target "Child2", sub {
                    my ($this) = @_;
                    before     { print "[Child2] before()\n" };
                    after      { print "[Child2] after()\n" };
                    spec "spec3", sub { OK (1+1) == 2 };
                    spec "spec4", sub { OK ('a') eq 'a' };
                };
                #
            };
            #
            my $expected =
                '1..4\n' .
                '## * Parent\n' .
                '##   * Child1\n' .
                '[Parent] before()\n' .
                '[Child1] before()\n' .
                '[Child1] after()\n' .
                '[Parent] after()\n' .
                'ok 1 - spec1\n' .
                '[Parent] before()\n' .
                '[Child1] before()\n' .
                '[Child1] after()\n' .
                '[Parent] after()\n' .
                'ok 2 - spec2\n' .
                '##   * Child2\n' .
                '[Parent] before()\n' .
                '[Child2] before()\n' .
                '[Child2] after()\n' .
                '[Parent] after()\n' .
                'ok 3 - spec3\n' .
                '[Parent] before()\n' .
                '[Child2] before()\n' .
                '[Child2] after()\n' .
                '[Parent] after()\n' .
                'ok 4 - spec4\n' .
                '## ok:4, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n' .
                '';
            $expected =~ s/\\n/\n/g;
            my $actual = _run_with_capture();
            is($actual, $expected);
        }

        #: 'after' block is called even when error happened in body block.
        {
            Oktest::__clear();
            #
            my $after_called = 0;
            target "Hello", sub {
                after { $after_called = 1; };
                spec "example", sub { die "SomethingError\n"; };
            };
            #
            my $expected =
                '1..1\n' .
                '## * Hello\n' .
                'not ok 1 - example\n' .
                '# ----------------------------------------------------------------------\n' .
                '# [ERROR] * Hello > example\n' .
                '# SomethingError\n' .
                '# ----------------------------------------------------------------------\n' .
                '## ok:0, failed:0, error:1, skipped:0, todo:0  (elapsed: 0.000)\n' .
                '';
            $expected =~ s/\\n/\n/g;
            my $actual = _run_with_capture();
            is($actual, $expected);
            is($after_called, 1);
        }

        #: error messages are concatenated when error happened in both body block and 'after' block.
        {
            Oktest::__clear();
            #
            target "Hello", sub {
                after { die "AnotherError\n" };
                spec "example", sub { die "SomethingError\n" };
            };
            #
            my $expected =
                '1..1\n' .
                '## * Hello\n' .
                'not ok 1 - example\n' .
                '# ----------------------------------------------------------------------\n' .
                '# [ERROR] * Hello > example\n' .
                '# SomethingError\n' .
                '# AnotherError\n' .
                '# ----------------------------------------------------------------------\n' .
                '## ok:0, failed:0, error:1, skipped:0, todo:0  (elapsed: 0.000)\n' .
                '';
            $expected =~ s/\\n/\n/g;
            my $actual = _run_with_capture();
            is($actual, $expected);
        }

        #: both body block and 'after' block are not called when error happened in 'before' block.
        {
            Oktest::__clear();
            #
            my $before_called = 0;
            my $after_called  = 0;
            my $body_called   = 0;
            target "Hello", sub {
                before { $before_called = 1; die "SomethingError\n"; };
                after  { $after_called  = 1; };
                spec "example", sub { $body_called = 1; };
            };
            #
            my $expected =
                '1..1\n' .
                '## * Hello\n' .
                'not ok 1 - example\n' .
                '# ----------------------------------------------------------------------\n' .
                '# [ERROR] * Hello > example\n' .
                '# SomethingError\n' .
                '# ----------------------------------------------------------------------\n' .
                '## ok:0, failed:0, error:1, skipped:0, todo:0  (elapsed: 0.000)\n' .
                '';
            $expected =~ s/\\n/\n/g;
            my $actual = _run_with_capture();
            is($actual, $expected);
            is($before_called, 1);
            is($after_called, 0);
            is($body_called, 0);
        }

        #: removes done assertion objects.
        {
            no warnings 'void';  ## suppress warning 'Useless use of string eq in void context'
            Oktest::__clear();
            ## 'OK()' registers assertion objects.
            OK("Haruhi") eq "Haruhi";   # done
            OK("Mikuru");               # not done
            OK("Yuki")   ne "Haruhi";     # done
            is($#Oktest::__assertion_objects, 2);
            is($Oktest::__assertion_objects[0]->{_done}, 1==1);
            is($Oktest::__assertion_objects[1]->{_done}, 0==1);
            is($Oktest::__assertion_objects[2]->{_done}, 1==1);
            ## run_specs() calls Oktest::__sweep() which removes done assertion objects.
            target "Example", sub {
                spec "spec", sub {
                };
            };
            Oktest::Util::capture_stdouterr {
                Oktest::run();
            };
            is($#Oktest::__assertion_objects, 0);
            is($Oktest::__assertion_objects[0]->{_done}, 0==1);
            is($Oktest::__assertion_objects[0]->{actual}, "Mikuru");
        }

        #: calls 'at_end' block.
        {
            Oktest::__clear();
            my $called = 0==1;
            target "Example", sub {
                spec "example", sub {
                    at_end {
                        $called = 1==1;
                    };
                    is($called, 0==1, "at_end() is not called yet.");
                    die "SomethingError";
                };
            };
            Oktest::Util::capture_stdouterr {
                Oktest::run();
            };
            is($called, 1==1, "at_end() is called in spite of 'die' called.");
        }

    }


    for (TARGET('#_filter()')) {

        my $setup_shallow_tree = sub {
            Oktest::__clear();
            target "Parent", sub {
                target "Child1", sub {
                    spec "A1", sub { OK (1+1) == 2 };
                    spec "B1", sub { OK (1+1) == 2 };
                };
                target "Child2", sub {
                    spec "A2", sub { OK (1+1) == 2 };
                    spec "B2", sub { OK (1+1) == 2 };
                };
            };
        };

        #: skip specs when spec filter is specified by string.
        {
            $setup_shallow_tree->();
            my $expected =
                "1..1\n" .
                "## * Parent\n" .
                #"##   * Child1\n" .
                "##   * Child2\n" .
                "ok 1 - A2\n" .
                "## ok:1, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
                "";
            my $actual = _run_with_capture(spec=>'A2');
            is($actual, $expected);
        }

        #: skip specs when spec filter is specified by regexp.
        {
            $setup_shallow_tree->();
            my $expected =
                "1..2\n" .
                "## * Parent\n" .
                "##   * Child1\n" .
                "ok 1 - B1\n" .
                "##   * Child2\n" .
                "ok 2 - B2\n" .
                "## ok:2, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
                "";
            my $actual = _run_with_capture(spec=>qr/^B[0-9]$/);
            is($actual, $expected);
        }

        my $setup_deep_tree = sub {
            Oktest::__clear();
            target "Root", sub {
                target "Mother", sub {
                    target "ChildA", sub {
                        spec "X1", sub { OK (1+1) == 2 };
                        spec "Y1", sub { OK (1+1) == 2 };
                    };
                    target "ChildB", sub {
                        spec "X2", sub { OK (1+1) == 2 };
                        spec "Y2", sub { OK (1+1) == 2 };
                    };
                };
                target "Father", sub {
                    target "ChildC", sub {
                        spec "X3", sub { OK (1+1) == 2 };
                        spec "Y3", sub { OK (1+1) == 2 };
                    };
                    target "ChildD", sub {
                        spec "X4", sub { OK (1+1) == 2 };
                        spec "Y4", sub { OK (1+1) == 2 };
                    };
                };
            };
        };

        #: skip targets when target filter is specified.
        {
            my $expected =
                "1..2\n" .
                "## * Root\n" .
                "##   * Father\n" .
                "##     * ChildC\n" .
                "ok 1 - X3\n" .
                "ok 2 - Y3\n" .
                "## ok:2, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
                "";
            $setup_deep_tree->();
            my $actual1 = _run_with_capture(target=>'ChildC');
            is($actual1, $expected);
            $setup_deep_tree->();
            my $actual2 = _run_with_capture(target=>qr/^Child[C]$/);
            is($actual2, $expected);
        }

        #: complex filter is available by regexp.
        {
            my $expected =
                "1..4\n" .
                "## * Root\n" .
                "##   * Mother\n" .
                "##     * ChildB\n" .
                "ok 1 - X2\n" .
                "ok 2 - Y2\n" .
                "##   * Father\n" .
                "##     * ChildC\n" .
                "ok 3 - X3\n" .
                "ok 4 - Y3\n" .
                "## ok:4, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
                "";
            $setup_deep_tree->();
            my $actual1 = _run_with_capture(target=>qr/Child[BC]/);
            is($actual1, $expected);
        }

        #: don't skip children of filter-matched target.
        {
            $setup_deep_tree->();
            my $expected =
                "1..4\n" .
                "## * Root\n" .
                "##   * Father\n" .
                "##     * ChildC\n" .
                "ok 1 - X3\n" .
                "ok 2 - Y3\n" .
                "##     * ChildD\n" .
                "ok 3 - X4\n" .
                "ok 4 - Y4\n" .
                "## ok:4, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
                "";
            my $actual1 = _run_with_capture(target=>'Father');
            is($actual1, $expected);
        }

    }


}

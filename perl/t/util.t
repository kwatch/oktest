###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

use strict;
use warnings;
use Test::More tests => 68;
use Oktest;


sub TARGET { return undef; }



for (TARGET('Oktest::Util')) {


    for (TARGET('strip()')) {

        #: removes white spaces at the beginning and end of string.
        {
            is(Oktest::Util::strip(" \tHaruhi \r\n"), "Haruhi");
        }

    }


    for (TARGET('last_item()')) {


        #: returns last item of array.
        {
            my $arr = ["Haruhi", "Mikuru", "Yuki"];
            is(Oktest::Util::last_item(@$arr), "Yuki");
        }

    }


    for (TARGET('length()')) {


        #: returns length of array.
        {
            my $arr = ["Haruhi", "Mikuru", "Yuki"];
            is(Oktest::Util::length(@$arr), 3);
        }

    }


    for (TARGET('current_time()')) {

        #: returns current time (microsec)
        {
            my $usec = Oktest::Util::current_time();
            ok(Oktest::Util::is_float($usec));
        }

    }


    for (TARGET('index()')) {

        #: returns index of item which satisfies condition.
        {
            my $ret = Oktest::Util::index { $_ % 4 == 0 } (3, 6, 9, 12, 15);
            is($ret, 3);
        }

        #: returns -1 when there is no item to satisfy condition.
        {
            my $ret = Oktest::Util::index { $_ % 7 == 0 } (3, 6, 9, 12, 15);
            is($ret, -1);
        }

    }


    for (TARGET('index_denied()')) {

        #: returns index of item which satisfies condition.
        {
            my $ret = Oktest::Util::index_denied { $_ % 3 == 0 } (3, 6, 9, 13, 15);
            is($ret, 3);
        }

        #: returns -1 when there is no item to satisfy condition.
        {
            my $ret = Oktest::Util::index_denied { $_ % 3 == 0 } (3, 6, 9, 12, 15);
            is($ret, -1);
        }

    }


    for (TARGET('is_string()')) {

        #: returns 1 when argument is a string, else returns 0.
        {
            is(Oktest::Util::is_string('123'),   1);
            is(Oktest::Util::is_string(''),      1);
            is(Oktest::Util::is_string(1),       0);
            is(Oktest::Util::is_string(0),       0);
            is(Oktest::Util::is_string(-1),      0);
            is(Oktest::Util::is_string(-3.14),   0);
            is(Oktest::Util::is_string(undef),   0);
            is(Oktest::Util::is_string([1,2,3]), 0);
            is(Oktest::Util::is_string({x=>1}),  0);
            is(Oktest::Util::is_string(sub {}),  0);
        }

    }


    for (TARGET('is_number()')) {

        #: returns 1 when argument is a number, else returns 0.
        {
            is(Oktest::Util::is_number('123'),   0);
            is(Oktest::Util::is_number(''),      0);
            is(Oktest::Util::is_number(1),       1);
            is(Oktest::Util::is_number(0),       1);
            is(Oktest::Util::is_number(-1),      1);
            is(Oktest::Util::is_number(-3.14),   1);
            is(Oktest::Util::is_number(undef),   0);
            is(Oktest::Util::is_number([1,2,3]), 0);
            is(Oktest::Util::is_number({x=>1}),  0);
            is(Oktest::Util::is_number(sub {}),  0);
        }

    }


    for (TARGET('is_integer()')) {

        #: returns 1 when argument is an integer, else returns 0.
        {
            is(Oktest::Util::is_integer('123'),   0);
            is(Oktest::Util::is_integer(''),      0);
            is(Oktest::Util::is_integer(1),       1);
            is(Oktest::Util::is_integer(0),       1);
            is(Oktest::Util::is_integer(-1),      1);
            is(Oktest::Util::is_integer(-3.14),   0);
            is(Oktest::Util::is_integer(undef),   0);
            is(Oktest::Util::is_integer([1,2,3]), 0);
            is(Oktest::Util::is_integer({x=>1}),  0);
            is(Oktest::Util::is_integer(sub {}),  0);
        }

    }


    for (TARGET('is_float()')) {

        #: returns 1 when argument is a float, else returns 0.
        {
            is(Oktest::Util::is_float('123'),   0);
            is(Oktest::Util::is_float(''),      0);
            is(Oktest::Util::is_float(1),       0);
            is(Oktest::Util::is_float(0),       0);
            is(Oktest::Util::is_float(-1),      0);
            is(Oktest::Util::is_float(-3.14),   1);
            is(Oktest::Util::is_float(undef),   0);
            is(Oktest::Util::is_float([1,2,3]), 0);
            is(Oktest::Util::is_float({x=>1}),  0);
            is(Oktest::Util::is_float(sub {}),  0);
        }

    }


    for (TARGET('read_file()')) {

        #: returns content of file.
        {
            my $s = Oktest::Util::read_file(__FILE__);
            ## val=132e810686cb00a19fe6b3de0de2de5e
            like($s, qr/132e810686cb00a19fe6b3de0de2de5e/);
            is(length($s), -s __FILE__);
        }

    }


    for (TARGET('write_file()')) {

        #: returns content of file.
        {
            my $s = "af19b47b5b4c2341ad87566cf8192d79\n";
            my $fname = "_test_write_file.data";
            ok(! -e $fname);
            undef $@;
            eval {
                Oktest::Util::write_file($fname, $s);
                ok(-e $fname);
                is(Oktest::Util::read_file($fname), $s);
            };
            unlink($fname) if -f $fname;
            die $@ if $@;
        }

    }


    for (TARGET('read_line_from()')) {

        #: returns line string at specified line number of file.
        {
            my $linenum = __LINE__;
            my $linestr = Oktest::Util::read_line_from(__FILE__, $linenum);
            is($linestr, "            my \$linenum = __LINE__;\n");
        }

    }


    for (TARGET('rm_rf()')) {

        #: remove files matched to pattern.
        {
            Oktest::Util::write_file("_test_ex.tmp", "x");
            mkdir(                   "_test_ex.d");
            Oktest::Util::write_file("_test_ex.d/ex1", "1");
            mkdir(                   "_test_ex.d/ex2");
            Oktest::Util::write_file("_test_ex.d/ex2/ex3", "3");
            Oktest::Util::write_file("_test_foo.tmp", "foo");
            ok(-f "_test_ex.tmp");
            ok(-d "_test_ex.d");
            ok(-f "_test_foo.tmp");
            Oktest::Util::rm_rf('_test_ex.*');
            ok(! -e "_test_ex.tmp");
            ok(! -e "_test_ex.d");
            ok(-f "_test_foo.tmp");
            unlink("_test_foo.tmp") or die "unlink(): $!";
        }

    }


    for (TARGET('capture()')) {

        #: captures STDOUT and STDERR.
        {
            my ($sout, $serr) = Oktest::Util::capture {
                print "Haruhi\n";
                print STDERR "Sasaki\n";
            };
            is($sout, "Haruhi\n");
            is($serr, "Sasaki\n");
        }

    }


    for (TARGET('capture_stdout()')) {

        #: captures STDOUT.
        {
            my $stdout;
            my ($sout, $serr) = Oktest::Util::capture {
                $stdout = Oktest::Util::capture_stdout {
                    print "Haruhi\n";
                    print STDERR "Sasaki\n";
                };
            };
            is($sout, "");
            is($serr, "Sasaki\n");
            is($stdout, "Haruhi\n");
        }

    }


    for (TARGET('capture_stderr()')) {

        #: captures STDOUT.
        {
            my $stderr;
            my ($sout, $serr) = Oktest::Util::capture {
                $stderr = Oktest::Util::capture_stderr {
                    print "Haruhi\n";
                    print STDERR "Sasaki\n";
                };
            };
            is($sout, "Haruhi\n");
            is($serr, "");
            is($stderr, "Sasaki\n");
        }

    }


}

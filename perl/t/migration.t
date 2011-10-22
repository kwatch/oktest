###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

use strict;
use warnings;
#use Test::More tests=>0;
print "1..53\n";

use Data::Dumper;
use Text::Diff;

use Oktest;
use Oktest::Migration::TestMore;


sub TARGET { return undef; }
#sub SPEC { return; }


sub _assert_eq {
    my ($actual, $expected) = @_;
    my ($pkgname, $filename, $linenum) = caller();
    if ($actual eq $expected) {
        print "ok - L$linenum\n";
        #return 1==1;
    }
    else {
        print "not ok - L$linenum\n";
        my $s1 = Dumper($actual);
        my $s2 = Dumper($expected);
        my $diff = Text::Diff::diff(\$s2, \$s1, {STYLE=>'Unified'});
        my $msg =
            "[Failed] \$actual eq \$expected : failed.\n" .
            "--- \$expected\n" .
            "+++ \$actual\n" .
            $diff;
        #local $Data::Dumper::Terse = 1;
        #my $msg =
        #    #"[Failed] _assert_equal(): not equal.\n" .
        #    "  \$actual:   " . Dumper($actual) .
        #    "  \$expected: " . Dumper($expected);
        $msg =~ s/^/# /mg;
        print $msg;
        #die $msg;
    }
}

sub _chomp {
    my ($output) = @_;
    $output =~ s/^File '.*', line \d+.*$//smg;
    return $output;
}



for (TARGET("Oktest::TestMoreMigration")) {


    for (TARGET("ok()")) {

        #: returns true when expression is true.
        {
            _assert_eq(ok(123, "test name"), 1==1);
        };

        #: raises exception when expression is false.
        {
            undef $@;
            eval { ok('', 'test name') };
            my $line = __LINE__;
            my $expected =
                "[Failed] OK(\$expression) : assertion failed.\n" .
                "  \$expression:  ''\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { ok('', 'test name') };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { ok('', 'test name') };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    };


    for (TARGET("is()")) {

        #: returns true when actual and expected values are equal.
        {
            _assert_eq(is('S' x 3, 'SSS', 'test name'), 1==1);
        }

        #: raises exception when actual and expected values are not equal.
        {
            undef $@;
            eval { is('S' x 3, 'SOS', 'test name') };
            my $line = __LINE__;
            my $expected =
                "[Failed] \$actual eq \$expected : failed.\n" .
                "  \$actual:   'SSS'\n" .
                "  \$expected: 'SOS'\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { is('S' x 3, 'SOS', 'test name') };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { is('S' x 3, 'SOS', 'test name') };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("isnt()")) {

        #: returns true when actual and expected values are not equal.
        {
            _assert_eq(isnt('S' x 3, 'SOS', 'test name'), 1==1);
        }

        #: raises exception when actual and expected values are equal.
        {
            undef $@;
            eval { isnt('S' x 3, 'SSS', 'test name') };
            my $line = __LINE__;
            my $expected =
                "[Failed] \$actual ne \$expected : failed.\n" .
                "  \$actual:   'SSS'\n" .
                "  \$expected: 'SSS'\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { isnt('S' x 3, 'SSS', 'test name') };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { isnt('S' x 3, 'SSS', 'test name') };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("like()")) {

        #: returns true when actual matches to expected pattern.
        {
            _assert_eq(like('SOS', qr/^\w\w\w$/, 'test name'), 1==1);
        }

        #: raises exception when actual doesn't match to expected pattern.
        {
            undef $@;
            eval { like('SOS', qr/^\w+\d$/, 'test name') };
            my $line = __LINE__;
            my $expected =
                "[Failed] \$actual =~ \$expected : failed.\n" .
                "  \$actual:   'SOS'\n" .
                "  \$expected: qr/(?-xism:^\\w+\\d\$)/\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { like('SOS', qr/^\\w+\\d\$/, 'test name') };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { like('SOS', qr/^\\w+\\d\$/, 'test name') };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("unlike()")) {

        #: returns true when actual doesn't match to expected pattern.
        {
            _assert_eq(unlike('SOS', qr/^[0-9]+$/, 'test name'), 1==1);
        }

        #: raises exception when actual matches to expected pattern.
        {
            undef $@;
            eval { unlike('SOS', qr/^[A-Z]+$/, 'test name') };
            my $line = __LINE__;
            my $expected =
                "[Failed] \$actual !~ \$expected : failed.\n" .
                "  \$actual:   'SOS'\n" .
                "  \$expected: qr/(?-xism:^[A-Z]+\$)/\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { unlike('SOS', qr/^[A-Z]+\$/, 'test name') };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { unlike('SOS', qr/^[A-Z]+\$/, 'test name') };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("cmp_ok()")) {

        #: returns true when compared result is true.
        {
            _assert_eq(cmp_ok(123, '==', 123), 1==1);
            _assert_eq(cmp_ok(123, '!=', 124), 1==1);
            _assert_eq(cmp_ok(123, '>',  122), 1==1);
            _assert_eq(cmp_ok(123, '>=', 123), 1==1);
            _assert_eq(cmp_ok(122, '<',  123), 1==1);
            _assert_eq(cmp_ok(123, '<=', 123), 1==1);
            _assert_eq(cmp_ok('A', 'eq', 'A'), 1==1);
            _assert_eq(cmp_ok('A', 'ne', 'B'), 1==1);
            _assert_eq(cmp_ok('B', 'gt', 'A'), 1==1);
            _assert_eq(cmp_ok('B', 'ge', 'B'), 1==1);
            _assert_eq(cmp_ok('A', 'lt', 'B'), 1==1);
            _assert_eq(cmp_ok('A', 'le', 'A'), 1==1);
            _assert_eq(cmp_ok('SOS', '=~', qr/^[A-Z]+$/), 1==1);
            _assert_eq(cmp_ok('SOS', '!~', qr/^[0-9]+$/), 1==1);
        }

        #: raises exception when actual and expected values are equal.
        {
            undef $@;
            eval { _assert_eq(cmp_ok(123, '==', 124), 1==1) };
            my $line = __LINE__;
            my $expected =
                "[Failed] \$actual == \$expected : failed.\n" .
                "  \$actual:   123\n" .
                "  \$expected: 124\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { _assert_eq(cmp_ok(123, '==', 124), 1==1) };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { _assert_eq(cmp_ok(123, '==', 124), 1==1) };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("is_deeply()")) {

        #: returns true when actual and expected are equal deeply.
        {
            _assert_eq(is_deeply([1, 2, 3], [1, 2, 3], 'test name'), 1==1);
            _assert_eq(is_deeply({x=>10}, {x=>10}, 'test name'), 1==1);
        }

        #: raises exception when actual matches to expected pattern.
        {
            undef $@;
            eval { is_deeply({x=>10}, {x=>11}, 'test name') };
            my $line = __LINE__;
            my $expected =
                "[Failed] \$actual equals to \$expected : failed.\n" .
                "--- Dumper(\$expected)\n" .
                "+++ Dumper(\$actual)\n" .
                "\@\@ -1,3 +1,3 \@\@\n" .
                " \$VAR1 = {\n" .
                "-          'x' => 11\n" .
                "+          'x' => 10\n" .
                "         };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { is_deeply({x=>10}, {x=>11}, 'test name') };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { is_deeply({x=>10}, {x=>11}, 'test name') };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("can_ok()")) {

        #: returns true when actual has method.
        {
            my $obj = bless({}, "ClassName");
            _assert_eq(can_ok($obj, 'isa'), 1==1);
        }

        #: raises exception when actual matches to expected pattern.
        {
            undef $@;
            my $obj = bless({}, "ClassName");
            eval { can_ok($obj, 'notfound', 'test name') };
            my $line = __LINE__;
            my $expected =
                "[Failed] \$actual->can('notfound') : failed.\n" .
                "  \$actual:   bless( {}, \'ClassName\' )\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { can_ok(\$obj, 'notfound', 'test name') };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { can_ok(\$obj, 'notfound', 'test name') };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("isa_ok()")) {

        #: returns true when actual has method.
        {
            my $obj = bless({}, "ClassName");
            _assert_eq(isa_ok($obj, 'ClassName'), 1==1);
        }

        #: raises exception when actual matches to expected pattern.
        {
            undef $@;
            my $obj = bless({}, "ClassName");
            eval { isa_ok($obj, 'KlassName', 'test name') };
            my $line = __LINE__;
            my $expected =
                "[Failed] \$actual->isa(\$expected) : failed.\n" .
                "  \$actual:   bless( {}, \'ClassName\' )\n" .
                "  \$expected: \'KlassName\'\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { isa_ok(\$obj, 'KlassName', 'test name') };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { isa_ok(\$obj, 'KlassName', 'test name') };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("pass()")) {

        #: returns true everytime.
        {
            _assert_eq(pass("message"), 1==1);
            _assert_eq(pass(0==1), 1==1);
            _assert_eq(pass(undef), 1==1);
        }

    }


    for (TARGET("fail()")) {

        #: throws exception everytime.
        {
            undef $@;
            eval { fail('message') };
            my $line = __LINE__;
            my $expected =
                "[Failed] message\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { fail('message') };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { fail('message') };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("throws_ok()")) {

        #: returns true when block dies and error message matches to expected pattern.
        {
            _assert_eq((throws_ok { die "SOS\n" } "SOS\n"), 1==1);
            _assert_eq((throws_ok { die "SOS\n" } qr/^[A-Z]+\n$/), 1==1);
        }

        #: throws exception when block doesn't die.
        {
            undef $@;
            eval { (throws_ok { 1 } "SOS\n") };
            my $line = __LINE__;
            my $expected =
                "[Failed] exception expected but nothing thrown.\n" .
                "  \$expected: \'SOS\n" .
                "'\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { (throws_ok { 1 } \"SOS\\n\") };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { (throws_ok { 1 } \"SOS\\n\") };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

        #: throws exception when error message not matched.
        {
            undef $@;
            eval { (throws_ok { die "SOS\n" } qr/[0-9]+/) };
            my $line = __LINE__;
            my $expected =
                "[Failed] \$\@ =~ \$expected : failed.\n" .
                "  \$\@:        \'SOS\n" .
                "'\n" .
                "  \$expected: qr/(?-xism:[0-9]+)/\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { (throws_ok { die \"SOS\\n\" } qr/[0-9]+/) };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { (throws_ok { die \"SOS\\n\" } qr/[0-9]+/) };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("dies_ok()")) {

        #: returns true when block dies.
        {
            _assert_eq((dies_ok { die "SOS\n" }), 1==1);
        }

        #: throws exception when block doesn't die.
        {
            undef $@;
            eval { (dies_ok { 1 }) };
            my $line = __LINE__;
            my $expected =
                "[Failed] exception expected but nothing thrown.\n" .
                "  \$expected: \'\'\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { (dies_ok { 1 }) };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { (dies_ok { 1 }) };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("lives_ok()")) {

        #: returns true when block doesn't die.
        {
            _assert_eq((lives_ok { 1 } 'test name'), 1==1);
        }

        #: throws exception when block dies.
        {
            undef $@;
            eval { (lives_ok { die "SOS\n" } 'test name') };
            my $line = __LINE__;
            my $expected =
                "[Failed] no exception expected but thrown.\n" .
                "  \$\@: \'SOS\n" .
                "'\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { (lives_ok { die \"SOS\\n\" } 'test name') };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { (lives_ok { die \"SOS\\n\" } 'test name') };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("lives_and()")) {

        #: returns true when block doesn't die.
        {
            _assert_eq((lives_and { 1 } 'test name'), 1==1);
        }

        #: throws exception when block dies.
        {
            undef $@;
            eval { (lives_and { die "SOS\n" } 'test name') };
            my $line = __LINE__;
            my $expected =
                "[Failed] no exception expected but thrown.\n" .
                "  \$\@: \'SOS\n" .
                "'\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { (lives_and { die \"SOS\\n\" } 'test name') };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { (lives_and { die \"SOS\\n\" } 'test name') };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("warning_like()")) {

        #: returns true when warning message matched to expected pattern.
        {
            _assert_eq((warning_like { warn("SOS\n") } "SOS\n"), 1==1);
            _assert_eq((warning_like { warn("SOS\n") } qr/^[A-Z]+$/), 1==1);
        }

        #: throws exception when no warning message printed.
        {
            undef $@;
            eval { warning_like { my $x = 1 } qr/[A-Z]+/ };
            my $line = __LINE__;
            my $expected =
                "[Failed] warning expected : failed (nothing printed).\n" .
                "  \$expected: qr/(?-xism:[A-Z]+)/\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { warning_like { my \$x = 1 } qr/[A-Z]+/ };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { warning_like { my \$x = 1 } qr/[A-Z]+/ };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

        #: throws exception when warning message not matched to expected pattern.
        {
            undef $@;
            eval { warning_like { warn("SOS\n") } qr/[0-9]+/ };
            my $line = __LINE__;
            my $expected =
                "[Failed] \$warning =~ \$expected : failed.\n" .
                "  \$warning:  \'SOS\n" .
                "\'\n" .
                "  \$expected: qr/(?-xism:[0-9]+)/\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { warning_like { warn(\"SOS\\n\") } qr/[0-9]+/ };\n" .
                "File 't/migration.t', line " . ($line-1) . ":\n" .
                "    eval { warning_like { warn(\"SOS\\n\") } qr/[0-9]+/ };\n" .
                "";
            #_assert_eq(_chomp($@), $expected);
            _assert_eq($@, $expected);
        };

    }


    for (TARGET("diag()")) {

        #: prints message.
        {
            my $output = Oktest::Util::capture_stdout {
                diag "SOS";
            };
            _assert_eq($output, "# SOS\n");
        }

    }


    for (TARGET("note()")) {

        #: prints message.
        {
            my $output = Oktest::Util::capture_stdout {
                note "SOS";
            };
            _assert_eq($output, "# SOS\n");
        }

    }


    for (TARGET("explain()")) {

        #: returns data representing string.
        {
            my $s = explain {name=>'Haruhi', team=>'SOS'};
            my $expected =
                "{\n" .
                "  'name' => 'Haruhi',\n" .
                "  'team' => 'SOS'\n" .
                "}\n" .
                "";
            _assert_eq($s, $expected);
        }

    }


};


#Oktest::main() if $0 eq __FILE__;
#1;

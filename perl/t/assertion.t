###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

use strict;
use warnings;
no warnings 'void';   # suppress 'Useless use of ... in void context'
use Test::More tests => 158;


use Oktest qw(OK);


sub TARGET { return undef; }


sub _chomp {
    my ($errmsg) = @_;
    $errmsg =~ s/^File '.*', line \d+:\n.*\n//mg;
    return $errmsg;
}



for (TARGET('Oktest::AssertionObject')) {


    for (TARGET('->new()')) {

        #: returns AssertionObject object."
        {
            my $ao = Oktest::AssertionObject->new('foo');
            ok($ao->isa('Oktest::AssertionObject'));
            is($ao->{actual}, 'foo');
        }

        #: 'OK()' returns AssertionObject object."
        {
            my $ao = OK ('foo');
            $ao->_done();    # to supress warning
            ok($ao->isa('Oktest::AssertionObject'));
            is($ao->{actual}, 'foo');
        }

    }


    for (TARGET('->_die()')) {

        #: appends stacktrace information into error message.
        {
            my $line = __LINE__;
            my $sub1 = sub {
                OK (1+1) == 0;
            };
            my $sub2 = sub {
                $sub1->();
            };
            undef $@;
            eval { $sub2->() };
            my $file = __FILE__;
            my $expected =
                "[Failed] \$actual == \$expected : failed.\n" .
                "  \$actual:   2\n" .
                "  \$expected: 0\n" .
                "File '" . __FILE__ . "', line " . ($line + 2) . ":\n" .
                "    OK (1+1) == 0;\n" .
                "File '" . __FILE__ . "', line " . ($line + 5) . ":\n" .
                "    \$sub1->();\n" .
                "File '" . __FILE__ . "', line " . ($line + 8) . ":\n" .
                "    eval { \$sub2->() };\n" .
                "File '" . __FILE__ . "', line " . ($line + 8) . ":\n" .
                "    eval { \$sub2->() };\n" .
                "";
            is($@, $expected);
            undef $@;
        }

    }


    for (TARGET("'==' operator")) {

        #: returns $this when '$actual == $expected.' is true.
        {
            #my $ao = Oktest::AssertionObject->new(1+1);
            #my $ret = eval { $ao == 2 };
            my $ret = OK (1+1) == 2;
            ok($ret->{actual} == 2);
        }

        #: throws nothing when '$actual == $expected.' is true.
        {
            undef $@;
            #my $ao = Oktest::AssertionObject->new(1+1);
            #eval { $ao == 2 };
            eval { OK (1+1) == 2 };
            is($@, '');
        }

        #: throws exception when '$actual == $expected' is false.
        {
            my $expected =
                "[Failed] \$actual == \$expected : failed.\n" .
                "  \$actual:   2\n" .
                "  \$expected: 3\n";
            undef $@;
            #my $ao = Oktest::AssertionObject->new(1+1);
            #eval { $ao == 3 };
            eval { OK (1+1) == 3 };
            is(_chomp($@), $expected);
        }

        #: error when $expected is a string
        {
            my $expected =
                "[ERROR] right hand of '==' should not be a string.\n" .
                "  \$actual:   2\n" .
                "  \$expected: '2'\n";
            undef $@;
            eval { OK (1+1) == '2' };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("'!=' operator")) {

        #: returns $this when '$actual != $expected.' is true.
        {
            #my $ao = Oktest::AssertionObject->new(1+1);
            #my $ret = $ao != 3;
            my $ret = OK (1+1) != 3;
            ok($ret->{actual} == 2);
        }

        #: throws nothing when '$actual != $expected.' is true.
        {
            undef $@;
            #my $ao = Oktest::AssertionObject->new(1+1);
            #my $ret = eval { $ao != 3 };
            eval { OK (1+1) != 3 };
            is($@, '');
        }

        #: throws exception when '$actual != $expected' is false.
        {
            my $expected =
                "[Failed] \$actual != \$expected : failed.\n" .
                "  \$actual:   2\n" .
                "  \$expected: 2\n";
            undef $@;
            eval { OK (1+1) != 2 };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("'>' operator")) {

        #: returns $this when '$actual > $expected.' is true.
        {
            my $ret = eval { OK (1+1) > 1 };
            ok($ret->{actual} == 2);
        }

        #: throws nothing when '$actual > $expected.' is true.
        {
            undef $@;
            eval { OK (1+1) > 1 };
            is($@, '');
        }

        #: throws exception when '$actual > $expected' is false.
        {
            my $expected =
                "[Failed] \$actual > \$expected : failed.\n" .
                "  \$actual:   2\n" .
                "  \$expected: 3\n";
            undef $@;
            eval { OK (1+1) > 3 };
            is(_chomp($@), $expected);
            #
            $expected =~ s/3/2/;
            undef $@;
            eval { OK (1+1) > 2 };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("'>=' operator")) {

        #: returns $this when '$actual >= $expected.' is true.
        {
            my $ret = OK (1+1) >= 2;
            ok($ret->{actual} == 2);
        }

        #: throws nothing when '$actual >= $expected.' is true.
        {
            undef $@;
            eval { OK (1+1) >= 2 };
            is($@, '');
            eval { OK (1+1) >= 1 };
            is($@, '');
        }

        #: throws exception when '$actual >= $expected' is false.
        {
            my $expected =
                "[Failed] \$actual >= \$expected : failed.\n" .
                "  \$actual:   2\n" .
                "  \$expected: 3\n";
            undef $@;
            eval { OK (1+1) >= 3 };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("'<' operator")) {

        #: returns $this when '$actual < $expected.' is true.
        {
            my $ret = OK (1+1) < 3;
            ok($ret->{actual} == 2);
        }

        #: throws nothing when '$actual < $expected.' is true.
        {
            undef $@;
            eval { OK (1+1) < 3 };
            is($@, '');
        }

        #: throws exception when '$actual < $expected' is false.
        {
            my $expected =
                "[Failed] \$actual < \$expected : failed.\n" .
                "  \$actual:   2\n" .
                "  \$expected: 1\n";
            undef $@;
            eval { OK (1+1) < 1 };
            is(_chomp($@), $expected);
            #
            $expected =~ s/1/2/;
            undef $@;
            eval { OK (1+1) < 2 };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("'<=' operator")) {

        #: returns $this when '$actual <= $expected.' is true.
        {
            my $ret = OK (1+1) <= 2;
            ok($ret->{actual} == 2);
        }

        #: throws nothing when '$actual <= $expected.' is true.
        {
            undef $@;
            eval { OK (1+1) <= 2 };
            is($@, '');
            eval { OK (1+1) <= 3 };
            is($@, '');
        }

        #: throws exception when '$actual <= $expected' is false.
        {
            my $expected =
                "[Failed] \$actual <= \$expected : failed.\n" .
                "  \$actual:   2\n" .
                "  \$expected: 1\n";
            undef $@;
            eval { OK (1+1) <= 1 };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("'eq' operator")) {

        #: returns $this when '$actual eq $expected.' is true.
        {
            my $ret = OK ('foo') eq 'foo';
            ok($ret->{actual} eq 'foo');
        }

        #: throws nothing when '$actual eq $expected.' is true.
        {
            undef $@;
            eval { OK ('foo') eq 'foo' };
            is($@, '');
        }

        #: throws exception when '$actual eq $expected' is false.
        {
            my $expected =
                "[Failed] \$actual eq \$expected : failed.\n" .
                "  \$actual:   'foo'\n" .
                "  \$expected: 'bar'\n";
            undef $@;
            eval { OK ('foo') eq 'bar' };
            is(_chomp($@), $expected);
        }

        #: shows unified diff when either $actual or $expected contains "\n".
        {
            my $text1 =
                "Haruhi\n" .
                "Mikuru\n" .
                "Yuki\n" .
                "Itsuki\n" .
                "Kyon\n" .
                "";
            my $text2 =
                "Haruhi\n" .
                "Michiru\n" .
                "Yuki\n" .
                "Itsuki\n" .
                "John\n" .
                "";
            my $expected =
                "[Failed] \$actual eq \$expected : failed.\n" .
                "--- \$expected\n" .
                "+++ \$actual\n" .
                "@@ -1,5 +1,5 @@\n" .
                " Haruhi\n" .
                "-Michiru\n" .
                "+Mikuru\n" .
                " Yuki\n" .
                " Itsuki\n" .
                "-John\n" .
                "+Kyon\n" .
                "";
            undef $@;
            eval { OK ($text1) eq $text2 };
            is(_chomp($@), $expected);
            #
            $expected =
                "[Failed] \$actual eq \$expected : failed.\n" .
                "--- \$expected\n" .
                "+++ \$actual\n" .
                "@@ -1 +1 @@\n" .
                "-foo\n" .
                "+foo\\ No newline at end\n" .
                "";
            undef $@;
            eval { OK ("foo") eq "foo\n" };
            is(_chomp($@), $expected);
            #
            $expected =
                "[Failed] \$actual eq \$expected : failed.\n" .
                "--- \$expected\n" .
                "+++ \$actual\n" .
                "@@ -1 +1 @@\n" .
                "-foo\\ No newline at end\n" .
                "+foo\n" .
                "";
            undef $@;
            eval { OK ("foo\n") eq "foo" };
            is(_chomp($@), $expected);
            #
            $expected =
                "[Failed] \$actual eq \$expected : failed.\n" .
                "--- \$expected\n" .
                "+++ \$actual\n" .
                "@@ -1,2 +1,2 @@\n" .
                " foo\n" .
                "-baz\\ No newline at end\n" .
                "+bar\\ No newline at end\n" .
                "";
            undef $@;
            eval { OK ("foo\nbar") eq "foo\nbaz" };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("'ne' operator")) {

        #: returns $this when '$actual ne $expected.' is true.
        {
            my $ret = OK ('foo') ne 'bar';
            ok($ret->{actual} eq 'foo');
        }

        #: throws nothing when '$actual ne $expected.' is true.
        {
            undef $@;
            eval { OK ('foo') ne 'bar' };
            is($@, '');
        }

        #: throws exception when '$actual ne $expected' is false.
        {
            my $expected =
                "[Failed] \$actual ne \$expected : failed.\n" .
                "  \$actual:   'foo'\n" .
                "  \$expected: 'foo'\n";
            undef $@;
            eval { OK ('foo') ne 'foo'; };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("'gt' operator")) {

        #: returns $this when '$actual gt $expected.' is true.
        {
            my $ret = OK ('B') gt 'A';
            ok($ret->{actual} eq 'B');

        }

        #: throws nothing when '$actual gt $expected.' is true.
        {
            undef $@;
            eval { OK ('B') gt 'A' };
            is($@, '');
        }

        #: throws exception when '$actual gt $expected' is false.
        {
            my $expected =
                "[Failed] \$actual gt \$expected : failed.\n" .
                "  \$actual:   'A'\n" .
                "  \$expected: 'B'\n";
            undef $@;
            eval { OK ('A') gt 'B'; };
            is(_chomp($@), $expected);
            #
            $expected =~ s/'B'/'A'/;
            undef $@;
            eval { OK ('A') gt 'A'; };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("'ge' operator")) {

        #: returns $this when '$actual ge $expected.' is true.
        {
            my $ret = OK ('B') ge 'B';
            ok($ret->{actual} eq 'B');
        }

        #: throws nothing when '$actual ge $expected.' is true.
        {
            undef $@;
            eval { OK ('B') ge 'B' };
            is($@, '');
            eval { OK ('B') ge 'A' };
            is($@, '');
        }

        #: throws exception when '$actual ge $expected' is false.
        {
            my $expected =
                "[Failed] \$actual ge \$expected : failed.\n" .
                "  \$actual:   'A'\n" .
                "  \$expected: 'B'\n";
            undef $@;
            eval { OK ('A') ge 'B'; };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("'lt' operator")) {

        #: returns $this when '$actual lt $expected.' is true.
        {
            my $ret = OK ('A') lt 'B';
            ok($ret->{actual} eq 'A');
        }

        #: throws nothing when '$actual lt $expected.' is true.
        {
            undef $@;
            eval { OK ('A') lt 'B' };
            is($@, '');
        }

        #: throws exception when '$actual lt $expected' is false.
        {
            my $expected =
                "[Failed] \$actual lt \$expected : failed.\n" .
                "  \$actual:   'B'\n" .
                "  \$expected: 'A'\n";
            undef $@;
            eval { OK ('B') lt 'A'; };
            is(_chomp($@), $expected);
            #
            $expected =~ s/'B'/'A'/;
            undef $@;
            eval { OK ('A') lt 'A'; };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("'le' operator")) {

        #: returns $this when '$actual le $expected.' is true.
        {
            my $ret = OK ('A') le 'A';
            ok($ret->{actual} eq 'A');
        }

        #: throws nothing when '$actual le $expected.' is true.
        {
            undef $@;
            eval { OK ('A') le 'A' };
            is($@, '');
            eval { OK ('A') le 'B' };
            is($@, '');
        }

        #: throws exception when '$actual le $expected' is false.
        {
            my $expected =
                "[Failed] \$actual le \$expected : failed.\n" .
                "  \$actual:   'B'\n" .
                "  \$expected: 'A'\n";
            undef $@;
            eval { OK ('B') le 'A'; };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#in_delta()")) {

        #: returns $this when $actual is in range.
        {
            my $ret = OK (3.1415)->in_delta(3.14, 0.002);
            ok($ret->{actual} == 3.1415);
        }

        #: throws nothing when $actual is in range.
        {
            undef $@;
            eval { OK (3.1415)->in_delta(3.14, 0.002) };
            is($@, '');
        }

        #: throws exception when $actual is less than range.
        {
            my $expected =
                "[Failed] \$expected - \$delta <= \$actual : failed.\n" .
                "  \$expected - \$delta: 3.13\n" .
                "  \$actual:            3.129\n";
            undef $@;
            eval { OK (3.129)->in_delta(3.14, 0.01) };
            is(_chomp($@), $expected);
        }

        #: throws exception when $actual is larger than range.
        {
            my $expected =
                "[Failed] \$actual <= \$expected + \$delta : failed.\n" .
                "  \$actual:            3.151\n" .
                "  \$expected + \$delta: 3.15\n";
            undef $@;
            eval { OK (3.151)->in_delta(3.14, 0.01) };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#matches()")) {

        #: returns $this when '$actual =~ $expected.' is true.
        {
            my $ret = OK ('Haruhi')->matches(qr/^\w+$/);
            is($ret->{actual}, 'Haruhi');
        }

        #: throws nothing when '$actual =~ $expected.' is true.
        {
            undef $@;
            eval { OK ('Haruhi')->matches(qr/^\w+$/) };
            is($@, '');
        }

        #: throws exception when '$actual =~ $expected' is false.
        {
            my $expected =
                "[Failed] \$actual =~ \$expected : failed.\n" .
                "  \$actual:   'Haruhi!'\n" .
                "  \$expected: qr/(?-xism:^\\w+\$)/\n";
            undef $@;
            eval { OK ('Haruhi!')->matches(qr/^\w+$/); };
            is(_chomp($@), $expected);
        }

        #: throws exception when pattern is not passed.
        {
            undef $@;
            no warnings 'uninitialized';
            eval { OK ('Haruhi!')->matches(/^\w+$/); };
            #like($@, qr`^\[ERROR\] OK\(\): use matches\(qr/pattern/\) instead of matches\(/pattern/\)\. at .*? line \d+\.`);
            like($@, qr`^\[ERROR\] OK\(\): use matches\(qr/pattern/\) instead of matches\(/pattern/\)\.`);
        }

    }


    for (TARGET("#not_match()")) {

        #: returns $this when '$actual =~ $expected.' is true.
        {
            my $ret = OK ('Haruhi')->not_match(qr/^\d+$/);
            is($ret->{actual}, 'Haruhi');
        }

        #: throws nothing when '$actual =~ $expected.' is true.
        {
            undef $@;
            eval { OK ('Haruhi')->not_match(qr/^\d+$/) };
            is($@, '');
        }

        #: throws exception when '$actual =~ $expected' is false.
        {
            my $expected =
                "[Failed] \$actual !~ \$expected : failed.\n" .
                "  \$actual:   '12345'\n" .
                "  \$expected: qr/(?-xism:^\\d+\$)/\n";
            undef $@;
            eval { OK ('12345')->not_match(qr/^\d+$/); };
            is(_chomp($@), $expected);
        }

        #: throws exception when pattern is not passed.
        {
            undef $@;
            no warnings 'uninitialized';
            eval { OK ('Haruhi!')->not_match(/^\w+$/); };
            #like($@, qr`^\[ERROR\] OK\(\): use not_match\(qr/pattern/\) instead of not_match\(/pattern/\)\. at .*? line \d+\.`);
            like($@, qr`^\[ERROR\] OK\(\): use not_match\(qr/pattern/\) instead of not_match\(/pattern/\)\.`);
        }


    }


    for (TARGET("#is_a()")) {

        #: returns $this when '$actual->is_a($expected).' is true.
        {
            my $obj = bless({x=>10}, 'Test::More');
            my $ret = OK ($obj)->is_a('Test::More');
            is($ret->{actual}->{x}, 10);
        }

        #: throws nothing when '$actual->is_a($expected).' is true.
        {
            undef $@;
            my $obj = bless({x=>10}, 'Test::More');
            eval { OK ($obj)->is_a('Test::More') };
            is($@, '');
        }

        #: throws exception when '$actual->is_a($expected).' is false.
        {
            my $expected =
                "[Failed] \$actual->isa(\$expected) : failed.\n" .
                "  \$actual:   bless( {\n" .
                "                 'x' => 10\n" .
                "               }, 'Test::More' )\n" .
                "  \$expected: 'Test::Simple'\n";
            undef $@;
            my $obj = bless({x=>10}, 'Test::More');
            eval { OK ($obj)->is_a('Test::Simple') };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#not_a()")) {

        #: returns $this when '$actual->is_a($expected).' is false.
        {
            my $obj = bless({x=>10}, 'Test::More');
            my $ret = OK ($obj)->not_a('Test::Simple');
            is($ret->{actual}->{x}, 10);
        }

        #: throws nothing when '$actual->is_a($expected).' is false.
        {
            undef $@;
            my $obj = bless({x=>10}, 'Test::More');
            eval { OK ($obj)->not_a('Test::Simple') };
            is($@, '');
        }

        #: throws exception when '$actual->is_a($expected).' is true.
        {
            my $expected =
                "[Failed] ! \$actual->isa(\$expected) : failed.\n" .
                "  \$actual:   bless( {\n" .
                "                 'x' => 10\n" .
                "               }, 'Test::More' )\n" .
                "  \$expected: 'Test::More'\n";
            undef $@;
            my $obj = bless({x=>10}, 'Test::More');
            eval { OK ($obj)->not_a('Test::More') };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#dies()")) {

        #: returns $this when expected exception is thrown.
        {
            my $code = sub { die "SOS\n" };
            my $ret = OK ($code)->dies("SOS\n");
            is(ref($ret->{actual}), 'CODE');
        }

        #: throws nothing when expected exception is thrown.
        {
            undef $@;
            my $code = sub { die "SOS\n" };
            eval { OK ($code)->dies("SOS\n") };
            is($@, '');
        }

        #: accepts regular expression as error message.
        {
            undef $@;
            my $code = sub { die 'SOS' };
            eval { OK ($code)->dies(qr/^SOS at .* line .*$/) };
            is($@, '');
        }

        #: throws exception when nothing is thrown.
        {
            my $expected =
                "[Failed] exception expected but nothing thrown.\n" .
                "  \$expected: 'SOS'\n";
            undef $@;
            my $code = sub { 1+1 == 2 };
            eval { OK ($code)->dies('SOS') };
            is(_chomp($@), $expected);
        }

        #: throws exception when actual error message is different from expected.
        {
            my $expected =
                "[Failed] \$\@ eq \$expected : failed.\n" .
                "  \$\@:        'Haruhi\n'\n" .
                "  \$expected: 'Sasaki\n'\n";
            undef $@;
            my $code = sub { die "Haruhi\n" };
            eval { OK ($code)->dies("Sasaki\n") };
            is(_chomp($@), $expected);
        }

        #: throws exception when actual error message is not matched to pattern.
        {
            my $expected =
                '[Failed] $@ =~ $expected : failed.\n' .
                '  $@:        \'SOS at t/assertion.t line %LINE%.\n\'\n' .
                '  $expected: qr/(?-xism:^SOS  at .* line .*$)/\n';
            $expected =~ s/\\n/\n/g;
            $expected =~ s/\%LINE\%/__LINE__ + 2/e;
            undef $@;
            my $code = sub { die 'SOS' };
            eval { OK ($code)->dies(qr/^SOS  at .* line .*$/) };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#not_die()")) {

        #: returns $this when nothing thrown.
        {
            my $code = sub { 1 };
            my $ret = OK ($code)->not_die();
            is(ref($ret->{actual}), 'CODE');
        }

        #: throws nothing when nothing thrown.
        {
            undef $@;
            my $code = sub { 1 };
            eval { OK ($code)->not_die() };
            is($@, '');
        }

        #: throws exception when something thrown.
        {
            my $expected =
                "[Failed] no exception expected but thrown.\n" .
                "  \$\@: 'SOS\n'\n";
            undef $@;
            my $code = sub { die("SOS\n") };
            eval { OK ($code)->not_die() };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#warns()")) {

        #: returns $this when expected warning is printed.
        {
            my $code = sub { warn "SOS\n" };
            my $ret = OK ($code)->warns("SOS\n");
            is(ref($ret->{actual}), 'CODE');
        }

        #: throws nothing when expected warning is printed.
        {
            undef $@;
            my $code = sub { warn "SOS\n" };
            eval { OK ($code)->warns("SOS\n") };
            is($@, '');
        }

        #: accepts regular expression as warning message.
        {
            undef $@;
            my $code = sub { warn 'SOS' };
            eval { OK ($code)->warns(qr/^SOS at .* line .*$/) };
            is($@, '');
        }

        #: throws exception when nothing is printed.
        {
            my $expected =
                "[Failed] warning expected : failed (nothing printed).\n" .
                "  \$expected: 'SOS'\n";
            undef $@;
            my $code = sub { 1+1 == 2 };
            eval { OK ($code)->warns('SOS') };
            is(_chomp($@), $expected);
        }

        #: throws exception when actual warning message is different from expected.
        {
            my $expected =
                "[Failed] \$warning eq \$expected : failed.\n" .
                "  \$warning:  'Haruhi\n'\n" .
                "  \$expected: 'Sasaki\n'\n";
            undef $@;
            my $code = sub { warn "Haruhi\n" };
            eval { OK ($code)->warns("Sasaki\n") };
            is(_chomp($@), $expected);
        }

        #: throws exception when actual warning message is not matched to pattern.
        {
            my $expected =
                '[Failed] $warning =~ $expected : failed.\n' .
                '  $warning:  \'SOS at t/assertion.t line %LINE%.\n\'\n' .
                '  $expected: qr/(?-xism:^SOS  at .* line .*$)/\n';
            $expected =~ s/\\n/\n/g;
            $expected =~ s/\%LINE\%/__LINE__ + 2/e;
            undef $@;
            my $code = sub { warn 'SOS' };
            eval { OK ($code)->warns(qr/^SOS  at .* line .*$/) };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#not_warn()")) {

        #: returns $this when nothing printed.
        {
            my $code = sub { 1 };
            my $ret = OK ($code)->not_warn();
            is(ref($ret->{actual}), 'CODE');
        }

        #: throws nothing when nothing printed.
        {
            undef $@;
            my $code = sub { 1 };
            eval { OK ($code)->not_warn() };
            is($@, '');
        }

        #: throws exception when something printed to stderr.
        {
            my $expected =
                "[Failed] no warning expected : failed.\n" .
                "  \$warning: 'SOS\n'\n";
            undef $@;
            my $code = sub { warn("SOS\n") };
            eval { OK ($code)->not_warn() };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#is_string()")) {

        #: returns $this when actual is a string.
        {
            my $ret = OK ("SOS")->is_string();
            is($ret->{actual}, "SOS");
        }

        #: throws exception when actual is not a string.
        {
            undef $@;
            eval { OK (123)->is_string() };
            my $expected =
                "[Failed] \$actual : string expected, but not.\n" .
                "  \$actual:   123\n";
            is(_chomp($@), $expected);
            #
            undef $@;
            eval { OK (undef)->is_string() };
            my $expected2 =
                "[Failed] \$actual : string expected, but not.\n" .
                "  \$actual:   undef\n";
            is(_chomp($@), $expected2);
        }

    }


    for (TARGET("#is_number()")) {

        #: returns $this when actual is a number.
        {
            my $ret1 = OK (- 123)->is_number();
            is($ret1->{actual}, - 123);
            my $ret2 = OK (- 3.14)->is_number();
            is($ret2->{actual}, - 3.14);
        }

        #: throws exception when actual is not a number.
        {
            undef $@;
            eval { OK ("123")->is_number() };
            my $expected =
                "[Failed] \$actual : number expected, but not.\n" .
                "  \$actual:   '123'\n";
            is(_chomp($@), $expected);
            #
            undef $@;
            eval { OK (undef)->is_number() };
            my $expected2 =
                "[Failed] \$actual : number expected, but not.\n" .
                "  \$actual:   undef\n";
            is(_chomp($@), $expected2);
        }

    }


    for (TARGET("#is_integer()")) {

        #: returns $this when actual is an integer.
        {
            my $ret = OK (- 123)->is_integer();
            is($ret->{actual}, - 123);
        }

        #: throws exception when actual is not an integer.
        {
            undef $@;
            eval { OK ("123")->is_integer() };
            my $expected =
                "[Failed] \$actual : integer expected, but not.\n" .
                "  \$actual:   '123'\n";
            is(_chomp($@), $expected);
            #
            undef $@;
            eval { OK (undef)->is_integer() };
            my $expected2 =
                "[Failed] \$actual : integer expected, but not.\n" .
                "  \$actual:   undef\n";
            is(_chomp($@), $expected2);
        }

    }


    for (TARGET("#is_float()")) {

        #: returns $this when actual is a float.
        {
            my $ret = OK (- 3.14)->is_float();
            is($ret->{actual}, - 3.14);
        }

        #: throws exception when actual is not a float.
        {
            undef $@;
            eval { OK ("3.14")->is_float() };
            my $expected =
                "[Failed] \$actual : float expected, but not.\n" .
                "  \$actual:   '3.14'\n";
            is(_chomp($@), $expected);
            #
            undef $@;
            eval { OK (undef)->is_float() };
            my $expected2 =
                "[Failed] \$actual : float expected, but not.\n" .
                "  \$actual:   undef\n";
            is(_chomp($@), $expected2);
        }

    }


    for (TARGET("#is_ref()")) {

        #: returns $this when actual is a specified reference.
        {
            my $ret;
            $ret = OK (["Haruhi"])->is_ref('ARRAY');
            is($ret->{actual}->[0], "Haruhi");
            #
            $ret = OK ({name=>"Haruhi"})->is_ref('HASH');
            is($ret->{actual}->{name}, "Haruhi");
            #
            $ret = OK (sub {"Haruhi"})->is_ref('CODE');
            is($ret->{actual}->(), "Haruhi");
        }

        #: throws exception when actual is not a specified reference.
        {
            my $expected;
            undef $@;
            eval { OK (["Sasaki"])->is_ref('HASH') };
            $expected =
                "[Failed] ref(\$actual) eq 'HASH' : failed.\n" .
                "  ref(\$actual): 'ARRAY'\n" .
                "  \$actual:    [\n" .
                "          'Sasaki'\n" .
                "        ]\n";
            is(_chomp($@), $expected);
            #
            undef $@;
            eval { OK ({name=>"Sasaki"})->is_ref('ARRAY') };
            $expected =
                "[Failed] ref(\$actual) eq 'ARRAY' : failed.\n" .
                "  ref(\$actual): 'HASH'\n" .
                "  \$actual:    {\n" .
                "          'name' => 'Sasaki'\n" .
                "        }\n";
            is(_chomp($@), $expected);
            #
            undef $@;
            eval { OK ("Haruhi")->is_ref('ARRAY') };
            $expected =
                "[Failed] ref(\$actual) eq 'ARRAY' : failed.\n" .
                "  ref(\$actual): ''\n" .
                "  \$actual:    'Haruhi'\n";
            is(_chomp($@), $expected);
            #
            undef $@;
            eval { OK (undef)->is_ref('ARRAY') };
            $expected =
                "[Failed] ref(\$actual) eq 'ARRAY' : failed.\n" .
                "  ref(\$actual): ''\n" .
                "  \$actual:    undef\n";
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#not_ref()")) {

        #: returns $this when actual is not a specified reference.
        {
            my $ret;
            $ret = OK (["Haruhi"])->not_ref('HASH');
            is($ret->{actual}->[0], "Haruhi");
            #
            $ret = OK ({name=>"Haruhi"})->not_ref('ARRAY');
            is($ret->{actual}->{name}, "Haruhi");
            #
            $ret = OK (sub {"Haruhi"})->not_ref('ARRAY');
            is($ret->{actual}->(), "Haruhi");
        }

        #: throws exception when actual is not a specified reference.
        {
            my $expected;
            undef $@;
            eval { OK (["Sasaki"])->not_ref('ARRAY') };
            $expected =
                "[Failed] ref(\$actual) ne 'ARRAY' : failed.\n" .
                "  ref(\$actual): 'ARRAY'\n" .
                "  \$actual:    [\n" .
                "          'Sasaki'\n" .
                "        ]\n";
            is(_chomp($@), $expected);
            #
            undef $@;
            eval { OK ({name=>"Sasaki"})->not_ref('HASH') };
            $expected =
                "[Failed] ref(\$actual) ne 'HASH' : failed.\n" .
                "  ref(\$actual): 'HASH'\n" .
                "  \$actual:    {\n" .
                "          'name' => 'Sasaki'\n" .
                "        }\n";
            is(_chomp($@), $expected);
        }

    }


#    for (TARGET("#is_arrayref()")) {
#
#        #: returns $this when actual is a reference of array.
#        {
#            my $arr = ["SOS"];
#            my $ret = OK ($arr)->is_arrayref();
#            is($ret->{actual}->[0], "SOS");
#        }
#
#        #: throws exception when actual is not a reference of array.
#        {
#            undef $@;
#            eval { OK ({x=>1})->is_arrayref() };
#            my $expected =
#                "[Failed] ref(\$actual) : ARRAY expected, but got HASH.\n" .
#                "  \$actual:   {\n" .
#                "          'x' => 1\n" .
#                "        }\n";
#            is(_chomp($@), $expected);
#            #
#            undef $@;
#            eval { OK (undef)->is_arrayref() };
#            my $expected2 =
#                "[Failed] ref(\$actual) : ARRAY expected, but got .\n" .
#                "  \$actual:   undef\n";
#            is(_chomp($@), $expected2);
#        }
#
#    }
#
#
#    for (TARGET("#is_hashref()")) {
#
#        #: returns $this when actual is a reference of hash.
#        {
#            my $hash = {x=>10};
#            my $ret = OK ($hash)->is_hashref();
#            is($ret->{actual}->{x}, 10);
#        }
#
#        #: throws exception when actual is not a reference of hash.
#        {
#            undef $@;
#            eval { OK (["SOS"])->is_hashref() };
#            my $expected =
#                "[Failed] ref(\$actual) : HASH expected, but got ARRAY.\n" .
#                "  \$actual:   [\n" .
#                "          'SOS'\n" .
#                "        ]\n";
#            is(_chomp($@), $expected);
#            #
#            undef $@;
#            eval { OK (undef)->is_hashref() };
#            my $expected2 =
#                "[Failed] ref(\$actual) : HASH expected, but got .\n" .
#                "  \$actual:   undef\n";
#            is(_chomp($@), $expected2);
#        }
#
#    }
#
#
#    for (TARGET("#is_coderef()")) {
#
#        #: returns $this when actual is a reference of code.
#        {
#            my $code = sub { "SOS" };
#            my $ret = OK ($code)->is_coderef();
#            is($ret->{actual}->(), "SOS");
#        }
#
#        #: throws exception when actual is not a reference of code.
#        {
#            undef $@;
#            eval { OK (["SOS"])->is_coderef() };
#            my $expected =
#                "[Failed] ref(\$actual) : CODE expected, but got ARRAY.\n" .
#                "  \$actual:   [\n" .
#                "          'SOS'\n" .
#                "        ]\n";
#            is(_chomp($@), $expected);
#            #
#            undef $@;
#            eval { OK (undef)->is_coderef() };
#            my $expected2 =
#                "[Failed] ref(\$actual) : CODE expected, but got .\n" .
#                "  \$actual:   undef\n";
#            is(_chomp($@), $expected2);
#        }
#
#    }


    for (TARGET("#length()")) {

        #: returns $this when actual string length is same as expected.
        {
            my $ret = OK ("Haruhi")->length(6);
            is($ret->{actual}, "Haruhi");
        }

        #: returns $this when actual array length is same as expected.
        {
            my $ret = OK (["S", "O", "S"])->length(3);
            is_deeply($ret->{actual}, ["S", "O", "S"]);
        }

        #: throws exception when actual is not string nor array.
        {
            undef $@;
            eval { OK (undef)->length(0) };
            my $expected =
                "[ERROR] \$actual : string or array expected.\n" .
                "  \$actual:   undef\n";
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#has()")) {

        #: returns $this when actual object has expected attrbute.
        {
            my $obj = {"name"=>"Haruhi", "team"=>"SOS"};
            my $ret = OK ($obj)->has('name', "Haruhi");
            ok($ret->{actual} == $obj);
        }

        #: throws exception when actual object doesn't have the attribute.
        {
            undef $@;
            my $obj = {"name"=>"Haruhi"};
            eval { OK ($obj)->has('team', "SOS") };
            my $expected =
                "[Failed] defined(\$actual->{team}) : failed.\n" .
                "  \$actual:   {\n" .
                "          'name' => 'Haruhi'\n" .
                "        }\n";
            is(_chomp($@), $expected);
        }

        #: throws exception when actual value is different from expected.
        {
            undef $@;
            my $obj = {"name"=>"Haruhi"};
            eval { OK ($obj)->has('name', "Sasaki") };
            my $expected =
                "[Failed] \$actual->{name} eq \$expected : failed.\n" .
                "  \$actual->{name}: 'Haruhi'\n" .
                "  \$expected:      'Sasaki'\n";
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#can_()")) {

        #: returns $this when $actual can respond to $expected method.
        {
            my $obj = bless({name=>'SOS'}, 'Dummy');
            my $ret = OK ($obj)->can_('isa');
            is($ret->{actual}->{name}, 'SOS');
        }

        #: throws exception when $actual cannot respond to $expected method.
        {
            my $expected =
                "[Failed] \$actual->can_('foobar') : failed.\n" .
                "  \$actual:   'foobar'\n";
            my $obj = bless({}, 'Dummy');
            undef $@;
            eval { OK ($obj)->can_('foobar') };
            is(_chomp($@), $expected);
            undef $@;
        }

        #: error when no method name specified.
        {
            my $expected =
                "[ERROR] OK()->can_(): method name required.\n";
            my $obj = bless({}, 'Dummy');
            undef $@;
            eval { OK ($obj)->can_('') };
            is(_chomp($@), $expected);
            undef $@;
        }

    }


    for (TARGET("#can_not()")) {

        #: returns $this when $actual can NOT respond to $expected method.
        {
            my $obj = bless({name=>"SOS"}, 'Dummy');
            my $ret = OK ($obj)->can_not('foo');
            is($ret->{actual}->{name}, 'SOS');
        }

        #: throws exception when $actual can respond to $expected method.
        {
            my $expected =
                "[Failed] ! \$actual->can_not('isa') : failed.\n" .
                "  \$actual:   'isa'\n";
            my $obj = bless({}, 'Dummy');
            undef $@;
            eval { OK ($obj)->can_not('isa') };
            is(_chomp($@), $expected);
            undef $@;
        }

        #: error when no method name specified.
        {
            my $expected =
                "[ERROR] OK()->can_not(): method name required.\n";
            my $obj = bless({}, 'Dummy');
            undef $@;
            eval { OK ($obj)->can_not('') };
            is(_chomp($@), $expected);
            undef $@;
        }

    }


    for (TARGET("#same()")) {

        #: returns $this when actual and expected are same.
        {
            my $obj = ["SOS"];
            my $ret = OK ($obj)->same($obj);
        }

        #: throws exception when actual and expected are not same.
        {
            undef $@;
            my $obj1 = ["SOS"];
            my $obj2 = ["SOS"];
            eval { OK ($obj1)->same($obj2) };
            my $expected =
                "[Failed] refaddr(\$actual) == refaddr(\$expected) : failed.\n" .
                "  \$actual:   [\n" .
                "          'SOS'\n" .
                "        ]\n" .
                "  \$expected: [\n" .
                "          'SOS'\n" .
                "        ]\n";
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#not_same()")) {

        #: returns $this when actual and expected are not same.
        {
            my $obj1 = ["SOS"];
            my $obj2 = ["SOS"];
            my $ret = OK ($obj1)->not_same($obj2);
        }

        #: throws exception when actual and expected are same.
        {
            undef $@;
            my $obj1 = ["SOS"];
            my $obj2 = $obj1;
            eval { OK ($obj1)->not_same($obj2) };
            my $expected =
                "[Failed] refaddr(\$actual) != refaddr(\$expected) : failed.\n" .
                "  \$actual:   [\n" .
                "          'SOS'\n" .
                "        ]\n" .
                "  \$expected: [\n" .
                "          'SOS'\n" .
                "        ]\n";
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#is_true()")) {

        #: returns $this when expression is truthy.
        {
            my $ret = OK (1==1)->is_true();
            is($ret->{actual}, 1==1);
        }

        #: throws exception when expression is falthy.
        {
            my $expected =
                "[Failed] OK(\$expression) : assertion failed.\n" .
                "  \$expression:  ''\n";
            undef $@;
            eval { OK (0==1)->is_true() };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#is_false()")) {

        #: returns $this when expression is falthy.
        {
            my $ret = OK (0==1)->is_false();
            is($ret->{actual}, 0==1);
        }

        #: throws exception when expression is truthy.
        {
            my $expected =
                "[Failed] OK(! \$expression) : assertion failed.\n" .
                "  \$expression:  1\n";
            undef $@;
            eval { OK (1==1)->is_false() };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#equals()")) {   ## !! EXPERIMENTAL !!

        #: returns $this when actual and expected are equal.
        {
            my $obj1 = [
                {name=>"Haruhi", team=>"SOS"},
                {name=>"Kyon", team=>"SOS"},
            ];
            my $obj2 = [
                {name=>"Haruhi", team=>"SOS"},
                {name=>"Kyon", team=>"SOS"},
            ];
            my $ret = OK ($obj1)->equals($obj2);
        }

        #: throws exception when actual and expected are not eaual.
        {
            undef $@;
            my $obj1 = [
                {name=>"Haruhi", team=>"SOS"},
                {name=>"John", team=>"SOS"},
            ];
            my $obj2 = [
                {name=>"Haruhi", team=>"SOS"},
                {name=>"Kyon", team=>"SOS"},
            ];
            eval { OK ($obj1)->equals($obj2) };
            my $expected =
                "[Failed] \$actual equals to \$expected : failed.\n" .
                "--- Dumper(\$expected)\n" .
                "+++ Dumper(\$actual)\n" .
                "\@\@ -4,7 +4,7 \@\@\n" .
                "             'team' => 'SOS'\n" .
                "           },\n" .
                "           {\n" .
                "-            'name' => 'Kyon',\n" .
                "+            'name' => 'John',\n" .
                "             'team' => 'SOS'\n" .
                "           }\n" .
                "         ];\n" .
                "";
            is(_chomp($@), $expected);
        }

        #: throws exception when ref($actual) and ref($expected) are not eaual.
        {
            undef $@;
            my $obj1 = ["Haruhi"];
            my $obj2 = {name=>"Haruhi"};
            eval { OK ($obj1)->equals($obj2) };
            my $expected =
                "[Failed] ref(\$actual) eq ref(\$expected) : failed.\n" .
                "  ref(\$actual):   'ARRAY'\n" .
                "  ref(\$expected): 'HASH'\n" .
                "  \$actual:   [\n" .
                "          'Haruhi'\n" .
                "        ]\n" .
                "  \$expected: {\n" .
                "          'name' => 'Haruhi'\n" .
                "        }\n" .
                "";
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#not_equal()")) {   ## !! EXPERIMENTAL !!

        #: returns $this when $actual and $expected are not equal.
        {
            my $ret = OK ('1')->not_equal(1);
            is($ret->{actual}, '1');
        }

        #: throws exception when $actual and $expected are equal.
        {
            my $expected =
                "[Failed] \$actual and \$expected are not equal: failed.\n" .
                "  \$actual and \$expected: '1'\n";
            undef $@;
            eval { OK ('1')->not_equal('1') };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#all()")) {

        #: returns $this when all items in $actual satisfy $expected block.
        {
            my $arr = [3, 6, 9, 12];
            my $ret = OK ($arr)->all(sub {$_ % 3 == 0});
            ok($ret->{actual}->[3] == 12);
        }

        #: throws exception when any item in $actual doesn't satisfy $expected block.
        {
            my $expected =
                "[Failed] OK(\$actual)->all(sub{...}) : failed at index=2.\n" .
                "  \$actual->[2]: 10\n";
            my $arr = [3, 6, 10, 12];
            undef $@;
            eval { OK ($arr)->all(sub {$_ % 3 == 0}) };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#any()")) {

        #: returns $this when any item in $actual satisfies $expected block.
        {
            my $arr = [3, 6, 10, 12];
            my $ret = OK ($arr)->any(sub {$_ % 5 == 0});
            ok($ret->{actual}->[3] == 12);
        }

        #: throws exception when all items in $actual don't satisfy $expected block.
        {
            my $expected =
                "[Failed] OK(\$actual)->any(sub{...}) : failed.\n" .
                "  \$actual: [\n" .
                "          3,\n" .
                "          6,\n" .
                "          9,\n" .
                "          12\n" .
                "        ]\n" .
                "";
            my $arr = [3, 6, 9, 12];
            undef $@;
            eval { OK ($arr)->any(sub {$_ % 5 == 0}) };
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#is_file()")) {

        #: returns $this when file exists.
        {
            my $ret = OK (__FILE__)->is_file();
            is($ret->{actual}, __FILE__);
        }

        #: throws exception when file not exist.
        {
            undef $@;
            eval { OK ("foobar.php")->is_file() };
            my $expected =
                "[Failed] -f \$actual : failed (file not exist).\n" .
                "  \$actual:   'foobar.php'\n";
            is(_chomp($@), $expected);
        }

        #: throws exception when not a file.
        {
            undef $@;
            eval { OK ("/")->is_file() };
            my $expected =
                "[Failed] -f \$actual : failed (not a file).\n" .
                "  \$actual:   '/'\n";
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#is_directory()")) {

        #: returns $this when directory exists.
        {
            use Cwd;
            my $path = getcwd();
            my $ret = OK ($path)->is_dir();
            is($ret->{actual}, $path);
        }

        #: throws exception when directory not exist.
        {
            undef $@;
            eval { OK ("foobar_php")->is_dir() };
            my $expected =
                "[Failed] -d \$actual : failed (directory not exist).\n" .
                "  \$actual:   'foobar_php'\n";
            is(_chomp($@), $expected);
        }

        #: throws exception when not a directory.
        {
            undef $@;
            eval { OK (__FILE__)->is_dir() };
            my $expected =
                "[Failed] -d \$actual : failed (not a directory).\n" .
                "  \$actual:   '" . __FILE__ . "'\n";
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#not_file()")) {

        #: returns $this when doesn't exist.
        {
            my $ret = OK ("foobar_py")->not_file();
            is($ret->{actual}, "foobar_py");
        }

        #: returns $this when not a file.
        {
            my $ret = OK ("/")->not_file();
            is($ret->{actual}, "/");
        }

        #: throws exception when file exists.
        {
            undef $@;
            eval { OK (__FILE__)->not_file() };
            my $expected =
                "[Failed] ! -f \$actual : failed (file exists).\n" .
                "  \$actual:   '" . __FILE__ . "'\n";
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#not_dir()")) {

        #: returns $this when doesn't exist.
        {
            my $ret = OK ("foobar_py")->not_dir();
            is($ret->{actual}, "foobar_py");
        }

        #: returns $this when not a dir.
        {
            my $ret = OK (__FILE__)->not_dir();
            is($ret->{actual}, __FILE__);
        }

        #: throws exception when directory exists.
        {
            undef $@;
            eval { OK ("/")->not_dir() };
            my $expected =
                "[Failed] ! -d \$actual : failed (directory exists).\n" .
                "  \$actual:   '/'\n";
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#exist()")) {

        #: returns $this when file or directory exists.
        {
            my $ret = OK (__FILE__)->exist();
            is($ret->{actual}, __FILE__);
            my $ret2 = OK ("/")->exist();
            is($ret2->{actual}, "/");
        }

        #: throws exception when neigther file nor directory exist.
        {
            undef $@;
            eval { OK ("foobar_py")->exist() };
            my $expected =
                "[Failed] -e \$actual : failed (file or directory not found).\n" .
                "  \$actual:   'foobar_py'\n";
            is(_chomp($@), $expected);
        }

    }


    for (TARGET("#not_exist()")) {

        #: returns $this when neigther file nor directory exist.
        {
            my $ret = OK ("foobar_py")->not_exist();
            is($ret->{actual}, "foobar_py");
        }

        #: throws exception when file exists.
        {
            undef $@;
            eval { OK (__FILE__)->not_exist() };
            my $expected =
                "[Failed] ! -e \$actual : failed (file or directory exists).\n" .
                "  \$actual:   '" . __FILE__ . "'\n";
            is(_chomp($@), $expected);
        }

    }


}

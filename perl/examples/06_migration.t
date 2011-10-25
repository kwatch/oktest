###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

use strict;
use warnings;
no warnings 'void';   # suppress 'Useless use of ... in void context'

use Oktest;
use Oktest::Migration::TestMore;


topic "Migration Example", sub {

    spec "helpers", sub {
        ok(1+1 == 2, "test name");
        is(1+1, 2, "test name");
        isnt(1+1, 3, "test name");
        like("SOS", qr/^SOS$/, "test name");
        unlike("SOS", qr/^ZOZ$/, "test name");
        cmp_ok(1+1, '>', 1, "test name");
        is_deeply([1,2,3], [1,2,3], "test name");   ## !! EXPERIMENTAL !!
        my $obj = bless({}, 'Dummy');
        can_ok($obj, 'isa');
        isa_ok($obj, 'Dummy', "test name");
        throws_ok(sub { die("SOS\n") }, "SOS\n", "test name");
        throws_ok(sub { die("SOS\n") }, qr/SOS/, "test name");
        dies_ok(sub { die("SOS\n") }, "test name");
        lives_ok(sub { return 1 }, "test name");
        warning_like(sub { warn("SOS\n") }, qr/SOS/, "test name");
        diag("message");
    };

};


Oktest::main() if $0 eq __FILE__;
1;

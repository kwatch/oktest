###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

use strict;
use warnings;
no warnings 'void';   # suppress 'Useless use of ... in void context'

use Oktest;


target "Assertion Example", sub {

    spec "numeric operators", sub {
        OK (1+1) == 2;
        OK (1+1) != 1;
        OK (1+1) >  1;
        OK (1+1) >= 2;
        OK (1+1) <  3;
        OK (1+1) <= 2;
        OK (1+1)->cmp('==', 2);   # or '!=', '>', and so on
        OK (3.141)->in_delta(3.14, 0.01);
    };

    spec "string operators", sub {
        OK ('aaa') eq 'aaa';
        OK ('aaa') ne 'bbb';
        OK ('aaa') lt 'bbb';
        OK ('aaa') le 'aaa';
        OK ('bbb') gt 'aaa';
        OK ('aaa') ge 'aaa';
        OK ('aaa')->cmp('eq', 'aaa');   # or 'ne', 'lt', and so on
        OK ('aaa')->length(3);
    };

    spec "logical expression", sub {
        OK (1==1)->is_truthy();
        OK (0==1)->is_falsy();
        OK (0)->is_defined();
        OK (undef)->not_defined();
    };

    spec "regular expression", sub {
        OK ('FOO')->matches(qr/^[A-Z]+$/);
        OK ('123')->not_match(qr/^[A-Z]+$/);
    };

    spec "type", sub {
        OK ('s')->is_string();
        OK (123)->is_integer();
        OK (0.1)->is_float();
        OK ([1,2,3])->is_ref('ARRAY');
        OK ({x=>10})->is_ref('HASH');
        OK (sub {1})->is_ref('CODE');
    };

    spec "object", sub {
        my $obj = bless({'x'=>1, 'y'=>2}, 'FooClass');
        OK ($obj)->is_a('FooClass');
        OK ($obj)->not_a('BarClass');
        OK ($obj)->has('x', 1)->has('y', 2);
        OK ($obj)->has('x')->has('y');
        OK ($obj)->can_('isa')->can_('can');
        OK ($obj)->can_not('foo')->can_not('bar');
        my $arr = [1, 2, 3];
        OK ($arr)->length(3);
        my $arr2 = [1, 2, 3];
        OK ($arr)->same($arr);
        OK ($arr)->not_same($arr2);
        OK ($arr)->equals($arr2);   ## (EXPERIMENTAL) similar to 'is_deeply()'
    };

    spec "file system", sub {
        use Cwd qw(getcwd);
        my $file = __FILE__;
        my $pwd  = getcwd();
        OK ($file)->is_file();
        OK ($pwd )->not_file();
        OK ($pwd )->is_dir();
        OK ($file)->not_dir();
        OK ($file)->exist();
        OK ($pwd )->exist();
        OK ("NotExist.txt")->not_exist();
    };

    spec "exception", sub {
        OK (sub { die "SOS\n"  })->dies("SOS\n");
        OK (sub { die "SOS\n"  })->dies(qr/^SOS$/);
        OK (sub { 1 })->not_die();
        #
        OK (sub { warn "SOS\n" })->warns("SOS\n");
        OK (sub { warn "SOS\n" })->warns(qr/^SOS$/);
        OK (sub { 1 })->not_warn();
    };

    spec "collection", sub {
        OK ([3, 6, 9, 12])->all(sub {$_ % 3 == 0});
        OK ([3, 6, 9, 12])->any(sub {$_ % 4 == 0});
    };

};


Oktest::main() if $0 eq __FILE__;
1;

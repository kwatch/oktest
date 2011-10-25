###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

use strict;
use warnings;
use Test::More tests => 60;

use Oktest;


sub TARGET { return undef; }
#sub SPEC { return; }



for (TARGET('Oktest')) {


    for (TARGET('OK()')) {

        #: returns assertion object.
        {
            my $ret = OK("SOS");
            isa_ok($ret, 'Oktest::AssertionObject');
            is($ret->{actual}, "SOS");
            Oktest::__clear();
        };

        #: registers assertion object.
        {
            Oktest::__clear();
            is($#Oktest::__assertion_objects, -1);
            OK("Haruhi");
            OK("Sasaki");
            is($#Oktest::__assertion_objects, 1);
            is($Oktest::__assertion_objects[0]->{actual}, "Haruhi");
            is($Oktest::__assertion_objects[1]->{actual}, "Sasaki");
            Oktest::__clear();
        };

    }


    for (TARGET('pre_cond()')) {

        #: is an alias of 'OK()'.
        {
            Oktest::__clear();
            my $ret = pre_cond("John Smith");
            isa_ok($ret, 'Oktest::AssertionObject');
            is($ret->{actual}, "John Smith");
            is($Oktest::__assertion_objects[0]->{actual}, "John Smith");
            Oktest::__clear();
        };

    }


    for (TARGET('topic()')) {

        #: returns an instance of TopicObject.
        {
            my $ret = topic 'topic1', sub { 'sub1' };
            isa_ok($ret, 'Oktest::TopicObject');
        }

        #: takes topic name and block.
        {
            my $ret = topic 'topic1', sub { 'sub1' };
            is($ret->{name}, 'topic1');
        }

        #: block passed is called.
        {
            my $called = 0;
            topic 'topic1', sub { $called = 1 };
            is($called, 1);
        }

    }


    for (TARGET('case_when()')) {

        #: returns an instance of CaseObject which extends TopicObject.
        {
            my $ret = case_when 'positive value...', sub { 'sub1' };
            isa_ok($ret, 'Oktest::CaseObject');
            isa_ok($ret, 'Oktest::TopicObject');
        }

        #: adds 'When ' prefix to condition description.
        {
            my $ret = case_when 'value is positive...', sub { 'sub1' };
            is($ret->{name}, 'When value is positive...');
        }

        #: block passed is called.
        {
            my $called = 0;
            case_when 'value is positive...', sub { $called = 1 };
            is($called, 1);
        }

    }


    for (TARGET('spec()')) {

        #: takes spec description and block, and returns SpecObject object.
        {
            #my $actual = Oktest::Util::capture_stdout {
            #    spec { "description1" } sub { "sub1" };
            #    spec "description1", sub { "sub1" };
            #};
            #my $expected = "ok - description1\n";
            #is($actual, $expected);
            my $ret = spec "desc1", sub { "sub1" };
            isa_ok($ret, 'Oktest::SpecObject');
        }

        #: block passed is not called just after when created.
        {
            my $called = 0;
            my $so = spec "description1", sub { $called = 1; };
            is($called, 0);
        }

        #: new block containing TODO is created when block is not passed.
        {
            my $so = spec "desc1";
            is(ref($so->{block}), 'CODE');
            undef $@;
            eval { $so->{block}->() };
            is($@, "[TODO] not implemented yet.\n");
        }

#        #: block passed throws exception when assertion is failed.
#        {
#            my $so = spec "description1", sub { die("--failed--"); };
#            $so->{block}->();
#            my $here = __LINE__ - 1;
#            my $expected =
#                "not ok - description1\n" .
#                "# --failed-- at t/oktest.t line $here.\n";
#            is($sout->{output}, $expected);
#        }

        topic "ClassName", sub {
            topic "#method()", sub {
                spec "spec1", sub { OK (1+1) == 2 };
                spec "spec2", sub { OK (1-1) == 0 };
            };
            topic "#method2()", sub {
                spec "spec3", sub { OK (1*1) == 1 };
            };
        };

        #: spec object created is registered into parent topic object.
        {
            my ($to, $specs);
            $to = Oktest::TopicObject::__last();
            is($to->{name}, 'ClassName');
            $specs = $to->{specs};
            is($#{$specs}+1, 0);
            #
            is($to->{topics}->[0]->{name}, '#method()');
            $specs = $to->{topics}->[0]->{specs};
            is($#{$specs}+1, 2);
            is($specs->[0]->{desc}, 'spec1');
            is($specs->[1]->{desc}, 'spec2');
            #
            is($to->{topics}->[1]->{name}, '#method2()');
            $specs = $to->{topics}->[1]->{specs};
            is($#{$specs}+1, 1);
            is($specs->[0]->{desc}, 'spec3');
        }

        #: parent topic object is set into each spec object.
        {
            my ($to, $specs);
            $to = Oktest::TopicObject::__last();
            my $to1 = $to->{topics}->[0];
            ok($to1->{specs}->[0]->{parent} == $to1);
            ok($to1->{specs}->[1]->{parent} == $to1);
            my $to2 = $to->{topics}->[1];
            ok($to2->{specs}->[0]->{parent} == $to2);
        }

        Oktest::__clear();

    }


    for (TARGET('before()')) {

        #: takes a block and sets it into current topic object.
        {
            Oktest::__clear();
            topic "Parent", sub {
                before { '[Parent] before' };
                topic "Child", sub {
                    before { '[Child] before' };
                };
            };
            my $to1 = Oktest::TopicObject::__last();
            my $to2 = $to1->{topics}->[0];
            is(ref($to1->{_before}), 'CODE');
            is(ref($to2->{_before}), 'CODE');
            is($to1->{_before}->(), '[Parent] before');
            is($to2->{_before}->(), '[Child] before');
        }

        #: error when called out of topic block.
        {
            undef $@;
            eval { before { 1 } };
            like($@, qr/^before\(\) should be called in topic block\. at .* line \d+\.$/);
            undef $@;
        }

    }


    for (TARGET('after()')) {

        #: takes a block and sets it into current topic object.
        {
            Oktest::__clear();
            topic "Parent", sub {
                after { '[Parent] after' };
                topic "Child", sub {
                    after { '[Child] after' };
                };
            };
            my $to1 = Oktest::TopicObject::__last();
            my $to2 = $to1->{topics}->[0];
            is(ref($to1->{_after}), 'CODE');
            is(ref($to2->{_after}), 'CODE');
            is($to1->{_after}->(), '[Parent] after');
            is($to2->{_after}->(), '[Child] after');
        }

        #: error when called out of topic block.
        {
            undef $@;
            eval { after { 1 } };
            like($@, qr/^after\(\) should be called in topic block\. at .* line \d+\.$/);
            undef $@;
        }

    }


    for (TARGET('before_all()')) {

        #: takes a block and sets it into current topic object.
        {
            Oktest::__clear();
            topic "Parent", sub {
                before_all { '[Parent] before_all' };
                topic "Child", sub {
                    before_all { '[Child] before_all' };
                };
            };
            my $to1 = Oktest::TopicObject::__last();
            my $to2 = $to1->{topics}->[0];
            is(ref($to1->{_before_all}), 'CODE');
            is(ref($to2->{_before_all}), 'CODE');
            is($to1->{_before_all}->(), '[Parent] before_all');
            is($to2->{_before_all}->(), '[Child] before_all');
        }

        #: error when called out of topic block.
        {
            undef $@;
            eval { before_all { 1 } };
            like($@, qr/^before_all\(\) should be called in topic block\. at .* line \d+\.$/);
            undef $@;
        }

    }


    for (TARGET('after_all()')) {

        #: takes a block and sets it into current topic object.
        {
            Oktest::__clear();
            topic "Parent", sub {
                after_all { '[Parent] after_all' };
                topic "Child", sub {
                    after_all { '[Child] after_all' };
                };
            };
            my $to1 = Oktest::TopicObject::__last();
            my $to2 = $to1->{topics}->[0];
            is(ref($to1->{_after_all}), 'CODE');
            is(ref($to2->{_after_all}), 'CODE');
            is($to1->{_after_all}->(), '[Parent] after_all');
            is($to2->{_after_all}->(), '[Child] after_all');
        }

        #: error when called out of topic block.
        {
            undef $@;
            eval { after_all { 1 } };
            like($@, qr/^after_all\(\) should be called in topic block\. at .* line \d+\.$/);
            undef $@;
        }

    }


    for (TARGET('skip_when()')) {

        #: throws exception with reason when condition is true.
        {
            my $condition = 1==1;
            undef $@;
            eval { skip_when $condition, "...reason..." };
            is($@, "[Skipped] ...reason...\n");
            undef $@;
        }

        #: throws nothing when condition is false.
        {
            my $condition = 0==1;
            undef $@;
            eval { skip_when $condition, "...reason..." };
            is($@, '');
        }

    }


    for (TARGET('TODO()')) {

        #: throws exception with description text.
        {
            undef $@;
            eval { TODO "...description..." };
            is($@, "[TODO] ...description...\n");
            undef $@;
        }

    }


    for (TARGET('run()')) {

        #: calls block of each spec objects.
        {
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
            my $actual = Oktest::Util::capture_stdout { Oktest::run() };
            $actual =~ s/elapsed: (\d\.\d\d\d)/elapsed: 0.000/;
            is($actual, $expected);
        }

    }


    for (TARGET('__at_exit()')) {

        #: warns when unevaluated assertion remained.
        {
            Oktest::__clear();
            is($#Oktest::__assertion_objects, -1);
            my $obj = bless({'x'=>1}, 'FooClass');
            OK($obj)->is_a('FooClass');
            OK($obj)->isa('FooClass');      # should be 'is_a()'
            my $linenum  = __LINE__ - 1;
            my $filename = __FILE__;
            is($#Oktest::__assertion_objects, 1);
            my ($sout, $serr) = Oktest::Util::capture_stdouterr {
                Oktest::__at_exit();
            };
            is($sout, '');
            is($serr, "*** OK() called but not tested at '$filename' line $linenum.\n");
            Oktest::__clear();
        }

    }


}

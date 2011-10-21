###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

##
## example of before/after/before_all/after_all
##

use strict;
use warnings;
no warnings 'void';   # suppress 'Useless use of ... in void context'
use Oktest;


target "Parent", sub {

    before_all { print "= [Parent] before_all\n" };
    after_all  { print "= [Parent] after_all\n" };
    before     { print "= [Parent] before\n" };
    after      { print "= [Parent] after\n" };

    target "Child1", sub {
        spec "A1", sub { OK (1+1) == 2 };
        spec "B1", sub { OK (1-1) == 0 };
    };

    target "Child2", sub {
        before_all { print "  = [Child] before_all\n" };
        after_all  { print "  = [Child] after_all\n" };
        before     { print "  = [Child] before\n" };
        after      { print "  = [Child] after\n" };
        spec "A3", sub { OK (1+1) == 2 };
        spec "B4", sub { OK (1-1) == 0 };
    };

};


target "Context Example", sub {

    my $member;
    before {
        $member = "Haruhi";
        my $context = shift;
        $context->{team} = "SOS";
    };

    spec "'before' block can set variable.", sub {
        OK ($member) eq "Haruhi";
    };

    spec "'before' block can set context data.", sub {
        my $context = shift;
        OK ($context)->has('team', "SOS");
    };

};


Oktest::main() if $0 eq __FILE__;
1;

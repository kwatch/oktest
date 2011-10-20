###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

use strict;
use warnings;
no warnings 'void';   # suppress 'Useless use of ... in void context'

use Oktest;


## 'target' represents topic of test (such as ClassName or method_name())
target "ClassName", sub {

    ## 'target' can be nestable
    target "method_name()", sub {

        ## 'spec' describes details of test
        spec "1 + 1 should be equal to 2.", sub {
            ## 'OK()' describes assertion.
            OK (1+1) == 2;
        };

        ## a target can contain multiple specs.
        spec "'x' repeats string.", sub {
            ## a spec can contain multiple assertions.
            OK ('a' x 3) eq 'aaa';
            OK ('a' x 3)->matches(qr/^a+$/);
        };

        ## 'case_when' represents test context
        case_when "value is an array...", sub {
            my $val = ["SOS"];
            spec "contains name", sub { OK ($val->[0]) eq "SOS" };
        };
        case_when "value is a hash...", sub {
            my $val = {name=>"SOS"};
            spec "contains name", sub { OK ($val->{name}) eq "SOS" };
        };

    };

};


Oktest::main() if $0 eq __FILE__;
1;

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

use strict;
use warnings;
no warnings 'void';   # suppress 'Useless use of ... in void context'
#no warnings 'redefine';


##
## class definition
##
package Hello;

sub new {
    my ($class, $name) = @_;
    my $this = {
        name => $name || 'guest',
    };
    return bless($this, $class);
}

sub say {
    my ($this) = @_;
    return "Hello $this->{name}!";
}


##
## test code
##
package main;
use Oktest;

topic "Hello", sub {

    topic "new()", sub {

        spec "takes user name.", sub {
            my $obj = Hello->new("Haruhi");
            OK ($obj->{name}) eq "Haruhi";
        };

        spec "uses 'guest' as default name when no user name.", sub {
            my $obj = Hello->new();
            OK ($obj->{name}) eq "guest";
        }

    };

    topic "say()", sub {

        spec "returns greeting message.", sub {
            my $obj = Hello->new("Sasaki");
            OK ($obj->say()) eq "Hello Sasaki!";
        };

    };

};


Oktest::main() if $0 eq __FILE__;
1;

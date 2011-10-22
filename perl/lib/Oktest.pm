###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

use strict;
use warnings;
use Data::Dumper;



package Oktest;
use base 'Exporter';
our @EXPORT    = qw(OK pre_cond target case_when spec before after before_all after_all at_end skip_when TODO);
our @EXPORT_OK = qw(run main with);
our $VERSION   = ('$Release: 0.0.0 $' =~ /\d+(\.\d+)*/ && $&);
our @__assertion_objects = ();
our @__at_end_blocks  = ();

sub OK {
    my ($actual) = shift;
    my ($pkgname, $filepath, $linenum) = caller();
    my $location = [$filepath, $linenum, $pkgname];
    my $ao = Oktest::AssertionObject->new($actual, $location);
    push(@__assertion_objects, $ao);
    return $ao;
}

*pre_cond = *OK;    ## alias of OK(), representing pre-condition

sub target {
    my ($target_name, $block) = @_;
    my $to = Oktest::TargetObject->new($target_name);
    return __yield_block($to, $block);
}

sub case_when {
    my ($description, $block) = @_;
    my $co = Oktest::CaseObject->new('When ' . $description, $block);
    return __yield_block($co, $block);
};

sub __yield_block {
    my ($to, $block) = @_;
    my $parent = $Oktest::TargetObject::__current;
    if ($parent) {
        $parent->_add_target($to);
    }
    else {
        push(@Oktest::TargetObject::__tops, $to);
    }
    $Oktest::TargetObject::__current = $to;
    $block->($to);
    $Oktest::TargetObject::__current = $parent;
    return $to;
}

sub spec {
    my ($spec_desc, $block) = @_;
    $block ||= sub { TODO("not implemented yet.") };
    my $so = Oktest::SpecObject->new($spec_desc, $block);
    my $to = $Oktest::TargetObject::__current;
    $to->_add_spec($so) if $to;
    return $so;
}

sub _set_fixture {
    my ($name, $block) = @_;
    my $to = $Oktest::TargetObject::__current
        or die "$name() should be called in target block.";
    $to->$name($block);
}

sub before(&) {
    _set_fixture('before', @_);
}

sub after(&) {
    _set_fixture('after', @_);
}

sub before_all(&) {
    _set_fixture('before_all', @_);
}

sub after_all(&) {
    _set_fixture('after_all', @_);
}

sub at_end(&) {
    my ($block) = @_;
    ## todo: check whether at_end() is called in spec block.
    push(@Oktest::__at_end_blocks, $block);
}

sub __at_end_of_spec {
    for my $block (@Oktest::__at_end_blocks) {
        $block->();
    }
}

sub skip_when {
    my ($condition, $reason) = @_;
    if ($condition) {
        die "[Skipped] " . $reason . "\n";
    }
}

sub TODO {
    my ($description) = @_;
    die "[TODO] " . $description . "\n";
}

our %_default_opts = (
    reporter => undef,
    style    => 'tap',
    spec     => undef,
    target   => undef,
    report_skipped => 0==1,
    report_todo    => 0==1,
);

sub run {
    my %opts = @_;
    %opts = (%_default_opts, %opts);
    my $reporter = $opts{reporter} || Oktest::Reporter::create_instance($opts{style});
    my $runner = $Oktest::Runner::RUNNER->new();
    $runner->{reporter}      = $reporter;
    $runner->{filter_spec}   = $opts{spec};
    $runner->{filter_target} = $opts{target};
    $reporter->{report_skipped} ||= $opts{report_skipped};
    $reporter->{report_todo}    ||= $opts{report_todo};
    my @targets = @Oktest::TargetObject::__tops;
    $runner->run_all(@targets);
}

sub main {
    Oktest::MainApp->new(@_)->execute();
}

sub with(&) {
    my ($block) = @_;
    return $block;
}

sub __clear {
    @__assertion_objects = ();
    Oktest::TargetObject::__clear();
}

sub __at_exit {
    for my $ao (@__assertion_objects) {
        unless ($ao->{_done}) {
            my ($filepath, $linenum, $pkgname) = @{$ao->{location}};
            warn "*** OK() called but not tested at '$filepath' line $linenum.\n";
        }
    }
}

END {
    __at_exit();
}

sub __sweep {
    @__assertion_objects = grep { ! $_->{_done} } @__assertion_objects;
}



package Oktest::TargetObject;

our $__current = undef;
our @__tops = ();

our $EXEC   = 1;
our $IGNORE = 0;
our $ENTER  = -1;

sub __last {
    return $__tops[$#__tops];
}

sub __clear {
    $Oktest::TargetObject::__current = undef;
    @Oktest::TargetObject::__tops = ();
}

sub new {
    my ($class, $name, $parent) = @_;
    my $this = {
        name     => $name,
        parent   => $parent,
        targets  => [],
        specs    => [],
        status   => $EXEC,
    };
    return bless($this, $class);
}

sub accept {
    my ($this, $runner, $depth) = @_;
    return $runner->run_target($this, $depth);
}

sub _add_target {
    my ($this, $to) = @_;
    die unless $to->isa('Oktest::TargetObject');
    push(@{$this->{targets}}, $to);
    $to->{parent} = $this;
    return $this;
}

sub _add_spec {
    my ($this, $so) = @_;
    die unless $so->isa('Oktest::SpecObject');
    push(@{$this->{specs}}, $so);
    $so->{parent} = $this;
    return $this;
}

sub _count_specs {
    my ($this) = @_;
    my $n = 0;
    for my $to (@{$this->{targets}}) {
        $n += $to->_count_specs();
    }
    if ($this->{status} == $EXEC) {
        for my $so (@{$this->{specs}}) {
            $n++ if $so->{status} == $EXEC;
        }
    }
    return $n;
}

sub before {
    my ($this, $block) = @_;
    $this->{_before} = $block;
}

sub after {
    my ($this, $block) = @_;
    $this->{_after} = $block;
}

sub before_all {
    my ($this, $block) = @_;
    $this->{_before_all} = $block;
}

sub after_all {
    my ($this, $block) = @_;
    $this->{_after_all} = $block;
}

$INC{'Oktest/TargetObject'} = __FILE__;



package Oktest::CaseObject;
our @ISA = ('Oktest::TargetObject');

sub new {
    my ($class, $desc) = @_;
    my $this = $class->SUPER::new($desc);
    return $this;
}



package Oktest::SpecObject;

our $EXEC = $Oktest::TargetObject::EXEC;

sub new {
    my ($class, $desc, $block) = @_;
    my $this = {
        desc   => $desc,
        parent => undef,
        block  => $block,
        status => $EXEC,
    };
    return bless($this, $class);
}

sub accept {
    my ($this, $runner, $depth) = @_;
    return $runner->run_spec($this, $depth);
}



package Oktest::AssertionObject;
use Text::Diff;
use Scalar::Util qw(refaddr);
use Data::Dumper;

sub new {
    my ($class, $actual, $location) = @_;
    my $this = {
        actual   => $actual,
        location => $location,
        _done    => 0==1,
    };
    return bless($this, $class);
}

sub _done {
    my ($this) = @_;
    $this->{_done} = 1==1;
    return $this;
}

sub _repr {
    my ($arg) = @_;
    local $Data::Dumper::Terse = 1;
    return Dumper($arg);
}

sub _validate_expected {
    my ($this, $expected, $op) = @_;
    my $msg;
    if (Oktest::Util::is_string($expected)) {
        $msg =
            "[ERROR] right hand of '" . $op . "' should not be a string.\n" .
            "  \$actual:   " . _repr($this->{actual}) .
            "  \$expected: " . _repr($expected);
    }
    return $msg;
}

sub _failed_message {
    my ($this, $actual, $op, $expected) = @_;
    my $msg =
        "[Failed] \$actual " . $op . " \$expected : failed.\n" .
        "  \$actual:   " . _repr($actual) .
        "  \$expected: " . _repr($expected);
    return $msg;
}

sub _die {
    my ($this, $errmsg) = @_;
    my $stacktrace = _stacktrace(2, 20);
    $errmsg .= "\n" unless $errmsg =~ /\n$/;
    die $errmsg . $stacktrace;
}

sub _stacktrace {
    my ($depth) = @_;
    my $max = 20;
    my $i = $depth;
    for (; $i < $max; $i++) {
        my ($pkgname, $filename, $linenum, @rest) = caller($i);
        last if $filename ne __FILE__;
    }
    my $str = "";
    for (; $i < $max; $i++) {
        my ($pkgname, $filename, $linenum, @rest) = caller($i);
        last if ! $filename || $filename eq __FILE__;
        my $line = Oktest::Util::read_line_from($filename, $linenum);
        $str .=
            "File '$filename', line $linenum:\n" .
            "    " . Oktest::Util::strip($line) . "\n";
    }
    return $str;
}

sub _assert(&@) {
    my ($closure, $op, $validate, $this, $expected) = @_;
    $this->_done();
    if ($validate) {
        my $msg = $this->_validate_expected($expected, $op);
        die $msg if $msg;
    }
    my $actual = $this->{actual};
    return $this if $closure->($actual, $expected);
    my $msg = $this->_failed_message($actual, $op, $expected);
    $this->_die($msg);
}

use overload
    '==' => \&_num_eq,
    '!=' => \&_num_ne,
    '>'  => \&_num_gt,
    '>=' => \&_num_ge,
    '<'  => \&_num_lt,
    '<=' => \&_num_le,
    'eq' => \&_str_eq,
    'ne' => \&_str_ne,
    'lt' => \&_str_lt,
    'le' => \&_str_le,
    'gt' => \&_str_gt,
    'ge' => \&_str_ge;

sub _num_eq {
    #my ($this, $expected) = @_;
    return _assert { $_[0] == $_[1] } '==', 1, @_;
}

sub _num_ne {
    #my ($this, $expected) = @_;
    return _assert { $_[0] != $_[1] } '!=', 1, @_;
}

sub _num_gt {
    return _assert { $_[0] > $_[1] } '>', 1, @_;
}

sub _num_ge {
    return _assert { $_[0] >= $_[1] } '>=', 1, @_;
}

sub _num_lt {
    return _assert { $_[0] < $_[1] } '<', 1, @_;
}

sub _num_le {
    return _assert { $_[0] <= $_[1] } '<=', 1, @_;
}

sub _str_eq {
    #return _assert { $_[0] eq $_[1] } 'eq', 0, @_;
    my ($this, $expected) = @_;
    $this->_done();
    my $actual = $this->{actual};
    return $this if $actual eq $expected;
    if ($actual !~ /\n/ && $expected !~ /\n/) {
        my $msg =
            "[Failed] \$actual eq \$expected : failed.\n" .
            "  \$actual:   " . _repr($actual) .
            "  \$expected: " . _repr($expected);
        $this->_die($msg);
    }
    else {
        #if ($actual !~ /\n$/ || $expected !~ /\n$/) {
            my $append = "\\ No newline at end\n";
            $actual   .= $append if $actual   !~ /\n$/;
            $expected .= $append if $expected !~ /\n$/;
        #}
        my $diff = Text::Diff::diff(\$expected, \$actual, {STYLE=>'Unified'});
        my $msg =
            "[Failed] \$actual eq \$expected : failed.\n" .
            "--- \$expected\n" .
            "+++ \$actual\n" .
            $diff;
        $this->_die($msg);
    }
}

sub _str_ne {
    return _assert { $_[0] ne $_[1] } 'ne', 0, @_;
}

sub _str_gt {
    return _assert { $_[0] gt $_[1] } 'gt', 0, @_;
}

sub _str_ge {
    return _assert { $_[0] ge $_[1] } 'ge', 0, @_;
}

sub _str_lt {
    return _assert { $_[0] lt $_[1] } 'lt', 0, @_;
}

sub _str_le {
    return _assert { $_[0] le $_[1] } 'le', 0, @_;
}

sub in_delta {
    my ($this, $expected, $delta) = @_;
    $this->_done();
    my $actual = $this->{actual};
    my ($min, $max) = ($expected - $delta, $expected + $delta);
    unless ($min <= $actual) {
        my $msg =
            '[Failed] $expected - $delta <= $actual : failed.\n' .
            '  $expected - $delta: ' . $min . '\n' .
            '  $actual:            ' . $actual . '\n';
        $msg =~ s/\\n/\n/g;
        $this->_die($msg);
    }
    unless ($actual <= $max) {
        my $msg =
            '[Failed] $actual <= $expected + $delta : failed.\n' .
            '  $actual:            ' . $actual . '\n' .
            '  $expected + $delta: ' . $max . '\n';
        $msg =~ s/\\n/\n/g;
        $this->_die($msg);
    }
    return $this;
}

sub matches {
    my ($this, $expected) = @_;
    $this->_done();
    defined($expected)
        or $this->_die("[ERROR] OK(): use matches(qr/pattern/) instead of matches(/pattern/).");
    return _assert { $_[0] =~ $_[1] } '=~', 0, @_;
}

sub not_match {
    my ($this, $expected) = @_;
    $this->_done();
    defined($expected)
        or $this->_die("[ERROR] OK(): use not_match(qr/pattern/) instead of not_match(/pattern/).");
    return _assert { $_[0] !~ $_[1] } '!~', 0, @_;
}

sub is_a {
    my ($this, $expected) = @_;
    $this->_done();
    #return _assert { $_[0]->isa($_[1]) } ' instanceof ', 0, @_;
    my $actual = $this->{actual};
    unless ($actual->isa($expected)) {
        #my $msg = $this->_failed_message($actual, $op, $expected);
        my $msg = "[Failed] \$actual->isa(\$expected) : failed.\n"
            . "  \$actual:   " . _repr($actual)
            . "  \$expected: " . _repr($expected);
        $this->_die($msg);
    }
    return $this;
}

sub not_a {
    my ($this, $expected) = @_;
    $this->_done();
    #return _assert { ! $_[0]->isa($_[1]) } ' instanceof ', 0, @_;
    my $actual = $this->{actual};
    if ($actual->isa($expected)) {
        #my $msg = $this->_failed_message($actual, $op, $expected);
        my $msg = "[Failed] ! \$actual->isa(\$expected) : failed.\n"
            . "  \$actual:   " . _repr($actual)
            . "  \$expected: " . _repr($expected);
        $this->_die($msg);
    }
    return $this;
}

sub dies {
    my ($this, $errmsg) = @_;
    $this->_done();
    #return _assert { $_[0]->isa($_[1]) } ' instanceof ', 0, @_;
    $errmsg = '' unless defined($errmsg);
    my $actual = $this->{actual};
    undef $@;
    eval { $actual->() };
    unless ($@) {
        my $msg =
            "[Failed] exception expected but nothing thrown.\n" .
            "  \$expected: " . _repr($errmsg);
        $this->_die($msg);
    }
    my $ok = 1==1;
    my $op;
    if (! $errmsg) {
        # pass
    }
    elsif (ref($errmsg) eq 'Regexp') {
        $ok = $@ =~ $errmsg;
        $op = '=~';
    }
    else {
        $ok = $@ eq $errmsg;
        if (! $ok) {
            my $s = substr($@, 0, length($errmsg));
            my $rest = substr($@, length($errmsg));
            $ok = $s eq $errmsg && $rest =~ / at .*/;
        };
        $op = 'eq';
    }
    unless ($ok) {
        my $msg =
            '[Failed] $@ ' . $op . ' $expected : failed.' . "\n" .
            '  $@:        ' . _repr($@) .
            '  $expected: ' . _repr($errmsg);
        $this->_die($msg);
    }
    return $this;
}

sub not_die {
    my ($this) = @_;
    $this->_done();
    my $actual = $this->{actual};
    undef $@;
    eval { $actual->() };
    if ($@) {
        my $msg =
            "[Failed] no exception expected but thrown.\n" .
            "  \$\@: " . _repr($@);
        undef $@;
        $this->_die($msg);
    }
    return $this;
}

sub warns {
    my ($this, $expected) = @_;
    $this->_done();
    my $actual = $this->{actual};
    #my $warning = &Oktest::Util::capture_stderr(sub { $actual->() });
    my $warning;
    local $SIG{__WARN__} = sub { $warning = shift };
    $actual->();
    unless ($warning) {
        my $msg =
            "[Failed] warning expected : failed (nothing printed).\n" .
            "  \$expected: " . _repr($expected);
        $this->_die($msg);
    }
    my $new_msg = sub {
        my ($op) = @_;
        return
            "[Failed] \$warning $op \$expected : failed.\n" .
            "  \$warning:  " . _repr($warning) .
            "  \$expected: " . _repr($expected);
    };
    if (ref($expected) eq 'Regexp') {
        #$this->_die($new_msg->('=~')) unless $warning =~ $expected;
        unless ($warning =~ $expected) {
            my $msg = $new_msg->('=~');
            $this->_die($msg);
        }
    }
    else {
        #$this->_die($new_msg->('eq')) unless $warning eq $expected;
        unless ($warning eq $expected) {
            my $msg = $new_msg->('eq');
            $this->_die($msg);
        }
    }
    return $this;
}

sub not_warn {
    my ($this) = @_;
    $this->_done();
    my $actual = $this->{actual};
    my $warning = &Oktest::Util::capture_stderr(sub { $actual->() });
    unless (! $warning) {
        my $msg =
            "[Failed] no warning expected : failed.\n" .
            "  \$warning: " . _repr($warning);
        $this->_die($msg);
    }
    return $this;
}

sub is_string {
    my ($this) = @_;
    return $this->_is_type('string', Oktest::Util::is_string($this->{actual}));
}

sub is_number {
    my ($this) = @_;
    return $this->_is_type('number', Oktest::Util::is_number($this->{actual}));
}

sub is_integer {
    my ($this) = @_;
    return $this->_is_type('integer', Oktest::Util::is_integer($this->{actual}));
}

sub is_float {
    my ($this) = @_;
    return $this->_is_type('float', Oktest::Util::is_float($this->{actual}));
}

sub _is_type {
    my ($this, $type, $bool) = @_;
    $this->_done();
    my $actual = $this->{actual};
    if (! $bool) {
        my $msg =
            "[Failed] \$actual : $type expected, but not.\n" .
            "  \$actual:   " . _repr($actual);
        $this->_die($msg);
    }
    return $this;
}

sub is_ref {
    my ($this, $expected) = @_;
    return $this->_is_reference($expected, 'eq', 1==1);
}

sub not_ref {
    my ($this, $expected) = @_;
    return $this->_is_reference($expected, 'ne', 0==1);
}

sub _is_reference {
    my ($this, $expected, $op, $bool) = @_;
    $this->_done();
    my $actual = $this->{actual};
    unless ((ref($actual) eq $expected) == $bool) {
        my $msg =
            "[Failed] ref(\$actual) $op '$expected' : failed.\n" .
            "  ref(\$actual): '" . ref($actual) . "'\n" .
            "  \$actual:    " . _repr($actual);
        $this->_die($msg);
    }
    return $this;
}

#sub is_arrayref {
#    my ($this) = @_;
#    return $this->_is_reftype('ARRAY');
#}
#
#sub is_hashref {
#    my ($this) = @_;
#    return $this->_is_reftype('HASH');
#}
#
#sub is_coderef {
#    my ($this) = @_;
#    return $this->_is_reftype('CODE');
#}
#
#sub _is_reftype {
#    my ($this, $reftype) = @_;
#    $this->_done();
#    my $actual = $this->{actual};
#    if (ref($actual) ne $reftype) {
#        my $msg =
#            "[Failed] ref(\$actual) : $reftype expected, but got " . ref($actual) . ".\n" .
#            "  \$actual:   " . _repr($actual);
#        $this->_die($msg);
#    }
#    return $this;
#}

sub length {
    my ($this, $expected) = @_;
    $this->_done();
    my $actual = $this->{actual};
    if (Oktest::Util::is_string($actual)) {
        unless (CORE::length($actual) == $expected) {
            my $msg =
                "[Failed] length(\$actual) == \$expected : failed.\n" .
                "  \$actual:   " . _repr($actual) .
                "  \$expected: " . _repr($expected);
            $this->_die($msg);
        }
    }
    elsif (ref($actual)) {
        my $n = $#{$actual} + 1;
        unless ($n == $expected) {
            my $msg =
                "[Failed] \$\#{$actual} + 1 == \$expected : failed.\n" .
                "  \$actual+1: $n\n" .
                "  \$expected: $expected\n";
            $this->_die($msg);
        }
    }
    else {
        my $msg =
            "[ERROR] \$actual : string or array expected.\n" .
            "  \$actual:   " . _repr($actual);
        $this->_die($msg);
    }
    return $this;
}

sub has {
    my ($this, $name, $expected) = @_;
    $this->_done();
    my $actual = $this->{actual};
    unless (defined($actual->{$name})) {
        my $msg =
            "[Failed] defined(\$actual->{$name}) : failed.\n" .
            '  $actual:   ' . _repr($actual);
        $this->_die($msg);
    }
    if ($#_ == 2) {  # when expected value is passed
        unless ($actual->{$name} eq $expected) {
            my $msg =
                "[Failed] \$actual->{$name} eq \$expected : failed.\n" .
                "  \$actual->{$name}: " . _repr($actual->{$name}) .
                "  \$expected:      " . _repr($expected);
            $this->_die($msg);
        }
    }
    return $this;
}

sub can_ {
    my ($this, $method) = @_;
    return $this->_can_or_not($method, 1==1, 'can_', '');
}

sub can_not {
    my ($this, $method) = @_;
    return $this->_can_or_not($method, 0==1, 'can_not', '! ');
}

sub _can_or_not {
    my ($this, $method, $bool, $caller, $op) = @_;
    $this->_done();
    my $actual = $this->{actual};
    unless ($method) {
        my $msg =
            "[ERROR] OK()->$caller(): method name required.\n";
        $this->_die($msg);
    }
    unless (!! $actual->can($method) == $bool) {
        my $msg =
            "[Failed] $op\$actual->can('$method') : failed.\n" .
            "  \$actual:   " . _repr($actual);
        $this->_die($msg);
    }
    return $this;
}

sub same {
    my ($this, $expected) = @_;
    return $this->_same_or_not($expected, '==', 1==1);
}

sub not_same {
    my ($this, $expected) = @_;
    return $this->_same_or_not($expected, '!=', 1!=1);
}

sub _same_or_not {
    my ($this, $expected, $op, $bool) = @_;
    $this->_done();
    my $actual = $this->{actual};
    unless ((refaddr($actual) == refaddr($expected)) == $bool) {
        my $msg =
            '[Failed] refaddr($actual) ' . $op . ' refaddr($expected) : failed.' . "\n" .
            '  $actual:   ' . _repr($actual) .
            '  $expected: ' . _repr($expected);
        $this->_die($msg);
    }
    return $this;
}

sub is_true {
    my ($this) = @_;
    $this->_done();
    unless ($this->{actual}) {
        my $msg =
            "[Failed] OK(\$expression) : assertion failed.\n" .
            "  \$expression:  " . _repr($this->{actual});
        $this->_die($msg);
    }
    return $this;
}

sub is_false {
    my ($this) = @_;
    $this->_done();
    unless (! $this->{actual}) {
        my $msg =
            "[Failed] OK(! \$expression) : assertion failed.\n" .
            "  \$expression:  " . _repr($this->{actual});
        $this->_die($msg);
    }
    return $this;
}

sub equals {     ## !! EXPERIMENTAL !!
    my ($this, $expected) = @_;
    $this->_done();
    my $actual = $this->{actual};
    #
    unless (ref($actual) eq ref($expected)) {
        my $msg =
            '[Failed] ref($actual) eq ref($expected) : failed.' . "\n" .
            '  ref($actual):   ' . _repr(ref($actual)) .
            '  ref($expected): ' . _repr(ref($expected)) .
            '  $actual:   ' . _repr($actual) .
            '  $expected: ' . _repr($expected);
        $this->_die($msg);
    }
    #
    my $actual_dump   = Dumper($actual);    # _repr($actual);
    my $expected_dump = Dumper($expected);  # _repr($expected);
    unless ($actual_dump eq $expected_dump) {
        my $diff = Text::Diff::diff(\$expected_dump, \$actual_dump, {STYLE=>'Unified'});
        my $msg =
            "[Failed] \$actual equals to \$expected : failed.\n" .
            "--- Dumper(\$expected)\n" .
            "+++ Dumper(\$actual)\n" .
            $diff;
        $this->_die($msg);
    };
    #
    return $this;
}

sub not_equal {     ## !! EXPERIMENTAL !!
    my ($this, $expected) = @_;
    $this->_done();
    my $actual = $this->{actual};
    if (Dumper($actual) eq Dumper($expected)) {
        my $msg =
            "[Failed] \$actual and \$expected are not equal: failed.\n" .
            "  \$actual and \$expected: " . _repr($actual);
        $this->_die($msg);
    };
    return $this;
}

sub all {
    my ($this, $block) = @_;
    $this->_done();
    my $actual = $this->{actual};
    my $index = &Oktest::Util::index_denied($block, @$actual);
    my $found = $index >= 0;
    if ($found) {
        my $msg =
            "[Failed] OK(\$actual)->all(sub{...}) : failed at index=$index.\n" .
            "  \$actual->[$index]: " . _repr($actual->[$index]);
        $this->_die($msg);
    }
    return $this;
}

sub any {
    my ($this, $block) = @_;
    $this->_done();
    my $actual = $this->{actual};
    my $found = &Oktest::Util::index($block, @$actual) >= 0;
    unless ($found) {
        my $msg =
            "[Failed] OK(\$actual)->any(sub{...}) : failed.\n" .
            "  \$actual: " . _repr($actual);
        $this->_die($msg);
    }
    return $this;
}

sub is_file {
    my ($this) = @_;
    return $this->_is_file_or_dir('file', '-f', -f $this->{actual});
}

sub is_dir {
    my ($this) = @_;
    return $this->_is_file_or_dir('directory', '-d', -d $this->{actual});
}

sub _is_file_or_dir {
    my ($this, $kind, $op, $bool) = @_;
    $this->_done();
    my $actual = $this->{actual};
    unless ($bool) {
        my $msg = ! -e $actual
            ? "[Failed] $op \$actual : failed ($kind not exist).\n"
            : "[Failed] $op \$actual : failed (not a $kind).\n";
        $msg .= "  \$actual:   " . _repr($actual);
        $this->_die($msg);
    }
    return $this;
}

sub not_file {
    my ($this) = @_;
    return $this->_not_file_or_dir('file', '-f', -f $this->{actual});
}

sub not_dir {
    my ($this) = @_;
    return $this->_not_file_or_dir('directory', '-d', -d $this->{actual});
}

sub _not_file_or_dir {
    my ($this, $kind, $op, $bool) = @_;
    $this->_done();
    my $actual = $this->{actual};
    unless (! $bool) {
        my $msg =
            "[Failed] ! $op \$actual : failed ($kind exists).\n" .
            "  \$actual:   " . _repr($actual);
        $this->_die($msg);
    }
    return $this;
}

sub exist {
    my ($this) = @_;
    $this->_done();
    my $actual = $this->{actual};
    unless (-e $actual) {
        my $msg =
            "[Failed] -e \$actual : failed (file or directory not found).\n" .
            "  \$actual:   " . _repr($actual);
        $this->_die($msg);
    }
    return $this;
}

sub not_exist {
    my ($this) = @_;
    $this->_done();
    my $actual = $this->{actual};
    unless (! -e $actual) {
        my $msg =
            "[Failed] ! -e \$actual : failed (file or directory exists).\n" .
            "  \$actual:   " . _repr($actual);
        $this->_die($msg);
    }
    return $this;
}



package Oktest::Runner;

our $RUNNER = 'Oktest::Runner::DefaultRunner';



package Oktest::Runner::Base;

sub new {
    my ($class) = @_;
    my $this = {
        'reporter' => undef,
    };
    return bless($this, $class);
}

sub reporter {
    my ($this) = @_;
    $this->{reporter} ||= $Oktest::Reporter::REPORTER->new();
    return $this->{reporter};
}

sub run_all {
    my ($this, @targets) = @_;
}

sub run_target {
    my ($this, $to, $depth) = @_;
}

sub run_spec {
    my ($this, $so, $depth) = @_;
}

sub detect_status {
    my ($this, $errmsg) = @_;
    return '.' unless $errmsg;
    return 'f' if $errmsg =~ /^\[Failed\]/;
    return 'E' if $errmsg =~ /^\[ERROR\]/;
    return 's' if $errmsg =~ /^\[Skipped\]/;
    return 't' if $errmsg =~ /^\[TODO\]/;
    #return '?';
    return 'E';
}



package Oktest::Runner::DefaultRunner;
our @ISA = ('Oktest::Runner::Base');

our $EXEC   = $Oktest::TargetObject::EXEC;
our $IGNORE = $Oktest::TargetObject::IGNORE;
our $ENTER  = $Oktest::TargetObject::ENTER;

sub new {
    my ($class) = @_;
    my $this = $class->SUPER::new();
    $this->{depth} = 0;
    return $this;
}

sub run_all {
    my ($this, @targets) = @_;
    $this->_filter(@targets);
    $this->reporter->enter_all(@targets);
    for my $to (@targets) {
        #$this->run_target($to, 0);
        $to->accept($this, 0);
    }
    $this->reporter->exit_all(@targets);
}

sub run_target {
    my ($this, $to, $depth) = @_;        ## $to is a TargetObject
    return if $to->{status} == $IGNORE;
    $this->reporter->enter_target($to, $depth);
    $to->{_before_all}->() if $to->{_before_all};
    #
    if ($to->{status} == $EXEC) {
        for my $so (@{$to->{specs}}) {
            #$this->run_spec($so, $depth + 1) if $so->{status} == $EXEC;
            $so->accept($this, $depth + 1) if $so->{status} == $EXEC;
        }
    }
    #
    for my $child (@{$to->{targets}}) {
        #$this->run_target($child, $depth + 1);
        $child->accept($this, $depth + 1);
    }
    #
    $to->{_after_all}->() if $to->{_after_all};
    $this->reporter->exit_target($to, $depth);
}

sub run_spec {
    my ($this, $so, $depth) = @_;        ## $so is a SpecObject
    $this->reporter->enter_spec($so, $depth);
    my $context = {
        spec   => $so->{desc},
        target => $so->{parent}->{name},
    };
    my $errmsg;
    undef $@;
    eval { $this->_run_befores($so, $context) };
    if ($@) {
        $errmsg = $@;
        undef $@;
    }
    else {
        eval { $so->{block}->($context) };
        $errmsg = $@;
        undef $@;
        eval { Oktest::__at_end_of_spec() };
        $errmsg .= $@ if $@;
        undef $@;
        eval { $this->_run_afters($so, $context) };
        $errmsg .= $@ if $@;
        undef $@;
    }
    my $status = $this->detect_status($errmsg);
    $this->reporter->exit_spec($so, $depth, $status, $errmsg);
    Oktest::__sweep();
}

sub _run_befores {
    my ($this, $so, $context) = @_;
    my $to = $so->{parent};
    ## parent-first
    my @arr = ();
    while ($to) {
        push(@arr, $to);
        $to = $to->{parent};
    }
    for $to (reverse(@arr)) {
        $to->{_before}->($context) if $to->{_before};
    }
}

sub _run_afters {
    my ($this, $so, $context) = @_;
    my $to = $so->{parent};
    ## child-first
    while ($to) {
        $to->{_after}->($context) if $to->{_after};
        $to = $to->{parent};
    }
}

sub _filter {
    my ($this, @targets) = @_;
    #
    my $pat1 = $this->{filter_spec};
    _filter_specs($pat1, @targets) if $pat1;
    #
    my $pat2 = $this->{filter_target};
    _filter_targets($pat2, @targets) if $pat2;
    #
    if ($pat1 || $pat2) {
        _change_status_recursively($_) for @targets;
    }
}

sub _filter_specs {
    my ($pat, @targets) = @_;
    for my $to (@targets) {
        my $found = 0==1;
        for my $so (@{$to->{specs}}) {
            if ($so->{desc} =~ $pat) {
                $found = 1==1;
            }
            else {
                $so->{status} = $IGNORE;
            }
        }
        $to->{status} = $IGNORE unless $found;
        _filter_specs($pat, @{$to->{targets}});
    }
}

sub _filter_targets {
    my ($pat, @targets) = @_;
    for my $to (@targets) {
        unless ($to->{name} =~ $pat) {
            $to->{status} = $IGNORE;
            _filter_targets($pat, @{$to->{targets}});
        }
    }
}

sub _change_status_recursively {
    my ($to) = @_;
    my $flag = 0==1;
    for my $child (@{$to->{targets}}) {
        my $ret = _change_status_recursively($child);
        $flag = 1==1 if $ret;
    }
    if ($to->{status} != $IGNORE) {
        return 1==1;   # not ignored
    }
    elsif ($flag) {
        $to->{status} = $ENTER;
        return 1==1;   # not ignored, because non-ignored target exists in targets
    }
    else {
        return 0==1;   # ignored
    }
}



package Oktest::Reporter;

our $REPORTER = 'Oktest::Reporter::TapReporter';

our %_registered = (
    tap     => 'Oktest::Reporter::TapReporter',
    verbose => 'Oktest::Reporter::VerboseReporter',
    simple  => 'Oktest::Reporter::SimpleReporter',
    plain   => 'Oktest::Reporter::PlainReporter',
    't'     => 'Oktest::Reporter::TapReporter',
    'v'     => 'Oktest::Reporter::VerboseReporter',
    's'     => 'Oktest::Reporter::SimpleReporter',
    'p'     => 'Oktest::Reporter::PlainReporter',
);

sub create_instance {
    my ($style) = @_;
    $style ||= 'tap';    # default: 'tap' style
    my $class = $Oktest::Reporter::_registered{$style};
    return unless $class;
    return $class->new();
}



package Oktest::Reporter::Base;

our %STATUS_LABELS = (
    '.' => 'ok',
    'f' => 'Failed',
    'E' => 'ERROR',
    's' => 'Skipped',
    't' => 'TODO',
    '?' => '???',
);

sub new {
    my ($class) = @_;
    my $this = {
        count     => 0,
        counts    => {},
        separator => '-' x 70,
    };
    return bless($this, $class);
}

sub _indent {
    my ($this, $depth) = @_;
    return '  ' x $depth;
}

sub enter_all {
    my ($this, @targets) = @_;
    $this->{_started_at} = Oktest::Util::current_time();
};

sub exit_all {
    my ($this, @targets) = @_;
    my $now = Oktest::Util::current_time();
    my $elapsed = $now - $this->{_started_at};
    my $c = $this->{counts};
    my $s = sprintf("## ok:%s, failed:%s, error:%s, skipped:%s, todo:%s  (elapsed: %.3f)\n",
                    $c->{'.'}||0, $c->{'f'}||0, $c->{'E'}||0, $c->{'s'}||0, $c->{'t'}||0, $elapsed);
    print $s;
}

sub enter_target {
    my ($this, $to, $depth) = @_;
};

sub exit_target {
    my ($this, $to, $depth) = @_;
};

sub enter_spec {
    my ($this, $so, $depth) = @_;
};

sub exit_spec {
    my ($this, $so, $depth, $status, $errmsg) = @_;
    ++$this->{counts}->{$status};
    ++$this->{count};
};

sub _error_should_be_reported {
    my ($this, $status) = @_;
    return 1==1 if $status eq 's' && $this->{report_skipped};
    return 1==1 if $status eq 't' && $this->{report_todo};
    return 1==1 if $status ne 's' && $status ne 't';
    return 0==1;
}

sub _report_errmsg_list {
    my ($this, @exc_items) = @_;
    for (@exc_items) {
        my ($so, $depth, $status, $errmsg) = @$_;
        $this->_print_separator();
        $this->_report_errmsg($so, $status, $errmsg);
    }
    $this->_print_separator() if @exc_items;
}

sub _print_separator {
    my ($this) = @_;
    print '# ', $this->{separator}, "\n";
}

sub _report_errmsg {
    my ($this, $so, $status, $errmsg) = @_;
    if    ($status eq 'f') { $errmsg =~ s/^\[Failed\]/Assertion:/ }
    elsif ($status eq 'E') { }
    elsif ($status eq 's') { $errmsg =~ s/^\[Skipped\]/Reason:/ }
    elsif ($status eq 't') { $errmsg =~ s/^\[TODO\]/Description:/ }
    else                   { }
    print '# [', $STATUS_LABELS{$status}, '] * ', $this->_breadcrumb($so), "\n";
    $_ = $errmsg;
    s/^/# /mg;
    s/\n$//;
    print $_, "\n";
}

sub _breadcrumb {
    my ($this, $so) = @_;
    my @arr = $this->_path_elems($so);
    return join(' > ', @arr);
}

sub _path_elems {
    my ($this, $so) = @_;
    my @arr;
    my $x = $so->{desc};
    push(@arr, $so->{desc});
    my $to = $so->{parent};
    while ($to) {
        push(@arr, $to->{name});
        $to = $to->{parent};
    }
    return reverse(@arr);
}

sub _itemize {
    my ($this, $to) = @_;
    return $to->isa('Oktest::CaseObject') ? '- ' : '* ';
}


package Oktest::Reporter::TapReporter;
our @ISA = ('Oktest::Reporter::Base');

sub enter_all {
    my ($this, @targets) = @_;
    $this->SUPER::enter_all(@targets);
    my $n = 0;
    for my $to (@targets) {
        $n += $to->_count_specs();
    }
    print "1..$n\n";
}

sub enter_target {
    my ($this, $to, $depth) = @_;
    print '## ', $this->_indent($depth), $this->_itemize($to), $to->{name}, "\n";
};

sub exit_spec {
    my ($this, $so, $depth, $status, $errmsg) = @_;
    $this->SUPER::exit_spec($so, $depth, $status, $errmsg);
    my $n = $this->{count};
    if (! $errmsg) {
        print 'ok ', $n, ' - ', $so->{desc}, "\n";
    }
    elsif ($status eq 's') {
        my $reason = $errmsg;
        $reason =~ s/^\[Skipped\] ?//;
        chomp($reason);
        print 'ok ', $n, ' - ', $so->{desc}, ' # skip - ', $reason, "\n";
    }
    elsif ($status eq 't') {
        my $desc = $errmsg;
        $desc =~ s/^\[TODO\] ?//;
        chomp($desc);
        print 'not ok ', $n, ' - ', $so->{desc}, ' # TODO - ', $desc, "\n";
    }
    else {
        print 'not ok ', $n, ' - ', $so->{desc}, "\n";
        $this->_print_separator();
        $this->_report_errmsg($so, $status, $errmsg);
        $this->_print_separator();
    }
}



package Oktest::Reporter::VerboseReporter;
our @ISA = ('Oktest::Reporter::Base');

sub enter_all {
    my ($this, @targets) = @_;
    $this->SUPER::enter_all(@targets);
    $this->{exc_stack} = [];
}

sub enter_target {
    my ($this, $to, $depth) = @_;
    $this->SUPER::enter_target($to, $depth);
    push(@{$this->{exc_stack}}, []);
    print $this->_indent($depth), $this->_itemize($to), $to->{name}, "\n";
};

sub exit_target {
    my ($this, $to, $depth) = @_;
    $this->SUPER::exit_target($to, $depth);
    my $exc_items = pop(@{$this->{exc_stack}});
    $this->_report_errmsg_list(@$exc_items);
    undef @$exc_items;
};

sub exit_spec {
    my ($this, $so, $depth, $status, $errmsg) = @_;
    $this->SUPER::exit_spec($so, $depth, $status, $errmsg);
    my $label = $Oktest::Reporter::Base::STATUS_LABELS{$status};
    print $this->_indent($depth), "- [", $label, "] ", $so->{desc};
    if ($errmsg) {
        if ($status eq 's' || $status eq 't') {
            my $_ = $errmsg;
            s/^\[(Skipped|TODO)\] ?//;
            chomp();
            print ' ## ', $_;
        }
        if ($this->_error_should_be_reported($status)) {
            my $arr = Oktest::Util::last_item(@{$this->{exc_stack}});
            push(@$arr, [$so, $depth, $status, $errmsg]);
        }
    }
    print "\n";
}



package Oktest::Reporter::SimpleReporter;
our @ISA = ('Oktest::Reporter::Base');

sub enter_all {
    my ($this, @targets) = @_;
    $this->SUPER::enter_all(@targets);
    $this->{exc_stack} = [];
    $this->{_nl} = 1==1;
}

sub enter_target {
    my ($this, $to, $depth) = @_;
    return if $to->isa('Oktest::CaseObject');
    $this->SUPER::enter_target($to, $depth);
    push(@{$this->{exc_stack}}, []);
    print "\n" unless $this->{_nl};
    print $this->_indent($depth), $this->_itemize($to), $to->{name};
    print ": " if @{$to->{specs}};
    $this->{_nl} = 0==1;
};

sub exit_target {
    my ($this, $to, $depth) = @_;
    return if $to->isa('Oktest::CaseObject');
    $this->SUPER::exit_target($to, $depth);
    my $exc_items = pop(@{$this->{exc_stack}});
    print "\n" unless $this->{_nl};
    $this->{_nl} = 1==1;
    $this->_report_errmsg_list(@$exc_items);
    undef @$exc_items;
};

sub exit_spec {
    my ($this, $so, $depth, $status, $errmsg) = @_;
    $this->SUPER::exit_spec($so, $depth, $status, $errmsg);
    print $status;
    if ($errmsg) {
        if ($this->_error_should_be_reported($status)) {
            #my @stack = @{$this->{exc_stack}};
            #my $arr = $stack[$#stack];
            my $arr = Oktest::Util::last_item(@{$this->{exc_stack}});
            push(@$arr, [$so, $depth, $status, $errmsg]);
        }
    }
}



package Oktest::Reporter::PlainReporter;
our @ISA = ('Oktest::Reporter::Base');

sub enter_all {
    my ($this, @targets) = @_;
    $this->SUPER::enter_all(@targets);
    $this->{exc_items} = [];
}

sub exit_all {
    my ($this, @targets) = @_;
    print "\n";
    $this->_report_errmsg_list(@{$this->{exc_items}});
    $this->SUPER::exit_all(@targets);
}

sub exit_spec {
    my ($this, $so, $depth, $status, $errmsg) = @_;
    $this->SUPER::exit_spec($so, $depth, $status, $errmsg);
    print $status;
    if ($errmsg) {
        my $v = $this->_error_should_be_reported($status);
        if ($this->_error_should_be_reported($status)) {
            push(@{$this->{exc_items}}, [$so, $depth, $status, $errmsg]);
        }
    }
}



package Oktest::Util;
use base 'Exporter';
our @EXPORT_OK = qw(strip last_item length current_time
                    is_string is_number is_integer is_float
                    read_file write_file read_line_from rm_rf
                    capture capture_stdout capture_stderr);
use Time::HiRes qw(gettimeofday);

sub strip {
    my ($s) = @_;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    return $s;
}

sub last_item {
    my (@arr) = @_;
    return $arr[$#arr] if @arr;
    return;
}

sub length {
    my (@arr) = @_;
    return $#arr + 1;
}

sub current_time {
    my ($sec, $usec) = gettimeofday();
    return $sec + $usec / 1000000.0
}

sub index(&@) {
    my ($block, @arr) = @_;
    my $i = 0;
    for (@arr) {
        return $i if $block->($_);
        $i++;
    }
    return -1;
}

sub index_denied(&@) {
    my ($block, @arr) = @_;
    my $i = 0;
    for (@arr) {
        return $i unless $block->($_);
        $i++;
    }
    return -1;
}

sub is_string {
    my ($arg) = @_;
    return 0 if ref($arg);              # not scalar
    return 0 unless defined($arg);      # undef
    return 0 if ($arg ^ $arg) eq '0';   # number
    return 1;                           # string
}

sub is_number {
    my ($arg) = @_;
    return 0 if ref($arg);              # not scalar
    return 0 unless defined($arg);      # undef
    return 1 if ($arg ^ $arg) eq '0';   # number
    return 0;                           # string
}

sub is_integer {
    my ($arg) = @_;
    return is_number($arg) && $arg =~ /^-?\d+$/ ? 1 : 0;
}

sub is_float {
    my ($arg) = @_;
    return is_number($arg) && $arg =~ /^-?\d+\.\d+$/ ? 1 : 0;
}

sub read_file {
    my ($filename) = @_;
    open(my $fh, '<', $filename)
        or die "$filename: $!";
    local $/ = undef;
    my $content = <$fh>;
    close($fh)
        or die "$filename: $!";
    return $content;
}

sub write_file {
    my ($filename, $content) = @_;
    open(my $fh, '>', $filename)
        or die "$filename: $!";
    print $fh $content;
    close($fh)
        or die "$filename: $!";
}

our $__read_filename = '';
our @__read_lines = ();

sub read_line_from {
    my ($filename, $linenum) = @_;
    if ($filename ne $__read_filename) {
        open(my $fh, '<', $filename)
            or die "$filename: $!";
        @__read_lines = <$fh>;
        close($fh)
            or die "$filename: $!";
        $__read_filename = $filename;
    }
    return $__read_lines[$linenum-1];
}

sub rm_rf {
    my (@patterns) = @_;
    for my $pattern (@patterns) {
        for my $path (glob($pattern)) {
            _rm_rf($path) if -e $path;
        }
    }
}

sub _rm_rf {
    my ($path) = @_;
    if (-f $path) {
        unlink($path);
    }
    elsif (-d $path) {
        opendir(my $dh, $path);
        my @children = readdir($dh);
        closedir($dh);
        for (@children) {
            _rm_rf("$path/$_") unless $_ eq '.' || $_ eq '..';
        }
        rmdir($path);
    }
}

sub capture(&) {
    my ($block) = @_;
    my $sout = tie(local *STDOUT, 'Oktest::Util::PrintHandler');
    my $serr = tie(local *STDERR, 'Oktest::Util::PrintHandler');
    $block->();
    return ($sout->{output}, $serr->{output});
}

sub capture_stdout(&) {
    my ($block) = @_;
    my $sout = tie(local *STDOUT, 'Oktest::Util::PrintHandler');
    $block->();
    return $sout->{output};
}

sub capture_stderr(&) {
    my ($block) = @_;
    my $serr = tie(local *STDERR, 'Oktest::Util::PrintHandler');
    $block->();
    return $serr->{output};
}

$INC{'Oktest/Util.pm'} = __FILE__;



package Oktest::Util::PrintHandler;

sub TIEHANDLE {
    my ($class) = @_;
    my $this = { output => "" };
    return bless($this, $class);
}

sub PRINT {
    my ($this, @args) = @_;
    for my $arg (@args) {
        $this->{output} .= $arg;
    }
}



package Oktest::Migration::TestMore;    ## !! EXPERIMENTAL !!
use base 'Exporter';
our @EXPORT = qw(ok is isnt like unlike cmp_ok is_deeply can_ok isa_ok pass fail
                 throws_ok dies_ok lives_ok lives_and warning_like diag note explain);
#use Oktest;
no warnings 'void';

sub ok {
    my ($condition, $test_name) = @_;
    Oktest::OK ($condition)->is_true();
    return 1==1;
}

sub is {
    my ($this, $that, $test_name) = @_;
    Oktest::OK ($this) eq $that;
    return 1==1;
}

sub isnt {
    my ($this, $that, $test_name) = @_;
    Oktest::OK ($this) ne $that;
    return 1==1;
}

sub like {
    my ($this, $regexp, $test_name) = @_;
    Oktest::OK ($this)->matches($regexp);
    return 1==1;
}

sub unlike {
    my ($this, $regexp, $test_name) = @_;
    Oktest::OK ($this)->not_match($regexp);
    return 1==1;
}

sub cmp_ok {
    my ($this, $op, $that, $test_name) = @_;
    if    ($op eq '==') { Oktest::OK ($this) == $that }
    elsif ($op eq '!=') { Oktest::OK ($this) != $that }
    elsif ($op eq '>' ) { Oktest::OK ($this) >  $that }
    elsif ($op eq '>=') { Oktest::OK ($this) >= $that }
    elsif ($op eq '<' ) { Oktest::OK ($this) <  $that }
    elsif ($op eq '<=') { Oktest::OK ($this) <= $that }
    elsif ($op eq 'eq') { Oktest::OK ($this) eq $that }
    elsif ($op eq 'ne') { Oktest::OK ($this) ne $that }
    elsif ($op eq 'gt') { Oktest::OK ($this) gt $that }
    elsif ($op eq 'ge') { Oktest::OK ($this) ge $that }
    elsif ($op eq 'lt') { Oktest::OK ($this) lt $that }
    elsif ($op eq 'le') { Oktest::OK ($this) le $that }
    elsif ($op eq '=~') { Oktest::OK ($this)->matches($that) }
    elsif ($op eq '!~') { Oktest::OK ($this)->not_match($that) }
    else { die "Oktest::TestMoreMigration::cmp_ok(): operator '$op' not supported.\n" };
    return 1==1;
}

sub is_deeply {
    my ($complex_structure1, $complex_structure2, $test_name) = @_;
    Oktest::OK ($complex_structure1)->equals($complex_structure2);
    return 1==1;
}

sub can_ok {
    my ($module, @methods) = @_;
    Oktest::OK ($module)->can_($_) for (@methods);
    return 1==1;
}

sub isa_ok {
    my ($object, $class) = @_;
    Oktest::OK ($object)->is_a($class);
    return 1==1;
}

sub pass {
    my ($test_name) = @_;
    return 1==1;
}

sub fail {
    my ($test_name) = @_;
    my $msg =
        "[Failed] $test_name\n";
    Oktest::OK()->_done()->_die($msg);
    return;
}

#sub eq_array {
#    my ($this, $that) = @_;
#    Oktest::OK ($this)->equals($that);
#}
#
#sub eq_hash {
#    my ($this, $that) = @_;
#    Oktest::OK ($this)->equals($that);
#}
#
#sub eq_set {
#    my ($this, $that) = @_;
#    Oktest::OK ($this)->equals($that);
#}

sub throws_ok(&$;$) {
    my ($coderef, $pattern, $description) = @_;
    Oktest::OK ($coderef)->dies($pattern);
    return 1==1;
}

sub dies_ok(&;$) {
    my ($coderef, $description) = @_;
    Oktest::OK ($coderef)->dies();
    return 1==1;
}

sub lives_ok(&;$) {
    my ($coderef, $description) = @_;
    Oktest::OK ($coderef)->not_die();
    return 1==1;
}

sub lives_and(&;$) {
    my ($test, $description) = @_;
    Oktest::OK ($test)->not_die();
    return 1==1;
}

sub warning_like(&$;$) {
    my ($coderef, $pattern, $test_name) = @_;
    Oktest::OK ($coderef)->warns($pattern);
    return 1==1;
}

sub diag {
    my ($message) = @_;
    print STDOUT "# $message\n";
    return 0==1;
}

sub note {              ## TODO: check original spec
    my ($message) = @_;
    print STDOUT "# $message\n";
    return 0==1;
}

sub explain {           ## TODO: check original spec
    my ($value) = @_;
    use Data::Dumper;
    local $Data::Dumper::Terse = 1;
    $_ = Dumper($value);
    s/^        //mg;
    return $_;
}

$INC{'Oktest/Migration/TestMore.pm'} = __FILE__;



package Oktest::MainApp;

our $optdef_table = [
    ## name,   short,  long,      argname,    desc
    ['help',      'h', 'help',    '',         'show help'],
    ['version',   'v', 'version', '',         'show version'],
    ['style',     's', 'style',   'name',     'reporting style (tap/verbose/simple/plain, or t/v/s/p)'],
    ['spec',      '',  'spec',    'regexp',   'filter by spec description'],
    ['target',    '',  'target',  'regexp',   'filter by target name'],
    ['r_skipped', '',  'report-skipped', '',  'report detail of skipped items'],
    ['r_todo',    '',  'report-todo',    '',  'report detail of TODO items'],
    ['debug',     'D', 'debug',   '',         ''],
];

our $optdef_list = [];
our $optdef_dict = {};
for (@$optdef_table) {
    my ($name, $short, $long, $argname, $desc) = @$_;
    my $item = { name=>$name, short=>$short, long=>$long, argname=>$argname, desc=>$desc, };
    push(@$optdef_list, $item);
    $optdef_dict->{$short} = $item if $short;
    $optdef_dict->{$long}  = $item if $long;
}

sub new {
    my ($class, $argv, $command) = @_;
    my $this = {
        argv    => $argv || \@ARGV,
        command => $command || ($0 =~ /([-\w.]+)$/ and $1),
    };
    return bless($this, $class);
}

sub _help_message {
    my ($this) = @_;
    my $str =
        $this->{command} . " - a new-style testing library.\n" .
        "Usage:  oktest.pl [options] file_or_dir [file_or_dir2...]\n";
    for my $item (@$optdef_list) {
        $_ = $item;
        my ($name, $short, $long, $argname, $desc) =
            ($_->{name}, $_->{short}, $_->{long}, $_->{argname}, $_->{desc});
        next unless $desc;
        my $s = $short && $long ? "-$short, --$long" . ($argname ? "=$argname" : "")
              : $short          ? "-$short"          . ($argname ? " $argname" : "")
              : $long           ? "    --$long"      . ($argname ? "=$argname" : "")
              : undef;
        $str .= sprintf("  %-20s : %s\n", $s, $desc);
    }
    return $str;
}

sub execute {
    my ($this) = @_;
    my ($opts, $props) = $this->_parse_argv();
    my $DEBUG = $opts->{debug};
    ## help
    if ($opts->{help}) {
        print $this->_help_message();
        return;
    }
    ## version
    if ($opts->{version}) {
        print $Oktest::VERSION, "\n";
        return;
    }
    ## reporter
    my $reporter = Oktest::Reporter::create_instance($opts->{style})
        or die "-s $opts->{style}: unknown reporting style.\n";
    $reporter->{report_skipped} = 1==1 if $opts->{r_skipped};
    $reporter->{report_todo}    = 1==1 if $opts->{r_todo};
    ## options for Oktest::run()
    my $run_options = {
        reporter => $reporter,
        spec     => _str_or_rexp($opts->{spec}),
        target   => _str_or_rexp($opts->{target}),
    };
    ## load files
    my @filepaths = ();
    for my $arg (@{$this->{argv}}) {
        -e $arg
            or die "$arg: no such file or directory.\n";
        my @arr = -d $arg ? _find_files($arg, qr/\.t$/) : ($arg);
        push(@filepaths, @arr);
    }
    for my $fpath (@filepaths) {
        print "## require '$fpath'\n" if $DEBUG;
        require $fpath;
    }
    ##
    Oktest::run(%$run_options);
}

sub _str_or_rexp {
    my ($pattern) = @_;
    if ($pattern && $pattern =~ /^\/(.*)\/$/) {
        my $rexp = qr/$1/;
        return $rexp;
    }
    return $pattern;
}

sub _parse_argv {
    my ($this) = @_;
    my $argv    = $this->{argv};
    my $command = $this->{command};
    my $opts    = {};
    #my $props   = {};
    while ($argv->[0] && $argv->[0] =~ /^-/) {
        my $optstr = shift(@$argv);
        last if $optstr eq '--';
        if ($optstr =~ /^--/) {
            $optstr =~ /^--(\w[-\w]*)(=(.*))?$/
                or die "$command: $optstr: invalid option.\n";
            #$props->{$1} = $2 ? $3 : 1;
            my $has_arg = !! $2;
            my ($key, $val) = ($1, $has_arg ? $3 : 1);
            my $item = $optdef_dict->{$key}
                or die "$command: $optstr: unknown option.\n";
            my $arg_required = !! $item->{argname};
            $arg_required && ! $has_arg
                and die "$command: $optstr: argument required.\n";
            ! $arg_required && $has_arg
                and die "$command: $optstr: unexpected argument.\n";
            #$opts->{$key} = $val;
            $opts->{$item->{name}} = $val;
        }
        else {
            my @optchars = split('', substr($optstr, 1));
            while (my $ch = shift(@optchars)) {
                my $item = $optdef_dict->{$ch}
                    or die "$command: -$ch: unknown option.\n";
                my $val;
                my $argname = $item->{argname};
                if    (! $argname) { $val = 1; }
                elsif (@optchars)  { $val = join('', @optchars); @optchars = (); }
                elsif (@$argv)     { $val = shift(@$argv); }
                else { die "$command: -$ch: argument required.\n"; }
                $opts->{$item->{name}} = $val;
            }
        }
    }
    #return $opts, $props;
    return $opts;
};

sub _find_files {
    my ($arg, $rexp) = @_;
    if (-f $arg) {
        return if $rexp && $arg !~ $rexp;
        return ($arg);
    }
    elsif (-d $arg) {
        my @arr = ();
        for (glob("$arg/*")) {
            push(@arr, _find_files($_, $rexp));
        }
        return @arr;
    }
    else {
        die "_find_files(): $arg: not file nor directory.\n";
    }
}



1;


__END__


=pod

=head1 NAME

Oktest - a new-style testing library

($Release: 0.0.0 $)


=head1 SYNOPSIS

	use strict;
	use warnings;
	no warnings 'void';   # suppress 'Useless use of ... in void context'
	use Oktest;

	target "Example1", sub {

	    spec "1 + 1 should be equal to 2.", sub {
	        OK (1+1) == 2;
	    };

	    spec "'x' repeats string.", sub {
	        OK ('a' x 3) eq 'aaa';
	    };

	};

	Oktest::main() if $0 eq __FILE__;
	1;


=head1 DESCRIPTION

Oktest is a new-style testing library for Perl.

Features:

=over 1

=item *

Structured test code

=item *

Convenient assertion

=item *

Setup/Teardown fixtures

=item *

Unified diff for different texts

=item *

Filtering by string or regular expression

=back


=head2 Structured Test Code

Oktest allows you to write your test code in structured format.

=over 1

=item *

'target' represents topic or subject of test.
 Normally, it represents ClassName or method_name().

=item *

'spec' represens specification details.
 You can write description in a free text.

=item *

'case_when' represens text context.

=back

Example (01_basic.t):

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

Output:

	$ perl 01_basic.t   # or prove 01_basic.t
	1..2
	## * ClassName
	##   * method_name()
	ok 1 - 1 + 1 should be equal to 2.
	ok 2 - 'x' repeats string.
	## elapsed: 0.000

Points:

=over 1

=item *

'target()' can be nestable.
In other words, 'target()' can contain multiple specs and/ore other targets.

=item *

'spec()' can NOT be nestable.
You should not put other targes or specs in a spec block.

=item *

'case_when()' can contain specs, but cannot contain target.

=item *

Result is reported by specs, not assertions.
For example, a spec containing more than two assertions is reported
as in a line ('ok' or 'not ok').

=item *

Oktest calculates number of specs and prints accurate test plan automatically.
You don't need to update test plan manually, wow!

=back


=head2 Assertions

In Oktest, assertion is represented by 'OK()'.
You don't need to use 'ok()', 'is()', 'like()', 'isa_ok()', and so on.

Example (02_assertions.t):

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
	        OK (3.141)->in_delta(3.14, 0.01);
	    };

	    spec "string operators", sub {
	        OK ('aaa') eq 'aaa';
	        OK ('aaa') ne 'bbb';
	        OK ('aaa') lt 'bbb';
	        OK ('aaa') le 'aaa';
	        OK ('bbb') gt 'aaa';
	        OK ('aaa') ge 'aaa';
	        OK ('aaa')->length(3);
	    };

	    spec "logical expression", sub {
	        OK (1==1)->is_true();
	        OK (0==1)->is_false();
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
	        OK ($pwd )->is_dir();
	        OK ($file)->exist();
	        OK ($pwd )->exist();
	        OK ($pwd )->not_file();
	        OK ($file)->not_dir();
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

Assertion methods are chainable.

	## object is an array reference and it's length is 3.
	OK ([1,2,3])->is_arrayref()->length(3);
	## object has 'name' and 'team' attributes.
	OK ($obj)->has('name', "Haruhi")->has('team', "SOS");


=head2 Setup/Teadown

Oktest provides fixtures (= setup or teardown function).

=over 1

=item *

'before()' defines setup fixture which is called before each spec.

=item *

'after()' defines teardown fixture which is called after each spec.

=item *

'before_all()' defines setup fixture which is called before all specs.

=item *

'after_all()' defines teardown fixture which is called after all specs.

=back

Example (04_fixture.t):

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

	Oktest::main() if $0 eq __FILE__;
	1;

Output example:

	$ perl 04_fixture.t
	1..4
	## * Parent
	= [Parent] before_all
	##   * Child1
	= [Parent] before
	= [Parent] after
	ok 1 - A1
	= [Parent] before
	= [Parent] after
	ok 2 - B1
	##   * Child2
	  = [Child] before_all
	= [Parent] before
	  = [Child] before
	  = [Child] after
	= [Parent] after
	ok 3 - A3
	= [Parent] before
	  = [Child] before
	  = [Child] after
	= [Parent] after
	ok 4 - B4
	  = [Child] after_all
	= [Parent] after_all
	## elapsed: 0.000

Context data (= a hash object) is passed to 'before' and 'after' blocks.
Of course, you can use outer-closure variables instead of context data.

Example:

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


Oktest provides 'at_end()' function. It registers closure which will be
called at end of spec block.

Example:

	target "at_end() example" sub {

	    spec "create and remove files", sub {
	        # create data files
	        Oktest::Util::write_file("data1.html", "<div></div>");
	        Oktest::Util::write_file("data2.html", "<h1></h1>");
	        # register closure which will be called at end of spec
	        at_end {
	            Oktest::Util::rm_rf("data*.html");
	        };
	        #
	        # ... do test here ...
	        #
	    };

	};


=head2 Skip and TODO

Example of Skip and TODO:

	target "Misc", sub {

	    ## example of 'skip_when()'
	    spec "some cool feature is available", sub {
	        my $on_windows = $^O =~ /MSWin/;
	        skip_when $on_windows, "Windows not supported";
	        OK (`echo Haruhi | md5`) eq 'd7f76bdf93d3f59fba678b204fc4faa1';
	    };

	    ## example of 'TODO()'
	    spec "another cool feature is available", sub {
	        TODO "not implemented yet.";
	    };

	    ## Tips: if spec body is not specified then it is regarded as TODO.
	    ## For example, the following line is equivarent to above.
	    spec "another cool feature is available";

	};


=head2 Filter by Pattern

You can filter targets or specs by pattern.

	## filter targets
	$ perl t/foo.t --target='ClassName'      # by string
	$ perl t/foo.t --target=/^\w+$/          # by regular expression

	## filter specs
	$ perl t/foo.t --spec='1+1 should be 2'  # by string
	$ perl t/foo.t --spec=/^.*should.*$/     # by regular expression


=head2 Reporting Style

In default, Oktest reports results in TAP style format.
You can change it by '--style' or '-s' option.

Plain style ('-s simple' or '-ss'):

	$ perl examples/01_basic.t -ss
	..
	## elapsed: 0.000

Simple style ('-s simple' or '-ss'):

	$ perl examples/01_basic.t -ss
	* ClassName
	  * method_name(): ..
	## elapsed: 0.000

Verbose style ('-s verbose' or '-sv'):

	$ perl examples/01_basic.t -sv
	* ClassName
	  * method_name()
	    - [ok] 1 + 1 should be equal to 2.
	    - [ok] 'x' repeats string.
	## elapsed: 0.001


=head2 Command-line Interface

Oktest provides 'oktest.pl' script for command-line interface.

	## run test scripts
	$ oktest.pl t/foo.t t/bar.t

	## run test scripts under 't' directory
	$ oktest.pl t

	## change reporting style
	$ oktest.pl -s plain t       # or -sp
	$ oktest.pl -s simple t      # or -ss
	$ oktest.pl -s verbose t     # or -sv

	## filter by spec description
	$ oktest.pl --spec='1+1 should be 2' t    # string
	$ oktest.pl --spec='/^.*should.*$/' t     # regexp

	## filter by target name
	$ oktest.pl --target='ClassName' t        # string
	$ oktest.pl --target='/^\w+$/' t          # regexp


=head1 REFERENCE


=head2 package Oktest


=over 1

=item target(String name, Code block)

Represents spec target, for example ClassName, method_name(), or feature-name.

Block of 'target()' can contain other 'target()', 'case_when()', and 'spec()'.


=item case_when(String description, Code block)

Represents test context, for example "when data is not found in database..."
or "when argument is not passed...".

This is almost same as 'target()', but intended to represent test context.

Block of 'case_when()' can contain 'blocks()', 'spec()', or other 'case_when()'.


=item spec(String description[, Code block])

Represents spec details, for example "should return integer value" or
"should die with appropriate message".

Argument 'description' describes spec description, and 'block' contains
assertions to validate your code.

If body block is not passed then 'sub { TODO("not implemented yet") }' is
created instead.

Body of 'spec()' can't contain both 'targets()', 'case_when()' nor 'spec()'.

This function should be called in blocks of 'target()' or 'case_when()'.


=item skip_when(Boolean condition, String reason)

If condition is true then the rest assertions in the same spec are skipped.

This should be called in blocks of 'spec()'.


=item TODO(String description)

Represents that the test code is not wrote yet.

This should be called in blocks of 'spec()'.


=back


=head1 TODO

=over 1

=item *

[_] Tracer

=item *

[_] Fixture Injection

=item *

[_] Multi-Process Test Runner

=back


=head1 AUTHOR

makoto kuwata E<lt>kwa@kuwata-lab.comE<gt>


=head1 LICENSE

MIT License

=cut

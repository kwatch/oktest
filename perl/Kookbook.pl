
$kook_default = 'test';

recipe 'test', {
    desc   => 'do test',
    method => sub {
        sys 'prove t';
        #sys 'bin/oktest.pl examples';
    }
};

recipe 'examples', {
    desc   => 'run examples',
    method => sub {
        sys 'bin/oktest.pl -sv examples';
    }
};

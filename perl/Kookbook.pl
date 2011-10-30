use strict;
use warnings;

my $project   = prop('project', 'Oktest');
my $release   = prop('release', '0.0102');
my $copyright = 'copyright(c) 2010-2011 kuwata-lab.com all rights reserved';
my $license   = 'MIT License';

$kook_default = 'test';

my @perl_bin_paths = (
    '/opt/lang/perl/5.8.9/bin',
    '/opt/lang/perl/5.10.1/bin',
    '/opt/lang/perl/5.12.4/bin',
    '/opt/lang/perl/5.14.2/bin',
);

recipe 'test', {
    desc   => 'do test',
    spices => ["-a: test with Perl 5.8, 5.10, 5.12, and 5.14"],
    method => sub {
        my ($c, $opts) = @_;
        if ($opts->{a}) {
            for my $binpath (@perl_bin_paths) {
                my $ver = ($binpath =~ /5(?:\.\d+)+/ && $&);
                print "#---- Perl $ver --------------------\n";
                sys "$binpath/prove t";
            }
        }
        else {
            sys 'prove t';
            #sys 'bin/oktest.pl examples';
        }
    }
};

recipe 'examples', {
    desc   => 'run examples',
    method => sub {
        sys 'bin/oktest.pl -sv examples';
    }
};

recipe 'README', {
    ingreds => ['lib/Oktest.pm'],
    method  => sub {
        sys 'pod2text lib/Oktest.pm > README';
    }
};

recipe 'package', {
    desc    => 'create package',
    ingreds => ['dist'],
    method  => sub {
        my $dir = "dist/$project-$release";
        cd $dir, sub {
            sys 'perl Makefile.PL';
            sys 'make';
            #sys 'make disttest';
            sys 'make dist';
        };
        mv "$dir/$project-$release.tar.gz", '.';
    }
};

my @text_files = qw(Changes Kookbook.pl MANIFEST MIT-LICENSE Makefile.PL README);

recipe 'dist', {
    desc    => 'copy and edit files into dist directory',
    ingreds => ['README'],
    method  => sub {
        ## create directory
        my $dir = "dist/$project-$release";
        rm_rf $dir if -d $dir;
        mkdir_p "dist/$project-$release";
        ## copy files
        store @text_files, $dir;
        store 'bin/*', 'lib/**/*', 't/**/*', 'examples/**/*', $dir;
        ## create MANIFEST file
        cd $dir, sub {
            #sys 'make -f ../../Makefile manifest';
            #rm 'MANIFEST';
            #sys 'perl "-MExtUtils::Manifest=mkmanifest" -e mkmanifest 2>/dev/null';
            sys "find . -type f | sed -e 's=^\\./==g' > MANIFEST";
            cp 'MANIFEST', '../..';
            #rm 'MANIFEST.bak' if -f 'MANIFEST.bak';
        };
        ## edit files
        cd $dir, sub {
            edit '**/*', sub {
                s/\$Release\$/$release/eg;
                #s/\$Copyright\$/$copyright/eg;
                #s/\$License\$/$license/eg;
                s/\$Release: .*? \$/"\$Release: $release \$"/eg;
                #s/\$Copyright: .*? \$/"\$Copyright: $copyright \$"/eg;
                #s/\$License: .*? \$/"\$License: $license \$"/eg;
                $_ || '-';
            };
            chmod 0755, $_ for glob('bin/*');
        };
        ##
    }
};

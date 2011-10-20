###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

use strict;
use warnings;
use Test::More tests => 55;


use Oktest;


sub TARGET { return undef; }



for (TARGET('Oktest::MainApp')) {


    for (TARGET('new()')) {

        #: takes argv and command name.
        {
            my $argv = ['-h', 'foo'];
            my $app = Oktest::MainApp->new($argv, 'oktest.php');
            ok($app->{argv} == $argv);
            is($app->{command}, 'oktest.php');
        }

        #: uses @ARGV when $argv is not specified.
        {
            my $app = Oktest::MainApp->new();
            ok($app->{argv} == \@ARGV);
        }

        #: detects $command from $0 when $command is not specified.
        {
            local $0 = 'foo/bar/baz-1.pl';
            my $app = Oktest::MainApp->new();
            is($app->{command}, 'baz-1.pl');
        }

    }


    for (TARGET("#_parse_argv()")) {

        sub _parse_argv {
            my ($argv) = @_;
            my $app = Oktest::MainApp->new($argv, 'oktest.pl');
            return $app->_parse_argv();
        }

        #: parses short options which don't take argument.
        {
            my $argv = ['-h', '-v', 'foo', 'bar'];
            my $opts = _parse_argv($argv);
            cmp_ok($opts->{help},    '==', 1);
            cmp_ok($opts->{version}, '==', 1);
            is_deeply($argv, ['foo', 'bar']);
        }

        #: parses short options which take argument.
        {
            my $argv = ['-s', 'verbose', 'foo', 'bar'];
            my $opts = _parse_argv($argv);
            cmp_ok($opts->{style}, 'eq', 'verbose');
            is_deeply($argv, ['foo', 'bar']);
        }

        #: parses concatenated short options.
        {
            my $argv = ['-hvsverbose', 'foo', 'bar'];
            my $opts = _parse_argv($argv);
            cmp_ok($opts->{help},    '==', 1);
            cmp_ok($opts->{version}, '==', 1);
            cmp_ok($opts->{style},   'eq', 'verbose');
            is_deeply($argv, ['foo', 'bar']);
        }

        #: throws error when required argument is missing.
        {
            undef $@;
            eval { _parse_argv(['-h', '-s']) };
            is($@, "oktest.pl: -s: argument required.\n");
            #
            undef $@;
            eval { _parse_argv(['-hs']) };
            is($@, "oktest.pl: -s: argument required.\n");
            undef $@;
        }

        #: throws error when unknown short option found.
        {
            undef $@;
            eval { _parse_argv(['-h', '-H']) };
            is($@, "oktest.pl: -H: unknown option.\n");
            undef $@;
            eval { _parse_argv(['-hvx']) };
            is($@, "oktest.pl: -x: unknown option.\n");
            undef $@;
        }

        #: parses long options.
        {
            my $argv = ['--help', '--spec=pat', 'foo', 'bar'];
            my $opts = _parse_argv($argv);
            cmp_ok($opts->{help}, '==', 1);
            cmp_ok($opts->{spec}, 'eq', 'pat');
            is_deeply($argv, ['foo', 'bar']);
        }

        #: throws error when unknown long option found.
        {
            undef $@;
            eval { _parse_argv(['--quiet', 'foo']) };
            is($@, "oktest.pl: --quiet: unknown option.\n");
            undef $@;
            eval { _parse_argv(['--quiet=true', 'foo']) };
            is($@, "oktest.pl: --quiet=true: unknown option.\n");
            undef $@;
        }

        #: throws error when unexpected argument specified for long option.
        {
            undef $@;
            eval { _parse_argv(['--version=1.2.3', 'foo']) };
            is($@, "oktest.pl: --version=1.2.3: unexpected argument.\n");
            undef $@;
        }

        #: throws error when required argument is missing for long option.
        {
            undef $@;
            eval { _parse_argv(['--spec', 'foo']) };
            is($@, "oktest.pl: --spec: argument required.\n");
            undef $@;
        }

        #: stops parsing when '--' found.
        {
            my $argv = ['-h', '--', '-v', 'foo', 'bar'];
            my ($opts, $props) = _parse_argv($argv);
            is_deeply($opts, { help=>1 });
            is_deeply($argv, ['-v', 'foo', 'bar']);
        }

    }


    for (TARGET("#execute()")) {

        my $dir   = '_test.d';
        my $file1 = "$dir/ex1.t";
        my $file2 = "$dir/ex2.t";
        my $file3 = "$dir/ex3.t";
        my $cont1 =
            "use strict;\n" .
            "use warnings;\n" .
            "no warnings 'void';\n" .
            "use Oktest;\n" .
            "target 'Ex1', sub {\n" .
            "    spec 'S1', sub {\n" .
            "        OK (1+1) == 2;\n" .
            "    };\n" .
            "};\n" .
            "1;\n" .
            "";
        my $cont2 = $cont1;  $cont2 =~ s/1'/2'/g;
        my $cont3 = $cont1;  $cont3 =~ s/1'/3'/g;

        my $setup = sub {
            mkdir($dir) unless -d $dir;
            Oktest::Util::write_file($file1, $cont1);
            Oktest::Util::write_file($file2, $cont2);
            Oktest::Util::write_file($file3, $cont3);
            Oktest::__clear();
        };
        my $teardown = sub {
            Oktest::__clear();
            unlink($_) for glob("$dir/*");
            rmdir($dir);
            delete $INC{$file1};
            delete $INC{$file2};
            delete $INC{$file3};
        };

        #: load files specified in argv.
        {
            my $expected =
                "1..2\n" .
                "## * Ex1\n" .
                "ok 1 - S1\n" .
                "## * Ex3\n" .
                "ok 2 - S3\n" .
                "## ok:2, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
                "";
            $setup->();
            undef $@;
            my $output = eval {
                Oktest::Util::capture_stdout {
                    Oktest::MainApp->new([$file1, $file3])->execute();
                };
            };
            $output =~ s/elapsed: \d+\.\d\d\d/elapsed: 0.000/;
            $teardown->();
            is($output, $expected);
            die $@ if $@;
        }

        #: load files under directory specified.
        {
            my $expected =
                "1..3\n" .
                "## * Ex1\n" .
                "ok 1 - S1\n" .
                "## * Ex2\n" .
                "ok 2 - S2\n" .
                "## * Ex3\n" .
                "ok 3 - S3\n" .
                "## ok:3, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
                "";
            $setup->();
            undef $@;
            my $output = eval {
                Oktest::Util::capture_stdout {
                    Oktest::MainApp->new([$dir])->execute();
                };
            };
            $output =~ s/elapsed: \d+\.\d\d\d/elapsed: 0.000/;
            $teardown->();
            is($output, $expected);
            die $@ if $@;
        }

        #: error when file is not found.
        {
            $setup->();
            undef $@;
            eval {
                Oktest::MainApp->new([$file1, "$dir/ex9.t", $file2])->execute();
            };
            $teardown->();
            is($@, "$dir/ex9.t: no such file or directory.\n");
            undef $@;
        }

    }


    sub _run_mainapp {
        Oktest::__clear();
        my @argv = @_;
        my $output = Oktest::Util::capture_stdout {
            Oktest::main(\@argv, 'oktest.pl');
        };
        $output =~ s/elapsed: \d+\.\d\d\d/elapsed: 0.000/;
        return $output;
    }


    for (TARGET("'-h', '--help'")) {

        #: prints help message.
        {
            my $expected =
                "oktest.pl - a new-style testing library.\n" .
                "Usage:  oktest.pl [options] file_or_dir [file_or_dir2...]\n" .
                "  -h, --help           : show help\n" .
                "  -v, --version        : show version\n" .
                "  -s, --style=name     : reporting style (tap/verbose/simple/plain, or t/v/s/p)\n" .
                "      --spec=regexp    : filter by spec description\n" .
                "      --target=regexp  : filter by target name\n" .
                "      --report-skipped : report detail of skipped items\n" .
                "      --report-todo    : report detail of TODO items\n" .
                "";
            my $actual = _run_mainapp('-h');
            is($actual, $expected);
            $actual = _run_mainapp('--help');
            is($actual, $expected);
        }

    }


    for (TARGET("'-v', '--version'")) {

        #: prints version.
        {
            my $expected = $Oktest::VERSION . "\n";
            my $actual = _run_mainapp('-v');
            is($actual, $expected);
            $actual = _run_mainapp('--version');
            is($actual, $expected);
        }

    }


    my $_filename = "_test_example_code.t";
    my $_content =
        "use strict;\n" .
        "use warnings;\n" .
        "use Oktest;\n" .
        "target 'ClassName', sub {\n" .
        "  target 'methodA', sub {\n" .
        "    spec 'A1', sub { OK(1+1)==2 };\n" .
        "    spec 'A2', sub { OK(1+1)==1 };\n" .
        "    spec 'A3', sub { die \"ORA800\n\" };\n" .
        "    spec 'A4', sub { skip_when 1==1, 'not supported' };\n" .
        "    spec 'A5', sub { TODO('not implemented') };\n" .
        "  };\n" .
        "  target 'methodB', sub {\n" .
        "    spec 'B1', sub { OK(1+1)==2 };\n" .
        "  };\n" .
        "};\n" .
        "";
    my $_run_testcode = sub {
        my (@opts) = @_;
        Oktest::__clear();
        delete $INC{$_filename} if $INC{$_filename};
        Oktest::Util::write_file($_filename, $_content);
        undef $@;
        my $output = eval { _run_mainapp(@opts, $_filename) };
        unlink($_filename) if -f $_filename;
        die $@ if $@;
        return $output;
    };


    for (TARGET("'-s' or '--style'")) {

        #: reports in verbose style when '-sv', '-s verbose', or '--style=verbose' specfied.
        {
            my $expected =
                "* ClassName\n" .
                "  * methodA\n" .
                "    - [ok] A1\n" .
                "    - [Failed] A2\n" .
                "    - [ERROR] A3\n" .
                "    - [Skipped] A4 ## not supported\n" .
                "    - [TODO] A5 ## not implemented\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [Failed] * ClassName > methodA > A2\n" .
                "# Assertion: \$actual == \$expected : failed.\n" .
                "#   \$actual:   2\n" .
                "#   \$expected: 1\n" .
                "# File '_test_example_code.t', line 7:\n" .
                "#     spec 'A2', sub { OK(1+1)==1 };\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [ERROR] * ClassName > methodA > A3\n" .
                "# ORA800\n" .
                "# ----------------------------------------------------------------------\n" .
                "  * methodB\n" .
                "    - [ok] B1\n" .
                "## ok:2, failed:1, error:1, skipped:1, todo:1  (elapsed: 0.000)\n" .
                "";
            is($_run_testcode->('-sv'),             $expected);
            is($_run_testcode->('-sverbose'),       $expected);
            is($_run_testcode->('--style=v'),       $expected);
            is($_run_testcode->('--style=verbose'), $expected);
        }

        #: reports in verbose style when '-ss', '-s simple', or '--style=simple' specfied.
        {
            my $expected =
                "* ClassName\n" .
                "  * methodA: .fEst\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [Failed] * ClassName > methodA > A2\n" .
                "# Assertion: \$actual == \$expected : failed.\n" .
                "#   \$actual:   2\n" .
                "#   \$expected: 1\n" .
                "# File '_test_example_code.t', line 7:\n" .
                "#     spec 'A2', sub { OK(1+1)==1 };\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [ERROR] * ClassName > methodA > A3\n" .
                "# ORA800\n" .
                "# ----------------------------------------------------------------------\n" .
                "  * methodB: .\n" .
                "## ok:2, failed:1, error:1, skipped:1, todo:1  (elapsed: 0.000)\n" .
                "";
            is($_run_testcode->('-ss'),            $expected);
            is($_run_testcode->('-ssimple'),       $expected);
            is($_run_testcode->('--style=s'),      $expected);
            is($_run_testcode->('--style=simple'), $expected);
        }

        #: reports in verbose style when '-sp', '-s plain', or '--style=plain' specfied.
        {
            my $expected =
                ".fEst.\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [Failed] * ClassName > methodA > A2\n" .
                "# Assertion: \$actual == \$expected : failed.\n" .
                "#   \$actual:   2\n" .
                "#   \$expected: 1\n" .
                "# File '_test_example_code.t', line 7:\n" .
                "#     spec 'A2', sub { OK(1+1)==1 };\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [ERROR] * ClassName > methodA > A3\n" .
                "# ORA800\n" .
                "# ----------------------------------------------------------------------\n" .
                "## ok:2, failed:1, error:1, skipped:1, todo:1  (elapsed: 0.000)\n" .
                "";
            is($_run_testcode->('-sp'),           $expected);
            is($_run_testcode->('-splain'),       $expected);
            is($_run_testcode->('--style=p'),     $expected);
            is($_run_testcode->('--style=plain'), $expected);
        }

    };


    for (TARGET("'--report-skipped'")) {

        #: reports detail of skipped items.
        {
            my $expected1 =
                "* ClassName\n" .
                "  * methodA\n" .
                "    - [ok] A1\n" .
                "    - [Failed] A2\n" .
                "    - [ERROR] A3\n" .
                "    - [Skipped] A4 ## not supported\n" .
                "    - [TODO] A5 ## not implemented\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [Failed] * ClassName > methodA > A2\n" .
                "# Assertion: \$actual == \$expected : failed.\n" .
                "#   \$actual:   2\n" .
                "#   \$expected: 1\n" .
                "# File '_test_example_code.t', line 7:\n" .
                "#     spec 'A2', sub { OK(1+1)==1 };\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [ERROR] * ClassName > methodA > A3\n" .
                "# ORA800\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [Skipped] * ClassName > methodA > A4\n" .
                "# Reason: not supported\n" .
                "# ----------------------------------------------------------------------\n" .
                "  * methodB\n" .
                "    - [ok] B1\n" .
                "## ok:2, failed:1, error:1, skipped:1, todo:1  (elapsed: 0.000)\n" .
                "";
            my $expected2 =
                "* ClassName\n" .
                "  * methodA: .fEst\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [Failed] * ClassName > methodA > A2\n" .
                "# Assertion: \$actual == \$expected : failed.\n" .
                "#   \$actual:   2\n" .
                "#   \$expected: 1\n" .
                "# File '_test_example_code.t', line 7:\n" .
                "#     spec 'A2', sub { OK(1+1)==1 };\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [ERROR] * ClassName > methodA > A3\n" .
                "# ORA800\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [Skipped] * ClassName > methodA > A4\n" .
                "# Reason: not supported\n" .
                "# ----------------------------------------------------------------------\n" .
                "  * methodB: .\n" .
                "## ok:2, failed:1, error:1, skipped:1, todo:1  (elapsed: 0.000)\n" .
                "";
            my $expected3 =
                ".fEst.\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [Failed] * ClassName > methodA > A2\n" .
                "# Assertion: \$actual == \$expected : failed.\n" .
                "#   \$actual:   2\n" .
                "#   \$expected: 1\n" .
                "# File '_test_example_code.t', line 7:\n" .
                "#     spec 'A2', sub { OK(1+1)==1 };\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [ERROR] * ClassName > methodA > A3\n" .
                "# ORA800\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [Skipped] * ClassName > methodA > A4\n" .
                "# Reason: not supported\n" .
                "# ----------------------------------------------------------------------\n" .
                "## ok:2, failed:1, error:1, skipped:1, todo:1  (elapsed: 0.000)\n" .
                "";
            is($_run_testcode->('-sv', '--report-skipped'),  $expected1);
            is($_run_testcode->('-ss', '--report-skipped'),  $expected2);
            is($_run_testcode->('-sp', '--report-skipped'),  $expected3);
        }

    }


    for (TARGET("'--report-todo'")) {

        #: reports detail of skipped items.
        {
            my $expected1 =
                "* ClassName\n" .
                "  * methodA\n" .
                "    - [ok] A1\n" .
                "    - [Failed] A2\n" .
                "    - [ERROR] A3\n" .
                "    - [Skipped] A4 ## not supported\n" .
                "    - [TODO] A5 ## not implemented\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [Failed] * ClassName > methodA > A2\n" .
                "# Assertion: \$actual == \$expected : failed.\n" .
                "#   \$actual:   2\n" .
                "#   \$expected: 1\n" .
                "# File '_test_example_code.t', line 7:\n" .
                "#     spec 'A2', sub { OK(1+1)==1 };\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [ERROR] * ClassName > methodA > A3\n" .
                "# ORA800\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [TODO] * ClassName > methodA > A5\n" .
                "# Description: not implemented\n" .
                "# ----------------------------------------------------------------------\n" .
                "  * methodB\n" .
                "    - [ok] B1\n" .
                "## ok:2, failed:1, error:1, skipped:1, todo:1  (elapsed: 0.000)\n" .
                "";
            my $expected2 =
                "* ClassName\n" .
                "  * methodA: .fEst\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [Failed] * ClassName > methodA > A2\n" .
                "# Assertion: \$actual == \$expected : failed.\n" .
                "#   \$actual:   2\n" .
                "#   \$expected: 1\n" .
                "# File '_test_example_code.t', line 7:\n" .
                "#     spec 'A2', sub { OK(1+1)==1 };\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [ERROR] * ClassName > methodA > A3\n" .
                "# ORA800\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [TODO] * ClassName > methodA > A5\n" .
                "# Description: not implemented\n" .
                "# ----------------------------------------------------------------------\n" .
                "  * methodB: .\n" .
                "## ok:2, failed:1, error:1, skipped:1, todo:1  (elapsed: 0.000)\n" .
                "";
            my $expected3 =
                ".fEst.\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [Failed] * ClassName > methodA > A2\n" .
                "# Assertion: \$actual == \$expected : failed.\n" .
                "#   \$actual:   2\n" .
                "#   \$expected: 1\n" .
                "# File '_test_example_code.t', line 7:\n" .
                "#     spec 'A2', sub { OK(1+1)==1 };\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [ERROR] * ClassName > methodA > A3\n" .
                "# ORA800\n" .
                "# ----------------------------------------------------------------------\n" .
                "# [TODO] * ClassName > methodA > A5\n" .
                "# Description: not implemented\n" .
                "# ----------------------------------------------------------------------\n" .
                "## ok:2, failed:1, error:1, skipped:1, todo:1  (elapsed: 0.000)\n" .
                "";
            is($_run_testcode->('-sv', '--report-todo'),  $expected1);
            is($_run_testcode->('-ss', '--report-todo'),  $expected2);
            is($_run_testcode->('-sp', '--report-todo'),  $expected3);
        }

    }


    my $run_examples = sub {              ## depends on 'examples' directory
        Oktest::__clear();
        undef *Hello::new if defined(*Hello::new);
        undef *Hello::say if defined(*Hello::say);
        my %inc = %INC;
        #
        my (@args) = @_;
        push(@args, 'examples');
        my $output = Oktest::Util::capture_stdout {
            Oktest::main(\@args, 'oktest.pl');
        };
        $output =~ s/elapsed: \d+\.\d\d\d/elapsed: 0.000/;
        #
        for (keys(%INC)) {
            delete $INC{$_} unless defined($inc{$_});
        }
        return $output;
    };


    for (TARGET("'--spec=pattern'")) {

        #: filters specs by pattern string.
        {
            my $output = $run_examples->('--spec=returns greeting message.');
            my $expected =
                "1..1\n" .
                "## * Hello\n" .
                "##   * say()\n" .
                "ok 1 - returns greeting message.\n" .
                "## ok:1, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
                "";
            is($output, $expected);
        }

        #: filters specs by pattern regexp.
        {
            my $output = $run_examples->('--spec=/user name/');
            my $expected =
                "1..2\n" .
                "## * Hello\n" .
                "##   * new()\n" .
                "ok 1 - takes user name.\n" .
                "ok 2 - uses 'guest' as default name when no user name.\n" .
                "## ok:2, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
                "";
            is($output, $expected);
        }

    }


    for (TARGET("'--target=pattern'")) {

        #: filters targets by pattern string.
        {
            my $output = $run_examples->('--target=say()');
            my $expected =
                "1..1\n" .
                "## * Hello\n" .
                "##   * say()\n" .
                "ok 1 - returns greeting message.\n" .
                "## ok:1, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
                "";
            is($output, $expected);
        }

        #: filters targets by pattern regexp.
        {
            my $output = $run_examples->('--target=/new\(\)/');
            my $expected =
                "1..2\n" .
                "## * Hello\n" .
                "##   * new()\n" .
                "ok 1 - takes user name.\n" .
                "ok 2 - uses 'guest' as default name when no user name.\n" .
                "## ok:2, failed:0, error:0, skipped:0, todo:0  (elapsed: 0.000)\n" .
                "";
            is($output, $expected);
        }

    }


}

CHANGES
=======


Release 1.4.0
-------------

* [enhance] `ok {}.raise_nothing?` provided which is same as but non-ambiguous than `ok {}.NOT.raise?`.
* [change] `capture_sio()` is renamed to `capture_stdio()`. For backward compatibility, `capture_sio()` is still available as an alias of `capture_stdio()`.
* [enhance] `capture_stdout()` provided which is almost same as `sout, serr = capture_stdio(); ok {serr} == ""`.
* [enhance] `capture_stderr()` provided which is almost same as `sout, serr = capture_stdio(); ok {sout} == ""`.
* [enhance] `capture_command()` provided which invokes command and captures output of stdout and stderr.
* [enhance] `capture_command!()` provided which is similar to `capture_command()` but not raise error even when command failed.



Release 1.3.1
-------------

* [bugfix] Fix gemspec informations.



Release 1.3.0
-------------

* [enhance] `ok {}.raise?` now returns exception object instead of self.
            For example: `exc = ok {...}.raise?(FooError); ok{exc.message} =~ /..../`
* [enhance] `ok {}.method_missing()` now supports keyword arguments and block argument.



Release 1.2.1
-------------

* [bugfix] Fix `VerboseReporter` class to report detail of errors even when no topics.
* [bugfix] Fix `fixture()` in specs to accept keyword arguments.
* [bugfix] Fix wrong text on `README.md`.



Release 1.2.0
-------------

* [enhance] Performance of `ok{}` is significantly improved.
* [enhance] New helpr method `partial_regexp()` provided which is very useful to validate multiline string with regexp. See:
  <https://github.com/kwatch/oktest/blob/ruby/ruby/README.md#partial_regexp>
* [enhance] New keyword argument `fixture:` is added to `spec()`. For example `spec("...", fixture: {key: "value"})` overwrites value of fixture `key`. See:
  <https://github.com/kwatch/oktest/blob/ruby/ruby/README.md#fixture-keyword-argument>
* [enhance] Environemnt variable `$OKTEST_RB` supported which stores default command-line options.
* [change] Color of 'pass' status changed from blue to cyan, because blue color is not visible in dark background very much, while cyan color is visible in both light and dark background.
* [change] Command-line option `--faster` is removed from help message. `--faster` is still available, but not recommended because the performance of `ok{}` is significantly improved.
* [change] Command-line opton `-C`/`--create` are rename to `-S`/`--skeleton`.



Release 1.1.1
-------------

* [bugfix] fix not to raise internal error when filterning by `-F` option matched to nothing.



Release 1.1.0
-------------

* [newfeature] JSON Matcher (like JSON Schema). See:
  https://github.com/kwatch/oktest/blob/ruby/ruby/README.md#json-matcher
* [change] change reporting style of '-s simple' option to print topics.
* [change] add `-s compact` option which output is same as `-s simple` of previous release.



Release 1.0.2
-------------

* [bugfix] `ruby foo_test.rb` runs test cases in that script instead of printing help message.



Release 1.0.1
-------------

* [bugfix] `Oktest.scope()` converts test script filename from absolute path to relative path.
* [bugfix] fix README file.



Release 1.0.0
-------------

* public release

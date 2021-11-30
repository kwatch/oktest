CHANGES
=======



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

CHANGES
=======


Release 1.2.0
-------------

* [enhance] performance of `ok{}` is improved.
* [change] command-line option `--faster` is removed from help message. `--faster` is still available, but not recommended because the performance without `--faster` is improved very much.



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

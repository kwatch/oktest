======
README
======

$Release: $


Overview
--------

Oktest is a new-style testing library for Python.
::

    from oktest import ok
    ok (x) > 0                 # same as assert_(x > 0)
    ok (s) == 'foo'            # same as assertEqual(s, 'foo')
    ok (s) != 'foo'            # same as assertNotEqual(s, 'foo')
    ok (f).raises(ValueError)  # same as assertRaises(ValueError, f)
    ok ('file.txt').is_file()  # same as assert_(os.path.isfile('file.txt'))
    ok (u'123').is_a(unicode)  # same as assert_(isinstance(u'123', unicode))

You can use ok() instead of 'assertXxx()' in unittest.

Oktest requires Python 2.4 or later. Oktest is ready for Python 3.

NOTICE!! Oktest is a young project and specification may change in the future.


Example
-------

test_example.py::

    from oktest import ok, run
    import sys, os

    ## no need to extend TestCase class
    class Example1Test(object):

        ## invoked only once before all tests
        @classmethod
        def before_all(self):
            os.mkdir('tmp.d')

        ## invoked only once after all tests done
        @classmethod
        def after_all(self):
            import shutil
            shutil.rmtree('tmp.d')

        ## invoked before each test
        def before_all(self):
            self.val = ['aaa', 'bbb', 'ccc']

        ## invoked after each test
        def after_all(self):
            pass

        ## test methods
        def test_valtype(self):
            ok (type(self.val)) == list

        def test_length(self):
            ok (len(self.val)) == 3


    ## 'ok()' is available with unittest.TestCase
    import unittest
    class Example2Test(unittest.TestCase):

        def setUp(self):
            self.val = ['aaa', 'bbb', 'ccc']

        def test_valtype(self):
            ok (type(self.val)) == list

        def test_length(self):
            ok (len(self.val)) == 3

    ## invoke tests
    if __name__ == '__main__':
        from oktest import run
        run(Example1Test, Example2Test)
	## or
	#run('.*Test$')  # specify class names by regular expression


Reference
---------

:ok (val1) == val2:
	Raise AssertionError unless val == val2.

:ok (val1) != val2:
	Raise AssertionError unless val != val2.

:ok (val1) > val2:
	Raise AssertionError unless val > val2.

:ok (val1) >= val2:
	Raise AssertionError unless val >= val2.

:ok (val1) < val2:
	Raise AssertionError unless val < val2.

:ok (val1) <= val2:
	Raise AssertionError unless val <= val2.

:ok (val1).in_(val2):
	Raise AssertionError unless val in val2.

:ok (val1).not_in(val2):
	Raise AssertionError unless val not in val2.

:ok (val1).contains(val2):
	Raise AssertionError unless va2 in val1.

:ok (val1).contains(val2):
	Raise AssertionError unless va2 not in val1.

:ok (val1).is_(val2):
	Raise AssertionError unless va2 is val1.

:ok (val1).is_not(val2):
	Raise AssertionError if va2 is val1.

:ok (val1).is_a(val2):
	Raise AssertionError unless isinstance(val1, val2).

:ok (val1).is_not_a(val2):
	Raise AssertionError if isinstance(val1, val2).

:ok (val1).matches(val2):
	If val2 is a string, raise AssertionError unless re.search(val2, val1).
	If val2 is a re.Pattern object, raise AssertionError unless val2.search(val1).

:ok (val1).not_match(val2):
	If val2 is a string, raise AssertionError if re.search(val2, val1).
	If val2 is a re.Pattern object, raise AssertionError if val2.search(val1).

:ok (path).is_file():
	Raise AssertionError unless os.path.isfile(path).

:ok (path).is_not_file():
	Raise AssertionError if os.path.isfile(path).

:ok (path).is_dir():
	Raise AssertionError unless os.path.isdir(path).

:ok (path).is_not_dir():
	Raise AssertionError if os.path.isdir(path).

:ok (path).exists():
	Raise AssertionError unless os.path.exists(path).

:ok (path).not_exist():
	Raise AssertionError if os.path.exists(path).

:ok (func).raises(error_class[, errmsg=None]):
	Raise AssertionError unless func() raises error_class.

:ok (func).not_raise(error_class):
	Raise AssertionError if func() raises error_class.

:run(*classes):
	Invokes tests of each class.
	Argument can be regular expression string.
	For example, run(r'.*Test$') invokes tests of Example1Test, Example2Test, and so on.

:dummy_file(filename, content):
	Create dummy file with specified content.
	For example, 'with dummy_file("A.txt", "aaa") ...' creates dummy file 'A.txt' with content 'aaa' and it will be removed automatically at the end of with-statement block.

:dummy_dir(dirname):
	Create dummy directory.
	For example, 'with dummy_dir("tmp.d") ...' creates dummy directory 'tmp.txt' and it will be removed automatically at the end of with-statement block.

:chdir(dirname):
	Change current directory to dirname temporarily.
	For example, 'with chdir("lib") ...' changes current directory to 'lib' and back-to original directory at the end of with-statement block.


Tips
----

* You can filter test methods to invoke by environment variable $TEST. For example, 'export TEST="ex[0-9]+"' will invokes 'test_ex1()', 'test_ex2()', ..., but not invoke 'test_1()', 'test_2()', and so on.

* If you want to output format, create oktest.Reporter subclass and set it to oktest.REPORTER variable.


ToDo
----

* [_] print 'diff -u' when two strings are different
* [_] improve reporters
* [_] make package(?)


License
---------

$License: MIT License $


Copyright
---------

$Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $

======
README
======

$Release: 0.2.2 $


Overview
--------

Oktest is a new-style testing library for Python.
::

    from oktest import ok
    ok (x) > 0                 # same as assert_(x > 0)
    ok (s) == 'foo'            # same as assertEqual(s, 'foo')
    ok (s) != 'foo'            # same as assertNotEqual(s, 'foo')
    ok (f).raises(ValueError)  # same as assertRaises(ValueError, f)
    ok (u'foo').is_a(unicode)  # same as assert_(isinstance(u'foo', unicode))
    not_ok (u'foo').is_a(int)  # same as assert_(not isinstance(u'foo', int))
    ok ('A.txt').is_file()     # same as assert_(os.path.isfile('A.txt'))
    not_ok ('A.txt').is_dir()  # same as assert_(not os.path.isdir('A.txt'))

You can use ok() instead of 'assertXxx()' in unittest.

Oktest requires Python 2.3 or later. Oktest is ready for Python 3.

NOTICE!! Oktest is a young project and specification may change in the future.


Download
--------

http://pypi.python.org/pypi/Oktest/

Installation::

    ## if you have installed easy_install:
    $ sudo easy_install Oktest
    ## or download Oktest-$Release$.tar.gz and install it
    $ wget http://pypi.python.org/packages/source/O/Oktest/Oktest-$Release$.tar.gz
    $ tar xzf Oktest-$Release$.tar.gz
    $ cd Oktest-$Release$/
    $ sudo python setup.py install


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

ok (x) == y
	Raise AssertionError unless x == y.

ok (x) != y
	Raise AssertionError unless x != y.

ok (x) > y
	Raise AssertionError unless x > y.

ok (x) >= y
	Raise AssertionError unless x >= y.

ok (x) < y
	Raise AssertionError unless x < y.

ok (x) <= y
	Raise AssertionError unless x <= y.

ok (x).in_(y)
	Raise AssertionError unless x in y.

ok (x).contains(y)
	Raise AssertionError unless y in x. This is opposite of in_().

ok (x).is_(y)
	Raise AssertionError unless x is y.

ok (x).is_not(y)
	Raise AssertionError if x is y.

ok (x).is_a(y)
	Raise AssertionError unless isinstance(x, y).

ok (x).matches(y)
	If y is a string, raise AssertionError unless re.search(y, x).
	If y is a re.pattern object, raise AssertionError unless y.search(x).

ok (path).is_file()
	Raise AssertionError unless os.path.isfile(path).

ok (path).is_dir()
	Raise AssertionError unless os.path.isdir(path).

ok (path).exists()
	Raise AssertionError unless os.path.exists(path).

ok (func).raises(error_class[, errmsg=None])
	Raise AssertionError unless func() raises error_class.
	It sets raised exception into 'func.exception' therefore you can do another test with raised exception object.

not_ok (x)
	Opposite of ok(x). For example, 'not_ok ("foo").matches(r"[0-9]+")' is True.

run(\*classes)
	Invokes tests of each class.
	Argument can be regular expression string.
	For example, run(r'.*Test$') invokes tests of Example1Test, Example2Test, and so on.

dummy_file(filename, content)
	Create dummy file with specified content.
	For example, 'with dummy_file("A.txt", "aaa") ...' creates dummy file 'A.txt' with content 'aaa' and it will be removed automatically at the end of with-statement block.

dummy_dir(dirname)
	Create dummy directory.
	For example, 'with dummy_dir("tmp.d") ...' creates dummy directory 'tmp.txt' and it will be removed automatically at the end of with-statement block.

chdir(dirname)
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

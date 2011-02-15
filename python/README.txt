======
README
======

$Release: 0.8.0 $


Overview
========

Oktest is a new-style testing library for Python.
::

    from oktest import ok
    ok (x) > 0                 # same as assert_(x > 0)
    ok (s) == 'foo'            # same as assertEqual(s, 'foo')
    ok (s) != 'foo'            # same as assertNotEqual(s, 'foo')
    ok (f).raises(ValueError)  # same as assertRaises(ValueError, f)
    ok (u'foo').is_a(unicode)  # same as assert_(isinstance(u'foo', unicode))
    NG (u'foo').is_a(int)      # same as assert_(not isinstance(u'foo', int))
    ok ('A.txt').is_file()     # same as assert_(os.path.isfile('A.txt'))
    NG ('A.txt').is_dir()      # same as assert_(not os.path.isdir('A.txt'))

You can use ok() instead of 'assertXxx()' in unittest.

Oktest requires Python 2.4 or later (3.x is supported).

See CHANGES.txt for changes.

NOTICE!! Oktest is a young project and specification may change in the future.


Download
========

http://pypi.python.org/pypi/Oktest/

Installation::

    ## if you have installed easy_install:
    $ sudo easy_install Oktest
    ## or download Oktest-0.8.0.tar.gz and install it
    $ wget http://pypi.python.org/packages/source/O/Oktest/Oktest-0.8.0.tar.gz
    $ tar xzf Oktest-0.8.0.tar.gz
    $ cd Oktest-0.8.0/
    $ sudo python setup.py install


Example
=======

The following is a short example. ::

    from oktest import ok, NG, run

    class Example1Test(object):

        def test_add(self):
	    ok (1+1) == 1

        def test_sub(self):
	    ok (1-1) == 0

    if __name__ == '__main__':
        run()


The following is a long example. ::

    import sys, os
    from oktest import ok, NG, run

    ## no need to extend TestCase class
    class Example1Test(object):

        ## invoked only once before all tests
        @classmethod
        def before_all(cls):
            os.mkdir('tmp.d')

        ## invoked only once after all tests done
        @classmethod
        def after_all(cls):
            import shutil
            shutil.rmtree('tmp.d')

        ## invoked before each test
        def before(self):   # or setUp(self)
            self.val = ['aaa', 'bbb', 'ccc']

        ## invoked after each test
        def after(self):    # or tearDown(self)
            pass

        ## test methods
        def test_valtype(self):
            ok (self.val).is_a(list)

        def test_length(self):
            ok (len(self.val)) == 3


    ## 'ok()' is available with unittest.TestCase
    import unittest
    class Example2Test(unittest.TestCase):

        def setUp(self):
            self.val = ['aaa', 'bbb', 'ccc']

        def test_valtype(self):
            ok (self.val).is_a(list)

        def test_length(self):
            ok (len(self.val)) == 3

    ## invoke tests
    if __name__ == '__main__':
        run(Example1Test, Example2Test)
        ## or
        #run(r'.*Test$')  # specify class names by regular expression
        ## or
        #run()            # same as run(r'.*(Test|TestCase|_TC)$')


NOTE: Since Oktest 0.5, it is recommended to describe test scpecification by spec() helper for readability.
See the example at the bottom of this document.


Assertion Reference
===================

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

ok (x).in_delta(y, delta)
	Raise AssertionError unless y-delta < x < y+delta.

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

ok (x).has_attr(y)
	Raise AssertionError unless hasattr(x, y).

ok (x).matches(y[, flag=None])
	If y is a string, raise AssertionError unless re.search(y, x).
	If y is a re.pattern object, raise AssertionError unless y.search(x).
	You can pass flag such as ``re.M | re.S``.

ok (path).is_file()
	Raise AssertionError unless os.path.isfile(path).

ok (path).is_dir()
	Raise AssertionError unless os.path.isdir(path).

ok (path).exists()
	Raise AssertionError unless os.path.exists(path).

ok (func).raises(error_class[, errmsg=None])
	Raise AssertionError unless func() raises error_class.
	It sets raised exception into 'func.exception' therefore you can do another test with raised exception object. ::

	    obj = "foobar"
	    def f():
	        obj.name
	    ok (f).raises(AttributeError, "'str' object has no attribute 'name'")
	    ok (f.exception.message) == "'str' object has no attribute 'name'"

NG (x)
	Opposite of ok(x). For example, 'NG ("foo").matches(r"[0-9]+")' is True. ::

	    fname = 'file.txt'
	    open(fname, 'w').write('foo')
	    ok (fname).is_file()            # file exists
	    os.unlink(fname)
	    NG (fname).is_file()        # file doesn't exist

not_ok (x)
	Same as NG(x).


Oktest allows you to define custom assertion functions.
See Tips section.


Unified Diff
============

'ok(x) == y' prints unified diff (diff -u) if:

* both x and y are str or unicode
* and x != y
* and oktest.DIFF is True or 'repr'
* and invoked with oktest.run()

For example::

    ## foo_test.py
    from oktest import *
    
    class FooTest(object):
    
        def test1(self):
            s1 = ( "AAA\n"
                   "BBB\n"
                   "CCC\n" )
            s2 = ( "AAA\n"
                   "CCC\n"
                   "DDD\n" )
            ok (s1) == s2
    
    if __name__ == '__main__':
        run(FooTest)

If you run this script, you'll find that unified diff is displayed.

Output result::

    $ python foo_test.py
    ### FooTest
    f
    Failed: FooTest#test1()
       'AAA\nBBB\nCCC\n' == 'AAA\nCCC\nDDD\n' : failed.
       foo_test.py:13:  ok (s1) == s2
    --- expected 
    +++ actual 
    @@ -1,3 +1,3 @@
     AAA
    +BBB
     CCC
    -DDD

If you set 'oktest.DIFF' to 'repr', each line is preprocessed by repr(). This is very useful to show non-visible characters. For example::

    $ vi foo_test.py    # add 'import oktest; oktest.DIFF = repr'
    $ python foo_test.py
    ### FooTest
    f
    Failed: FooTest#test1()
       'AAA\nBBB\nCCC\n' == 'AAA\nCCC\nDDD\n' : failed.
       hoge.py:15:  ok (s1) == s2
    --- expected 
    +++ actual 
    @@ -1,3 +1,3 @@
     'AAA\n'
    +'BBB\n'
     'CCC\n'
    -'DDD\n'

If you set 'oktest.DIFF' to False, unified diff is not displayed.

Notice that this feature is only available with oktest.run() and not available with unittest module.


Tracer
======

Oktest provides ``Tracer`` class which can be stub or mock object.
``Tracer`` class can:

* Create fake object.
* Trace method or function call.
* Fake method, or function.

In any case, ``Tracer`` object records both arguments and return-value of method or function calls.

Example to create fake object::

    ## create fake objects
    from oktest.tracer import Tracer
    tr = Tracer()
    foo = tr.fake_obj(m1=100, m2=200)   # method name and return-value
    bar = tr.fake_obj(m3=lambda self, x: x+1)  # method name and body
    ## call fake methods
    ok (bar.m3(0))     == 1
    ok (foo.m2(1,2,3)) == 200    # any argument can be passed
    ok (foo.m1(x=123)) == 100    # any argument can be passed
    ## check results
    ok (repr(tr[0]))   == 'm3(0) #=> 1'
    ok (repr(tr[1]))   == 'm2(1, 2, 3) #=> 200'
    ok (repr(tr[2]))   == 'm1(x=123) #=> 100'

There are several ways to check results::

    from oktest.tracer import Tracer
    tr = Tracer()
    obj = tr.fake_obj(meth=9)
    ok (obj.meth(1, 2, x=3)) == 9
    ## check results
    ok (repr(tr[0]))  == 'meth(1, 2, x=3) #=> 9'
    ## or
    ok (tr[0].list()) == [obj, 'meth', (1, 2), {'x': 3}, 9]
    ## or
    ok (tr[0])        == [obj, 'meth', (1, 2), {'x': 3}, 9]
    ## or
    ok (tr[0].receiver).is_(obj)
    ok (tr[0].name)   == 'meth'
    ok (tr[0].args)   == (1, 2)
    ok (tr[0].kwargs) == {'x': 3}
    ok (tr[0].ret)    == 9

Example to trace method call::

    class Foo(object):
        def m1(self, x):
            return x + 1
        def m2(self, y):
            return y + 1
    obj = Foo()
    ## trace methods
    from oktest.tracer import Tracer
    tr = Tracer()
    def dummy(original_func, *args, **kwargs):
        #return original_func(*args, **kwargs)
        return 100
    tr.fake_method(obj, m1=dummy, m2=200)
    ## call methods
    ok (obj.m1(1)) == 100
    ok (obj.m2(2)) == 200
    ## check results
    ok (tr[0]) == [obj, 'm1', (1,), {}, 100]
    ok (tr[1]) == [obj, 'm2', (2,), {}, 200]

Example to trace function call::

    def f(x):
        return x+1
    def g(y):
        return f(y+1) + 1
    ## trace functions
    from oktest.tracer import Tracer
    tr = Tracer()
    f = tr.trace_func(f)
    g = tr.trace_func(g)
    ## call functions
    ok (g(0)) == 3
    ## check results
    ok (tr[0]) == [None, 'g', (0,), {}, 3]
    ok (tr[1]) == [None, 'f', (1,), {}, 2]

Example to fake method call::

    class Foo(object):
        def m1(self, x):
            return x + 1
        def m2(self, y):
            return y + 1
    obj = Foo()
    ## fake methods
    from oktest.tracer import Tracer
    tr = Tracer()
    def dummy(original_func, *args, **kwargs):
        #return original_func(*args, **kwargs)
        return 100
    tr.fake_method(obj, m1=dummy, m2=200)
    ## call method
    ok (obj.m1(1)) == 100
    ok (obj.m2(2)) == 200
    ## check results
    ok (tr[0]) == [obj, 'm1', (1,), {}, 100]
    ok (tr[1]) == [obj, 'm2', (2,), {}, 200]

Example to fake function call::

    def f(x):
        return x*2
    ## fake a function
    def dummy(original_func, x):
        #return original_func(x)
        return 'x=%s' % repr(x)
    from oktest.tracer import Tracer
    tr = Tracer()
    f = tr.fake_func(f, dummy)
    ## call function
    ok (f(3))  == 'x=3'
    ## check results
    ok (tr[0]) == [None, 'f', (3,), {}, 'x=3']


Helpers Reference
=================


``oktest`` module
-----------------

run(\*classes)
	Invokes tests of each class.
	Argument can be regular expression string. ::

	    import oktest
	    oktest.run(FooTest, BarTest)  # invokes FooTest and BarTest
	    oktest.run(r'.*Test$')        # invokes FooTest, BarTest, and so on
	    oktest.run()                  # same as oktest.run('.*(Test|TestCase|_TC)$')

spec(description)
	Represents spec description. This is just a marker function, but very useful for readability.
	**It is recommended to use spec() helper for readability of tests.** ::

	    class NumericTest(object):
	        def test_integer(self):
	            with spec("1+1 should be equal to 2."):
	                ok (1+1) == 2
	            with spec("1/0 should be error."):
	                def f(): 1/0
	                ok (f).raises(ZeroDivisionError,
	                              "integer division or modulo by zero")
	            ## tips: 'for' statement is available instead of 'with' for Python 2.4
	            for _ in spec("1+1 should be equal to 2."):
	                ok (1+1) == 2


``oktest.helper`` module
------------------------

chdir(dirname)
	Change current directory to dirname temporarily. ::

	    import os
	    cwd = os.getcwd()                         # current working directory
	    with chdir("/var/tmp"):
	        assert os.getcwd() == "/var/tmp"      # current directory is changed!
	        # do something
	    assert os.getcwd() == cwd                 # back to the original place
	    ## or
	    def fn():
	        assert os.getcwd() == "/var/tmp"
		# do something
            chdir("/var/tmp").run(fn)

rm_rf(filename, dirname, ...)
	Remove file or directory recursively.


``oktest.dummy`` module
------------------------

dummy_file(filename, content)
	Create dummy file with specified content. ::

	    import os
	    from oktest.helper import dummy_file
	    assert not os.path.exists("A.txt")        # file doesn't exist
	    with dummy_file("A.txt", "aaa"):
	        assert os.path.isfile("A.txt")        # file is created!
	        # do something
	    assert not os.path.exists("A.txt")        # file is removed
	    ## or
	    def fn():
	        assert os.path.isfile("A.txt")
	    dummy_file("A.txt", "aaa").run(fn)

dummy_dir(dirname)
	Create dummy directory. ::

	    import os
	    from oktest.helper import dummy_dir
	    assert not os.path.exists("tmpdir")       # directory doesn't exist
	    with dummy_dir("tmpdir"):
	        assert os.path.isdir("tmpdir")        # directory is created!
	        # do something
	    assert not os.path.exists("tmpdir")       # directory is removed
	    ## or
	    def fn():
	        assert os.path.isdir("tmpdir")
            dummy_dir("tmpdir").run(fn)

dummy_values(dictionary, items_=None, \*\*kwargs):
	Change dictionary's values temporarily. ::

	    from oktest.helper import dummy_values
	    d = {'A':10, 'B':20}
	    with dummy_values(d, A=1000, X=2000):
	        assert d['A'] == 1000                 # dictionary values are changed!
	        assert d['B'] == 20
	        assert d['X'] == 2000
	        # do something
	    assert d == {'A':10, 'B':20}              # values are backed
	    ## or
	    def fn():
	        assert d['A'] == 1000
	    dummy_values(d, A=1000, X=2000).run(fn)

dummy_attrs(object, items_=None, \*\*kwargs):
	Change object's attributes temporarily.
	This is same as dummy_values(object.__dict__, \*\*kwargs). ::

	    from oktest.helper import dummy_attrs
	    class Hello(object):
	        pass
	    obj = Hello()
	    obj.x = 10
	    obj.y = 20
	    with dummy_attrs(obj, x=90, z=100):
	        assert obj.x == 90                    # attributes are changed!
	        assert obj.y == 20
	        assert obj.z == 100
	        # do something
	    assert obj.x == 10                        # attributes are backed
	    assert obj.y == 20
	    assert not hasattr(obj, 'z')
	    ## or
	    def fn():
	        assert obj.x == 90
	    dummy_attrs(obj, x=90, z=100).run(fn)

dummy_io(stdin_content=None, func=None):
	Set dummy I/O to sys.stdout, sys.stderr, and sys.stdin. ::

	    with dummy_io("SOS") as d_io:
	        assert sys.stdin.read() == "SOS"
	        print("Haruhi")
	    assert d_io.stdout == "Haruhi\n"
	    assert d_io.stderr == ""
	    ## or
	    def fn():
	        assert sys.stdin.read() == "SOS"
	        print("Haruhi")
	    d_io = dummy_io("SOS")
	    d_io.run(fn)
	    assert d_io.stdout == "Haruhi\n"


``oktest.tracer`` module
------------------------

tracer():
	Return tracer object. See the above section for details.


Tips
====

* You can define your own custom assertion function. ::

    ## define custom assertion function
    import oktest
    @oktest.assertion
    def startswith(self, arg):
        boolean = self.target.startswith(arg)
        if boolean == self.expected:
            return True
        self.failed("%r.startswith(%r) : failed." % (self.target, arg))

    ## how to use
    from oktest import ok
    ok ("Sasaki").startswith("Sas")

* It is possible to chain assertion methods. ::

    ## chain assertion methods
    ok ("sos".upper()).is_a(str).matches(r'^[A-Z]+$')

* If you call ok() or not_ok() but forget to do assertion, oktest warns it. ::

    import oktest
    from oktest import ok, not_ok
    
    class FooTest(object):
        def test_1(self):
            #ok (1+1) == 2
            ok (1+1)         # missing assertion

    oktest.run()   #=> warning: ok() is called but not tested.

* You can filter test methods to invoke by environment variable $TEST. For example, 'export TEST="ex[0-9]+"' will invokes 'test_ex1()', 'test_ex2()', ..., but not invoke 'test_1()', 'test_2()', and so on.
  ::

    ### filter test by name
    $ TEST='ex[0-9]' python test/foobar_test.py

* If you want to output format, create oktest.Reporter subclass and set it to oktest.REPORTER variable.


ToDo
====

* [v] print unified diff when two strings are different
* [_] improve reporters
* [_] make package(?)
* [v] report assertion objects which are not tested


License
=======

$License: MIT License $


Copyright
=========

$Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $

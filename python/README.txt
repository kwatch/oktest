======
README
======

$Release: 0.5.0 $


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
    not_ok (u'foo').is_a(int)  # same as assert_(not isinstance(u'foo', int))
    ok ('A.txt').is_file()     # same as assert_(os.path.isfile('A.txt'))
    not_ok ('A.txt').is_dir()  # same as assert_(not os.path.isdir('A.txt'))

You can use ok() instead of 'assertXxx()' in unittest.

Oktest requires Python 2.4 or later (3.x is supported).

NOTICE!! Oktest is a young project and specification may change in the future.


Download
========

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
=======

test_example.py::

    from oktest import ok, not_ok, run
    import sys, os

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
        run(Example1Test, Example2Test)
        ## or
        #run(r'.*Test$')  # specify class names by regular expression
        ## or
        #run()            # same as run(r'.*Test(Case)?$')


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

ok (x).hasattr(y)
	Raise AssertionError unless hasattr(x, y).

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
	It sets raised exception into 'func.exception' therefore you can do another test with raised exception object. ::

	    obj = "foobar"
	    def f():
	        obj.name
	    ok (f).raises(AttributeError, "'str' object has no attribute 'name'")
	    ok (f.exception.message) == "'str' object has no attribute 'name'"

not_ok (x)
	Opposite of ok(x). For example, 'not_ok ("foo").matches(r"[0-9]+")' is True. ::

	    fname = 'file.txt'
	    open(fname, 'w').write('foo')
	    ok (fname).is_file()            # file exists
	    os.unlink(fname)
	    not_ok (fname).is_file()        # file doesn't exist


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

Oktest provides Tracer class which steal function or method call and record both arguments and return value.

Example to trace function::

    def hello(x):
        return "Hello %s!" % x
    #
    from oktest.helper import Tracer
    tr = Tracer()              # create Tracer object
    hello = tr.trace(hello)    # trace target function
    #
    hello("John")              # call target function
    print(tr[0].name)     #=> 'hello'
    print(tr[0].args)     #=> ('John',)
    print(tr[0].kwargs)   #=> {}
    print(tr[0].ret)      #=> 'Hello John!'
    print(repr(tr[0]))    #=> hello(args=('John',), kwargs={}, ret='Hello John!')

Example to trace method::

    class Hello(object):
        def hello(self, x):
            return "Hello %s!" % x
    obj = Hello()              # target object to trace
    #
    from oktest.helper import Tracer
    tr = Tracer()              # create tracer object
    tr.trace(obj, 'hello')     # trace method
    #
    obj.hello('John')          # call target method
    print(tr[0].name)     #=> 'hello'
    print(tr[0].args)     #=> ('John',)
    print(tr[0].kwargs)   #=> {}
    print(tr[0].ret)      #=> 'Hello John!'
    print(repr(tr[0]))    #=> hello(args=('John',), kwargs={}, ret='Hello John!')

If you want to trace several methods, specify them into tr.trace().
::

    tr.trace(obj, 'method1', 'method2', 'method3')

It is possible to trace several function or method calls.
::

    def greeting(name):
        return "Hi %s!" % name
    class Hello(object):
        def hello(self, x):
            return greeting(x) + ' How are you?'
    obj = Hello()
    #
    import oktest
    from oktest.helper import Tracer
    tr = Tracer()
    greeting = tr.trace(greeting)  # trace function
    tr.trace(obj, 'hello')         # trace method
    #
    obj.hello('John')
    print(repr(tr[0]))  #=> hello(args=('John',), kwargs={}, ret='Hi John! How are you?')
    print(repr(tr[1]))  #=> greeting(args=('John',), kwargs={}, ret='Hi John!')

Tracer allows you to fake function or method calls.
::

    def f1(x):
        return x+1
    class Example(object):
        def f2(self, x):
            return x+2
    obj = Example()
    ## create trace object
    from oktest.helper import Tracer
    tr = Tracer()
    ## fake f1 function
    def fake_f1(original_func, *args):
        v = original_func(*args)
        return v+10
    f1 = tr.fake_func(f1, fake_f1)
    ## fake f2 method
    def fake_f2(self, x):
        return x+20
    tr.fake_method(obj, f2=fake_f2)
    ## call target function and method
    print(f1(1))         #=> 12
    print(obj.f2(2))     #=> 22
    ## traced data
    print(repr(tr[0]))   #=> f1(args=(1,), kwargs={}, ret=12)
    print(repr(tr[1]))   #=> f2(args=(2,), kwargs={}, ret=22)

Tracer can generate FakeObject which can be stub or mock object.
::

    from oktest.helper import Tracer
    tr = Tracer()
    ## create fake object
    obj1 = tr.fake_obj(f1=lambda self, x: x+1)  # method_name=function
    obj2 = tr.fake_obj(hello="Hello!")          # or method_name=return_value
    ## call fake method
    print(obj2.hello("John"))  #=> 'Hello!'
    print(obj1.f1(10))         #=> 11
    ## check result
    print(repr(tr[0]))  #=> hello(args=('John',), kwargs={}, ret='Hello!')
    print(repr(tr[1]))  #=> f1(args=(10,), kwargs={}, ret=11)



Helpers Reference
=================


``oktest`` module
-----------------

run(\*classes)
	Invokes tests of each class.
	Argument can be regular expression string. ::

	    import oktest
	    oktest.run(FooTest, BarTest)  # invokes FooTest and BarTest
	    oktest.run('.*Test$')         # invokes FooTest, BarTest, and so on
	    oktest.run()                  # same as oktest.run('.*Test(Case)$')

spec(description)
	Represents spec description. This is just a marker function, but very useful for readability.
	**It is strongly recommended to use spec() helper for readability of tests.** ::

	    class NumericTest(object):
	        def test_integer(self):
		    with spec("1+1 should be equal to 2."):
		        ok (1+1) == 2
		    with spec("1/0 should be error."):
		        def f(): 1/0
			ok (f).raises(ZeroDivisionError,
			              "integer division or modulo by zero")


``oktest.helper`` module
------------------------------------

chdir(dirname)
	Change current directory to dirname temporarily. ::

            import os
	    cwd = os.getcwd()                         # current working directory
	    with oktest.chdir("/var/tmp"):
	        assert os.getcwd() == "/var/tmp"      # current directory is changed!
		# do something
	    assert os.getcwd() == cwd                 # back to the original place

Tracer()
	Return new Tracer object. See the previous section for details.

dummy_file(filename, content)
	Create dummy file with specified content. ::

	    import os
	    assert not os.path.exists("A.txt")        # file doesn't exist
	    with oktest.dummy_file("A.txt", "aaa"):
	        assert os.path.isfile("A.txt")        # file is created!
	        # do something
	    assert not os.path.exists("A.txt")        # file is removed

dummy_dir(dirname)
	Create dummy directory. ::

	    import os
	    assert not os.path.exists("tmpdir")       # directory doesn't exist
	    with oktest.dummy_dir("tmpdir"):
	        assert os.path.isdir("tmpdir")        # directory is created!
		# do something
	    assert not os.path.exists("tmpdir")       # directory is removed

dummy_values(dictionary, items_=None, \*\*kwargs):
	Change dictionary's values temporarily. ::

	    d = {'A':10, 'B':20}
	    with oktest.dummy_values(d, A=1000, X=2000):
	        assert d['A'] == 1000                 # dictionary values are changed!
		assert d['B'] == 20
		assert d['X'] == 2000
		# do something
	    assert d == {'A':10, 'B':20}              # values are backed

dummy_attrs(object, items_=None, \*\*kwargs):
	Change object's attributes temporarily.
	This is same as dummy_values(object.__dict__, \*\*kwargs). ::

	    class Hello(object):
	        pass
	    obj = Hello()
	    obj.x = 10
	    obj.y = 20
	    with oktest.dummy_attrs(obj, x=90, z=100):
	        assert obj.x == 90                    # attributes are changed!
		assert obj.y == 20
		assert obj.z == 100 
	        # do something
	    assert obj.x == 10                        # attributes are backed
	    assert obj.y == 20
	    assert not hasattr(obj, 'z')


Tips
====

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

$Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $

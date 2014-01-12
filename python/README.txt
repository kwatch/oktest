=============
Oktest README
=============

Release: $Release$

.. contents::


Overview
========

Oktest is a new-style testing library for Python. ::

    from oktest import test, ok, NG

    class FooTest(unittest.TestCase):

       @test("1 + 1 should be 2")
       def _(self):
          ok (1+1) == 2          # same as assertEqual(2, 1+1)

       @test("other examples")
       def _(self):
          ok (s) == 'foo'        # same as assertEqual(s, 'foo')
          ok (s) != 'foo'        # same as assertNotEqual(s, 'foo')
          ok (n) > 0             # same as assertTrue(n > 0)
          ok (fn).raises(Error)  # same as assertRaises(Error, fn)
          ok ([]).is_a(list)     # same as assertTrue(isinstance([], list))
          NG ([]).is_a(tuple)    # same as assertTrue(not isinstance([], tuple))
          ok ('A.txt').is_file() # same as assertTrue(os.path.isfile('A.txt'))
          NG ('A.txt').is_dir()  # same as assertTrue(not os.path.isdir('A.txt'))

Features:

* Provides ``ok()`` which is much shorter than ``self.assertXxxx()``.
* Allow to write test name in free text.
* `Fixture Injection`_ support.
* `Tracer`_ class is provided which can be used as mock or stub.
* Text diff (diff -u) is displayed when texts are different.

Oktest requires Python 2.4 or later (3.x is supported).

See CHANGES.txt for changes.


Download
========

http://pypi.python.org/pypi/Oktest/

Installation::

    ## if you have installed easy_install:
    $ sudo easy_install Oktest
    ## or download Oktest-0.0.0.tar.gz and install it
    $ wget http://pypi.python.org/packages/source/O/Oktest/Oktest-0.0.0.tar.gz
    $ tar xzf Oktest-0.0.0.tar.gz
    $ cd Oktest-0.0.0/
    $ sudo python setup.py install


Example
=======

Oktest is available with unittest module which is a standard testing library
of Python. ::

    import unittest
    {{*from oktest ok*}}

    class FooTest(unittest.TestCase):

        def test_1_plus_1_should_be_2(self):
            {{*ok (1+1) == 2*}}    # instead of self.assertEqual(2, 1+1)

        def test_string_should_contain_digits(self):
            {{*ok ("foo 123 bar").matches(r"\d+")*}}

    if __name__ == '__main__':
        unittest.main()

See `Assertion Reference`_ section for details about ``ok()`` and ``NG()``.

Using ``@test`` decorator, you can write test name in free text. ::

    import unittest
    from oktest ok, {{*test*}}

    class FooTest(unittest.TestCase):

        {{*@test("1 + 1 should be 2")*}}
        {{*def _(self):*}}
            ok (1+1) == 2

        {{*@test("string should contain digits")*}}
        {{*def _(self):*}}
            ok ("foo 123 bar").matches(r"\d+")

    if __name__ == '__main__':
        unittest.main()

See `@test Decorator`_ section for details about ``@test`` decorator.

Oktest is also available without unittest. See the folloing example. ::

    import sys, os
    {{*import oktest*}}
    from oktest import ok, NG, test

    ## no need to extend TestCase class
    class Example1Test(object):

        ## invoked only once before all tests
        @classmethod
        {{*def before_all(cls):*}}  # or setUpClass(cls)
            os.mkdir('tmp.d')

        ## invoked only once after all tests done
        @classmethod
        {{*def after_all(cls):*}}  # or tearDownClass(cls)
            import shutil
            shutil.rmtree('tmp.d')

        ## invoked before each test
        {{*def before(self):*}}   # or setUp(self)
            self.val = ['aaa', 'bbb', 'ccc']

        ## invoked after each test
        {{*def after(self):*}}    # or tearDown(self)
            pass

        ## test methods

        @test("value should be a list")
        def _(self):
            ok (self.val).is_a(list)

        @test("list length should be 3")
        def _(self):
            ok (len(self.val)) == 3

    ## invoke tests
    if __name__ == '__main__':
        {{*oktest.main()*}}
        ## or
        #{{*oktest.run(r'.*Test$')*}}
        ## or
        #{{*oktest.run(Example1Test, Example2Test)*}}

Both ``Oktest.main()`` and ``Oktest.run()`` accept unittest.TestCase and other class.


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

ok (x).not_in(y)
	Raise AssertionError if x in y.

ok (x).contains(y)
	Raise AssertionError unless y in x. This is opposite of in_().

ok (x).is_(y)
	Raise AssertionError unless x is y.

ok (x).is_not(y)
	Raise AssertionError if x is y.

ok (x).is_a(y)
	Raise AssertionError unless isinstance(x, y).

ok (x).is_not_a(y)
	Raise AssertionError if isinstance(x, y).

ok (x).is_truthy()
	Raise AssertionError unless bool(x) == True.

ok (x).is_falsy()
	Raise AssertionError unless bool(x) == False.

ok (x).has_attr(name)
	Raise AssertionError unless hasattr(x, name).

ok (x).attr(name, value)
	Raise AssertionError unless hasattr(x, name) and getattr(x, name) == value.

ok (x).matches(y[, flag=0])
	If y is a string, raise AssertionError unless re.search(y, x).
	If y is a re.pattern object, raise AssertionError unless y.search(x).
	You can pass flag such as ``re.M | re.S``.

ok (x).not_match(y[, flag=0])
	If y is a string, raise AssertionError if re.search(y, x).
	If y is a re.pattern object, raise AssertionError if y.search(x).
	You can pass flag such as ``re.M | re.S``.

ok (x).length(n):
	Raise AssertionError unless len(x) == n.
	This is same as ``ok (len(x)) == n``, but it is useful to chain
	assertions, like ``ok (x).is_a(tuple).length(n)``.

ok (path).is_file()
	Raise AssertionError unless os.path.isfile(path).

ok (path).not_file()
	Raise AssertionError if os.path.isfile(path).

ok (path).is_dir()
	Raise AssertionError unless os.path.isdir(path).

ok (path).not_dir()
	Raise AssertionError if os.path.isdir(path).

ok (path).exists()
	Raise AssertionError unless os.path.exists(path).

ok (path).not_exist()
	Raise AssertionError if os.path.exists(path).

ok (func).raises(error_class[, errmsg=None])
	Raise AssertionError unless func() raises error_class.
	Second argument is a string or regular expression (re.compile() object).
	It sets raised exception into 'func.exception' therefore you can do another test with raised exception object. ::

	    obj = "foobar"
	    def f():
	        obj.name
	    ok (f).raises(AttributeError, "'str' object has no attribute 'name'")
	    ok (f.exception.message) == "'str' object has no attribute 'name'"

ok (func).not_raise([error_class=Exception])
	Raise AssertionError if func() raises error_class.

ok (value).should
	Special property to test boolean method.
	For example, ``ok (string).should.startswith('foo')`` is same as
	to ``ok (string.startswith('foo')) == True``.

ok (value).should_not
	Special property to test boolean method.
	For example, ``ok (string).should_not.startswith('foo')`` is same as
	to ``ok (string.startswith('foo')) == False``.

ok (response).is_response(status).header(name, value).body(str_or_rexp).json(dict)
	(experimental) Assertions for WebOb or Werkzeug response object. ::

	    ok (response).is_response(200)                          # status code
	    ok (response).is_response('200 OK')                     # status line
	    ok (response).is_response(302).header("Location", "/")  # header
	    ok (response).is_response(200).json({"status": "OK"})   # json data
	    ok (response).is_response(200).body("<h1>Hello</h1>")   # response body
	    ok (response).is_response(200).body(re.compile("<h1>.*?</h1>"))

NG (x)
	Opposite of ok(x). For example, 'NG ("foo").matches(r"[0-9]+")' is True. ::

	    fname = 'file.txt'
	    open(fname, 'w').write('foo')
	    ok (fname).is_file()            # file exists
	    os.unlink(fname)
	    NG (fname).is_file()        # file doesn't exist

not_ok (x)
	Same as NG(x). Provided for backward compatibility.

NOT (x)
	Same as NG(x). Provided experimentalily.

fail(message)
	Raises AssertionError with message.


It is possible to chain assertions. ::

    ## chain assertion methods
    ok (func()).is_a(tuple).length(2)
    d = datetime.date(2000, 12, 31)
    ok (d).attr('year', 2000).attr('month', 12).attr('day', 31)

Oktest allows you to define custom assertion functions.
See `Tips`_ section.


``@test`` Decorator
===================

Oktest provides ``@test()`` decorator.
It is simple but very powerful.

Using ``@test()`` decorator, you can write test description in free text instead
of test method::

    import unittest
    {{*from oktest import test*}}

    class FooTest(unittest.TestCase):

        def test_1_plus_1_should_be_2(self):  # not cool...
            assert 1+1 == 2

        {{*@test("1 + 1 should be 2")*}}    # cool! easy to read & write!
        {{*def _(self):*}}
            assert 1+1 == 2

``@test()`` decorator changes test methods.
For example, the above code is same as the following::

    class FooTest(unittest.TestCase):
        __n = 0

        def _(self):
            assert 1+1 == 2

        __n += 1
        _.__doc__  = "1 + 1 should be 2"
        _.__name__ = "test_%03d: %s" % (__n, _.__doc__)
        locals()[_.__name__] = _

Non-English language is available on ``@test()``::

    class FooTest(unittest.TestCase):

        {{*@test("1 + 1 は 2 になること。")*}}
        def _(self):
            assert 1+1 == 2

``@test()`` decorator accepts user-defined options. You can specify any name and
value as option. It is accessable by 'self._options' in ``setUp()``, therefore
you can change behaviour of ``setUp()`` according to options. ::

    class FooTest(unittest.TestCase):

        def setUp(self):
            tag = {{*self._options.get("tag")*}}
            if tag == "experimental":
                ....

        @test("1 + 1 should be 2", {{*tag="experimental"*}})
        def _(self):
            assert 1+1 == 2

You can filter testcase by user-defined options in command-line. ::

    ## do test only tagged as 'experimental'
    $ python -m oktest.py {{*-f tag=experimental*}} test/*_test.py



Fixture Injection
=================

``@test()`` decorator supports fixture injection.

* Arguments of test method are regarded as fixture names
  and they are injected by ``@test()`` decorator automatically.
* Instance methods or global functions which name is ``provide_xxxx()`` are
  regarded as fixture provider (or builder) for fixture ``xxxx``.
* Similar to that, instance methods or global functions which name is
  ``release_xxxx()`` are regarded as fixture releaser (or destroyer).
  Notice that provider is mandatory but releaser is optional for fixture.

::

    class SosTest(unittest.TestCase):

        ##
        ## fixture providers
        ##
        def {{*provide_member1*}}(self):
            return {"name": "Haruhi"}

        def {{*provide_member2*}}(self):
            return {"name": "Kyon"}

        ##
        ## fixture releasers (optional)
        ##
        def {{*release_member1*}}(self, value):
            assert value == {"name": "Haruhi"}

        ##
        ## testcase which requires 'member1' and 'member2' fixtures.
        ##
        @test("validate member's names")
        def _(self, {{*member1, member2*}}):
            ok (member1["name"]) == "Haruhi"
            ok (member2["name"]) == "Kyon"

This feature is more flexible and useful than ``setUp()`` and ``tearDown()``.

For example, the following code ensures that dummy files are removed
automatically at the end of test without ``tearDown()``. ::

    import os, shutil

    def {{*provide_cleaner()*}}:
        paths = []
        return paths

    def {{*release_cleaner(paths)*}}:
        assert isinstance(paths, list)
        ## remove dummy files registered
        for path in paths:
            if os.path.isfile(path):
                os.unlink(path)
            elif os.path.isdir(path):
                shutil.rmtree(path)

    class FooTest(unittest.TestCase):

        @test("example1")
        def _(self, {{*cleaner*}}):
            fpath = "dummy.txt"
            ## register dummy file
            {{*cleaner.append(fpath)*}}
            ## create dummy file and do test with it
            f = open(fpath, "w"); f.write("DUUUMY"); f.close()
            ok (fpath).is_file()

Default parameter values of test methods are passed into provider functions
if necessary. Using this, you can change provider behaviour as you need. ::

    ## provider can have default value of argument
    def provide_tempfile({{*content="dummy"*}}):
        filename = '__tmp.txt'
        with open(filename, 'w') as f:
            f.write(content)
        return filename

    def release_tempfile(filename):
        if os.path.exists(filename):
            os.unlink(filename)

    class FooTest(unittest.TestCase):

        ## override default value of providers by test method's
        ## default argument value
        @test("example")
        def _(self, tempfile, {{*content="AAAA"*}}):
            with open(tempfile) as f:
                s = f.read()
            ok (s) == {{*"AAAA"*}}

        ## if you don't specify default value in test method,
        ## provider's default value is used
        @test("example")
        def _(self, tempfile):
            with open(tempfile) as f:
                s = f.read()
            ok (s) == {{*"dummy"*}}

Dependencies between fixtures are resolved automatically.
If you know dependency injection framework such as `Spring`_ or `Guice`_,
imagine to apply dependency injection into fixtures. ::

    class BarTest(unittest.TestCase):

        ##
        ## for example:
        ## - Fixture 'a' depends on 'b' and 'c'.
        ## - Fixture 'c' depends on 'd'.
        ##
        def provide_{{*a*}}({{*b*}}, {{*c*}}):  return b + c + ["A"]
        def provide_{{*b*}}():      return ["B"]
        def provide_{{*c*}}({{*d*}}):     return d + ["C"]
        def provide_{{*d*}}():      reutrn ["D"]

        ##
        ## Dependencies between fixtures are solved automatically.
        ## If loop exists in dependency then @test reports error.
        ##
        @test("dependency test")
        def _(self, {{*a*}}):
            assert a == ["B", "D", "C", "A"]

Fixture injection is provided by ``@test()`` decorator, and it is available
with existing test methods::

    {{*@test()*}}
    def test_sample1(self, {{*member1, member2*}}):
        """description"""
        ...

If you want to integrate with other fixture library, create manager object
and set it into ``oktest.fixture_manager``.
The following is an example to use `Forge`_ as external fixture library::

    ## fixture data
    from forge import Forge
    Forge.define('haruhi', name='Haruhi')
    Forge.define('mikuru', name='Mikuru')
    Forge.define('yuki',   name='Yuki')

    ## manager class
    class ForgeFixtureManager(object):
        {{*def provide(self, name):*}}
            return Forge.build(name)
        {{*def release(self, name, value):*}}
            pass

    ## use it
    {{*oktest.fixture_manager =*}} ForgeFixtureManager()


..    _`Spring`: http://www.springsource.org/
..    _`Guice`:  http://code.google.com/p/google-guice/
..    _`Forge`:  https://github.com/mnoble/forge/


``@at_end`` Decorator
=======================

``@at_end`` decorator registers callback function which is called at end of test case.
You can use it as replacement of ``tearDown()`` or ``after()``. ::

    import unittest
    from oktest import ok, test, {{*at_end*}}
    
    class FooTest(unittest.TestCase):
        @test("file.read() returns content of file.")
        def _(self):
            # create a dummy file
            filename = "dummy.tmp"
            with open(filename, 'w') as f:
                f.write("homhom")
            # register callback which is invoked at end of test case
            {{*@at_end*}}
            {{*def _():*}}
                {{*import os*}}
                {{*os.unlink(filename)  # remove dummy file*}}
            # do assertion
            with open(filename) as f:
                content = f.read()
            ok (content) == "homhom"
    
    #
    if __name__ == "__main__":
        import oktest
        oktest.main()    # NOT unittest.main() !

Notice tha you must call ``oktest.main()`` instead of ``unitetst.main``
to use ``@at_end`` decorator.

It is good idea to use ``@at_end`` instead of ``release_xxx()`` methods. ::

    import unittest
    from oktest import ok, test, {{*at_end*}}
    
    class FooTest(unittest.TestCase):
    
        _CONTENT = "homhom"
    
        def {{*provide_dummyfile*}}(self):
            # create dummy file
            filename = "dummy.tmp"
            with open(filename, 'w') as f:
                f.write(self._CONTENT)
            # register callback which is invoked at end of test case
            {{*@at_end*}}
            {{*def _():*}}
                {{*import os*}}
                {{*os.unlink(filename)  # remove dummy file*}}
            #
            return filename
    
        @test("file.read() returns content of file.")
        def _(self, {{*dummyfile*}}):
            # do assertion
            with open(dummyfile) as f:
                content = f.read()
            ok (content) == self._CONTENT
    
    if __name__ == '__main__':
        import oktest
        oktest.main()   # NOT unittest.main() !

``@at_end`` decorator is similar to ``unittest.TestCase#atCleanup()``,
but the former is called *before* ``tearDown()`` and the latter is called
*after* ``tearDown()``.
See the following example.::

    import sys, unittest
    from oktest import ok, test, at_end
    
    class HomTest(unittest.TestCase):
    
        def {{*tearDown*}}(self):
            print({{*'** tearDown'*}})
    
        def test_ex1(self):
            {{*@self.addCleanup*}}
            def _(): print({{*'** addCleanup: #1'*}})
            #
            {{*@at_end*}}
            def _(): print({{*'** at_end: #1'*}})
            #
            {{*@self.addCleanup*}}
            def _(): print({{*'** addCleanup: #2'*}})
            #
            {{*@at_end*}}
            def _(): print({{*'** at_end: #2'*}})
            #
            assert 1+1 == 2
    
    if __name__ == "__main__":
        import oktest
        oktest.main()

Result::

    $ py hom_test.py
    * HomTest
      - [      ] test_ex1{{*** at_end: #2*}}
    {{*** at_end: #1*}}
    {{*** tearDown*}}
    {{*** addCleanup: #2*}}
    {{*** addCleanup: #1*}}
      - [pass] test_ex1
    ## total:1, pass:1, fail:0, error:0, skip:0, todo:0  (0.001 sec)


Test Context
============

**(Experimental)**

Oktest provides helper functions to describe test methods in structural style. ::

    from oktest import ok, test
    {{*from oktest import subject, situation*}}

    class SampleTestCase(unittest.TestCase):
        {{*SUBJECT = "Sample"*}}

        {{*with subject("method1()"):*}}

            {{*with situation("when condition:"):*}}

                @test("spec1")
                def _(self):
                  ...

                @test("spec2")
                def _(self):
                  ...

            {{*with situation("else:"):*}}

                @test("spec3")
                def _(self):
                    ...

Output example::

    * Sample
      + method1()
        + when condition:
          - [pass] spec1
          - [pass] spec2
        + else:
          - [pass] spec3
    ## total:3, pass:3, fail:0, error:0, skip:0, todo:0  (0.000 sec)

(Notice that this feature is experimental and may be changed in the future.)


Unified Diff
============

'ok(x) == y' prints unified diff (diff -u) if:

* both x and y are one of str, unicode, list, tuple, and dict
* and x != y
* and ``oktest.DIFF`` is True or 'repr'
* and invoked with ``oktest.main()`` or ``oktest.run()``

For example::

    ## foo_test.py
    import unittest
    from oktest import ok

    class FooTest(unittest.TestCase):

        def test1(self):
            s1 = ( "AAA\n"
                   "BBB\n"
                   "CCC\n" )
            s2 = ( "AAA\n"
                   "CCC\n"
                   "DDD\n" )
            ok (s1) == s2

    if __name__ == '__main__':
        unittest.main()

If you run this script, you'll find that unified diff is displayed.

Output result::

    $ python -V
    Python 2.5.5
    $ python foo_test.py
    F
    ======================================================================
    FAIL: test1 (__main__.FooTest)
    ----------------------------------------------------------------------
    Traceback (most recent call last):
      File "foo_test.py", line 14, in test1
        ok (s1) == s2
    AssertionError: 'AAA\nBBB\nCCC\n' == 'AAA\nCCC\nDDD\n' : failed.
    --- expected
    +++ actual
    @@ -1,3 +1,3 @@
     AAA
    +BBB
     CCC
    -DDD


    ----------------------------------------------------------------------
    Ran 1 test in 0.006s

    FAILED (failures=1)

When actual and expected values are list, tuple or dict, then ``ok()`` converts
these values into string by ``pprint.pformat()`` before calculating unified
diff output. For example::

    ## json_test.py
    import unittest
    from oktest import ok
    
    class JsonTest(unittest.TestCase):
        def test_ex1(self):
            expected = { 'username': "Haruhi", 'gender': "Female",
                         'email': "haruhi@sos-brigade.org", }
            actual   = { 'username': "Haruhi", 'gender': "female",
                         'email': "haruhi@sos-brigade.org", }
            ok (actual) == expected
    #
    if __name__ == "__main__":
        unittest.main()

Result shows in unified diff format using ``pprint.pformat()``::

    $ py json_test.py
    F
    ======================================================================
    FAIL: test_ex1 (__main__.JsonTest)
    ----------------------------------------------------------------------
    Traceback (most recent call last):
      File "json_test.py", line 11, in test_ex1
        ok (actual) == expected
    AssertionError: {'username': 'Haruhi', 'gender': 'female', 'email': 'haruhi@sos
    -brigade.org'} == {'username': 'Haruhi', 'gender': 'Female', 'email': 'haruhi@s
    os-brigade.org'} : failed.
    --- expected
    +++ actual
    @@ -1,3 +1,3 @@
     {'email': 'haruhi@sos-brigade.org',
    - 'gender': 'Female',
    + 'gender': 'female',
      'username': 'Haruhi'}
    \ No newline at end of string
    
    
    ----------------------------------------------------------------------
    Ran 1 test in 0.001s
    
    FAILED (failures=1)

If you set ``oktest.DIFF`` to ``repr``, each line is preprocessed by ``repr()``.
This is very useful to show non-visible characters. For example::

    ## foo_test.py
    import unittest
    from oktest import ok
    import oktest
    {{*oktest.DIFF = repr*}}

    class FooTest(unittest.TestCase):

        def test1(self):
            s1 = ( "AAA\n"
                   {{*"BBB  \n"*}}     # contains white space character
                   "CCC\n" )
            s2 = ( "AAA\n"
                   {{*"BBB\n"*}}
                   "CCC\n" )
            ok (s1) == s2

    if __name__ == '__main__':
        unittest.main()

Result::

    $ python foo_test.py
    F
    ======================================================================
    FAIL: test1 (__main__.FooTest)
    ----------------------------------------------------------------------
    Traceback (most recent call last):
      File "foo_test.py", line 16, in test1
        ok (s1) == s2
    AssertionError: 'AAA\nBBB \nCCC\n' == 'AAA\nBBB\nCCC\n' : failed.
    --- expected
    +++ actual
    @@ -1,3 +1,3 @@
     'AAA\n'
    {{*+'BBB  \n'*}}
    {{*-'BBB\n'*}}
     'CCC\n'


    ----------------------------------------------------------------------
    Ran 1 test in 0.011s

    FAILED (failures=1)

If you set ``oktest.DIFF`` to False, unified diff is not displayed.


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
    {{*from oktest.tracer import Tracer*}}
    {{*tr = Tracer()*}}
    foo = {{*tr.fake_obj(m1=100, m2=200)*}}   # method name and return-value
    bar = {{*tr.fake_obj(m3=lambda self, x: x+1)*}}  # method name and body
    ## call fake methods
    ok (bar.m3(0))     == 1
    ok (foo.m2(1,2,3)) == 200    # any argument can be passed
    ok (foo.m1(x=123)) == 100    # any argument can be passed
    ## check results
    ok (repr({{*tr[0]*}}))   == 'm3(0) #=> 1'
    ok (repr({{*tr[1]*}}))   == 'm2(1, 2, 3) #=> 200'
    ok (repr({{*tr[2]*}}))   == 'm1(x=123) #=> 100'

There are several ways to check results::

    from oktest.tracer import Tracer
    tr = Tracer()
    obj = tr.fake_obj(meth=9)
    ok (obj.meth(1, 2, x=3)) == 9
    ## check results
    ok ({{*repr(tr[0])*}})  == 'meth(1, 2, x=3) #=> 9'
    ## or
    ok ({{*tr[0].list()*}}) == [obj, 'meth', (1, 2), {'x': 3}, 9]
    ## or
    ok ({{*tr[0]*}})        == [obj, 'meth', (1, 2), {'x': 3}, 9]
    ## or
    ok ({{*tr[0].receiver*}}).is_(obj)
    ok ({{*tr[0].name*}})   == 'meth'
    ok ({{*tr[0].args*}})   == (1, 2)
    ok ({{*tr[0].kwargs*}}) == {'x': 3}
    ok ({{*tr[0].ret*}})    == 9

Example to trace method call::

    class Foo(object):
        def add(self, x, y):
            return x + y
        def hello(self, name='World'):
            return "Hello " + name
    obj = Foo()
    ## trace methods
    from oktest.tracer import Tracer
    tr = Tracer()
    {{*tr.trace_method(obj, 'add', 'hello')*}}
    ## call methods
    ok (obj.add(2, 3)) == 5
    ok (obj.hello(name="SOS")) == "Hello SOS"
    ## check results
    ok (tr[0]) == [obj, 'add', (2, 3), {}, 5]
    ok (tr[1]) == [obj, 'hello', (), {'name':'SOS'}, "Hello SOS"]

Example to trace function call::

    def f(x):
        return x+1
    def g(y):
        return f(y+1) + 1
    ## trace functions
    from oktest.tracer import Tracer
    tr = Tracer()
    {{*f = tr.trace_func(f)*}}
    {{*g = tr.trace_func(g)*}}
    ## call functions
    ok (g(0)) == 3
    ## check results
    ok (tr[0]) == [None, 'g', (0,), {}, 3]
    ok (tr[1]) == [None, 'f', (1,), {}, 2]

Example to fake method call::

    class Foo(object):
        def add(self, x, y):
            return x + y
        def hello(self, name='World'):
            return "Hello " + name
    obj = Foo()
    ## fake methods
    from oktest.tracer import Tracer
    tr = Tracer()
    def dummy(original_func, *args, **kwargs):
        return "Hello!"
    {{*tr.fake_method(obj, add=100, hello=dummy)*}}
    ## call methods
    ok (obj.add(2, 3)) == 100
    ok (obj.hello(name="SOS")) == "Hello!"
    ## check results
    ok (tr[0]) == [obj, 'add', (2, 3), {}, 100]
    ok (tr[1]) == [obj, 'hello', (), {'name':"SOS"}, "Hello!"]

Example to fake function call::

    def f(x):
        return x*2
    ## fake a function
    def dummy(original_func, x):
        return 'x=%s' % repr(x)
    from oktest.tracer import Tracer
    tr = Tracer()
    {{*f = tr.fake_func(f, dummy)*}}
    ## call function
    ok (f(3))  == 'x=3'
    ## check results
    ok (tr[0]) == [None, 'f', (3,), {}, 'x=3']


Skip Test
=========

**(Experimental)**

It is possible to skip tests according to a certain condition. ::

    import unittest
    import oktest
    from oktest import ok, test, {{*skip*}}
    some_condition = True

    class SkipExampleTest(unittest.TestCase):

        @test("example of skip")
        def _(self):
            if some_condition:
                {{*skip("reason to skip")*}}
            ...

        @test("example of skip")
        {{*@skip.when(some_condition, "reason to skip")*}}
        def _(self):
            ...

        ## unittest2 helpers are also available (if you installed it)
        @unittest.skipIf(some_condition, "reason to skip")
        def testExample(self):
            ...

    if __name__ == '__main__':
        oktest.main()

Notice that the following doesn't work correctly. ::

        ## NG: @skip.when should be the below of @test
        @skip.when(some_condition, "reason to skip")
        @test("example of skip")
        def _(self):
            ...


``@todo`` Decorator
===================

``@todo`` decorator represents that "this test will be failed expectedly
because feature is not implemented yet, therefore don't count
this test as failed, please!".

Code Example::

    import unittest
    from oktest import ok, test, {{*todo*}}

    def add(x, y):
        return 0    ## not implemented yet!

    class AddTest(unittest.TestCase):
        SUBJECT = 'add()'

        @test("returns sum of arguments.")
        {{*@todo*}}      # equivarent to @unittest.expectedFailure
        def _(self):
            n = add(10, 20)
            ok (n) == 30    # will be failed expectedly
                            # (because add() is not implemented yet)

    if __name__ == '__main__':
        import oktest
        oktest.main()

Output Example::

    $ python test/add_test.py
    * add()
      - [TODO] returns sum of arguments.
    ## total:1, pass:0, fail:0, error:0, skip:0, todo:1  (0.000 sec)

If test decoreated by ``@todo`` doesn't raise AssertionError, Oktest will report
you that, for example::

    $ python test/add_test.py
    * add()
      - [Fail] returns sum of arguments.
    ----------------------------------------------------------------------
    [Fail] add() > 001: returns sum of arguments.
    _UnexpectedSuccess: test should be failed (because not implemented yet), but passed unexpectedly.
    ----------------------------------------------------------------------
    ## total:1, pass:0, fail:1, error:0, skip:0, todo:0  (0.000 sec)

Notice that the following will not work::

    ## NG: @todo should be appeared after @test decorator
    @todo
    @test("....")
    def _(self): ...


Command-line Interface
======================

Oktest now supports command-line interface to execute test scripts. ::

    ## run test scripts except foo_*.py
    $ python -m oktest {{*-x 'foo_*.py' tests/*_test.py*}}
    ## run test scripts in 'tests' dir with pattern '*_test.py'
    $ python -m oktest {{*-p '*_test.py' tests*}}
    ## reports result in plain format (p: plain, s: simple, v: verbose)
    $ python -m oktest {{*-sp*}} tests
    ## filter by class name
    $ python -m oktest {{*-f class='ClassName*'*}} tests
    ## filter by test method name
    $ python -m oktest {{*-f test='*keyword*'*}} tests   # or {{*-f '*keyword*'*}}
    ## filter by user-defined option added by @test decorator
    $ python -m oktest {{*-f tag='*value*'*}} tests

Try ``python -m oktest -h`` for details about command-line options.

If you use ``oktest.main()`` in your test script, it accepts command-line options. ::

    ## reports output in plain format
    $ python test/foobar_test.py {{*-sp -f test='*keyword*'*}}


Helpers Reference
=================

.. role:: strike
    :class: strike


``oktest`` module
-----------------

fail(message)
	Raises AssertionError exception with message.

main(\*args)
	Invokes tests of each class.
	Args represents command-line options. ::

	    import oktest
	    oktest.main()         # same as: python -m oktest
	    oktest.main('-sp')    # same as: python -m oktest -sp

NG(actual)
	Represents test assertion.
	See `Assertion Reference`_ section.

ok(actual)
	Represents test assertion.
	See `Assertion Reference`_ section.

run(\*classes)
	Invokes tests of each class.
	Argument can be regular expression string. ::

	    import oktest
	    oktest.run(FooTest, BarTest)  # invokes FooTest and BarTest
	    oktest.run(r'.*Test$')        # invokes FooTest, BarTest, and so on
	    oktest.run()                  # same as oktest.run('.*(Test|TestCase|_TC)$')

subject(name)
	Represents subject of specs such as ClassName, method_name() or feature name.
	See `Test Context`_ section.

situation(desc)
	Represents situation of specs such as a certain condition.
	See `Test Context`_ section.

spec(description)
	:strike:`(Obsolete! Don't use this!)`
	NOT OBSOLETED

	Represents spec description.
	This is just a marker function, but very useful for readability. ::

	    class NumericTest(object):
	        def test_integer(self):
	            with spec("1+1 should be equal to 2."):
	                ok (1+1) == 2
	            with spec("1/0 should be error."):
	                def f(): 1/0
	                ok (f).raises(ZeroDivisionError,
	                              "integer division or modulo by zero")
	            ## spec() is also available as decorator
	            @spec("1+1 should be equal to 2.")
		    def _():
	                ok (1+1) == 2
	            ## tips: 'for' statement is available instead of 'with' for Python 2.4
	            for _ in spec("1+1 should be equal to 2."):
	                ok (1+1) == 2

skip(reason)
	Skip test method.
	Equivarent to ``unittest.skip()`` or ``unittest.skipIf()``.
	See `Skip Test`_ section.

test(desc)
	Decorator to generate test method with spec description.
	See `@test Decorator`_ section.

todo()
	Represents that the test will be failed expectedly.
	Equivarent to ``unittest.expectedFailure()``.
	See `@todo Decorator`_ section.


``oktest.util`` module
------------------------

Since 0.10.0, ``oktest.helper`` is renamed to ``oktest.util``, but
``oktest.helper`` is still available for backward compatibility.


chdir(dirname)
	Change current directory to dirname temporarily. ::

	    import os
	    from oktest.util import chdir
	    cwd = os.getcwd()                         # current working directory
	    with chdir("/var/tmp"):
	        assert os.getcwd() == "/var/tmp"      # current directory is changed!
	        # do something
	    assert os.getcwd() == cwd                 # back to the original place
	    ## or
	    @chdir("/var/tmp")
	    def fn():
	        assert os.getcwd() == "/var/tmp"
	        # do something

rm_rf(filename, dirname, ...)
	Remove file or directory recursively.

from_here(dirpath=None)
	Set current directory as the first element of sys.path temporarily.
	This is useful very much when you want to import a certain module
	from current directory or a specific directory. ::
	
	    from oktest.util import from_here
	    with from_here():
	      import mymodule1       # import from directory path of this file
	    with from_here('../lib'):
	      import mymodule2       # import from ../lib

randstr(n=8)
	Return random number string which width is n (default 8).
	This is useful when creating fixture data. ::
	
	    >>> from oktest.util import randstr
	    >>> randstr(4)
	    '7327'
	    >>> randstr(4)
	    '1598'
	    >>> randstr(4)
	    '0362'
	    >>> randstr()
	    '38127841'


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
	    @dummy_file("A.txt", "aaa")
	    def fn():
	        assert os.path.isfile("A.txt")

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
	    @dummy_dir("tmpdir")
	    def fn():
	        assert os.path.isdir("tmpdir")

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
	    @dummy_values(d, A=1000, X=2000)
	    def fn():
	        assert d['A'] == 1000

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
	    @dummy_attrs(obj, x=90, z=100)
	    def fn():
	        assert obj.x == 90

dummy_io(stdin_content=None, func=None):
	Set dummy I/O to sys.stdout, sys.stderr, and sys.stdin. ::

	    with dummy_io("SOS") as d_io:
	        assert sys.stdin.read() == "SOS"
	        print("Haruhi")
	    sout, serr = d_io
	    assert sout == "Haruhi\n"
	    assert serr == ""
	    ## or
	    @dummy_io("SOS")
	    def d_io():
	        assert sys.stdin.read() == "SOS"
	        print("Haruhi")
	    sout, serr = d_io
	    assert sout == "Haruhi\n"
	    assert serr == ""


``oktest.tracer`` module
------------------------

Tracer:
	Tracer class. See `Tracer`_ section for details.


Tips
====

* You can define your own custom assertion function. ::

    ## define custom assertion function
    import oktest
    {{*@oktest.assertion*}}
    def startswith(self, arg):
        boolean = {{*self.target*}}.startswith(arg)
        if boolean == {{*self.boolean*}}:
            return True
        {{*self.failed*}}("%r.startswith(%r) : failed." % (self.target, arg))

    ## how to use
    from oktest import ok
    ok ("Sasaki").startswith("Sas")

* It is possible to chain assertion methods. ::

    ## chain assertion methods
    ok (func()).is_a(tuple).length(2)
    d = datetime.date(2000, 12, 31)
    ok (d).attr('year', 2000).attr('month', 12).attr('day', 31)

* ``oktest.run()`` returns total number of failures and errors. ::

    ## exit with status code 0 when no errors.
    sys.exit(run())

* If you call ``ok()`` or ``NG()`` but forget to do assertion, oktest warns it. ::

    import oktest
    from oktest import ok, NG

    class FooTest(object):
        def test_1(self):
            #ok (1+1) == 2
            ok (1+1)         # missing assertion

    oktest.run()   #=> warning: ok() is called but not tested.

* ``$TEST`` environment variable is now obsolete.
  Use command-line option instead to filter testcase by name. ::

      ## filter testcase by name
      $ python -m oktest -f test='*foobar*' test/foo_test.py


License
=======

$License: MIT License $


Copyright
=========

$Copyright: copyright(c) 2010-2013 kuwata-lab.com all rights reserved $

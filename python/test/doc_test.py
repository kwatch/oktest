import re
from oktest import ok

if True:

#Tracer
#======

#Oktest provides ``Tracer`` class which can be stub or mock object.
#``Tracer`` class can:

#* Create fake object.
#* Trace method or function call.
#* Fake method, or function.

#In any case, ``Tracer`` object records both arguments and return-value of method or function calls.

#Example to create fake object::

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

#There are several ways to check results::

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

#Example to trace method call::

    class Foo(object):
        def add(self, x, y):
            return x + y
        def hello(self, name='World'):
            return "Hello " + name
    obj = Foo()
    ## trace methods
    from oktest.tracer import Tracer
    tr = Tracer()
    tr.trace_method(obj, 'add', 'hello')
    ## call methods
    ok (obj.add(2, 3)) == 5
    ok (obj.hello(name="SOS")) == "Hello SOS"
    ## check results
    ok (tr[0]) == [obj, 'add', (2, 3), {}, 5]
    ok (tr[1]) == [obj, 'hello', (), {'name':'SOS'}, "Hello SOS"]

#Example to trace function call::

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

#Example to fake method call::

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
    tr.fake_method(obj, add=100, hello=dummy)
    ## call methods
    ok (obj.add(2, 3)) == 100
    ok (obj.hello(name="SOS")) == "Hello!"
    ## check results
    ok (tr[0]) == [obj, 'add', (2, 3), {}, 100]
    ok (tr[1]) == [obj, 'hello', (), {'name':"SOS"}, "Hello!"]

#Example to fake function call::

    def f(x):
        return x*2
    ## fake a function
    def dummy(original_func, x):
        return 'x=%s' % repr(x)
    from oktest.tracer import Tracer
    tr = Tracer()
    f = tr.fake_func(f, dummy)
    ## call function
    ok (f(3))  == 'x=3'
    ## check results
    ok (tr[0]) == [None, 'f', (3,), {}, 'x=3']


#Command-line Interface
#======================

#Oktest now supports command-line interface to execute test scripts. ::

    ## run test scripts except foo_*.py
    #$ python -m oktest -x 'foo_*.py' tests/*_test.py
    ## run test scripts in 'tests' dir with pattern '*_test.py'
    #$ python -m oktest -p '*_test.py' tests
    ## filter by class name
    #$ python -m oktest -f class='ClassName*' tests
    ## filter by test method name
    #$ python -m oktest -f test='*keyword*' tests   # or -f '*keyword*'
    ## filter by user-defined option added by @test decorator
    #$ python -m oktest -f tag='*value*' tests

#Try ``python -m oktest -h`` for details about command-line options.


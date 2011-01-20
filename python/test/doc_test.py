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
    foo = tr.fake_obj(m1=100, m2=200)
    bar = tr.fake_obj(m3=lambda self, x: x+1)
    ## call fake methods
    ok (bar.m3(0))     == 1
    ok (foo.m2(1,2,3)) == 200
    ok (foo.m1(x=123)) == 100
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

#Example to fake function call::

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


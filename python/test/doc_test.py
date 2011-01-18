import re
from oktest import ok



if "dummy object":
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
               ok (repr(tr[0]))  == 'm3(0): 1'
               ok (repr(tr[1]))  == 'm2(1, 2, 3): 200'
               ok (repr(tr[2]))  == 'm1(x=123): 100'
               # or
               ok (tr[0].receiver).is_(bar)
               ok (tr[0].name)   == 'm3'
               ok (tr[0].args)   == (0,)
               ok (tr[0].kwargs) == {}
               ok (tr[0].ret)    == 1
               ok (list(tr[0]))  == [bar, 'm3', (0,), {}, 1]
               ok (tr[1].receiver).is_(foo)
               ok (tr[1].name)   == 'm2'
               ok (tr[1].args)   == (1, 2, 3)
               ok (tr[1].kwargs) == {}
               ok (tr[1].ret)    == 200
               ok (list(tr[1]))  == [foo, 'm2', (1, 2, 3), {}, 200]
               ok (tr[2].receiver).is_(foo)
               ok (tr[2].name)   == 'm1'
               ok (tr[2].args)   == ()
               ok (tr[2].kwargs) == {'x': 123}
               ok (tr[2].ret)    == 100
               ok (list(tr[2]))  == [foo, 'm1', (), {'x': 123}, 100]

if "trace functions":
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
               ok (g(0))         == 3
               ## check results
               ok (tr[0].name)   == 'g'
               ok (tr[0].args)   == (0,)
               ok (tr[0].kwargs) == {}
               ok (tr[0].ret)    == 3
               ok (list(tr[0]))  == [None, 'g', (0,), {}, 3]
               #
               ok (tr[1].name)   == 'f'
               ok (tr[1].args)   == (1,)
               ok (tr[1].kwargs) == {}
               ok (tr[1].ret)    == 2
               ok (list(tr[1]))  == [None, 'f', (1,), {}, 2]

if "trace methods":
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
               ok (obj.m1(1))    == 100
               ok (obj.m2(2))    == 200
               ## check results
               ok (tr[0].name)   == 'm1'
               ok (tr[0].args)   == (1,)
               ok (tr[0].kwargs) == {}
               ok (tr[0].ret)    == 100
               ok (list(tr[0]))  == [obj, 'm1', (1,), {}, 100]
               #
               ok (tr[1].name)   == 'm2'
               ok (tr[1].args)   == (2,)
               ok (tr[1].kwargs) == {}
               ok (tr[1].ret)    == 200
               ok (list(tr[1]))  == [obj, 'm2', (2,), {}, 200]

if "dummy function":
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
               f(3)             #=> 'x=3'
               ## check result
               ok (list(tr[0])) == [None, 'f', (3,), {}, 'x=3']

if "dummy method":
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
               ok (obj.m1(1))    == 100
               ok (obj.m2(2))    == 200
               ## check result
               ok (list(tr[0]))  == [obj, 'm1', (1,), {}, 100]
               ok (list(tr[1]))  == [obj, 'm2', (2,), {}, 200]
        
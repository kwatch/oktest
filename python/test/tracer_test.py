###
### $Release: $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###
#from __future__ import with_statement

import sys, os, re
import unittest

import oktest
from oktest import ok, NG, run, spec
from oktest.util import *
from oktest.tracer import Tracer, Call, FakeObject

try:
    from cStringIO import StringIO
except ImportError:
    from io import StringIO

os.environ['OKTEST_WARNING_DISABLED'] = 'true'


class Call_TC(unittest.TestCase):

    def create(self):
        return Call('o', 'n', ('a',), {'k': 1}, 'r')

    def setUp(self):
        self.call = self.create()
        self.expected = ['o', 'n', ('a',), {'k': 1}, 'r']

    def test___init__(self):
        if spec("takes receiver, name, args, kwargs, and ret."):
            obj = self.create()
            ok (obj.receiver) == 'o'
            ok (obj.name) == 'n'
            ok (obj.args) == ('a',)
            ok (obj.kwargs) == {'k': 1}
            ok (obj.ret) == 'r'

    def test__repr__(self):
        obj = self.create()
        if spec("returns readable string."):
            ok (repr(obj)) == "n('a', k=1) #=> 'r'"
        if spec("if repr style is set then changes output."):
            obj == []
            ok (repr(obj)) == "['o', 'n', ('a',), {'k': 1}, 'r']"
            obj == ()
            ok (repr(obj)) == "('o', 'n', ('a',), {'k': 1}, 'r')"

    def test__iter__(self):
        if spec("returns attribute values."):
            obj = self.create()
            arr = [ x for x in obj ]
            ok (arr) == self.expected

    def test_list(self):
        if spec("returns a list which contains attribute values."):
            obj = self.create()
            ok (obj.list()) == self.expected

    def test_list(self):
        if spec("returns a list which contains attribute values."):
            obj = self.create()
            ok (obj.tuple()) == tuple(self.expected)

    def test___eq__(self):
        if spec("able to compare with a list."):
            obj = self.create()
            ok (obj == self.expected)          == True
            ok (obj == self.expected + [None]) == False
        if spec("able to compare with a tuple."):
            obj = self.create()
            ok (obj == tuple(self.expected))          == True
            ok (obj == tuple(self.expected + [None])) == False
        if spec("able to cmpare with a Call instance."):
            obj = self.create()
            obj2  = self.create()
            ok (obj == obj2) == True
            obj2.name = 'x'
            ok (obj == obj2) == False

    def test___ne__(self):
        if spec("returns opposite value of __eq__()."):
            obj = self.create()
            obj.name = 'x'
            ok (obj == self.expected) == False
            ok (obj != self.expected) == True
            arr = self.expected + [None]
            ok (obj == self.expected) == False
            ok (obj != self.expected) == True


class FakeObject_TC(unittest.TestCase):

    def test___init__(self):
        if spec("takes keyword args as dummy method definitions."):
            obj = FakeObject(a=1, b='foo')
            ok (obj.a()) == 1
            ok (obj.b()) == 'foo'

    def test___new_method(self):
        obj = FakeObject(a=lambda self, x: x+1,
                          b=[1, None])
        if spec("accepts function object as dummy method."):
            ok (obj.a(1)) == 2
            ok (obj.a(x=1)) == 2
        if spec("accepts any value as return value of dummy method."):
            ok (obj.b()) == [1, None]
        if spec("sets methods name correctly."):
            ok (obj.a.__name__) == 'a'
            ok (obj.b.__name__) == 'b'
        if spec("configures to record method calls."):
            calls = obj._calls
            ok (calls[0]) == [obj, 'a', (1,), {}, 2]
            ok (calls[1]) == [obj, 'a', (), {'x': 1}, 2]
            ok (calls[2]) == [obj, 'b', (), {}, [1, None]]


class DummyObj(object):

    def hello(self, name='World'):
        return "Hello %s!" % name

    def bye(self):
        return "Bye!"


class Tracer_TC(unittest.TestCase):

    def test___getitem__(self):
        tr = Tracer()
        tr.calls.append(10)
        tr.calls.append(False)
        if spec("returns call object."):
            ok (tr[0]) == 10
            ok (tr[1]) == False
        if spec("raises error if index is out of range."):
            def f(): tr[3]
            ok (f).raises(IndexError, "list index out of range")

    def test___len__(self):
        if spec("returns length of call objects."):
            tr = Tracer()
            ok (len(tr)) == 0
            tr.calls.append(10)
            tr.calls.append(20)
            ok (len(tr)) == 2

    def test__iter__(self):
        if spec("iterates over call objects."):
            tr = Tracer()
            tr.calls.append(10)
            tr.calls.append(20)
            ok ([ x for x in tr ]) == [10, 20]

    def test_trace_func(self):
        tr = Tracer()
        def f1(x, y=1):
            """returns x+y"""
            return x+y
        if spec("accepts function object and returns new one."):
            f2 = tr.trace_func(f1)
            ok (f2).is_not(f1)
            ok (f2(3)) == 4
            ok (f2(3, y=2)) == 5
        if spec("returned function has same name and desc as original."):
            ok (f2.__name__) == 'f1'
            ok (f2.__doc__) == """returns x+y"""
        if spec("function calls are recorded into tracer object."):
            ok (tr[0]) == [None, 'f1', (3,), {}, 4]
            ok (tr[1]) == [None, 'f1', (3,), {'y': 2}, 5]

    def test_fake_func(self):
        tr = Tracer()
        def f3(a, b=10):
            """returns a*b"""
            return a*b
        f4 = tr.fake_func(f3, lambda *args, **kwargs: [args, kwargs])
        if spec("accepts function and body and returns new one."):
            ok (f4(3, b=4)) == [(f3, 3), {'b': 4}]
        if spec("returned function has same name and desc as original."):
            ok (f4.__name__) == 'f3'
            ok (f4.__doc__) == """returns a*b"""
        if spec("function calls are recorded into tracer object."):
            ok (tr[0]) == [None, 'f3', (3,), {'b': 4}, [(f3, 3), {'b': 4}]]

    def test_trace_method(self):
        tr = Tracer()
        obj = DummyObj()
        ret = tr.trace_method(obj, 'hello', 'bye')
        if spec("returns None"):
            ok (ret) == None
        if spec("not change behaviour of traced method."):
            ok (obj.bye()) == "Bye!"
            ok (obj.hello('Haruhi')) == "Hello Haruhi!"
        if spec("traces method calls into trace object."):
            ok (tr[0]) == [obj, 'bye', (), {}, "Bye!"]
            ok (tr[1]) == [obj, 'hello', ('Haruhi',), {}, "Hello Haruhi!"]
        if spec("raises NameError when specified method is not found."):
            def fn(): tr.trace_method(obj, 'foobarbaz')
            ok (fn).raises(NameError, re.compile(r"^foobarbaz: method not found on "))

    def test_fake_method(self):
        tr = Tracer()
        obj = DummyObj()
        orig_bye = obj.bye
        def hello2(original, *a, **k):
            val = original(*a, **k)
            return "<<%r>>" % (val, )
        ret = tr.fake_method(obj, hello=hello2, bye=lambda *a, **k: [a, k])
        if spec("returns None"):
            ok (ret) == None
        if spec("fake method takes original bound method as 1st argument."):
            ok (obj.bye(123, x=999)) == [(orig_bye, 123), {'x': 999}]
        if spec("changes behaviour of methods."):
            ok (obj.hello('Haruhi')) == "<<'Hello Haruhi!'>>"
        if spec("traces method calls into trace object."):
            ok (tr[0]) == [obj, "bye", (123,), {'x': 999}, [(orig_bye, 123), {'x': 999}]]
            ok (tr[1]) == [obj, "hello", ("Haruhi",), {}, "<<'Hello Haruhi!'>>"]

    def test_trace(self):
        tr = Tracer()
        if spec("calls trace_func() if arg is a function."):
            def f1(x): return x+1
            f2 = tr.trace(f1)
            ok (f2(4)) == 5
            ok (tr[0]) == [None, 'f1', (4,), {}, 5]
        if spec("calls trace_method() if arg is an object."):
            obj = DummyObj()
            tr.trace(obj, "hello", "bye")
            ok (obj.hello("Sasaki")) == "Hello Sasaki!"
            ok (tr[1]) == [obj, "hello", ("Sasaki",), {}, "Hello Sasaki!"]

    def test_fake(self):
        tr = Tracer()
        if spec("calls fake_func() if arg is a function."):
            def f3(x): return x*2
            f4 = tr.fake(f3, lambda original, y: y*3)
            ok (f4(10)) == 30
            ok (tr[0]) == [None, 'f3', (10,), {}, 30]
        if spec("calls fake_method() if arg is an object"):
            obj = DummyObj()
            tr.fake(obj, bye=lambda original, *args: "BYE!")
            ok (obj.bye()) == "BYE!"
            ok (tr[1]) == [obj, "bye", (), {}, "BYE!"]

    def test_fake_obj(self):
        tr = Tracer()
        obj = tr.fake_obj(a='Hello', b=lambda self, x, y: x+y)
        if spec("returns a fake object."):
            ok (obj.a()) == 'Hello'
            ok (obj.b(10, 20)) == 30
        if spec("traces method calls into trace object."):
            ok (tr[0]) == [obj, "a", (), {}, "Hello"]
            ok (tr[1]) == [obj, "b", (10, 20), {}, 30]




class Tracer_UseCase(unittest.TestCase):    # moved from oktest_test.py

    def do_test_with(self, desc, script, expected):
        sys_stdout = sys.stdout
        sys.stdout = StringIO()
        try:
            gvars = {}
            exec(script, gvars, gvars)
            output = sys.stdout.getvalue()
            self.assertEqual(expected, output)
        finally:
            sys.stdout = sys_stdout

    def test_trace_function(self):
        ### Tracer (function)
        desc = "Tracer (function)"
        script = r"""
from oktest import *
from oktest.tracer import Tracer
def f1(a, b):
    return f2(a + f3(b))
def f2(a):
    return a+2
def f3(b):
    return b*2
tr = Tracer()
f1 = tr.trace_func(f1)
f2 = tr.trace_func(f2)
f3 = tr.trace(f3)
print(f1(3, 5))
for call in tr:
    print("---")
    print(repr(call))
    print(repr(call.receiver))
    print(repr(call.name))
    print(repr(call.args))
    print(repr(call.kwargs))
    print(repr(call.ret))
"""[1:]
        expected = """
15
---
f1(3, 5) #=> 15
None
'f1'
(3, 5)
{}
15
---
f3(5) #=> 10
None
'f3'
(5,)
{}
10
---
f2(13) #=> 15
None
'f2'
(13,)
{}
15
"""[1:]
        self.do_test_with(desc, script, expected)


    def test_trace_instance_method(self):
        ### Tracer (instance method)
        desc = "Tracer (instance method)"
        script = r"""
from oktest import *
from oktest.tracer import Tracer
class Dummy(object):
    def f1(self, x, y):
        return [self.f2(x, y=y),
                self.f2(y, y=x)]
    def f2(self, x=None, y=None):
        return x-y
obj = Dummy()
tr = Tracer()
tr.trace_method(obj, 'f1', 'f2')
ret = obj.f1(5, 3)
print(ret)
for call in tr:
    print('---')
    print(repr(call))
    print(call.receiver is obj)
    print(repr(call.name))
    print(repr(call.args))
    print(repr(call.kwargs))
    print(repr(call.ret))
"""[1:]
        expected = """
[2, -2]
---
f1(5, 3) #=> [2, -2]
True
'f1'
(5, 3)
{}
[2, -2]
---
f2(5, y=3) #=> 2
True
'f2'
(5,)
{'y': 3}
2
---
f2(3, y=5) #=> -2
True
'f2'
(3,)
{'y': 5}
-2
"""[1:]
        self.do_test_with(desc, script, expected)


    def test_trace_class_method(self):
        ### Tracer (class method)
        desc = "Tracer (class method)"
        script = r"""
from oktest import *
from oktest.tracer import Tracer
class Dummy(object):
    @classmethod
    def f1(cls, x, y):
        return [cls.__name__,
                cls.f2(x, y=y),
                cls.f2(y, y=x)]
    @classmethod
    def f2(cls, x=None, y=None):
        return x-y
tr = Tracer()
tr.trace_method(Dummy, 'f1', 'f2')
ret = Dummy.f1(5, 3)
print(ret)
for call in tr:
    print("---")
    print(repr(call))
    print(call.receiver is Dummy)
    print(repr(call.name))
    print(repr(call.args))
    print(repr(call.kwargs))
    print(repr(call.ret))
"""[1:]
        expected = """
['Dummy', 2, -2]
---
f1(5, 3) #=> ['Dummy', 2, -2]
True
'f1'
(5, 3)
{}
['Dummy', 2, -2]
---
f2(5, y=3) #=> 2
True
'f2'
(5,)
{'y': 3}
2
---
f2(3, y=5) #=> -2
True
'f2'
(3,)
{'y': 5}
-2
"""[1:]
        self.do_test_with(desc, script, expected)


    def test_trace_in_repr_style(self):
        ### Tracer (repr style)
        desc = "Tracer (repr style)"
        script = r"""
from oktest import *
from oktest.tracer import Tracer
class Dummy(object):
    def f1(self, *args, **kwargs):
        return 1
    def __repr__(self):
        return '#<Dummy>'
tr = Tracer()
obj = Dummy()
tr.trace_method(obj, 'f1')
obj.f1(10,20,x=30)
print(repr(tr[0]))
tr[0] == []
print(repr(tr[0]))
tr[0] == ()
print(repr(tr[0]))
"""[1:]
        expected = """
f1(10, 20, x=30) #=> 1
[#<Dummy>, 'f1', (10, 20), {'x': 30}, 1]
(#<Dummy>, 'f1', (10, 20), {'x': 30}, 1)
"""[1:]
        self.do_test_with(desc, script, expected)


    def test_fake(self):
        ### Tracer (fake)
        desc = "Tracer (fake_func)"
        script = r"""
from oktest import *
from oktest.tracer import Tracer
def f(x, y, z=0):
    return x + y + z
def block(orig, *args, **kwargs):
    v = orig(*args, **kwargs)
    return 'v=%s' % v
tr = Tracer()
f = tr.fake_func(f, block)
print(f(10, 20, z=7))  #=> 'v=37'
print(repr(tr[0]))   #=> f(10, 20, z=7) #=> 'v=37'
print(tr[0].receiver is None)  #=> True
print(tr[0].name)    #=> f
print(tr[0].args)    #=> (10, 20)
print(tr[0].kwargs)  #=> {'z': 7}
print(tr[0].ret)     #=> 'v=37'
print('---')
class Hello(object):
    def hello(self, name):
        return 'Hello %s!' % name
    def hi(self):
        pass
obj = Hello()
tr.fake_method(obj, hello=block, hi="Hi!", ya="Ya!")
print(obj.hello('World'))  #=> v=Hello World!
print(repr(tr[1]))    #=> hello('World') #=> 'v=Hello World!'
print(tr[1].receiver is obj)  #=> True
print(tr[1].name)     #=> hello
print(tr[1].args)     #=> ('World',)
print(tr[1].kwargs)   #=> {}
print(tr[1].ret)      #=> v=Hello World!
print('---')
print(obj.hi('SOS'))  #=> Hi!
print(repr(tr[2]))    #=> hi('SOS') #=> 'Hi!'
print(tr[2].receiver is obj)  #=> True
print(tr[2].name)     #=> hi
print(tr[2].args)     #=> ('SOS',)
print(tr[2].kwargs)   #=> {}
print(tr[2].ret)      #=> Hi!
print('---')
print(obj.ya('SOS'))  #=> Ya!
print(repr(tr[3]))    #=> ya('SOS') #=> 'Ya!'
print(tr[3].receiver is obj)  #=> True
print(tr[3].name)     #=> ya
print(tr[3].args)     #=> ('SOS',)
print(tr[3].kwargs)   #=> {}
print(tr[3].ret)      #=> Ya!
"""[1:]
        expected = """
v=37
f(10, 20, z=7) #=> 'v=37'
True
f
(10, 20)
{'z': 7}
v=37
---
v=Hello World!
hello('World') #=> 'v=Hello World!'
True
hello
('World',)
{}
v=Hello World!
---
Hi!
hi('SOS') #=> 'Hi!'
True
hi
('SOS',)
{}
Hi!
---
Ya!
ya('SOS') #=> 'Ya!'
True
ya
('SOS',)
{}
Ya!
"""[1:]
        self.do_test_with(desc, script, expected)


    def test_FakeObject(self):
        ### FakeObject class
        desc = "FakeObject class"
        script = r"""
from oktest import ok
from oktest.tracer import FakeObject
obj = FakeObject(hi="Hi", hello=lambda self, x: "Hello %s!" % x)
ok (obj.hi()) == 'Hi'
ok (obj.hello("SOS")) == 'Hello SOS!'
ok (obj._calls[0].name  ) == 'hi'
ok (obj._calls[0].args  ) == ()
ok (obj._calls[0].kwargs) == {}
ok (obj._calls[0].ret   ) == 'Hi'
ok (obj._calls[1].name  ) == 'hello'
ok (obj._calls[1].args  ) == ('SOS', )
ok (obj._calls[1].kwargs) == {}
ok (obj._calls[1].ret   ) == 'Hello SOS!'
print("OK")
"""[1:]
        expected = "OK\n"
        self.do_test_with(desc, script, expected)


    def test_fake_obj(self):
        ### Tracer.fake_obj()
        desc = "Tracer.fake_obj()"
        script = r"""
from oktest import *
from oktest.tracer import Tracer
tr = Tracer()
## create dummy object
obj1 = tr.fake_obj(hi="Hi!")
obj2 = tr.fake_obj(hello=lambda self, x: "Hello %s!" % x)
## call dummy method
ok (obj2.hello("SOS")) == 'Hello SOS!'
ok (obj1.hi())         == 'Hi!'
## check result
ok (tr[0].name  ) == 'hello'
ok (tr[0].args  ) == ('SOS', )
ok (tr[0].kwargs) == {}
ok (tr[0].ret   ) == 'Hello SOS!'
ok (tr[1].name  ) == 'hi'
ok (tr[1].args  ) == ()
ok (tr[1].kwargs) == {}
ok (tr[1].ret   ) == 'Hi!'
## __iter__() and __eq__()
ok (tr[0].list())  == [obj2, 'hello', ('SOS',), {}, 'Hello SOS!']
ok (tr[0])         == [obj2, 'hello', ('SOS',), {}, 'Hello SOS!']
ok (tr[1].tuple()) == (obj1, 'hi', (), {}, 'Hi!')
ok (tr[1])         == (obj1, 'hi', (), {}, 'Hi!')
print("OK")
"""[1:]
        expected = "OK\n"
        self.do_test_with(desc, script, expected)



if __name__ == '__main__':
    unittest.main()

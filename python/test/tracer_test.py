###
### $Release: 0.8.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###
from __future__ import with_statement

import sys, os, re
import unittest

import oktest
from oktest import ok, NG, run, spec
from oktest.helper import *
from oktest.tracer import Tracer, Call, FakeObject


class Call_TC(unittest.TestCase):

    def create(self):
        return Call('o', 'n', ('a',), {'k': 1}, 'r')

    def setUp(self):
        self.call = self.create()
        self.expected = ['o', 'n', ('a',), {'k': 1}, 'r']

    def test___init__(self):
        with spec("takes receiver, name, args, kwargs, and ret."):
            obj = self.create()
            ok (obj.receiver) == 'o'
            ok (obj.name) == 'n'
            ok (obj.args) == ('a',)
            ok (obj.kwargs) == {'k': 1}
            ok (obj.ret) == 'r'

    def test__repr__(self):
        obj = self.create()
        with spec("returns readable string."):
            ok (repr(obj)) == "n('a', k=1) #=> 'r'"
        with spec("if repr style is set then changes output."):
            obj == []
            ok (repr(obj)) == "['o', 'n', ('a',), {'k': 1}, 'r']"
            obj == ()
            ok (repr(obj)) == "('o', 'n', ('a',), {'k': 1}, 'r')"

    def test__iter__(self):
        with spec("returns attribute values."):
            obj = self.create()
            arr = [ x for x in obj ]
            ok (arr) == self.expected

    def test_list(self):
        with spec("returns a list which contains attribute values."):
            obj = self.create()
            ok (obj.list()) == self.expected

    def test_list(self):
        with spec("returns a list which contains attribute values."):
            obj = self.create()
            ok (obj.tuple()) == tuple(self.expected)

    def test___eq__(self):
        with spec("able to compare with a list."):
            obj = self.create()
            ok (obj == self.expected)          == True
            ok (obj == self.expected + [None]) == False
        with spec("able to compare with a tuple."):
            obj = self.create()
            ok (obj == tuple(self.expected))          == True
            ok (obj == tuple(self.expected + [None])) == False
        with spec("able to cmpare with a Call instance."):
            obj = self.create()
            obj2  = self.create()
            ok (obj == obj2) == True
            obj2.name = 'x'
            ok (obj == obj2) == False

    def test___ne__(self):
        with spec("returns opposite value of __eq__()."):
            obj = self.create()
            obj.name = 'x'
            ok (obj == self.expected) == False
            ok (obj != self.expected) == True
            arr = self.expected + [None]
            ok (obj == self.expected) == False
            ok (obj != self.expected) == True


class FakeObject_TC(unittest.TestCase):

    def test___init__(self):
        with spec("takes keyword args as dummy method definitions."):
            obj = FakeObject(a=1, b='foo')
            ok (obj.a()) == 1
            ok (obj.b()) == 'foo'

    def test___new_method(self):
        obj = FakeObject(a=lambda self, x: x+1,
                          b=[1, None])
        with spec("accepts function object as dummy method."):
            ok (obj.a(1)) == 2
            ok (obj.a(x=1)) == 2
        with spec("accepts any value as return value of dummy method."):
            ok (obj.b()) == [1, None]
        with spec("sets methods name correctly."):
            ok (obj.a.__name__) == 'a'
            ok (obj.b.__name__) == 'b'
        with spec("configures to record method calls."):
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
        with spec("returns call object."):
            ok (tr[0]) == 10
            ok (tr[1]) == False
        with spec("raises error if index is out of range."):
            def f(): tr[3]
            ok (f).raises(IndexError, "list index out of range")

    def test___len__(self):
        with spec("returns length of call objects."):
            tr = Tracer()
            ok (len(tr)) == 0
            tr.calls.append(10)
            tr.calls.append(20)
            ok (len(tr)) == 2

    def test__iter__(self):
        with spec("iterates over call objects."):
            tr = Tracer()
            tr.calls.append(10)
            tr.calls.append(20)
            ok ([ x for x in tr ]) == [10, 20]

    def test_trace_func(self):
        tr = Tracer()
        def f1(x, y=1):
            """returns x+y"""
            return x+y
        with spec("accepts function object and returns new one."):
            f2 = tr.trace_func(f1)
            ok (f2).is_not(f1)
            ok (f2(3)) == 4
            ok (f2(3, y=2)) == 5
        with spec("returned function has same name and desc as original."):
            ok (f2.__name__) == 'f1'
            ok (f2.__doc__) == """returns x+y"""
        with spec("function calls are recorded into tracer object."):
            ok (tr[0]) == [None, 'f1', (3,), {}, 4]
            ok (tr[1]) == [None, 'f1', (3,), {'y': 2}, 5]

    def test_fake_func(self):
        tr = Tracer()
        def f3(a, b=10):
            """returns a*b"""
            return a*b
        f4 = tr.fake_func(f3, lambda *args, **kwargs: [args, kwargs])
        with spec("accepts function and body and returns new one."):
            ok (f4(3, b=4)) == [(f3, 3), {'b': 4}]
        with spec("returned function has same name and desc as original."):
            ok (f4.__name__) == 'f3'
            ok (f4.__doc__) == """returns a*b"""
        with spec("function calls are recorded into tracer object."):
            ok (tr[0]) == [None, 'f3', (3,), {'b': 4}, [(f3, 3), {'b': 4}]]

    def test_trace_method(self):
        tr = Tracer()
        obj = DummyObj()
        ret = tr.trace_method(obj, 'hello', 'bye')
        with spec("returns None"):
            ok (ret) == None
        with spec("not change behaviour of traced method."):
            ok (obj.bye()) == "Bye!"
            ok (obj.hello('Haruhi')) == "Hello Haruhi!"
        with spec("traces method calls into trace object."):
            ok (tr[0]) == [obj, 'bye', (), {}, "Bye!"]
            ok (tr[1]) == [obj, 'hello', ('Haruhi',), {}, "Hello Haruhi!"]

    def test_fake_method(self):
        tr = Tracer()
        obj = DummyObj()
        orig_bye = obj.bye
        def hello2(original, *a, **k):
            val = original(*a, **k)
            return "<<%r>>" % (val, )
        ret = tr.fake_method(obj, hello=hello2, bye=lambda *a, **k: [a, k])
        with spec("returns None"):
            ok (ret) == None
        with spec("fake method takes original bound method as 1st argument."):
            ok (obj.bye(123, x=999)) == [(orig_bye, 123), {'x': 999}]
        with spec("changes behaviour of methods."):
            ok (obj.hello('Haruhi')) == "<<'Hello Haruhi!'>>"
        with spec("traces method calls into trace object."):
            ok (tr[0]) == [obj, "bye", (123,), {'x': 999}, [(orig_bye, 123), {'x': 999}]]
            ok (tr[1]) == [obj, "hello", ("Haruhi",), {}, "<<'Hello Haruhi!'>>"]

    def test_trace(self):
        tr = Tracer()
        with spec("calls trace_func() if arg is a function."):
            def f1(x): return x+1
            f2 = tr.trace(f1)
            ok (f2(4)) == 5
            ok (tr[0]) == [None, 'f1', (4,), {}, 5]
        with spec("calls trace_method() if arg is an object."):
            obj = DummyObj()
            tr.trace(obj, "hello", "bye")
            ok (obj.hello("Sasaki")) == "Hello Sasaki!"
            ok (tr[1]) == [obj, "hello", ("Sasaki",), {}, "Hello Sasaki!"]

    def test_fake(self):
        tr = Tracer()
        with spec("calls fake_func() if arg is a function."):
            def f3(x): return x*2
            f4 = tr.fake(f3, lambda original, y: y*3)
            ok (f4(10)) == 30
            ok (tr[0]) == [None, 'f3', (10,), {}, 30]
        with spec("calls fake_method() if arg is an object"):
            obj = DummyObj()
            tr.fake(obj, bye=lambda original, *args: "BYE!")
            ok (obj.bye()) == "BYE!"
            ok (tr[1]) == [obj, "bye", (), {}, "BYE!"]

    def test_fake_obj(self):
        tr = Tracer()
        obj = tr.fake_obj(a='Hello', b=lambda self, x, y: x+y)
        with spec("returns a fake object."):
            ok (obj.a()) == 'Hello'
            ok (obj.b(10, 20)) == 30
        with spec("traces method calls into trace object."):
            ok (tr[0]) == [obj, "a", (), {}, "Hello"]
            ok (tr[1]) == [obj, "b", (10, 20), {}, 30]


if __name__ == '__main__':
    unittest.main()

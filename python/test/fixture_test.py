# -*- coding: utf-8 -*-
###
### $Release: $
### $Copyright: copyright(c) 2010-2012 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest

import oktest
from oktest import test

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3


def provide_g1():
    return {"key": "G1"}

def provide_g4():
    return {"key": "G4"}

def provide_g5(self):
    self.g5 = "G5"
    return {"key": "G5"}

_releasers_are_called = {}

def release_g1(value):
    _releasers_are_called["g1"] = value

#def release_g4():
#    pass

def release_g5(self, value):
    assert self.g5 == "G5"


class Feature_FixtureInjection_TC(unittest.TestCase):

    ##
    ## test fixtures
    ##

    def provide_item1(self):
        return {"key": "ITEM1"}

    def provide_item4(self):
        return {"key": "ITEM4"}

    def release_item1(self, value):
        self._release_item1_called = value

    #def release_item4(self):
    #    pass

    def tearDown(self):
        #
        if getattr(self, '_check_releasers_called', None):
            self._test_releasers_called()
        #
        if getattr(self, '_check_release_d_called', None):
            self._test_release_d_called()

    @test("fixtures should be set")
    def t(self, item1, g1):
        assert item1 == {"key": "ITEM1"}
        assert g1    == {"key": "G1"}

    @test("releaser functions are called if defined")
    def t(self, item1, item4, g1):
        _releasers_are_called.clear()
        assert len(_releasers_are_called) == 0
        self._check_releasers_called = True    # enable assertions in tearDown()

    def _test_releasers_called(self):
        assert hasattr(self, '_release_item1_called')
        assert self._release_item1_called == {"key": "ITEM1"}
        assert _releasers_are_called["g1"] == {"key": "G1"}

    @test("releaser function is not called if not defined")
    def t(self, item4, g4):
        pass         # nothing should be raised


    def provide_foo():
        return "<FOO>"

    @test("provider function can invoke without self.")
    def t(self, foo):
        self.assertEqual("<FOO>", foo)


    @test("global provider and releaser function can take 'self' argument.")
    def t(self, g5):
        self.assertEqual("G5", self.g5)


    global DummyFixtureManager
    class DummyFixtureManager(object):
        _values = {
            "foo": "[FOO]",
            "bar": "[BAR]",
            "baz": "[BAZ]",
        }
        def provide(self, name):
            return self._values.get(name)
        def release(self, name, value):
            self._values.pop(name, None)

    @test("if delegate fixture resolver is set then use it.")
    def t(self):
        bkup = oktest.fixture_manager
        oktest.fixture_manager = DummyFixtureManager()
        try:
            called = []
            @test("T1")
            def f(self, foo, bar, baz):
                called.append(True)
                assert (foo) == "<FOO>"  # by provide_foo()
                assert (bar) == "[BAR]"  # by DummyFixtureManager
                assert (baz) == "[BAZ]"  # by DummyFixtureManager
            f(self)
            assert (called) == [True]
            self.assertEqual([True], called)
            # is delegate.resolve() called?
            self.assertEqual({"foo": "[FOO]"}, DummyFixtureManager._values)
        finally:
            oktest.fixture_manager = bkup

    global DummyTestCase3
    class DummyTestCase3(object):
        @test("xxx")
        def _(self, foo):
            pass

    @test("raises NameError if fixture provider is not found.")
    def t(self):
        try:
            from StringIO import StringIO
        except ImportError:
            from io import StringIO
        out = StringIO()
        oktest.run(DummyTestCase3, out=out)
        output = out.getvalue()
        expected = r"""
* DummyTestCase3
  - [ERROR] xxx
----------------------------------------------------------------------
[ERROR] DummyTestCase3 > 001: xxx
NameError: Fixture provider for 'foo' not found.
----------------------------------------------------------------------
## total:1, passed:0, failed:0, error:1, skipped:0, todo:0  (0.000 sec)
"""[1:]
        output   = re.sub(r'\d\.\d\d\d sec', '0.000 sec', output)
        assert output == expected


    ##
    ## default parameter values
    ##
    def provide_para1(self, x=10, y=20):
        return [x, y]

    @test("provider can take default parameter values.")
    def t(self, para1):
        assert para1 == [10, 20]

    @test("default param value of test methods are passed into providers.")
    def t(self, para1, y=30):
        assert para1 == [10, 30]


    ##
    ## test fixture dependencies
    ##

    def provide_x(self, y1, z1):  return y1 + z1 + ["X"]
    def provide_y1(self, y2):     return y2 + ["Y1"]
    def provide_y2(self):         return ["Y2"]
    def provide_z1(self, z2):     return z2 + ["Z1"]
    def provide_z2(self):         return ["Z2"]
    def release_z1(self, val):    self._release_z1_called = val

    @test("dependencies between fixtures are solved")
    def t(self, x):
        self.assertEqual(["Y2", "Y1", "Z2", "Z1", "X"], x)

    @test("releaser function of depended fixtures are invoked.")
    def t(self, x):
        self._check_release_z1_called = True

    def _test_release_z1_called(self):
        assert hasattr(self, '_release_z1_called')
        assert self._release_z1_called == ["E", "D"]


    def provide_a(b):    return b + ["A"]
    def provide_b(c, e): return c + ["B"]
    def provide_c(d):    return d + ["C"]
    def provide_d():     return ["D"]
    def provide_e(f, g): return f + ["E"]
    def provide_f(h):    return h + ["F"]
    def provide_g(b):    return b + ["G"]   # looped
    def provide_h():     return ["F"]

    @test("detects loop in fixture dependencies.")
    def t(self):

        @test("desc1")
        def fn(self, a):
            pass
        try:
            fn(self)
        except oktest.LoopedDependencyError:
            ex = sys.exc_info()[1]
            expected = "fixture dependency is looped: a->b=>e=>g=>b (class: Feature_FixtureInjection_TC, test: 'desc1')"
            self.assertEqual(expected, str(ex))
        else:
            assert False, "LoopedDependencyError expected but not raised."



if __name__ == '__main__':
    unittest.main()

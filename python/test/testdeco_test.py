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


class TestDeco_TC(unittest.TestCase):

    ##
    ## test basic feature
    ##

    @test("demo: 2 - 1 should be 1")
    def t(self):
        assert 2 - 1 == 1

    @test("demo: 1 + 1 should be 2")
    def t(self):
        expected = 2
        assert 1 + 1 == expected

    @test("description text is used as a part of test method name")
    def t(self):
        desc = "description text is used as a part of test method name"
        #desc = re.sub(r'[^\w]', '_', desc)
        d = self.__class__.__dict__
        lst = [ k for k in d if k.find(desc) > 0 ]
        assert len(lst) == 1
        name = lst[0]
        assert hasattr(d[name], '__call__')
        assert re.match(r'^test_\d\d\d: ' + desc, name)

    @test("test methods are indexed")
    def t(self):
        d = self.__class__.__dict__
        names = [ k for k in d if k.startswith('test_') ]
        nums = []
        for name in names:
            m = re.search(r'^test_(\d+): ', name)
            assert m
            nums.append(m.group(1))
        f = open(__file__); s = f.read(); f.close()
        m = re.compile(r'^class TestDeco.*?^(class|if) ', re.M | re.S).search(s)
        n = len(list(re.finditer(r'\n    @test\(', m.group(0))))
        self.assertEqual(n, len(nums))
        assert len(nums) == n
        nums.sort()
        expected = [ "%003d" % n for n in range(1, n+1) ]
        assert nums == expected

    @test("method name is keeped when starting with 'test'.")
    def t(self):
        @test("desc1")
        def test_foo_bar(self):
            pass
        self.assertEqual("test_foo_bar", test_foo_bar.__name__)
        self.assertEqual("desc1", test_foo_bar.__doc__)
        @test("desc2")
        def testFooBar(self):
            pass
        self.assertEqual("testFooBar", testFooBar.__name__)
        self.assertEqual("desc2", testFooBar.__doc__)
        @test("desc3")
        def tst(self):
            pass
        self.assertEqual("test_003: desc3", tst.__name__)
        self.assertEqual("desc3", tst.__doc__)

    @test("description text can be None for existing test methods.")
    def t(self):
        try:
            @test(tag='test')
            def test_foo(self):
                "Description"
                pass
            self.assertTrue("Nothing raised.")
        except:
            ex_class, ex = sys.exc_info()[:2]
            self.fail("Nothing should be raised but got %s: %s" % (ex_class.__name__, ex))
        self.assertEqual({'tag': "test"}, test_foo._options)

    @test("not to override existing document of function.")
    def t(self):
        @test()
        def test_foo(self):
            "Description"
            pass
        self.assertEqual("Description", test_foo.__doc__)
        @test("new desc")
        def test_bar(self):
            "old desc"
            pass
        self.assertEqual("old desc", test_bar.__doc__)

    @test("[!xyz] regards '[!foobar]' as spec id.", tag='abc')
    def t(self):
        @test("[!abc123_-] description", tag='hom')
        def _(self):
            pass
        self.assertEqual(_._options, {'sid': 'abc123_-', 'tag': 'hom'})
        self.assertEqual(self._options, {'sid': 'xyz', 'tag': 'abc'})

    @test("日本語文字列をサポート")
    def _(self):
        assert isinstance(self._testMethodName, str)
        assert "日本語文字列をサポート" in self._testMethodName


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
            expected = "fixture dependency is looped: a->b=>e=>g=>b (class: TestDeco_TC, test: 'desc1')"
            self.assertEqual(expected, str(ex))
        else:
            assert False, "LoopedDependencyError expected but not raised."


    ##
    ## test options
    ##

    @test("set options to test object", name="Haruhi", team="SOS")
    def t(self):
        assert self._options == {"name": "Haruhi", "team": "SOS"}

    @test("set options even when fixtures are supplied", name="Sasaki", team="Tengai")
    def t(self, item1, g1):
        assert self._options == {"name": "Sasaki", "team": "Tengai"}

    def provide_item1(self):
        return {"key": "ITEM1"}



class TestDeco2_TC(unittest.TestCase):

    def provide_item1(self):
        return ["<item1>"]

    @test()
    def testWithExistingMethod(self, item1):
        """@test decorator is available with existing test methods"""
        self.assertEqual(["<item1>"], item1)

    @test("desc")
    def testWithExistingMethod2(self, item1):
        """@test decorator is available with existing test methods"""
        self.assertEqual(["<item1>"], item1)



if __name__ == '__main__':
    #unittest.main()
    suite = unittest.TestLoader().loadTestsFromTestCase(TestDeco_TC)
    suite.addTests(unittest.TestLoader().loadTestsFromTestCase(TestDeco2_TC))
    unittest.TextTestRunner(verbosity=2).run(suite)

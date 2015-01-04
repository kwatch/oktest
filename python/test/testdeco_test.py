# -*- coding: utf-8 -*-
###
### $Release: $
### $Copyright: copyright(c) 2010-2014 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest

import oktest
from oktest import test

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3



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
        if python2:
            kwargs = {}
        if python3:
            kwargs = {'encoding': 'utf-8'}
        f = open(__file__, **kwargs); s = f.read(); f.close()
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

    if python2:
        #desc1 = u"ユニコード文字列をサポート"
        desc1 = "ユニコード文字列をサポート".decode('utf-8')
        assert isinstance(desc1, unicode)
    else:
        desc1 = "ユニコード文字列をサポート"
    @test(desc1)
    def _(self):
        assert isinstance(self._testMethodName, str)
        assert "ユニコード文字列をサポート" in self._testMethodName


    ##
    ## test options
    ##

    @test("set options to test object", name="Haruhi", team="SOS")
    def t(self):
        assert self._options == {"name": "Haruhi", "team": "SOS"}

    @test("set options even when fixtures are supplied", name="Sasaki", team="Tengai")
    def t(self, item1):
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



class TestDeco3_TC(unittest.TestCase):

    def setUp(self):
        self._before_called = False
        self._after_called  = False

    def tearDown(self):
        assert self._before_called == True
        assert self._after_called  == True

    def before(self):
        self._before_called = True

    def after(self):
        self._after_called = True

    @test("[!8qkjr] decorated method calls before() and/or after() when exist.")
    def _(self):
        pass

    @test("[!271gt] decorated method calls after() even when error raised.")
    def _(self):
        @test("")
        def test1(self):
            1/0
        assert self._after_called == False
        try:
            test1(self)
        except ZeroDivisionError:
            pass
        assert self._after_called == True      # !!!

    @test("[!el8wi] decorated method skips after() when before() raised error.")
    def _(self):
        self._before_called = False
        def before():
            self._before_called = True
            1/0
        self.before = before
        #
        @test("")
        def test2(self):
            self._body_called = True
        self._body_called   = False
        #
        assert self._before_called == False
        assert self._body_called   == False
        assert self._after_called  == False
        try:
            test2(self)
        except ZeroDivisionError:
            pass
        assert self._before_called == True       # !!!
        assert self._body_called   == False
        assert self._after_called  == False      # !!!



class TestDeco4_TC(unittest.TestCase):

    def before(self, x, y, z=100):
        self._fixtures = (x, y, z)

    def after(self, x, y, z):
        assert x == 3
        assert y == 13
        assert z == 100

    def provide_x(self):
        return 3

    def provide_y(self, x):
        return x+10

    @test("[!0npfi] decorated method provides/releases fixtures.")
    def _(self, x, y):
        assert x == 3
        assert y == 13
        assert self._fixtures == (3, 13, 100)



if __name__ == '__main__':
    #unittest.main()
    suite = unittest.TestLoader().loadTestsFromTestCase(TestDeco_TC)
    for cls in (TestDeco2_TC, TestDeco3_TC, TestDeco4_TC):
        suite.addTests(unittest.TestLoader().loadTestsFromTestCase(cls))
    unittest.TextTestRunner(verbosity=2).run(suite)

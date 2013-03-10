# -*- coding: utf-8 -*-
###
### $Release: $
### $Copyright: copyright(c) 2010-2013 kuwata-lab.com all rights reserved $
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
        self.assertEqual({'tag': "test"}, test_foo._okt_tags)

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
        self.assertEqual(_._okt_tags, {'sid': 'abc123_-', 'tag': 'hom'})
        self.assertEqual(self._okt_tags, {'sid': 'xyz', 'tag': 'abc'})

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
    ## test tags
    ##

    @test("set tags to test object", name="Haruhi", team="SOS")
    def t(self):
        assert self._okt_tags == {"name": "Haruhi", "team": "SOS"}

    @test("set tags even when fixtures are supplied", name="Sasaki", team="Tengai")
    def t(self, item1):
        assert self._okt_tags == {"name": "Sasaki", "team": "Tengai"}

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

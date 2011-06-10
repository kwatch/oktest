###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest

import oktest
from oktest import test


def provide_g1():
    return {"key": "G1"}

def provide_g2(name):
    return {"key": "G2", "name": name}

def provide_g3(name, testfunc):
    return {"key": "G2", "name": name, "testfunc": testfunc}

def provide_g4():
    return {"key": "G4"}

_releasers_are_called = {}

def release_g1(value):
    _releasers_are_called["g1"] = True

def release_g2(value):
    _releasers_are_called["g2"] = value

def release_g3(value):
    _releasers_are_called["g3"] = ("g3",)

#def release_g4():
#    pass


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
        f = open(__file__)
        s = f.read()
        f.close()
        n = len(list(re.finditer(r'\n    @test\(', s)))
        assert len(nums) == n
        nums.sort()
        expected = [ "%003d" % n for n in range(1, n+1) ]
        assert nums == expected


    ##
    ## test fixtures
    ##

    def provide_item1(self):
        return {"key": "ITEM1"}

    def provide_item2(self, name):
        return {"key": "ITEM2", "name": name}

    def provide_item3(self, name, testfunc):
        return {"key": "ITEM2", "name": name, "testfunc": testfunc}

    def provide_item4(self):
        return {"key": "ITEM4"}

    def release_item1(self, value):
        self._release_item1_called = True

    def release_item2(self, value):
        self._release_item2_called = value

    def release_item3(self, value):
        self._release_item3_called = ("item3",)

    #def release_item4(self):
    #    pass

    def tearDown(self):
        if getattr(self, '_check_releasers_called', None):
            assert self._release_item1_called == True
            assert self._release_item2_called == {"key": "ITEM2", "name": "item2"}
            assert self._release_item3_called == ("item3",)
            assert _releasers_are_called["g1"] == True
            assert _releasers_are_called["g2"] == {"key": "G2", "name": "g2"}
            assert _releasers_are_called["g3"] == ("g3",)

    @test("fixtures should be set")
    def t(self, item1, g1):
        assert item1 == {"key": "ITEM1"}
        assert g1    == {"key": "G1"}

    @test("arguments of fixture supplier function can be variable")
    def t(self, item2, g2):
        assert item2 == {"key": "ITEM2", "name": "item2"}
        assert g2    == {"key": "G2", "name": "g2"}

    @test("releaser function is called if defined")
    def t(self, item1, item2, item3, g1, g2, g3):
        _releasers_are_called.clear()
        assert len(_releasers_are_called) == 0
        self._check_releasers_called = True    # enable assertions in tearDown()

    @test("releaser function is not called if not defined")
    def t(self, item4, g4):
        pass         # nothing should be raised


    ##
    ## test options
    ##

    @test("set options to test object", name="Haruhi", team="SOS")
    def t(self):
        assert self._options == {"name": "Haruhi", "team": "SOS"}

    @test("set options even when fixtures are supplied", name="Sasaki", team="Tengai")
    def t(self, item1, g1):
        assert self._options == {"name": "Sasaki", "team": "Tengai"}


if __name__ == '__main__':
    #unittest.main()
    suite = unittest.TestLoader().loadTestsFromTestCase(TestDeco_TC)
    unittest.TextTestRunner(verbosity=2).run(suite)

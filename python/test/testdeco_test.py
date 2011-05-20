###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###
from __future__ import with_statement

import sys, os, re
import unittest

import oktest
from oktest import test

with_stmt_available = sys.version_info >= (2, 5,)


def fixture_g1():
    return {"key": "G1"}

def fixture_g2(name):
    return {"key": "G2", "name": name}

def fixture_g3(name, testfunc):
    return {"key": "G2", "name": name, "testfunc": testfunc}

def fixture_g4():
    return {"key": "G4"}

_releasers_are_called = {}

def release_g1():
    _releasers_are_called["g1"] = True

def release_g2(name, value):
    _releasers_are_called["g2"] = (name, value)

def release_g3(name):
    _releasers_are_called["g3"] = (name,)

#def release_g4():
#    pass


class TestDeco_TC(unittest.TestCase):

    def fixture_item1(self):
        return {"key": "ITEM1"}

    def fixture_item2(self, name):
        return {"key": "ITEM2", "name": name}

    def fixture_item3(self, name, testfunc):
        return {"key": "ITEM2", "name": name, "testfunc": testfunc}

    def fixture_item4(self):
        return {"key": "ITEM4"}

    def release_item1(self):
        self._release_item1_called = True

    def release_item2(self, name, value):
        self._release_item2_called = (name, value)

    def release_item3(self, name):
        self._release_item3_called = (name,)

    #def release_item4(self):
    #    pass

    def tearDown(self):
        if getattr(self, '_check_releasers_called', None):
            assert self._release_item1_called == True
            assert self._release_item2_called == ("item2", {"key": "ITEM2", "name": "item2"})
            assert self._release_item3_called == ("item3",)
            assert _releasers_are_called["g1"] == True
            assert _releasers_are_called["g2"] == ("g2", {"key": "G2", "name": "g2"})
            assert _releasers_are_called["g3"] == ("g3",)

    @test("demo: 2 - 1 should be 1")
    def t(self):
        assert 2 - 1 == 1

    @test("demo: 1 + 1 should be 2")
    def t(self):
        assert 1 + 1 == 2

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


if __name__ == '__main__':
    #unittest.main()
    suite = unittest.TestLoader().loadTestsFromTestCase(TestDeco_TC)
    unittest.TextTestRunner(verbosity=2).run(suite)

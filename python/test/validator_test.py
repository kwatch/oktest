# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010-2014 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest

from oktest.validator import Validator
from oktest import ok, test
from oktest import python2, python3


def not_raise(fn):
    try:
        fn()
    except Exception:
        ex = sys.exc_info()[1]
        raise AssertionError("Unexpected error: %r" % (ex,))

def should_raise(errmsg):
    def deco(fn):
        try:
            fn()
        except AssertionError:
            ex = sys.exc_info()[1]
            if str(ex) != errmsg:
                raise AssertionError("%r == %r: failed." % (str(ex), errmsg))
    return deco



class Validator_TC(unittest.TestCase):

    def test_type(self):
        v = Validator('test', type=int)
        if python2:
            s = 'type'
        elif python3:
            s = 'class'
        errmsg = ("Validator('test'):  isinstance($actual, <%s 'int'>): failed.\n"
                  "  $actual: '123'" % (s,))
        @not_raise
        def _(): 123 == v
        @should_raise(errmsg)
        def _(): '123' == v
        assert (123 == v) == True

    def test_enum(self):
        v = Validator('test', enum=('A', 'B', 'O', 'AB'))
        errmsg = ("Validator('test'):  $actual in ('A', 'B', 'O', 'AB'): failed.\n"
                  "  $actual: 'C'")
        @not_raise
        def _(): 'B' == v
        @should_raise(errmsg)
        def _(): 'C' == v
        assert ('B' == v) == True

    def test_between(self):
        v = Validator('test', between=(10, 20))
        @not_raise
        def _(): 10 == v
        @not_raise
        def _(): 20 == v
        @should_raise("Validator('test'):  $actual >= 10: failed.\n  $actual: 9")
        def _(): 9 == v
        @should_raise("Validator('test'):  $actual <= 20: failed.\n  $actual: 21")
        def _(): 21 == v
        assert (10 == v) == True

    def test_length(self):
        v = Validator('test', length=(6, 7))
        @not_raise
        def _(): "haruhi" == v
        @not_raise
        def _(): "tsuruya" == v
        @should_raise("Validator('test'):  len($actual) >= 6: failed.\n"
                      "  len($actual): 5\n"
                      "  $actual     : 'kyonn'")
        def _(): "kyonn" == v
        @should_raise("Validator('test'):  len($actual) <= 7: failed.\n"
                      "  len($actual): 8\n"
                      "  $actual     : 'suzumiya'")
        def _(): "suzumiya" == v
        assert ("haruhi" == v) == True
        #
        v = Validator('test', length=6)
        @not_raise
        def _(): "haruhi" == v
        @should_raise("Validator('test'):  len($actual) == 6: failed.\n"
                      "  len($actual): 5\n"
                      "  $actual     : 'kyonn'")
        def _(): "kyonn" == v
        assert ("haruhi" == v) == True

    def test_pattern(self):
        v = Validator('test', pattern=r'^\d+$')
        @not_raise
        def _(): "123" == v
        @should_raise(r"Validator('test'):  re.search($actual, '^\\d+$'): failed."
                      "\n  $actual: '123e'")
        def _(): "123e" == v
        assert ("123" == v) == True
        #
        v = Validator('test', pattern=re.compile(r'^[a-z]+$', re.M|re.I))
        @not_raise
        def _(): "2\nB\n3\n" == v
        @should_raise(r"Validator('test'):  re.search($actual, '^[a-z]+$'): failed."
                      "\n  $actual: '2\\n3\\n4\\n'")
        def _(): "2\n3\n4\n" == v
        assert ("2\nB\n3\n" == v) == True
        #
        v = Validator('test', pattern=(r'^[a-z]+$', re.M|re.I))
        @not_raise
        def _(): "2\nB\n3\n" == v
        @should_raise(r"Validator('test'):  re.search($actual, '^[a-z]+$'): failed."
                      "\n  $actual: '2\\n3\\n4\\n'")
        def _(): "2\n3\n4\n" == v
        assert ("2\nB\n3\n" == v) == True
        #
        try:
            Validator('test', pattern=True)
        except TypeError:
            pass
        else:
            assert False, "Type error expected but nothing raised."

    def test_func(self):
        def func(actual):
            if not re.match(r'^[A-Z]{4}\d{4}$', actual):
                return "%r: unexpected pattern" % (actual,)
        v = Validator('test', func=func)
        errmsg = "Validator('test'):  'abcd1234': unexpected pattern"
        @not_raise
        def _(): "ABCD1234" == v
        @should_raise(errmsg)
        def _(): "abcd1234" == v
        assert ("ABCD1234" == v) == True



if __name__ == '__main__':
    unittest.main()

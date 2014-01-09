# -*- coding: utf-8 -*-
###
### $Release: $
### $Copyright: copyright(c) 2010-2013 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest

import oktest
from oktest import ok


class ResponseAssertionObject_TC(unittest.TestCase):

    def test_resp_property(self):
        obj = ok (""); obj == ""
        assert isinstance(obj, oktest.AssertionObject)
        assert not isinstance(obj, oktest.ResponseAssertionObject)
        assert isinstance(obj.resp, oktest.ResponseAssertionObject)



if __name__ == '__main__':
    unittest.main()

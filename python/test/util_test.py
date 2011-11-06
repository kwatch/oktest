# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest
import oktest
from oktest import python2, python3


class Util_TC(unittest.TestCase):

    def do_test(self, input):
        fname = "__test_input.txt"
        if python2:
            assert isinstance(input, str)
            cp932 = input.decode('utf-8').encode('cp932')
            assert isinstance(cp932, str)
            f = open(fname, 'wb'); f.write(cp932); f.close()
            try:
                u = oktest.util.read_text_file(fname)
                self.assertEqual(unicode, type(u))
                self.assertEqual(input.decode('utf-8'), u)
            finally:
                os.path.exists(fname) and os.unlink(fname)
        if python3:
            assert isinstance(input, str)
            cp932 = input.encode('cp932')
            assert isinstance(cp932, bytes)
            f = open(fname, 'wb'); f.write(cp932); f.close()
            try:
                s = oktest.util.read_text_file(fname)
                self.assertEqual(str, type(s))
                self.assertEqual(input, s)
            finally:
                os.path.exists(fname) and os.unlink(fname)

    def test__read_text_file__with_magic_comment(self):
        ## with magic comment
        input = r"""
# -*- coding: cp932 -*-
あいうえお
"""[1:]
        self.do_test(input)

    def test__read_text_file__with_shebang(self):
        ## with shebang
        input = r"""
#!/usr/bin/env python
# -*- coding: cp932 -*-
あいうえお
"""[1:]
        self.do_test(input)

    def test__read_text_file__when_no_magic_comment(self):
        ## without magic comment
        input = r"""
あいうえお
"""[1:]
        try:
            self.do_test(input)
            self.fail('UnicodeDecodeError expected but not raised')
        except Exception:
            ex = sys.exc_info()[1]
            self.assertEqual(UnicodeDecodeError, ex.__class__)
            self.assertTrue("'utf8' codec can't decode byte 0x82 in position 0: invalid start byte", str(ex))



if __name__ == '__main__':
    unittest.main()


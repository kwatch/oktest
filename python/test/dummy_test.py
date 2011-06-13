###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest

from oktest import ok
from oktest.dummy import *

available_with_statement = sys.version_info[0:2] >= (2, 5)


class Dummy_TC(unittest.TestCase):


    def test_dummy_file(self):
        if not available_with_statement: return
        exec(r"""from __future__ import with_statement
with dummy_file('_dummy_.txt', 'hogehoge') as f:
    ok (f.filename) == '_dummy_.txt'
    ok (f.filename).is_file()
    x = open(f.filename); s = x.read(); x.close()
    ok (s) == 'hogehoge'
ok (f.filename).not_exist()
""")


    def test_dummy_file2(self):
        filename = '_dummy_.txt'
        called = [False]
        @dummy_file(filename, 'hogehoge')
        def fn():
            called[0] = True
            ok (filename).is_file()
            f = open(filename); s = f.read(); f.close()
            ok (s) == 'hogehoge'
        ok (called[0]) == True
        ok (filename).not_exist()


    def test_dummy_dir(self):
        if not available_with_statement: return
        exec(r"""from __future__ import with_statement
with dummy_dir('_dummy_.d') as d:
    ok (d.dirname) == '_dummy_.d'
    ok (d.dirname).is_dir()
ok (d.dirname).not_exist()
""")


    def test_dummy_dir2(self):
        dirname = '_dummy_.d'
        called = [False]
        @dummy_dir(dirname)
        def fn():
            called[0] = True
            ok (dirname).is_dir()
        ok (called[0]) == True
        ok (dirname).not_exist()


    def test_dummy_environ_vars(self):
        if not available_with_statement: return
        exec(r"""from __future__ import with_statement
os.environ['AAAA'] = 'hoge'
os.environ['CCCC'] = ''
with dummy_environ_vars(AAAA='aaa', BBBB='bbb', CCCC='ccc'):
    ok (os.environ['AAAA']) == 'aaa'
    ok (os.environ['BBBB']) == 'bbb'
    ok (os.environ['CCCC']) == 'ccc'
ok (os.environ.get('AAAA')) == 'hoge'
ok ('BBBB' not in os.environ) == True
ok ('CCCC' in os.environ) == True
ok (os.environ.get('CCCC')) == ''
""")


    def test_dummy_environ_vars2(self):
        os.environ['AAAA'] = 'hoge'
        os.environ['CCCC'] = ''
        called = [False]
        @dummy_environ_vars(AAAA='aaa', BBBB='bbb', CCCC='ccc')
        def f():
            called[0] = True
            ok (os.environ['AAAA']) == 'aaa'
            ok (os.environ['BBBB']) == 'bbb'
            ok (os.environ['CCCC']) == 'ccc'
        ok (called[0]) == True
        ok (os.environ.get('AAAA')) == 'hoge'
        ok ('BBBB' not in os.environ) == True
        ok ('CCCC' in os.environ) == True
        ok (os.environ.get('CCCC')) == ''


    def test_dummy_values(self):
        if not available_with_statement: return
        exec(r"""from __future__ import with_statement
d = {'A': 10, 'B': 20, 'C': 30 }
with dummy_values(d, {999: 0}, A=100, B=200):
    ok (d) == {'A': 100, 'B': 200, 'C': 30, 999: 0}
ok (d) == {'A': 10, 'B': 20, 'C': 30 }
""")


    def test_dummy_values2(self):
        d = {'A': 10, 'B': 20, 'C': 30 }
        called = [False]
        @dummy_values(d, {999: 0}, A=100, B=200)
        def f():
            called[0] = True
            ok (d) == {'A': 100, 'B': 200, 'C': 30, 999: 0}
        ok (called[0]) == True
        ok (d) == {'A': 10, 'B': 20, 'C': 30 }


    global Foo
    class Foo(object):
        def __init__(self, x, y):
            self.x = x
            self.y = y


    def test_dummy_attrs(self):
        if not available_with_statement: return
        exec(r"""from __future__ import with_statement
obj = Foo(10, 20)
with dummy_attrs(obj, x=100, z=300):
  ok (obj.x) == 100
  ok (obj.y) == 20
  ok (obj.z) == 300
#
ok (obj.x) == 10
ok (obj.y) == 20
ok (hasattr(obj, 'z')) == False
""")


    def test_dummy_attrs2(self):
        obj = Foo(10, 20)
        called = [False]
        @dummy_attrs(obj, x=100, z=300)
        def f():
          called[0] = True
          ok (obj.x) == 100
          ok (obj.y) == 20
          ok (obj.z) == 300
        ok (called[0]) == True
        #
        ok (obj.x) == 10
        ok (obj.y) == 20
        ok (hasattr(obj, 'z')) == False


    def test_dummy_io(self):
        if not available_with_statement: return
        exec(r"""from __future__ import with_statement
sin, sout, serr = sys.stdin, sys.stdout, sys.stderr
with dummy_io("SOS") as d_io:
    ok (sys.stdin)  != sin
    ok (sys.stdout) != sout
    ok (sys.stderr) != serr
    ok (sys.stdin.read()) == "SOS"
    sys.stdout.write("Haruhi")
    sys.stderr.write("Sasaki")
ok (sys.stdin).is_(sin)
ok (sys.stdout).is_(sout)
ok (sys.stderr).is_(serr)
sout, serr = d_io
ok (sout) == "Haruhi"
ok (serr) == "Sasaki"
ok (d_io.stdout) == "Haruhi"
ok (d_io.stderr) == "Sasaki"
""")


    def test_dummy_io2(self):
        sin, sout, serr = sys.stdin, sys.stdout, sys.stderr
        called = [False]
        @dummy_io("SOS")
        def d_io():
            called[0] = True
            ok (sys.stdin)  != sin
            ok (sys.stdout) != sout
            ok (sys.stderr) != serr
            ok (sys.stdin.read()) == "SOS"
            sys.stdout.write("Haruhi")
            sys.stderr.write("Sasaki")
        ok (called[0]) == True
        ok (sys.stdin).is_(sin)
        ok (sys.stdout).is_(sout)
        ok (sys.stderr).is_(serr)
        sout, serr = d_io
        ok (sout) == "Haruhi"
        ok (serr) == "Sasaki"
        ok (d_io.stdout) == "Haruhi"
        ok (d_io.stderr) == "Sasaki"



if __name__ == '__main__':
    unittest.main()

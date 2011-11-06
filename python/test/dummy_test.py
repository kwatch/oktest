###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest

from oktest import ok, NG
from oktest.dummy import *

available_with_statement = sys.version_info[0:2] >= (2, 5)


class DummyClass(object):
    pass


class Dummy_TC(unittest.TestCase):


    def test_dummy_file_1(self):
        """creates a dummy file temporarily when used with with-stmt."""
        if not available_with_statement:
            print("*** skipped")
            return
        fname, content = '_test.sos.txt', 'SOS'
        exec(r"""
from __future__ import with_statement
with dummy_file(fname, content) as df:
    ok (fname).is_file()
    f = open(fname); s = f.read(); f.close()
    ok (s) == content
    ok (df.filename) == fname
NG (fname).is_file()
""")

    def test_dummy_file_2(self):
        """creates a dummy file temporarily when run() called with a function."""
        fname, content = '_test.sos.txt', 'SOS'
        called = []
        def func():
            called.append(('func', fname))
            ok (fname).is_file()
            f = open(fname); s = f.read(); f.close()
            ok (s) == content
            return 999
        ret = dummy_file(fname, content).run(func)
        ok (fname).not_exist()
        ok (called[0]) == ('func', fname)
        ok (ret) == 999

    def test_dummy_file_3(self):
        """available as decorator."""
        fname, content = '_test.sos.txt', 'SOS'
        called = []
        @dummy_file(fname, content)
        def func():
            called.append(('func', fname))
            ok (fname).is_file()
            f = open(fname); s = f.read(); f.close()
            ok (s) == content
            return 999
        ret = func
        ok (fname).not_exist()
        ok (called[0]) == ('func', fname)
        ok (ret) == 999


    def test_dummy_dir_1(self):
        """creates a dummy directory temporarily when used with with-stmt."""
        if not available_with_statement:
            print("*** skipped")
            return
        dname = '_test.sos.dir'
        exec(r"""
from __future__ import with_statement
with dummy_dir(dname):
    ok (dname).is_dir()
NG (dname).is_dir()
""")

    def test_dummy_dir_2(self):
        """creates a dummy directory temporarily when run() called with a function."""
        dname = '_test.sos.dir'
        called = []
        def func():
            called.append(('func', dname))
            ok (dname).is_dir()
            return 888
        ret = dummy_dir(dname).run(func)
        ok (dname).not_exist()
        ok (called[0]) == ('func', dname)
        ok (ret) == 888

    def test_dummy_dir_3(self):
        """available as decorator."""
        dname = '_test.sos.dir'
        called = []
        @dummy_dir(dname)
        def func():
            called.append(('func', dname))
            ok (dname).is_dir()
            return 888
        ret = func
        ok (dname).not_exist()
        ok (called[0]) == ('func', dname)
        ok (ret) == 888


    def test_dummy_values_1(self):
        """changes dictionary value temporarily when used with with-stmt."""
        if not available_with_statement:
            print("*** skipped")
            return
        exec(r"""
from __future__ import with_statement
d = {"haruhi":"Suzumiya", "mikuru":"Asahina"}
with dummy_values(d, {"yuki": "Nagato"}, mikuru="ASAHINA"):
    ok (d) == {"haruhi":"Suzumiya", "mikuru":"ASAHINA", "yuki":"Nagato"}
ok (d) == {"haruhi":"Suzumiya", "mikuru":"Asahina"}
""")

    def test_dummy_values_2(self):
        """changes dictionary value temporarily when run() called with function."""
        d = {'Haruhi': 'Suzumiya'}
        called = []
        def func():
            called.append(True)
            ok (d) == {'Haruhi':'SUZIMIYA', 'Mikuru':'Asahina'}
        dummy_values(d, Haruhi='SUZIMIYA', Mikuru='Asahina').run(func)
        ok (called) == [True]
        ok (d) == {'Haruhi': 'Suzumiya'}

    def test_dummy_values_3(self):
        """available as decorator."""
        d = {'Haruhi': 'Suzumiya'}
        called = []
        @dummy_values(d, Haruhi='SUZIMIYA', Mikuru='Asahina')
        def func():
            called.append(True)
            ok (d) == {'Haruhi':'SUZIMIYA', 'Mikuru':'Asahina'}
        ok (called) == [True]
        ok (d) == {'Haruhi': 'Suzumiya'}


    def test_dummy_attrs_1(self):
        """changes attributes temporarily when used with with-stmt."""
        if not available_with_statement:
            print("*** skipped")
            return
        obj = DummyClass()
        exec(r"""
from __future__ import with_statement
with dummy_attrs(obj, SOS=[123]):
    ok (obj).has_attr('SOS')
    ok (obj.SOS) == [123]
NG (obj).has_attr('SOS')
""")

    def test_dummy_attrs_2(self):
        """changes attributes temporarily when run() called with function."""
        obj = DummyClass()
        called = []
        def func():
            called.append(True)
            ok (obj).has_attr('SOS')
            ok (obj.SOS) == [123]
            return 999
        ret = dummy_attrs(obj, SOS=[123]).run(func)
        ok (called) == [True]
        NG (obj).has_attr('SOS')
        ok (ret) == 999

    def test_dummy_attrs_3(self):
        """available as decorator."""
        obj = DummyClass()
        called = []
        @dummy_attrs(obj, SOS=[123])
        def func():
            called.append(True)
            ok (obj).has_attr('SOS')
            ok (obj.SOS) == [123]
            return 999
        ret = func
        ok (called) == [True]
        NG (obj).has_attr('SOS')
        ok (ret) == 999


    def test_dummy_environ_vars_1(self):
        """changes environment variables temporarily when used with with-stmt."""
        if not available_with_statement:
            print("*** skipped")
            return
        exec(r"""
from __future__ import with_statement
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

    def test_dummy_environ_vars_2(self):
        """changes environment variables temporarily when run() called with function."""
        called = []
        def func():
            called.append(True)
            ok ('SOS' in os.environ) == True
            ok (os.environ['SOS']) == '???'
            return 111
        ret = dummy_environ_vars(SOS='???').run(func)
        ok (called) == [True]
        ok ('SOS' in os.environ) == False
        ok (ret) == 111

    def test_dummy_environ_vars_3(self):
        """available as decorator."""
        called = []
        @dummy_environ_vars(SOS='???')
        def func():
            called.append(True)
            ok ('SOS' in os.environ) == True
            ok (os.environ['SOS']) == '???'
            return 111
        ret = func
        ok (called) == [True]
        ok ('SOS' in os.environ) == False
        ok (ret) == 111


    def test_dummy_io_1(self):
        """changes stdio temporarily when used with with-stmt."""
        if not available_with_statement:
            print("*** skipped")
            return
        exec(r"""
from __future__ import with_statement
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

    def test_dummy_io_2(self):
        """changes stdio temporarily when run() called with function."""
        sin, sout, serr = sys.stdin, sys.stdout, sys.stderr
        called = []
        def func():
            called.append(True)
            ok (sys.stdin)  != sin
            ok (sys.stdout) != sout
            ok (sys.stderr) != serr
            ok (sys.stdin.read()) == "SOS"
            sys.stdout.write("Mikuru")
            print("Yuki")
            sys.stderr.write("Itsuki")
            return 777
        d_io = dummy_io("SOS")
        ret = d_io.run(func)
        ok (called) == [True]
        ok (sys.stdin).is_(sin)
        ok (sys.stdout).is_(sout)
        ok (sys.stderr).is_(serr)
        ok (d_io.stdout) == "MikuruYuki\n"
        ok (d_io.stderr) == "Itsuki"
        ok (ret) == 777

    def test_dummy_io_3(self):
        """available as decorator."""
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

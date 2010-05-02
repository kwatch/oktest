###
### $Release: 0.3.0 $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###
from __future__ import with_statement

import sys, os, re
python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3
if python2:
    from StringIO import StringIO
    with_statement_supported = sys.version_info[1] >= 5
if python3:
    from io import StringIO
    with_statement_supported = True

for path in ['lib', '../lib']:
    if os.path.isdir(path):
        sys.path.append(path)
        os.environ['PYTHONPATH'] = path
        break
os.environ['OKTEST_REPORTER'] = 'OldStyleReporter'

import oktest

echo = sys.stdout.write
python_command = os.environ.get('PYTHON', 'python')

def do_test_with(desc, script, expected,  _pat=re.compile(r'0\.00[01]s')):
    filename = '_test_.py'
    try:
        echo("- %s..." % desc)
        open(filename, 'w').write(script)
        output = os.popen(python_command + ' ' + filename).read()
        if isinstance(output, str):
            output = re.sub(r' at 0x[0-9a-f]{6}', '', output)
        if output == expected:
            echo("done.\n")
        elif _pat.sub('', output) == _pat.sub('', expected):
            echo("done.\n")
        else:
            echo("FAILED.\n")
            if (isinstance(output, str) and isinstance(expected, str)):
                lf = (not output or output[-1] != "\n") and "\n" or ""
                echo("output: %s%s" % (output, lf))
                lf = (not expected or expected[-1] != "\n") and "\n" or ""
                echo("expected: %s%s" % (expected, lf))
            else:
                echo('%s != %s' % (repr(output), repr(expected)))
    finally:
        if os.path.exists(filename):
            os.unlink(filename)


###
desc = "successful script"
script = r"""
from oktest import *
class FooTest(object):
    def test_plus(self):
        ok (1+1) == 2
run(FooTest)
"""
expected = "* FooTest.test_plus ... [ok]\n"
do_test_with(desc, script, expected)

###
desc = "failed script"
script = r"""
from oktest import *
class FooTest(object):
    def test_plus(self):
        ok (1+1) == 1
run(FooTest)
"""[1:]
expected = r"""
* FooTest.test_plus ... [NG] 2 == 1 : failed.
   _test_.py:4: ok (1+1) == 1
"""[1:]
do_test_with(desc, script, expected)

###
desc = "class name pattern"
script = r"""
from oktest import *
class FooTest(object):
    def test_plus(self):
        ok (1+1) == 2
class BarTest(object):
    def test_minus(self):
        ok (4-1) == 3
run('.*Test$')
"""[1:]
expected = r"""
* BarTest.test_minus ... [ok]
* FooTest.test_plus ... [ok]
"""[1:]
do_test_with(desc, script, expected)


###
desc = "before_all/before_each/after_each/after_all"
script = r"""
from oktest import *
class FooTest(object):
    def before_all(cls):
        print('before_all() called.')
    before_all = classmethod(before_all)
    def after_all(cls):
        print('after_all() called.')
    after_all  = classmethod(after_all)
    def before(self):
        print('before() called.')
    def after(self):
        print('after() called.')
    #
    def test_1(self):
        print('test_1() called.')
        ok (1+1) == 2
    def test_2(self):
        print('test_2() called.')
        ok (1+1) == 3
    def test_3(self):
        print('test_3() called.')
        int('abc')
run('FooTest')
"""[1:]
expected = r"""
before_all() called.
* FooTest.test_1 ... before() called.
test_1() called.
[ok]
after() called.
* FooTest.test_2 ... before() called.
test_2() called.
[NG] 2 == 3 : failed.
   _test_.py:19: ok (1+1) == 3
after() called.
* FooTest.test_3 ... before() called.
test_3() called.
[ERROR] ValueError: invalid literal for int() with base 10: 'abc'
  - _test_.py:22:  int('abc')
after() called.
after_all() called.
"""[1:]
do_test_with(desc, script, expected)

###
desc = "setUp()/tearDown()"
script = r"""
from oktest import *
class FooTest(object):
    def setUp(self):
        print('setUp() called.')
    def tearDown(self):
        print('tearDown() called.')
    #
    def test_1(self):
        print('test_1() called.')
        ok (1+1) == 2
    def test_2(self):
        print('test_2() called.')
        ok (1+1) == 3
    def test_3(self):
        print('test_3() called.')
        int('abc')
run('FooTest')
"""[1:]
expected = r"""
* FooTest.test_1 ... setUp() called.
test_1() called.
[ok]
tearDown() called.
* FooTest.test_2 ... setUp() called.
test_2() called.
[NG] 2 == 3 : failed.
   _test_.py:13: ok (1+1) == 3
tearDown() called.
* FooTest.test_3 ... setUp() called.
test_3() called.
[ERROR] ValueError: invalid literal for int() with base 10: 'abc'
  - _test_.py:16:  int('abc')
tearDown() called.
"""[1:]
do_test_with(desc, script, expected)


###
desc = "op '=='"
script = r"""
import oktest
oktest.DIFF = False
from oktest import *
class FooTest(object):
    def test_inteq(self):
        ok (4*4) == 16
    def test_streq(self):
        ok ('FOO'.lower()) == 'foo'
class BarTest(object):
    def test_inteq(self):
        ok (4*4) == 15
    def test_streq(self):
        ok ("foo".upper()) == 'foo'
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_inteq ... [ok]
* FooTest.test_streq ... [ok]
* BarTest.test_inteq ... [NG] 16 == 15 : failed.
   _test_.py:11: ok (4*4) == 15
* BarTest.test_streq ... [NG] 'FOO' == 'foo' : failed.
   _test_.py:13: ok ("foo".upper()) == 'foo'
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op '!='"
script = r"""
from oktest import *
class FooTest(object):
    def test_inteq(self):
        ok (4*4) != 15
    def test_streq(self):
        ok ('FOO'.lower()) != 'FOO'
class BarTest(object):
    def test_inteq(self):
        ok (4*4) != 16
    def test_streq(self):
        ok ("foo".upper()) != 'FOO'
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_inteq ... [ok]
* FooTest.test_streq ... [ok]
* BarTest.test_inteq ... [NG] 16 != 16 : failed.
   _test_.py:9: ok (4*4) != 16
* BarTest.test_streq ... [NG] 'FOO' != 'FOO' : failed.
   _test_.py:11: ok ("foo".upper()) != 'FOO'
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op '>, >=, <, <='"
script = r"""
from oktest import *
class FooTest(object):
    def test_gt(self):
        ok (2) > 1
    def test_ge(self):
        ok (2) >= 2
    def test_lt(self):
        ok (1) < 2
    def test_le(self):
        ok (2) <= 2
class BarTest(object):
    def test_gt(self):
        ok (2) > 2
    def test_ge(self):
        ok (1) >= 2
    def test_lt(self):
        ok (2) < 2
    def test_le(self):
        ok (2) <= 1
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_gt ... [ok]
* FooTest.test_ge ... [ok]
* FooTest.test_lt ... [ok]
* FooTest.test_le ... [ok]
* BarTest.test_gt ... [NG] 2 > 2 : failed.
   _test_.py:13: ok (2) > 2
* BarTest.test_ge ... [NG] 1 >= 2 : failed.
   _test_.py:15: ok (1) >= 2
* BarTest.test_lt ... [NG] 2 < 2 : failed.
   _test_.py:17: ok (2) < 2
* BarTest.test_le ... [NG] 2 <= 1 : failed.
   _test_.py:19: ok (2) <= 1
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op '.matches'"
script = r"""
from oktest import *
class FooTest(object):
    def test_match(self):
        ok ("123@mail.com").matches(r'\w+@\w+(\.\w+)')
    def test_match2(self):
        import re
        ok ("123@mail.com").matches(re.compile(r'^\w+@\w+(\.\w+)$'))
class BarTest(object):
    def test_match(self):
        ok ("abc").matches(r'\d+')
    def test_match2(self):
        import re
        ok ("abc").matches(re.compile(r'\d+'))
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_match ... [ok]
* FooTest.test_match2 ... [ok]
* BarTest.test_match ... [NG] re.search('\\d+', 'abc') : failed.
   _test_.py:10: ok ("abc").matches(r'\d+')
* BarTest.test_match2 ... [NG] re.search('\\d+', 'abc') : failed.
   _test_.py:13: ok ("abc").matches(re.compile(r'\d+'))
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op '.not_match'"
script = r"""
from oktest import *
class FooTest(object):
    def test_match(self):
        ok ("foo").not_match(r'\d+')
    def test_match2(self):
        import re
        ok ("foo").not_match(re.compile(r'\d+'))
class BarTest(object):
    def test_match(self):
        ok ("foo").not_match(r'\w+')
    def test_match2(self):
        import re
        ok ("foo").not_match(re.compile(r'\w+'))
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_match ... [ok]
* FooTest.test_match2 ... [ok]
* BarTest.test_match ... [NG] not re.search('\\w+', 'foo') : failed.
   _test_.py:10: ok ("foo").not_match(r'\w+')
* BarTest.test_match2 ... [NG] not re.search('\\w+', 'foo') : failed.
   _test_.py:13: ok ("foo").not_match(re.compile(r'\w+'))
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op 'is_', 'is_not'"
script = r"""
from oktest import *
val1 = {'x': 10}
val2 = {'x': 10}
class FooTest(object):
    def test_is(self):
        ok (val1).is_(val1)
    def test_is_not(self):
        ok (val1).is_not(val2)
class BarTest(object):
    def test_is(self):
        ok (val1).is_(val2)
    def test_is_not(self):
        ok (val1).is_not(val1)
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_is ... [ok]
* FooTest.test_is_not ... [ok]
* BarTest.test_is ... [NG] {'x': 10} is {'x': 10} : failed.
   _test_.py:11: ok (val1).is_(val2)
* BarTest.test_is_not ... [NG] {'x': 10} is not {'x': 10} : failed.
   _test_.py:13: ok (val1).is_not(val1)
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op 'in_', 'not_in'"
script = r"""
from oktest import *
L = [0,10,20,30]
class FooTest(object):
    def test_in(self):
        ok (10).in_(L)
    def test_not_in(self):
        ok (11).not_in(L)
class BarTest(object):
    def test_in(self):
        ok (11).in_(L)
    def test_not_in(self):
        ok (10).not_in(L)
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_in ... [ok]
* FooTest.test_not_in ... [ok]
* BarTest.test_in ... [NG] 11 in [0, 10, 20, 30] : failed.
   _test_.py:10: ok (11).in_(L)
* BarTest.test_not_in ... [NG] 10 not in [0, 10, 20, 30] : failed.
   _test_.py:12: ok (10).not_in(L)
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op 'is_a', 'is_not_a'"
script = r"""
from oktest import *
class Val(object):
  def __init__(self, val):
    self.val = val
  def __repr__(self):
    return "<Val val=%s>" % self.val
class FooTest(object):
    def test_is_a(self):
        ok (Val(123)).is_a(Val)
    def test_is_not_a(self):
        ok (123).is_not_a(Val)
class BarTest(object):
    def test_is_a(self):
        ok (123).is_a(Val)
    def test_is_not_a(self):
        ok (Val(123)).is_not_a(Val)
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_is_a ... [ok]
* FooTest.test_is_not_a ... [ok]
* BarTest.test_is_a ... [NG] isinstance(123, Val) : failed.
   _test_.py:14: ok (123).is_a(Val)
* BarTest.test_is_not_a ... [NG] not isinstance(<Val val=123>, Val) : failed.
   _test_.py:16: ok (Val(123)).is_not_a(Val)
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op 'raises'"
script = r"""
from oktest import *
class FooTest(object):
    def test_raises1(self):
        def f(): raise ValueError('errmsg1')
        ok (f).raises(ValueError)             # ValueError
    def test_raises2(self):
        def f(): raise ValueError('errmsg1')
        ok (f).raises(ValueError, 'errmsg1')   # ValueError + errmsg
    def test_raises3(self):
        def f(): raise ValueError('errmsg1')
        ok (f).raises(Exception, 'errmsg1')    # Exception + errmsg
    def test_raises4(self):
        def f(): raise ValueError('errmsg1')
        ok (f).raises(Exception)                # f.exception
        assert hasattr(f, 'exception')
        assert isinstance(f.exception, ValueError)
        assert str(f.exception) == 'errmsg1'
class BarTest(object):
    def test_raises1(self):
        def f(): pass
        ok (f).raises(Exception)
    def test_raises2(self):
        def f(): raise ValueError('errmsg1')
        ok (f).raises(NameError)
    def test_raises3(self):
        def f(): raise ValueError('errmsg1')
        ok (f).raises(ValueError, 'errmsg2')
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_raises1 ... [ok]
* FooTest.test_raises2 ... [ok]
* FooTest.test_raises3 ... [ok]
* FooTest.test_raises4 ... [ok]
* BarTest.test_raises1 ... [NG] Exception should be raised : failed.
   _test_.py:21: ok (f).raises(Exception)
* BarTest.test_raises2 ... [NG] ValueError('errmsg1',) is kind of NameError : failed.
   _test_.py:24: ok (f).raises(NameError)
* BarTest.test_raises3 ... [NG] 'errmsg1' == 'errmsg2' : failed.
   _test_.py:27: ok (f).raises(ValueError, 'errmsg2')
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op 'not raise'"
script = r"""
from oktest import *
class FooTest(object):
    def test_not_raises1(self):
        def f(): return 1
        ok (f).not_raise(Exception)              # Exception
    def test_not_raises2(self):
        def f(): raise ValueError('errmsg1')
        ok (f).not_raise(NameError)              # NameError
        assert hasattr(f, 'exception')
        assert isinstance(f.exception, ValueError)
        assert str(f.exception) == 'errmsg1'
class BarTest(object):
    def test_not_raises1(self):
        def f(): raise ValueError('errmsg1')
        ok (f).not_raise(Exception)
    def test_not_raises2(self):
        def f(): raise ValueError('errmsg1')
        ok (f).not_raise(ValueError)
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_not_raises1 ... [ok]
* FooTest.test_not_raises2 ... [ok]
* BarTest.test_not_raises1 ... [NG] Exception should not be raised : failed.
   _test_.py:15: ok (f).not_raise(Exception)
* BarTest.test_not_raises2 ... [NG] ValueError should not be raised : failed.
   _test_.py:18: ok (f).not_raise(ValueError)
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op 'is_file', 'is_dir'"
script = r"""
from oktest import *
import os
class FooTest(object):
    def before_all(cls):
        open('foobar.txt', 'w').write('foobar')
        os.mkdir('foobar.d')
    before_all = classmethod(before_all)
    def after_all(cls):
        os.unlink('foobar.txt')
        os.rmdir('foobar.d')
    after_all = classmethod(after_all)
    #
    def test_isfile(self):
        ok ("foobar.txt").is_file()
    def test_isdir(self):
        ok ("foobar.d").is_dir()
    def test_isnotfile(self):
        ok ("foobar.d").is_not_file()
    def test_isnotdir(self):
        ok ("foobar.txt").is_not_dir()
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_isfile ... [ok]
* FooTest.test_isdir ... [ok]
* FooTest.test_isnotfile ... [ok]
* FooTest.test_isnotdir ... [ok]
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op 'not_ok'"
script = r"""
from oktest import *
import os
class FooTest(object):
    def before_all(cls):
        open('foobar.txt', 'w').write('foobar')
        os.mkdir('foobar.d')
    before_all = classmethod(before_all)
    def after_all(cls):
        os.unlink('foobar.txt')
        os.rmdir('foobar.d')
    after_all = classmethod(after_all)
    #
    def test_isfile(self):
        not_ok ("xxxxxx.txt").is_file()
        not_ok ("foobar.d").is_file()
        not_ok ("foobar.txt").is_not_file()
    def test_isdir(self):
        not_ok ("xxxxxx.d").is_dir()
        not_ok ("foobar.txt").is_dir()
        not_ok ("foobar.d").is_not_dir()
    def test_matches(self):
        not_ok ("foobar").matches("\d+")
        not_ok ("123").not_match("\d+")
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_isfile ... [ok]
* FooTest.test_isdir ... [ok]
* FooTest.test_matches ... [ok]
"""[1:]
do_test_with(desc, script, expected)




### dummy_file (with with-statement)
desc = "dummy_file (with with-statement)"
script = r"""
from __future__ import with_statement
from oktest import *
class FooTest(object):
    def test_dummy_file(self):
        with dummy_file('_dummy_.txt', 'hogehoge') as f:
            ok (f.filename) == '_dummy_.txt'
            ok (f.filename).is_file()
            ok (open(f.filename).read()) == 'hogehoge'
        ok (f.filename).not_exist()
run(FooTest)
"""
expected = "* FooTest.test_dummy_file ... [ok]\n"
if with_statement_supported:
    do_test_with(desc, script, expected)

### dummy_file (without with-statement)
desc = "dummy_file (without with-statement)"
script = r"""
from oktest import *
class FooTest(object):
    def test_dummy_file2(self):
        filename = '_dummy_.txt'
        def f():
            ok (filename).is_file()
            ok (open(filename).read()) == 'hogehoge'
        dummy_file(filename, 'hogehoge')(f)
        ok (filename).not_exist()
run(FooTest)
"""
expected = "* FooTest.test_dummy_file2 ... [ok]\n"
do_test_with(desc, script, expected)

### dummy_dir (with with-statement)
desc = "dummy_dir (with with-statement)"
script = r"""
from __future__ import with_statement
from oktest import *
class FooTest(object):
    def test_dummy_dir(self):
        with dummy_dir('_dummy_.d') as d:
            ok (d.dirname) == '_dummy_.d'
            ok (d.dirname).is_dir()
        ok (d.dirname).not_exist()
run(FooTest)
"""
expected = "* FooTest.test_dummy_dir ... [ok]\n"
if with_statement_supported:
    do_test_with(desc, script, expected)

### dummy_dir (without with-statement)
desc = "dummy_dir (without with-statement)"
script = r"""
from oktest import *
class FooTest(object):
    def test_dummy_dir2(self):
        dirname = '_dummy_.d'
        def f():
            ok (dirname).is_dir()
        dummy_dir(dirname)(f)
        ok (dirname).not_exist()
run(FooTest)
"""
expected = "* FooTest.test_dummy_dir2 ... [ok]\n"
do_test_with(desc, script, expected)

### chdir (with with-statement)
desc = "chdir (with with-statement)"
script = r"""
from __future__ import with_statement
import os
from oktest import *
class FooTest(object):
    def test_chdir(self):
        with dummy_dir('_dummy_.d'):
            pwd = os.getcwd()
            with chdir('_dummy_.d') as d:
                ok (d.dirname) == '_dummy_.d'
                ok (os.getcwd()) != pwd
                ok (os.getcwd()) == os.path.join(pwd, '_dummy_.d')
            ok (os.getcwd()) == pwd
run(FooTest)
"""
expected = "* FooTest.test_chdir ... [ok]\n"
if with_statement_supported:
    do_test_with(desc, script, expected)

### chdir (without with-statement)
desc = "chdir (without with-statement)"
script = r"""
import os
from oktest import *
class FooTest(object):
    def test_chdir2(self):
        def f():
            pwd = os.getcwd()
            def g():
                ok (os.path.basename(os.getcwd())) == '_dummy_.d'
                ok (os.getcwd()) != pwd
                ok (os.getcwd()) == os.path.join(pwd, '_dummy_.d')
            chdir('_dummy_.d')(g)
            ok (os.getcwd()) == pwd
        dummy_dir('_dummy_.d')(f)
run(FooTest)
"""
expected = "* FooTest.test_chdir2 ... [ok]\n"
do_test_with(desc, script, expected)


### diff (oktest.DIFF = True)
desc = "diff (oktest.DIFF = True)"
script = r"""
from oktest import *
import oktest
oktest.DIFF = True
class FooTest(object):
    def test1(self):
       ok ('foo') == 'foo1'
    def test2(self):
       ok ("AAA\nBBB\nCCC\n") == "AAA\n888\nCCC"
run(FooTest)
"""[1:]
expected = r"""
* FooTest.test1 ... [NG] 'foo' == 'foo1' : failed.
   _test_.py:6: ok ('foo') == 'foo1'
--- expected 
+++ actual 
@@ -1,1 +1,1 @@
-foo1
+foo
* FooTest.test2 ... [NG] 'AAA\nBBB\nCCC\n' == 'AAA\n888\nCCC' : failed.
   _test_.py:8: ok ("AAA\nBBB\nCCC\n") == "AAA\n888\nCCC"
--- expected 
+++ actual 
@@ -1,3 +1,3 @@
 AAA
-888
-CCC
\ No newline at end of string
+BBB
+CCC
"""[1:]
do_test_with(desc, script, expected)

### diff (oktest.DIFF == 'repr')
desc = "diff (oktest.DIFF == 'repr')"
script = r"""
from oktest import *
import oktest
oktest.DIFF = repr
class FooTest(object):
    def test1(self):
        ok ('foo') == 'foo1'
    def test2(self):
        ok ("AAA\nBBB\nCCC\n") == "AAA\n888\nCCC"
run(FooTest)
"""[1:]
expected = r"""
* FooTest.test1 ... [NG] 'foo' == 'foo1' : failed.
   _test_.py:6: ok ('foo') == 'foo1'
--- expected 
+++ actual 
@@ -1,1 +1,1 @@
-'foo1'
+'foo'
* FooTest.test2 ... [NG] 'AAA\nBBB\nCCC\n' == 'AAA\n888\nCCC' : failed.
   _test_.py:8: ok ("AAA\nBBB\nCCC\n") == "AAA\n888\nCCC"
--- expected 
+++ actual 
@@ -1,3 +1,3 @@
 'AAA\n'
-'888\n'
-'CCC'
+'BBB\n'
+'CCC\n'
"""[1:]
do_test_with(desc, script, expected)

### diff (oktest.DIFF == False)
desc = "diff (oktest.DIFF == False)"
script = r"""
from oktest import *
import oktest
oktest.DIFF = False
class FooTest(object):
    def test1(self):
       ok ('foo') == 'foo1'
    def test2(self):
       ok ("AAA\nBBB\nCCC\n") == "AAA\n888\nCCC"
run(FooTest)
"""[1:]
expected = r"""
* FooTest.test1 ... [NG] 'foo' == 'foo1' : failed.
   _test_.py:6: ok ('foo') == 'foo1'
* FooTest.test2 ... [NG] 'AAA\nBBB\nCCC\n' == 'AAA\n888\nCCC' : failed.
   _test_.py:8: ok ("AAA\nBBB\nCCC\n") == "AAA\n888\nCCC"
"""[1:]
do_test_with(desc, script, expected)


## unittest compatibility
desc = "unittest compatibility"
script = r"""
from oktest import *
import sys
sys.stderr = sys.stdout
import unittest
class FooTest(unittest.TestCase):
  def test1(self):
    ok (1+1) == 2
  def test2(self):
    ok (1+1) == 3
unittest.main()
"""[1:]
expected = r"""
.F
======================================================================
FAIL: test2 (__main__.FooTest)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "_test_.py", line 9, in test2
    ok (1+1) == 3
AssertionError: 2 == 3 : failed.

----------------------------------------------------------------------
Ran 2 tests in 0.000s

FAILED (failures=1)
"""[1:]
do_test_with(desc, script, expected)


## simple reporter
desc = "simple reporter"
script = r"""
from oktest import *
import sys
sys.stderr = sys.stdout
import unittest
class FooTest(object):
  def test_success(self):
    ok (1+1) == 2
  def test_failed(self):
    ok (1+1) == 3
  def test_error(self):
    ok (int('aaa')) == 0
run(FooTest)
"""[1:]
expected = r"""
### FooTest
.fE
Failed: FooTest#test_failed()
  2 == 3 : failed.
  File "_test_.py", line 9
    ok (1+1) == 3
ERROR: FooTest#test_error()
  ValueError: invalid literal for int() with base 10: 'aaa'
  File "_test_.py", line 11, in test_error
    ok (int('aaa')) == 0
"""[1:]
os.environ['OKTEST_REPORTER'] = 'SimpleReporter'
do_test_with(desc, script, expected)

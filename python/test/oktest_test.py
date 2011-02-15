###
### $Release: 0.8.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
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

def do_test_with(desc, script, expected,  _pat=re.compile(r'0\.00[\d]s')):
    filename = '_test_.py'
    try:
        echo("- %s..." % desc)
        open(filename, 'w').write(script)
        output = os.popen(python_command + ' ' + filename).read()
        #sin, sout, serr = os.popen(python_command + ' ' + filename)
        #sin.close()
        #output = sout.read();  sout.close()
        #output_err = serr.read();  serr.close()
        if isinstance(output, str):
            output = re.sub(r' at 0x[0-9a-f]{6,9}', '', output)
        if output == expected:
            echo("done.\n")
        elif _pat.sub('', output) == _pat.sub('', expected):
            echo("done.\n")
        elif output == expected.replace('--- expected ', '--- expected').replace('+++ actual ', '+++ actual'):   # for Python 3.x
            echo("done.\n")
        else:
            echo("FAILED.\n")
            if (isinstance(output, str) and isinstance(expected, str)):
                import difflib
                for x in difflib.unified_diff(expected.splitlines(True), output.splitlines(True), 'expected', 'actual', n=2):
                    echo(x)
                    #echo(repr(x) + "\n")
                #lf = (not output or output[-1] != "\n") and "\n" or ""
                #echo("output: %s%s" % (output, lf))
                #lf = (not expected or expected[-1] != "\n") and "\n" or ""
                #echo("expected: %s%s" % (expected, lf))
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
* FooTest.test_plus ... [ok]
* BarTest.test_minus ... [ok]
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
if python2 and sys.version_info[1] <= 4:
    expected = expected.replace("int() with base 10: 'abc'", 'int(): abc')
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
if python2 and sys.version_info[1] <= 4:
    expected = expected.replace("int() with base 10: 'abc'", 'int(): abc')
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
desc = "in_delta()'"
script = r"""
from oktest import *
class FooTest(object):
    def test_in_delta(self):
        ok (3.14159).in_delta(3.1415, 0.0001)
class BarTest(object):
    def test_in_delta(self):
        ok (3.14159).in_delta(3.1415, 0.00001)
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_in_delta ... [ok]
* BarTest.test_in_delta ... [NG] 3.1415899999999999 < 3.1415100000000002 : failed.
   _test_.py:7: ok (3.14159).in_delta(3.1415, 0.00001)
"""[1:]
if repr(3.14159) == '3.14159':    # for Python 3.x
    expected = expected.replace('3.1415899999999999', '3.14159')
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
desc = "op 'hasattr'"
script = r"""
from oktest import *
class FooTest(object):
    def test_hasattr(self):
        ok ("s").hasattr("__class__")
class BarTest(object):
    def test_hasattr(self):
        ok ("s").hasattr("xxxxx")
run('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_hasattr ... [ok]
* BarTest.test_hasattr ... [NG] hasattr('s', 'xxxxx') : failed.
   _test_.py:7: ok ("s").hasattr("xxxxx")
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
desc = "op 'raises' (skip AssertionError)"
script = r"""
from oktest import *
class FooTest(object):
    def test_skip_assert(self):
        def f():
            assert 1 == 2
            raise ValueError('errmsg1')
        ok (f).raises(ValueError)
try:
    run(FooTest)
except AssertionError:
    import sys
    ex = sys.exc_info()[1]
    print("")
    print("ex.__class__.__name__=%r" % ex.__class__.__name__)
    print("str(ex)=%r" % str(ex))
"""[1:]
expected = r"""
* FooTest.test_skip_assert ... 
ex.__class__.__name__='AssertionError'
str(ex)=''
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
desc = "op 'not raise' (skip AssertionError)"
script = r"""
from oktest import *
class FooTest(object):
    def test_skip_assert(self):
        def f(): assert 1 == 0
        ok (f).not_raise(Exception)              # Exception
try:
    run(FooTest)
except AssertionError:
    import sys
    ex = sys.exc_info()[1]
    print("")
    print("ex.__class__.__name__=%r" % ex.__class__.__name__)
    print("str(ex)=%r" % str(ex))
"""[1:]
expected = r"""
* FooTest.test_skip_assert ... 
ex.__class__.__name__='AssertionError'
str(ex)=''
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
desc = "chained method"
script = r"""
from oktest import *
class FooTest(object):
    def test_chained1(self):
        ok ("Sasaki".upper()).is_a(str).matches(r'^[A-Z]+$') == "SASAKI"
run()
"""[1:]
expected = r"""
* FooTest.test_chained1 ... [ok]
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


###
desc = "assertion()"
script = r"""
import oktest
from oktest import *

@oktest.assertion
def startswith(self, arg):
  boolean = self.target.startswith(arg)
  if boolean != self.expected:
    self.failed("%r.startswith(%r) : failed." % (self.target, arg))

class FooTest(object):
  def test_original_assertion1(self):
    ok ("foobar").startswith("foob")
    not_ok ("foobar").startswith("a")
  def test_original_assertion2(self):
    ok ("foobar").startswith("afoo")
  def test_original_assertion3(self):
    not_ok ("foobar").startswith("foo")

run(FooTest)
"""[1:]
expected = r"""
* FooTest.test_original_assertion1 ... [ok]
* FooTest.test_original_assertion2 ... [NG] 'foobar'.startswith('afoo') : failed.
   _test_.py:15: ok ("foobar").startswith("afoo")
* FooTest.test_original_assertion3 ... [NG] not 'foobar'.startswith('foo') : failed.
   _test_.py:17: not_ok ("foobar").startswith("foo")
"""[1:]
do_test_with(desc, script, expected)


###
desc = "Should"
script = r"""
from oktest import *

class FooTest(object):
  def test_should1(self):
    ok ("foobar").should.startswith("foob")
  def test_should2(self):
    ok ("foobar").should.startswith("aaa")
  def test_should3(self):
    ok ("foobar").should.start_with("foob")   # AttributeError
  def test_should4(self):
    ok (Bar('sasaki')).should.name()          # ValueError: not a callable
  def test_should5(self):
    ok ("Sasaki").should.upper()              # ValueError: expected to return True or False

class Bar(object):
  def __init__(self, name):
    self.name = name

run(FooTest)
"""[1:]
expected = r"""
* FooTest.test_should1 ... [ok]
* FooTest.test_should2 ... [NG] 'foobar'.startswith('aaa') : failed.
   _test_.py:7: ok ("foobar").should.startswith("aaa")
* FooTest.test_should3 ... [ERROR] AttributeError: 'str' object has no attribute 'start_with'
  - _test_.py:9:  ok ("foobar").should.start_with("foob")   # AttributeError
  - /Users/kwatch/src/oktest/python/lib/oktest.py:442:  val = getattr(ass.target, key)
* FooTest.test_should4 ... [ERROR] ValueError: Bar.name: not a callable.
  - _test_.py:11:  ok (Bar('sasaki')).should.name()          # ValueError: not a callable
  - /Users/kwatch/src/oktest/python/lib/oktest.py:445:  raise ValueError(msg)
* FooTest.test_should5 ... [ERROR] ValueError: 'Sasaki'.upper(): expected to return True or False but it returned 'SASAKI'.
  - _test_.py:13:  ok ("Sasaki").should.upper()              # ValueError: expected to return True or False
  - /Users/kwatch/src/oktest/python/lib/oktest.py:453:  raise ValueError(msg)
"""[1:]
do_test_with(desc, script, expected, re.compile(r'.*oktest\.py:\d+\:.*\n'))

###
desc = "Should_not"
script = r"""
from oktest import *

class FooTest(object):
  def test_should_not1(self):
    ok ("foobar").should_not.startswith("aaa")
  def test_should_not2(self):
    ok ("foobar").should_not.startswith("foo")

run(FooTest)
"""[1:]
expected = r"""
* FooTest.test_should_not1 ... [ok]
* FooTest.test_should_not2 ... [NG] not 'foobar'.startswith('foo') : failed.
   _test_.py:7: ok ("foobar").should_not.startswith("foo")
"""[1:]
do_test_with(desc, script, expected, re.compile(r'.*oktest\.py:\d+\:.*\n'))


### run (with class objects)
desc = "run (with class objects)"
script = r"""
from oktest import *
class FooTest(object):
    def test_1(self):
        ok (1+1) == 2
class BarTest(object):
    def test_2(self):
        ok (1+1) == 2
run(FooTest, BarTest)
"""
expected = r"""
* FooTest.test_1 ... [ok]
* BarTest.test_2 ... [ok]
"""[1:]
do_test_with(desc, script, expected)

### run (with pattern)
desc = "run (with pattern)"
script = r"""
from oktest import *
class FooTest(object):
    def test_1(self):
        ok (1+1) == 2
class BarTestCase(object):
    def test_2(self):
        ok (1+1) == 2
class BazTestCase(object):
    def test_3(self):
        ok (1+1) == 2
run('.*TestCase$')
"""
expected = r"""
* BarTestCase.test_2 ... [ok]
* BazTestCase.test_3 ... [ok]
"""[1:]
do_test_with(desc, script, expected)

### run (without args)
desc = "run (without args)"
script = r"""
from oktest import *
class FooTest(object):
    def test_1(self):
        ok (1+1) == 2
class BarTestCase(object):
    def test_2(self):
        ok (1+1) == 2
class BazTestCase(object):
    def test_3(self):
        ok (1+1) == 2
run()
"""
expected = r"""
* FooTest.test_1 ... [ok]
* BarTestCase.test_2 ... [ok]
* BazTestCase.test_3 ... [ok]
"""[1:]
do_test_with(desc, script, expected)

### run (skip AssertionError)
desc = "run (skip AssertionError)"
script = r"""
from oktest import *
class FooTestCase(object):
    def test_1(self):
        assert 1 != 1
        ok (1+1) == 2
try:
    run()
except Exception:
    import sys
    ex = sys.exc_info()[1]
    print("")
    print("ex.__class__.__name__=%r" % ex.__class__.__name__)
    print("str(ex)=%r" % str(ex))
"""
expected = r"""
* FooTestCase.test_1 ... 
ex.__class__.__name__='AssertionError'
str(ex)=''
"""[1:]
do_test_with(desc, script, expected)

## _min_firstlineno_of_methods
desc = "_min_firstlineno_of_methods"
script = r"""
import oktest                  # 1
class FooTest(object):         # 2
    def test_2(self):          # 3
        pass                   # 4
    def test_1(self):          # 5
        pass                   # 6
class BarTest(FooTest):        # 7
    def test_1(self):          # 8
        pass                   # 9
class BazTest(FooTest):        # 10
    def _test_1(self):         # 11
        pass                   # 12
print(oktest._min_firstlineno_of_methods(FooTest))   #=> 3
print(oktest._min_firstlineno_of_methods(BarTest))   #=> 8
print(oktest._min_firstlineno_of_methods(BazTest))   #=> -1
"""[1:]
expected = r"""
3
8
-1
"""[1:]
do_test_with(desc, script, expected)



### dummy_file (with with-statement)
desc = "dummy_file (with with-statement)"
script = r"""
from __future__ import with_statement
from oktest import *
from oktest.helper import *
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
from oktest.helper import *
class FooTest(object):
    def test_dummy_file2(self):
        filename = '_dummy_.txt'
        called = [False]
        def f():
            called[0] = True
            ok (filename).is_file()
            ok (open(filename).read()) == 'hogehoge'
        dummy_file(filename, 'hogehoge').run(f)
        ok (called[0]) == True
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
from oktest.helper import *
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
from oktest.helper import *
class FooTest(object):
    def test_dummy_dir2(self):
        dirname = '_dummy_.d'
        called = [False]
        def f():
            called[0] = True
            ok (dirname).is_dir()
        dummy_dir(dirname).run(f)
        ok (called[0]) == True
        ok (dirname).not_exist()
run(FooTest)
"""
expected = "* FooTest.test_dummy_dir2 ... [ok]\n"
do_test_with(desc, script, expected)

### dummy_environ_vars (with with-statement)
desc = "dummy_environ_vars (with with-statement)"
script = r"""
from __future__ import with_statement
import os
from oktest import *
from oktest.helper import *
class FooTest(object):
    def test_dummy_environ_vars(self):
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
run(FooTest)
"""
expected = "* FooTest.test_dummy_environ_vars ... [ok]\n"
if with_statement_supported:
    do_test_with(desc, script, expected)

### dummy_environ_vars (without with-statement)
desc = "dummy_environ_vars (without with-statement)"
script = r"""
import os
from oktest import *
from oktest.helper import *
class FooTest(object):
    def test_dummy_environ_vars2(self):
        os.environ['AAAA'] = 'hoge'
        os.environ['CCCC'] = ''
        called = [False]
        def f():
            called[0] = True
            ok (os.environ['AAAA']) == 'aaa'
            ok (os.environ['BBBB']) == 'bbb'
            ok (os.environ['CCCC']) == 'ccc'
        dummy_environ_vars(AAAA='aaa', BBBB='bbb', CCCC='ccc').run(f)
        ok (called[0]) == True
        ok (os.environ.get('AAAA')) == 'hoge'
        ok ('BBBB' not in os.environ) == True
        ok ('CCCC' in os.environ) == True
        ok (os.environ.get('CCCC')) == ''
run(FooTest)
"""
expected = "* FooTest.test_dummy_environ_vars2 ... [ok]\n"
do_test_with(desc, script, expected)

### dummy_values (with with-statement)
desc = "dummy_values (with with-statement)"
script = r"""
from __future__ import with_statement
import os
from oktest import *
from oktest.helper import *
class FooTest(object):
    def test_dummy_values(self):
        d = {'A': 10, 'B': 20, 'C': 30 }
        with dummy_values(d, {999: 0}, A=100, B=200):
            ok (d) == {'A': 100, 'B': 200, 'C': 30, 999: 0}
        ok (d) == {'A': 10, 'B': 20, 'C': 30 }
run(FooTest)
"""
expected = "* FooTest.test_dummy_values ... [ok]\n"
if with_statement_supported:
    do_test_with(desc, script, expected)

### dummy_values (without with-statement)
desc = "dummy_values (without with-statement)"
script = r"""
import os
from oktest import *
from oktest.helper import *
class FooTest(object):
    def test_dummy_values2(self):
        d = {'A': 10, 'B': 20, 'C': 30 }
        called = [False]
        def f():
            called[0] = True
            ok (d) == {'A': 100, 'B': 200, 'C': 30, 999: 0}
        dummy_values(d, {999: 0}, A=100, B=200).run(f)
        ok (called[0]) == True
        ok (d) == {'A': 10, 'B': 20, 'C': 30 }
run(FooTest)
"""
expected = "* FooTest.test_dummy_values2 ... [ok]\n"
do_test_with(desc, script, expected)

### dummy_attrs (with with-statement)
desc = "dummy_attrs (with with-statement)"
script = r"""
from __future__ import with_statement
import os
from oktest import *
from oktest.helper import *
class Foo(object):
  def __init__(self, x, y):
    self.x = x
    self.y = y
class FooTest(object):
    def test_dummy_attrs(self):
        obj = Foo(10, 20)
        with dummy_attrs(obj, x=100, z=300):
          ok (obj.x) == 100
          ok (obj.y) == 20
          ok (obj.z) == 300
        #
        ok (obj.x) == 10
        ok (obj.y) == 20
        ok (hasattr(obj, 'z')) == False
run(FooTest)
"""
expected = "* FooTest.test_dummy_attrs ... [ok]\n"
if with_statement_supported:
    do_test_with(desc, script, expected)

### dummy_attrs (without with-statement)
desc = "dummy_attrs (without with-statement)"
script = r"""
import os
from oktest import *
from oktest.helper import *
class Foo(object):
  def __init__(self, x, y):
    self.x = x
    self.y = y
class FooTest(object):
    def test_dummy_attrs2(self):
        obj = Foo(10, 20)
        called = [False]
        def f():
          called[0] = True
          ok (obj.x) == 100
          ok (obj.y) == 20
          ok (obj.z) == 300
        dummy_attrs(obj, x=100, z=300).run(f)
        ok (called[0]) == True
        #
        ok (obj.x) == 10
        ok (obj.y) == 20
        ok (hasattr(obj, 'z')) == False
run(FooTest)
"""
expected = "* FooTest.test_dummy_attrs2 ... [ok]\n"
do_test_with(desc, script, expected)

### dummy_io (with with-statement)
desc = "dummy_io (with with-statement)"
script = r"""
from __future__ import with_statement
import sys, os
from oktest import *
from oktest.helper import *
class FooTest(object):
    def test_dummy_io(self):
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
        ok (d_io.stdout) == "Haruhi"
        ok (d_io.stderr) == "Sasaki"
run(FooTest)
"""
expected = "* FooTest.test_dummy_io ... [ok]\n"
if with_statement_supported:
    do_test_with(desc, script, expected)

### dummy_io (without with-statement)
desc = "dummy_io (without with-statement)"
script = r"""
import sys, os
from oktest import *
from oktest.helper import *
class FooTest(object):
    def test_dummy_io(self):
        sin, sout, serr = sys.stdin, sys.stdout, sys.stderr
        called = [False]
        def f(arg1, arg2):
            called[0] = True
            ok (sys.stdin)  != sin
            ok (sys.stdout) != sout
            ok (sys.stderr) != serr
            ok (sys.stdin.read()) == "SOS"
            sys.stdout.write(arg1)
            sys.stderr.write(arg2)
        d_io = dummy_io("SOS")
        d_io.run(f, "Haruhi", "Sasaki")
        ok (called[0]) == True
        ok (sys.stdin).is_(sin)
        ok (sys.stdout).is_(sout)
        ok (sys.stderr).is_(serr)
        ok (d_io.stdout) == "Haruhi"
        ok (d_io.stderr) == "Sasaki"
run(FooTest)
"""
expected = "* FooTest.test_dummy_io ... [ok]\n"
if with_statement_supported:
    do_test_with(desc, script, expected)

### chdir (with with-statement)
desc = "chdir (with with-statement)"
script = r"""
from __future__ import with_statement
import os
from oktest import *
from oktest.helper import *
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
from oktest.helper import *
class FooTest(object):
    def test_chdir2(self):
        def f():
            pwd = os.getcwd()
            called = [False]
            def g():
                called[0] = True
                ok (os.path.basename(os.getcwd())) == '_dummy_.d'
                ok (os.getcwd()) != pwd
                ok (os.getcwd()) == os.path.join(pwd, '_dummy_.d')
            chdir('_dummy_.d', g)
            ok (called[0]) == True
            ok (os.getcwd()) == pwd
        dummy_dir('_dummy_.d')(f)
run(FooTest)
"""
expected = "* FooTest.test_chdir2 ... [ok]\n"
do_test_with(desc, script, expected)

### spec (with with-statement)
desc = "spec (with with-statement)"
script = r"""
from __future__ import with_statement
from oktest import *
from oktest.helper import *
class FooTest(object):
    def test_spec1(self):
        with spec('1+1 is 2') as sp:
            ok (1+1) == 2
        ok (sp.desc) == '1+1 is 2'
    def test_spec2(self):
        with spec('1-1 is 0') as sp:
            ok (1-1) == -1
run(FooTest)
"""
expected = """
* FooTest.test_spec1 ... [ok]
* FooTest.test_spec2 ... [NG] 0 == -1 : failed.
   _test_.py:12: ok (1-1) == -1
"""[1:]
if with_statement_supported:
    do_test_with(desc, script, expected)

### spec (with for-statement)
desc = "spec (with for-statement)"
script = r"""
from __future__ import with_statement
from oktest import *
from oktest.helper import *
class FooTest(object):
    def test_spec1(self):
        for sp in spec('1+1 is 2'):
            ok (1+1) == 2
        ok (sp.desc) == '1+1 is 2'
    def test_spec2(self):
        for _ in spec('1-1 is 0'):
            ok (1-1) == -1
            None.foobar   # raise NameError
run(FooTest)
"""
expected = """
* FooTest.test_spec1 ... [ok]
* FooTest.test_spec2 ... [NG] 0 == -1 : failed.
   _test_.py:12: ok (1-1) == -1
"""[1:]
do_test_with(desc, script, expected)

### using (with with-statement)
desc = "using (with with-statement)"
script = r"""
from __future__ import with_statement
from oktest import *
from oktest.helper import using
class FooTest(object):
    pass
with using(FooTest):
    def test_1(self):
        ok (1+1) == 2
    def test_2(self):
        ok (1*1) == 1
run(FooTest)
"""
expected = """
* FooTest.test_1 ... [ok]
* FooTest.test_2 ... [ok]
"""[1:]
if with_statement_supported:
    do_test_with(desc, script, expected)


### Tracer (function)
desc = "Tracer (function)"
script = r"""
from oktest import *
from oktest.tracer import Tracer
def f1(a, b):
    return f2(a + f3(b))
def f2(a):
    return a+2
def f3(b):
    return b*2
tr = Tracer()
f1 = tr.trace_func(f1)
f2 = tr.trace_func(f2)
f3 = tr.trace(f3)
print(f1(3, 5))
for call in tr:
    print("---")
    print(repr(call))
    print(repr(call.receiver))
    print(repr(call.name))
    print(repr(call.args))
    print(repr(call.kwargs))
    print(repr(call.ret))
"""[1:]
expected = """
15
---
f1(3, 5) #=> 15
None
'f1'
(3, 5)
{}
15
---
f3(5) #=> 10
None
'f3'
(5,)
{}
10
---
f2(13) #=> 15
None
'f2'
(13,)
{}
15
"""[1:]
do_test_with(desc, script, expected)

### Tracer (instance method)
desc = "Tracer (instance method)"
script = r"""
from oktest import *
from oktest.tracer import Tracer
class Dummy(object):
    def f1(self, x, y):
        return [self.f2(x, y=y),
                self.f2(y, y=x)]
    def f2(self, x=None, y=None):
        return x-y
obj = Dummy()
tr = Tracer()
tr.trace_method(obj, 'f1', 'f2')
ret = obj.f1(5, 3)
print(ret)
for call in tr:
    print('---')
    print(repr(call))
    print(call.receiver is obj)
    print(repr(call.name))
    print(repr(call.args))
    print(repr(call.kwargs))
    print(repr(call.ret))
"""[1:]
expected = """
[2, -2]
---
f1(5, 3) #=> [2, -2]
True
'f1'
(5, 3)
{}
[2, -2]
---
f2(5, y=3) #=> 2
True
'f2'
(5,)
{'y': 3}
2
---
f2(3, y=5) #=> -2
True
'f2'
(3,)
{'y': 5}
-2
"""[1:]
do_test_with(desc, script, expected)

### Tracer (class method)
desc = "Tracer (class method)"
script = r"""
from oktest import *
from oktest.tracer import Tracer
class Dummy(object):
    @classmethod
    def f1(cls, x, y):
        return [cls.__name__,
                cls.f2(x, y=y),
                cls.f2(y, y=x)]
    @classmethod
    def f2(cls, x=None, y=None):
        return x-y
tr = Tracer()
tr.trace_method(Dummy, 'f1', 'f2')
ret = Dummy.f1(5, 3)
print(ret)
for call in tr:
    print("---")
    print(repr(call))
    print(call.receiver is Dummy)
    print(repr(call.name))
    print(repr(call.args))
    print(repr(call.kwargs))
    print(repr(call.ret))
"""[1:]
expected = """
['Dummy', 2, -2]
---
f1(5, 3) #=> ['Dummy', 2, -2]
True
'f1'
(5, 3)
{}
['Dummy', 2, -2]
---
f2(5, y=3) #=> 2
True
'f2'
(5,)
{'y': 3}
2
---
f2(3, y=5) #=> -2
True
'f2'
(3,)
{'y': 5}
-2
"""[1:]
do_test_with(desc, script, expected)

### Tracer (repr style)
desc = "Tracer (repr style)"
script = r"""
from oktest import *
from oktest.tracer import Tracer
class Dummy(object):
    def f1(self, *args, **kwargs):
        return 1
    def __repr__(self):
        return '#<Dummy>'
tr = Tracer()
obj = Dummy()
tr.trace_method(obj, 'f1')
obj.f1(10,20,x=30)
print(repr(tr[0]))
tr[0] == []
print(repr(tr[0]))
tr[0] == ()
print(repr(tr[0]))
"""[1:]
expected = """
f1(10, 20, x=30) #=> 1
[#<Dummy>, 'f1', (10, 20), {'x': 30}, 1]
(#<Dummy>, 'f1', (10, 20), {'x': 30}, 1)
"""[1:]
do_test_with(desc, script, expected)

### Tracer (fake)
desc = "Tracer (fake_func)"
script = r"""
from oktest import *
from oktest.tracer import Tracer
def f(x, y, z=0):
    return x + y + z
def block(orig, *args, **kwargs):
    v = orig(*args, **kwargs)
    return 'v=%s' % v
tr = Tracer()
f = tr.fake_func(f, block)
print(f(10, 20, z=7))  #=> 'v=37'
print(repr(tr[0]))   #=> f(10, 20, z=7) #=> 'v=37'
print(tr[0].receiver is None)  #=> True
print(tr[0].name)    #=> f
print(tr[0].args)    #=> (10, 20)
print(tr[0].kwargs)  #=> {'z': 7}
print(tr[0].ret)     #=> 'v=37'
print('---')
class Hello(object):
    def hello(self, name):
        return 'Hello %s!' % name
    def hi(self):
        pass
obj = Hello()
tr.fake_method(obj, hello=block, hi="Hi!", ya="Ya!")
print(obj.hello('World'))  #=> v=Hello World!
print(repr(tr[1]))    #=> hello('World') #=> 'v=Hello World!'
print(tr[1].receiver is obj)  #=> True
print(tr[1].name)     #=> hello
print(tr[1].args)     #=> ('World',)
print(tr[1].kwargs)   #=> {}
print(tr[1].ret)      #=> v=Hello World!
print('---')
print(obj.hi('SOS'))  #=> Hi!
print(repr(tr[2]))    #=> hi('SOS') #=> 'Hi!'
print(tr[2].receiver is obj)  #=> True
print(tr[2].name)     #=> hi
print(tr[2].args)     #=> ('SOS',)
print(tr[2].kwargs)   #=> {}
print(tr[2].ret)      #=> Hi!
print('---')
print(obj.ya('SOS'))  #=> Ya!
print(repr(tr[3]))    #=> ya('SOS') #=> 'Ya!'
print(tr[3].receiver is obj)  #=> True
print(tr[3].name)     #=> ya
print(tr[3].args)     #=> ('SOS',)
print(tr[3].kwargs)   #=> {}
print(tr[3].ret)      #=> Ya!
"""[1:]
expected = """
v=37
f(10, 20, z=7) #=> 'v=37'
True
f
(10, 20)
{'z': 7}
v=37
---
v=Hello World!
hello('World') #=> 'v=Hello World!'
True
hello
('World',)
{}
v=Hello World!
---
Hi!
hi('SOS') #=> 'Hi!'
True
hi
('SOS',)
{}
Hi!
---
Ya!
ya('SOS') #=> 'Ya!'
True
ya
('SOS',)
{}
Ya!
"""[1:]
do_test_with(desc, script, expected)


### FakeObject class
desc = "FakeObject class"
script = r"""
from oktest import *
from oktest.tracer import FakeObject
class FakeObjectTest(object):
    def test_fake_object(self):
        obj = FakeObject(hi="Hi", hello=lambda self, x: "Hello %s!" % x)
        ok (obj.hi()) == 'Hi'
        ok (obj.hello("SOS")) == 'Hello SOS!'
        ok (obj._calls[0].name  ) == 'hi'
        ok (obj._calls[0].args  ) == ()
        ok (obj._calls[0].kwargs) == {}
        ok (obj._calls[0].ret   ) == 'Hi'
        ok (obj._calls[1].name  ) == 'hello'
        ok (obj._calls[1].args  ) == ('SOS', )
        ok (obj._calls[1].kwargs) == {}
        ok (obj._calls[1].ret   ) == 'Hello SOS!'
run()
"""[1:]
expected = """
* FakeObjectTest.test_fake_object ... [ok]
"""[1:]
do_test_with(desc, script, expected)

### Tracer.fake_obj()
desc = "Tracer.fake_obj()"
script = r"""
import sys
from oktest import *
from oktest.tracer import Tracer
class FakeObjectTest(object):
    def test_dummy(self):
        tr = Tracer()
        ## create dummy object
        obj1 = tr.fake_obj(hi="Hi!")
        obj2 = tr.fake_obj(hello=lambda self, x: "Hello %s!" % x)
        ## call dummy method
        ok (obj2.hello("SOS")) == 'Hello SOS!'
        ok (obj1.hi())         == 'Hi!'
        ## check result
        ok (tr[0].name  ) == 'hello'
        ok (tr[0].args  ) == ('SOS', )
        ok (tr[0].kwargs) == {}
        ok (tr[0].ret   ) == 'Hello SOS!'
        ok (tr[1].name  ) == 'hi'
        ok (tr[1].args  ) == ()
        ok (tr[1].kwargs) == {}
        ok (tr[1].ret   ) == 'Hi!'
        ## __iter__() and __eq__()
        ok (tr[0].list())  == [obj2, 'hello', ('SOS',), {}, 'Hello SOS!']
        ok (tr[0])         == [obj2, 'hello', ('SOS',), {}, 'Hello SOS!']
        ok (tr[1].tuple()) == (obj1, 'hi', (), {}, 'Hi!')
        ok (tr[1])         == (obj1, 'hi', (), {}, 'Hi!')
run()
"""[1:]
expected = """
* FakeObjectTest.test_dummy ... [ok]
"""[1:]
do_test_with(desc, script, expected)


## flatten
desc = "flatten()"
script = r"""
from oktest import ok, run
from oktest.helper import flatten
class FooTest(object):
    def test_flatten(self):
        ok (flatten([1, [2, 3, [4, 5, [[[6]]]], [7, 8]]])) == [1,2,3,4,5,6,7,8]
run(FooTest)
"""
expected = """
* FooTest.test_flatten ... [ok]
"""[1:]
do_test_with(desc, script, expected)

## rm_rf()
desc = "rm_rf()"
script = r"""
import os
from oktest import ok, not_ok, run
from oktest.helper import flatten, rm_rf
class FooTest(object):
    def setup(self):
        os.mkdir('_rm_rf')
        os.mkdir('_rm_rf/A')
        os.mkdir('_rm_rf/B')
        os.mkdir('_rm_rf/B/C')
        open('_rm_rf/B/C/X.txt', 'w').write('xxx')
        open('_rm_rf/Y.txt', 'w').write('yyy')
        assert os.path.isfile('_rm_rf/B/C/X.txt')
        assert os.path.isfile('_rm_rf/Y.txt')
    def after(setup):
        import shutil
        if os.path.isdir('_rm_rf'):
            shutil.rmtree('_rm_rf')
    def test_remove_files_recursively(self):
        args = ['_rm_rf/A', '_rm_rf/B', '_rm_rf/Y.txt']
        rm_rf(*args)
        for arg in flatten(args):
            ok (os.path.exists(arg)) == False
    def test_flatten_args(self):
        args = ['_rm_rf/A', ['_rm_rf/B', '_rm_rf/Y.txt']]
        rm_rf(args)
        for arg in flatten(args):
            ok (os.path.exists(arg)) == False
    def test_ignore_unexist_files(self):
        args = ['_rm_rf/A', '_rm_rf/K', '_rm_rf/Z.txt']
        def f():
            rm_rf(*args)
        not_ok (f).raises(Exception)
run(FooTest)
"""
expected = """
* FooTest.test_remove_files_recursively ... [ok]
* FooTest.test_flatten_args ... [ok]
* FooTest.test_ignore_unexist_files ... [ok]
"""[1:]
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
    def test3(self):   # bug: [ERROR] IndexError: list index out of range
       ok ("") == "\n"
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
* FooTest.test3 ... [NG] '' == '\n' : failed.
   _test_.py:10: ok ("") == "\n"
--- expected 
+++ actual 
@@ -1,1 +1,1 @@
-
+
\ No newline at end of string
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
  def test_nested(self):
    self._test1()
  def _test1(self):
    self._test2()
  def _test2(self):
    ok (1+1) == 0
run(FooTest)
"""[1:]
expected = r"""
### FooTest
.fEf
Failed: FooTest#test_failed()
  2 == 3 : failed.
  File "_test_.py", line 9, in test_failed
    ok (1+1) == 3
ERROR: FooTest#test_error()
  ValueError: invalid literal for int() with base 10: 'aaa'
  File "_test_.py", line 11, in test_error
    ok (int('aaa')) == 0
Failed: FooTest#test_nested()
  2 == 0 : failed.
  File "_test_.py", line 13, in test_nested
    self._test1()
  File "_test_.py", line 15, in _test1
    self._test2()
  File "_test_.py", line 17, in _test2
    ok (1+1) == 0
"""[1:]
if python2 and sys.version_info[1] <= 4:
    expected = expected.replace("int() with base 10: 'aaa'", 'int(): aaa')
os.environ['OKTEST_REPORTER'] = 'SimpleReporter'
do_test_with(desc, script, expected)
del os.environ['OKTEST_REPORTER']


## checking tested or not
desc = "checking tested or not"
script = r"""
from oktest import *
import sys
sys.stderr = sys.stdout
import unittest
class FooTest(object):
  def test_1(self):
    ok (1+1) == 2
  def test_2(self):
    ok (1+1)
  def test_3(self):
    not_ok (1+1)
run(FooTest)
"""[1:]
expected = r"""
### FooTest
.*** warning: oktest: ok() is called but not tested. (file '_test_.py', line 9)
.*** warning: oktest: not_ok() is called but not tested. (file '_test_.py', line 11)
.
"""[1:]
do_test_with(desc, script, expected)

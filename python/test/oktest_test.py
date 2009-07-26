###
### $Release:$
### $Copyright$
### $License$
###

import sys, os, re
from StringIO import StringIO
if os.path.isdir('lib'):
    sys.path.append('lib')
    os.environ['PYTHONPATH'] ='lib'
elif os.path.isdir('../lib'):
    sys.path.append('../lib')
    os.environ['PYTHONPATH'] = '../lib'
import oktest

echo = sys.stdout.write

def do_test_with(desc, script, expected):
    filename = '_test_.py'
    try:
        echo("- %s..." % desc)
        open(filename, 'w').write(script)
        output = os.popen('python '+filename).read()
        if isinstance(output, str):
            output = re.sub(r' at 0x[0-9a-f]{6}', '', output)
        if output == expected:
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
        ok(1+1, '==', 2)
invoke_tests(FooTest)
"""
expected = "* FooTest.test_plus ... [ok]\n"
do_test_with(desc, script, expected)

###
desc = "failed script"
script = r"""
from oktest import *
class FooTest(object):
    def test_plus(self):
        ok(1+1, '==', 1)
invoke_tests(FooTest)
"""[1:]
expected = r"""
* FooTest.test_plus ... [NG] 2 == 1 : failed.
   _test_.py:4: ok(1+1, '==', 1)
"""[1:]
do_test_with(desc, script, expected)

###
desc = "class name pattern"
script = r"""
from oktest import *
class FooTest(object):
    def test_plus(self):
        ok(1+1, '==', 2)
class BarTest(object):
    def test_minus(self):
        ok(4-1, '==', 3)
invoke_tests('Test$')
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
    def before_each(self):
        print('before_each() called.')
    def after_each(self):
        print('after_each() called.')
    #
    def test_1(self):
        print('test_1() called.')
    def test_2(self):
        print('test_2() called.')
invoke_tests('FooTest')
"""[1:]
expected = r"""
before_all() called.
* FooTest.test_1 ... before_each() called.
test_1() called.
after_each() called.
[ok]
* FooTest.test_2 ... before_each() called.
test_2() called.
after_each() called.
[ok]
after_all() called.
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op '=='"
script = r"""
from oktest import *
class FooTest(object):
    def test_inteq(self):
        ok(4*4, '==', 16)
    def test_streq(self):
        ok('FOO'.lower(), '==', 'foo')
class BarTest(object):
    def test_inteq(self):
        ok(4*4, '==', 15)
    def test_streq(self):
        ok("foo".upper(), '==', 'foo')
invoke_tests('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_inteq ... [ok]
* FooTest.test_streq ... [ok]
* BarTest.test_inteq ... [NG] 16 == 15 : failed.
   _test_.py:9: ok(4*4, '==', 15)
* BarTest.test_streq ... [NG] 'FOO' == 'foo' : failed.
   _test_.py:11: ok("foo".upper(), '==', 'foo')
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op '!='"
script = r"""
from oktest import *
class FooTest(object):
    def test_inteq(self):
        ok(4*4, '!=', 15)
    def test_streq(self):
        ok('FOO'.lower(), '!=', 'FOO')
class BarTest(object):
    def test_inteq(self):
        ok(4*4, '!=', 16)
    def test_streq(self):
        ok("foo".upper(), '!=', 'FOO')
invoke_tests('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_inteq ... [ok]
* FooTest.test_streq ... [ok]
* BarTest.test_inteq ... [NG] 16 != 16 : failed.
   _test_.py:9: ok(4*4, '!=', 16)
* BarTest.test_streq ... [NG] 'FOO' != 'FOO' : failed.
   _test_.py:11: ok("foo".upper(), '!=', 'FOO')
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op '>, >=, <, <='"
script = r"""
from oktest import *
class FooTest(object):
    def test_gt(self):
        ok(2, '>', 1)
    def test_ge(self):
        ok(2, '>=', 2)
    def test_lt(self):
        ok(1, '<', 2)
    def test_le(self):
        ok(2, '<=', 2)
class BarTest(object):
    def test_gt(self):
        ok(2, '>', 2)
    def test_ge(self):
        ok(1, '>=', 2)
    def test_lt(self):
        ok(2, '<', 2)
    def test_le(self):
        ok(2, '<=', 1)
invoke_tests('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_ge ... [ok]
* FooTest.test_gt ... [ok]
* FooTest.test_le ... [ok]
* FooTest.test_lt ... [ok]
* BarTest.test_ge ... [NG] 1 >= 2 : failed.
   _test_.py:15: ok(1, '>=', 2)
* BarTest.test_gt ... [NG] 2 > 2 : failed.
   _test_.py:13: ok(2, '>', 2)
* BarTest.test_le ... [NG] 2 <= 1 : failed.
   _test_.py:19: ok(2, '<=', 1)
* BarTest.test_lt ... [NG] 2 < 2 : failed.
   _test_.py:17: ok(2, '<', 2)
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op '=~'"
script = r"""
from oktest import *
class FooTest(object):
    def test_match(self):
        ok("123@mail.com", '=~', r'\w+@\w+(\.\w+)')
    def test_match2(self):
        import re
        ok("123@mail.com", '=~', re.compile(r'^\w+@\w+(\.\w+)$'))
class BarTest(object):
    def test_match(self):
        ok("abc", '=~', r'\d+')
    def test_match2(self):
        import re
        ok("abc", '=~', re.compile(r'\d+'))
invoke_tests('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_match ... [ok]
* FooTest.test_match2 ... [ok]
* BarTest.test_match ... [NG] 'abc' =~ '\\d+' : failed.
   _test_.py:10: ok("abc", '=~', r'\d+')
* BarTest.test_match2 ... [NG] 'abc' =~ <_sre.SRE_Pattern object> : failed.
   _test_.py:13: ok("abc", '=~', re.compile(r'\d+'))
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op '!~'"
script = r"""
from oktest import *
class FooTest(object):
    def test_match(self):
        ok("foo", '!~', r'\d+')
    def test_match2(self):
        import re
        ok("foo", '!~', re.compile(r'\d+'))
class BarTest(object):
    def test_match(self):
        ok("foo", '!~', r'\w+')
    def test_match2(self):
        import re
        ok("foo", '!~', re.compile(r'\w+'))
invoke_tests('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_match ... [ok]
* FooTest.test_match2 ... [ok]
* BarTest.test_match ... [NG] 'foo' !~ '\\w+' : failed.
   _test_.py:10: ok("foo", '!~', r'\w+')
* BarTest.test_match2 ... [NG] 'foo' !~ <_sre.SRE_Pattern object> : failed.
   _test_.py:13: ok("foo", '!~', re.compile(r'\w+'))
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op 'is', 'is not'"
script = r"""
from oktest import *
val1 = {'x': 10}
val2 = {'x': 10}
class FooTest(object):
    def test_is(self):
        ok(val1, 'is', val1)
    def test_is_not(self):
        ok(val1, 'is not', val2)
class BarTest(object):
    def test_is(self):
        ok(val1, 'is', val2)
    def test_is_not(self):
        ok(val1, 'is not', val1)
invoke_tests('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_is ... [ok]
* FooTest.test_is_not ... [ok]
* BarTest.test_is ... [NG] {'x': 10} is {'x': 10} : failed.
   _test_.py:11: ok(val1, 'is', val2)
* BarTest.test_is_not ... [NG] {'x': 10} is not {'x': 10} : failed.
   _test_.py:13: ok(val1, 'is not', val1)
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op 'in', 'not in'"
script = r"""
from oktest import *
L = [0,10,20,30]
class FooTest(object):
    def test_in(self):
        ok(10, 'in', L)
    def test_not_in(self):
        ok(11, 'not in', L)
class BarTest(object):
    def test_in(self):
        ok(11, 'in', L)
    def test_not_in(self):
        ok(10, 'not in', L)
invoke_tests('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_in ... [ok]
* FooTest.test_not_in ... [ok]
* BarTest.test_in ... [NG] 11 in [0, 10, 20, 30] : failed.
   _test_.py:10: ok(11, 'in', L)
* BarTest.test_not_in ... [NG] 10 not in [0, 10, 20, 30] : failed.
   _test_.py:12: ok(10, 'not in', L)
"""[1:]
do_test_with(desc, script, expected)

###
desc = "op function"
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
        ok("foobar.txt", os.path.isfile)
    def test_isdir(self):
        ok("foobar.d", os.path.isdir)
    def test_isnotfile(self):
        ok("foobar.d", os.path.isfile, False)
    def test_isnotdir(self):
        ok("foobar.txt", os.path.isdir, False)
invoke_tests('FooTest', 'BarTest')
"""[1:]
expected = r"""
* FooTest.test_isdir ... [ok]
* FooTest.test_isfile ... [ok]
* FooTest.test_isnotdir ... [ok]
* FooTest.test_isnotfile ... [ok]
"""[1:]
do_test_with(desc, script, expected)

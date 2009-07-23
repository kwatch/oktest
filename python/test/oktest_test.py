import sys, os, re
from StringIO import StringIO
if os.path.isdir('lib'):
    sys.path.append('lib')
elif os.path.isdir('../lib'):
    sys.path.append('../lib')
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
                lf = (not expected and expected[-1] != "\n") and "\n" or ""
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

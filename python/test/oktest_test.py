import sys, os
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
        echo("* %s..." % desc)
        open(filename, 'w').write(script)
        output = os.popen('python '+filename).read()
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


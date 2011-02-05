# -*- coding: utf-8 -*-

###
### oktest.py -- new style test utility
###
### $Release: 0.7.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

__all__ = ('ok', 'not_ok', 'run', 'spec',)

import sys, os, re, types, traceback

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3
if python2:
    from cStringIO import StringIO
    def _is_string(val):
        return isinstance(val, (str, unicode))
    def _is_class(obj):
        return isinstance(obj, (types.TypeType, types.ClassType))
    def _is_unbound(method):
        return not method.im_self
    def _func_name(func):
        return func.func_name
    def _func_firstlineno(func):
        func = getattr(func, 'im_func', func)
        return func.func_code.co_firstlineno
    def _read_file(fname):
        f = open(fname)
        s = f.read()
        f.close()
        return s
if python3:
    from io import StringIO
    def _is_string(val):
        return isinstance(val, (str, bytes))
    def _is_class(obj):
        return isinstance(obj, (type, ))
    def _is_unbound(method):
        return not method.__self__
    def _func_name(func):
        return func.__name__
    def _func_firstlineno(func):
        return func.__code__.co_firstlineno
    def _read_file(fname, encoding='utf-8'):
        #with open(fname, encoding=encoding) as f:
        #    s = f.read()
        f = open(fname, encoding=encoding)
        s = f.read()
        f.close()
        return s

def _get_location(depth=0):
    frame = sys._getframe(depth+1)
    return (frame.f_code.co_filename, frame.f_lineno)

def _new_module(name, local_vars, helper=None):
    mod = type(sys)(name)
    sys.modules[name] = mod
    mod.__dict__.update(local_vars)
    if helper and getattr(mod, '__all__', None):
        for k in mod.__all__:
            helper.__dict__[k] = mod.__dict__[k]
        helper.__all__ += mod.__all__
    return mod


__unittest = True    # see unittest.TestResult._is_relevant_tb_level()

## not used for compatibility with unittest
#class TestFailed(AssertionError):
#
#    def __init__(self, mesg, file=None, line=None, diff=None):
#        AssertionError.__init__(self, mesg)
#        self.file = file
#        self.line = line
#        self.diff = diff
#

ASSERTION_ERROR = AssertionError


def ex2msg(ex):
    #return ex.message   # deprecated since Python 2.6
    #return str(ex)      # may be empty
    #return ex.args[0]   # ex.args may be empty (ex. AssertionError)
    #return (ex.args or ['(no error message)'])[0]
    return str(ex) or '(no error message)'


def _msg(target, op, other=None):
    if   op.endswith('()'):   msg = '%r%s'     % (target, op)
    elif op.startswith('.'):  msg = '%r%s(%r)' % (target, op, other)
    else:                     msg = '%r %s %r' % (target, op, other)
    msg += " : failed."
    if op == '==' and target != other and _is_string(target) and _is_string(other):
        if DIFF:
            #if python2 or isinstance(target, str) and isinstance(other, str):
            is_a = isinstance
            if (            is_a(target, str)     and is_a(other, str)    )  or \
               (python2 and is_a(target, unicode) and is_a(other, unicode)):
                diff = _diff(target, other)
                return (msg, diff)
    return msg


DIFF = True

def _diff(target, other):
    from difflib import unified_diff
    if hasattr(DIFF, '__call__'):
        expected = [ DIFF(line) + "\n" for line in other.splitlines(True) ]
        actual   = [ DIFF(line) + "\n" for line in target.splitlines(True) ]
    else:
        if other.find("\n") == -1 and target.find("\n") == -1:
            expected, actual = [other + "\n"], [target + "\n"]
        else:
            expected, actual = other.splitlines(True), target.splitlines(True)
            if not expected: expected.append('')
            if not actual:   actual.append('')
            for lines in (expected, actual):
                if not lines[-1].endswith("\n"):
                    lines[-1] += "\n\\ No newline at end of string\n"
    return ''.join(unified_diff(expected, actual, 'expected', 'actual', n=2))


def assertion(func):
    """decorator to declare assertion function.
       ex.
         @oktest.assertion
         def startswith(self, arg):
           boolean = self.target.startswith(arg)
           if boolean != self.expected:
             self.failed("%r.startswith(%r) : failed." % (self.target, arg))
         #
         ok ("Sasaki").startswith("Sas")
    """
    def deco(self, *args):
        self._tested = True
        return func(self, *args)
    if python2:
        deco.func_name = func.func_name
    deco.__name__ = func.__name__
    deco.__doc__ = func.__doc__
    setattr(AssertionObject, func.__name__, deco)
    return deco


#def deprecated(f):
#    return f


class AssertionObject(object):

    def __init__(self, target, expected=True):
        self.target = target
        self.expected = expected
        self._tested = False
        self._location = None

    def __del__(self):
        if self._tested is False:
            msg = "%s() is called but not tested." % (self.expected and 'ok' or 'not_ok')
            if self._location:
                msg += " (file '%s', line %s)" % self._location
            #import warnings; warnings.warn(msg)
            sys.stderr.write("*** warning: oktest: %s\n" % msg)

    #def not_(self):
    #    self.expected = not self.expected
    #    return self

    def failed(self, msg, depth=2):
        file, line = _get_location(depth + 1)
        diff = None
        if isinstance(msg, tuple):
            msg, diff = msg
        if self.expected is False:
            msg = 'not ' + msg
        raise self._assertion_error(msg, file, line, diff)

    def _assertion_error(self, msg, file, line, diff):
        #return TestFailed(msg, file=file, line=line, diff=diff)
        ex = ASSERTION_ERROR(msg)
        ex.file = file;  ex.line = line;  ex.diff = diff
        ex._raised_by_oktest = True
        return ex

    @property
    def should(self):           # UNDOCUMENTED
        """(experimental) allows user to call True/False method as assertion.
           ex.
             ok ("SOS").should.startswith("S")   # same as ok ("SOS".startswith("S")) == True
             ok ("123").should.isdigit()         # same as ok ("123".isdigit()) == True
        """
        return Should(self, self.expected)

    @property
    def should_not(self):       # UNDOCUMENTED
        """(experimental) allows user to call True/False method as assertion.
           ex.
             ok ("SOS").should_not.startswith("X")   # same as ok ("SOS".startswith("X")) == False
             ok ("123").should_not.isalpha()         # same as ok ("123".isalpha()) == False
        """
        return Should(self, not self.expected)


def _f():

    @assertion
    def __eq__(self, other):
        boolean = self.target == other
        if boolean == self.expected:  return True
        self.failed(_msg(self.target, '==', other))

    @assertion
    def __ne__(self, other):
        boolean = self.target != other
        if boolean == self.expected:  return True
        self.failed(_msg(self.target, '!=', other))

    @assertion
    def __gt__(self, other):
        boolean = self.target > other
        if boolean == self.expected:  return True
        self.failed(_msg(self.target, '>', other))

    @assertion
    def __ge__(self, other):
        boolean = self.target >= other
        if boolean == self.expected:  return True
        self.failed(_msg(self.target, '>=', other))

    @assertion
    def __lt__(self, other):
        boolean = self.target < other
        if boolean == self.expected:  return True
        self.failed(_msg(self.target, '<', other))

    @assertion
    def __le__(self, other):
        boolean = self.target <= other
        if boolean == self.expected:  return True
        self.failed(_msg(self.target, '<=', other))

    @assertion
    def in_delta(self, other, delta):
        boolean = self.target > other - delta
        if boolean != self.expected:
            self.failed(_msg(self.target, '>', other - delta))
        boolean = self.target < other + delta
        if boolean != self.expected:
            self.failed(_msg(self.target, '<', other + delta))
        return True

#    @assertion
#    def __contains__(self, other):
#        boolean = self.target in other
#        if boolean == self.expected:  return True
#        self.failed(_msg(self.target, 'in', other))

    @assertion
    def in_(self, other):
        boolean = self.target in other
        if boolean == self.expected:  return True
        self.failed(_msg(self.target, 'in', other))

    @assertion
    def not_in(self, other):  # DEPRECATED
        boolean = self.target not in other
        if boolean == self.expected:  return True
        self.failed(_msg(self.target, 'not in', other))

    @assertion
    def contains(self, other):
        boolean = other in self.target
        if boolean == self.expected:  return True
        self.failed(_msg(other, 'in', self.target))

    @assertion
    def not_contain(self, other):  # DEPRECATED
        boolean = other in self.target
        if boolean == self.expected:  return True
        self.failed(_msg(other, 'not in', self.target))

    @assertion
    def is_(self, other):
        boolean = self.target is other
        if boolean == self.expected:  return True
        self.failed(_msg(self.target, 'is', other))

    @assertion
    def is_not(self, other):
        boolean = self.target is not other
        if boolean == self.expected:  return True
        self.failed(_msg(self.target, 'is not', other))

    @assertion
    def is_a(self, other):
        boolean = isinstance(self.target, other)
        if boolean == self.expected:  return True
        self.failed("isinstance(%r, %s) : failed." % (self.target, other.__name__))

    @assertion
    def is_not_a(self, other):  # DEPRECATED
        boolean = not isinstance(self.target, other)
        if boolean == self.expected:  return True
        self.failed("not isinstance(%r, %s) : failed." % (self.target, other.__name__))

    @assertion
    def has_attr(self, name):
        boolean = hasattr(self.target, name)
        if boolean == self.expected:  return True
        self.failed("hasattr(%r, %r) : failed." % (self.target, name))

    @assertion
    def matches(self, pattern):
        if isinstance(pattern, type(re.compile('x'))):
            boolean = bool(pattern.search(self.target))
            if boolean == self.expected:  return True
            self.failed("re.search(%r, %r) : failed." % (pattern.pattern, self.target))
        else:
            boolean = bool(re.search(pattern, self.target))
            if boolean == self.expected:  return True
            self.failed("re.search(%r, %r) : failed." % (pattern, self.target))

    @assertion
    def not_match(self, pattern):  # DEPRECATED
        if isinstance(pattern, type(re.compile('x'))):
            boolean = not pattern.search(self.target)
            if boolean == self.expected:  return True
            self.failed("not re.search(%r, %r) : failed." % (pattern.pattern, self.target))
        else:
            boolean = not re.search(pattern, self.target)
            if boolean == self.expected:  return True
            self.failed("not re.search(%r, %r) : failed." % (pattern, self.target))

    @assertion
    def is_file(self):
        boolean = os.path.isfile(self.target)
        if boolean == self.expected:  return True
        self.failed('os.path.isfile(%r) : failed.' % self.target)

    @assertion
    def is_not_file(self):  # DEPRECATED
        boolean = not os.path.isfile(self.target)
        if boolean == self.expected:  return True
        self.failed('not os.path.isfile(%r) : failed.' % self.target)

    @assertion
    def is_dir(self):
        boolean = os.path.isdir(self.target)
        if boolean == self.expected:  return True
        self.failed('os.path.isdir(%r) : failed.' % self.target)

    @assertion
    def is_not_dir(self):  # DEPRECATED
        boolean = not os.path.isdir(self.target)
        if boolean == self.expected:  return True
        self.failed('not os.path.isdir(%r) : failed.' % self.target)

    @assertion
    def exists(self):
        boolean = os.path.exists(self.target)
        if boolean == self.expected:  return True
        self.failed('os.path.exists(%r) : failed.' % self.target)

    @assertion
    def not_exist(self):  # DEPRECATED
        boolean = not os.path.exists(self.target)
        if boolean == self.expected:  return True
        self.failed('not os.path.exists(%r) : failed.' % self.target)

    @assertion
    def raises(self, exception_class, errmsg=None):
        return self._raise_or_not(exception_class, errmsg, self.expected)

    @assertion
    def not_raise(self, exception_class=Exception):
        return self._raise_or_not(exception_class, None, not self.expected)

    def _raise_or_not(self, exception_class, errmsg, flag_raise):
        ex = None
        try:
            self.target()
        except:
            ex = sys.exc_info()[1]
            if isinstance(ex, AssertionError) and not hasattr(ex, '_raised_by_oktest'):
                raise
            self.target.exception = ex
            if flag_raise:
                if not isinstance(ex, exception_class):
                    self.failed('%s%r is kind of %s : failed.' % (ex.__class__.__name__, ex.args, exception_class.__name__), depth=3)
                    #raise
                if errmsg is not None and str(ex) != errmsg:   # don't use ex2msg(ex)!
                    #self.failed("expected %r but got %r" % (errmsg, str(ex)))
                    self.failed("%r == %r : failed." % (str(ex), errmsg), depth=3)   # don't use ex2msg(ex)!
            else:
                if isinstance(ex, exception_class):
                    self.failed('%s should not be raised : failed.' % exception_class.__name__, depth=3)
        else:
            if flag_raise and ex is None:
                self.failed('%s should be raised : failed.' % exception_class.__name__, depth=3)
        return True

    AssertionObject._raise_or_not = _raise_or_not
    AssertionObject.hasattr = has_attr    # for backward compatibility

_f()
del _f


ASSERTION_OBJECT = AssertionObject


def ok(target):
    obj = ASSERTION_OBJECT(target, True)
    obj._location = _get_location(1)
    return obj

def not_ok(target):
    obj = ASSERTION_OBJECT(target, False)
    obj._location = _get_location(1)
    return obj


class Should(object):

    def __init__(self, assertion_object, expected=None):
        self.assertion_object = assertion_object
        if expected is None:
            expected = assertion_object.expected
        self.expected = expected

    def __getattr__(self, key):
        ass = self.assertion_object
        tested = ass._tested
        ass._tested = True
        val = getattr(ass.target, key)
        if not hasattr(val, '__call__'):
            msg = "%s.%s: not a callable." % (type(ass.target).__name__, key)
            raise ValueError(msg)
        ass._tested = tested
        def f(*args, **kwargs):
            ass._tested = True
            ret = val(*args, **kwargs)
            if ret not in (True, False):
                msg = "%r.%s(): expected to return True or False but it returned %r." \
                      % (ass.target, val.__name__, ret)
                raise ValueError(msg)
            if ret != self.expected:
                buf = [ repr(arg) for arg in args ]
                buf.extend([ "%s=%r" % (k, kwargs[k]) for k in kwargs ])
                msg = "%r.%s(%s) : failed." % (ass.target, val.__name__, ", ".join(buf))
                if self.expected is False:
                    msg = "not " + msg
                ass.failed(msg)
        return f


class TestRunner(object):

    def __init__(self, klass, reporter=None):
        self.klass = klass
        if reporter is None:  reporter = REPORTER()
        self.reporter = reporter

    def _test_name(self, name):
        return re.sub(r'^test_?', '', name)

    def _gather_test_methods(self):
        pairs = []   # pairs of method name and function
        for k in dir(self.klass):
            v = getattr(self.klass, k)
            if k.startswith('test') and hasattr(v, '__call__'):
                pairs.append((k, v))
        ## filer by $TEST environment variable
        pattern = os.environ.get('TEST')
        if pattern:
            regexp = re.compile(pattern)
            pairs = [ t for t in pairs if regexp.search(self._test_name(t[0])) ]
        ## sort by linenumber
        pairs.sort(key=lambda t: _func_firstlineno(t[1]))
        return pairs

    def _new_testcase_object(self, method_name, func):
        try:
            obj = self.klass()
        except ValueError:     # unittest.TestCase raises ValueError
            obj = self.klass(method_name)
        obj.__name__ = self._test_name(method_name)
        obj._testMethodName = method_name    # unittest.TestCase compatible
        obj._testMethodDoc = func.__doc__    # unittest.TestCase compatible
        return obj

    def _invoke_before_all(self, klass):
        self.reporter.before_all(klass)
        if hasattr(klass, 'before_all'):
            klass.before_all()

    def _invoke_before(self, obj):
        self.reporter.before(obj)
        if   hasattr(obj, 'before'):       obj.before()
        elif hasattr(obj, 'before_each'):  obj.before_each()  # for backward compatibility
        elif hasattr(obj, 'setUp'):        obj.setUp()

    def _invoke_after(self, obj):
        if   hasattr(obj, 'after'):       obj.after()
        elif hasattr(obj, 'after_each'):  obj.after_each()  # for backward compatibility
        elif hasattr(obj, 'tearDown'):    obj.tearDown()
        self.reporter.after(obj)

    def _invoke_after_all(self, klass):
        if hasattr(klass, 'after_all'):
            klass.after_all()
        self.reporter.after_all(klass)

    def run(self):
        test_methods = self._gather_test_methods()
        self._invoke_before_all(self.klass)
        count = 0
        for method_name, func in test_methods:
            obj = self._new_testcase_object(method_name, func)
            self._invoke_before(obj)
            try:
                try:
                    func(obj)
                    self.reporter.print_ok(obj)
                #except TestFailed, ex:
                except ASSERTION_ERROR:
                    ex = sys.exc_info()[1]
                    if not hasattr(ex, '_raised_by_oktest'):
                        raise
                    count += 1
                    self.reporter.print_failed(obj, ex)
                except Exception:
                    ex = sys.exc_info()[1]
                    count += 1
                    self.reporter.print_error(obj, ex)
            finally:
                self._invoke_after(obj)
        self._invoke_after_all(self.klass)
        return count


TEST_RUNNER = TestRunner


TARGET_PATTERN = '.*(Test|TestCase|_TC)$'

def run(*targets):
    if len(targets) == 0:
        targets = (TARGET_PATTERN, )
    count = 0
    for klass in _target_classes(targets):
        runner = TEST_RUNNER(klass, REPORTER())
        count += runner.run()
    return count

def _target_classes(targets):
    target_classes = []
    rexp_type = type(re.compile('x'))
    vars = None
    for arg in targets:
        if _is_class(arg):
            klass = arg
            target_classes.append(klass)
        elif _is_string(arg) or isinstance(arg, rexp_type):
            rexp = _is_string(arg) and re.compile(arg) or arg
            if vars is None: vars = sys._getframe(2).f_locals
            klasses = [ vars[k] for k in vars if rexp.search(k) and _is_class(vars[k]) ]
            if TESTCLASS_SORT_KEY:
                klasses.sort(key=TESTCLASS_SORT_KEY)
            target_classes.extend(klasses)
        else:
            raise ValueError("%r: not a class nor pattern string." % (arg, ))
    return target_classes


OUT = sys.stdout


def _min_firstlineno_of_methods(klass):
    func_types = (types.FunctionType, types.MethodType)
    d = klass.__dict__
    linenos = [ _func_firstlineno(d[k]) for k in d
                if k.startswith('test') and type(d[k]) in func_types ]
    return linenos and min(linenos) or -1

TESTCLASS_SORT_KEY = _min_firstlineno_of_methods



##
## Reporter
##

class Reporter(object):

    def before_all(self, klass):
        pass

    def after_all(self, klass):
        pass

    def before(self, obj):
        pass

    def after(self, obj):
        pass

    def print_ok(self, obj):
        pass

    def print_failed(self, obj, ex):
        pass

    def print_error(self, obj, ex):
        pass


class BaseReporter(Reporter):

    def before_all(self, klass):
        self.klass = klass

    def _test_ident(self, obj):
        return '%s#%s' % (self.klass.__name__, obj._testMethodName)

    def _get_line_text(self, file, line):
        if not hasattr(self, '_lines'):
            self._lines = {}
        if file not in self._lines:
            if not os.path.isfile(file): return None
            s = _read_file(file)
            self._lines[file] = s.splitlines(True)
        return self._lines[file][line-1]

    def _get_location(self, ex):
        if hasattr(ex, 'file') and hasattr(ex, 'line'):
            text = self._get_line_text(ex.file, ex.line)
            if text: text = text.strip()
            return (ex.file, ex.line, None, text)
        else:
            tb = traceback.extract_tb(sys.exc_info()[2])
            for file, line, func, text in tb:
                if os.path.basename(file) not in ('oktest.py', 'oktest.pyc'):
                    return (file, line, func, text)
            return (None, None, None, None)

    def _write(self, str):
        OUT.write(str)

    def _write_tb(self, filename, linenum, funcname, linetext):
        if funcname:
            self._write('  File "%s", line %s, in %s\n' % (filename, linenum, funcname))
        else:
            self._write('  File "%s", line %s\n' % (filename, linenum))
        if linetext:
            self._write('    %s\n' % linetext)


## NOTICE! reporter spec will be changed frequently
class SimpleReporter(BaseReporter):

    def before_all(self, klass):
        self.klass = klass
        OUT.write("### %s\n" % klass.__name__)
        self.buf = []

    def after_all(self, klass):
        OUT.write("\n")
        OUT.write("".join(self.buf))

    def print_ok(self, obj):
        OUT.write("."); OUT.flush()

    def _write(self, str):
        self.buf.append(str)

    def print_failed(self, obj, ex):
        OUT.write("f"); OUT.flush()
        self._write("Failed: %s()\n" % self._test_ident(obj))
        self._write("  %s\n" % ex2msg(ex))
        file, line, func, text = self._get_location(ex)
        if file:
            #self._write("   %s:%s:  %s\n" % (file, line, text))
            self._write_tb(file, line, func, text)
        if getattr(ex, 'diff', None):
            self._write(ex.diff)

    def print_error(self, obj, ex):
        OUT.write('E'); OUT.flush()
        self._write("ERROR: %s()\n" % self._test_ident(obj))
        self._write("  %s: %s\n" % (ex.__class__.__name__, ex2msg(ex)))
        #traceback.print_exc(file=sys.stdout)
        tb = traceback.extract_tb(sys.exc_info()[2])
        iter = tb.__iter__()
        for filename, linenum, funcname, linetext in iter:
            if os.path.basename(filename) not in ('oktest.py', 'oktest.pyc'):
                break
        self._write_tb(filename, linenum, funcname, linetext)
        for filename, linenum, funcname, linetext in iter:
            self._write_tb(filename, linenum, funcname, linetext)
        tb = iter = None


## NOTICE! reporter spec will be changed frequently
class OldStyleReporter(BaseReporter):

    def before_all(self, klass):
        self.klass = klass

    def after_all(self, klass):
        pass

    def _test_ident(self, obj):
        return '%s.%s' % (self.klass.__name__, obj._testMethodName)

    def before(self, obj):
        OUT.write("* %s ... " % self._test_ident(obj))

    def print_ok(self, obj):
        OUT.write("[ok]\n")

    def print_failed(self, obj, ex):
        OUT.write("[NG] %s\n" % ex2msg(ex))
        file, line, func, text = self._get_location(ex)
        if file:
            OUT.write("   %s:%s: %s\n" % (file, line, text))
        if getattr(ex, 'diff', None):
            OUT.write(ex.diff)

    def print_error(self, obj, ex):
        OUT.write("[ERROR] %s: %s\n" % (ex.__class__.__name__, ex2msg(ex)))
        #traceback.print_exc(file=sys.stdout)
        tb = traceback.extract_tb(sys.exc_info()[2])
        iter = tb.__iter__()
        for filename, linenum, funcname, linetext in iter:
            if os.path.basename(filename) not in ('oktest.py', 'oktest.pyc'):
                break
        OUT.write(    "  - %s:%s:  %s\n" % (filename, linenum, linetext))
        for filename, linenum, funcname, linetext in iter:
            OUT.write("  - %s:%s:  %s\n" % (filename, linenum, linetext))
        tb = iter = None


## NOTICE! reporter spec will be changed frequently
class TapStyleReporter(BaseReporter):

    BOL_PATTERN = re.compile(r'^', re.M)

    def before_all(self, klass):
        self.klass = klass
        OUT.write("### %s\n" % klass.__name__)

    def after_all(self, klass):
        OUT.write("\n")

    def print_ok(self, obj):
        OUT.write("ok     # %s\n" % self._test_ident(obj))

    def print_failed(self, obj, ex):
        OUT.write("not ok # %s\n" % self._test_ident(obj))
        OUT.write("   #  %s\n" % ex2msg(ex))
        file, line, func, text = self._get_location(ex)
        if file:
            OUT.write("   #  %s:%s:  %s\n" % (file, line, text))
        if getattr(ex, 'diff', None):
            OUT.write(re.sub(self.BOL_PATTERN, '   #', ex.diff))

    def print_error(self, obj, ex):
        OUT.write("ERROR  # %s\n" % self._test_ident(obj))
        OUT.write("   #  %s: %s\n" % (ex.__class__.__name__, ex2msg(ex)))
        #traceback.print_exc(file=sys.stdout)
        tb = traceback.extract_tb(sys.exc_info()[2])
        iter = tb.__iter__()
        for file, line, func, text in iter:
            if os.path.basename(file) not in ('oktest.py', 'oktest.pyc'):
                break
        OUT.write(    "   #  %s:%s:  %s" % (file, line, text))
        for filename, linenum, funcname, linetext in iter:
            OUT.write("   #  %s:%s:  %s" % (file, line, text))
        tb = iter = None


REPORTER = SimpleReporter
#REPORTER = OldStyleReporter
#REPORTER = TapStyleReporter
if os.environ.get('OKTEST_REPORTER'):
    REPORTER = globals().get(os.environ.get('OKTEST_REPORTER'))
    if not REPORTER:
        raise ValueError("%s: reporter class not found." % os.environ.get('OKTEST_REPORTER'))



##
## _Context
##
class _Context(object):

    def __enter__(self, *args):
        return self

    def __exit__(self, *args):
        return None

    def __call__(self, func, *args):
        self.__enter__()
        try:
            func(*args)
        finally:
            self.__exit__(*sys.exc_info())



##
## spec()
##
class Spec(_Context):

    def __init__(self, desc):
        self.desc = desc

    def __iter__(self):
        self.__enter__()
        #try:
        #    yield self  # (Python2.4) SyntaxError: 'yield' not allowed in a 'try' block with a 'finally' clause
        #finally:
        #    self.__exit__(*sys.exc_info())
        ex = None
        try:
            yield self
        except:
            ex = None
        self.__exit__(*sys.exc_info())
        if ex:
            raise ex


def spec(desc):
    return Spec(desc)



##
## helpers
##
def _dummy():

    __all__ = ('chdir', 'using')


    class Chdir(_Context):

        def __init__(self, dirname):
            self.dirname = dirname
            self.path    = os.path.abspath(dirname)
            self.back_to = os.getcwd()

        def __enter__(self, *args):
            os.chdir(self.path)
            return self

        def __exit__(self, *args):
            os.chdir(self.back_to)


    class Using(_Context):
        """ex.
             class MyTest(object):
                pass
             with oktest.Using(MyTest):
                def test_1(self):
                  ok (1+1) == 2
             if __name__ == '__main__':
                oktest.run(MyTest)
        """
        def __init__(self, klass):
            self.klass = klass

        def __enter__(self):
            self.locals = sys._getframe(1).f_locals
            self.start_names = self.locals.keys()
            if python3: self.start_names = list(self.start_names)
            return self

        def __exit__(self, *args):
            curr_names = self.locals.keys()
            diff_names = list(set(curr_names) - set(self.start_names))
            for name in diff_names:
                setattr(self.klass, name, self.locals[name])


    def chdir(path, func=None):
        cd = Chdir(path)
        return func is not None and cd(func) or cd

    def using(klass):
        return Using(klass)


    def flatten(arr, type=(list, tuple)):   ## undocumented
        L = []
        for x in arr:
            if isinstance(x, type):
                L.extend(flatten(x))
            else:
                L.append(x)
        return L

    def rm_rf(*fnames):                     ## undocumented
        for fname in flatten(fnames):
            if os.path.isfile(fname):
                os.unlink(fname)
            elif os.path.isdir(fname):
                from shutil import rmtree
                rmtree(fname)


    return locals()


helper = _new_module('oktest.helper', _dummy())
del _dummy



##
## dummy
##
def _dummy():

    __all__ = ('dummy_file', 'dummy_dir', 'dummy_values', 'dummy_attrs', 'dummy_environ_vars', 'dummy_io')


    class DummyFile(_Context):

        def __init__(self, filename, content):
            self.filename = filename
            self.path     = os.path.abspath(filename)
            self.content  = content

        def __enter__(self, *args):
            f = open(self.path, 'w')
            try:
                f.write(self.content)
            finally:
                f.close()
            return self

        def __exit__(self, *args):
            os.unlink(self.path)


    class DummyDir(_Context):

        def __init__(self, dirname):
            self.dirname = dirname
            self.path    = os.path.abspath(dirname)

        def __enter__(self, *args):
            os.mkdir(self.path)
            return self

        def __exit__(self, *args):
            import shutil
            shutil.rmtree(self.path)


    class DummyValues(_Context):

        def __init__(self, dictionary, items_=None, **kwargs):
            self.dict = dictionary
            self.items = {}
            if isinstance(items_, dict):
                self.items.update(items_)
            if kwargs:
                self.items.update(kwargs)

        def __enter__(self):
            self.original = d = {}
            for k in self.items:
                if k in self.dict:
                    d[k] = self.dict[k]
            self.dict.update(self.items)
            return self

        def __exit__(self, *args):
            for k in self.items:
                if k in self.original:
                    self.dict[k] = self.original[k]
                else:
                    del self.dict[k]
            self.__dict__.clear()


    class DummyIO(_Context):

        def __init__(self, stdin_content=None):
            self.stdin_content = stdin_content

        def __enter__(self):
            self.stdout, sys.stdout = sys.stdout, StringIO()
            self.stderr, sys.stderr = sys.stderr, StringIO()
            self.stdin,  sys.stdin  = sys.stdin,  StringIO(self.stdin_content or "")
            return self

        def __exit__(self, *args):
            sout, serr = sys.stdout.getvalue(), sys.stderr.getvalue()
            sys.stdout, self.stdout = self.stdout, sys.stdout.getvalue()
            sys.stderr, self.stderr = self.stderr, sys.stderr.getvalue()
            sys.stdin,  self.stdin  = self.stdin,  self.stdin_content


    def dummy_file(filename, content):
        return DummyFile(filename, content)

    def dummy_dir(dirname):
        return DummyDir(dirname)

    def dummy_values(dictionary, items_=None, **kwargs):
        return DummyValues(dictionary, items_, **kwargs)

    def dummy_attrs(object, items_=None, **kwargs):
        return DummyValues(object.__dict__, items_, **kwargs)

    def dummy_environ_vars(**kwargs):
        return DummyValues(os.environ, **kwargs)

    def dummy_io(stdin_content="", func=None, *args, **kwargs):
        obj = dummy.DummyIO(stdin_content)
        if func is None:
            return obj    # for with-statement
        obj.__enter__()
        try:
            func(*args, **kwargs)
        finally:
            obj.__exit__(*sys.exc_info())
        #return obj.stdout, obj.stderr
        return obj


    return locals()


dummy = _new_module('oktest.dummy', _dummy(), helper)
del _dummy



##
## Tracer
##
def _dummy():

    __all__ = ('Tracer', )


    class Call(object):

        __repr_style = None

        def __init__(self, receiver=None, name=None, args=None, kwargs=None, ret=None):
            self.receiver = receiver
            self.name   = name     # method name
            self.args   = args
            self.kwargs = kwargs
            self.ret    = ret

        def __repr__(self):
            #return '%s(args=%r, kwargs=%r, ret=%r)' % (self.name, self.args, self.kwargs, self.ret)
            if self.__repr_style == 'list':
                return repr(self.list())
            if self.__repr_style == 'tuple':
                return repr(self.tuple())
            buf = []; a = buf.append
            a("%s(" % self.name)
            for arg in self.args:
                a(repr(arg))
                a(", ")
            for k in self.kwargs:
                a("%s=%s" % (k, repr(self.kwargs[k])))
                a(", ")
            if buf[-1] == ", ":  buf.pop()
            a(") #=> %s" % repr(self.ret))
            return "".join(buf)

        def __iter__(self):
            yield self.receiver
            yield self.name
            yield self.args
            yield self.kwargs
            yield self.ret

        def list(self):
            return list(self)

        def tuple(self):
            return tuple(self)

        def __eq__(self, other):
            if isinstance(other, list):
                self.__repr_style = 'list'
                return list(self) == other
            elif isinstance(other, tuple):
                self.__repr_style = 'tuple'
                return tuple(self) == other
            elif isinstance(other, self.__class__):
                return self.name == other.name and self.args == other.args \
                    and self.kwargs == other.kwargs and self.ret == other.ret
            else:
                return False

        def __ne__(self, other):
            return not self.__eq__(other)


    class FakeObject(object):

        def __init__(self, **kwargs):
            self._calls = self.__calls = []
            for name in kwargs:
                setattr(self, name, self.__new_method(name, kwargs[name]))

        def __new_method(self, name, val):
            fake_obj = self
            if isinstance(val, types.FunctionType):
                func = val
                def f(self, *args, **kwargs):
                    r = Call(fake_obj, name, args, kwargs, None)
                    fake_obj.__calls.append(r)
                    r.ret = func(self, *args, **kwargs)
                    return r.ret
            else:
                def f(self, *args, **kwargs):
                    r = Call(fake_obj, name, args, kwargs, val)
                    fake_obj.__calls.append(r)
                    return val
            f.func_name = f.__name__ = name
            if python2: return types.MethodType(f, self, self.__class__)
            if python3: return types.MethodType(f, self)


    class Tracer(object):
        """trace function or method call to record arguments and return value.
           see README.txt for details.
        """

        def __init__(self):
            self.calls = []

        def __getitem__(self, index):
            return self.calls[index]

        def __len__(self):
            return len(self.calls)

        def __iter__(self):
            return self.calls.__iter__()

        def _copy_attrs(self, func, newfunc):
            for k in ('func_name', '__name__', '__doc__'):
                if hasattr(func, k):
                    setattr(newfunc, k, getattr(func, k))

        def _wrap_func(self, func, block):
            tr = self
            def newfunc(*args, **kwargs):                # no 'self'
                call = Call(None, _func_name(func), args, kwargs, None)
                tr.calls.append(call)
                if block:
                    ret = block(func, *args, **kwargs)
                else:
                    ret = func(*args, **kwargs)
                #newfunc._return = ret
                call.ret = ret
                return ret
            self._copy_attrs(func, newfunc)
            return newfunc

        def _wrap_method(self, method_obj, block):
            func = method_obj
            tr = self
            def newfunc(self, *args, **kwargs):          # has 'self'
                call = Call(self, _func_name(func), args, kwargs, None)
                tr.calls.append(call)
                if _is_unbound(func): args = (self, ) + args   # call with 'self' if unbound method
                if block:
                    ret = block(func, *args, **kwargs)
                else:
                    ret = func(*args, **kwargs)
                call.ret = ret
                return ret
            self._copy_attrs(func, newfunc)
            if python2:  return types.MethodType(newfunc, func.im_self, func.im_class)
            if python3:  return types.MethodType(newfunc, func.__self__)

        def trace_func(self, func):
            newfunc = self._wrap_func(func, None)
            return newfunc

        def fake_func(self, func, block):
            newfunc = self._wrap_func(func, block)
            return newfunc

        def trace_method(self, obj, *method_names):
            for method_name in method_names:
                method_obj = getattr(obj, method_name, None)
                if method_obj is None:
                    raise ValueError("%s: no method found on %r." % (method_name, obj))
                setattr(obj, method_name, self._wrap_method(method_obj, None))
            return None

        def fake_method(self, obj, **kwargs):
            def _new_block(ret_val):
                def _block(*args, **kwargs):
                    return ret_val
                return _block
            def _dummy_method(obj, name):
                fn = lambda *args, **kwargs: None
                fn.__name__ = name
                if python2: fn.func_name = name
                if python2: return types.MethodType(fn, obj, type(obj))
                if python3: return types.MethodType(fn, obj)
            for method_name in kwargs:
                method_obj = getattr(obj, method_name, None)
                if method_obj is None:
                    method_obj = _dummy_method(obj, method_name)
                block = kwargs[method_name]
                if not isinstance(block, types.FunctionType):
                    block = _new_block(block)
                setattr(obj, method_name, self._wrap_method(method_obj, block))
            return None

        def trace(self, target, *args):
            if type(target) is types.FunctionType:       # function
                func = target
                return self.trace_func(func)
            else:
                obj = target
                return self.trace_method(obj, *args)

        def fake(self, target, *args, **kwargs):
            if type(target) is types.FunctionType:       # function
                func = target
                block = args and args[0] or None
                return self.fake_func(func, block)
            else:
                obj = target
                return self.fake_method(obj, **kwargs)

        def fake_obj(self, **kwargs):
            obj = FakeObject(**kwargs)
            obj._calls = obj._FakeObject__calls = self.calls
            return obj


    return locals()


tracer = _new_module('oktest.tracer', _dummy(), helper)
del _dummy

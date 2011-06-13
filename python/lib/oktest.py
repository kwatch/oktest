# -*- coding: utf-8 -*-

###
### oktest.py -- new style test utility
###
### $Release: 0.8.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

__all__ = ('ok', 'NOT', 'NG', 'not_ok', 'run', 'spec', 'test')
__version__ = "$Release: 0.0.0 $".split()[1]

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
    xrange = range
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

if python3:
    def func_argnames(func):
        if isinstance(func, types.MethodType):
            codeobj = func.__func__.__code__
            index = 1
        else:
            codeobj = func.__code__
            index = 0
        return codeobj.co_varnames[index:codeobj.co_argcount]
else:
    def func_argnames(func):
        if isinstance(func, types.MethodType):
            codeobj = func.im_func.func_code
            index = 1
        else:
            codeobj = func.func_code
            index = 0
        return codeobj.co_varnames[index:codeobj.co_argcount]


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


def _diff_p(target, op, other):
    if op != '==':             return False
    if target == other:        return False
    #if not _is_string(target): return False
    #if not _is_string(other):  return False
    if not DIFF:               return False
    is_a = isinstance
    if is_a(target, str) and is_a(other, str):
        return True
    if python2 and is_a(target, unicode) and is_a(other, unicode):
        return True
    return False


def _truncated_repr(obj, max=80+15):
    s = repr(obj)
    if len(s) > max:
        return s[:max - 15] + ' [truncated]...'
    return s


def _msg(target, op, other=None):
    if _diff_p(target, op, other):
        diff = _diff(target, other)
        msg = "%s == %s : failed." % (_truncated_repr(target), _truncated_repr(other))
        return (msg, diff)
    if   op.endswith('()'):   msg = '%r%s'     % (target, op)
    elif op.startswith('.'):  msg = '%r%s(%r)' % (target, op, other)
    else:                     msg = '%r %s %r' % (target, op, other)
    msg += " : failed."
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
           if boolean != self.boolean:
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

    def __init__(self, target, boolean=True):
        self.target = target
        self.boolean = boolean
        self._tested = False
        self._location = None

    def __del__(self):
        if self._tested is False:
            msg = "%s() is called but not tested." % (self.boolean and 'ok' or 'not_ok')
            if self._location:
                msg += " (file '%s', line %s)" % self._location
            #import warnings; warnings.warn(msg)
            sys.stderr.write("*** warning: oktest: %s\n" % msg)

    #def not_(self):
    #    self.boolean = not self.boolean
    #    return self

    def failed(self, msg, depth=2):
        file, line = _get_location(depth + 1)
        diff = None
        if isinstance(msg, tuple):
            msg, diff = msg
        if self.boolean is False:
            msg = 'not ' + msg
        raise self._assertion_error(msg, file, line, diff)

    def _assertion_error(self, msg, file, line, diff):
        #return TestFailed(msg, file=file, line=line, diff=diff)
        ex = ASSERTION_ERROR(diff and msg + "\n" + diff or msg)
        ex.file = file;  ex.line = line;  ex.diff = diff;  ex.errmsg = msg
        ex._raised_by_oktest = True
        return ex

    @property
    def should(self):           # UNDOCUMENTED
        """(experimental) allows user to call True/False method as assertion.
           ex.
             ok ("SOS").should.startswith("S")   # same as ok ("SOS".startswith("S")) == True
             ok ("123").should.isdigit()         # same as ok ("123".isdigit()) == True
        """
        return Should(self, self.boolean)

    @property
    def should_not(self):       # UNDOCUMENTED
        """(experimental) allows user to call True/False method as assertion.
           ex.
             ok ("SOS").should_not.startswith("X")   # same as ok ("SOS".startswith("X")) == False
             ok ("123").should_not.isalpha()         # same as ok ("123".isalpha()) == False
        """
        return Should(self, not self.boolean)


def _f():

    @assertion
    def __eq__(self, other):
        boolean = self.target == other
        if boolean == self.boolean:  return self
        self.failed(_msg(self.target, '==', other))

    @assertion
    def __ne__(self, other):
        boolean = self.target != other
        if boolean == self.boolean:  return self
        self.failed(_msg(self.target, '!=', other))

    @assertion
    def __gt__(self, other):
        boolean = self.target > other
        if boolean == self.boolean:  return self
        self.failed(_msg(self.target, '>', other))

    @assertion
    def __ge__(self, other):
        boolean = self.target >= other
        if boolean == self.boolean:  return self
        self.failed(_msg(self.target, '>=', other))

    @assertion
    def __lt__(self, other):
        boolean = self.target < other
        if boolean == self.boolean:  return self
        self.failed(_msg(self.target, '<', other))

    @assertion
    def __le__(self, other):
        boolean = self.target <= other
        if boolean == self.boolean:  return self
        self.failed(_msg(self.target, '<=', other))

    @assertion
    def in_delta(self, other, delta):
        boolean = self.target > other - delta
        if boolean != self.boolean:
            self.failed(_msg(self.target, '>', other - delta))
        boolean = self.target < other + delta
        if boolean != self.boolean:
            self.failed(_msg(self.target, '<', other + delta))
        return self

#    @assertion
#    def __contains__(self, other):
#        boolean = self.target in other
#        if boolean == self.boolean:  return self
#        self.failed(_msg(self.target, 'in', other))

    @assertion
    def in_(self, other):
        boolean = self.target in other
        if boolean == self.boolean:  return self
        self.failed(_msg(self.target, 'in', other))

    @assertion
    def not_in(self, other):
        boolean = self.target not in other
        if boolean == self.boolean:  return self
        self.failed(_msg(self.target, 'not in', other))

    @assertion
    def contains(self, other):
        boolean = other in self.target
        if boolean == self.boolean:  return self
        self.failed(_msg(other, 'in', self.target))

    @assertion
    def not_contain(self, other):  # DEPRECATED
        boolean = other in self.target
        if boolean == self.boolean:  return self
        self.failed(_msg(other, 'not in', self.target))

    @assertion
    def is_(self, other):
        boolean = self.target is other
        if boolean == self.boolean:  return self
        self.failed(_msg(self.target, 'is', other))

    @assertion
    def is_not(self, other):
        boolean = self.target is not other
        if boolean == self.boolean:  return self
        self.failed(_msg(self.target, 'is not', other))

    @assertion
    def is_a(self, other):
        boolean = isinstance(self.target, other)
        if boolean == self.boolean:  return self
        self.failed("isinstance(%r, %s) : failed." % (self.target, other.__name__))

    @assertion
    def is_not_a(self, other):
        boolean = not isinstance(self.target, other)
        if boolean == self.boolean:  return self
        self.failed("not isinstance(%r, %s) : failed." % (self.target, other.__name__))

    @assertion
    def has_attr(self, name):
        boolean = hasattr(self.target, name)
        if boolean == self.boolean:  return self
        self.failed("hasattr(%r, %r) : failed." % (self.target, name))

    @assertion
    def matches(self, pattern, flags=0):
        if isinstance(pattern, type(re.compile('x'))):
            boolean = bool(pattern.search(self.target))
            if boolean == self.boolean:  return self
            self.failed("re.search(%r, %r) : failed." % (pattern.pattern, self.target))
        else:
            rexp = re.compile(pattern, flags)
            boolean = bool(rexp.search(self.target))
            if boolean == self.boolean:  return self
            self.failed("re.search(%r, %r) : failed." % (pattern, self.target))

    @assertion
    def not_match(self, pattern):  # DEPRECATED
        if isinstance(pattern, type(re.compile('x'))):
            boolean = not pattern.search(self.target)
            if boolean == self.boolean:  return self
            self.failed("not re.search(%r, %r) : failed." % (pattern.pattern, self.target))
        else:
            boolean = not re.search(pattern, self.target)
            if boolean == self.boolean:  return self
            self.failed("not re.search(%r, %r) : failed." % (pattern, self.target))

    @assertion
    def is_file(self):
        boolean = os.path.isfile(self.target)
        if boolean == self.boolean:  return self
        self.failed('os.path.isfile(%r) : failed.' % self.target)

    @assertion
    def is_not_file(self):  # DEPRECATED
        boolean = not os.path.isfile(self.target)
        if boolean == self.boolean:  return self
        self.failed('not os.path.isfile(%r) : failed.' % self.target)

    @assertion
    def is_dir(self):
        boolean = os.path.isdir(self.target)
        if boolean == self.boolean:  return self
        self.failed('os.path.isdir(%r) : failed.' % self.target)

    @assertion
    def is_not_dir(self):  # DEPRECATED
        boolean = not os.path.isdir(self.target)
        if boolean == self.boolean:  return self
        self.failed('not os.path.isdir(%r) : failed.' % self.target)

    @assertion
    def exists(self):
        boolean = os.path.exists(self.target)
        if boolean == self.boolean:  return self
        self.failed('os.path.exists(%r) : failed.' % self.target)

    @assertion
    def not_exist(self):  # DEPRECATED
        boolean = not os.path.exists(self.target)
        if boolean == self.boolean:  return self
        self.failed('not os.path.exists(%r) : failed.' % self.target)

    @assertion
    def raises(self, exception_class, errmsg=None):
        return self._raise_or_not(exception_class, errmsg, self.boolean)

    @assertion
    def not_raise(self, exception_class=Exception):
        return self._raise_or_not(exception_class, None, not self.boolean)

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
                if errmsg is None:
                    pass
                elif isinstance(errmsg, _rexp_type):
                    if not errmsg.search(str(ex)):
                        self.failed("error message %r is not matched to pattern." % str(ex), depth=3)   # don't use ex2msg(ex)!
                else:
                    if str(ex) != errmsg:   # don't use ex2msg(ex)!
                        #self.failed("expected %r but got %r" % (errmsg, str(ex)))
                        self.failed("%r == %r : failed." % (str(ex), errmsg), depth=3)   # don't use ex2msg(ex)!
            else:
                if isinstance(ex, exception_class):
                    self.failed('%s should not be raised : failed, got %r.' % (exception_class.__name__, ex), depth=3)
        else:
            if flag_raise and ex is None:
                self.failed('%s should be raised : failed.' % exception_class.__name__, depth=3)
        return self

    AssertionObject._raise_or_not = _raise_or_not
    AssertionObject.hasattr = has_attr    # for backward compatibility

_f()
del _f

_rexp_type = type(re.compile('x'))

ASSERTION_OBJECT = AssertionObject


def ok(target):
    obj = ASSERTION_OBJECT(target, True)
    obj._location = _get_location(1)
    return obj

def NG(target):
    obj = ASSERTION_OBJECT(target, False)
    obj._location = _get_location(1)
    return obj

def not_ok(target):  # for backward compatibility
    obj = ASSERTION_OBJECT(target, False)
    obj._location = _get_location(1)
    return obj

def NOT(target):     # experimental. prefer to NG()?
    obj = ASSERTION_OBJECT(target, False)
    obj._location = _get_location(1)
    return obj


class Should(object):

    def __init__(self, assertion_object, boolean=None):
        self.assertion_object = assertion_object
        if boolean is None:
            boolean = assertion_object.boolean
        self.boolean = boolean

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
            if ret != self.boolean:
                buf = [ repr(arg) for arg in args ]
                buf.extend([ "%s=%r" % (k, kwargs[k]) for k in kwargs ])
                msg = "%r.%s(%s) : failed." % (ass.target, val.__name__, ", ".join(buf))
                if self.boolean is False:
                    msg = "not " + msg
                ass.failed(msg)
        return f


class TestRunner(object):

    _filter_test = _filter_key = _filter_val = None

    def __init__(self, klass, reporter=None, filter=None):
        self.klass = klass
        if reporter is None:  reporter = REPORTER()
        self.reporter = reporter
        self.filter = filter
        filter = filter and filter.copy() or {}
        if filter:
            self._filter_test = filter.pop('test', None)
        if filter:
            self._filter_key  = list(filter.keys())[0]
            self._filter_val  = filter.pop(self._filter_key)

    def _test_name(self, name):
        return re.sub(r'^test_?', '', name)

    def _gather_test_methods(self):
        pairs = []   # pairs of method name and function
        for k in dir(self.klass):
            v = getattr(self.klass, k)
            if k.startswith('test') and hasattr(v, '__call__'):
                pairs.append((k, v))
        ## filter by test name or user-defined options
        pattern, key, val = self._filter_test, self._filter_key, self._filter_val
        if pattern or key:
            #pairs = [ t for t in pairs
            #              if _filtered(self.klass, t[1], t[0], pattern, key, val) ]
            arr = []
            for t in pairs:
                ret = _filtered(self.klass, t[1], t[0], pattern, key, val)
                if ret:
                    arr.append(t)
            pairs = arr
        ## filter by $TEST environment variable
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
        obj._testMethodDoc  = func.__doc__   # unittest.TestCase compatible
        obj._run_by_oktest  = True
        obj._oktest_specs   = []
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
                #except TestFailed, ex:
                except ASSERTION_ERROR:
                    _, ex, tb = sys.exc_info()
                    if not hasattr(ex, '_raised_by_oktest'):
                        raise
                    count += 1
                    self.reporter.print_failed(obj, ex, tb)
                except Exception:
                    _, ex, tb = sys.exc_info()
                    count += 1
                    self.reporter.print_error(obj, ex, tb)
                else:
                    specs = getattr(obj, '_oktest_specs', None)
                    failed = False
                    if specs:
                        for spec in specs:
                            if spec._exception:
                                failed = True
                                count += 1
                                self.reporter.print_failed(obj, spec._exception, spec._traceback, spec._stacktrace)
                    if not failed:
                        self.reporter.print_passed(obj)
            finally:
                self._invoke_after(obj)
        self._invoke_after_all(self.klass)
        return count


def _filtered(klass, meth, tname, pattern, key, val, _rexp=re.compile(r'^test(_|_\d\d\d(_|: ))?')):
    from fnmatch import fnmatch
    if pattern:
        if not fnmatch(_rexp.sub('', tname), pattern):
            return False   # skip testcase
    if key:
        if not meth: meth = getattr(klass, tname)
        d = getattr(meth, '_options', None)
        if not (d and isinstance(d, dict) and fnmatch(str(d.get(key)), val)):
            return False   # skip testcase
    return True   # invoke testcase


TEST_RUNNER = TestRunner


TARGET_PATTERN = '.*(Test|TestCase|_TC)$'

def run(*targets, **filter):
    if len(targets) == 0:
        targets = (TARGET_PATTERN, )
    count = 0
    for klass in _target_classes(targets):
        runner = TEST_RUNNER(klass, REPORTER(), filter)
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

    def print_passed(self, obj):
        pass

    def print_failed(self, obj, ex, tb=None, stacktrace=None):
        pass

    def print_error(self, obj, ex, tb=None, stacktrace=None):
        pass


class BaseReporter(Reporter):

    def before_all(self, klass):
        self.klass = klass

    def _test_ident(self, obj):
        return '%s#%s' % (self.klass.__name__, obj._testMethodName)

    def _write(self, str):
        OUT.write(str)

    def _print_traceback_entry(self, file, line, func, text):
        raise NotImplementedError("%s._print_traceback_entry(): not implemented yet." % self.__class__.__name__)

    def _is_oktest_py(self, fpath,  _fnames=set(['oktest.py', 'oktest.pyc', 'oktest.pyo'])):
        return os.path.basename(fpath) in _fnames

    def _print_stacktrace(self, stacktrace, file, func):
        is_oktest_py = self._is_oktest_py
        i = len(stacktrace) - 1
        while i >= 0 and not (stacktrace[i][0] == file and stacktrace[i][2] == func):
            i -= 1
        bottom = i
        while i >= 0 and not is_oktest_py(stacktrace[i][0]):
            i -= 1
        top = i + 1
        for t in stacktrace[top:bottom]:
            self._print_traceback_entry(*t)

    def _print_traceback(self, tb=None, stacktrace=None, all=False):
        entries = traceback.extract_tb(tb or sys.exc_info()[2])
        is_oktest_py = self._is_oktest_py
        i, n = 0, len(entries)
        if stacktrace:
            assert all == False
            file, line, func, text = entries[0]
            self._print_stacktrace(stacktrace, file, func)
        else:
            while i < n and is_oktest_py(entries[i][0]):
                i += 1
        while i < n and (all or not is_oktest_py(entries[i][0])):
            self._print_traceback_entry(*entries[i])
            i += 1


## NOTICE! reporter spec will be changed frequently
class SimpleReporter(BaseReporter):

    def before_all(self, klass):
        self.klass = klass
        OUT.write("### %s: " % klass.__name__)
        self.buf = []

    def after_all(self, klass):
        OUT.write("\n")
        OUT.write("".join(self.buf))

    def print_passed(self, obj):
        OUT.write("."); OUT.flush()

    def _write(self, str):
        self.buf.append(str)

    def _top_separator(self):
        self._write("======================================================================\n")

    def _middle_separator(self):
        self._write("----------------------------------------------------------------------\n")

    def _bottom_separator(self):
        self._write("\n")

    def _print_traceback_entry(self, file, line, func, text):
        if func:  self._write('  File "%s", line %s, in %s\n' % (file, line, func))
        else:     self._write('  File "%s", line %s\n'        % (file, line))
        if text:  self._write('    %s\n' % text)

    def print_failed(self, obj, ex, tb=None, stacktrace=None):
        OUT.write("f"); OUT.flush()
        self._top_separator()
        self._write("Failed: %s()\n" % self._test_ident(obj))
        self._middle_separator()
        #self._write("  %s\n" % ex2msg(ex))
        self._print_traceback(tb, stacktrace, all=False)
        self._write("%s: %s\n" % (ex.__class__.__name__, ex2msg(ex)))
        #if getattr(ex, 'diff', None):
        #    self._write(ex.diff)
        self._bottom_separator()

    def print_error(self, obj, ex, tb=None, stacktrace=None):
        OUT.write("E"); OUT.flush()
        self._top_separator()
        self._write("ERROR: %s()\n" % self._test_ident(obj))
        self._middle_separator()
        #self._write("  %s: %s\n" % (ex.__class__.__name__, ex2msg(ex)))
        self._print_traceback(tb, stacktrace, all=True)
        self._write("%s: %s\n" % (ex.__class__.__name__, ex2msg(ex)))
        self._bottom_separator()


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

    def print_passed(self, obj):
        OUT.write("[ok]\n")

    _traceback_entry_format = "   %s:%s: %s\n"
    #_traceback_entry_format = "  - %s:%s:  %s\n"

    def _print_traceback_entry(self, file, line, func, text):
        OUT.write(self._traceback_entry_format % (file, line, text))

    def print_failed(self, obj, ex, tb=None, stacktrace=None):
        raised_by_oktest = hasattr(ex, '_raised_by_oktest')
        if raised_by_oktest:
            OUT.write("[NG] %s\n" % ex.errmsg)
        else:
            OUT.write("[NG] %s\n" % ex2msg(ex))
        self._traceback_entry_format = "   %s:%s: %s\n"
        self._print_traceback(tb, stacktrace, all=False)
        if raised_by_oktest:
            if getattr(ex, 'diff', None):
                OUT.write(ex.diff)

    def print_error(self, obj, ex, tb=None, stacktrace=None):
        OUT.write("[ERROR] %s: %s\n" % (ex.__class__.__name__, ex2msg(ex)))
        self._traceback_entry_format = "  - %s:%s:  %s\n"
        self._print_traceback(tb, stacktrace, all=True)


## NOTICE! reporter spec will be changed frequently
class TapStyleReporter(BaseReporter):

    BOL_PATTERN = re.compile(r'^', re.M)

    def before_all(self, klass):
        self.klass = klass
        OUT.write("### %s\n" % klass.__name__)

    def after_all(self, klass):
        OUT.write("\n")

    def print_passed(self, obj):
        OUT.write("ok     # %s\n" % self._test_ident(obj))

    def _print_traceback_entry(self, file, line, func, text):
        OUT.write("   #  %s:%s:  %s\n" % (file, line, text))

    def print_failed(self, obj, ex, tb=None, stacktrace=None):
        OUT.write("not ok # %s\n" % self._test_ident(obj))
        if hasattr(ex, '_raised_by_oktest'):
            OUT.write("   #  %s\n" % ex.errmsg)
            self._print_traceback(tb, stacktrace, all=False)
            if getattr(ex, 'diff', None):
                OUT.write(re.sub(self.BOL_PATTERN, '   #', ex.diff))
        else:
            OUT.write("   #  %s\n" % ex2msg(ex))
            self._print_traceback(tb, stacktrace, all=False)

    def print_error(self, obj, ex, tb=None, stacktrace=None):
        OUT.write("ERROR  # %s\n" % self._test_ident(obj))
        OUT.write("   #  %s: %s\n" % (ex.__class__.__name__, ex2msg(ex)))
        self._print_traceback(tb, stacktrace, all=True)


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


class _RunnableContext(_Context):

    def run(self, func, *args, **kwargs):
        self.__enter__()
        try:
            return func(*args, **kwargs)
        finally:
            self.__exit__(*sys.exc_info())

    def deco(self, func):
        def f(*args, **kwargs):
            return self.run(func, *args, **kwargs)
        return f

    __call__ = run    # for backward compatibility


##
## spec()
##
class Spec(_Context):

    _exception  = None
    _traceback  = None
    _stacktrace = None

    def __init__(self, desc):
        self.desc = desc
        self._testcase = None

    def __enter__(self):
        self._testcase = tc = self._find_testcase_object()
        if getattr(tc, '_run_by_oktest', None):
            getattr(tc, '_oktest_specs').append(self)
        return self

    def _find_testcase_object(self):
        max_depth = 10
        for i in xrange(2, max_depth):
            try:
                frame = sys._getframe(i)   # raises ValueError when too deep
            except ValueError:
                break
            method = frame.f_code.co_name
            if method.startswith("test"):
                arg_name = frame.f_code.co_varnames[0]
                testcase = frame.f_locals.get(arg_name, None)
                if hasattr(testcase, "_testMethodName") or hasattr(testcase, "_TestCase__testMethodName"):
                    return testcase
        return None

    def __exit__(self, *args):
        ex = args[1]
        tc = self._testcase
        if ex and hasattr(ex, '_raised_by_oktest') and hasattr(tc, '_run_by_oktest'):
            self._exception  = ex
            self._traceback  = args[2]
            self._stacktrace = traceback.extract_stack()
            return True

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

    def __bool__(self):       # for Pyton3
        filter = os.environ.get('SPEC')
        return not filter or (filter in self.desc)

    __nonzero__ = __bool__    # for Python2


def spec(desc):
    return Spec(desc)


##
## @test() decorator
##

def test(description_text, **options):
    frame = sys._getframe(1)
    localvars  = frame.f_locals
    globalvars = frame.f_globals
    n = localvars.get('__n', 0) + 1
    localvars['__n'] = n
    def deco(orig_func):
        orig_name = orig_func.__name__
        if orig_name.startswith('test_'):
            newname = 'test_%03d_' % n + orig_name[5:]
        elif orig_name.startswith('test'):
            newname = 'test_%03d_' % n + orig_name[4:]
        else:
            newname = 'test_%03d: ' % n + description_text
        argnames = func_argnames(orig_func)
        fixture_names = argnames[1:]   # except 'self'
        if fixture_names:
            def newfunc(self):
                self._options = options
                self._description = description_text
                return fixture_injector.invoke(orig_func, self, fixture_names, globalvars)
        else:
            def newfunc(self):
                self._options = options
                self._description = description_text
                return orig_func(self)
        localvars[newname] = newfunc
        newfunc.__name__ = newname
        newfunc.__doc__  = description_text
        newfunc._options = options
        return newfunc
    return deco


##
## fixture manager and injector
##

class FixtureManager(object):

    def provide(self, name):
        raise ValueError("Fixture provider for '%s' not found." % (name,))

    def release(self, name, value):
        pass

fixture_manager = FixtureManager()


class FixtureInjector(object):

    def invoke(self, func, testcase, fixture_names, *opts):
        """invoke function with fixtures."""
        releasers = {"self": None}       # {"fixture_name": releaser_func()}
        resolved  = {"self": testcase}   # {"fixture_name": fixture_value}
        in_progress = []
        #
        def _resolve(name):
            if name not in resolved:
                pair = self.find(name, testcase, *opts)
                if pair:
                    provider, releaser = pair
                    resolved[name] = _call(name, provider)
                    releasers[name] = releaser
                else:
                    resolved[name] = fixture_manager.provide(name)
            return resolved[name]
        def _call(name, provider):
            argnames = func_argnames(provider)
            if not argnames:
                return provider()
            in_progress.append(name)
            args = [ _get_arg(aname) for aname in argnames ]
            in_progress.remove(name)
            return provider(*args)
        def _get_arg(aname):
            if aname in resolved:        return resolved[aname]
            if aname not in in_progress: return _resolve(aname)
            raise self._looped_dependency_error(aname, in_progress, testcase)
        #
        fixtures = [ _resolve(name) for name in fixture_names ]
        assert not in_progress
        #
        try:
            return func(testcase, *fixtures)
        #
        finally:
            self._release_fixtures(resolved, releasers)

    def _release_fixtures(self, resolved, releasers):
        for name in resolved:
            if name in releasers:
                releaser = releasers[name]
                if releaser:
                    releaser(resolved[name])
            else:
                fixture_manager.release(name, resolved[name])

    def find(self, name, testcase, *opts):
        """return provide_xxx() and release_xxx() functions."""
        globalvars = opts[0]
        provider_name = 'provide_' + name
        releaser_name = 'release_' + name
        meth = getattr(testcase, provider_name, None)
        if meth:
            provider = meth
            if python2:
                if hasattr(meth, 'im_func'):  provider = meth.im_func
            elif python3:
                if hasattr(meth, '__func__'): provider = meth.__func__
            releaser = getattr(testcase, releaser_name, None)
            return (provider, releaser)
        elif provider_name in globalvars:
            provider = globalvars[provider_name]
            if not isinstance(provider, types.FunctionType):
                raise TypeError("%s: expected function but got %s." % (provider_name, type(provider)))
            releaser = globalvars.get(releaser_name)
            return (provider, releaser)
        #else:
        #    raise NameError("%s: no such fixture provider for '%s'." % (provider_name, name))
            return None

    def _looped_dependency_error(self, aname, in_progress, testcase):
        names = in_progress + [aname]
        pos   = names.index(aname)
        loop  = '=>'.join(names[pos:])
        if pos > 0:
            loop = '->'.join(names[0:pos]) + '->' + loop
        classname = testcase.__class__.__name__
        testdesc  = testcase._description
        return LoopedDependencyError("fixture dependency is looped: %s (class: %s, test: '%s')" % (loop, classname, testdesc))


fixture_injector = FixtureInjector()


class LoopedDependencyError(ValueError):
    pass


##
## helpers
##
def _dummy():

    __all__ = ('chdir', 'rm_rf')


    class Chdir(_RunnableContext):

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
            localvars = sys._getframe(1).f_locals
            self._start_names = localvars.keys()
            if python3: self._start_names = list(self._start_names)
            return self

        def __exit__(self, *args):
            localvars  = sys._getframe(1).f_locals
            curr_names = localvars.keys()
            diff_names = list(set(curr_names) - set(self._start_names))
            for name in diff_names:
                setattr(self.klass, name, localvars[name])


    def chdir(path, func=None):
        cd = Chdir(path)
        return func is not None and cd.run(func) or cd

    def using(klass):                       ## undocumented
        return Using(klass)


    def flatten(arr, type=(list, tuple)):   ## undocumented
        L = []
        for x in arr:
            if isinstance(x, type):
                L.extend(flatten(x))
            else:
                L.append(x)
        return L

    def rm_rf(*fnames):
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


    class DummyFile(_RunnableContext):

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


    class DummyDir(_RunnableContext):

        def __init__(self, dirname):
            self.dirname = dirname
            self.path    = os.path.abspath(dirname)

        def __enter__(self, *args):
            os.mkdir(self.path)
            return self

        def __exit__(self, *args):
            import shutil
            shutil.rmtree(self.path)


    class DummyValues(_RunnableContext):

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


    class DummyIO(_RunnableContext):

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

        def __call__(self, func, *args, **kwargs):
            self.returned = self.run(func, *args, **kwargs)
            return self

        def __iter__(self):
            yield self.stdout
            yield self.stderr


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



##
## main
##

def load_module(mod_name, filepath, content=None):
    mod = type(os)(mod_name)
    mod.__dict__["__name__"] = mod_name
    mod.__dict__["__file__"] = filepath
    #mod.__dict__["__file__"] = os.path.abspath(filepath)
    if content is None:
        content = _read_file(filepath)
    if filepath:
        code = compile(content, filepath, "exec")
        exec(code, mod.__dict__, mod.__dict__)
    else:
        exec(content, mod.__dict__, mod.__dict__)
    return mod

def rglob(dirpath, pattern, _entries=None):
    import fnmatch
    if _entries is None: _entries = []
    isdir, join = os.path.isdir, os.path.join
    add = _entries.append
    if isdir(dirpath):
        items = os.listdir(dirpath)
        for item in fnmatch.filter(items, pattern):
            path = join(dirpath, item)
            add(path)
        for item in items:
            path = join(dirpath, item)
            if isdir(path) and not item.startswith('.'):
                rglob(path, pattern, _entries)
    return _entries


def _dummy():


    class MainApp(object):

        debug = False

        def __init__(self, command=None):
            self.command = command

        def _new_cmdopt_parser(self):
            #import cmdopt
            #parser = cmdopt.Parser()
            #parser.opt("-h").name("help")                         .desc("show help")
            #parser.opt("-v").name("version")                      .desc("version of oktest.py")
            ##parser.opt("-s").name("testdir").arg("DIR[,DIR2,..]") .desc("test directory (default 'test' or 'tests')")
            #parser.opt("-p").name("pattern").arg("PAT[,PAT2,..]") .desc("test script pattern (default '*_test.py,test_*.py')")
            #parser.opt("-x").name("exclude").arg("PAT[,PAT2,..]") .desc("exclue file pattern")
            #parser.opt("-D").name("debug")                        .desc("debug mode")
            #return parser
            import optparse
            parser = optparse.OptionParser(conflict_handler="resolve")
            parser.add_option("-h", "--help",       action="store_true",     help="show help")
            parser.add_option("-v", "--version",    action="store_true",     help="verion of oktest.py")
            #parser.add_option("-s", dest="testdir", metavar="DIR[,DIR2,..]", help="test directory (default 'test' or 'tests')")
            parser.add_option("-p", dest="pattern", metavar="PAT[,PAT2,..]", help="test script pattern (default '*_test.py,test_*.py')")
            parser.add_option("-x", dest="exclude", metavar="PAT[,PAT2,..]", help="exclue file pattern")
            parser.add_option("-D", dest="debug",   action="store_true",     help="debug mode")
            parser.add_option("-f", dest="filter",  metavar="FILTER",        help="filter (class=xxx/test=xxx/useroption=xxx)")
            return parser

        def _load_modules(self, filepaths, pattern=None):
            from fnmatch import fnmatch
            modules = []
            for fpath in filepaths:
                mod_name = os.path.basename(fpath).replace('.py', '')
                if pattern and not fnmatch(mod_name, pattern):
                    continue
                mod = load_module(mod_name, fpath)
                modules.append(mod)
            self._trace("modules: ", modules)
            return modules

        def _load_classes(self, modules, pattern=None):
            import unittest
            from fnmatch import fnmatch
            unittest_testcases = []    # classes
            oktest_testcases   = []    # classes
            for mod in modules:
                for k in dir(mod):
                    if k.startswith('_'): continue
                    v = getattr(mod, k)
                    if not isinstance(v, type): continue
                    klass = v
                    if pattern and not fnmatch(klass.__name__, pattern):
                        continue
                    if issubclass(klass, unittest.TestCase):
                        unittest_testcases.append(klass)
                    elif re.search(TARGET_PATTERN, klass.__name__):
                        oktest_testcases.append(klass)
            return unittest_testcases, oktest_testcases

        def _run_unittest(self, klasses, pattern=None, filters=None):
            self._trace("test_pattern: %r" % (pattern,))
            self._trace("unittest_testcases: ", klasses)
            import unittest
            from fnmatch import fnmatch
            loader = unittest.TestLoader()
            the_suite = unittest.TestSuite()
            rexp = re.compile(r'^test(_|_\d\d\d(_|: ))?')
            if filters:
                key = list(filters.keys())[0]
                val = filters[key]
            else:
                key = val = None
            for klass in klasses:
                if pattern or filters:
                    testnames = loader.getTestCaseNames(klass)
                    testcases = [ klass(tname) for tname in testnames
                                      if _filtered(klass, None, tname, pattern, key, val) ]
                    suite = loader.suiteClass(testcases)
                else:
                    suite = loader.loadTestsFromTestCase(klass)
                the_suite.addTest(suite)
            runner = unittest.TextTestRunner()
            runner.run(the_suite)

        def _run_oktest(self, klasses, pattern=None, filters=None):
            self._trace("test_pattern: %r" % (pattern,))
            self._trace("oktest_testcases: ", klasses)
            if filters is None: filters = {}
            if pattern: filters['test'] = pattern
            import oktest
            oktest.run(*klasses, **filters)

        def _trace(self, msg, items=None):
            write = sys.stderr.write
            if items is None:
                write("** DEBUG: %s\n" % msg)
            else:
                write("** DEBUG: %s[\n" % msg)
                for item in items:
                    write("**   %r,\n" % (item,))
                write("** ]\n")

        def _help_message(self, parser):
            buf = []; add = buf.append
            add("Usage: python -m oktest [options] file_or_directory...\n")
            #add(parser.help_message(20))
            add(re.sub(r'^.*\n.*\nOptions:\n', '', parser.format_help()))
            add("Example:\n")
            add("   ## run test scripts except foo_*.py\n")
            add("   $ python -m oktest -x 'foo_*.py' tests/*_test.py\n")
            add("   ## run test scripts in 'tests' dir with pattern '*_test.py'\n")
            add("   $ python -m oktest -p '*_test.py' tests\n")
            add("   ## filter by class name\n")
            add("   $ python -m oktest -f class='ClassName*' tests\n")
            add("   ## filter by test method name\n")
            add("   $ python -m oktest -f test='*keyword*' tests\n")
            add("   $ python -m oktest -f '*keyword*' tests     # 'test=' is omittable\n")
            add("   ## filter by user-defined option added by @test decorator\n")
            add("   $ python -m oktest -f tag='*value*' tests\n")
            return "".join(buf)

        def _version_info(self):
            buf = []; add = buf.append
            add("oktest: " + __version__)
            add("python: " + sys.version.split("\n")[0])
            add("")
            return "\n".join(buf)

        def _get_files(self, args, pattern):
            filepaths = []
            for arg in args:
                if os.path.isfile(arg):
                    filepaths.append(arg)
                elif os.path.isdir(arg):
                    files = self._find_files_recursively(arg, pattern)
                    filepaths.extend(files)
                else:
                    raise ValueError("%s: file or directory expected." % (arg,))
            return filepaths

        def _find_files_recursively(self, testdir, pattern):
            _trace = self._trace
            isdir = os.path.isdir
            assert isdir(testdir)
            filepaths = []
            for pat in pattern.split(","):
                files = rglob(testdir, pat)
                if files:
                    filepaths.extend(files)
                    _trace("testdir: %r, pattern: %r, files: " % (testdir, pat), files)
            return filepaths

        def _exclude_files(self, filepaths, pattern):
            from fnmatch import fnmatch
            _trace = self._trace
            basename = os.path.basename
            original = filepaths[:]
            for pat in pattern.split(","):
                filepaths = [ fpath for fpath in filepaths
                                  if not fnmatch(basename(fpath), pat) ]
            _trace("excluded: %r" % (list(set(original) - set(filepaths)), ))
            return filepaths

        def _get_filters(self, opts_filter):
            filters = {}
            if opts_filter:
                pair = opts_filter.split('=', 2)
                if len(pair) != 2:
                    pair = ('test', pair[0])
                filters[pair[0]] = pair[1]
            return filters

        def run(self, args=None):
            if args is None: args = sys.argv[1:]
            parser = self._new_cmdopt_parser()
            #opts = parser.parse(args)
            opts, args = parser.parse_args()
            if opts.debug:
                self.debug = True
                _trace = self._trace
            else:
                _trace = self._trace = lambda msg, items=None: None
            _trace("python: " + sys.version.split()[0])
            _trace("oktest: " + __version__)
            _trace("opts: %r" % (opts,))
            _trace("args: %r" % (args,))
            if opts.help:
                print(self._help_message(parser))
                return
            if opts.version:
                print(self._version_info())
                return
            pattern = opts.pattern or '*_test.py,test_*.py'
            filepaths = self._get_files(args, pattern)
            if opts.exclude:
                filepaths = self._exclude_files(filepaths, opts.exclude)
            filters = self._get_filters(opts.filter)
            fval = lambda key, filters=filters: filters.pop(key, None)
            modules = self._load_modules(filepaths, fval('module'))
            pair = self._load_classes(modules, fval('class'))
            unittest_testcases, oktest_testcases = pair
            if unittest_testcases:
                self._run_unittest(unittest_testcases, fval('test'), filters)
            if oktest_testcases:
                self._run_oktest(oktest_testcases, fval('test'), filters)

        @classmethod
        def main(cls, sys_argv=None):
            #import cmdopt
            if sys_argv is None: sys_argv = sys.argv
            #app = cls(sys_argv[0])
            #try:
            #    app.run(sys_argv[1:])
            #    sys.exit(0)
            #except cmdopt.ParseError:
            #    ex = sys.exc_info()[1]
            #    sys.stderr.write("%s" % (ex, ))
            #    sys.exit(1)
            app = cls(sys_argv[0])
            app.run()
            sys.exit(0)

    return locals()


main = _new_module('oktest.main', _dummy(), helper)
del _dummy


if __name__ == '__main__':
    main.MainApp.main()

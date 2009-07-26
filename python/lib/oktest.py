###
### $Release:$
### $Copyright$
### $License$
###


__all__ = ('TestFailedError', 'ok', 'invoke_tests')


import sys, os, re, types, traceback


class TestFailedError(Exception):
    pass


def _err(actual, op, expected, message=None, format=None):
    if message:
        pass
    elif format:
        message = format % (repr(actual), repr(expected)) + ' : failed.'
    else:
        message = '%s %s %s : failed.' % (repr(actual), op, repr(expected))
    #
    tuples = traceback.extract_stack(sys._getframe())
    tuples.reverse()
    for filepath, linenum, funcname, linetext in tuples:
        filename = os.path.basename(filepath)
        if filename != 'oktest.py' and filename != 'oktest.pyc':
            message = message + "\n   %s:%s: %s" % (filename, linenum, linetext)
            break
    #
    ex = TestFailedError(message)
    ex.actual   = actual
    ex.op       = op
    ex.expected = expected
    return ex


def _re_compile(expected, arg):
    if type(expected) == type(re.compile('')):
        rexp = expected
    else:
        rexp = re.compile(expected, arg or 0)
    return rexp


def ok(actual, op, expected=True, arg=None):
    result = format = message = None
    if False:
        pass
    elif op == '==':     result = actual == expected
    elif op == '!=':     result = actual != expected
    elif op == '>' :     result = actual >  expected
    elif op == '>=':     result = actual >= expected
    elif op == '<' :     result = actual <  expected
    elif op == '<=':     result = actual <= expected
    elif op == '=~':     result = bool(_re_compile(expected, arg).search(actual))
    elif op == '!~':     result = not  _re_compile(expected, arg).search(actual)
    elif op == 'is':     result = actual is expected
    elif op == 'is not': result = actual is not expected
    elif op == 'in':     result = actual in expected
    elif op == 'not in': result = actual not in expected
    elif op == 'raises':
        ex = None
        error_class = expected
        try:
            actual()
        except Exception:
            ex = sys.exc_info()[1]
        if ex is None:
            message = "%s should be raised : failed" % error_class.__name__
        elif not isinstance(ex, error_class):
            message = "%s is kind of %s : failed" % (repr(ex), error_class.__name__)
        elif arg is not None and ex.message != arg:
            message = "%s == %s : failed" % (repr(ex.message), repr(arg))
        result = message is None and True or False
    elif op == 'not raise':
        ex = None
        error_class = expected
        try:
            actual()
        except Exception:
            ex = sys.exc_info()[1]
        if ex is not None and isinstance(ex, error_class):
            message = "%s should not be raised : failed" % error_class.__name__
        result = message is None and True or False
    elif isinstance(op, types.FunctionType):
        func = op
        result = func(actual) == expected
        format = func.__name__ + "(%s) == %s"
    else:
        raise ValueError("%s: unknown operator" % repr(op))
    if format is None: format = "%s " + op + " %s"
    #
    if result is True:  return _test_ok(actual, op, expected)
    if result is False: return _test_ng(actual, op, expected, format=format, message=message)
    raise Exception("** internal error: result=%s" % repr(result))


def _test_ok(actual, op, expected):
    return True


def _test_ng(actual, op, expected, message=None, format=None):
    raise _err(actual, op, expected, message=message, format=format)


def _invoke(obj, callable_name):
    if not hasattr(obj, callable_name): return None
    f = getattr(obj, callable_name)
    if not hasattr(f, '__call__'):
        raise TypeError('%s: not a callable.' % callable_name)
    if isinstance(obj, types.ClassType):
        return f.__call__(obj)
    else:
        return f.__call__()


stdout = sys.stdout
stderr = sys.stderr


def _matched_class_objects(*classes):
    class_types = (types.TypeType, types.ClassType)
    class_objects = []
    for c in classes:
        if isinstance(c, class_types):
            class_objects.append(c)
        elif isinstance(c, str):
            rexp = re.compile(c)
            globals = sys._getframe(2).f_globals
            for k in globals:
                v = globals.get(k)
                if rexp.search(k) and isinstance(v, class_types):
                    class_objects.append(v)
        else:
            raise ValueError('%s: expected class object or rexp string.' % repr(c))
    return class_objects


def invoke_tests(*classes):
    class_objects = _matched_class_objects(*classes)
    target = os.environ.get('TEST', None)
    for cls in class_objects:
        try:
            _invoke(cls, 'before_all')
            method_names = [ m for m in dir(cls) if m.startswith('test') ]
            if target:
                method_names = [ t for t in method_names if t.find(target) >= 0 ]
            method_names.sort()
            for method_name in method_names:
                obj = cls()
                obj.name = method_name
                invoke_test(obj, method_name)
        finally:
            _invoke(cls, 'after_all')


def invoke_test(obj, method_name):
    try:
        stdout.write("* %s.%s ... " % (obj.__class__.__name__, method_name))
        try:
            _invoke(obj, 'before_each')
            _invoke(obj, method_name)
        finally:
            _invoke(obj, 'after_each')
        stdout.write("[ok]\n")
    except Exception:
        ex = sys.exc_info()[1]
        stdout.write("[NG] %s\n" % str(ex))
        #tb = traceback.extract_tb(sys.exc_info()[2])
        #for filename, linenum, funcname, linetext in tb:
        #    stdout.write("  %s:%s: %s\n" % (filename, linenum, linetext))

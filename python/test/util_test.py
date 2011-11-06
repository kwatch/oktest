# -*- coding: utf-8 -*-

###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re, shutil
import unittest
import oktest
from oktest import ok, NG, run, spec
from oktest import python2, python3
from oktest.util import *
from oktest.util import flatten, rm_rf


available_with_statement = sys.version_info[0:2] > (2, 4)

os.environ['OKTEST_WARNING_DISABLED'] = 'true'


class DummyClass(object):
    pass


def do_exec(script, **kwargs):
    if not available_with_statement:
        print("*** skipped")
        return
    script = "from __future__ import with_statement\n" + script + "\n"
    gvars = {'sys': sys, 'os': os, 're': re, 'ok': ok, 'NG': NG}
    for k in oktest.dummy.__all__:
        gvars[k] = getattr(oktest.dummy, k)
    gvars.update(kwargs)
    exec(script, gvars, gvars)



class _Context_TC(unittest.TestCase):

    def setUp(self):
        self.ctx = oktest._Context()

    def test___enter__(self):
        if spec("returns self."):
            ok (self.ctx.__enter__()).is_(self.ctx)

    def test__exit__(self):
        if spec("returns None."):
            ok (self.ctx.__exit__()) == None


class _RunnableContext_TC(unittest.TestCase):

    def test_run(self):
        ctx = oktest._RunnableContext()
        ret = None
        #
        if spec("calls __enter__() and __exit__() to emurate with-statement."):
            called = []
            def enter(*args):
                called.append(('enter', args))
            def exit(*args):
                called.append(('exit', args))
            #
            ctx.__enter__ = enter
            ctx.__exit__  = exit
            def func(*args, **kwargs):
                called.append(('func', args, kwargs))
                return 123
            #
            ret = ctx.run(func, 'a', b=1)
            ok (called[0]) == ('enter', ())
            ok (called[1]) == ('func', ('a',), {'b': 1})
            ok (called[2]) == ('exit', (None, None, None))
        #
        if spec("returns value which func returned."):
            ok (ret) == 123

    def test_deco(self):
        ctx = oktest._RunnableContext()
        if spec("decorates function."):
            @ctx.deco
            def func(x):
                return x + 10
            ret = func(123)
            ok (ret) == 133
        if spec("__enter__() and __exit__() are called when decoreated function called."):
            called = []
            def enter(*args): called.append(('enter', args))
            def exit(*args): called.append(('exit', args))
            ctx.__enter__ = enter
            ctx.__exit__ = exit
            @ctx.deco
            def func(*args):
                called.append(('func', args))
                return 999
            ok (called) == []
            ret = func(456)
            ok (called[0]) == ('enter', ())
            ok (called[1]) == ('func', (456,))
            ok (called[2]) == ('exit', (None, None, None))
            ok (ret) == 999


class Spec_TC(unittest.TestCase):

    def test___init__(self):
        if spec("takes description."):
            obj = oktest.Spec('foobar')
            ok (obj.desc) == 'foobar'

    def test___iter__(sefl):
        if spec("emurates with-stmt when used with for-stmt."):
            called = []
            def enter(*args):
                called.append(('enter', args))
            def exit(*args):
                called.append(('exit', args))
            obj = oktest.Spec('foo')
            obj.__enter__ = enter
            obj.__exit__  = exit
            i = 0
            for x in obj:
                i += 1
                called.append(('yield', x))
                ok (x).is_(obj)
            ok (i) == 1
            ok (called[0]) == ('enter', ())
            ok (called[1]) == ('yield', obj)
            ok (called[2]) == ('exit', (None, None, None))

    def test___bool__(self):
        obj = oktest.Spec('SOS')
        #
        if spec("returns True when $SPEC is not set."):
            ok (bool(obj)) == True
        #
        if spec("returns False when $SPEC not matched to SPEC."):
            try:
                os.environ['SPEC'] = 'SOS'
                ok (bool(obj)) == True
                os.environ['SPEC'] = 'SOS!'
                ok (bool(obj)) == False
                os.environ['SPEC'] = 'OS'
                ok (bool(obj)) == True
            finally:
                os.environ.pop('SPEC')


class GLOBAL_TC(unittest.TestCase):

    def test_spec(self):
        obj = oktest.spec('Haruhi')
        if spec("returns oktest.Spec object."):
            ok (obj).is_a(oktest.Spec)
        if spec("takes description."):
            ok (obj.desc) == 'Haruhi'


class util_TC(unittest.TestCase):

    def test_chdir(self):
        try:
            tmpdir = '_tmp_dir'
            os.mkdir(tmpdir)
            cwd = os.getcwd()
            tmpdir_path = os.path.abspath(tmpdir)
            #+
            if spec("change directory temporarily when used with with-stmt."):
                script = r"""if True:
                import oktest
                with oktest.util.chdir(tmpdir):
                    ok (os.getcwd()) != cwd
                    ok (os.getcwd()) == tmpdir_path
                ok (os.getcwd()) == cwd  """
                do_exec(script, tmpdir=tmpdir, cwd=cwd, tmpdir_path=tmpdir_path)
            #-
            #
            if spec("change directory temporarily when run() called with function."):
                def f():
                    ok (os.getcwd()) != cwd
                    ok (os.getcwd()) == tmpdir_path
                oktest.util.chdir(tmpdir, f)
                ok (os.getcwd()) == cwd
                oktest.util.chdir(tmpdir).run(f)
                ok (os.getcwd()) == cwd
        finally:
            os.rmdir(tmpdir)

    def test_using(self):
        #+
        if spec("takes a class object and adds local vars to it when used with with-stmt."):
            script = r"""if True:
            import oktest
            with oktest.util.using(DummyClass) as obj:
                def test_1(self):
                    ok (1+1) == 2
                def test_2(self):
                    ok (1-1) == 0  """
            do_exec(script, DummyClass=DummyClass)
            if available_with_statement:
                ok (DummyClass).has_attr('test_1')
                ok (DummyClass).has_attr('test_2')
        #-
        pass

    def test_flatten(self):
        if spec("flatten nested list or tuple."):
            ret = oktest.util.flatten([[1, (2, (3, 4)), 5]])
            ok (ret) == [1, 2, 3, 4, 5]
            ret = flatten([1, [2, 3, [4, 5, [[[6]]]], [7, 8]]])
            ok (ret) == [1, 2, 3, 4, 5, 6, 7, 8]

    def test_rm_rf(self):
        try:
            os.mkdir('_test_foo1')
            os.mkdir('_test_foo2')
            os.mkdir('_test_foo2/bar1')
            for fname in ('_test_foo2/bar1/baz.txt', '_test_bar9'):
                f = open(fname, 'w')
                f.write(fname)
                f.close()
                ok (fname).is_file()
            #
            if spec("removes files and directories recursively."):
                oktest.util.rm_rf('_test_foo1', '_test_foo2', '_test_bar9')
                ok ('_test_foo1').not_exist()
                ok ('_test_foo2').not_exist()
                ok ('_test_bar9').not_exist()
        finally:
            for x in ['_test_foo1', '_test_foo2']:
                if os.path.isdir(x):
                    shutil.rmtree(x)


class util_rm_rf_TC(unittest.TestCase):

    def setUp(self):
        os.mkdir('_rm_rf')
        os.mkdir('_rm_rf/A')
        os.mkdir('_rm_rf/B')
        os.mkdir('_rm_rf/B/C')
        f = open('_rm_rf/B/C/X.txt', 'w'); f.write('xxx'); f.close()
        f = open('_rm_rf/Y.txt', 'w'); f.write('yyy'); f.close()
        assert os.path.isfile('_rm_rf/B/C/X.txt')
        assert os.path.isfile('_rm_rf/Y.txt')
    def tearDown(setup):
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
        NG (f).raises(Exception)



class Util_TC(unittest.TestCase):

    def do_test(self, input):
        fname = "__test_input.txt"
        if python2:
            assert isinstance(input, str)
            cp932 = input.decode('utf-8').encode('cp932')
            assert isinstance(cp932, str)
            f = open(fname, 'wb'); f.write(cp932); f.close()
            try:
                u = oktest.util.read_text_file(fname)
                self.assertEqual(unicode, type(u))
                self.assertEqual(input.decode('utf-8'), u)
            finally:
                os.path.exists(fname) and os.unlink(fname)
        if python3:
            assert isinstance(input, str)
            cp932 = input.encode('cp932')
            assert isinstance(cp932, bytes)
            f = open(fname, 'wb'); f.write(cp932); f.close()
            try:
                s = oktest.util.read_text_file(fname)
                self.assertEqual(str, type(s))
                self.assertEqual(input, s)
            finally:
                os.path.exists(fname) and os.unlink(fname)

    def test__read_text_file__with_magic_comment(self):
        ## with magic comment
        input = r"""
# -*- coding: cp932 -*-
あいうえお
"""[1:]
        self.do_test(input)

    def test__read_text_file__with_shebang(self):
        ## with shebang
        input = r"""
#!/usr/bin/env python
# -*- coding: cp932 -*-
あいうえお
"""[1:]
        self.do_test(input)

    def test__read_text_file__when_no_magic_comment(self):
        ## without magic comment
        input = r"""
あいうえお
"""[1:]
        try:
            self.do_test(input)
            self.fail('UnicodeDecodeError expected but not raised')
        except Exception:
            ex = sys.exc_info()[1]
            self.assertEqual(UnicodeDecodeError, ex.__class__)
            self.assertTrue("'utf8' codec can't decode byte 0x82 in position 0: invalid start byte", str(ex))



if __name__ == '__main__':
    #oktest.run()
    unittest.main()

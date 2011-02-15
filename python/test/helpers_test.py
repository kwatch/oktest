###
### $Release: 0.8.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###
from __future__ import with_statement

import sys, os, re
import oktest
from oktest import ok, NG, run, spec
from oktest.helper import *
from oktest.dummy import *


class _Context_TC(object):

    def before(self):
        self.ctx = oktest._Context()

    def test___enter__(self):
        with spec("returns self."):
            ok (self.ctx.__enter__()).is_(self.ctx)

    def test__exit__(self):
        with spec("returns None."):
            ok (self.ctx.__exit__()) == None


class _RunnableContext_TC(object):

    def test_run(self):
        ctx = oktest._RunnableContext()
        ret = None
        #
        with spec("calls __enter__() and __exit__() to emurate with-statement."):
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
        with spec("returns value which func returned."):
            ok (ret) == 123

    def test_deco(self):
        ctx = oktest._RunnableContext()
        with spec("decorates function."):
            @ctx.deco
            def func(x):
                return x + 10
            ret = func(123)
            ok (ret) == 133
        with spec("__enter__() and __exit__() are called when decoreated function called."):
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


class Spec_TC(object):

    def test___init__(self):
        with spec("takes description."):
            obj = oktest.Spec('foobar')
            ok (obj.desc) == 'foobar'

    def test___iter__(sefl):
        with spec("emurates with-stmt when used with for-stmt."):
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
        with spec("returns True when $SPEC is not set."):
            ok (bool(obj)) == True
        #
        with spec("returns False when $SPEC not matched to SPEC."):
            try:
                os.environ['SPEC'] = 'SOS'
                ok (bool(obj)) == True
                os.environ['SPEC'] = 'SOS!'
                ok (bool(obj)) == False
                os.environ['SPEC'] = 'OS'
                ok (bool(obj)) == True
            finally:
                os.environ.pop('SPEC')


class GLOBAL_TC(object):

    def test_spec(self):
        obj = oktest.spec('Haruhi')
        with spec("returns oktest.Spec object."):
            ok (obj).is_a(oktest.Spec)
        with spec("takes description."):
            ok (obj.desc) == 'Haruhi'


class DummyClass(object):
    pass


class helper_TC(object):

    def test_chdir(self):
        try:
            tmpdir = '_tmp_dir'
            os.mkdir(tmpdir)
            cwd = os.getcwd()
            tmpdir_path = os.path.abspath(tmpdir)
            #+
            with spec("change directory temporarily when used with with-stmt."):
                with oktest.helper.chdir(tmpdir):
                    ok (os.getcwd()) != cwd
                    ok (os.getcwd()) == tmpdir_path
                ok (os.getcwd()) == cwd
            #-
            #
            with spec("change directory temporarily when run() called with function."):
                def f():
                    ok (os.getcwd()) != cwd
                    ok (os.getcwd()) == tmpdir_path
                oktest.helper.chdir(tmpdir, f)
                ok (os.getcwd()) == cwd
                oktest.helper.chdir(tmpdir).run(f)
                ok (os.getcwd()) == cwd
        finally:
            os.rmdir(tmpdir)

    def test_using(self):
        #+
        with spec("takes a class object and adds local vars to it when used with with-stmt."):
            with oktest.helper.using(DummyClass) as obj:
                def test_1(self):
                    ok (1+1) == 2
                def test_2(self):
                    ok (1-1) == 0
            ok (DummyClass).has_attr('test_1')
            ok (DummyClass).has_attr('test_2')
        #-
        pass

    def test_flatten(self):
        with spec("flatten nested list or tuple."):
            ret = oktest.helper.flatten([[1, (2, (3, 4)), 5]])
            ok (ret) == [1, 2, 3, 4, 5]

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
            with spec("removes files and directories recursively."):
                oktest.helper.rm_rf('_test_foo1', '_test_foo2', '_test_bar9')
                ok ('_test_foo1').not_exist()
                ok ('_test_foo2').not_exist()
                ok ('_test_bar9').not_exist()
        finally:
            pass


from oktest.dummy import *

class dummy_TC(object):

    def test_dummy_file(self):
        fname, content = '_test.sos.txt', 'SOS'
        #+
        with spec("creates a dummy file temporarily when used with with-stmt."):
            with dummy_file(fname, content):
                ok (fname).is_file()
                f = open(fname); s = f.read(); f.close()
                ok (s) == content
            NG (fname).is_file()
        #-
        #
        with spec("creates a dummy file temporarily when run() called with a function."):
            called = []
            def func():
                called.append(('func', fname))
                ok (fname).is_file()
                f = open(fname); s = f.read(); f.close()
                ok (s) == content
                return 999
            ret = dummy_file(fname, content).run(func)
            NG (fname).is_file()
            ok (called[0]) == ('func', fname)
            ok (ret) == 999

    def test_dummy_dir(self):
        dname = '_test.sos.dir'
        #+
        with spec("creates a dummy directory temporarily when used with with-stmt."):
            with dummy_dir(dname):
                ok (dname).is_dir()
            NG (dname).is_dir()
        #-
        #
        with spec("creates a dummy directory temporarily when run() called with a function."):
            called = []
            def func():
                called.append(('func', dname))
                ok (dname).is_dir()
                return 888
            ret = dummy_dir(dname).run(func)
            NG (dname).is_dir()
            ok (called[0]) == ('func', dname)
            ok (ret) == 888

    def test_dummy_values(self):
        d = {'Haruhi': 'Suzumiya'}
        #+
        with spec("changes dictionary value temporarily when used with with-stmt."):
            with dummy_values(d, Yuki='Nagato'):
                ok (d.get('Yuki', None)) == 'Nagato'
            ok ('Haruhi' in d) == True
            ok ('Yuki' in d) == False
        #-
        #
        with spec("changes dictionary value temporarily when run() called with function."):
            called = []
            def func():
                called.append(True)
                ok (d.get('Mikuru', None)) == 'Asahina'
            dummy_values(d, Mikuru='Asahina').run(func)
            ok (called) == [True]
            ok (d) == {'Haruhi': 'Suzumiya'}

    def test_dummy_attrs(self):
        obj = DummyClass()
        #+
        with spec("changes attributes temporarily when used with with-stmt."):
            with dummy_attrs(obj, SOS=[123]):
                ok (obj).has_attr('SOS')
                ok (obj.SOS) == [123]
            NG (obj).has_attr('SOS')
        #-
        #
        with spec("changes attributes temporarily when run() called with function."):
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

    def test_dummy_environ_vars(self):
        #+
        with spec("changes environment variables temporarily when used with with-stmt."):
            ok ('SOS' in os.environ) == False
            with dummy_environ_vars(SOS='!!!'):
                ok ('SOS' in os.environ) == True
                ok (os.environ['SOS']) == '!!!'
            ok ('SOS' in os.environ) == False
        #-
        #
        with spec("changes environment variables temporarily when run() called with function."):
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

    def test_dummy_io(self):
        sin = sys.stdin
        sout = sys.stdout
        serr = sys.stderr
        #+
        with spec("changes stdio temporarily when used with with-stmt."):
            with dummy_io("foobar") as d_io:
                NG (sys.stdin).is_(sin)
                NG (sys.stdout).is_(sout)
                NG (sys.stderr).is_(serr)
                ok (sys.stdin.read()) == "foobar"
                sys.stdout.write("Haruhi\n")
                print("Sasaki")
                sys.stderr.write("Kyon")
            ok (sys.stdin).is_(sin)
            ok (sys.stdout).is_(sout)
            ok (sys.stderr).is_(serr)
            ok (d_io.stdout) == "Haruhi\nSasaki\n"
            ok (d_io.stderr) == "Kyon"
        #-
        #
        with spec("changes stdio temporarily when run() called with function."):
            called = []
            def func():
                called.append(True)
                NG (sys.stdin).is_(sin)
                NG (sys.stdout).is_(sout)
                NG (sys.stderr).is_(serr)
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


if __name__ == '__main__':
    oktest.run()

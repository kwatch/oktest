###
### $Release: 0.9.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re, shutil
import unittest
import oktest
from oktest import ok, NG, run, spec
from oktest.util import *
from oktest.util import flatten, rm_rf
from oktest.dummy import *

available_with_statement = sys.version_info[0:2] > (2, 4)

os.environ['OKTEST_WARNING_DISABLED'] = 'true'


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


class DummyClass(object):
    pass


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



from oktest.dummy import *

def new_gvars(**kwargs):
    d = {'sys': sys, 'os': os, 're': re, 'ok': ok, 'NG': NG}
    d.update(kwargs)
    return d


class dummy_TC(unittest.TestCase):


    def test_dummy_file(self):
        fname, content = '_test.sos.txt', 'SOS'
        if spec("creates a dummy file temporarily when used with with-stmt."):
            script = r"""if True:
            with dummy_file(fname, content):
                ok (fname).is_file()
                f = open(fname); s = f.read(); f.close()
                ok (s) == content
            NG (fname).is_file()  """
            do_exec(script, fname=fname, content=content)
        #
        if spec("creates a dummy file temporarily when run() called with a function."):
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
        #
        if spec("available as decorator."):
            called = []
            @dummy_file(fname, content)
            def func():
                called.append(('func', fname))
                ok (fname).is_file()
                f = open(fname); s = f.read(); f.close()
                ok (s) == content
                return 999
            ret = func
            NG (fname).is_file()
            ok (called[0]) == ('func', fname)
            ok (ret) == 999

    def test_dummy_dir(self):
        dname = '_test.sos.dir'
        #+
        if spec("creates a dummy directory temporarily when used with with-stmt."):
            script = r"""if True:
            with dummy_dir(dname):
                ok (dname).is_dir()
            NG (dname).is_dir()  """
            do_exec(script, dname=dname)
        #-
        #
        if spec("creates a dummy directory temporarily when run() called with a function."):
            called = []
            def func():
                called.append(('func', dname))
                ok (dname).is_dir()
                return 888
            ret = dummy_dir(dname).run(func)
            NG (dname).is_dir()
            ok (called[0]) == ('func', dname)
            ok (ret) == 888
        #
        if spec("available as decorator."):
            called = []
            @dummy_dir(dname)
            def func():
                called.append(('func', dname))
                ok (dname).is_dir()
                return 888
            ret = func
            NG (dname).is_dir()
            ok (called[0]) == ('func', dname)
            ok (ret) == 888

    def test_dummy_values(self):
        d = {'Haruhi': 'Suzumiya'}
        #+
        if spec("changes dictionary value temporarily when used with with-stmt."):
            script = r"""if True:
            with dummy_values(d, Yuki='Nagato'):
                ok (d.get('Yuki', None)) == 'Nagato'
            ok ('Haruhi' in d) == True
            ok ('Yuki' in d) == False  """
            do_exec(script, d=d)
        #-
        #
        if spec("changes dictionary value temporarily when run() called with function."):
            called = []
            def func():
                called.append(True)
                ok (d.get('Mikuru', None)) == 'Asahina'
            dummy_values(d, Mikuru='Asahina').run(func)
            ok (called) == [True]
            ok (d) == {'Haruhi': 'Suzumiya'}
        #
        if spec("available as decorator."):
            called = []
            @dummy_values(d, Mikuru='Asahina')
            def func():
                called.append(True)
                ok (d.get('Mikuru', None)) == 'Asahina'
            ok (called) == [True]
            ok (d) == {'Haruhi': 'Suzumiya'}

    def test_dummy_attrs(self):
        obj = DummyClass()
        #+
        if spec("changes attributes temporarily when used with with-stmt."):
            script = r"""if True:
            with dummy_attrs(obj, SOS=[123]):
                ok (obj).has_attr('SOS')
                ok (obj.SOS) == [123]
            NG (obj).has_attr('SOS')  """
            do_exec(script, obj=obj)
        #-
        #
        if spec("changes attributes temporarily when run() called with function."):
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
        #
        if spec("available as decorator."):
            called = []
            @dummy_attrs(obj, SOS=[123])
            def func():
                called.append(True)
                ok (obj).has_attr('SOS')
                ok (obj.SOS) == [123]
                return 999
            ret = func
            ok (called) == [True]
            NG (obj).has_attr('SOS')
            ok (ret) == 999

    def test_dummy_environ_vars(self):
        #+
        if spec("changes environment variables temporarily when used with with-stmt."):
            script = r"""if True:
            ok ('SOS' in os.environ) == False
            with dummy_environ_vars(SOS='!!!'):
                ok ('SOS' in os.environ) == True
                ok (os.environ['SOS']) == '!!!'
            ok ('SOS' in os.environ) == False  """
            do_exec(script)
        #-
        #
        if spec("changes environment variables temporarily when run() called with function."):
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
        #
        if spec("available as decorator."):
            called = []
            @dummy_environ_vars(SOS='???')
            def func():
                called.append(True)
                ok ('SOS' in os.environ) == True
                ok (os.environ['SOS']) == '???'
                return 111
            ret = func
            ok (called) == [True]
            ok ('SOS' in os.environ) == False
            ok (ret) == 111

    def test_dummy_io(self):
        sin = sys.stdin
        sout = sys.stdout
        serr = sys.stderr
        #+
        if spec("changes stdio temporarily when used with with-stmt."):
            script = r"""if True:
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
            ok (d_io.stderr) == "Kyon"  """
            do_exec(script, sin=sin, sout=sout, serr=serr)
        #-
        #
        if spec("changes stdio temporarily when run() called with function."):
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
        #
        if spec("available as decorator."):
            called = []
            @dummy_io("SOS")
            def func():
                called.append(True)
                NG (sys.stdin).is_(sin)
                NG (sys.stdout).is_(sout)
                NG (sys.stderr).is_(serr)
                ok (sys.stdin.read()) == "SOS"
                sys.stdout.write("Mikuru")
                print("Yuki")
                sys.stderr.write("Itsuki")
            d_io = func
            ok (called) == [True]
            ok (sys.stdin).is_(sin)
            ok (sys.stdout).is_(sout)
            ok (sys.stderr).is_(serr)
            ok (d_io.stdout) == "MikuruYuki\n"
            ok (d_io.stderr) == "Itsuki"
            sout, serr = d_io
            ok (sout) == "MikuruYuki\n"
            ok (serr) == "Itsuki"


if __name__ == '__main__':
    #oktest.run()
    unittest.main()

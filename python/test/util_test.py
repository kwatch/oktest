# -*- coding: utf-8 -*-
###
### $Release: 0.0.0 $
### $Copyright: copyright(c) 2010-2012 kuwata-lab.com all rights reserved $
### $License: MIT License $
###
from __future__ import with_statement

import sys, os, re, shutil
import unittest
import oktest
from oktest import ok, NG, run
from oktest import python2, python3
from oktest.util import chdir, flatten, rm_rf, from_here, zenkaku_width, zenkaku_shorten


available_with_statement = sys.version_info[0:2] > (2, 4)

os.environ['OKTEST_WARNING_DISABLED'] = 'true'


class DummyClass(object):
    pass


def _do_exec(script, **kwargs):
    if not available_with_statement:
        print("*** skipped")
        return
    script = "from __future__ import with_statement\n" + script + "\n"
    gvars = {'sys': sys, 'os': os, 're': re, 'ok': ok, 'NG': NG}
    for k in oktest.dummy.__all__:
        gvars[k] = getattr(oktest.dummy, k)
    gvars.update(kwargs)
    exec(script, gvars, gvars)



class Context_TC(unittest.TestCase):


    def test___enter__(self):
        """returns self."""
        ctx = oktest.util.Context()
        ok (ctx.__enter__()).is_(ctx)


    def test__exit__(self):
        """returns None."""
        ctx = oktest.util.Context()
        ok (ctx.__exit__()) == None



class RunnableContext_TC(unittest.TestCase):


    def test_run_1(self):
        """calls __enter__() and __exit__() to emurate with-statement."""
        ctx = oktest.util.RunnableContext()
        ret = None
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

    def test_run_2(self):
        """returns value which func returned."""
        ctx = oktest.util.RunnableContext()
        def func():
            return 123
        ret = ctx.run(func)
        ok (ret) == 123


    def test_deco_1(self):
        """decorates function."""
        ctx = oktest.util.RunnableContext()
        @ctx.deco
        def func(x):
            return x + 10
        ret = func(123)
        ok (ret) == 133

    def test_deco_2(self):
        """__enter__() and __exit__() are called when decoreated function called."""
        ctx = oktest.util.RunnableContext()
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



class util_TC(unittest.TestCase):


    def _before_chdir(self):
        self.tmpdir = '_tmp_dir'
        os.mkdir(self.tmpdir)
        self.cwd = os.getcwd()
        self.tmpdir_path = os.path.abspath(self.tmpdir)

    def _after_chdir(self):
        os.rmdir(self.tmpdir)


    def test_chdir_1(self):
        """change directory temporarily when used with with-stmt."""
        try:
            self._before_chdir()
            tmpdir, cwd, tmpdir_path = self.tmpdir, self.cwd, self.tmpdir_path
            script = r"""if True:
                import oktest
                with oktest.util.chdir(tmpdir):
                    ok (os.getcwd()) != cwd
                    ok (os.getcwd()) == tmpdir_path
                ok (os.getcwd()) == cwd  """
            _do_exec(script, tmpdir=tmpdir, cwd=cwd, tmpdir_path=tmpdir_path)
        finally:
            self._after_chdir()

    def test_chdir_2(self):
        """change directory temporarily when run() called with function."""
        try:
            self._before_chdir()
            tmpdir, cwd, tmpdir_path = self.tmpdir, self.cwd, self.tmpdir_path
            #
            def f():
                ok (os.getcwd()) != cwd
                ok (os.getcwd()) == tmpdir_path
            oktest.util.chdir(tmpdir, f)
            ok (os.getcwd()) == cwd
            oktest.util.chdir(tmpdir).run(f)
            ok (os.getcwd()) == cwd
        finally:
            self._after_chdir()


    def test_using_1(self):
        """takes a class object and adds local vars to it when used with with-stmt."""
        script = r"""if True:
        import oktest
        with oktest.util.using(DummyClass) as obj:
            def test_1(self):
                ok (1+1) == 2
            def test_2(self):
                ok (1-1) == 0  """
        _do_exec(script, DummyClass=DummyClass)
        if available_with_statement:
            ok (DummyClass).has_attr('test_1')
            ok (DummyClass).has_attr('test_2')


    def test_flatten_1(self):
        """flatten nested list or tuple."""
        ret = oktest.util.flatten([[1, (2, (3, 4)), 5]])
        ok (ret) == [1, 2, 3, 4, 5]
        ret = flatten([1, [2, 3, [4, 5, [[[6]]]], [7, 8]]])
        ok (ret) == [1, 2, 3, 4, 5, 6, 7, 8]


    def _before_rm_rf(self):
        os.mkdir('_rm_rf')
        os.mkdir('_rm_rf/A')
        os.mkdir('_rm_rf/B')
        os.mkdir('_rm_rf/B/C')
        f = open('_rm_rf/B/C/X.txt', 'w'); f.write('xxx'); f.close()
        f = open('_rm_rf/Y.txt', 'w'); f.write('yyy'); f.close()
        assert os.path.isfile('_rm_rf/B/C/X.txt')
        assert os.path.isfile('_rm_rf/Y.txt')

    def _after_rm_rf(setup):
        if os.path.isdir('_rm_rf'):
            shutil.rmtree('_rm_rf')

    def test_rm_rf_1(self):
        """remove files or directories recursively"""
        self._before_rm_rf()
        try:
            rm_rf('_rm_rf')
            ok ('_rm_rf').not_exist()
        finally:
            self._after_rm_rf()

    def test_rm_rf_2(self):
        """accepts arguments"""
        self._before_rm_rf()
        try:
            args = ['_rm_rf/A', '_rm_rf/B', '_rm_rf/Y.txt']
            rm_rf(*args)
            ok ('_rm_rf/A').not_exist()
            ok ('_rm_rf/B').not_exist()
            ok ('_rm_rf/Y.txt').not_exist()
        finally:
            self._after_rm_rf()

    def test_rm_rf_3(self):
        """flatten args"""
        self._before_rm_rf()
        try:
            args = ['_rm_rf/A', ['_rm_rf/B', '_rm_rf/Y.txt']]
            rm_rf(args)
            for arg in flatten(args):
                ok (os.path.exists(arg)) == False
        finally:
            self._after_rm_rf()

    def test_rm_rf_4(self):
        """ignore unexist files"""
        self._before_rm_rf()
        try:
            def fn():
                rm_rf('_rm_rf/A', '_rm_rf/K', '_rm_rf/Z.txt')
            ok (fn).not_raise()
        finally:
            self._after_rm_rf()


    def test_from_here_1(self):
        old = sys.path[:]
        currpath = os.path.join(os.getcwd(), os.path.dirname(__file__), 'foobar')
        expected = [currpath] + old
        with from_here('foobar'):
            ok (sys.path) == expected
        ok (sys.path) != expected
        ok (sys.path) == old

    def test_from_here_2(self):
        old = sys.path[:]
        currpath = os.path.join(os.getcwd(), os.path.dirname(__file__), '../foobar')
        expected = [os.path.realpath(currpath)] + old
        with from_here('../foobar'):
            ok (sys.path) == expected
        ok (sys.path) != expected
        ok (sys.path) == old

    def test_from_here_3(self):
        old = sys.path[:]
        abspath = os.path.dirname(os.path.abspath(__file__))
        expected = [abspath] + old
        with from_here():
            ok (sys.path) == expected
        ok (sys.path) != expected
        ok (sys.path) == old


    def _do_test(self, input):
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

    def test_read_text_file_1(self):
        """with magic comment"""
        input = r"""
# -*- coding: cp932 -*-
あいうえお
"""[1:]
        self._do_test(input)

    def test_read_text_file_2(self):
        """with shebang"""
        input = r"""
#!/usr/bin/env python
# -*- coding: cp932 -*-
あいうえお
"""[1:]
        self._do_test(input)

    def test_read_text_file_3(self):
        """without magic comment"""
        input = r"""
あいうえお
"""[1:]
        try:
            self._do_test(input)
            self.fail('UnicodeDecodeError expected but not raised')
        except Exception:
            ex = sys.exc_info()[1]
            self.assertEqual(UnicodeDecodeError, ex.__class__)
            self.assertTrue("'utf8' codec can't decode byte 0x82 in position 0: invalid start byte", str(ex))

    def test_zenkaku_width_1(self):
        if python2:
            _unistr = lambda s: s.decode('utf-8')
        elif python3:
            _unistr = lambda s: s
        ok (zenkaku_width(_unistr("SOS"))) == 3
        ok (zenkaku_width(_unistr("ハルヒ"))) == 6
        ok (zenkaku_width(_unistr("SOS/ハルヒ"))) == 10

    def test_zenkaku_shorten_1(self):
        if python2:
            _unistr = lambda s: s.decode('utf-8')
        elif python3:
            _unistr = lambda s: s
        unicode_string = _unistr("SOS/ハルヒ")
        ok (zenkaku_shorten(unicode_string, 4)) == _unistr("SOS/")
        ok (zenkaku_shorten(unicode_string, 5)) == _unistr("SOS/")
        ok (zenkaku_shorten(unicode_string, 6)) == _unistr("SOS/ハ")
        ok (zenkaku_shorten(unicode_string, 7)) == _unistr("SOS/ハ")
        ok (zenkaku_shorten(unicode_string, 8)) == _unistr("SOS/ハル")
        ok (zenkaku_shorten(unicode_string, 9)) == _unistr("SOS/ハル")
        ok (zenkaku_shorten(unicode_string, 10)) == _unistr("SOS/ハルヒ")
        ok (zenkaku_shorten(unicode_string, 11)) == _unistr("SOS/ハルヒ")
        ok (zenkaku_shorten(unicode_string, 12)) == _unistr("SOS/ハルヒ")

    def test_helper_1(self):
        """'help' is an alias of 'util'"""
        import oktest
        import oktest.util
        ok (oktest).has_attr('helper')
        ok (oktest.helper).is_(oktest.util)

    def test_helper_2(self):
        """'help' is an alias of 'util'"""
        def fn():
            import oktest.helper
        ok (fn).not_raise()



if __name__ == '__main__':
    #oktest.run()
    unittest.main()

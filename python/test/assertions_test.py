###
### $Release: $
### $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest

import oktest
from oktest import ok, not_ok, NG


def be_fail(message):
    def deco(func):
        try:
            func()
        except AssertionError:
            if message:
                ex = sys.exc_info()[1]
                assert message == str(ex), "%r != %r" % (message, str(ex))
        else:
            assert False, "AssertionError expected but not raised"
    return deco


def be_error(error_class, message):
    def deco(func):
        try:
            func()
        except Exception:
            exc_info = sys.exc_info()
            assert exc_info[0] is error_class, "%r is not %r" % (exc_info[0], error_class)
            if message:
                ex = exc_info[1]
                assert message == str(ex), "%r != %r" % (message, str(ex))
        else:
            assert False, "%s expected but not raised" % (exc_info[0])
    return deco



class Assertions_TC(unittest.TestCase):


    def test_eq(self):
        ok (1+1) == 2
        NG (1+1) == 1
        @be_fail("2 == 1 : failed.")
        def fn(): ok (1+1) == 1
        @be_fail("not 2 == 2 : failed.")
        def fn(): NG (1+1) == 2


    def test_ne(self):
        ok (1+1) != 1
        NG (1+1) != 2
        @be_fail("2 != 2 : failed.")
        def fn(): ok (1+1) != 2
        @be_fail("not 2 != 1 : failed.")
        def fn(): NG (1+1) != 1


    def test_lt(self):
        ok (1) < 2
        NG (2) < 2
        @be_fail("2 < 2 : failed.")
        def fn(): ok (2) < 2
        @be_fail("not 1 < 2 : failed.")
        def fn(): NG (1) < 2

    def test_le(self):
        ok (2) <= 2
        NG (2) <= 1
        @be_fail("2 <= 1 : failed.")
        def fn(): ok (2) <= 1
        @be_fail("not 2 <= 2 : failed.")
        def fn(): NG (2) <= 2

    def test_gt(self):
        ok (2) > 1
        NG (2) > 2
        @be_fail("2 > 2 : failed.")
        def fn(): ok (2) > 2
        @be_fail("not 2 > 1 : failed.")
        def fn(): NG (2) > 1

    def test_ge(self):
        ok (2) >= 2
        NG (1) >= 2
        @be_fail("1 >= 2 : failed.")
        def fn(): ok (1) >= 2
        @be_fail("not 2 >= 2 : failed.")
        def fn(): NG (2) >= 2


    def test_in_delta(self):
        ok (3.14159).in_delta(3.1415, 0.0001)
        @be_fail(None)
        def fn(): ok (3.14159).in_delta(3.1415, 0.00001)
        #msg = "3.1415899999999999 < 3.1415100000000002 : failed."
        #msg = "3.14159 < 3.1415100000000002 : failed."
        msg = "%r < %r : failed." % (3.14159, 3.1415 + 0.00001)
        @be_fail(msg)
        def fn(): ok (3.14159).in_delta(3.1415, 0.00001)


    def test_in_delta(self):
        ok ("123@mail.com").matches(r'\w+@\w+(\.\w+)')
        ok ("123@mail.com").matches(re.compile(r'^\w+@\w+(\.\w+)$'))
        @be_fail(r"re.search('\\d+', 'abc') : failed.")
        def fn(): ok ("abc").matches(r'\d+')
        @be_fail(r"not re.search('\\w+', 'foo') : failed.")
        def fn(): ok ("foo").not_match(re.compile(r'\w+'))


    def test_is_(self):
        val1 = [10]
        val2 = [10]
        ok (val1).is_(val1)
        @be_fail("[10] is [10] : failed.")
        def fn(): ok (val1).is_(val2),

    def test_is_not(self):
        val1 = [10]
        val2 = [10]
        ok (val1).is_not(val2)
        @be_fail("[10] is not [10] : failed.")
        def fn(): ok (val1).is_not(val1)


    def test_in_(self):
        L = [0,10,20,30]
        ok (10).in_(L)
        @be_fail("11 in [0, 10, 20, 30] : failed.")
        def fn(): ok (11).in_(L)

    def test_not_in(self):
        L = [0,10,20,30]
        ok (11).not_in(L)
        @be_fail("10 not in [0, 10, 20, 30] : failed.")
        def fn(): ok (10).not_in(L)


    global Val
    class Val(object):
        def __init__(self, val):
            self.val = val
        def __repr__(self):
            return "<Val val=%s>" % self.val

    def test_is_a(self):
        ok (Val(123)).is_a(Val)
        @be_fail("isinstance(123, Val) : failed.")
        def fn(): ok (123).is_a(Val)

    def test_is_not_a(self):
        ok (123).is_not_a(Val)
        @be_fail("not isinstance(<Val val=123>, Val) : failed.")
        def fn(): ok (Val(123)).is_not_a(Val)


    def test_has_attr(self):
        ok ("s").has_attr("__class__")
        @be_fail("hasattr('s', 'xxxxx') : failed.")
        def fn(): ok ("s").has_attr("xxxxx")
        #
        ok ("s").hasattr("__class__")
        @be_fail("hasattr('s', 'xxxxx') : failed.")
        def fn(): ok ("s").hasattr("xxxxx")


    def test_raises(self):
        def f(): raise ValueError('errmsg1')
        ok (f).raises(ValueError)              # ValueError
        def f(): raise ValueError('errmsg1')
        ok (f).raises(ValueError, 'errmsg1')   # ValueError + errmsg
        def f(): raise ValueError('errmsg1')
        ok (f).raises(Exception, 'errmsg1')    # Exception + errmsg
        def f(): raise ValueError('errmsg1')
        ok (f).raises(Exception)               # f.exception
        assert hasattr(f, 'exception')
        assert isinstance(f.exception, ValueError)
        assert str(f.exception) == 'errmsg1'
        #
        @be_fail("Exception should be raised : failed.")
        def fn():
            def f(): pass
            ok (f).raises(Exception)
        @be_fail("ValueError('errmsg1',) is kind of NameError : failed.")
        def fn():
            def f(): raise ValueError('errmsg1')
            ok (f).raises(NameError)
        @be_fail("'errmsg1' == 'errmsg2' : failed.")
        def fn():
            def f(): raise ValueError('errmsg1')
            ok (f).raises(ValueError, 'errmsg2')

    def test_raises2(self):     # pass through AssertionError
        def f():
            assert 1 == 2, '1==2'            # assertion failed
            raise ValueError('errmsg1')
        try:
            ok (f).raises(ValueError)        # ok().raises() doens't catch assertion error
        except AssertionError:
            assert True, "OK"
            ex = sys.exc_info()[1]
            assert str(ex) == '1==2'
        except Exception:
            assert Failse, "AssertionError expected"
        else:
            assert Failse, "AssertionError expected"


    def test_not_raise2(self):  # pass through AssertionError
        def f():
            assert 1 == 0                  # assertion failed
        try:
            ok (f).not_raise(Exception)    # Exception
        except AssertionError:
            ex = sys.exc_info()[1]
            assert str(ex) == ""
        except Exception:
            assert Failse, "AssertionError expected"
        else:
            assert Failse, "AssertionError expected"


    def test_is_file(self):
        fname = '__foobar.txt'
        dname = '__foobar.d'
        try:
            f = open(fname, 'w')
            f.write('foobar')
            f.close()
            os.mkdir(dname)
            #
            ok (fname).is_file()
            ok (dname).is_not_file()
        finally:
            os.unlink(fname)
            os.rmdir(dname)


    def test_is_dir(self):
        fname = '__foobar.txt'
        dname = '__foobar.d'
        try:
            f = open(fname, 'w')
            f.write('foobar')
            f.close()
            os.mkdir(dname)
            #
            ok (dname).is_dir()
            ok (fname).is_not_dir()
        finally:
            os.unlink(fname)
            os.rmdir(dname)


    ## ------------------------------------------------------------


    def test_not_ok(self):
        try:
            f = open('foobar.txt', 'w'); f.write('foobar'); f.close()
            os.mkdir('foobar.d')
            #
            not_ok ("xxxxxx.txt").is_file()
            not_ok ("foobar.d").is_file()
            not_ok ("foobar.txt").is_not_file()
            #
            not_ok ("xxxxxx.d").is_dir()
            not_ok ("foobar.txt").is_dir()
            not_ok ("foobar.d").is_not_dir()
            #
            not_ok ("foobar").matches("\d+")
            not_ok ("123").not_match("\d+")
        finally:
            os.unlink('foobar.txt')
            os.rmdir('foobar.d')


    def test_NG(self):
        try:
            f = open('foobar.txt', 'w'); f.write('foobar'); f.close()
            os.mkdir('foobar.d')
            #
            NG ("xxxxxx.txt").is_file()
            NG ("foobar.d").is_file()
            NG ("foobar.txt").is_not_file()
            #
            NG ("xxxxxx.d").is_dir()
            NG ("foobar.txt").is_dir()
            NG ("foobar.d").is_not_dir()
            #
            NG ("foobar").matches("\d+")
            NG ("123").not_match("\d+")
        finally:
            os.unlink('foobar.txt')
            os.rmdir('foobar.d')


    def test_should(self):
        ok ("foobar").should.startswith("foob")
        @be_fail("'foobar'.startswith('aaa') : failed.")
        def fn(): ok ("foobar").should.startswith("aaa")
        #
        @be_error(AttributeError, "'str' object has no attribute 'start_with'")
        def fn(): ok ("foobar").should.start_with("foob")   # AttributeError
        @be_error(ValueError, "module.path: not a callable.")
        def fn(): ok (sys).should.path()
        @be_error(ValueError, "'Sasaki'.upper(): expected to return True or False but it returned 'SASAKI'.")
        def fn(): ok ("Sasaki").should.upper()


    def test_should_not(self):
        ok ("foobar").should_not.startswith("aaa")
        @be_fail("not 'foobar'.startswith('foo') : failed.")
        def fn(): ok ("foobar").should_not.startswith("foo")


    def test_assertion(self):
        @oktest.assertion
        def startswith_(self, arg):
            boolean = self.target.startswith(arg)
            if boolean != self.boolean:
                self.failed("%r.startswith(%r) : failed." % (self.target, arg))
        ok ("foobar").startswith_("foob")
        NG ("foobar").startswith_("a")
        @be_fail("'foobar'.startswith('afoo') : failed.")
        def fn(): ok ("foobar").startswith_("afoo")
        @be_fail("not 'foobar'.startswith('foo') : failed.")
        def fn(): NG ("foobar").startswith_("foo")


    def test_chained(self):
        ok ("Sasaki".upper()).is_a(str).matches(r'^[A-Z]+$') == "SASAKI"
        try:
            bkup = oktest.DIFF
            oktest.DIFF = False
            @be_fail("'SASAKI' == 'Sasaki' : failed.")
            def fn(): ok ("Sasaki".upper()).is_a(str).matches(r'^[A-Z]+$') == "Sasaki"
        finally:
            oktest.DIFF = bkup



if __name__ == '__main__':
    unittest.main()
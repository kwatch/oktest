# -*- coding: utf-8 -*-

import sys
import unittest
import oktest
from oktest import ok, test, run

try:
    from cStringIO import StringIO
except ImportError:
    from io import StringIO

try:
    xrange
except NameError:
    xrange = range


from benchmarker import Benchmarker, cmdopt
#cmdopt.parse()

def unittest_run(klass):
    loader = unittest.defaultTestLoader
    runner = unittest.TextTestRunner(stream=StringIO())
    suite = loader.loadTestsFromTestCase(klass)
    runner.run(suite)


class MenuEntry(object):

    def __init__(self):
        self.items = []

    def __call__(self, title):
        def deco(fn):
            self.items.append((title, fn))
        return deco

    def main_loop(self):
        while True:
            i = 0
            for title, block in self.items:
                i += 1
                print("** %d: %s" % (i, title))
            ret = raw_input("** which? [1-%d, or enter to quit]: " % i)
            ret = ret.strip()
            if not ret:
                break
            choice = int(ret)
            if 1 <= choice <= len(self.items):
                index = choice - 1
                block = self.items[index][1]
                print("")
                block()
                print("")
            else:
                print("** unexpected input.")

entry = MenuEntry()

###
@entry("how much difference between oktest and unittest about speed?")
def _():

    class OktestRunningTest(object):
        for i in xrange(10):
            exec("def test_%s(self): assert 1==1\n" % i)
    #run(OktestRunningTest)

    class UnittestRunningTest(unittest.TestCase):
        for i in xrange(10):
            exec("def test_%s(self): assert 1==1\n" % i)
    #loader = unittest.defaultTestLoader
    #runner = unittest.TextTestRunner()
    #suite = loader.loadTestsFromTestCase(UnittestRunningTest)
    #runner.run(suite)

    for bm in Benchmarker(width=25, loop=10000, cycle=3):
        ## oktest
        for _ in bm("oktest.run()"):
            run(OktestRunningTest, out=StringIO())
        ## unittest
        loader = unittest.TestLoader()
        runner = unittest.TextTestRunner(stream=StringIO())
        for _ in bm("unittest.runner.run()"):
            suite = loader.loadTestsFromTestCase(UnittestRunningTest)
            runner.run(suite)


###
@entry("how does existence of 'self' affect to speed?")
def _():

    class ProviderHasSelf(unittest.TestCase):

        def provide_haruhi(self): return "Haruhi"
        def provide_mikuru(self): return "Mikuru"
        def provide_yuki(self):   return "Yuki"

        for i in xrange(10):
            @test("example")
            def _(self, haruhi, mikuru, yuki):
                #ok (haruhi) == "Haruhi"
                #ok (mikuru) == "Mikuru"
                #ok (yuki)   == "Yuki"
                pass

    class ProviderHasNoSelf(unittest.TestCase):

        def provide_haruhi(): return "Haruhi"
        def provide_mikuru(): return "Mikuru"
        def provide_yuki():   return "Yuki"

        for i in xrange(10):
            @test("example")
            def _(self, haruhi, mikuru, yuki):
                #ok (haruhi) == "Haruhi"
                #ok (mikuru) == "Mikuru"
                #ok (yuki)   == "Yuki"
                pass

    for bm in Benchmarker(width=25, loop=10000, cycle=3):
        ## oktest
        for _ in bm("provide_xxx(self)"):
            unittest_run(ProviderHasSelf)
        ## unittest
        for _ in bm("provide_xxx()"):
            unittest_run(ProviderHasNoSelf)


###
entry("how does resolving injection affect to speed?")
def _():

    class DependencyNotExist(unittest.TestCase):

        def provide_a(self): return "A"
        def provide_b(self): return "B"
        def provide_c(self): return "C"
        def provide_d(self): return "D"
        def provide_e(self): return "E"

        for i in xrange(10):
            @test("no dependency between fixtures")
            def _(self, a, b, c, d, e):
                pass

    class ComplexDependencies(unittest.TestCase):

        def provide_a(self, b, c): return "A"
        def provide_b(self, d):    return "B"
        def provide_c(self, e):    return "C"
        def provide_d(self):       return "D"
        def provide_e(self):       return "E"

        for i in xrange(10):
            @test("complex dependencies between fixtures")
            def _(self, a):
                pass

    class ResolveDependencyManually(unittest.TestCase):

        def provide_a(self, b, c): return "A"
        def provide_b(self, d):    return "B"
        def provide_c(self, e):    return "C"
        def provide_d(self):       return "D"
        def provide_e(self):       return "E"

        for i in xrange(10):
            @test("resolve dependencies manually")
            def _(self, d, e):
                #d = self.provide_d()
                b = self.provide_b(d)
                #e = self.provide_e()
                c = self.provide_c(e)
                a = self.provide_a(b, c)
                pass

    for bm in Benchmarker(width=25, loop=1000, cycle=3):
        for _ in bm("dependency not exist"):
            unittest_run(DependencyNotExist)
        for _ in bm("complex dependencies"):
            unittest_run(ComplexDependencies)
        for _ in bm("resolve manually"):
            unittest_run(ResolveDependencyManually)


###
@entry("how does number of injection affect to speed?")
def _():

    defstr = r"""
def provide_a(self): return "A"
def provide_b(self): return "B"
def provide_c(self): return "C"
def provide_d(self): return "D"
def provide_e(self): return "E"
"""[1:]

    class ZeroInjection(unittest.TestCase):
        exec(defstr)
        for i in xrange(10):
            @test("zero injection")
            def _(self):
                a = self.provide_a()
                b = self.provide_b()
                c = self.provide_c()
                d = self.provide_d()
                e = self.provide_e()

    class OneInjection(unittest.TestCase):
        exec(defstr)
        for i in xrange(10):
            @test("one injection")
            def _(self, a):
                #a = self.provide_a()
                b = self.provide_b()
                c = self.provide_c()
                d = self.provide_d()
                e = self.provide_e()

    class TwoInjection(unittest.TestCase):
        exec(defstr)
        for i in xrange(10):
            @test("two injections")
            def _(self, a, b):
                #a = self.provide_a()
                #b = self.provide_b()
                c = self.provide_c()
                d = self.provide_d()
                e = self.provide_e()

    class ThreeInjection(unittest.TestCase):
        exec(defstr)
        for i in xrange(10):
            @test("three injections")
            def _(self, a, b, c):
                #a = self.provide_a()
                #b = self.provide_b()
                #c = self.provide_c()
                d = self.provide_d()
                e = self.provide_e()

    class FourInjection(unittest.TestCase):
        exec(defstr)
        for i in xrange(10):
            @test("four injections")
            def _(self, a, b, c, d):
                #a = self.provide_a()
                #b = self.provide_b()
                #c = self.provide_c()
                #d = self.provide_d()
                e = self.provide_e()

    class FiveInjection(unittest.TestCase):
        exec(defstr)
        for i in xrange(10):
            @test("five injections")
            def _(self, a, b, c, d, e):
                #a = self.provide_a()
                #b = self.provide_b()
                #c = self.provide_c()
                #d = self.provide_d()
                #e = self.provide_e()
                pass

    for bm in Benchmarker(width=25, loop=1000, cycle=3):
        for _ in bm("zero injection"):
            unittest_run(ZeroInjection)
        for _ in bm("one injection"):
            unittest_run(OneInjection)
        for _ in bm("two injections"):
            unittest_run(TwoInjection)
        for _ in bm("thee injections"):
            unittest_run(ThreeInjection)
        for _ in bm("four injections"):
            unittest_run(FourInjection)
        for _ in bm("five injections"):
            unittest_run(FiveInjection)



if __name__ == '__main__':
    entry.main_loop()

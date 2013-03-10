# -*- coding: utf-8 -*-
###
### $Release: $
### $Copyright: copyright(c) 2010-2013 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re, types
import unittest
try:
    from cStringIO import StringIO
except ImportError:
    from io import StringIO


python24 = sys.version_info[:2] <= (2,4)

def withstmt_avaialble():
    return not python24

def withstmt_not_available():
    if python24:
        sys.stderr.write("*** skip because with-statment is not supported\n")
        return True
    return False


import oktest
from oktest import ok, test, run
from oktest.context import TestContext  #, subject, situation
from oktest import subject, situation


def inspect_test_contexts(context_list):
    depth = 0
    buf = []
    for context in context_list:
        _inspect_test_context(context, depth, buf)
    return "".join(buf)

def _inspect_test_context(context, depth, buf):
    add = buf.append
    indent = "  " * depth
    add("%s- Context: %r\n" % (indent, context.desc))
    for item in context.items:
        if isinstance(item, tuple):
            add("%s  - %s()\n" % (indent, item[0]))
        elif isinstance(item, TestContext):
            _inspect_test_context(item, depth+1, buf)
        else:
            add("%s  - %r\n" % (item,))


prefix = "from __future__ import with_statement\nif True:\n"


def _exec_code(code):
    lvars = {'unittest': unittest, 'ok': ok, 'test': test,
             'subject': subject, 'situation': situation }
    exec(code, lvars, lvars)
    return lvars


class TestContext_TC(unittest.TestCase):


    def test_subject(self):
        """TextContent.__enter__() and .__exit__() saves context into class."""
        if withstmt_not_available(): return
        input = prefix + r"""
        class _SubjectTest1(unittest.TestCase):
          with subject('#method1'):
            def test_1(self):
              ok (1) == 1
            def test_2(self):
              ok (2) == 2
          with subject('#method2'):
            def test_3(self):
              ok (4) == 3
            def test_4(self):
              ok (4) == 4
"""[1:]
        expected = r"""
- Context: '#method1'
  - test_1()
  - test_2()
- Context: '#method2'
  - test_3()
  - test_4()
"""[1:]
        lvars = _exec_code(input)
        klass = lvars.get('_SubjectTest1')
        ok (klass).has_attr('_context_list')
        ok (klass._context_list).is_a(list).length(2)
        actual = inspect_test_contexts(klass._context_list)
        ok (actual) == expected


    def test_situation(self):
        """TextContent can be nestable"""
        if withstmt_not_available(): return
        input = prefix + r"""
        class _SituationTest1(unittest.TestCase):
          with subject('module hello'):
            with subject('#method1'):
              def test_1(self):
                ok (1) == 1
              with situation('when condtion1:'):
                def test_2(self):
                  ok (2) == 2
                def test_3(self):
                  ok (3) == 3
              with situation('else:'):
                def test_4(self):
                  ok (4) == 4
              def test_5(self):
                ok (5) == 5
            #
          #
          def test_6(self):
            ok (6) == 6
"""[1:]
        expected = r"""
- Context: 'module hello'
  - Context: '#method1'
    - test_1()
    - Context: 'when condtion1:'
      - test_2()
      - test_3()
    - Context: 'else:'
      - test_4()
    - test_5()
"""[1:]
        lvars = _exec_code(input)
        klass = lvars.get('_SituationTest1')
        actual = inspect_test_contexts(klass._context_list)
        ok (actual) == expected


    def test_with_test_decorator(self):
        """TextContent can be nestable"""
        if withstmt_not_available(): return
        input = prefix + r"""
        class _WithTestDecoratorTest1(unittest.TestCase):
          with subject('module hello'):
            with subject('#method1'):
              @test('spec1')
              def _(self):
                ok (1) == 1
              with situation('when condition1:'):
                @test('spec2')
                def _(self):
                  ok (2) == 2
                @test('spec3')
                def _(self):
                  ok (3) == 3
"""[1:]
        expected = r"""
- Context: 'module hello'
  - Context: '#method1'
    - test_001: spec1()
    - Context: 'when condition1:'
      - test_002: spec2()
      - test_003: spec3()
"""[1:]
        lvars = _exec_code(input)
        klass = lvars.get('_WithTestDecoratorTest1')
        actual = inspect_test_contexts(klass._context_list)
        ok (actual) == expected


    class _ContextTagTest(unittest.TestCase):
        x1 = subject('#foobar()', tag1='aaa', tag2='bbb')
        x1.__enter__()
        #
        def test1(self):
            pass
        #
        @test("test2")
        def _(self):
            pass
        #
        @test("test3", tag1='ccc', tag3='ddd')
        def _(self):
            pass
        #
        x1.__exit__()
        #
        @test("test4")
        def _(self):
            pass
        ####
        x2 = situation('case when blablabla', tag1='eee', tag2='fff')
        x2.__enter__()
        #
        def test6(self):
            pass
        #
        @test("test7")
        def _(self):
            pass
        #
        @test("test8", tag1='ggg', tag3='hhh')
        def _(self):
            pass
        #
        x2.__exit__()
        #
        @test("test9")
        def _(self):
            pass

    def test_with_tags(self):
        testclass = self._ContextTagTest
        for k in dir(testclass):
            if   re.match(r'.*test1', k):  test1 = getattr(testclass, k)
            elif re.match(r'.*test2', k):  test2 = getattr(testclass, k)
            elif re.match(r'.*test3', k):  test3 = getattr(testclass, k)
            elif re.match(r'.*test4', k):  test4 = getattr(testclass, k)
            elif re.match(r'.*test6', k):  test6 = getattr(testclass, k)
            elif re.match(r'.*test7', k):  test7 = getattr(testclass, k)
            elif re.match(r'.*test8', k):  test8 = getattr(testclass, k)
            elif re.match(r'.*test9', k):  test9 = getattr(testclass, k)
        #
        self.assertEqual(test1._tags, {'tag1': 'aaa', 'tag2': 'bbb'})
        self.assertEqual(test2._tags, {'tag1': 'aaa', 'tag2': 'bbb'})
        self.assertEqual(test3._tags, {'tag1': 'ccc', 'tag2': 'bbb', 'tag3': 'ddd'})
        self.assertEqual(test4._tags, {})
        #
        self.assertEqual(test6._tags, {'tag1': 'eee', 'tag2': 'fff'})
        self.assertEqual(test7._tags, {'tag1': 'eee', 'tag2': 'fff'})
        self.assertEqual(test8._tags, {'tag1': 'ggg', 'tag2': 'fff', 'tag3': 'hhh'})
        self.assertEqual(test9._tags, {})


    class _NestedContextTagTest(unittest.TestCase):
        x1 = subject('parent context', tag1='aaa', tag2='bbb')
        if x1.__enter__():
            #
            x2 = situation('parent context', tag1='ccc', tag3='ddd')
            if x2.__enter__():
                #
                @test('test1')
                def _(self):
                    pass
                #
                x3 = situation('child context', tag1='eee', tag4='fff')
                if x3.__enter__():
                    #
                    @test('test2')
                    def _(self):
                        pass
                    #
                    x3.__exit__()
                #
                x2.__exit__()
            #
            x1.__exit__()

    def test_nested_context_tags(self):
        testclass = self._NestedContextTagTest
        for k in dir(testclass):
            if   re.match(r'^test_.*test1', k):  test1 = getattr(testclass, k)
            elif re.match(r'^test_.*test2', k):  test2 = getattr(testclass, k)
        self.assertEqual(test1._tags, {'tag1': 'ccc', 'tag2': 'bbb', 'tag3': 'ddd'})
        self.assertEqual(test2._tags, {'tag1': 'eee', 'tag2': 'bbb', 'tag3': 'ddd', 'tag4': 'fff'})



if __name__ == '__main__':
    unittest.main()

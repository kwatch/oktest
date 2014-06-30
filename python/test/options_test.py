# -*- coding: utf-8 -*-

import unittest
from oktest import ok, test, options_of


class OptionsOf_Test(unittest.TestCase):

    def setUp(self):
        self.curr_options = options_of(self)

    @test("options_of() returns tags of current test case.", tag1="var1", tag2=123)
    def _(self):
        expected = {'tag1': "var1", 'tag2': 123}
        self.assertEqual(expected, options_of(self))
        self.assertEqual(expected, self.curr_options)


if __name__ == '__main__':
    unittest.main()

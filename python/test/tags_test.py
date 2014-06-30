# -*- coding: utf-8 -*-

import unittest
from oktest import ok, test, tags_of


class TagsOf_Test(unittest.TestCase):

    def setUp(self):
        self.curr_tags = tags_of(self)

    @test("tags_of() returns tags of current test case.", tag1="var1", tag2=123)
    def _(self):
        expected = {'tag1': "var1", 'tag2': 123}
        self.assertEqual(expected, tags_of(self))
        self.assertEqual(expected, self.curr_tags)


if __name__ == '__main__':
    unittest.main()

###
### $Release: 0.8.0 $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, re, os
arg1 = len(sys.argv) > 1 and sys.argv[1] or None
if arg1 == 'egg_info':
    from ez_setup import use_setuptools
    use_setuptools()
if arg1 == 'bdist_egg':
    from setuptools import setup
else:
    from distutils.core import setup


def fn():
    name       = 'Oktest'    ## $Package: Oktest $
    version    = '0.8.0'     ## $Release: 0.8.0 $
    author     = 'makoto kuwata'
    email      = 'kwa@kuwata-lab.com'
    maintainer = author
    maintainer_email = email
    url        = 'http://pypi.python.org/pypi'
    desc       = 'a new-style testing library'
    detail     = r"""
Oktest is a new-style testing library for Python. ::

    from oktest import test, ok, NG

    class FooTest(unittest.TestCase):

       @test("1 + 1 should be 2")
       def _(self):
          ok (1+1) == 2          # same as assertEqual(2, 1+1)

       @test("other examples")
       def _(self):
          ok (s) == 'foo'        # same as assertEqual(s, 'foo')
          ok (s) != 'foo'        # same as assertNotEqual(s, 'foo')
          ok (n) > 0             # same as assert_(n > 0)
          ok (fn).raises(Error)  # same as assertRaises(Error, fn)
          ok ([]).is_a(list)     # same as assert_(isinstance([], list))
          NG ([]).is_a(tuple)    # same as assert_(not isinstance([], tuple))
          ok ('A.txt').is_file() # same as assert_(os.path.isfile('A.txt'))
          NG ('A.txt').is_dir()  # same as assert_(not os.path.isdir('A.txt'))

Features:

* ``ok()`` is provided which is much shorter than ``self.assertXxxx()``.
* Allow to write test name in free text.
* Fixture injection support.
* Tracer class is provided which can be used as mock or stub.
* Text diff (diff -u) is displayed when texts are different.

Oktest requires Python 2.4 or later (3.x is supported).

See README_ for details.

.. _README: http://packages.python.org/Oktest
"""[1:]
    license    = 'MIT License'     ## $License: MIT License $
    platforms  = 'any'
    #download  = 'http://downloads.sourceforge.net/oktest/Oktest-%s.tar.gz' % version
    download   = 'http://pypi.python.org/packages/source/O/Oktest/Oktest-%s.tar.gz' % version
    classifiers = [
        'Development Status :: 4 - Beta',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        #'Programming Language :: Python :: 2.3',
        'Programming Language :: Python :: 2.4',
        'Programming Language :: Python :: 2.5',
        'Programming Language :: Python :: 2.6',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.0',
        'Programming Language :: Python :: 3.1',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'Topic :: Software Development :: Testing'
    ]

    py_modules   = ['oktest']
    package_dir  = {'': 'lib'}
    #scripts     = ['bin/pytenjin']
    #packages    = ['tenjin']
    zip_safe     = False

    return locals()


setup(**fn())

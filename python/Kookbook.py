# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

##
## cookbook for pykook -- you must install pykook at first.
## pykook is a build tool like Rake. you can define your task in Python.
## http://pypi.python.org/pypi/Kook/
## http://www.kuwata-lab.com/kook/pykook-users-guide.html
##

from __future__ import with_statement

import sys, os, re
from glob import glob
from kook.utils import read_file, write_file

release   = prop('release', '0.8.0')
package   = prop('package', 'Oktest')
copyright = prop('copyright', "copyright(c) 2010-2011 kuwata-lab.com all rights reserved")
license   = "MIT License"
kook_default_product = 'test'

python = prop('python', 'python')


python_binaries = [
    ('2.4', '/opt/local/bin/python2.4'),
    ('2.5', '/opt/local/bin/python2.5'),
    ('2.6', '/opt/local/bin/python2.6'),
    #('2.7', '/opt/local/bin/python2.7'),
    ('2.7', '/usr/local/python/2.7.1/bin/python'),
    ('3.0', '/usr/local/python/3.0.1/bin/python'),
    ('3.1', '/usr/local/python/3.1/bin/python'),
    ('3.2', '/usr/local/python/3.2rc1/bin/python'),
]


def _with_backup(filepath):
    def deco(func):
        def new_func(*args, **kwargs):
            try:
                bkup = filepath + '.bkup'
                mv(filepath, bkup)
                cp(bkup, filepath)
                return func(*args, **kwargs)
            finally:
                mv(bkup, filepath)
        return new_func
    return deco


TEST_NAMES = ('oktest', 'helpers', 'tracer', 'doc')


@recipe
@ingreds('test/doc_test.py')
@spices("-a: do with python from 2.4 to 3.2", "[testnames...]")
def task_test(c, *args, **kwargs):
    """test 'doctest', 'helpers', 'tracer', or 'doc'"""
    flag_all = bool(kwargs.get('a'))
    if flag_all:
        pairs = python_binaries
    else:
        ver = '%s.%s' % (sys.version_info[0:2])
        bin = 'python' # or sys.executable
        pairs = [ (ver, bin) ]
    test_names = args or TEST_NAMES
    gvars = globals()
    funcs = []
    for tname in test_names:
        func = gvars.get("_run_%s_test" % tname)
        if not func:
            raise ValueError("%r: unknown test name." % tname)
        funcs.append(func)
    for ver, bin in pairs:
        if flag_all:
            print("# ============================================================")
            print("# python " + ver)
            print("# ============================================================")
        for func in funcs:
            func(c, ver, bin)


def _run_oktest_test(c, ver, bin):
    """invoke 'test/oktest_test.py'"""
    fpath = "test/oktest_test.py"
    cmd = c%("PYTHON=$(bin) $(bin) " + fpath)
    if ver == '2.4':
        @_with_backup(fpath)
        def f():
            line = 'from __future__ import with_statement'
            s = read_file(fpath).replace(line, '#' + line)
            write_file(fpath, s)
            system(cmd)
        f()
    else:
        system(cmd)


def _run_helpers_test(c, ver, bin):
    """invoke 'test/helpers_test.py'"""
    fpath = 'test/helpers_test.py'
    _invoke_test(c, ver, bin, fpath)


def _run_tracer_test(c, ver, bin):
    """invoke 'test/tracer_test.py'"""
    fpath = 'test/tracer_test.py'
    _invoke_test(c, ver, bin, fpath)


def _invoke_test(c, ver, bin, fpath):
    def replacer_for_py24(s):
        s = re.sub(r'(from __future__ import .*)', r'#\1', s)
        s = re.sub(r'with spec\(', r'if spec(', s)
        rexp = re.compile(r'^([ \t]*#\+\n)(.*?)^([ \t]*#\-\n)', re.M | re.S)
        def modify(m):
            commented = re.compile(r'^', re.M).sub(r'#', m.group(2))
            return '#' + m.group(1) + commented + m.group(3)
        s = rexp.sub(modify, s)
        return s
    cmd = c%"$(bin) $(fpath)"
    if ver == '2.4':
        @_with_backup(fpath)
        def f():
            edit(fpath, by=replacer_for_py24)
            system(cmd)
        f()
    else:
        system(cmd)


def _run_doc_test(c, ver, bin):
    """invoke 'test/doc_test.py'"""
    fpath = "test/doc_test.py"
    system(c%"$(bin) $(fpath)")


@recipe
@product('test/doc_test.py')
@ingreds('README.txt')
def file_doc_test_py(c):
    cont = open(c.ingred).read()
    pat = r'\n(Tracer\n=+\n.*?)\nHelpers Reference'
    m = re.compile(pat, re.S).search(cont)
    s = m.group(1)
    s = re.compile(r'^(\S)', re.M).sub(r'#\1', s)
    #
    f = open(c.product, 'w')
    f.write(
        "import re\n"
        "from oktest import ok\n"
        "\n"
        "if True:\n"
        "\n"
    )
    f.write(s)
    f.close()


def replacer(s):
    #s = re.sub(r'\$Package\$',   package,   s)
    #s = re.sub(r'\$Release\$',   release,   s)
    #s = re.sub(r'\$Copyright\$', copyright, s)
    #s = re.sub(r'\$License\$',   license,   s)
    s = re.sub(r'\$Package:[^%]*?\$',    '$Package: %s $'   % package,   s)
    s = re.sub(r'\$Release:[^%]*?\$',    '$Release: %s $'   % release,   s)
    s = re.sub(r'\$Copyright:[^%]*?\$',  '$Copyright: %s $' % copyright, s)
    s = re.sub(r'\$License:[^%]*?\$',    '$License: %s $'   % license,   s)
    s = re.sub(r'%s-\d+\.\d+\.\d+' % package, '%s-%s' % (package, release), s)
    return s


@recipe
def task_edit(c):
    """update $Release$, $Copyrigh$, and $License$ in files"""
    filenames = read_file('MANIFEST').splitlines()
    filenames.remove('Kookbook.py')
    filenames.append('website/index.html')
    edit(filenames, by=replacer)
    #
    def repl(s):
        pat = r"^([ \t]*\w+\s*=\s*)'.*?'(\s*##\s*\$(?:Package|Release|License): (.*?) \$)"
        return re.compile(pat, re.M).sub(r"\1'\3'\2", s)
    edit('setup.py', by=repl)


@recipe
@ingreds('sdist', 'eggs')
def task_package(c):
    """create package"""
    pass


@recipe
@ingreds('edit')
def task_sdist(c, *args, **kwargs):
    """create dist/Oktest-X.X.X.tar.gz"""
    #rm_rf(c%"dist/$(package)-$(release)*")
    system(c%'$(python) setup.py sdist --force-manifest')   # or setup.py sdist --keep-temp
    #with chdir('dist') as d:
    #    targz = c%"$(package)-$(release).tar.gz"
    #    #tar_xzf(targz)
    #    system(c%"tar xzf $(targz)")
    #    dir = targz.replace('.tar.gz', '')
    #    edit(c%"$(dir)/**/*", by=replacer)
    #    mv(targz, c%"$(targz).old")
    #    #tar_czf(c%"$(dir).tar.gz", dir)
    #    system(c%"tar -cf $(dir).tar $(dir)")
    #    system(c%"gzip -f9 $(dir).tar")


def _do_setup_py(c, command):
    for ver, bin in python_binaries:
        system(c%command)
        rm_rf(c%'lib/$(package).egg-info')


@recipe
@ingreds('edit')
def task_eggs(c):
    """create dist/*.egg files"""
    _do_setup_py(c, "$(bin) setup.py bdist_egg")


@recipe
@ingreds('edit')
def task_register(c):
    """register information into PyPI"""
    system(c%"$(python) setup.py register")


@recipe
@ingreds('edit')
def task_upload(c):
    """upload packages"""
    system(c%"$(python) setup.py sdist upload")
    _do_setup_py(c, "$(bin) setup.py bdist_egg upload")


@recipe
def task_clean(c):
    rm_rf('**/*.pyc', 'dist', 'build', 'lib/*.egg-info', c%'$(package).zip')


@recipe
@product('website/index.html')
@ingreds('README.txt')
def file_website_index_html(c):
    "create 'website/index.html' from 'README.txt'"
    #opts = '--stylesheet-path=website/style.css --link-stylesheet'
    #with chdir('website'):
    #    system(c%'rst2html.py $(opts) ../README.txt > index.html')
    opts = '--stylesheet-path=style.css --link-stylesheet --strip-class=field --strip-class=field-name --strip-class=field-body'
    system(c%'rst2html.py $(opts) $(ingred) > $(product)')
    def f(s):
        s = s.replace('README', 'Oktest - a new style testing library -')
        s = s.replace('See CHANGES.txt', 'See <a href="CHANGES.txt">CHANGES.txt</a>')
        #s = re.sub(r'^<h(\d)>(.*?)</h\d>', r, s)
        pat = re.compile(r'^<h(\d)>(.*?)</h\d>', re.M)
        def r(m):
            n = int(m.group(1)) + 1
            s = m.group(2)
            return '\n<h%s>%s</h%s>' % (n, s, n)
        s = re.sub(pat, r, s)
        return s
    edit(c.product, by=f)

@recipe
@product('website/CHANGES.txt')
@ingreds('CHANGES.txt')
def file_CHANGES_txt(c):
    cp(c.ingred, c.product)

@recipe
@product('Oktest.zip')
@ingreds('website/index.html', 'website/CHANGES.txt')
def file_Oktest_zip(c):
    """create Oktest.zip"""
    with chdir("website"):
        system("zip -r ../Oktest.zip index.html style.css CHANGES.txt")

@recipe
@ingreds('Oktest.zip')
def task_website(c):
    pass

# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010-2014 kuwata-lab.com all rights reserved $
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

package   = prop('package', 'Oktest')
release   = prop('release', '0.13.0')
copyright = prop('copyright', "copyright(c) 2010-2014 kuwata-lab.com all rights reserved")
license   = "MIT License"
python    = prop('python', sys.executable)
basename  = "%s-%s" % (package, release)

kookbook.default = 'test'


###
### test
###

python_binaries = [
    ('2.4', '/opt/local/bin/python2.4'),
    #('2.5', '/opt/local/bin/python2.5'),
    #('2.6', '/opt/local/bin/python2.6'),
    #('2.7', '/opt/local/bin/python2.7'),
    ('2.5', '/opt/lang/python/2.5.5/bin/python'),
    ('2.6', '/opt/lang/python/2.6.7/bin/python'),
    ('2.7', '/opt/lang/python/2.7.2/bin/python'),
    ('3.0', '/opt/lang/python/3.0.1/bin/python'),
    ('3.1', '/opt/lang/python/3.1.4/bin/python'),
    ('3.2', '/opt/lang/python/3.2.0/bin/python'),
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
                cp(filepath, '/tmp/' + filepath)
                mv(bkup, filepath)
        return new_func
    return deco


TEST_NAMES = ('tracer', 'spec', 'testdeco', 'fixture',
              'doc', 'assertions', 'dummy', 'runner', 'context', 'reporter',
              'util', 'skip', 'todo', 'resp', 'mainapp', 'web',)
test_names = [ os.path.basename(x).replace('_test.py', '')
                   for x in glob("test/*_test.py") ]
assert set(TEST_NAMES) == set(test_names)


@recipe
@spices("-a: do with python from 2.4 to 3.2", "[testnames...]")
def task_test(c, *args, **kwargs):
    """do test by oktest"""
    #optstr = " -m oktest"
    optstr = " -m oktest -sp test"
    if kwargs.get('a'):
        for ver, execpath in python_binaries:
            system_f(execpath + optstr)
    else:
        system(sys.executable + optstr)


@recipe
@ingreds('test/doc_test.py')
@spices("-a: do with python from 2.4 to 3.2", "[testnames...]")
def task_unittest(c, *args, **kwargs):
    """do test by unittest module"""
    flag_all = bool(kwargs.get('a'))
    if flag_all:
        pairs = python_binaries
    else:
        ver = '%s.%s' % (sys.version_info[0:2])
        pairs = [ (ver, python) ]
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

for tname in TEST_NAMES:
    exec(r'''
def _run_%s_test(c, ver, bin):
    fpath = 'test/%s_test.py'
    #_invoke_test(c, ver, bin, fpath)
    system(bin + ' ' + fpath)
''' % (tname, tname))

def _run_oktest_test(c, ver, bin):
    """invoke 'test/oktest_test.py'"""
    fpath = "test/oktest_test.py"
    cmd = c%("PYTHON=$(bin) $(bin) " + fpath)
    #if ver == '2.4':
    #    @_with_backup(fpath)
    #    def f():
    #        line = 'from __future__ import with_statement'
    #        s = read_file(fpath).replace(line, '#' + line)
    #        write_file(fpath, s)
    #        system(cmd)
    #    f()
    #else:
    #    system(cmd)
    system_f(cmd)

#def _invoke_test(c, ver, bin, fpath):
#    def replacer_for_py24(s):
#        s = re.sub(r'(from __future__ import .*)', r'#\1', s)
#        s = re.sub(r'with spec\(', r'if spec(', s)
#        rexp = re.compile(r'^([ \t]*#\+\n)(.*?)^([ \t]*#\-\n)', re.M | re.S)
#        def modify(m):
#            commented = re.compile(r'^', re.M).sub(r'#', m.group(2))
#            return '#' + m.group(1) + commented + m.group(3)
#        s = rexp.sub(modify, s)
#        return s
#    cmd = c%"$(bin) $(fpath)"
#    if ver == '2.4':
#        @_with_backup(fpath)
#        def f():
#            edit(fpath, by=replacer_for_py24)
#            system(cmd)
#        f()
#    else:
#        system(cmd)
#
#def _run_doc_test(c, ver, bin):
#    """invoke 'test/doc_test.py'"""
#    fpath = "test/doc_test.py"
#    system(c%"$(bin) $(fpath)")



@recipe
@product('test/doc_test.py')
@ingreds('README.txt')
def file_doc_test_py(c):
    cont = open(c.ingred).read()
    pat = r'\n(Tracer\n=+\n.*?)\nHelpers Reference'
    m = re.compile(pat, re.S).search(cont)
    s = m.group(1)
    #
    rexp = re.compile(r'^(    )', re.M)
    def fn(m, rexp=rexp):
        console = m.group(1)
        return "\n\n" + rexp.sub(r'\1#|', console) + "\n"
    s = re.compile(r'\n\n(    \$ .*?\n)\n', re.M|re.S).sub(fn, s)
    #
    s = re.compile(r'^(\S)', re.M).sub(r'#\1', s)
    s = re.compile(r'^( *)(\$ python)', re.M).sub(r'\1#\2', s)
    s = re.compile(r'^([ \t]*)(\.\.\.)', re.M).sub(r'\1ok (0) == 1 #...', s)
    s = re.compile(r'def _\(self\): \.\.\.').sub('def _(self): pass', s)
    s = re.sub(r'\{\{\*(.*?)\*\}\}', r'\1', s)
    #
    f = open(c.product, 'w')
    f.write(
        "import re\n"
        "from oktest import ok\n"
        "import unittest\n"
        "def skipIf(condition, reason):\n"
        "    def deco(func):\n"
        "        if not condition:\n"
        "            return func\n"
        "        def func2(*args, **kwargs):\n"
        "            return reason\n"
        "        return func2\n"
        "    return deco\n"
        "\n"
        "try:\n"
        "    _skipIf_bkup = getattr(unittest, 'skipIf', None)\n"
        "    unittest.skipIf = skipIf\n"
        "    del skipIf\n"
        "#--------------------------------------------------\n"
    )
    f.write(s)
    f.write(
        "#--------------------------------------------------\n"
        "finally:\n"
        "    if _skipIf_bkup:\n"
        "        unittest.skipIf = _skipIf_bkup\n"
    )
    f.close()


def _with_README_backup(fn):
    fname = "README.txt"
    try:
        f = open(fname); s = f.read(); f.close()
        os.rename(fname, fname + ".bkup")
        s = s.replace("{{*", "").replace("*}}", "")
        f = open(fname, 'w'); f.write(s); f.close()
        fn()
    finally:
        os.rename(fname + ".bkup", fname)


###
### package, dist
###

text_files = ['README.txt', 'CHANGES.txt', 'MIT-LICENSE', 'Kookbook.py', 'MANIFEST', 'MANIFEST.in', 'setup.py']

class pkg(Category):

    @recipe
    @ingreds('pkg:dist')
    def default(c):
        """create packages"""
        ## setup
        dir = c%"dist/$(basename)"
        @pushd(dir)
        def do():
            #system(c%'$(python) setup.py sdist')
            system(c%'$(python) setup.py sdist --force-manifest')
            system(c%'$(python) setup.py bdist_egg')
        cp(c%'$(dir)/MANIFEST', '.')


    @recipe
    def dist(c, *args, **kwargs):
        """create Oktest-X.X.X/ directory"""
        ## create dir
        dir = c%"dist/$(basename)"
        if os.path.isdir(dir):
            rm_rf(dir)
        mkdir(dir)
        ## copy files
        files = [ f for f in text_files if os.path.exists(f) ]
        store(files, dir)
        store('lib/**/*.py', 'test/*.py', dir)
        ## edit files
        replacer = [
            (r'\$(Package)\$',   package),
            (r'\$(Release)\$',   release),
            (r'\$(Copyright)\$', copyright),
            (r'\$(License)\$',   license),
            (r'\$(Package):.*?\$',    r'$\1: %s $' % package),
            (r'\$(Release):.*?\$',    r'$\1: %s $' % release),
            (r'\$(Copyright):.*?\$',  r'$\1: %s $' % copyright),
            (r'\$(License):.*?\$',    r'$\1: %s $' % license),
        ]
        edit(c%"$(dir)/**/*", exclude=[c%'$(dir)/Kookbook.py'], by=replacer)
        replacer2 = [
            (r'\{\{\*(.*?)\*\}\}', r'\1'),
            (r'0\.0\.0', release),
        ]
        edit(c%"$(dir)/README.txt", by=replacer2)
        ## MANIFEST
        #@pushd(dir)
        #def do():
        #    rm_f('MANIFEST')
        #    system(c%'$(python) setup.py sdist --force-manifest')

    @recipe
    def upload(c, *args, **kwargs):
        """upload new version to pypi"""
        dir = c%"dist/$(basename)"
        with chdir(dir):
            system(c%"python setup.py register")
            system(c%"python setup.py sdist upload")


kookbook.load('@kook/books/clean.py')
CLEAN.extend(('**/*.pyc', '**/__pycache__', 'lib/*.egg-info', '%s.zip' % package))


@recipe
def task_manifest(c):
    """update MANIFEST file"""
    system(c%'$(python) setup.py sdist --force-manifest')


replacer = [
    #(r'\$'r'Package\$',   package),
    #(r'\$'r'Release\$',   release),
    #(r'\$'r'Copyright\$', copyright),
    #(r'\$'r'License\$',   license),
    (r'\$'r'Package:[^%]*?\$',    '$''Package: %s $'   % package),
    (r'\$'r'Release:[^%]*?\$',    '$''Release: %s $'   % release),
    (r'\$'r'Copyright:[^%]*?\$',  '$''Copyright: %s $' % copyright),
    (r'\$'r'License:[^%]*?\$',    '$''License: %s $'   % license),
    (r'%s-\d+\.\d+\.\d+' % package, '%s-%s' % (package, release)),
]


@recipe
@spices("--copyright: update only $""Copyright$",
        "--license:   update only $""License$",
        "[filenames]")
def task_edit(c, *args, **kwargs):
    """update $Release$, $Copyrigh$, and $License$ in files"""
    if args:
        filenames = args
    else:
        with open('MANIFEST') as f:
            filenames = [ line.strip() for line in f if not line.startswith('#') ]
        #filenames.remove('Kookbook.py')
        filenames.append('website/index.html')
    if 'copyright' in kwargs:
        replacer_ = [ t for t in replacer if t[0].find('Copyright') >= 0 ]
        patternstr = 'Copyright'
    elif 'license' in kwargs:
        replacer_ = [ t for t in replacer if t[0].find('License') >= 0 ]
        patternstr = 'License'
    else:
        replacer_ = replacer[:]
        patternstr = 'Package|Release|Copyright|License'
    edit(filenames, by=replacer_)
    #
    def repl(s):
        pat = r"^([ \t]*\w+\s*=\s*)'.*?'(\s*##\s*\$(?:"+patternstr+r"): (.*?) \$)"
        return re.compile(pat, re.M).sub(r"\1'\3'\2", s)
    if 'setup.py' in filenames:
        edit('setup.py', by=repl)



###
### website
###

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
        s = s.replace('0.0.0', release)
        s = s.replace('$''Release$', release)
        s = re.sub('<\?xml version=".*" encoding=".*" *\?>\n', '', s)
        s = s.replace('Oktest README', 'Oktest - a new style testing library -')
        s = s.replace('See CHANGES.txt', 'See <a href="CHANGES.txt">CHANGES.txt</a>')
        s = s.replace('{{*', '<strong>')
        s = s.replace('*}}', '</strong>')
        s = re.sub(r'<span class="strike">(.*?)</span>', r'<del>\1</del>', s)
        #s = re.sub(r'^<h(\d)>(.*?)</h\d>', r, s)
        pat = re.compile(r'^<h(\d)>(.*?)</h\d>', re.M)
        def r(m):
            n = int(m.group(1)) + 1
            s = m.group(2)
            return '\n<h%s>%s</h%s>' % (n, s, n)
        s = re.sub(pat, r, s)
        return s
    edit(c.product, by=f)
    #
    def f2(s):
        s = re.sub(r'<head>\n',
                   ('<head>\n'
                    '<meta http-equiv="Refresh" content="5;url=http://www.kuwata-lab.com/oktest/oktest-py_users-guide.html" />\n'
                    ),
                   s)
        s = re.sub(r'<div class="document" id="oktest-readme">\n',
                   ('<div class="document" id="oktest-readme">\n'
                    '<div id="attention" style="border:solid 2px red;background:#FEE;font-size:large;padding:10px;margin-bottom:20px;">\n'
                    '  <p><strong style="color:red">ATTENTION</strong></p>\n'
                    '  <p>Oktest homepage is moved to <a href="http://www.kuwata-lab.com/oktest/">http://www.kuwata-lab.com/oktest/</a></p>\n'
                    '</div><!-- /attention -->\n'
                    ),
                   s)
        return s
    #edit(c.product, by=f2)

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

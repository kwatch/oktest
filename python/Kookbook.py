# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

##
## cookbook for pykook -- you must install pykook at first.
## pykook is a build tool like Rake. you can define your task in Python.
## http://pypi.python.org/pypi/Kook/
## http://www.kuwata-lab.com/kook/pykook-users-guide.html
##

from __future__ import with_statement

import os, re
from glob import glob
from kook.utils import read_file, write_file

release   = prop('release', '0.7.0')
package   = prop('package', 'Oktest')
copyright = prop('copyright', "copyright(c) 2010-2011 kuwata-lab.com all rights reserved")
license   = "MIT License"
kook_default_product = 'test'

python = prop('python', 'python')

@recipe
@spices("-a: do with python 2.4, 2.5, 2.6, 2.7, 3.0, 3.1, 3.2rc1")
def task_test(c, *args, **kwargs):
    if kwargs.get('a', None):
        _do_for_all_version(c, "PYTHON=$(bin) $(bin) test/oktest_test.py")
    else:
        system(c%"$(python) test/oktest_test.py")

def _do_for_all_version(c, command):
    versions = [
        ('2.4', '/opt/local/bin/python2.4'),
        ('2.5', '/opt/local/bin/python2.5'),
        ('2.6', '/opt/local/bin/python2.6'),
        #('2.7', '/opt/local/bin/python2.7'),
        ('2.7', '/usr/local/python/2.7.1/bin/python'),
        ('3.0', '/usr/local/python/3.0.1/bin/python'),
        ('3.1', '/usr/local/python/3.1/bin/python'),
        ('3.2', '/usr/local/python/3.2rc1/bin/python'),
    ]
    for ver, bin in versions:
        print("#")
        print("# python " + ver)
        print("#")
        fpath = "test/oktest_test.py"
        try:
            if ver == '2.4':
                mv(fpath, fpath+'.bkup')
                cp(fpath+'.bkup', fpath)
                s = open(fpath+'.bkup').read()
                line = 'from __future__ import with_statement'
                open(fpath, 'w').write(s.replace(line, '#' + line))
            system(c%command)
        finally:
            if ver == '2.4':
                mv(fpath+'.bkup', fpath)

@recipe
@ingreds('test/doc_test.py')
@spices("-a: do with python 2.4, 2.5, 2.6, 2.7, 3.0, 3.1, 3.2rc1")
def task_doc_test(c, *args, **kwargs):
    """invoke 'test/doc_test.py'"""
    if kwargs.get('a', None):
        _do_for_all_version(c, '$(python) ' + c.ingred)
    else:
        system(c%'python $(ingred)')

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

@recipe
def task_edit(c):
    """update $Release$, $Copyrigh$, and $License$ in files"""
    def replacer(s):
        s = re.sub(r'\$Package:[^%]*?\$',    '$Package: %s $'   % package,   s)
        s = re.sub(r'\$Release:[^%]*?\$',    '$Release: %s $'   % release,   s)
        s = re.sub(r'\$Copyright:[^%]*?\$',  '$Copyright: %s $' % copyright, s)
        s = re.sub(r'\$License:[^%]*?\$',    '$License: %s $'   % license,   s)
        s = re.sub(r'%s-\d+\.\d+\.\d+' % package, '%s-%s' % (package, release), s)
        return s
    filenames = read_file('MANIFEST').splitlines()
    filenames.remove('Kookbook.py')
    edit(filenames, by=replacer)
    #
    def replacer(s):
        pat = r"^([ \t]*\w+\s*=\s*)'.*?'(\s*##\s*\$(?:Package|Release|License): (.*?) \$)"
        return re.compile(pat, re.M).sub(r"\1'\3'\2", s)
        #s = re.compile(r"^(version\s*=\s*)'.*?'", re.M).sub(r"\1'%s'" % release, s)
        #s = re.compile(r"^(license\s*=\s*)'.*?'", re.M).sub(r"\1'%s'" % license, s)
        #return s
    edit('setup.py', by=replacer)


@recipe
def task_register(c):
    """regsiter information into PyPI"""
    system("python setup.py register")


@recipe
@ingreds('edit')
@spices('-a: create egg files for 2.4-2.7')
def task_package(c, *args, **kwargs):
    """create package"""
    ## remove files
    pattern = c%"dist/$(package)-$(release)*"
    if glob(pattern):
        rm_rf(pattern)
    ## edit files
    repl = (
        (r'\$Release\$',   release),
        (r'\$Copyright\$', copyright),
        (r'\$License\$',   license),
        (r'\$Package\$',   package),
        (r'\$Release:[^%]*?\$',   '$Release: %s $'   % release),
        (r'\$Copyright:[^%]*?\$', '$Copyright: %s $' % copyright),
        (r'\$License:[^%]*?\$',   '$License: %s $'   % license),
        (r'X\.X\.X',   release),
    )
    ## setup
    system(c%'$(python) setup.py sdist')
    #system(c%'$(python) setup.py sdist --keep-temp')
    with chdir('dist') as d:
        #pkgs = kook.util.glob2(c%"$(package)-$(release).tar.gz");
        #pkg = pkgs[0]
        pkg = c%"$(package)-$(release).tar.gz"
        echo(c%"pkg=$(pkg)")
        #tar_xzf(pkg)
        system(c%"tar xzf $(pkg)")
        dir = re.sub(r'\.tar\.gz$', '', pkg)
        #echo("*** debug: pkg=%s, dir=%s" % (pkg, dir))
        edit(c%"$(dir)/**/*", by=repl)
        #with chdir(dir):
        #    system(c%"$(python) setup.py egg_info --egg-base .")
        #    rm("*.pyc")
        mv(pkg, c%"$(pkg).bkup")
        #tar_czf(c%"$(dir).tar.gz", dir)
        system(c%"tar -cf $(dir).tar $(dir)")
        system(c%"gzip -f9 $(dir).tar")
        ## create *.egg file
        opt_a = kwargs.get('a')
        with chdir(dir):
            if opt_a:
                pythons = [
                    '/opt/local/bin/python2.7',
                    '/opt/local/bin/python2.6',
                    '/opt/local/bin/python2.5',
                    '/opt/local/bin/python2.4',
                ]
            else:
                pythons = [ python ]
            for py in pythons:
                system(c%'$(py) setup.py bdist_egg')
                mv("dist/*.egg", "..")
                rm_rf("build", "dist")


@recipe
def task_clean(c):
    rm_rf('**/*.pyc', 'dist', c%'$(package).zip')


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
        s = s.replace('$Release:[^%]*?$', '$Release: %s $' % release)
        s = s.replace('$'+'Release'+'$', release)
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

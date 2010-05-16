# -*- coding: utf-8 -*-

###
### $Release: $
### $Copyright: copyright(c) 2010 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

##
## cookbook for pykook -- you must install pykook at first.
## pykook is a build tool like Rake. you can define your task in Python.
## http://pypi.python.org/pypi/Kook/0.0.1
## http://www.kuwata-lab.com/kook/pykook-users-guide.html
##

from __future__ import with_statement

import os, re
from glob import glob
from kook.utils import read_file, write_file

release   = prop('release', '0.3.0')
package   = prop('package', 'Oktest')
copyright = prop('copyright', "copyright(c) 2010 kuwata-lab.com all rights reserved")
license   = "MIT License"
#kook_default_product = 'test'

python = prop('python', 'python')


@recipe
def task_test(c):
    system(c%"$(python) test/oktest_test.py")


@recipe
def task_edit(c):
    def replacer(s):
        s = re.sub(r'\$Release:.*\$',    '$Release: %s $'   % release,   s)
        s = re.sub(r'\$Copyright:.* \$', '$Copyright: %s $' % copyright, s)
        s = re.sub(r'\$License:.*\$',    '$License: %s $'   % license,   s)
        return s
    filenames = read_file('MANIFEST').splitlines()
    filenames.remove('Kookbook.py')
    filenames.append('README.wiki')
    edit(filenames, by=replacer)


@recipe
@spices('-a: create egg files for 2.4-2.7')
def task_package(c, *args, **kwargs):
    """create package"""
    ## remove files
    pattern = c%"dist/$(package)-$(release)*"
    if glob(pattern):
        rm_rf(pattern)
    ## edit files
    repl = (
        (r'\$Release\$', release),
        (r'\$Release:.*?\$', '$Release: %s $' % release),
        (r'\$Copyright\$', copyright),
        (r'\$Package\$', package),
        (r'\$License\$', license),
    )
    cp('setup.py.txt', 'setup.py')
    edit('setup.py', by=repl)
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
def task_uninstall(c):
    #script_file    = "$python_basepath/bin/" + script_file;
    #library_files  = [ os.path.join(site_packages_path, item) for item in library_files ]
    #compiled_files = [ item + '.c' for item in library_files ]
    script_file = "/usr/local/bin/pytenjin"
    dir = site_packages_dir
    library_files = "$dir/$(package)*"
    rm(script_file, library_files)
    filename = "$dir/easy-install.pth"
    if os.path.exists(filename):
        s = read_file(filename)
        pattern = r'/^\.\/$(package)-.*\n/m'
        if re.match(pattern, s):
            s = re.sub(pattern, s)
        write_file(filename, s)
        repl = ((pattern, ''), )
        edit(filename, by=repl)


@recipe
def task_clean(c):
    pass
    from glob import glob

@recipe
@product('website/index.html')
@ingreds('README.txt')
def file_website_index_html(c):
    #opts = '--stylesheet-path=website/style.css --link-stylesheet'
    #with chdir('website'):
    #    system(c%'rst2html.py $(opts) ../README.txt > index.html')
    opts = '--stylesheet-path=style.css --link-stylesheet --strip-class=field --strip-class=field-name --strip-class=field-body'
    system(c%'rst2html.py $(opts) $(ingred) > $(product)')
    def f(s):
        s = s.replace('$Release: $', '$Release: %s $' % release)
        s = s.replace('$Release$', release)
        s = s.replace('README', 'Oktest - a new style testing library -')
        #s = re.sub(r'^<h(\d)>(.*?)</h\d>', r, s)
        pat = re.compile(r'^<h(\d)>(.*?)</h\d>', re.M)
        def r(m):
            n = int(m.group(1)) + 1
            s = m.group(2)
            return '\n<h%s>%s</h%s>' % (n, s, n)
        s = re.sub(pat, r, s)
        return s
    edit(c.product, by=f)
    with chdir("website"):
        system("zip -r ../Oktest.zip index.html style.css")

@recipe
@ingreds('website/index.html')
def task_website(c):
    pass

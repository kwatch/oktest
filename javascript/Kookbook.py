from __future__ import with_statement

import sys, os, re, glob

package   = 'oktest'
release   = prop('release', '0.2.0')
copyright = 'copyright(c) 2010-2011 kuwata-lab.com all rights reserved'
license   = 'MIT License'

kookbook.default = "test"


node_path = os.environ.get('NODE_PATH')
if not node_path:
    node_path = os.path.dirname(os.path.abspath(__file__))
    os.environ['NODE_PATH'] = os.path.join(node_path, 'lib')


nodejs = "node --strict_mode"


def dist_dir():
    return "dist/oktest-" + release


vs_home = os.getenv('VS_PATH', '').split(':')[0]
nodejs_executables = [
    ('0.4', vs_home + '/node/0.4.11/bin/node'),
    ('0.5', vs_home + '/node/0.5.10/bin/node'),
    ('0.6', vs_home + '/node/0.6.3/bin/node'),
]


class test(Category):

    @recipe
    def default(c):
        """do test"""
        #system(c%"$(nodejs) math_test.js")
        with chdir("test"):
            for fname in glob.glob("*_test.js"):
                system(c%"$(nodejs) $(fname)")

    @recipe
    def all(c):
        """do test on Node.js 0.4, 0.5. and 0.6"""
        with chdir("test"):
            for ver, bin in nodejs_executables:
                print("******************** Node.js %s ********************" % ver)
                for fname in glob.glob("*_test.js"):
                    system(c%"$(bin) $(fname)")


text_files = [
    'README.txt', 'CHANGES.txt', 'MIT-LICENSE', 'Kookbook.py', 'package.json',
]


@recipe
def dist(c):
    """create 'dist-x.x.x' directory and copy files to it"""
    dir = dist_dir()
    rm_rf(dir)
    mkdir_p(dir)
    #
    store(text_files, dir)
    store("lib/*.js", "doc/users-guide.html", "doc/docstyle.css", "test/*_test.js", dir)
    #
    #mkdir(c%"$(dir)/bin")
    #cp("lib/oktest.js", c%"$(dir)/bin/oktest.js")
    #system(c%"chmod 0755 $(dir)/bin/oktest.js")
    #
    replacer = [
        (r'\$Release:.*?\$',   r'$Release: %s $'   % release),
        (r'\$Copyright:.*?\$', r'$Copyright: %s $' % copyright),
        (r'\$License:.*?\$',   r'$License: %s $'   % license),
        (r'\$Release\$',   release),
        (r'\$Copyright\$', copyright),
        (r'\$License\$',   license),
    ]
    edit(c%'$(dir)/**/*', by=replacer)
    cp('Kookbook.py', dir)   # don't edit 'Kookbook.py'


@recipe
@ingreds('dist')
def publish(c):
    """upload package; you must do 'npm adduser' in advance"""
    with chdir(dist_dir()):
        system("npm publish .")


HOME = os.getenv('HOME')


if not os.path.isdir('doc'):
    mkdir('doc')


@recipe
@ingreds('doc/users-guide.html', 'doc/docstyle.css')
def doc(c):
    """create documents under 'doc' directory"""
    pass


@recipe('doc/*.html')
@ingreds('doc/$(1).txt')
def file_doc_html(c):
    base = os.path.basename(c.product).replace('.html', '')
    with chdir('doc'):
        system(c%'kwaser -t html-css -T $(base).txt > $(base).toc.html')
        system(c%'kwaser -t html-css    $(base).txt > $(base).html')
        rm_f(c%'$(base).toc.html')


@recipe('doc/docstyle.css')
@ingreds(HOME + '/src/kwaser/docstyle.css')
def file_doc_docstyle_css(c):
    rm_f(c.product)
    system(c%'ln $(ingred) $(product)')

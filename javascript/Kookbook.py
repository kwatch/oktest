from __future__ import with_statement

import sys, os, re, glob

#release   = prop('release',   '0.0.0')
def read_version_from(filename):
    with open(filename) as f:
        for line in f:
            m = re.search(r'"version":\s*"(.*?)"', line)
            if m:
                release = m.group(1)
                break
        else:
            raise Exception("version is not found in package.json")
    return release
release   = prop('release',   read_version_from("package.json"))
copyright = prop('copyright', 'copyright(c) 2010-2011 kuwata-lab.com all rights reserved')
license   = prop('license',   'MIT License')

kook_default_product = "test"


node_path = os.environ.get('NODE_PATH')
if not node_path:
    node_path = os.path.dirname(os.path.abspath(__file__))
    os.environ['NODE_PATH'] = os.path.join(node_path, 'lib')


nodejs = "node --strict_mode"


dist_dir = 'dist-' + release


@recipe
def test(c):
    """do test"""
    #system(c%"$(nodejs) math_test.js")
    with chdir("test"):
        for fname in glob.glob("*_test.js"):
            system(c%"$(nodejs) $(fname)")


files = [
    'README.rst', 'CHANGES.txt', 'MIT-LICENSE', 'Kookbook.py', 'package.json',
    'lib/oktest.js',
    'doc/users-guide.html', 'doc/docstyle.css',
    'test/*_test.js',
]


@recipe
def dist(c):
    """create 'dist-x.x.x' directory and copy files to it"""
    rm_rf(dist_dir)
    mkdir_p(dist_dir)
    store(files, dist_dir)
    #
    replacer = [
        (r'\$Release:.*?\$',   r'$Release: %s $'   % release),
        (r'\$Copyright:.*?\$', r'$Copyright: %s $' % copyright),
        (r'\$License:.*?\$',   r'$License: %s $'   % license),
        (r'\$Release\$',   release),
        (r'\$Copyright\$', copyright),
        (r'\$License\$',   license),
    ]
    edit(c%'$(dist_dir)/**/*', by=replacer)
    #
    bin_dir = dist_dir + '/bin'
    os.path.isdir(bin_dir) or mkdir_p(bin_dir)
    cp('lib/oktest.js', bin_dir)
    system(c%'chmod 0755 $(bin_dir)/oktest.js')
    #
    from kook.utils import glob2
    with chdir(dist_dir):
        filenames = [ x for x in glob2('**/*')
                            if os.path.isfile(x) ]
    filenames.append("")
    s = "\n".join(filenames)
    with open(".npminclude", 'w') as f:
        f.write(s)


@recipe
@ingreds('dist')
def npm_publish(c):
    """upload package; you must do 'npm adduser' in advance"""
    with chdir(dist_dir):
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

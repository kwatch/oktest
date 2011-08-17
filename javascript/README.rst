================
Oktest.js README
================

$Release: 0.0.1 $



Overview
========

Oktest.js is a new-style testing library for Node.js. ::

    var oktest = require("oktest");
    var topic  = oktest.topic,
        spec   = oktest.spec,
        ok     = oktest.ok;

    topic("target to test", function() {
        spec("specification description", function() {
            ok (1+1).is(2);      // same as assert.ok(1+1 === 2)
            ok (1+1, '===', 2);  // same as assert.ok(1+1 === 2)
            ok (1+1).isNot(1);   // same as assert.ok(1+1 !== 1)
        });
    });

    if (process.argv[1] === __filename) {
        oktest.main();
    }


Features:

* Provides ``ok()`` which is much shorter than ``assert.xxxx()``.
* Allows to write tests in nested structure.
* `Fixture Injection`_ support.
* Text diff (diff -u) is displayed when texts are different.

See doc/users-guide.html for details.



Install
=======

    $ npm install oktest
    $ which oktest.js
    $ oktest.js -h



License
=======

$License: MIT License $



Copyright
=========

$Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $

================
Oktest.js README
================

$Release: 0.1.0 $



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

See CHANGES.txt for changes.



Install
=======

If you have installed npm::

    $ npm install oktest
    $ oktest.js -h

Or just download a file `oktest.js`_ and place it into your current directory
and type::

    $ chmod +x oktest.js
    $ node oktest.js -h


.. _`oktest.js`: https://bitbucket.org/kwatch/oktest/raw/tip/javascript/lib/oktest.js



Example
=======

If you are tring oktest.js for the first time, generate skeleton and try it::

    $ node oktest.js -g > example_test.js
    $ vi example_test.js
    $ node oktest.js example_test.js

The following is an example to demonstrate Oktest.js.
The points are:

* Test code is belong to spec.
* Each spec belongs to topic.
* Topic can be nestable to make tests structured.
* Use ok() or NG() instead of assert.xxxx().

::

    "use strict";
    var oktest = require("oktest");
    var topic  = oktest.topic,
        spec   = oktest.spec,
        ok     = oktest.ok,
        NG     = oktest.NG;

    topic("ClassName", function() {

        topic(".methodName()", function() {

            spec("1+1 should be 2", function() {
                ok (1+1).is(2);      // same as assert.ok(1+1 === 2)
                // or
                ok (1+1, '===', 2);
            });

            spec("other examples", function() {
                ok (null).eq(undefined);         // assert.ok(null == undefined)
                ok (null, '==', undefined);      // assert.ok(null == undefined)
                ok (null).ne(false);             // assert.ok(null != false)
                ok (null, '!=', false);          // assert.ok(null != false)
                ok (null).isNot(undefined);      // assert.ok(null !== undefined)
                ok (null, '!==', undefined);     // assert.ok(null !== undefined)
                ok ([1,2,3]).isa(Array);         // assert.ok([1,2,3] instanceof Array)
                ok (2).inArray([1,2,3]);         // verify whether 2 is in [1,2,3]
                ok ('y').inObject({x:1, y:2});   // assert.ok('y' in {x:1, y:2})
                ok ("foo").isString();           // assert.ok(typeof("foo")==='string')
                ok ([1,2,3]).all().isNumber();   // assert for each item in array
                function fn() { throw new Error("errmsg"); };
                ok (fn).throws_(Error, "errmsg");  // verify whether error is thrown
                ok (fn.exception.message).match(/errmsg/);
            });

        });

    });

    if (process.argv[1] === __filename) {
        oktest.main();  // or  oktest.run();
    }

See `Assertion Reference`_ section for details about ok() and NG().

assert.xxxx() is also available with Oktest.js.
For example you can write assert.equal(1+1, 2) instead of ok (1+1).eq(2).

The following is an output example::

    $ node example_test.js
    * ClassName
      * .methodName()
        - [ok] 1+1 should be 2
        - [ok] other examples
    ## total:2, passed:2, failed:0, error:0, skipped:0  (in 0.003s)

You can change reporting format.

    $ node oktest.js -sv example_test.js    # verbose format (default)
    $ node oktest.js -ss example_test.js    # simple format
    $ node oktest.js -sp example_test.js    # plain format

See `Tips`_ section for details.



Assertion Reference
===================

ok (x).eq(y) or ok (x, '==', y)
	Raises AssertionError unless x == y.

ok (x).ne(y) or ok (x, '!=', y)
	Raises AssertionError unless x != y.

ok (x).is(y) or ok (x, '===', y)
	Raises AssertionError unless x == y.

ok (x).isNot(y) or ok (x, '!==', y)
	Raises AssertionError unless x != y.

ok (x).gt(y) or ok (x, '>', y)
	Raises AssertionError unless x > y.

ok (x).ge(y) or ok (x, '>=', y)
	Raises AssertionError unless x >= y.

ok (x).lt(y) or ok (x, '<', y)
	Raises AssertionError unless x < y.

ok (x).le(y) or ok (x, '<=', y)
	Raises AssertionError unless x <= y.

ok (x).deepEqual(y)
	Same as assert.deepEqual(x, y), but it reports diff when
	x and y are different.

ok (x).inDelta(y, delta)
	Raises AssertionError unless y-delta < x < y+delta.

ok (x).isa(klass)
	Raises AssertionError unless x instanceof klass.

ok (x).match(rexp)
	Raises AssertionError unless x.match(rexp).

ok (x).hasAttr(name[, value])
	Raises AssertionError unless name in x.
	In addition, when value is specified, raises AssertionError unless x.name === value.

ok (x).inObject(obj)
	Raises AssertionError unless x in obj.

ok (x).inArray(arr)
	Raises AssertionError unless x exists in arr.

ok (x).length(n):
	Raise AssertionError unless x.length === n.
	This is same as ``ok (x.length) == n``, but it is useful to chain
	assertions, like ``ok (x).isa(Array).length(n)``.

ok (path).isFile()
	Raise AssertionError unless path is a file.

ok (path).isDirectory()
	Raise AssertionError unless path is a directory.

ok (path).exists()
	Raise AssertionError unless path exist as file or directory.

ok (path).notExist()
	Raise AssertionError unless path doesn't exist as file nor directory.

ok (func).throws_(errorClass[, errorMsg])
	Raise AssertionError unless func() throw errorClass.
	Second argument is a string or regular expression to be matched error message.
	It sets raised exception into 'func.exception' therefore you can do another test with thrown exception object. ::

	    var fs = require('fs');
	    function fn() { fs.statSync('not.exist'); }
	    ok (fn).throws_(Error, /No such file or directory/);
	    ok ({{*fn.exception*}}.code).is('ENOENT')

ok (func).throws(errorClass[, errorMsg])
	Same as throws_().
	Notice that 'throws' is a reserved keyword of JavaScript and
	some tools reports warning if you use 'throws' in your script.

ok (func).notThrow([errorClass=Exception])
	Raise AssertionError if func() raises exception of errorClass.

NG (x)
	Opposite of ok(x). For example, 'NG ("foo").isNumber()' is true. ::

NOT (x)
	Same as NG(x). Provided experimentalily.

precond (x)
	Same as ok(x), but intended to check precondition of test
	instead of assertion. ::

	    precond (filename).notExist();  // pre-condition of test
	    createFileTask(filename);
	    ok (flename).isFile();          // assertion

It is possible to chain assertions. ::

    // chain assertion methods
    ok (arr).isa(Array).length(2);
    ok (obj).hasAttr('name', 'Haruhi').hasAttr('gender', 'F');

Oktest.js allows you to define custom assertion functions.
See `Tips`_ section.



before/after/beforeAll/afterA
=============================

Oktest supports before(), after(), beforeAll() and afterA()
which are correspond to setUp(), tearDown(), setUpAll() and tearDownAll()
respectively::

    "use strict";
    var oktest = require("oktest");
    var topic  = oktest.topic,
        spec   = oktest.spec,
        ok     = oktest.ok,
        NG     = oktest.NG;

    topic("Parent", function() {

        this.beforeAll = function() { console.log("# in Parent.beforeAll()"); };
        this.afterAll  = function() { console.log("# in Parent.afterAll()"); };
        this.before    = function() { console.log("#   in Parent.before()"); };
        this.after     = function() { console.log("#   in Parent.after()"); };

        topic("Child", function() {

            this.beforeAll = function() { console.log("# in Child.beforeAll()"); };
            this.afterAll  = function() { console.log("# in Child.afterAll()"); };
            this.before    = function() { console.log("#   in Child.before()"); };
            this.after     = function() { console.log("#   in Child.after()"); };

            spec("spec1", function() {
                ok (1).is(1);
            });

            spec("spec2", function() {
                ok (2).is(2);
            });

        });

    });

    if (process.argv[1] === __filename) {
        oktest.main();
    }

Result example::

    $ node example_test.js -C
    * Parent
    # in Parent.beforeAll()
      * Child
    # in Child.beforeAll()
    #   in Parent.before()
    #   in Child.before()
    #   in Child.after()
    #   in Parent.after()
        - [ok] spec1
    #   in Parent.before()
    #   in Child.before()
    #   in Child.after()
    #   in Parent.after()
        - [ok] spec2
    # in Child.afterAll()
    # in Parent.afterAll()

Notice that before() and after() are not recommended very much [*]_ in
Oktest.js because they are not flexible.
Use `Fixture Injection`_ instead because it is more flexible than them.

Why before() and after() are not good?
For example if you want change behaviour of before()/after(), you must
change topics. This means that behaviour of before()/after() restricts
to structure of test topics and specs. It's not preferable.

Use `Fixture Injection`_ instead because it doesn't have this weakness.

.. [*] beforeAll() and afterAll() are recommended, because these are
       not covered by Fixture Injection.



Fixture Injection
=================

Oktest.js supports fixture injection.

* Arguments of spec body function are regarded as fixture names
  and they are injected by Oktest.js automatically.
* Functions which name is 'provideXxx()' are regarded as fixture provider
  (or builder) function for fixture 'xxx'.
* Similar to that, functions which name is 'releaseXxx()' are regarded as
  fixture releaser (or destroyer).
  Notice that provider is mandatory but releaser is optional for fixture.
* Providers and releasers should be defined in topics.

::

    "use strict";
    var oktest = require("oktest");
    var topic  = oktest.topic,
        spec   = oktest.spec,
        ok     = oktest.ok,
        NG     = oktest.NG;


    topic("Parent", function() {

        /// define fixture provider and releaser in topics.
        /// (releaser is an optional)
        {{*this.provideLeader*}} = function()    { return "Haruhi"; };
        {{*this.releaseLeader*}} = function(val) { ok (val).is("Haruhi"); };

        topic("Child", function() {

            /// define another fixture provider and releaser in topics.
            {{*this.provideMember*}} = function()    { return "Kyon"; };
            {{*this.releaseMember*}} = function(val) { ok (val).is("Kyon"); };

            /// specify fixture names which you want to use in spec body,
            /// and Oktest injects them automatically.
            spec("Fixture injection example", function({{*leader, member*}}) {
                ok (leader).is("Haruhi");
                ok (member).is("Kyon");
                /// the above two lines are equivarent to:
                //var leader = provideLeader();
                //var member = provideMember();
                //try {
                //  ok (leader).is("Haruhi");
                //  ok (member).is("Kyon");
                //} finally {
                //  if (releaseLeader) releaseLeader(leader);
                //  if (releaseMember) releaseMember(member);
                //}
            });

        });

    });


    if (process.argv[1] === __filename) {
        oktest.main();
    }


This feature is more flexible and useful than setUp() and tearDown().

For example, the following code ensures that dummy files are removed
automatically at the end of test without tearDown(). ::

    topic("Example", function() {

        {{*this.provideCleaner = function() {*}}
            {{*var items = [];*}}
            {{*return items;*}}
        {{*};*}}
        {{*this.releaseCleaner = function(items) {*}}
            {{*for (var i = 0, n = items.length; i < n; i++) {*}}
                {{*oktest.util.rm_rf(items[i]);*}}
            {{*}*}}
        {{*};*}}

        spec("Fixture injection example", function({{*cleaner*}}) {
            /// create dummy files
            var fs = require("fs");
            fs.writeFileSync("foo.txt", "dummy content", "utf8");
            fs.writeFileSync("bar.txt", "dummy content", "utf8");
            ok ("foo.txt").isFile();
            ok ("bar.txt").isFile();
            /// register them to be removed on teardown
            {{*cleaner.push("foo.txt", "bar.txt");*}}
        });

    });

In fact this is very useful, therefore Oktest.js supports cleaner in default. ::

    topic("Example", function() {

        /// No need to define provideCleaner() nor releaseCleaner()
        spec("cleaner fixture is always available", function({{*cleaner*}}) {
            ...
            {{*cleaner.add("foo.txt", "bar.txt");*}}
            ...
        });

    });

Dependencies between fixtures are resolved automatically.
If you know dependency injection framework such as `Spring`_ or `Guice`_,
imagine to apply dependency injection into fixtures. ::

    topic("Fixture Injection", function() {

        ///
        /// for example:
        /// - Fixture 'a' depends on 'b' and 'c'.
        /// - Fixture 'c' depends on 'd'.
        ///
        this.provideA = function({{*b, c*}}) { return b+c+"<A>"; };
        this.provideB = function()     { return "<B>"; };
        this.provideC = function({{*d*}})    { return d+"<C>"; };
        this.provideD = function()     { return "<D>"; };

        ///
        /// Dependencies between fixtures are solved automatically.
        /// If loop exists in dependency then error will be throw.
        ///
        spec("dependency between fixtures is solved", function({{*a*}}) {
            ok (a).is("<B><D><C><A>");
        });

    });

It is possible to pass parameters from specs to provider functions.
This is useful to change providers' behaviour as you need::

    topic("Example", function() {

        /// parameter name should start with '_'
        this.provideUser = function({{*_name*}}) {
            // change behavior according to parameters are passed or not
            {{*if (_name === undefined)*}} {
                {{*_name = "John Smith";*}}
            {{*}*}}
            return {name: _name};
        };

        /// when parameters are specified
        spec("parameters are passed to providers", {{*{_name:"Kyon"}*}}, function(user) {
            ok (user.name).is({{*"Kyon"*}});
        });

        /// when parameters are not specified
        spec("provider uses default values", function(user) {
            ok (user.name).is({{*"John Smith"*}});
        });

    });

If you want to integrate with other fixture library, create manager object
and set it into ``oktest.fixture.manager``. ::

    /// fixture manager class
    function FixtureManger() {
        this.fixtures = {};
    }
    FixtureManger.prototype.{{*provide = function(name) {*}}
        {{*return this.fixtures[name];*}}
    {{*};*}}
    FixtureManger.prototype.{{*release = function(name, value) {*}}
        {{*// do something to release value*}}
    {{*};*}}

    // fixture manager object
    var mgr = new FixtureManager();
    mgr.items["haruhi"] = {name: "Haruhi"};
    mgr.items["mikuru"] = {name: "Mikuru"};
    mgr.items["yuki"]   = {name: "Yuki"};

    // use it
    {{*oktest.fixture.manager =*}} mger;


..    _`Spring`: http://www.springsource.org/
..    _`Guice`:  http://code.google.com/p/google-guice/



Unified Diff
============

ok(x).eq(y) and ok(x).is(y) prints unified diff (diff -u) if x and y are
different text.

For example::

    topic("Unified diff", function() {

        var text1 = "Haruhi\n"
                  + "Mikuru\n"
                  + "Yuki\n"
                  + "Ituski\n"
                  + "Kyon\n";
        var text2 = "Haruhi\n"
                  + "Michiru\n"
                  + "Yuki\n"
                  + "Ituski\n"
                  + "Kyon\n";

        spec("display diff when texts are different", function() {
            ok (text1).is(text2);
        });

    });

If you run this script, you'll find that unified diff is displayed.

Output example::

    $ node example_test.js
    * Unified diff
      - [Failed] display diff when texts are different
    ----------------------------------------------------------------------
    [Failed] Unified diff > display diff when texts are different
    AssertionError: $actual === $expected : failed.
    +++ $actual
    --- $expected
    @@ -1 +1
     Haruhi
    +Mikuru
    -Michiru
     Yuki
     Ituski
     Kyon

        at spec (/home/kwatch/example_test.js:22:20)
            ok (text1).is(text2);
    ----------------------------------------------------------------------
    ## total:1, passed:0, failed:1, error:0, skipped:0  (in 0.006s)

It is good idea to compare complex objects with util.inspect(). ::

    topic("Unified diff", function() {

        var team1 = {
            team: "SOS",
            members: [
                {name: "Haruhi"},
                {name: "Mikuru"},
                {name: "Yuki"},
                {name: "Itsuki"},
                {name: "Kyon"}
            ]
        };
        var team2 = {
            team: "SOS",
            members: [
                {name: "Haruhi"},
                {name: "Michiru"},
                {name: "Yuki"},
                {name: "Itsuki"},
                {name: "Kyon"}
            ]
        };
        spec("display diff when texts are different", function() {
            {{*var util = require("util");*}}
            {{*ok (util.inspect(team1)).eq(util.inspect(team2));*}}
        });

    });

Output example::

    $ node example_test.js
    * Unified diff
      - [Failed] display diff when texts are different
    ----------------------------------------------------------------------
    [Failed] Unified diff > display diff when texts are different
    AssertionError: $actual == $expected : failed.
    +++ $actual
    --- $expected
    @@ -1 +1
     { team: 'SOS',
       members:
        [ { name: 'Haruhi' },
    +     { name: 'Mikuru' },
    -     { name: 'Michiru' },
          { name: 'Yuki' },
          { name: 'Itsuki' },
          { name: 'Kyon' } ] }
     \ No newline at end of file

        at spec (/home/kwatch/example_test.js:34:34)
            ok (util.inspect(team1)).eq(util.inspect(team2));
    ----------------------------------------------------------------------
    ## total:1, passed:0, failed:1, error:0, skipped:0  (in 0.009s)



Tracer
======

(Experimental)

Oktest provides tracer object which can be stub or mock object.

Tracer object have four methods:

trace(object, method1, method2, ...)
	Trace method calls.

traceFunc(func[, name])
	Create new function to trace function call of func and return it.
	Second argument is necessary if func is anonymous function.

dummy(object, {name1:returnval1, name2:returnval2, ...})
	Create dummy methods with dummy return values.

fake({name1:returnval1, name2:returnval2, ...})
	Return fake object.
	This is a short cut of dummy()::

	    /// for example,
	    var obj = tracer.fake({a:1, b:2});
	    /// ... is a short cut of:
	    var obj = {}
	    tracer.dummy({}, {a:1, b:2});

In any case, ``Tracer`` object records both arguments and return-value of method calls.

The following is an comprehensive example to demonstrace tracer features::

    "use strict";
    var oktest = require("oktest");
    var topic  = oktest.topic,
        spec   = oktest.spec,
        ok     = oktest.ok,
        NG     = oktest.NG;


    topic("Tracer demo", function() {

        this.provideObj = function() {
            return {
                add: function(x, y) { return x + y; },
                sub: function(x, y) { return x - y; }
            };
        };


        ///
        /// example to trace method calls
        ///
        topic("#trace()", function() {
            spec("traces method calls", function(obj) {
                /// create tracer object
                var tr = oktest.tracer.create();
                /// register methods to trace
                tr.trace(obj, 'add', 'sub');
                /// call methods
                ok (obj.add(1, 2)).is(3);
                ok (obj.sub(5, 1)).is(4);
                /// verify method calls
                ok (tr.called.length).is(2);
                ok (tr.called[0]).deepEqual({
                    object: obj, method: 'add', args: [1, 2], ret: 3 });
                ok (tr.called[1]).deepEqual({
                    object: obj, method: 'sub', args: [5, 1], ret: 4 });
            });
        });

        ///
        topic("#traceFunc()", function() {
            spec("returns new func to trace function call.", function(obj) {
                /// target functions to trace
                function add(x, y) { return x + y; }
                var sub = function(x, y) { return x - y; };
                /// create tracer object
                var tr = oktest.tracer.create();
                /// trace functions
                add = tr.traceFunc(add);
                sub = tr.traceFunc(sub, "sub"); // specify name to record
                /// call functions
                ok (add(1, 2)).is(3);
                ok (sub(5, 1)).is(4);
                /// verify function calls
                ok (tr.called.length).is(2);
                ok (tr.called[0]).deepEqual({
                    object: null, name: 'add', args: [1, 2], ret: 3 });
                ok (tr.called[1]).deepEqual({
                    object: null, name: 'sub', args: [5, 1], ret: 4 });
            });
        });

        ///
        /// example to set dummy methods
        ///
        topic("#dummy()", function() {
            spec("sets dummy methods", function(obj) {
                /// create tracer object
                var tr = oktest.tracer.create();
                /// register dummy method names and return values
                tr.dummy(obj, {add: 100, sub: 200});
                /// call methods
                ok (obj.add(1, 2)).is(100);   // != 3
                ok (obj.sub(5, 1)).is(200);   // != 4
                /// verify method calls
                ok (tr.called.length).is(2);
                ok (tr.called[0]).deepEqual({
                    object: obj, method: 'add', args: [1, 2], ret: 100 });
                ok (tr.called[1]).deepEqual({
                    object: obj, method: 'sub', args: [5, 1], ret: 200 });
            });
        });

        ///
        /// example to create fake object
        ///
        topic("#fake()", function() {
            spec("returns fake object", function() {
                /// create tracer object
                var tr = oktest.tracer.create();
                /// create fake object with dummy method names and return values
                var obj = tr.fake({add: 100, sub: 200});
                /// call methods
                ok (obj.add(1, 2)).is(100);   // != 3
                ok (obj.sub(5, 1)).is(200);   // != 4
                /// verify method calls
                ok (tr.called.length).is(2);
                ok (tr.called[0]).deepEqual({
                    object: obj, method: 'add', args: [1, 2], ret: 100 });
                ok (tr.called[1]).deepEqual({
                    object: obj, method: 'sub', args: [5, 1], ret: 200 });
            });
        });

    });


    if (process.argv[1] === __filename) {
        oktest.main();
    }



Skip Test
=========

It is possible to skip tests according to a certain condition. ::

    import unittest
    from oktest import ok, run, {{*skip*}}

    topic("Skip Demo", function() {

        skip("skip example", function() {
            if (condition) oktest.skip("...reason...");
            /// or
            oktest.skipWhen(condition, "...reason...");
            /// ...
        });

    });



Command-line Interface
======================

Oktest now supports command-line interface to execute test scripts. ::

    $ ls oktest.js
    oktest.js
    ## run test scripts in plain format
    $ node oktest.js -sp tests/*_test.py
    ## run test scripts in 'tests' dir with pattern '*_test.py'
    $ node oktest.js -p '*_test.py' tests
    ## filter by tipic
    $ node oktest.js -f topic='*pattern*' tests
    ## filter by spec
    $ node oktest.js -f '*pattern*' tests   # or -f spec='*pattern*'

Type ``node oktest.js -h`` for details about command-line options.



Tips
====

* You can define your own custom assertion function. ::

    // define custom assertion function
    function assertStartWith(bool, actual, expected) {
        var s = actual.substr(0, expected.length);
        if ((s === expected) === bool)
            return null;
        var errmsg = (bool ? "" : "NOT ")
            + "$actual starts with " + util.inspect(expected) + " : failed.\n"
            + "  $actual: " + util.inspect(actual);
        return errmsg;
    }
    // register
    oktest.assertion.register("startWith", assertStartWith);

    // how to use
    ok ("Haruhi").startWith("Haru");

* It is possible to chain assertion methods. ::

    // chain assertion methods
    ok (arr).isa(Array).length(2)
    ok (obj).hasAttr("name", "Haruhi").hasAttr("gender", "F");

* If you want to change reporting format, specify ``-sp`` (plain),
  ``-ss`` (simple), or ``-sv`` (verbose) in command-line::

    $ node example_test.js -sp    # or -s plain

  Or pass ``{style:"plain"}`` to ``oktest.run()``.

    if (process.argv[1] === __filename) {
        oktest.run({style:"plain"});
    }

* ``oktest.run()`` returns total number of failures and errors. ::

    // exit with status code 0 when no errors.
    process.exit(oktest.run());

* If you call ok() or NG() but forget to do assertion, Oktest.js warns it. ::

    topic("example", function() {
        spec("warned when assertion is not done", function() {
            //ok (1+1).is(2);
            ok (1+1)   // missing assertion
        });
    });

    oktest.run()   #=> warning: ok() is called but not tested.



License
=======

$License: MIT License $



Copyright
=========

$Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $

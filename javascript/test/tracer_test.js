"use strict";
var oktest = require("oktest");
var topic  = oktest.topic,
    spec   = oktest.spec,
    ok     = oktest.ok,
    NG     = oktest.NG,
    precond = oktest.precond;


+ topic("oktest.tracer.create()", function() {

  - spec("returns Tracer object.", function() {
      ok (oktest.tracer.create()).isa(oktest.tracer.Tracer);
    });

  });


+ topic("oktest.tracer.Tracer", function() {

    this.provideObj = function() {
        return {
            hello: function(name) { return "Hello "+name+"!"; },
            add:   function(x, y) { return x+y; },
            sub:   function(x, y) { return x-y; }
        };
    };

    + topic("#trace()", function() {

        - spec("modifies object to record method call.", function(obj) {
              var tr = oktest.tracer.create();
              tr.trace(obj, 'hello');
              precond (tr.called).length(0);
              ok (obj.hello("Sasaki")).is("Hello Sasaki!");
              ok (tr.called).length(1);
              var expected = {
                  object: obj, name: "hello", args: ["Sasaki"],
                  ret: "Hello Sasaki!"
              };
              ok (tr.called[0]).deepEqual(expected);
          });

        - spec("accepts several method names", function(obj) {
              var tr = oktest.tracer.create();
              tr.trace(obj, 'add', 'sub');
              precond (tr.called).length(0);
              ok (obj.add(1, 2)).is(3);
              ok (obj.sub(3, 4)).is(-1);
              ok (tr.called).length(2);
              var expected1 = {
                  object: obj, name: "add", args: [1, 2], ret: 3
              };
              var expected2 = {
                  object: obj, name: "sub", args: [3, 4], ret: -1
              };
              ok (tr.called[0]).deepEqual(expected1);
              ok (tr.called[1]).deepEqual(expected2);
          });

        - spec("records only registered methods", function(obj) {
              var tr = oktest.tracer.create();
              //tr.trace(obj, 'add', 'sub');
              tr.trace(obj, 'sub');
              precond (tr.called).length(0);
              ok (obj.add(1, 2)).is(3);   // not traced
              ok (obj.sub(3, 4)).is(-1);  // traced
              ok (tr.called).length(1);
              var expected = {
                  object: obj, name: "sub", args: [3, 4], ret: -1
              };
              ok (tr.called[0]).deepEqual(expected);
          });

      });

    + topic("#dummy()", function() {

        - spec("sets dummy methods to objects.", function(obj) {
              precond(obj.add(1, 2)).is(3);
              precond(obj.sub(7, 3)).is(4);
              var tr = oktest.tracer.create();
              tr.dummy(obj, {add: 100, sub: 200});
              ok (obj.add(1, 2)).is(100);
              ok (obj.sub(7, 3)).is(200);
          });

        - spec("method calls on dummy methods are traced.", function(obj) {
              var tr = oktest.tracer.create();
              tr.dummy(obj, {add: 100, sub: 200});
              precond (tr.called).length(0);
              ok (obj.add(1, 2)).is(100);
              ok (obj.sub(7, 3)).is(200);
              ok (tr.called).length(2);
              ok (tr.called[0]).deepEqual({object: obj, name: 'add', args: [1, 2], ret: 100});
              ok (tr.called[1]).deepEqual({object: obj, name: 'sub', args: [7, 3], ret: 200});
          });
      
      });

    + topic("#fake()", function() {

        - spec("takes dummy data and returns fake object.", function() {
              var tr = oktest.tracer.create();
              var fake = tr.fake({add: 10, sub: 20});
              ok (fake).hasAttr("add");
              ok (fake).hasAttr("sub");
              ok (fake.add).isFunction();
              ok (fake.sub).isFunction();
              ok (fake.add(1, 2)).is(10);
              ok (fake.sub(7, 4)).is(20);
          });

        - spec("method calls on fake methods are traced.", function() {
              var tr = oktest.tracer.create();
              var fake = tr.fake({add: 10, sub: 20});
              precond (tr.called).length(0);
              fake.add(1, 2);
              fake.sub(7, 4);
              ok (tr.called[0]).deepEqual({object: fake, name: "add", args: [1, 2], ret: 10});
              ok (tr.called[1]).deepEqual({object: fake, name: "sub", args: [7, 4], ret: 20});
          });
      
      });

    + topic("#intercept()", function() {

        - spec("intercepts method call.", function(obj) {
              var tr = oktest.tracer.create();
              function fn(original, x, y) {
                  return 10 * original.call(this, x, y);
              }
              tr.intercept(obj, {add:fn});
              ok (obj.add(1, 2)).is((1+2)*10);
          });

        - spec("intercepted method calls are traced.", function(obj) {
              var tr = oktest.tracer.create();
              function fn(original, x, y) {
                  return 10 * original.call(this, x, y);
              }
              tr.intercept(obj, {add:fn, sub:fn});
              precond(tr.called).length(0);
              obj.add(1,2);
              obj.sub(7,3);
              ok (tr.called).length(2);
              ok (tr.called[0]).deepEqual({object:obj, name: 'add', args: [1, 2], ret: 30});
              ok (tr.called[1]).deepEqual({object:obj, name: 'sub', args: [7, 3], ret: 40});
          });

      });

    this.provideAdd = function() { function add(x, y) { return x + y; }; return add; };
    this.provideSub = function() { function sub(x, y) { return x - y; }; return sub; };

    + topic("#traceFunc()", function() {

        - spec("returns new function.", function(add, sub) {
              var tr = oktest.tracer.create();
              ok (tr.traceFunc(add)).isFunction();
              ok (tr.traceFunc(sub, 'minus')).isFunction();
          });

        - spec("function calls are traced.", function(add, sub) {
              var tr = oktest.tracer.create();
              add = tr.traceFunc(add);
              sub = tr.traceFunc(sub, 'minus');
              ok (add(1, 2)).is(3);
              ok (sub(5, 3)).is(2);
              ok (tr.called).length(2);
              ok (tr.called[0]).deepEqual({
                  object: null, name: "add", args: [1, 2], ret: 3});
              ok (tr.called[1]).deepEqual({
                  object: null, name: "minus", args: [5, 3], ret: 2});
          });

      });

  });


if (process.argv[1] === __filename) {
    oktest.main();
}

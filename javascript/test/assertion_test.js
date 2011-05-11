///
/// $Release: $
/// $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
/// $License: MIT License $
///

var oktest = require('../lib/oktest.js');
var ok = oktest.ok;

function should_be_error(func, errmsg) {
	var thrown = null;
	var inspect = oktest.util.inspect;
	try {
		func();
	}
	catch (ex) {
		thrown = ex;
		//if (! (ex instanceof oktest.AssertionObject)) {
		if (! (ex instanceof oktest.AssertionError)) {
			throw "oktest.AssertionError expected but got " + require('util').inspect(ex);
		}
		if (errmsg && errmsg !== ex.message) {
			throw inspect(errmsg) + " is expected but got "+ inspect(ex.message);
		}
	}
	if (! thrown) {
		throw "Exception expected but not thrown.";
	}
}

var v = null;

/// eq()
ok (1).eq(1);
should_be_error(function() { ok (1).eq(2); },
				"1 == 2 : failed.");

/// ne()
ok (1).ne(2);
should_be_error(function() { ok (1).ne(1); },
				"1 != 1 : failed.");

/// is()
ok (null).is(null);
should_be_error(function() { ok (null).is(undefined); },
				"null === undefined : failed.");

/// isnt()
ok (null).isnt(undefined);
should_be_error(function() { ok (null).isnt(null); },
				"null !== null : failed.");

/// lt()
ok (1).lt(2);
should_be_error(function() { ok (1).lt(1); },
				"1 < 1 : failed.");

/// gt()
ok (1).gt(0);
should_be_error(function() { ok (1).gt(1); },
				"1 > 1 : failed.");

/// le()
ok (1).le(2);
ok (1).le(1);
should_be_error(function() { ok (1).le(0); },
				"1 <= 0 : failed.");

/// ge()
ok (1).ge(0);
ok (1).ge(1);
should_be_error(function() { ok (1).ge(2); },
				"1 >= 2 : failed.");

/// inDelta()
ok (1.0/3.0).inDelta(0.33333, 0.001);
should_be_error(function() { ok (0.333333).inDelta(0.3344, 0.001); },
				"0.333333 > 0.3334 : failed.");
should_be_error(function() { ok (0.333333).inDelta(0.3322, 0.001); },
				"0.333333 < 0.3332 : failed.");

/// isTypeof()
ok ("sos").isTypeof("string");
ok (123).isTypeof("number");
ok (3.14).isTypeof("number");
ok (true).isTypeof("boolean");
ok (false).isTypeof("boolean");
ok (null).isTypeof("object");
ok (undefined).isTypeof("undefined");
ok (function() {}).isTypeof("function");
ok ({}).isTypeof("object");
ok ([]).isTypeof("object");
should_be_error(function() { ok (null).isTypeof("null"); },
			   "typeof(null) == 'null' : failed.");

/// isa()
ok (new String("sos")).isa(String);
ok (new Number(123)).isa(Number);
ok (new Boolean(true)).isa(Boolean);
should_be_error(function() { ok ("sos").isa(String); },
				"'sos' instanceof [Function: String] : failed.");

/// matches()
ok ("haruhi").matches(/^[a-z]+$/);
should_be_error(function() { ok ("endless8").matches(/^[a-z]+$/); },
				"'endless8'.match(/^[a-z]+$/) : failed.");

/// arrayEq()
ok (["haruhi", "mikuru", "yuki"]).arrayEq(["haruhi", "mikuru", "yuki"]);
should_be_error(function() {
	ok (["haruhi", "mikuru", "yuki"]).arrayEq(["kyon", "itsuki"]);
}, "[ 'haruhi', 'mikuru', 'yuki' ].arrayEq([ 'kyon', 'itsuki' ]) : failed.");
should_be_error(function() {
	ok (["haruhi", "mikuru", "yuki"]).arrayEq(["haruhi", "mikuru", "nagato"]);
}, "[at index 2] 'yuki' === 'nagato' : failed.");
should_be_error(function() {
	ok ({haruhi: "Suzumiya"}).arrayEq(["haruhi", "mikuru", "nagato"]);
}, "Array is expected but got [object Object].");
should_be_error(function() {
	ok (["haruhi", "mikuru", "nagato"]).arrayEq(123);
}, "Array is expected but got haruhi,mikuru,nagato.");

/// inObject()
ok ("name").inObject({"name": "Sasaki"});
should_be_error(function() { ok ("namae").inObject({"name": "Sasaki"}); },
				"'namae' in { name: 'Sasaki' } : failed.");

/// inArray()
ok ("mikuru").inArray(["haruhi", "mikuru", "yuki"]);
should_be_error(function() { ok ("john").inArray(["kyon", "itsuki"]); },
				"'john' exists in [ 'kyon', 'itsuki' ] : failed.");

/// hasKey()
ok ({"name": "Sasaki"}).hasKey("name");
should_be_error(function() { ok ({"name": "Sasaki"}).hasKey("namae"); },
				"'namae' in { name: 'Sasaki' } : failed.");

/// hasItem()
ok (["haruhi", "mikuru", "yuki"]).hasItem("yuki");
should_be_error(function() { ok (["kyon", "itsuki"]).hasItem("john"); },
				"[ 'kyon', 'itsuki' ] has item 'john' : failed.");

/// throws_()
var fn1;
fn1 = function() { null.property; };
ok (fn1).throws_(Error);
ok (fn1.exception instanceof Error).is(true);
fn1 = function() { throw "ERROR"; };
ok (fn1).throws_(String, "ERROR");
ok (fn1.exception).eq("ERROR");
fn1 = function() { return; };
should_be_error(function() { ok (fn1).throws_(Error); },
			   "Error should be thrown : failed.");
fn1 = function() { throw new Error("ERROR"); };
should_be_error(function() { ok (fn1).throws_(TypeError, "ERROR"); },
                "TypeError should be thrown : failed, got Error object.");

/// throwsNothing()
var fn2;
fn2 = function() { return; };
ok (fn2).throwsNothing();
fn2 = function() { null.property; };
should_be_error(function() { ok (fn2).throwsNothing(); });


/// _done flag
(function() {
	var items = oktest.AssertionObject._instances;
	for (var i = 0, n = items.length; i < n; i++) {
		var item = items[i];
		ok (item).hasKey('_done');
		ok (item._done).is(true);
		if (item._done !== true) {
			oktest.print('*** debug: item='+oktest.util.inspect(item));
		}
	}
})();


///
oktest.print("Done.");

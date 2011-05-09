// -*- coding: utf-8 -*-

///
/// $Release: $
/// $Copyright: copyright(c) 2011 kuwata-lab.com all rights reserved $
/// $License: MIT License $
///


"use strict";

var Oktest = {
	VERSION:  '0.0.0',
	encoding: 'utf-8'
};


///
/// utilities
///

Oktest.util = {

	classdef: function(constructor, method_def, static_def) {
		if (static_def) static_def(constructor);
		if (method_def) method_def(constructor.prototype);
		return constructor;
	},

	quote: function(str) {
		return "'" + str.replace(/\\/, '\\\\').replace(/\n/, '\\\\n\\').replace(/'/, "\\\\'") + "'";  //'
	},

	inspect: function(value) {
		var t = typeof(value);
		if (t == "string")    return Oktest.util.quote(value);
		if (t == "number")    return value.toString();
		if (t == "boolean")   return value ? "true" : "false";
		if (t == "undefined") return "undefined";
		if (t == "function")  return value.name ? "<function " + value.name + "()>" : "<function()>";
		if (t == "object") {
			if (value === null) return "null";
			var buf = [];
			if (value.constructor === Array) {  /// or Array.prototype
				for (var i = 0, n = value.length; i < n; i++) {
					buf.push(Oktest.util.inspect(value[i]));
				}
				return "[" + buf.join(", ") + "]";
			}
			else {
				for (var p in value) {
					buf.push(p + ':' + Oktest.util.inspect(value[p]))
				}
				return "{" + buf.join(", ") + "}";
			}
		}
		throw "unreachable: typeof(value)="+typeof(value)+", value="+value;
	},

	strip: function(str) {
		return str.replace(/^\s+/, '').replace(/\s+$/, '');
	},

	flatten: function(arr) {
		var arr2 = [];
		for (var i = 0, n = arr.length; i < n; i++) {
			var item = arr[i];
			if (item instanceof Array) {
				arr2 = arr2.concat(Oktest.util.flatten(item));
			}
			else {
				arr2.push(item);
			}
		}
		return arr2;
	},

	readFile: function(filename) { },

	writeFile: function(filename) { },

	readLineInFile: function(filename, linenum) {
		var content = Oktest.util.readFile(filename)
		//return content.split(/^/m)[linenum-1];   // fails sometimes in nodejs (maybe V8 bug)
		return content.split(/\r?\n/)[linenum-1];
	},

	unifiedDiff: function(text1, texdt2) {
	}

};


///
/// compatibility layer
///
Oktest._engine = { nodejs: false, spidermoneky: false, rhino: false };
if (typeof(require) == 'function' && typeof(require.resolve) == 'function') { // node.js
	Oktest._engine.nodejs = true;
	(function() {
		var system = require('system');
		Oktest._args = Oktest.util.flatten(system.args);
		Oktest.print = system.print;  //require('sys').puts;
		var util = require("util");
		Oktest.util.inspect = util.inspect;
		var fs = require("fs");
		Oktest.util.readFile = function(filename) {
			return fs.readFileSync(filename, Oktest.encoding);
		};
		Oktest.util.writeFile = function(filename, content) {
			return fs.writeFileSync(filename, content, Oktest.encoding);
		};
		Oktest.util.system = function(command) {
			var sout, serr, ex;
			var called = false;
			var callback = function (error, stdout, stderr) {
				sout = stdout;
				serr = stderr;
				ex   = error;
				called = true;
			};
			var child = require('child_process').exec(command, callback);
			//var x = 0;
			//while (! called) {
			//	x++;
			//}
			return [ex, sout, serr];
		};
		Oktest.util.diff_u = function(content1, content2) {
			var fname1 = '__expected__', fname2 = '__actual__';
			Oktest.util.writeFile(fname1, content1);
			Oktest.util.writeFile(fname2, content2);
			var result = Oktest.util.system("diff -u " + fname1 + " " + fname2);
			console.log('*** debug: result='); console.log(result);
			return result[1];
		};
		Oktest.util.unifiedDiff = function(text1, text2) {
			//var diff_match_patch = require('./diff_match_patch.js');
			var diff_match_patch = require('diff_match_patch');
			var dmp = new diff_match_patch.diff_match_patch();
			var arr = dmp.diff_linesToChars(text1, text2);
			var chars1 = arr[0], chars2 = arr[1], char2line = arr[2];
			var diffs = dmp.diff_main(chars1, chars2, false);
			dmp.diff_charsToLines(diffs, char2line);
			//dmp.diff_cleanupSemantic(diffs);
			var sb = '';
			for (var i = -1, n = diffs.length; ++i < n; ) {
				var pair = diffs[i];
				var cmp  = pair[0];
				var text = pair[1];
				var sign = cmp > 0 ? '+' : cmp < 0 ? '-' : ' ';
				var s = text.replace(/^/mg, sign);
				if (text.match(/\n$/)) s = s.substring(0, s.length - 1);
				sb += s;
			}
			return sb;
		};

	})();
}
else if (typeof(java) == 'object' && typeof(Packages) == 'function') { // Rhino
	Oktest._engine.rhino = true;
	Oktest._args = arguments;
	Oktest.print = print;
	Oktest.util.readFile = function(filename) {
		var reader = new java.io.BufferedReader(new java.io.FileReader(filename));
		//var buf = Array(512);
		//reader.read(buf, 0, 512); // Cannot convert org.mozilla.javascript.NativeArray@3c6a22 to char[]
		var line, lines = [];
		try {
			while ((line = reader.readLine()) != null) lines.push(line);
		} finally { reader.close(); }
		buf.push("");
		return buf.join("\n");
	};
	Oktest.util.readLineInFile = function(filename, linenum) {
		var line;
		var reader = new java.io.BufferedReader(new java.io.FileReader(filename));
		try {
			for (var i = 1; (line = reader.readLine()) != null; i++) {
				if (i == linenum) break;
			}
		} finally { reader.close(); }
		return line;
	};
}
else if (typeof(print) == 'function') {  // SpiderMonkey
	Oktest._engine.spidermoneky = true;
	Oktest._args = arguments;
	Oktest.print = print;
	Oktest.util.readFile = function(filename) {
		var f = File(filename);
		f.open('text,read');
		var max = 4096, buf = [], i = 0, s;
		try {
			while ((s = f.read(max)) != undefined) {  /// readfile() will exit if EOF. Why?
				buf[i++] = s;
				if (s.length < max) break;
			}
		} finally { f.close(); }
		return buf.join('');
	};
}
else {
	throw "*** Unknown JavaScript engine: Oktest supports node.js, rhino, or spidermonkey.";
}


///
/// assertion object class and functions
///

Oktest.AssertionObject = Oktest.util.classdef(

	/// constructor
	function(left, bool, func_name, stack) {
		this._left  = left;
		this._bool  = bool;
		this._func_name = func_name;
		this._stack = stack;
		this._done  = false;
		Oktest.AssertionObject._instances.push(this);
	},

	/// instance methods
	function(def) {

		def._OKTEST_FAILED = null,

		def._get_location = function(stack) {
			if (! stack) stack = this._stack;
			var line = stack.split(/^/m)[2];
			if (! line) return [null, null];
			var m = line.match(/\((.*):(\d+):(\d+)\)/) || line.match(/@(.*):(\d+)$/m);
			if (! m) return [null, null];
			return [m[1], m[2]-0]; // filepath, linenum
		};

		def._failed = function(right, message) {
			this._right = right;
			this._message  = this._bool ? message : "NOT " + message;
			return this;
		};

		def._msg = function(left, op, right) {
			var inspect = Oktest.util.inspect;
			if (op[0] === '.') {
				return inspect(left) + op + "(" + inspect(right) + ") : failed.";
			}
			else {
				return inspect(left) + " " + op + " " + inspect(right) + " : failed.";
			}
		};

		def.eq = function(right) {
			this._done = true;
			var bool = this._left == right;
			if (bool == this._bool) return;
			//throw this._failed(right, this._msg(this._left, "==", right));
			var ex = this._failed(right, this._msg(this._left, "==", right));
			if (typeof(right) == 'string') {
				ex._diff = Oktest.util.unifiedDiff(right, this._left);
			}
			throw ex;
		};

		def.ne = function(right) {
			this._done = true;
			var bool = this._left != right;
			if (bool == this._bool) return;
			throw this._failed(right, this._msg(this._left, "!=", right));
		};

		def.is = function(right) {
			this._done = true;
			var bool = this._left === right;
			if (bool == this._bool) return;
			throw this._failed(right, this._msg(this._left, "!=", right));
		};

		def.isnt = function(right) {
			this._done = true;
			var bool = this._left !== right;
			if (bool == this._bool) return;
			throw this._failed(right, this._msg(this._left, "!=", right));
		};

		def.lt = function(right) {
			this._done = true;
			var bool = this._left < right;
			if (bool == this._bool) return;
			throw this._failed(right, this._msg(this._left, "<", right));
		};

		def.gt = function(right) {
			this._done = true;
			var bool = this._left > right;
			if (bool == this._bool) return;
			throw this._failed(right, this._msg(this._left, ">", right));
		};

		def.le = function(right) {
			this._done = true;
			var bool = this._left <= right;
			if (bool == this._bool) return;
			throw this._failed(right, this._msg(this._left, "<=", right));
		};

		def.ge = function(right) {
			this._done = true;
			var bool = this._left >= right;
			if (bool == this._bool) return;
			throw this._failed(right, this._msg(this._left, ">=", right));
		};

		def.in_delta = function(right, delta) {
			this._done = true;
			var bool;
			bool = this._left <= right - delta;
			if (bool != this._bool)
				throw this._failed(right, this._msg(this._left, ">", right - delta));
			bool = this._left >= right + delta;
			if (bool != this._bool)
				throw this._failed(right, this._msg(this._left, "<", right + delta));
		};

		def.is_a = function(type) {
			this._done = true;
			var bool;
			if (typeof(type) == 'string') {
				bool = typeof(this._left) == type;
				if (bool == this._bool) return;
				throw this._failed(right, "typeof(" + Oktest.util.inspect(this._left) + ") == '" + type + "' : failed.");
			}
			else if (typeof(type) == 'function') {
				bool = this._left instanceof type;
				if (bool == this._bool) return;
				throw this._failed(right, this._msg(this._left, "instanceof", type));
			}
			else {
				throw "*** Type error: is_a() expects type name or class object but got " + Oktest.util.inspect() + ".";
			}
		};

		def.match = function(pattern) {
			this._done = true;
			var bool = this._left.match(pattern);
			if (bool == this._bool) return;
			throw this._failed(right, this._msg(this._left, ".match", pattern));
		};

		def.in_object = function(obj) {
			this._done = true;
			var bool = this._left in obj;
			if (bool == this._bool) return;
			throw this._failed(obj, this._msg(this._left, "in", obj));
		};

		def.in_array = function(arr) {
			this._done = true;
			var bool = false;
			for (var i = 0, n = arr.length; i < n; i++) {
				if (arr[i] === this._left) {
					bool = true;
					break;
				}
			}
			if (bool == this._bool) return;
			throw this._failed(arr, this._msg(this._left, "found in", arr));
		};

		def.has_key = function(key) {
			this._done = true;
			var bool = key in this._left;
			if (bool == this._bool) return;
			throw this._failed(key, this._msg(key, "in", this._left));
		};

		def.has_item = function(item) {
			this._done = true;
			var bool = false;
			for (var k in item) {
				if (item[k] === this._left) {
					bool = true;
					break;
				}
			}
			if (bool == this._bool) return;
			throw this._failed(item, this._msg(this._left, "has item", item));
		};

		def.throws = function(exception) {
			this._done = true;
			if (! this._bool)
				throw "** ERROR: throws() is not available with NG().";
			if (typeof(this._left) != 'function')
				throw "** ERROR: throws() is available with function object.";
			var thrown = false;
			try {
				this._left();
			}
			catch (ex) {
				thrown = true;
				if (exception && ex !== exception) {
					var ins = Oktest.util.inspect;
					var msg1 = ins(exception) + " should be thrown : failed, got " + ins(ex) + ".";
					throw this._failed(exception, msg1);
				}
				this._left.exception = ex;
			}
			if (! thrown) {
				var msg2 = Oktest.util.inspect(exception) + " should be thrown : failed.";
				throw this._failed(exception, msg2);
			}
		};

		def.throws_nothing = function(exception) {
			if (! this._bool)
				throw "** ERROR: throws_nothing() is not available with NG().";
			if (typeof(this._left) != 'function')
				throw "** ERROR: throws() is available with function object.";
			try {
				this._left();
			}
			catch (ex) {
				var msg = "Nothing should be thrown : failed, got " + Oktest.util.inspect(ex) + ".";
				throw this._failed(exception, msg);
			}
		};

	},

	/// class methods
	function(cls) {
		cls._instances = [];
	}

);


Oktest.SkipException = Oktest.util.classdef(

	/// constructor
	function(reason) {
		this.reason = reason;
	},

	/// instance methods
	function(def) {
		def._OKITEST_SKIPPED = true;
	}

);


Oktest.ok = function(left) {
	return new Oktest.AssertionObject(left, true, 'ok', new Error().stack);
}

Oktest.NG = function(left) {
	return new Oktest.AssertionObject(left, false, 'NG', new Error().stack);
}

Oktest.pre_cond = function(left) {
	/// same as ok() but it represents precodition rather than specification.
	return new Oktest.AssertionObject(left, true, 'pre_cond', new Error().stack);
}

Oktest.skip_when = function(condition, reason) {
	if (condition) {
		throw new Oktest.SkipException(reason);
	}
}

Oktest.is_failed = function(ex) {
	return '_OKTEST_FAILED' in ex;
}

Oktest.is_skipped = function(ex) {
	return '_OKTEST_SKIPPED' in ex;
}


///
/// target object class and functions
///

Oktest.TargetObject = Oktest.util.classdef(

	/// constructor
	function(name, defun) {
		this.name = name;
		this.specs = [];
		this.results = {success: 0, failed: 0, error: 0, skipped: 0};
		this.status = null;   // '.':success, 'f':failed, 'E':error, 's':skipped
		Oktest.TargetObject._all.push(this);
		var stack = Oktest.TargetObject._stack;
		this.parent = stack[stack.length - 1];
		var depth = 0;
		for (var t = this; t.parent; t = t.parent) depth++;
		//for (var t = this, depth = 0; t.parent; t = t.parent, depth++);
		this.depth = depth;
		this._indent = (new Array(depth+1)).join("  ");
		stack.push(this);
		defun(this);
		stack.pop();
	},

	/// instance methods
	function(def) {

		def.accept = function(visitor) {
			return visitor.visit_target(this);
		};

		def.spec = function(desc, body) {
			var target_obj = this;
			var spec_obj = new Oktest.SpecObject(target_obj, desc, body);
			this.specs.push(spec_obj);
			return spec_obj;
		};

		def.should = def.spec;  // alias

	},

	/// class methods
	function(cls) {
		cls._all = [];
		cls._stack = [];
	}

);


Oktest.target = function(name, defun) {
	return new Oktest.TargetObject(name, defun);
};


///
/// spec object class
///

Oktest.SpecObject = Oktest.util.classdef(

	/// constructor
	function(target_obj, desc, body) {
		this.target = target_obj;
		this.desc = desc;
		this.body = body;
		this.status = null;
	},

	/// instance methods
	function(def) {

		def.accept = function(visitor) {
			return visitor.visit_spec(this);
		};

		def.after = null;

		def.echo = function(message) {
			Oktest.print(this.target._indent + "    " + message);
		};

	}

);


///
/// runner class and functions
///

Oktest.Runner = Oktest.util.classdef(

	/// constructor
	function() {
	},

	/// instance methods
	function(def) {

		def.visit = function(acceptor) {
			acceptor.accept(this);
		};

		def.visit_target = function(target) {
			Oktest.print(target._indent + "* " + target.name);
			var specs = target.specs;
			for (var spec, i = -1; spec = specs[++i]; ) spec.accept(this);
			var r = target.results;
			var total = r.success + r.failed + r.error + r.skipped;
			if (total > 0) this._report_target_result(total, target);
			//Oktest.print('');
		};

		def._report_target_result = function(total, target) {
			for (var spec, i = -1; spec = target.specs[++i]; ) {
				if (spec._thrown) {
				}
			}
			var r = target.results;
			var str = 'total:' + total + ', success:' + r.success + ', failed:'
			        + r.failed + ', error:' + r.error + ', skipped:' + r.skipped;
			Oktest.print(target._indent + '  (' + str + ')');
		};

		def.visit_spec = function(spec) {
			//Oktest.print(spec.target._indent + "  - " + spec.desc);
			var status = '';
			var msg = null;
			try {
				spec.body(spec);
				spec.target.results.success++;
				spec.status = '.';
				status = 'ok';
			}
			catch (ex) {
				spec._thrown = ex;
				if (Oktest.is_failed(ex)) {        // Oktest.AssertionObject object
					spec.target.results.failed++;
					spec.status = 'f';
					status = 'Failed';
					msg = [ex._message].concat(this._get_failed_msg(ex));
				}
				else if (Oktest.is_skipped(ex)) {  // Oktest.SkipException
					spec.target.results.skipped++;
					spec.status = 's';
					status = 'Skipped';
					msg = ["reason: " + ex.reason];
				}
				else {
					spec.target.results.errored++;
					spec.status = 'E';
					status = 'ERROR';
					throw ex;
				}
			}
			finally {
				var indent = spec.target._indent + "  ";
				this._report_spec_result(spec, indent, status, msg);
				this._check_specs_done(spec, indent, status);
				if (spec.after) spec.after();
			}
		};

		def._get_failed_msg = function(ass_obj) {
			var arr = ass_obj._get_location();
			var filepath = arr[0], linenum = arr[1];
			if (! filepath) return [];
			var line = Oktest.util.readLineInFile(filepath, linenum);
			arr = ["(File " + filepath + ", line " + linenum + ")",
			       "    " + Oktest.util.strip(line)];
			if (ass_obj._diff) {
				console.log('*** debug: diff='+ass_obj._diff);
				arr = arr.concat(ass_obj._diff.split(/\r?\n/));
			}
			return arr;
		};

		def._report_spec_result = function(spec, indent, status, msg) {
			Oktest.print(indent + "- [" + status + "] "+ spec.desc);
			if (msg !== null) {
				for (var s, i = -1; s = msg[++i]; ) {
					Oktest.print(indent + "  " + s);
				}
			}
		};

		def._check_specs_done = function(spec, indent, status) {
			var ass_objs = Oktest.AssertionObject._instances;
			for (var ass_obj, i = -1; ass_obj = ass_objs[++i]; ) {
				if (! ass_obj._done && status != 'ERROR') {
					var s = ass_obj._get_location().join(':');
					Oktest.print(indent + "  # Warning: " + ass_obj._func_name
					      + "() is called but not tested yet. (" + s + ")");
				}
			}
			Oktest.AssertionObject._instances = [];
		};

	}

);


Oktest.run_all = function() {
	var runner = new Oktest.Runner();
	var targets = Oktest.TargetObject._all;
	for (var target, i = -1; target = targets[++i]; ) {
		target.accept(runner);
	}
};


if (Oktest._engine.nodejs) {
	if (typeof(exports) == 'object') {
		(function() {
			for (var p in Oktest) exports[p] = Oktest[p];
		})();
	}
}

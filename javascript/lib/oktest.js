#!/usr/bin/env node

///
/// oktest.js - a new-style testing library for node.js
///
/// $Release: $
/// $Copyright: copyright(c) 2010-2011 kuwata-lab.com all rights reserved $
/// $License: MIT License $
///

"use strict";

var oktest = exports;
oktest.__version__ = '$Release: 0.0.0 $'.split(' ')[1];

var assert = require("assert");
var fs     = require("fs");
var os     = require("os");
var path   = require("path");
var tty    = require("tty");
var util   = require("util");


///
/// config
///

oktest.config = {
  encoding:         "utf8",
  style:            "verbose",
  color_available:  ! os.type().match(/^win/i),
  debug:            false
};


///
/// utilities
///

oktest.util = {

  _dp: function debugprint(name, arg) {
    if (oktest.config.debug) {
      util.print("** debug: "+name+"="+util.inspect(arg));
    }
  },

  repeat: function repeat(s, n) {
    var buf = "";
    while (n-- > 0) {
      buf += s;
    }
    return buf;
  },

  strip: function strip(str) {
    return str.replace(/^\s+/, '').replace(/\s+$/, '');
  },

  capitalize: function caplitalize(str) {
    return str[0].toUpperCase() + str.substr(1);
  },

  index: function index(array, item) {
    for (var i = 0, n = array.length; i < n; i++) {
      if (array[i] === item) return i;
    }
    return null;
  },

  split2: function split2(str, rexp) {
    var m = str.match(rexp);
    if (! m) return [str];
    return [str.substr(0, m.index), str.substr(m.index + m[0].length)];
  },

  fmt: function fmt(formatStr, varargs) {
    var args = arguments;
    formatStr = args[0];
    var i = 0;
    var n = args.length;
    var len = 0;
    var s = formatStr.replace(/%(.|\n)/g, function(m0, m1) {
      i++;
      if (i >= n) {
        throw new Error("format(): too less arguments.");
      }
      switch (m1) {
      case 's':  return String(args[i]);        break;
      case 'd':  return parseInt(args[i]);      break;
      case 'r':  return util.inspect(args[i]);  break;
      case '%':  return '%';                    break;
      default:
        throw new Error(util.inspect('%'+m1) + ": unsupported format.");
      }
    });
    if (i < n - 1) {
      throw new Error("format(): too much arguments.");
    }
    return s;
  },

  invoke: function invoke(object, method_name, args) {
    if (method_name in object) {
      var method = object[method_name];
      return method.apply(object, args);
    }
    return undefined;
  },

  fstat: function fstat(path) {
    var stat = null;
    try {
      stat = fs.statSync(path);
    }
    catch (ex) {
      if ('code' in ex && ex.code === 'ENOENT') {
        return null;   // not found
      }
      throw ex;
    }
    return stat;
  },

  rm_rf: function rm_rf(path) {
    if (path === "." || path === ".." || path === "/") {
      console.error("** warning: rm_rf() skips '"+path+"' (are you realy?).");
      return;
    }
    try { var fstat = fs.statSync(path); }
    catch (ex) { return; }
    if (fstat.isFile()) {
      fs.unlinkSync(path);
    }
    else if (fstat.isDirectory()) {
      var items = fs.readdirSync(path);
      for (var i = 0, n = items.length; i < n; i++) {
        var item = items[i];
        if (item === "." || item === "..") continue;
        oktest.util.rm_rf(path + "/" + item);
      }
      fs.rmdirSync(path);
    }
  },

  pattern2rexp: function pattern2rexp(pattern) {
    var rexp = "^";
    var symbols = '$^&*()[]{}.*?|\\-+';
    for (var i = 0, n = pattern.length; i < n; i++) {
      var ch = pattern[i];
      if (ch === "\\") {
        i++;
        rexp += i === n ? "\\\\" : pattern[i];
      }
      else if (ch === "*") {
        rexp += ".*";
      }
      else if (ch === "?") {
        rexp += ".";
      }
      else {
        rexp += symbols.indexOf(ch) >= 0 ? "\\" + ch : ch;
      }
    }
    rexp += "$";
    return new RegExp(rexp);
  },

  findFiles: function findFiles(pattern, dirpath) {
    function _findFiles(rexp, dirpath, matched) {
      var items = fs.readdirSync(dirpath || '.');
      for (var i = 0, n = items.length; i < n; i++) {
        var item = items[i];
        if (item == '.' || item == '..') continue;
        var child = dirpath ? dirpath + '/' + item : item;
        var fstat = fs.statSync(child);
        if (rexp.exec(child)) matched.push(child);
        if (fstat.isDirectory()) {
          _findFiles(rexp, child, matched);
        }
      }
    }
    var matched = [];
    var rexp = oktest.util.patternOrRexp(pattern);
    _findFiles(rexp, dirpath, matched);
    return matched;
  },

  patternOrRexp: function patternOrRexp(str) {
    var m = str.match('^/(.*)/$');
    var rexp = m ? new RegExp(m[1]) : oktest.util.pattern2rexp(str);
    return rexp;
  },

  StringIO: function StringIO() {
    this.output = "";
    this.write = function write(arg) { this.output += String(arg); };
    this.flush = function flush() {};
    this.value = function getValue() { return this.output; };
  },

  msec2str: function msec2str(msec) {
    if (msec === 0) return '0.000';
    var sec = msec / 1000.0;
    var min = parseInt(sec / 60);
    if (min === 0) return "" + sec;
    sec -= 60 * min;
    sec = parseInt(sec * 1000) / 1000.0;
    var zero = sec < 10 ? '0' : '';
    return "" + min + ":" + zero + sec;
  },

  //unifiedDiff: function unifiedDiff(text1, text2) {
  //  //var diff_match_patch = require('./diff_match_patch.js');
  //  var diff_match_patch = require('diff_match_patch');
  //  var dmp = new diff_match_patch.diff_match_patch();
  //  var arr = dmp.diff_linesToChars(text1, text2);
  //  var chars1 = arr[0], chars2 = arr[1], char2line = arr[2];
  //  var diffs = dmp.diff_main(chars1, chars2, false);
  //  dmp.diff_charsToLines(diffs, char2line);
  //  //dmp.diff_cleanupSemantic(diffs);
  //  var sb = '';
  //  for (var i = -1, n = diffs.length; ++i < n; ) {
  //    var pair = diffs[i];
  //    var cmp  = pair[0];
  //    var text = pair[1];
  //    var sign = cmp > 0 ? '+' : cmp < 0 ? '-' : ' ';
  //    var s = text.replace(/^/mg, sign);
  //    if (text.match(/\n$/)) s = s.substring(0, s.length - 1);
  //    sb += s;
  //  }
  //  return sb;
  //}

  unifiedDiff: function unifiedDiff(text1, text2, delta) {
    if (typeof(text1) !== "string") text1 = String(text1);
    if (typeof(text2) !== "string") text2 = String(text2);
    var diff = new oktest.util.Diff();
    return diff.unifiedDiff(text1, text2, delta);
  }

};


///
/// util.diff
///

oktest.util.Diff = function Diff(opts) {
  this.debug = false;
  if (opts && opts.debug) this.debug = opts.debug;
};

(function(def) {

  ///
  /// http://mashiki-memo.blogspot.com/2010/12/javascriptdiff.html
  /// license: unknown
  ///
  def.diff = function diff(arr1, arr2, rev) {
     var len1=arr1.length,
         len2=arr2.length;
     // reverse unless len1 <= len2
     if (!rev && len1>len2)
         return diff(arr2, arr1, true);
     // variable declaration and array initialization
     var k, p,
         offset=len1+1,
         delta =len2-len1,
         fp=[], ed=[];
     for (p=0; p<len1+len2+3; ++p) {
         fp[p] = -1;
         ed[p] = [];
     }
     // main process
     for (p=0; fp[delta + offset] != len2; p++) {
         for(k = -p       ; k <  delta; ++k) snake(k);
         for(k = delta + p; k >= delta; --k) snake(k);
     }
     return ed[delta + offset];

     // snake
     function snake(k) {
         var x, y, e0, o,
             y1=fp[k-1+offset],
             y2=fp[k+1+offset];
         if (y1>=y2) { // route choice
             y = y1+1;
             x = y-k;
             e0 = ed[k-1+offset];
             o = {edit:rev?'-':'+',arr:arr2, line:y-1};
         } else {
             y = y2;
             x = y-k;
             e0 = ed[k+1+offset];
             o = {edit:rev?'+':'-',arr:arr1, line:x-1};
         }
         // keep choiced route
         if (o.line>=0) ed[k+offset] = e0.concat(o);

         var max = len1-x>len2-y?len1-x:len2-y;
         for (var i=0; i<max && arr1[x+i]===arr2[y+i]; ++i) {
             // add route
             ed[k+offset].push({edit:'=', arr:arr1, line:x+i});
         }
         fp[k + offset] = y+i;
     }
  };

  def.unifiedDiff = function(text1, text2, delta) {
    if (text1 && text1[text1.length-1] != '\n')
      text1 += "\n\\ No newline at end of file\n";
    if (text2 && text2[text2.length-1] != '\n')
      text2 += "\n\\ No newline at end of file\n";
    var lines1 = text1.split(/\n/);
    var lines2 = text2.split(/\n/);
    lines1.unshift("");
    lines2.unshift("");
    var result = this.diff(lines1, lines2);
    var buf = "";
    var debug = this.debug;
    var callback = function(chunk, linenum1, linenum2) {
      var header = '@@ -' + linenum1 + ' +' + linenum2 + "\n";
      buf += header;
      for (var i = 0, n = chunk.length; i < n; i++) {
        var item = chunk[i];
        var ch = item.edit === '=' ? ' ' : item.edit;
        if (! debug)
          buf += ch + item.arr[item.line] + '\n';
        else
          buf += "" + item.line + ':' + item.edit + util.inspect(item.arr[item.line] + '\n') + "\n";
      }
    };
    this.eachChunk(result, callback, delta);
    return buf;
  };

  def.eachChunk = function eachChunk(result, callback, delta) {
    if (delta == null || delta < 0) delta = 3;
    var delta_x2 = delta * 2;
    var n_eq = 0;
    var linenum1 = 0;  // -
    var linenum2 = 0;  // +
    var tuple = null;
    var pos, chunk, i, n;
    for (i = 0, n = result.length; i < n; i++) {
      var ch = result[i].edit;
      if (ch === '=') {
        n_eq++; linenum1++; linenum2++;
        if (tuple !== null && n_eq > delta_x2) {
          pos = tuple[0];
          chunk = result.slice(pos, i - delta);
          callback(chunk, tuple[1], tuple[2]);
          tuple = null;
        }
      }
      else {
        if (tuple === null) {
          pos = Math.max(i - delta, 1);
          tuple = [pos, Math.max(linenum1 - delta, 1), Math.max(linenum2 - delta, 1)];
        }
        n_eq = 0;
        if      (ch === '-') linenum1++;
        else if (ch === '+') linenum2++;
      }
    }
    if (tuple !== null) {
      pos = tuple[0];
      chunk = result.slice(pos, i);
      callback(chunk, tuple[1], tuple[2]);
    }
    return this;
  };

})(oktest.util.Diff.prototype);

var fmt = oktest.util.fmt;


///
/// color
///

oktest.util.Color = {
  black  : function black  (s) { return "\x1b[0;30m" + s + "\x1b[0m"; },
  red    : function red    (s) { return "\x1b[0;31m" + s + "\x1b[0m"; },
  green  : function green  (s) { return "\x1b[0;32m" + s + "\x1b[0m"; },
  yellow : function yellow (s) { return "\x1b[0;33m" + s + "\x1b[0m"; },
  blue   : function blue   (s) { return "\x1b[0;34m" + s + "\x1b[0m"; },
  magenta: function magenta(s) { return "\x1b[0;35m" + s + "\x1b[0m"; },
  cyan   : function cyan   (s) { return "\x1b[0;36m" + s + "\x1b[0m"; },
  white  : function white  (s) { return "\x1b[0;37m" + s + "\x1b[0m"; },
  //
  bold   : function bold   (s) { return "\x1b[1;1m" + s + "\x1b[22m"; }
};

oktest.util.Color.Bold = {
  red    : function red    (s) { return "\x1b[1;31m" + s + "\x1b[0m"; },
  green  : function green  (s) { return "\x1b[1;32m" + s + "\x1b[0m"; },
  yellow : function yellow (s) { return "\x1b[1;33m" + s + "\x1b[0m"; },
  blue   : function blue   (s) { return "\x1b[1;34m" + s + "\x1b[0m"; },
  magenta: function magenta(s) { return "\x1b[1;35m" + s + "\x1b[0m"; },
  cyan   : function cyan   (s) { return "\x1b[1;36m" + s + "\x1b[0m"; },
  white  : function white  (s) { return "\x1b[1;37m" + s + "\x1b[0m"; }
};

oktest.util.Color.newColorTable = function newColorTable() {
  var c = oktest.util.Color;
  return {
    passed:     c.Bold.green,
    failed:     c.Bold.red,
    error:      c.Bold.red,
    skipped:    c.Bold.yellow,
    separator:  c.red,
    subject:    c.bold,
    null:       c.magenta
  };
};

oktest.util.Color.newMonoTable = function newMonoTable() {
  var _none = function(str) { return str; };
  return {
    passed:     _none,
    failed:     _none,
    error:      _none,
    skipped:    _none,
    separator:  _none,
    subject:    _none,
    null:       _none
  };
};

oktest.util.Color._colorize = function _colorize(str) {
  str = str.replace(/<r>((.|\n)*?)<\/r>/g, function(m0, m1) { return oktest.util.Color.red(m1); });
  str = str.replace(/<b>((.|\n)*?)<\/b>/g, function(m0, m1) { return oktest.util.Color.bold(m1); });
  str = str.replace(/<G>((.|\n)*?)<\/G>/g, function(m0, m1) { return oktest.util.Color.Bold.green(m1); });
  str = str.replace(/<R>((.|\n)*?)<\/R>/g, function(m0, m1) { return oktest.util.Color.Bold.red(m1); });
  str = str.replace(/<Y>((.|\n)*?)<\/Y>/g, function(m0, m1) { return oktest.util.Color.Bold.yellow(m1); });
  return str;
};


///
/// line cache
///

oktest.util.LineCache = function LineCache() {
  this.cache = {};
};

(function(def) {

  def.load = function load(filepath) {
    try {
      var content = fs.readFileSync(filepath, oktest.config.encoding);
      //var lines = content.split(/^/gm);   // fails sometimes in nodejs (maybe V8 bug)
      var lines = content.split(/\r?\n/);
      this.cache[filepath] = lines;
    }
    catch (ex) {
      this.cache[filepath] = null;   // file not found
    }
  };

  def.fetch = function fetch(filepath, linenum) {
    if (! (filepath in this.cache)) {
      this.load(filepath);
    }
    var lines = this.cache[filepath];
    return lines && linenum < lines.length ? lines[linenum-1] : null;
    //return lines[linenum-1];
  };

})(oktest.util.LineCache.prototype);


///
/// assertions
///

oktest.assertion = {
};


oktest.assertion.AssertionObject = function AssertionObject(actual, bool) {
  this.actual = actual;
  this.bool   = bool;
};

(function(def) {

  def._done  = false;

  def.failed = function(msg, expected, op) {
    //var params = {message: msg, actual: this.actual, expected: expected, operator: op};
    //throw new assert.AssertionError(params);  // stack is not set. why?
    try {
      assert.ok(false);
    }
    catch (ex) {
      ex.message  = msg;
      ex.actual   = this.actual;
      ex.expected = expected;
      ex.operator = op;
      //throw ex;
      return ex;
    }
    return "--unreachable--";
  };

  def._prefix = function _prefix(args) {
    return this.bool ? "" : "NOT ";
  };

  def._cmp = function _cmp(op, expected, bool, udiff) {
    this._done = true;
    if (bool === this.bool) return this;
    var msg = this._prefix() + "$actual " + op + " $expected : failed.\n";
    if (udiff) {
      msg += udiff;
    }
    else {
      //msg += "  $actual  : " + util.inspect(this.actual) + "\n"
      //     + "  $expected: " + util.inspect(expected);
      msg += fmt("  $actual  : %r\n  $expected: %r", this.actual, expected);
    }
    throw this.failed(msg, expected, op);
  };

  def._cmp2 = function _cmp(op, expected, bool) {
    this._done = true;
    var udiff = null;
    if (typeof(expected) === 'string' && expected.indexOf("\n") >= 0) {
      udiff = oktest.util.unifiedDiff(expected, String(this.actual));
      if (udiff) udiff = "+++ $actual\n--- $expected\n" + udiff.replace(/\r?\n$/, '');
    }
    return this._cmp(op, expected, bool, udiff);
  };

  def.eq = function eq(expected) {
    return this._cmp2("==", expected, this.actual == expected);
  };

  def.ne = function ne(expected) {
    return this._cmp("!=", expected, this.actual != expected);
  };

  def.is = function is(expected) {
    return this._cmp2("===", expected, this.actual === expected);
  };

  def.isNot = function isNot(expected) {
    return this._cmp("!==", expected, this.actual !== expected);
  };

  def.gt = function gt(expected) {
    return this._cmp(">", expected, this.actual > expected);
  };

  def.ge = function ge(expected) {
    return this._cmp(">=", expected, this.actual >= expected);
  };

  def.lt = function lt(expected) {
    return this._cmp("<", expected, this.actual < expected);
  };

  def.le = function le(expected) {
    return this._cmp("<=", expected, this.actual <= expected);
  };


  def.deepEqual = function deepEqual(expected) {
    if (! this.bool) return this.NotDeepEqual(expected);
    this._done = true;
    try {
      assert.deepEqual(this.actual, expected);
    }
    catch (ex) {
      if (ex instanceof assert.AssertionError) {
        var msg = "assert.deepEqual($actual, $expected) : failed.\n";
        var udiff = oktest.util.unifiedDiff(util.inspect(this.actual),
                                            util.inspect(expected));
        msg += udiff ? "+++ $actual\n--- $expected\n" + udiff.replace(/\r?\n$/, '')
                     : fmt("  $actual  %r: %r\n$expected: %r", this.actual, expected);
        ex.message = msg;
      }
      throw ex;
    }
    return this;
  };

  def.notDeepEqual = function notDeepEqual(expected) {
    if (! this.bool) return this.deepEqual(expected);
    this._done = true;
    try {
      assert.notDeepEqual(this.actual, expected);
    }
    catch (ex) {
      if (ex instanceof assert.AssertionError) {
        var msg = fmt("assert.notDeepEqual($actual, $expected) : failed, both are same.\n  $actual  : %r\n  $expected: %r",
                      this.actual, expected);
        ex.message = msg;
      }
      throw ex;
    }
    return this;
  };

  def.arrayEqual = function arrayEqual(expected) {
    this._done = true;
    if (! this.bool) throw new Error("arrayEqual() is not available with NG().");
    var msg;
    var actual = this.actual;
    if (! (expected instanceof Array)) {
      msg = fmt("$expected instanceof Array : failed.\n  $expected: %r", expected);
      throw this.failed(msg);
    }
    if (! (actual instanceof Array)) {
      msg = fmt("$actual instanceof Array : failed.\n  $actual  : %r", actual);
      throw this.failed(msg);
    }
    if (actual.length !== expected.length) {
      msg = fmt("$actual.length === $expected.length : failed.\n  $actual.length  : %r\n  $expected.length: %r",
                actual.length, expected.length);
      throw this.failed(msg);
    }
    for (var i = 0, n = expected.length; i < n; i++) {
      if (actual[i] !== expected[i]) {
        msg = fmt("$actual[%s] === $expected[%s] : failed.\n  $actual[%s]  : %r\n  $expected[%s]: %r",
                  i, i, i, actual[i], i, expected[i]);
        throw this.failed(msg);
      }
    }
    return this;
  };

  def.inDelta = function inDelta(expected, delta) {
    this._done = true;
    var ao = oktest.assertion._ok(this.actual, undefined, undefined, this.bool);
    ao.gt(expected - delta);
    ao.lt(expected + delta);
    return this;
  };

  def.isa = function isa(expected) {
    return this._cmp("instanceof", expected, this.actual instanceof expected);
  };

  def.inObject = function inObject(expected) {
    return this._cmp("in", expected, this.actual in expected);
  };

  def.inArray = function inArray(expected) {
    this._done = true;
    var arr = expected;
    for (var i = 0, n = arr.length; i < n; i++) {
      if (this.actual === arr[i]) break;
    }
    var found = i < n;
    return this._cmp("exists in", expected, found);
  };

  def.hasAttr = function hasAttr(name, value) {
    this._done = true;
    var msg, bool = name in this.actual;
    if (bool !== this.bool) {
      if (! this.bool) return this;
      msg = fmt("%s%r in $actual : failed.\n  $actual  : %r",
                this._prefix(), name, this.actual);
      throw this.failed(msg, name, "in");
    }
    if (arguments.length >= 2) {
      bool = this.actual[name] === value;
      if (bool !== this.bool) {
        msg = fmt("%s$actual.%s === $expected : failed.\n  $actual.%s: %r\n  $expected: %r",
                  this._prefix(), name, name, this.actual[name], value);
        throw this.failed(msg, name, "===");
      }
    }
    return this;
  };

//  def.attr = function attr(name, value) {
//    oktest.ok(this.actual).hasAttr(name);
//    var bool = this.actual[name] === value;
//    if (bool === this.bool) return this;
//    var op = "===";
//    //var msg = this._prefix() + "$expected " + op + " $actual : failed.";
//    var msg = this._prefix() + "$actual." + name + " " + op + " $expected : failed.\n"
//            + "  $actual." + name + ": " + util.inspect(this.actual[name]) + "\n"
//            + "  $expected: " + util.inspect(value);
//    this.actual = this.actual[name];
//    this.failed(msg, value, op);
//    return "--unreachable--";
//  };

  def.match = function match(rexp) {
    this._done = true;
    var bool = !! this.actual.match(rexp);
    if (bool === this.bool) return this;
    var msg = fmt("%s$actual.match(%s) : failed.\n  $actual  : %r",
                  this._prefix(), rexp, this.actual);
    throw this.failed(msg, rexp, 'match');
  };

  def.length = function length(expected) {
    this._done = true;
    var bool = this.actual.length === expected;
    if (bool === this.bool) return this;
    var msg = fmt("%s$actual.length === %d : failed.\n  $actual  : %r",
                  this._prefix(), expected, this.actual);
    throw this.failed(msg, expected, '===');
  };

  def.throws_ = function throws_(errclass, errmsg) {
    this._done = true;
    if (! this.bool) throw new Error("throws_() is not available with NG().");
    var classname = typeof(errclass) === "function" ? errclass.name : String(errclass);
    var exception = null;
    try {
      this.actual();
    }
    catch (ex) {
      exception = ex;
      this.actual.exception = ex;
      if (! (ex instanceof errclass)) {
        var msg = fmt("%s expected but got %s.\n  $exception  : %r",
                      classname, ex.name, ex);
        this.actual = ex;
        throw this.failed(msg, errclass);
      }
      if (errmsg) {
        var matched = errmsg instanceof RegExp
                      ? !! errmsg.exec(ex.message)
                      : errmsg === ex.message;
        if (! matched) {
          var msg2 = fmt("error message is not matched.\n  $actual  : %r\n  $expected: %r",
                         ex.message, errmsg);
          this.actual = ex.messge;
          throw this.failed(msg2, errmsg, "===");
        }
      }
    }
    if (exception === null) {
      throw this.failed(classname+" expected but not thrown.");
    }
    return this;
  };

  def['throws'] = def.throws_;

  def.notThrow = function notThrow(errclass) {
    this._done = true;
    if (! this.bool) throw new Error("notThrow() is not available with NG().");
    var classname = typeof(errclass) === "function" ? errclass.name : String(errclass);
    try {
      this.actual();
    }
    catch (ex) {
      var msg = null;
      if (! errclass) {
        msg = fmt("Nothing should be thrown, but got %s.\n  $exception: %r", ex.name, ex);
      }
      else if (ex instanceof errclass) {
        msg = fmt("%s is unexpected, but thrown.\n  $exception: %r", classname, ex);
      }
      if (msg) throw this.failed(msg);
    }
    return this;
  };

  def._fscmp = function _fscmp(funcname, cmpfunc) {
    this._done = true;
    var msg;
    var fstat = oktest.util.fstat(this.actual);
    if (! fstat) {  /// when not exist
      if (this.bool) {
        msg = fmt("%s($actual) : failed, not exist.\n  $actual  : %r",
                  funcname, this.actual);
        throw this.failed(msg);
      }
    }
    else {  /// when exists
      var bool = cmpfunc(fstat);
      if (bool !== this.bool) {
        msg = fmt("%s%s($actual) : failed.\n  $actual  : %r",
                  this._prefix(), funcname, this.actual);
        throw this.failed(msg);
      }
    }
    return this;
  };

  def.isFile = function isFile() {
    return this._fscmp("isFile", function(fstat) { return fstat.isFile(); });
  };

  def.isDirectory = function isDirectory() {
    return this._fscmp("isDirectory", function(fstat) { return fstat.isDirectory(); });
  };

  def.exists = function exists() {
    if (! this.bool) return this.notExist();
    this._done = true;
    var fstat = oktest.util.fstat(this.actual);
    if (fstat) return this;
    var msg = "$actual should exist, but not.\n"
            + "  $acutal  : " + util.inspect(this.actual);
    throw this.failed(msg);
  };

  def.notExist = function notExist() {
    if (! this.bool) return this.exists();
    this._done = true;
    var fstat = oktest.util.fstat(this.actual);
    if (! fstat) return this;
    var msg = "$actual expected not exist, ";
    if      (fstat.isFile())       msg += "but is a file.\n";
    else if (fstat.isDirectory())  msg += "but is a directory.\n";
    else                           msg += "but exists.\n";
    msg += "  $actual  : " + util.inspect(this.actual);
    throw this.failed(msg);
  };


  def._typecmp = function _typecmp(expected) {
    this._done = true;
    var bool = typeof(this.actual) === expected;
    if (bool === this.bool) return this;
    var msg = fmt("%stypeof($actual) === %r : failed.\n  $actual  : %r",
                  this._prefix(), expected, this.actual);
    this.actual = typeof(this.actual);
    throw this.failed(msg, expected, 'typeof');
  };

  def.isString    = function isString()   { return this._typecmp('string');    };
  def.isNumber    = function isNumber()   { return this._typecmp('number');    };
  def.isBoolean   = function isBoolean()  { return this._typecmp('boolean');   };
  def.isUndefined = function isUnefined() { return this._typecmp('undefined'); };
  def.isObject    = function isObject()   { return this._typecmp('object');    };
  def.isFunction  = function isFunction() { return this._typecmp('function');  };


  def.all = function all() {
    this._done = true;
    return new oktest.assertion.AssertionArray(this.actual, this.bool);
  };

})(oktest.assertion.AssertionObject.prototype);


oktest.assertion.AssertionArray = function AssertionArray(array, bool) {
  this.array = array;
  this.bool  = bool;
};

oktest.assertion.AssertionArray._methodFactory = function _methodFactory(methodName) {
  return function () {
    try {
      for (var i = 0, n = this.array.length; i < n; i++) {
        var assObj = this.bool ? oktest.ok (this.array[i]) : oktest.NG(this.array[i]);
        var method = assObj[methodName];
        method.apply(assObj, arguments);
      }
    }
    catch (ex) {
      if (ex instanceof assert.AssertionError) {
        ex.message = "[index="+i+"] "+ex.message;
      }
      throw ex;
    }
    return this;
  };
};

(function(def) {

  var methodNames = [
    "eq", "ne", "is", "isNot", "gt", "ge", "lt", "le",
    "deepEqual", "notDeepEqual",
    "inDelta", "isa", "inObject", "inArray", "hasAttr", "match", "length",
    "throws_", "throws", "notThrow",
    "isFile", "isDirectory", "exists", "notExist",
    "isString", "isNumber", "isBoolean", "isUndefined", "isObject", "isFunction"
  ];
  var methodFactory = oktest.assertion.AssertionArray._methodFactory;
  for (var i = 0, n = methodNames.length; i < n; i++) {
    var methodName = methodNames[i];
    def[methodName] = methodFactory(methodName);
  }

})(oktest.assertion.AssertionArray.prototype);


oktest.assertion._op2method = {
  "=="   :  "eq",
  "!="   :  "ne",
  "==="  :  "is",
  "!=="  :  "isNot",
  ">"    :  "gt",
  ">="   :  "ge",
  "<"    :  "lt",
  "<="   :  "le"
};


oktest.ok = function ok(actual, op, expected) {
  return oktest.assertion._ok(actual, op, expected, true);
};

oktest.NG = function NG(actual, op, expected) {
  return oktest.assertion._ok(actual, op, expected, false);
};

oktest.NOT = function NOT(actual, op, expected) {
  return oktest.assertion._ok(actual, op, expected, false);
};

oktest.precond = function precond(actual, op, expected) {
  return oktest.assertion._ok(actual, op, expected, true);
};

oktest.assertion._ok = function _ok(actual, op, expected, bool) {
  var klass = oktest.assertion.AssertionObject;
  var assObj = new klass(actual, bool);
  try {
    throw new Error();
  }
  catch (ex) {
    var m = ex.stack.match(/^Error\n    at .*\n    at .*\n    at .* \((.*):(\d+):(\d+)/);
    if (m) {
      var filename = m[1];
      var shared = oktest._sharedFilenames;
      if (! (filename in shared)) shared[filename] = filename;
      assObj._file   = shared[filename];
      assObj._line   = parseInt(m[2]);
      assObj._column = parseInt(m[3]);
    }
    else {
      assObj._file = assObj._line = assObj._column = null;
    }
  }
  oktest.assertion._objects.push(assObj);
  if (op === undefined) return assObj;
  if (! (op in oktest.assertion._op2method)) {
    throw new Error("'"+op+"': unknown comparison operator.");
  }
  var methodName = oktest.assertion._op2method[op];
  var method = assObj[methodName];
  return method.apply(assObj, [expected]);
};

oktest._sharedFilenames = {};

oktest.assertion._objects = [];

oktest.assertion._checkDone = function _checkDone() {
  var objects = oktest.assertion._objects;
  var n = objects.length;
  while (--n >= 0) {
    var obj = objects.pop();
    if (! obj._done) {
      if (obj._file && obj._line) {
        console.warn("warning: ok() is called but not testd (file '"+obj._file+"', line "+obj._line+")");
      }
    }
  }
};

oktest.assertion.register = function register(name, func) {
  oktest.assertion.AssertionObject.prototype[name] = function() {
    this._done = true;
    var args = [this.bool, this.actual];
    for (var i = 0, n = arguments.length; i < n; i++) {
      args.push(arguments[i]);
    }
    var errmsg = func.apply(this, args);
    if (errmsg) {
      throw this.failed(errmsg);
    }
    return this;
  };
};


///
/// core module (test, topic, and spec object)
///

oktest.core = {
};


oktest.core.TestObject = function TestObject() {
  this._topics = [];
  this._stack = [];
  var self = this;
  this.topic = function topic(desc, func)       { return self._topic(desc, func); };
  this.spec  = function spec (desc, opts, func) { return self._spec (desc, opts, func); };
  this.run   = function run  (opts)             { return self._run  (opts); };
};

(function(def) {

  def.onTopLevel = function onTopLevel() {
    return this._stack.length === 0;
  };

  def.addTopLevel = function addTopLevel(topic_obj) {
    this._topics.push(topic_obj);
  };

  def.currentTopic = function currentTopic() {
    var stack = this._stack;
    return stack.length ? stack[stack.length-1] : null;
  };

  def.invokeTopicBody = function invokeTopicBody(topic_obj, func) {
    var to = topic_obj;
    this._stack.push(to);
    //(func || to.body).apply(this, [to]);
    (func || to.body).apply(topic_obj, [to]);
    var popped = this._stack.pop();
    assert.ok(popped === to);
  };

  def._topic = function _topic(desc, func) {
    var engine = this;
    var to = new oktest.core.TopicObject(desc, func);
    if (engine.onTopLevel()) {
      engine.addTopLevel(to);
    }
    else {
      assert.ok(engine.currentTopic() != null);
      engine.currentTopic().addChild(to);
    }
    engine.invokeTopicBody(to, func);
    return to;
  };

  def._spec = function _spec(desc, opts, func) {
    var engine = this;
    if (engine.onTopLevel()) {
      throw new Error("spec() is not available without topic().");
    }
    var so = new oktest.core.SpecObject(desc, opts, func);
    assert.ok(engine.currentTopic() != null);
    engine.currentTopic().addChild(so);
    return so;
  };

  def._run = function _run(opts) {
    var engine = this;
    if (! opts) opts = {};
    var style  = oktest.config.style;
    if (opts.style) style = opts.style;
    var klass = oktest.reporter.getRegisteredClass(style);
    if (! klass) throw Error("'"+style+"': unknown style.");
    var reporter = new klass();
    if (opts.out) reporter.out = opts.out;
    if ('color' in opts && typeof(opts.color) === 'boolean') {
      reporter.enableColor(opts.color);
    }
    var filter = opts.filter ? opts.filter : {};
    var runner = new oktest.runner.TestRunner(reporter, {filter:filter});
    //
    reporter.onStart();
    for (var i = 0, n = engine._topics.length; i < n; i++) {
      var to = engine._topics[i];
      runner.run(to);
    }
    reporter.onStop();
    oktest.assertion._checkDone();
    var counts = reporter.counts;
    return counts['failed'] + counts['error'];
  };

})(oktest.core.TestObject.prototype);


oktest.core.TopicObject = function TopicObject(desc, body) {
  this.desc = desc;
  this.body = body;
  this.parent = null;
  this.children = [];
};

(function(def) {

  def.addChild = function addChild(to) {
    this.children.push(to);
    to.parent = this;
    return this;
  };

  def.accept = function accept(runner) {
    return runner.runTopic(this);
  };

})(oktest.core.TopicObject.prototype);


oktest.core.SpecObject = function SpecObject(desc, opts, body) {
  if (typeof(opts) === "function") {
    body = opts;
    opts = null;
  }
  this.desc = desc;
  this.opts = opts;
  this.body = body;
  this.parent = null;
};

(function(def) {

  def.accept = function accept(runner) {
    return runner.runSpec(this);
  };

})(oktest.core.SpecObject.prototype);


oktest.create = function() {
  return new oktest.core.TestObject();
};


oktest.shared = new oktest.core.TestObject();
oktest.topic  = oktest.shared.topic;
oktest.spec   = oktest.shared.spec;
oktest.run    = oktest.shared.run;


///
/// fixture
///

oktest.fixture = {
};


oktest.fixture.FixtureManager = function FixtureManager() {
  this.providers = {};
  this.releasers = {};
};

(function(def) {

  def.provide = function provide(name) {
    if (name in this.providers) {
      return this.providers[name]();
    }
    var provider_name = "provide" + oktest.util.capitalize(name);
    throw new Error(name+": fixture provider ("+provider_name+"()) not found.");
  };

  def.release = function release(name, value) {
    if (name in this.releasers) {
      this.releasers[name](value);
    }
  };

})(oktest.fixture.FixtureManager.prototype);

oktest.fixture.manager = new oktest.fixture.FixtureManager();


oktest.fixture.FixtureInjector = function FixtureInjector() {
};

(function(def) {

  def._argnames = function _argnames(func) {
    var m = func.toString().match(/\((.*?)\)/);
    var argStr = oktest.util.strip(m[1]);
    return argStr ? argStr.split(/\s*,\s*/) : null;
  };

  def._init = function _init(object, method, opts) {
    this.object = object;
    this.method = method;
    this.opts   = opts;
    this.releasers = { self: null };         // {"arg_name": releaser_func()}
    this.resolved  = { self: this.object };  // {"arg_name": arg_value}
    if (opts) {
      for (var p in opts) this.resolved[p] = opts[p];
    }
    this.in_progress = [];
  };

  def._resolve = function _resolve(arg_name) {
    var aname = arg_name;
    if (! (aname in this.resolved)) {
      if (aname[0] === "_") {
        return undefined;
      }
      var pair = this.find(aname, this.object);
      if (pair) {
        var provider = pair[0], releaser = pair[1];
        this.resolved[aname] = this._call(provider, aname);
        this.releasers[aname] = releaser;
      }
      else {
        this.resolved[aname] = oktest.fixture.manager.provide(aname);
      }
    }
    return this.resolved[aname];
  };

  def._call = function _call(provider, resolving_arg_name) {
    var arg_names = this._argnames(provider);
    if (! arg_names) return provider.apply(this.object);
    this.in_progress.push(resolving_arg_name);
    var arg_values = [];
    for (var i = 0, n = arg_names.length; i < n; i++) {
      arg_values.push(this._getValue(arg_names[i]));
    }
    var popped = this.in_progress.pop(resolving_arg_name);
    assert.ok(popped === resolving_arg_name);
    return provider.apply(this.object, arg_values);
  };

  def._getValue = function _getValue(arg_name) {
    if (arg_name in this.resolved) {
      return this.resolved[arg_name];
    }
    for (var i = 0, n = this.in_progress.length; i < n; i++) {
      if (this.in_progress[i] === arg_name) {
        throw this._loopedDependencyError(arg_name, this.in_progress, this.object);
      }
    }
    return this._resolve(arg_name);
  };

  def.invoke = function invoke(object, method, opts) {
    method = typeof(method) === "string" ? object[method] : method;
    var arg_names = this._argnames(method);
    if (! arg_names) {
      return method.apply(object);
    }
    //
    this._init(object, method, opts);
    //
    var fixtures = [];
    for (var j = 0, len = arg_names.length; j < len; j++) {
      fixtures.push(this._resolve(arg_names[j]));
    }
    assert.ok(this.in_progress.length === 0);
    try {
      return method.apply(object, fixtures);
    }
    finally {
      this._releaseFixtures(this.resolved, this.releasers, object);
    }
  };

  def._releaseFixtures = function _releaseFixtures(resolved, releasers, object) {
    for (var name in resolved) {
      if (name in releasers) {
        var releaser = releasers[name];
        if (releaser) releaser.apply(object, [resolved[name]]);
      }
      else {
        oktest.fixture.manager.release(name, resolved[name]);
      }
    }
  };

  def.find = function find(name, object) {
    assert.ok(object instanceof oktest.core.SpecObject);
    var to = object.parent; // topic object
    assert.ok(to instanceof oktest.core.TopicObject);
    var capitalized = name[0].toUpperCase() + name.substr(1);
    var provider_name = this._methodName(name, 'provide');
    var releaser_name = this._methodName(name, 'release');
    while (to) {
      if (provider_name in to) {
        var provider = to[provider_name];
        var releaser = releaser_name in to ? to[releaser_name] : null;
        return [provider, releaser];
      }
      to = to.parent;
    }
    return null;
  };

  def._methodName = function _methodName(name, prefix) {
    //return prefix + '_' + name;
    var capitalized = name[0].toUpperCase() + name.substr(1);
    return prefix + capitalized;
  };

  def._loopedDependencyError = function _loopedDependencyError(aname, in_progress, object) {
    var names = in_progress.concat([aname]);
    var pos   = oktest.util.index(names, aname);
    var loop  = names.slice(pos).join('=>');
    if (pos > 0) loop = names.slice(0, pos).join('->') + '->' + loop;
    assert.ok(object instanceof oktest.core.SpecObject);
    var spec_desc  = object.desc;
    var topic_desc = object.parent.desc;
    //return new oktest.fixture.LoopedDependencyError("fixture dependency is looped: "+loop+" (topic: "+topic_desc+", spec: "+spec_desc+")");
    return new Error("fixture dependency is looped: "+loop+" (topic: "+topic_desc+", spec: "+spec_desc+")");
  };

})(oktest.fixture.FixtureInjector.prototype);

oktest.fixture.invoke = function invoke(object, method, opts) {
  var injector = new oktest.fixture.FixtureInjector();
  return injector.invoke(object, method, opts);
};


//oktest.fixture.LoopedDependencyError = function LoopedDependencyError() {};
//oktest.fixture.LoopedDependencyError.prototype = {};//new Error('xxx');
//oktest.fixture.LoopedDependencyError = function LoopedDependencyError() {};
//oktest.fixture.LoopedDependencyError.prototype = Error.prototype;
//oktest.LoopedDependencyError = function LoopedDependencyError() {};
//oktest.LoopedDependencyError.prototype = new Error();


oktest.fixture.Cleaner = function Cleaner() {
  this.items = [];
};

(function(def) {

  def.add = function add() {
    for (var i = 0, n = arguments.length; i < n; i++) {
      var arg = arguments[i];
      if (! arg) {
        // pass
      } else if (arg.constructor === Array) {
        Array.prototype.push.apply(this.items, arg);
      }
      else {
        this.items.push(arg);
      }
    }
  };

  def.clean = function clean() {
    var rm_rf = oktest.util.rm_rf;
    for (var i = 0, n = this.items.length; i < n; i++) {
      var path = this.items[i];
      rm_rf(path);
    }
  };

})(oktest.fixture.Cleaner.prototype);

oktest.fixture.manager.providers['cleaner'] = function provideCleaner() {
  return new oktest.fixture.Cleaner();
};

oktest.fixture.manager.releasers['cleaner'] = function releaseCleaner(value) {
  assert.ok(value instanceof oktest.fixture.Cleaner);
  var cleaner = value;
  cleaner.clean();
};


///
/// test runner
///

oktest.runner = {
};


oktest.runner.Runner = function Runner() {
};

(function(def) {

  def.run = function run(topicOrSpec) {
    topicOrSpec.accept(this);
  };

  def.runTopic = function runTopic(topicObj) {};
  def.runSpec = function runSpec(specObj) {};

})(oktest.runner.Runner.prototype);


oktest.runner.TestRunner = function TestRunner(reporter, opts) {
  if (! opts) opts = {};
  this.reporter = reporter;
  this.filter   = opts.filter   ? opts.filter   : {};
  var fil = this.filter;
  fil._topicRexp = fil.topic ? oktest.util.patternOrRexp(fil.topic) : null;
  fil._specRexp  = fil.spec  ? oktest.util.patternOrRexp(fil.spec)  : null;
};

oktest.runner.TestRunner.prototype = new oktest.runner.Runner();

(function(def) {

  def.runTopic = function runTopic(to) {
    to._ignored = this.filter._topicRexp
                  ? ! to.desc.match(this.filter._topicRexp)
                  : false;
    this.reporter.onEnterTopic(to);
    try {
      if (to.beforeAll) to.beforeAll();
      for (var i = 0, n = to.children.length; i < n; i++) {
        //this.run(to.children[i]);
        to.children[i].accept(this);
      }
    }
    finally {
      if (to.afterAll) to.afterAll();
    }
    this.reporter.onExitTopic(to);
  };

  def.runSpec = function runSpec(so) {
    if (so.parent._ignored) return;
    if (this.filter._specRexp) {
      var matched = so.desc.match(this.filter._specRexp);
      if (! matched) return;
    }
    this.reporter.onEnterSpec(so);
    var status = 'passed', exception = null;
    try {
      try {
        this._invokeBefore(so.parent);  // so.parent is a TopicObject
        this._invokeWithFixtures(so);
      }
      finally {
        this._invokeAfter(so.parent);  // so.parent is a TopicObject
      }
    }
    catch (ex) {
      exception = ex;
      if      (ex instanceof assert.AssertionError)        status = 'failed';
      else if (ex.name === 'oktest.runner.SkipException')  status = 'skipped';
      else                                                 status = 'error';
    }
    this.reporter.onExitSpec(so, status, exception);
  };

  def._invokeBefore = function _invokeBefore(to) {
    if (to.parent) this._invokeBefore(to.parent);
    if (to.before) to.before();
  };

  def._invokeAfter = function _invokeAfter(to) {
    if (to.after) to.after();
    //if (to.parent) this._invokeAfter(to.parent);
    while ((to = to.parent)) if (to.after) to.after();
  };

  def._invokeWithFixtures = function _invokeWithFixtures(so) {
    return oktest.fixture.invoke(so, so.body, so.opts);
  };

})(oktest.runner.TestRunner.prototype);


///
/// skip
///

//// not work. give up...
//oktest.runner.SkipException = function SkipException(reason) {
//  Error.apply(this, [reason]);
//};
//oktest.runner.SkipException.prototype = new Error();
//oktest.runner.SkipException.prototype.constructor = oktest.runner.SkipException;
//oktest.runner.SkipException.prototype.name = "SkipException";
//var ctor = function () { this.constructor = oktest.runner.SkipException; };
//ctor.prototype = Error.prototype;
//oktest.runner.SkipException.prototype = new ctor();

oktest.skip = function skip(reason) {
  var ex = new Error(reason);
  ex.name = 'oktest.runner.SkipException';
  ex.reason = reason;
  throw ex;
};

oktest.skipWhen = function skipWhen(condition, reason) {
  if (condition) throw oktest.skip(reason);
};


///
/// reporter
///

oktest.reporter = {
};


oktest.reporter.Reporter = function Reporter() {
};

(function(def) {

  def.onStart      = function onStart() {};
  def.onStop       = function onStop() {};
  def.onEnterTopic = function onEnterTopic(to) {};
  def.onExitTopic  = function onExitTopic(to) {};
  def.onEnterSpec  = function onEnterSpec(so) {};
  def.onExitSpec   = function onExitSpec(so, status, exception) {};

})(oktest.reporter.Reporter.prototype);


oktest.reporter.BaseReporter = function BaseReporter(opts) {
  if (! opts) opts = {};
  this.out = opts.out ? opts.out : process.stdout;
  var flag_color = "color" in opts ? opts.color : null;
  if (flag_color == null) {
    flag_color = oktest.config.color_available && this._isatty();
  }
  this.enableColor(flag_color);
};
oktest.reporter.BaseReporter.prototype = new oktest.reporter.Reporter();

(function(def) {

  def.separator = "----------------------------------------------------------------------";

  def.onStart = function onStart() {
    this.counts = {total:0, passed:0, failed:0, error:0, skipped:0};
    this._depth = -1;
    this._tuples_stack = [];
    this._prev = null;
    this._linecache = new oktest.util.LineCache();
    this._start = new Date();
  };

  def.onStop = function onStop() {
    this.newline();
    var msec = (new Date()) - this._start;
    this.echo("## " + this._counts2str(this.counts) +
              "  (in " + oktest.util.msec2str(msec) + "s)");
  };

  def.onEnterTopic = function onEnterTopic(to) {
    this._depth++;
    this._indent = oktest.util.repeat("  ", this._depth);
    this._tuples_stack.push([]);
  };

  def.onExitTopic  = function onExitTopic(to) {
    this._depth--;
    this._indent = oktest.util.repeat("  ", this._depth);
    var tuples = this._tuples_stack.pop();
    if (tuples.length) {
      this.printStartSeparator();
      for (var i = 0, n = tuples.length; i < n; i++) {
        var so = tuples[i][0];
        var ex = tuples[i][1];
        this.printException(so, ex);
      }
      this.printEndSeparator();
    }
  };

  def.onEnterSpec  = function onEnterSpec(so) {
    this.counts.total++;
  };

  def.onExitSpec   = function onExitSpec(so, status, exception) {
    this.counts[status]++;
    if (exception) {
      var tuples = this._tuples_stack[this._tuples_stack.length - 1];
      if (exception instanceof Array) {
        var arr = exception;
        for (var i = 0, n = arr.length; i < n; i++) {
          if (arr[i].name !== 'oktest.runner.SkipException') {
            tuples.push([so, arr[i]]);
          }
        }
      }
      else {
        if (exception.name !== 'oktest.runner.SkipException') {
          tuples.push([so, exception]);
        }
      }
    }
  };

  //
  def.echo = function echo(arg) {
    this.write(arg);
    if (arg && ! arg.match(/\n$/)) {
      this.write("\n");
    }
  };

  def.write = function write(arg) {
    if (arg) {
      this.out.write(arg);
      this._prev = arg;
    }
  };

  def.newline = function newline(args) {
    if (this._prev && ! this._prev.match(/\n$/)) {
      this.write("\n");
    }
  };

  def._counts2str = function _counts2str(counts) {
    var buf = [];
    buf.push("total:"+counts.total);
    var statuses = ["passed", "failed", "error", "skipped"];
    for (var i = 0, st; st = statuses[i]; i++) {
      var s = st + ":" + counts[st];
      buf.push(counts[st] ? this.colorize[st](s) : s);
    }
    //var c = this.colorize, d = counts;
    //s = "passed:" +d.passed;  buf.push(d.passed  ? c.passed (s) : s);
    //s = "failed:" +d.failed;  buf.push(d.failed  ? c.failed (s) : s);
    //s = "error:"  +d.error;   buf.push(d.error   ? c.error  (s) : s);
    //s = "skipped:"+d.skipped; buf.push(d.skipped ? c.skipped(s) : s);
    return buf.join(", ");
  };

  def.enableColor = function enableColor(flag) {
    this.colorize = flag === false ? oktest.util.Color.newMonoTable()
                                   : oktest.util.Color.newColorTable();
    this.colorEnabled = flag !== false;
  };

  def._indicators = {
    passed: "ok", failed: "Failed", error: "ERROR", skipped: "skipped"
  };

  def._statusChars = {
    passed: ".", failed: "f", error: "E", skipped: "s"
  };

  def.indicator = function indicator(status) {
    return this.colorize[status](this._indicators[status]);
  };

  def.statusChar = function statusChar(status) {
    var ch = this._statusChars[status];
    return status === 'passed' ? ch : this.colorize[status](ch);
  };

  def.printStartSeparator = function printStartSeparator() {
    this.newline();
    //this.echo(this.colorize.separator(this.separator));
  };

  def.printEndSeparator = function printStartSeparator() {
    this.newline();
    this.echo(this.colorize.separator(this.separator));
  };

  def.printException = function printException(so, ex) {
    this.echo(this.colorize.separator(this.separator));
    this.printExceptionHeader(so, ex);
    this.printExceptionStack(so, ex);
  };

  def.printExceptionHeader = function printExceptionHeader(so, ex) {
    var items = [];
    var obj = so;
    while (obj) {
      items.push(obj.desc);
      obj = obj.parent;
    }
    var title = items.reverse().join(" > ");
    var c = this.colorize;
    var status = ex instanceof assert.AssertionError ? 'failed' : 'error';
    this.echo("[" + this.indicator(status) + "] " + title);
  };

  def.printExceptionStack = function printExceptionStack(so, ex) {
    var str = ex.stack;
    if (! oktest.config.debug) {
      str = str.replace(/^    at .*\boktest\.js:\d+.*(\n|$)/gm, '');
      str = str.replace(/^(    at) SpecObject\.body /gm, '$1 spec ');
    }
    var lines = str.split(/^/mg);
    for (var i = 0, n = lines.length; i < n; i++) {
      var line = lines[i];
      if (i === 0) {
        this.write(this.colorize.failed(line.replace(/\n$/, '')) + "\n");
      }
      else {
        this.write(line);
      }
      var m = line.match(/^    at .* \((.*):(\d+):\d+\)/);
      if (! m) continue;
      var filepath = m[1], linenum = parseInt(m[2]);
      var linestr = this._linecache.fetch(filepath, linenum);
      this.echo('        ' + oktest.util.strip(linestr || ''));
    }
  };

  def._isatty = function _isatty() {
    return this.out.fd && tty.isatty(this.out.fd);
  };

})(oktest.reporter.BaseReporter.prototype);


oktest.reporter.VerboseReporter = function VerboseReporter() {
};
oktest.reporter.VerboseReporter.prototype = new oktest.reporter.BaseReporter();

(function(def) {

  def._super = oktest.reporter.BaseReporter.prototype;

  def.onEnterTopic = function onEnterTopic(to) {
    this._super.onEnterTopic.apply(this, [to]);
    this.printTopic(to);
  };

  def.onEnterSpec  = function onEnterSpec(so) {
    this._super.onEnterSpec.apply(this, [so]);
    if (this.colorEnabled && this._isatty()) {
      this.write(this._indent + "  - [  ] " + so.desc);
    }
  };

  def._eraser = oktest.util.repeat("\b\b\b\b\b\b\b\b\b\b\b", 25);

  def.onExitSpec   = function onExitSpec(so, status, exception) {
    if (this.colorEnabled && this._isatty()) {
      this.write(this._eraser);
    }
    this._super.onExitSpec.apply(this, [so, status, exception]);
    this.printSpec(so, status, exception);
  };

  def.printTopic = function printTopic(to) {
    this.echo(this._indent + "* " + this.colorize.subject(to.desc));
  };

  def.printSpec = function printSpec(so, status, exception) {
    var s = status == 'skipped' ? " (reason: " + exception.reason + ")" : "";
    this.echo(this._indent + "  - [" + this.indicator(status) + "] " + so.desc + s);
  };

})(oktest.reporter.VerboseReporter.prototype);


oktest.reporter.SimpleReporter = function SimpleReporter() {
};
oktest.reporter.SimpleReporter.prototype = new oktest.reporter.BaseReporter();

(function(def) {

  def._super = oktest.reporter.BaseReporter.prototype;

  def.onEnterTopic = function onEnterTopic(to) {
    this.newline();
    this._super.onEnterTopic.apply(this, [to]);
    this.printTopic(to);
  };

  def.onExitSpec   = function onExitSpec(so, status, exception) {
    this._super.onExitSpec.apply(this, [so, status, exception]);
    this.printSpec(so, status);
  };

  def.printTopic = function printTopic(to) {
    this.write(this._indent + "* " + this.colorize.subject(to.desc) + ": ");
  };

  def.printSpec = function printSpec(so, status) {
    this.write(this.statusChar(status));
  };

})(oktest.reporter.SimpleReporter.prototype);


oktest.reporter.PlainReporter = function PlainReporter() {
};
oktest.reporter.PlainReporter.prototype = new oktest.reporter.BaseReporter();

(function(def) {

  def._super = oktest.reporter.BaseReporter.prototype;

  def.onExitSpec   = function onExitSpec(so, status, exception) {
    this._super.onExitSpec.apply(this, [so, status, exception]);
    this.printSpec(so, status);
  };

  def.printSpec = function printSpec(so, status) {
    this.write(this.statusChar(status));
  };

})(oktest.reporter.PlainReporter.prototype);


oktest.reporter._reporterClasses = {
  verbose: oktest.reporter.VerboseReporter,
  simple:  oktest.reporter.SimpleReporter,
  plain:   oktest.reporter.PlainReporter
};

oktest.reporter.getRegisteredClass = function getRegisteredClass(style) {
  return (style in oktest.reporter._reporterClasses)
         ? oktest.reporter._reporterClasses[style]
         : null;
};


///
/// tracer
///

oktest.tracer = {

  create: function create() {
    return new oktest.tracer.Tracer();
  }

};


oktest.tracer.Tracer = function Tracer() {
  this.called = [];
};

(function(def) {

  def.trace = function trace(object, method_names) {
    var called = this.called;
    var obj = arguments[0];
    function newfunc(called, obj, meth_name, meth) {
      return function() {
        var args = Array.prototype.slice.call(arguments);
        var record = {object: obj, name: meth_name, args: args, ret: undefined };
        called.push(record);
        var ret = meth.apply(obj, args);
        record.ret = ret;
        return ret;
      };
    }
    for (var i = 1, n = arguments.length; i < n; i++) {
      var meth_name = arguments[i];
      var meth = obj[meth_name];
      obj[meth_name] = newfunc(called, obj, meth_name, meth);
    }
  };

  def.dummy = function dummy(object, dummy_values) {
    function newfunc(called, obj, meth_name, value) {
      return function() {
        var args = Array.prototype.slice.call(arguments);
        var record = {object: obj, name: meth_name, args: args, ret: value };
        called.push(record);
        return value;
      };
    }
    for (var meth_name in dummy_values) {
      var ret_val = dummy_values[meth_name];
      object[meth_name] = newfunc(this.called, object, meth_name, ret_val);
    }
  };

  def.fake = function fake(dummy_values) {
    var obj = {};
    this.dummy(obj, dummy_values);
    return obj;
  };

  // (DEPRECATED) intercept, steal, proxy, hookup, ...
  def.intercept = function intercept(object, functions) {
    function newfunc(called, obj, meth_name, meth_func, original) {
      return function() {
        var args = Array.prototype.slice.call(arguments);
        var record = {object: obj, name: meth_name, args: args, ret: undefined };
        called.push(record);
        record.ret = meth_func.apply(obj, [original].concat(args));
        return record.ret;
      };
    }
    for (var meth_name in functions) {
      var meth_func = functions[meth_name];
      var original = object[meth_name];
      object[meth_name] = newfunc(this.called, object, meth_name, meth_func, original);
    }
  };

  def.traceFunc = function traceFunc(func, name) {
    var called = this.called;
    var obj = arguments[0];
    function newfunc(called, func, name) {
      return function() {
        var args = Array.prototype.slice.call(arguments);
        var record = {object: null, name: name, args: args, ret: undefined};
        called.push(record);
        record.ret = func.apply(null, args);  // or apply(this, args)?
        return record.ret;
      };
    }
    if (! name) name = func.name;
    return newfunc(this.called, func, name);
  };


})(oktest.tracer.Tracer.prototype);


///
/// template
///
oktest.TEMPLATE = (""
      //|"use strict";
      //|//require.paths.push(".");   // or export $NODE_PATH=$PWD
      //|var oktest = require("oktest");
      //|var topic   = oktest.topic,
      //|    spec    = oktest.spec,
      //|    ok      = oktest.ok,
      //|    NG      = oktest.NG,
      //|    precond = oktest.precond;
      //|
      //|
      //|+ topic("ClassName", function() {
      //|
      //|    + topic(".methodName()", function() {
      //|
      //|        - spec("description #1", function() {
      //|              ok (1+1).is(2);
      //|              ok (1+1, '===', 2);
      //|          });
      //|
      //|        - spec("throws Error with error message", function() {
      //|              function fn() { throw new Error("errmsg"); };
      //|              ok (fn).throws_(Error, "errmsg");  // or ok (fn).throws(...)
      //|              ok (fn.exception.message).match(/errmsg/);
      //|          });
      //|
      //|        /// fixture injection example
      //|
      //|        this.provideYuki   = function() { return "Humanoid Interface"; };
      //|        this.provideMikuru = function() { return "Time Traveler"; };
      //|
      //|        - spec("Yuki is a humanoid interface", function(yuki) {
      //|              ok (yuki).is("Humanoid Interface");
      //|          });
      //|        - spec("Mikuru is a time traveler", function(mikuru) {
      //|              ok (mikuru).is("Time Traveler");
      //|          });
      //|
      //|      });
      //|
      //|  });
      //|
      //|
      //|if (process.argv[1] === __filename) {
      //|    oktest.main();
      //|}
      + '"use strict";\n'
      + '//require.paths.push(".");   // or export $NODE_PATH=$PWD\n'
      + 'var oktest = require("oktest");\n'
      + 'var topic   = oktest.topic,\n'
      + '    spec    = oktest.spec,\n'
      + '    ok      = oktest.ok,\n'
      + '    NG      = oktest.NG,\n'
      + '    precond = oktest.precond;\n'
      + '\n'
      + '\n'
      + '+ topic("ClassName", function() {\n'
      + '\n'
      + '    + topic(".methodName()", function() {\n'
      + '\n'
      + '        - spec("description #1", function() {\n'
      + '              ok (1+1).is(2);\n'
      + '              ok (1+1, \'===\', 2);\n'
      + '          });\n'
      + '\n'
      + '        - spec("throws Error with error message", function() {\n'
      + '              function fn() { throw new Error("errmsg"); };\n'
      + '              ok (fn).throws_(Error, "errmsg");  // or ok (fn).throws(...)\n'
      + '              ok (fn.exception.message).match(/errmsg/);\n'
      + '          });\n'
      + '\n'
      + '        /// fixture injection example\n'
      + '\n'
      + '        this.provideYuki   = function() { return "Humanoid Interface"; };\n'
      + '        this.provideMikuru = function() { return "Time Traveler"; };\n'
      + '\n'
      + '        - spec("Yuki is a humanoid interface", function(yuki) {\n'
      + '              ok (yuki).is("Humanoid Interface");\n'
      + '          });\n'
      + '        - spec("Mikuru is a time traveler", function(mikuru) {\n'
      + '              ok (mikuru).is("Time Traveler");\n'
      + '          });\n'
      + '\n'
      + '      });\n'
      + '\n'
      + '  });\n'
      + '\n'
      + '\n'
      + 'if (process.argv[1] === __filename) {\n'
      + '    oktest.main();\n'
      + '}\n'
);


///
/// main app
///

var cmdopt = null;

oktest.mainapp = {
};

oktest.mainapp.MainApp = function MainApp(script) {
  this.script = path.basename(script);
};

(function(def) {

  def.newCmdoptParser = function newCmdoptParser() {
    if (! cmdopt) cmdopt = require("cmdopt");
    var parser = new cmdopt.Parser();
    parser.option('-h', '--help')                        .desc("show help");
    parser.option('-v', '--version')                     .desc("version");
    parser.option('-s').name('style')   .arg('STYLE')    .desc("reporting style (verbose/simple/plain, or v/s/p)");
    parser.option('-p').name('pattern') .arg('PATTERN')  .desc("file pattern to search (default '*_test.js')");
    parser.option('-f').name('filter')  .arg('KEY=VAL')  .desc("filter topic or spec to run (see examples)");
    parser.option('-g').name('generate')                 .desc("generate template");
    parser.option('-c').name('color')                    .desc("enable output colorize");
    parser.option('-C').name('nocolor')                  .desc("disable output colorize");
    parser.option('-D').name('debug')                    .desc("debug");
    return parser;
  };

  def._helpMessage = function _helpMessage(parser) {
    var buf = "Usage: node " + this.script + " [options] file [file2...]\n";
    buf += parser.helpMessage();
    buf += (""
      + "Example:\n"
      + "  ## run test scripts in plain format\n"
      + "  $ node oktest.js -sp tests/*_test.py\n"
      + "  ## run test scripts in 'tests' dir with pattern '*_test.py'\n"
      + "  $ node oktest.js -p '*_test.py' tests\n"
      + "  ## filter by topic\n"
      + "  $ node oktest.js -f topic='*pattern*' tests\n"
      + "  ## filter by spec\n"
      + "  $ node oktest.js -f '*pattern*' tests   # or -f spec='*pattern*'\n"
    );
    return buf;
  };

  def.run = function run(args) {
    var _dp = oktest.util._dp;
    var parser = this.newCmdoptParser();
    var opts = parser.parse(args);
    if (opts.debug) oktest.config.debug = true;
    _dp("args", args);
    _dp("opts", opts);
    //
    if (opts.help) {
      util.print(this._helpMessage(parser));
      return 0;
    }
    if (opts.version) {
      util.print(oktest.__version__);
      return 0;
    }
    if (opts.generate) {
      util.print(oktest.TEMPLATE);
      return 0;
    }
    //
    var kwargs = this._getKwargs(opts);
    //
    var pattern = opts.pattern || '*_test.js';
    //
    var filename_list = [];
    for (var i = 0, n = args.length; i < n; i++) {
      var filename = args[i];
      var fstat = oktest.util.fstat(filename);
      if (! fstat)
        throw cmdopt.ParseError(filename + ": no such file or directory.");
      if (fstat.isFile()) {
        filename_list.push(filename);
      }
      else if (fstat.isDirectory()) {
        var dirname = filename;
        var fpaths = oktest.util.findFiles(pattern, dirname);
        filename_list = filename_list.concat(fpaths);
      }
    }
    ///
    for (i = 0, n = filename_list.length; i < n; i++) {
      var fpath = filename_list[i];
      _dp("fpath", fpath);
      require(fs.realpathSync(fpath));
    }
    var n_errors = oktest.run(kwargs);
    return n_errors;
  };

  def._getKwargs = function _getKwargs(opts) {
    var kwargs = {};
    if (opts.style) {
      var style = opts.style;
      var shorts = {v: "verbose", s: "simple", p: "plain"};
      if (style in shorts) style = shorts[style];
      kwargs.style = style;
    }
    if (opts.color) {
      kwargs.color = opts.color;
    }
    if (opts.nocolor) {
      kwargs.color = false;
    }
    if (opts.filter) {
      var key, val;
      var pair = oktest.util.split2(opts.filter, /=/);
      if (pair.length == 1) {
        key = 'spec';  val = pair[0];
      }
      else {
        key = pair[0]; val = pair[1];
      }
      if (key !== 'topic' && key !== 'spec') {
        throw cmdopt.ParseError(opts.filter+": unknown filter key.");
      }
      var filter = {}; filter[key] = val;
      kwargs.filter = filter;
    }
    return kwargs;
  };

})(oktest.mainapp.MainApp.prototype);


oktest.main = function main() {
  var script = process.argv[1];
  var args   = process.argv.slice(2);
  var app = new oktest.mainapp.MainApp(script);
  var n_errors = app.run(args);
  //process.exit(n_errors);
};


if (require.main === module) {
  oktest.main();
}

# -*- coding: utf-8 -*-
###
### $Release: $
### $Copyright: copyright(c) 2010-2013 kuwata-lab.com all rights reserved $
### $License: MIT License $
###

import sys, os, re
import unittest

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3

import oktest
from oktest import ok


def be_failed(expected_errmsg):
    def deco(func):
        passed = False
        try:
            func()
            passed = True
        except AssertionError:
            ex = sys.exc_info()[1]
            assert str(ex) == expected_errmsg, "%r != %r" % (str(ex), expected_errmsg)
        if passed:
            assert False, "assertion should be faile, but passed."
    return deco


def to_binary(string):
    if python2:
        return str(string)
    if python3:
        return bytes(string, 'utf-8')


def ignore_import_error(func):
    def deco(self):
        try:
            func(self)
        except ImportError:
            pass
    deco.__name__ = func.__name__
    deco.__doc__  = func.__doc__
    return deco


class ResponseAssertionObject_TC(unittest.TestCase):

    def test_resp_property(self):
        obj = ok (""); obj == ""
        assert isinstance(obj, oktest.AssertionObject)
        assert not isinstance(obj, oktest.ResponseAssertionObject)
        assert isinstance(obj.resp, oktest.ResponseAssertionObject)

    @ignore_import_error
    def test_is_response(self):
        from webob.response import Response
        response = Response()
        #
        ret = ok (response).is_response(200); ret != None
        ok (ret).is_a(oktest.ResponseAssertionObject)
        #
        try:
            ok (response).is_response(200)
            ok (response).is_response('200 OK')
        except:
            assert False, "failed"
        #
        try:
            ok (response).is_response(201)
        except AssertionError:
            ex = sys.exc_info()[1]
            assert str(ex) == ("Response status 200 == 201: failed.\n"
                               "--- response body ---\n")
        else:
            assert False, "failed"

    @ignore_import_error
    def test_status_ok(self):
        from webob.response import Response
        from webob.exc import HTTPFound, HTTPNotFound
        try:
            ok (Response()).resp.status(200)
            ok (HTTPFound()).resp.status(302)
            ok (HTTPNotFound()).resp.status(404)
        except:
            assert False, "failed"

    @ignore_import_error
    def test_status_ok_returns_self(self):
        from webob.response import Response
        from webob.exc import HTTPFound, HTTPNotFound
        respobj = ok (Response()).resp
        assert respobj.status(200) is respobj

    @ignore_import_error
    def test_status_NG(self):
        from webob.response import Response
        from webob.exc import HTTPFound, HTTPNotFound
        #
        response = Response()
        response.body = to_binary('{"status": "OK"}')
        expected_errmsg = r"""
Response status 200 == 201: failed.
--- response body ---
{"status": "OK"}
"""[1:-1]
        @be_failed(expected_errmsg)
        def _():
            ok (response).resp.status(201)

    @ignore_import_error
    def test_header_ok(self):
        from webob.response import Response
        try:
            ok (Response()).resp.header('Content-Type', 'text/html; charset=UTF-8')
            ok (Response()).resp.header('Location', None)
        except:
            assert False, "failed"

    @ignore_import_error
    def test_header_ok_returns_self(self):
        from webob.response import Response
        respobj = ok (Response()).resp
        assert respobj.header('Content-Type', 'text/html; charset=UTF-8') is respobj

    @ignore_import_error
    def test_header_NG(self):
        from webob.response import Response
        response = Response()
        expected_errmsg = r"""
Response header 'Content-Type' is unexpected value.
  expected: 'text/html'
  actual:   'text/html; charset=UTF-8'
"""[1:-1]
        @be_failed(expected_errmsg)
        def _():
            ok (response).resp.header('Content-Type', 'text/html')
        #
        response.headers['Location'] = '/'
        expected_errmsg = r"""
Response header 'Location' should not be set : failed.
  header value: '/'
"""[1:-1]
        @be_failed(expected_errmsg)
        def _():
            ok (response).resp.header('Location', None)

    @ignore_import_error
    def test_json_ok(self):
        from webob.response import Response
        response = Response()
        content_types = [
            'application/json',
            'application/json;charset=utf8',
            'application/json; charset=utf-8',
            'application/json; charset=UTF-8',
            'application/json;charset=UTF8',
        ]
        response.body = to_binary('''{"status": "OK"}''')
        try:
            for cont_type in content_types:
                response.content_type = cont_type
                ok (response).resp.json({"status": "OK"})
        except:
            ex = sys.exc_info()[1]
            assert False, "failed"

    @ignore_import_error
    def test_json_ok_returns_self(self):
        from webob.response import Response
        response = Response()
        response.content_type = 'application/json'
        response.body = to_binary('{"status": "OK"}')
        respobj = ok (response).resp
        assert respobj.json({"status": "OK"}) is respobj

    @ignore_import_error
    def test_json_NG_when_content_type_is_empty(self):
        from webob.response import Response
        response = Response()
        response.headers['Content-Type'] = ""
        response.body = to_binary('''{"status": "OK"}''')
        @be_failed("Content-Type is not set.")
        def _():
            ok (response).resp.json({"status": "OK"})

    @ignore_import_error
    def test_json_NG_when_content_type_is_not_json_type(self):
        from webob.response import Response
        response = Response()
        response.body = to_binary('''{"status": "OK"}''')
        expected = ("Content-Type should be 'application/json' : failed.\n"
                    "--- content-type ---\n"
                    "'text/html; charset=UTF-8'")
        @be_failed(expected)
        def _():
            ok (response).resp.json({"status": "OK"})

    @ignore_import_error
    def test_json_NG_when_json_data_is_different(self):
        from webob.response import Response
        response = Response()
        response.content_type = 'application/json'
        response.body = to_binary('''{"status": "OK"}''')
        expected = r"""
Responsed JSON is different from expected data.
--- expected
+++ actual
@@ -1,3 +1,3 @@
 {
-  "status": "ok"
+  "status": "OK"
 }
"""[1:-1]
        @be_failed(expected)
        def _():
            ok (response).resp.json({"status": "ok"})



if __name__ == '__main__':
    unittest.main()

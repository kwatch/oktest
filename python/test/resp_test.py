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
if python2:
    _unicode = unicode
    _binary  = str
if python3:
    _unicode = str
    _binary  = bytes


from difflib import unified_diff
diff_lines = unified_diff(["foo\n"], ["bar\n"], 'expected', 'actual')
_difflib_has_bug = 'expected ' in list(diff_lines)[0]
del unified_diff, diff_lines
def _fix_diffstr(string):
    if _difflib_has_bug:
        string = string.replace('--- expected', '--- expected ')
        string = string.replace('+++ actual', '+++ actual ')
        return string


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


try:
    from webob.response import Response as WebObResponse
except ImportError:
    class WebObResponse(object):
        def __init__(self, status=200, headers=None, body=""):
            if headers is None:
                headers = {'Content-Type': 'text/html; charset=UTF-8'}
            self.status_int = 200
            self.status = "200 OK"
            self.headers = headers
            if isinstance(body, _unicode):
                self.text = body
                self.body = body.encode('utf-8')
            else:
                self.body = body
                self.text = body.decode('utf-8')



class ResponseAssertionObject_TC(unittest.TestCase):

    def test_resp_property(self):
        obj = ok (""); obj == ""
        assert isinstance(obj, oktest.AssertionObject)
        assert not isinstance(obj, oktest.ResponseAssertionObject)
        assert isinstance(obj.resp, oktest.ResponseAssertionObject)

    def test_is_response(self):
        response = WebObResponse()
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

    def test_status_ok(self):
        try:
            ok (WebObResponse()).resp.status(200)
            ok (WebObResponse(status=302)).resp.status(302)
        except:
            assert False, "failed"

    def test_status_ok_returns_self(self):
        respobj = ok (WebObResponse()).resp
        assert respobj.status(200) is respobj

    def test_status_NG(self):
        response = WebObResponse()
        response.body = to_binary('{"status": "OK"}')
        expected_errmsg = r"""
Response status 200 == 201: failed.
--- response body ---
{"status": "OK"}
"""[1:-1]
        @be_failed(expected_errmsg)
        def _():
            ok (response).resp.status(201)

    def test_header_ok(self):
        try:
            ok (WebObResponse()).resp.header('Content-Type', 'text/html; charset=UTF-8')
            ok (WebObResponse()).resp.header('Location', None)
        except:
            assert False, "failed"

    def test_header_ok_returns_self(self):
        respobj = ok (WebObResponse()).resp
        assert respobj.header('Content-Type', 'text/html; charset=UTF-8') is respobj

    def test_header_NG(self):
        response = WebObResponse()
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

    def test_body_ok(self):
        response = WebObResponse()
        response.body = to_binary('<h1>Hello</h1>')
        try:
            ok (response).resp.body('<h1>Hello</h1>')
            ok (response).resp.body(re.compile('<h1>.*</h1>'))
            ok (response).resp.body(re.compile('hello', re.I))
        except:
            ex = sys.exc_info()[1]
            assert False, "failed"

    def test_body_NG(self):
        response = WebObResponse()
        response.body = to_binary('<h1>Hello</h1>')
        #
        expected_msg = ("Response body is different from expected data.\n"
                        "  expected: <h1>Hello World!</h1>\n"
                        "  actual:   <h1>Hello</h1>")
        @be_failed(expected_msg)
        def _():
            ok (response).resp.body('<h1>Hello World!</h1>')
        #
        expected_msg = ("Response body failed to match to expected pattern.\n"
                        "  expected pattern: 'hello'\n"
                        "  response body:    <h1>Hello</h1>")
        @be_failed(expected_msg)
        def _():
            ok (response).resp.body(re.compile(r'hello'))

    def test_json_ok(self):
        response = WebObResponse()
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

    def test_json_ok_returns_self(self):
        response = WebObResponse()
        response.content_type = 'application/json'
        response.body = to_binary('{"status": "OK"}')
        respobj = ok (response).resp
        assert respobj.json({"status": "OK"}) is respobj

    def test_json_NG_when_content_type_is_empty(self):
        response = WebObResponse()
        response.headers['Content-Type'] = ""
        response.body = to_binary('''{"status": "OK"}''')
        @be_failed("Content-Type is not set.")
        def _():
            ok (response).resp.json({"status": "OK"})

    def test_json_NG_when_content_type_is_not_json_type(self):
        response = WebObResponse()
        response.body = to_binary('''{"status": "OK"}''')
        expected = ("Content-Type should be 'application/json' : failed.\n"
                    "--- content-type ---\n"
                    "'text/html; charset=UTF-8'")
        @be_failed(expected)
        def _():
            ok (response).resp.json({"status": "OK"})

    def test_json_NG_when_json_data_is_different(self):
        response = WebObResponse()
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
        expected = _fix_diffstr(expected)
        @be_failed(expected)
        def _():
            ok (response).resp.json({"status": "ok"})



if __name__ == '__main__':
    unittest.main()

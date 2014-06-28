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


import oktest
from oktest import ok, NOT

_diff_has_column_num = '1,1' in oktest._diff("foo\n", "bar\n")



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
        if isinstance(string, unicode):
            return string.encode('utf-8')
        else:
            return string
    if python3:
        if isinstance(string, bytes):
            return string
        else:
            return string.encode('utf-8')

def to_unicode(string):
    if python2:
        if isinstance(string, unicode):
            return string
        else:
            return string.decode('utf-8')
    if python3:
        if isinstance(string, bytes):
            return string.decode('utf-8')
        else:
            return string


try:
    from webob.response import Response as WebObResponse
except (ImportError, SyntaxError):
    class WebObResponse(object):
        def __init__(self, status=200, headers=None):
            if headers is None:
                headers = {'Content-Type': 'text/html; charset=UTF-8'}
            self.status_int = status
            self.status = status == 200 and "200 OK" or None
            self.headers = headers
            self.body = to_binary("")
            self.text = to_unicode("")

try:
    from werkzeug.wrappers import Response as WerkzeugResponse
except (ImportError, SyntaxError):
    class WerkzeugResponse(object):
        def __init__(self, status=200, headers=None):
            if headers is None:
                headers = {'Content-Type': 'text/html; charset=UTF-8'}
            self.status_code = status
            self.status = status == 200 and "200 OK" or None
            self.headers = headers
            self.data = ""
            self.mimetype = 'text/plain'
        def get_data(self, as_text=False):
            if as_text:
                return to_unicode(self._data)
            return self._data
        def set_data(self, data):
            self._data = to_binary(data)
        data = property(get_data, set_data)

try:
    from requests.models import Response as RequestsResponse
except (ImportError, SyntaxError):
    class RequestsResponse(object):
        def __init__(self):
            self.status_code = None
            self.reason = None
            self.headers = {}
            self._content = None
        @property
        def content(self):
            return self._content
        @property
        def text(self):
            return self._content.decode('utf-8')
finally:
    def _setUp(self, status=200, headers=None):
        if isinstance(status, int):
            self.status_code = status
            self.reason = {200:'OK', 201:'Created', 301: 'Moved Permanently', 302:'Found'}.get(status)
        elif isinstance(status, str):
            code, msg = str.split(' ', 1)
            self.status_code = code
            self.reason = msg
        else:
            raise TypeError
        self.headers = headers or {}
        self._content = to_binary("")
        return self
    assert not hasattr(RequestsResponse, '_setUp')
    RequestsResponse._setUp = _setUp
    del _setUp

from oktest.web import WSGIResponse as OktestWSGIResponse


def _set_body(response, body):
    if hasattr(response, 'body'):
        response.body = to_binary(body)
        response.text = to_unicode(body)
    elif hasattr(response, 'data'):
        response.data = body
    elif hasattr(response, '_content'):
        response._content = to_binary(body)
    elif hasattr(response, 'body_binary'):
        response._body_binary  = to_binary(body)
        response._body_unicode = to_unicode(body)
    else:
        raise Exception

def _set_ctype(response, content_type):
    if hasattr(response, 'content_type'):
        response.content_type = content_type
    elif hasattr(response, 'mimetype'):
        response.mimetype = content_type
    else:
        response.headers['Content-Type'] = content_type

def _get_ctype(response):
    if hasattr(response, 'content_type'):
        return response.content_type
    elif hasattr(response, 'mimetype'):
        return response.mimetype
    else:
        return response.headers['Content-Type']

def with_response_class(func):
    def newfunc(self):
        #for klass in [WebObResponse]:
        #for klass in [WerkzeugResponse]:
        #for klass in [RequestsResponse]:
        #for klass in [OktestWSGIResponse]:
        for klass in [WebObResponse, WerkzeugResponse, RequestsResponse, OktestWSGIResponse]:
            func(self, klass)
    newfunc.__name__ = func.__name__
    newfunc.__doc__  = func.__doc__
    return newfunc


class ResponseAssertionObject_TC(unittest.TestCase):

    @with_response_class
    def test_resp_property(self, Response):
        obj = ok (""); obj == ""
        assert isinstance(obj, oktest.AssertionObject)
        assert not isinstance(obj, oktest.ResponseAssertionObject)
        assert isinstance(obj._resp, oktest.ResponseAssertionObject)

    @with_response_class
    def test_is_response(self, Response):
        response = Response()
        if hasattr(response, '_setUp'): response._setUp()
        ret = ok (response).is_response(200); ret != None
        ok (ret).is_a(oktest.ResponseAssertionObject)
        #
        try:
            ok (response).is_response(200)
            #ok (response).is_response('200 OK')
            #ok (response).is_response((200, 201))
        except:
            assert False, "failed"
        #
        _set_ctype(response, 'text/html')
        try:
            ok (response).is_response(200, 'text/html')
            ok (response).is_response(200, re.compile(r'^text/(html|plain)$'))
        except:
            assert False, "failed"
        #
        try:
            ok (response).is_response(201)
        except AssertionError:
            ex = sys.exc_info()[1]
            expected_errmsg = r"""
Response status 200 == 201: failed.
--- response body ---
b''
"""[1:-1]
            if python2:
                expected_errmsg = expected_errmsg.replace("b''", "")
            assert str(ex) == (expected_errmsg)
        else:
            assert False, "failed"
        #
        _set_ctype(response, 'text/html')
        try:
            ok (response).is_response(200, 'text/plain')
        except AssertionError:
            ex = sys.exc_info()[1]
            expected_errmsg = r"""
Unexpected content-type value.
  expected: 'text/plain'
  actual:   %r
"""[1:-1] % _get_ctype(response)
            assert str(ex) == expected_errmsg
        #
        try:
            NOT (response).is_response(200)
        except TypeError:
            ex = sys.exc_info()[1]
            assert str(ex) == "is_response(): not available with NOT() nor NG()."
        else:
            assert false, "failed"

    @with_response_class
    def test_status_ok(self, Response):
        if Response is OktestWSGIResponse:
            status = '302 Found'
        else:
            status = 302
        try:
            if hasattr(Response, '_setUp'):
                ok (Response()._setUp())._resp.status(200)
                ok (Response()._setUp(status))._resp.status(302)
                ok (Response()._setUp(status))._resp.status((301, 302))
                pass
            else:
                ok (Response())._resp.status(200)
                ok (Response(status=status))._resp.status(302)
                ok (Response(status=status))._resp.status((301, 302))
        except:
            assert False, "failed"

    @with_response_class
    def test_status_ok_returns_self(self, Response):
        resp = Response()
        if hasattr(resp, '_setUp'): resp._setUp()
        ret = ok (resp)._resp
        assert ret.status(200) is ret

    @with_response_class
    def test_status_NG(self, Response):
        response = Response()
        if hasattr(response, '_setUp'): response._setUp()
        _set_body(response, to_binary('{"status": "OK"}'))
        expected_errmsg = r"""
Response status 200 == 201: failed.
--- response body ---
b'{"status": "OK"}'
"""[1:-1]
        if python2:
            expected_errmsg = re.sub(r"b'({.*?})'", r"\1", expected_errmsg)
        @be_failed(expected_errmsg)
        def _():
            ok (response)._resp.status(201)
        #
        expected_errmsg = r"""
Response status 200 in (301, 302): failed.
--- response body ---
b'{"status": "OK"}'
"""[1:-1]
        if python2:
            expected_errmsg = re.sub(r"b'({.*?})'", r"\1", expected_errmsg)
        @be_failed(expected_errmsg)
        def _():
            ok (response)._resp.status((301, 302))

    @with_response_class
    def test_cont_type_ok(self, Response):
        resp = Response()
        if hasattr(resp, '_setUp'): resp._setUp()
        _set_ctype(resp, 'image/jpeg')
        try:
            ok (resp)._resp.cont_type('image/jpeg')
            ok (resp)._resp.cont_type(re.compile('^image/(jpeg|png|gif)$'))
        except:
            assert False, "failed"

    @with_response_class
    def test_cont_type_ok_returns_self(self, Response):
        resp = Response()
        if hasattr(resp, '_setUp'): resp._setUp()
        _set_ctype(resp, 'image/jpeg')
        respobj = ok (resp)._resp
        assert respobj.cont_type('image/jpeg') is respobj
        assert respobj.cont_type(re.compile('^image/(jpeg|png|gif)$')) is respobj

    @with_response_class
    def test_cont_type_NG(self, Response):
        resp = Response()
        if hasattr(resp, '_setUp'): resp._setUp()
        #
        _set_ctype(resp, 'image/jpeg')
        expected_errmsg = r"""
Unexpected content-type value.
  expected: 'image/png'
  actual:   %r
"""[1:-1] % _get_ctype(resp)
        @be_failed(expected_errmsg)
        def _():
            ok (resp)._resp.cont_type('image/png')
        #
        expected_errmsg = r"""
Unexpected content-type value (not matched to pattern).
  expected: re.compile('^image/(jpg|png|gif)$')
  actual:   %r
"""[1:-1] % _get_ctype(resp)
        @be_failed(expected_errmsg)
        def _():
            ok (resp)._resp.cont_type(re.compile(r'^image/(jpg|png|gif)$'))

    @with_response_class
    def test_header_ok(self, Response):
        response = Response()
        if hasattr(response, '_setUp'): response._setUp()
        response.headers['Location'] = '/'
        try:
            ok (response)._resp.header('Location', '/')
            ok (response)._resp.header('Last-Modified', None)
        except:
            assert False, "failed"

    @with_response_class
    def test_header_ok_returns_self(self, Response):
        response = Response()
        if hasattr(response, '_setUp'): response._setUp()
        response.headers['Location'] = '/'
        respobj = ok (response)._resp
        assert respobj.header('Location', '/') is respobj

    @with_response_class
    def test_header_NG(self, Response):
        response = Response()
        if hasattr(response, '_setUp'): response._setUp()
        response.headers['Location'] = '/'
        expected_errmsg = r"""
Response header 'Location' is unexpected value.
  expected: '/index'
  actual:   u'/'
"""[1:-1]
        if python3 or (python2 and isinstance(response.headers['Location'], str)):
            expected_errmsg = expected_errmsg.replace("u'/'", "'/'")
        @be_failed(expected_errmsg)
        def _():
            ok (response)._resp.header('Location', '/index')
        #
        response.headers['Location'] = '/'
        expected_errmsg = r"""
Response header 'Location' should not be set : failed.
  header value: u'/'
"""[1:-1]
        if python3 or (python2 and isinstance(response.headers['Location'], str)):
            expected_errmsg = expected_errmsg.replace("u'/'", "'/'")
        @be_failed(expected_errmsg)
        def _():
            ok (response)._resp.header('Location', None)

    @with_response_class
    def test_body_ok(self, Response):
        response = Response()
        if hasattr(response, '_setUp'): response._setUp()
        _set_body(response, '<h1>Hello</h1>')
        try:
            ok (response)._resp.body('<h1>Hello</h1>')
            ok (response)._resp.body(re.compile('<h1>.*</h1>'))
            ok (response)._resp.body(re.compile('hello', re.I))
        except:
            assert False, "failed"

    @with_response_class
    def test_body_NG(self, Response):
        response = Response()
        if hasattr(response, '_setUp'): response._setUp()
        _set_body(response, to_binary('<h1>Hello</h1>'))
        #
        expected_msg = r"""
Response body is different from expected data.
--- expected
+++ actual
@@ -1,1 +1,1 @@
-<h1>Hello World!</h1>
+<h1>Hello</h1>
"""[1:]
        if not _diff_has_column_num:
            expected_msg = expected_msg.replace('1,1', '1')
        @be_failed(expected_msg)
        def _():
            ok (response)._resp.body('<h1>Hello World!</h1>')
        #
        expected_msg = r"""
Response body failed to match to expected pattern.
  expected pattern: 'hello'
  response body:    <h1>Hello</h1>
"""[1:-1]
        @be_failed(expected_msg)
        def _():
            ok (response)._resp.body(re.compile(r'hello'))

    @with_response_class
    def test_json_ok(self, Response):
        response = Response()
        if hasattr(response, '_setUp'): response._setUp()
        content_types = [
            'application/json',
            'application/json;charset=utf8',
            'application/json; charset=utf-8',
            'application/json; charset=UTF-8',
            'application/json;charset=UTF8',
        ]
        _set_body(response, to_binary('''{"status": "OK"}'''))
        try:
            for cont_type in content_types:
                _set_ctype(response, cont_type)
                ok (response)._resp.json({"status": "OK"})
        except:
            assert False, "failed"

    @with_response_class
    def test_json_ok_returns_self(self, Response):
        response = Response()
        if hasattr(response, '_setUp'): response._setUp()
        _set_ctype(response, 'application/json')
        _set_body(response, to_binary('{"status": "OK"}'))
        respobj = ok (response)._resp
        assert respobj.json({"status": "OK"}) is respobj

    @with_response_class
    def test_json_NG_when_content_type_is_empty(self, Response):
        response = Response()
        if hasattr(response, '_setUp'): response._setUp()
        _set_body(response, to_binary('{"status": "OK"}'))
        _set_ctype(response, '')
        @be_failed("Content-Type is not set.")
        def _():
            ok (response)._resp.json({"status": "OK"})

    @with_response_class
    def test_json_NG_when_content_type_is_not_json_type(self, Response):
        response = Response()
        if hasattr(response, '_setUp'): response._setUp()
        _set_body(response, to_binary('''{"status": "OK"}'''))
        _set_ctype(response, 'text/html; charset=UTF-8')
        expected = ("Content-Type should be 'application/json' : failed.\n"
                    "--- content-type ---\n" + repr(_get_ctype(response)))
        @be_failed(expected)
        def _():
            ok (response)._resp.json({"status": "OK"})

    @with_response_class
    def test_json_NG_when_json_data_is_different(self, Response):
        response = Response()
        if hasattr(response, '_setUp'): response._setUp()
        _set_body(response, to_binary('''{"status": "OK"}'''))
        _set_ctype(response, 'application/json')
        expected = r"""
Responsed JSON is different from expected data.
--- expected
+++ actual
@@ -1,3 +1,3 @@
 {
-  "status": "ok"
+  "status": "OK"
 }
\ No newline at end of string
"""[1:]
        @be_failed(expected)
        def _():
            ok (response)._resp.json({"status": "ok"})


    @with_response_class
    def test_cookie_ok(self, Response):
        response = Response()
        response.headers['Set-Cookie'] = 'name1=val1'
        try:
            ok (response)._resp.cookie('name1', 'val1')
        except:
            assert False, "failed"

    @with_response_class
    def test_cookie_ok_attributes(self, Response):
        if sys.version.startswith('3.0'):
            return   # cookie lib of Python3.0 has a bug
        #
        response = Response()
        cookie_str = 'name3=val3; domain=www.example.com; Path=/cgi; Expires=%s; Max-Age=120; Httponly; Secure'
        response.headers['Set-Cookie'] = cookie_str % 'Wed, 01-Jan-2020 12:34:56 GMT'
        try:
            ok (response)._resp.cookie('name3', 'val3',
                                       domain   = 'www.example.com',
                                       path     = '/cgi',
                                       expires  = 'Wed, 01-Jan-2020 12:34:56 GMT',
                                       max_age  = '120',
                                       secure   = True,
                                       httponly = True,
                                       )
        except:
            assert False, "failed"

    @with_response_class
    def test_cookie_fail_when_no_set_cookie_header(self, Response):
        response = Response()
        @be_failed("'Set-Cookie' header is empty or not provided in response.")
        def _():
            ok (response)._resp.cookie('name1', 'val1')
        response.headers['Set-Cookie'] = ''
        @be_failed("'Set-Cookie' header is empty or not provided in response.")
        def _():
            ok (response)._resp.cookie('name1', 'val1')

    @with_response_class
    def test_cookie_fail_when_unexpected_value(self, Response):
        response = Response()
        response.headers['Set-Cookie'] = 'name1=val1'
        @be_failed("Cookie 'name1': $actual == $expected: failed.\n"
                   "  $actual:   'val1'\n"
                   "  $expected: 'foobar'")
        def _():
            ok (response)._resp.cookie('name1', 'foobar')

    @with_response_class
    def test_cookie_fail_when_unexpected_attributes(self, Response):
        if sys.version.startswith('3.0'):
            return   # cookie lib of Python3.0 has a bug
        #
        response = Response()
        cookie_str = 'name3=val3; domain=www.example.com; Path=/cgi; Expires=%s; Max-Age=120; Httponly; Secure'
        response.headers['Set-Cookie'] = cookie_str % 'Wed, 01-Jan-2020 12:34:56 GMT'
        #
        @be_failed("Cookie 'name3': unexpected domain.\n"
                   "  expected domain:  'example.com'\n"
                   "  actual domain:    'www.example.com'")
        def _(): ok (response)._resp.cookie('name3', 'val3', domain='example.com')
        #
        @be_failed("Cookie 'name3': unexpected path.\n"
                   "  expected path:  '/'\n"
                   "  actual path:    '/cgi'")
        def _(): ok (response)._resp.cookie('name3', 'val3', path='/')
        #
        @be_failed("Cookie 'name3': unexpected expires.\n"
                   "  expected expires:  'Wed, 01-Jan-2020 12:34:56'\n"
                   "  actual expires:    'Wed, 01-Jan-2020 12:34:56 GMT'")
        def _(): ok (response)._resp.cookie('name3', 'val3', expires='Wed, 01-Jan-2020 12:34:56')
        #
        @be_failed("Cookie 'name3': unexpected max-age.\n"
                   "  expected max-age:  0\n"
                   "  actual max-age:    '120'")
        def _(): ok (response)._resp.cookie('name3', 'val3', max_age=0)
        #
        @be_failed("Cookie 'name3': unexpected httponly.\n"
                   "  expected httponly:  False\n"
                   "  actual httponly:    True")
        def _(): ok (response)._resp.cookie('name3', 'val3', httponly=False)
        #
        @be_failed("Cookie 'name3': unexpected secure.\n"
                   "  expected secure:  False\n"
                   "  actual secure:    True")
        def _(): ok (response)._resp.cookie('name3', 'val3', secure=False)


    def test_raises_UnsupportedResponseObjectError(self):
        if python2:
            errmsg = "'foo': failed to get response %s; <type 'str'> is unsupported response class in oktest."
        else:
            errmsg = "'foo': failed to get response %s; <class 'str'> is unsupported response class in oktest."
        #
        def fn(): ok ("foo").is_response(200)
        ok (fn).raises(oktest.UnsupportedResponseObjectError, errmsg % 'status code')
        #
        def fn(): ok ("foo")._resp.status(200)
        ok (fn).raises(oktest.UnsupportedResponseObjectError, errmsg % 'status code')
        #
        def fn(): ok ("foo")._resp.cont_type('text/plain')
        ok (fn).raises(oktest.UnsupportedResponseObjectError, errmsg % 'content type')
        #
        def fn(): ok ("foo")._resp.header('Content-Type', 'text/plain')
        ok (fn).raises(oktest.UnsupportedResponseObjectError, errmsg % 'header')
        #
        def fn(): ok ("foo")._resp.body(["hello!"])
        ok (fn).raises(oktest.UnsupportedResponseObjectError, errmsg % 'binary body')
        #
        def fn(): ok ("foo")._resp.json({"status":"OK"})
        ok (fn).raises(oktest.UnsupportedResponseObjectError, errmsg % 'content type')



if __name__ == '__main__':
    unittest.main()

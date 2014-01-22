# -*- coding: utf-8 -*-

import sys
import wsgiref.util

python2 = sys.version_info[0] == 2
python3 = sys.version_info[0] == 3
if python2:
    _binary = str
    _unicode = unicode
    python30 = False
    python31 = False
elif python3:
    _binary = bytes
    _unicode = str
    python30 = sys.version_info[1] == 0
    python31 = sys.version_info[1] == 1

def _B(val):
    return val.encode('utf-8') if isinstance(val, _unicode) else val
def _U(val):
    return val.decode('utf-8') if isinstance(val, _binary) else val

import unittest
import oktest
from oktest.web import WSGITest, WSGIStartResponse, WSGIResponse
from oktest.tracer import Tracer


def _app(environ, start_response):
    input = environ['wsgi.input']
    content = "OK"
    if input:
        buf = []
        while True:
            s = input.read(1024)
            if not s: break
            buf.append(s)
        empty = _B("")
        content += " <input=%r>" % empty.join(buf)
    if isinstance(content, _unicode):
        content = content.encode('utf-8')
    start_response("201 Created", [('Content-Type', 'image/jpeg')])
    return [content]



class WSGITest_TC(unittest.TestCase):

    def setUp(self):
        self.http = WSGITest(_app)

    def test___init__(self):
        http = WSGITest(_app)
        assert http._app is _app
        #
        http = WSGITest(_app)
        resp = http.GET('/hello')
        assert resp._environ['wsgi.url_scheme'] == 'http'
        full_url = wsgiref.util.request_uri(resp._environ)
        assert full_url == "http://127.0.0.1/hello"
        #
        http = WSGITest(_app, {'HTTPS':'on'})
        resp = http.GET('/hello')
        assert resp._environ['wsgi.url_scheme'] == 'https'
        full_url = wsgiref.util.request_uri(resp._environ)
        assert full_url == "https://127.0.0.1/hello"

    def test___call__(self):
        resp = self.http()
        assert isinstance(resp, WSGIResponse)
        assert resp.status  == "201 Created"
        assert resp.headers['Content-Type'] == 'image/jpeg'
        if python2:
            assert resp.body_binary  == _B("OK <input=''>")
            assert resp.body_unicode == _U("OK <input=''>")
        elif python3:
            assert resp.body_binary  == _B("OK <input=b''>")
            assert resp.body_unicode == _U("OK <input=b''>")

    def test__call___query(self):
        resp = self.http.POST('/hello', query={'q':"SOS", 'page':'1'})
        if python2:
            assert resp.body_binary  == _B("OK <input=''>")
            assert resp.body_unicode == _U("OK <input=''>")
        elif python3:
            assert resp.body_binary  == _B("OK <input=b''>")
            assert resp.body_unicode == _U("OK <input=b''>")
        assert resp._environ['QUERY_STRING'] in ("q=SOS&page=1", "page=1&q=SOS")
        assert 'CONTENT_TYPE' not in resp._environ
        assert 'CONTENT_LENGTH' not in resp._environ

    def test__call___form(self):
        resp = self.http.POST('/hello', form={'q':"SOS", 'page':'1'})
        if python2:
            assert resp.body_binary in ("OK <input='q=SOS&page=1'>",
                                        "OK <input='page=1&q=SOS'>",)
        elif python3:
            assert resp.body_binary in (_B("OK <input=b'q=SOS&page=1'>"),
                                        _B("OK <input=b'page=1&q=SOS'>"),)
        assert resp._environ['QUERY_STRING'] == ""
        assert resp._environ['CONTENT_TYPE'] == 'application/x-www-form-urlencoded'
        assert resp._environ['CONTENT_LENGTH'] == str(len('q=SOS&page=1'))

    def test__call___json(self):
        resp = self.http.POST('/hello', json={'q':"SOS", 'page':1})
        if python2:
            assert resp.body_binary in ("""OK <input='{"q":"SOS","page":1}'>""",
                                        """OK <input='{"page":1,"q":"SOS"}'>""",)
        elif python3:
            assert resp.body_binary in (_B("""OK <input=b'{"q":"SOS","page":1}'>"""),
                                        _B("""OK <input=b'{"page":1,"q":"SOS"}'>"""),)
        assert resp._environ['QUERY_STRING'] == ""
        assert resp._environ['CONTENT_TYPE'] == 'application/json'
        assert resp._environ['CONTENT_LENGTH'] == str(len('{"page":1,"q":"SOS"}'))

    def test_GET(self):
        resp = self.http.GET('/hello')
        assert resp._environ['REQUEST_METHOD'] == 'GET'

    def test_POST(self):
        resp = self.http.POST('/hello')
        assert resp._environ['REQUEST_METHOD'] == 'POST'

    def test_PUT(self):
        resp = self.http.PUT('/hello')
        assert resp._environ['REQUEST_METHOD'] == 'PUT'

    def test_DELETE(self):
        resp = self.http.DELETE('/hello')
        assert resp._environ['REQUEST_METHOD'] == 'DELETE'

    def test_PATCH(self):
        resp = self.http.PATCH('/hello')
        assert resp._environ['REQUEST_METHOD'] == 'PATCH'

    def test_OPTIONS(self):
        resp = self.http.OPTIONS('/hello')
        assert resp._environ['REQUEST_METHOD'] == 'OPTIONS'

    def test_TRACE(self):
        resp = self.http.TRACE('/hello')
        assert resp._environ['REQUEST_METHOD'] == 'TRACE'


class WSGIStartResponse_TC(unittest.TestCase):

    def test___call__(self):
        status = '201 Created'
        headers = [('Content-Type', 'image/png')]
        callback = WSGIStartResponse()
        callback(status, headers)
        assert callback.status is status
        assert callback.headers is headers


class WSGIResponse_TC(unittest.TestCase):

    def test_attributes(self):
        http = WSGITest(_app)
        resp = http.GET('/foo')
        assert resp.status == '201 Created'
        assert resp.headers['Content-Type'] == 'image/jpeg'
        if python2:
            assert resp.body_binary  == _B("OK <input=''>")
            assert resp.body_unicode == _U("OK <input=''>")
        elif python3:
            assert resp.body_binary  == _B("OK <input=b''>")
            assert resp.body_unicode == _U("OK <input=b''>")
        assert isinstance(resp.body_binary,  _binary)
        assert isinstance(resp.body_unicode, _unicode)

    def test_warning_when_response_body_contains_unicode(self):
        def app(env, callback):
            callback('200 OK', [('Content-Type', 'text/plain')])
            return [_U("Hello")]
        #
        if python2 or python30 or python31:
            called = []
            def warn(*args, **kwargs):
                called.append(args)
                called.append(kwargs)
            import warnings
            _original = warnings.warn
            warnings.warn = warn
            try:
                http = WSGITest(app)
                resp = http.GET('/foo')
                resp.body_binary
                errmsg = "response body should be binary, but got unicode data: u'Hello'\n"
                if python3:
                    errmsg = errmsg.replace("u'", "'")
                assert called[0] == (errmsg, oktest.web.OktestWSGIWarning, )
                assert called[1] == {}
            finally:
                warnings.warn = _original
        elif python3:
            try:
                http = WSGITest(app)
                resp = http.GET('/foo')
                resp.body_binary
            except AssertionError:
                ex = sys.exc_info()[1]
                assert str(ex) == "Iterator yielded non-bytestring ('Hello')"
            else:
                assert False, "assertion error expected but not raised."

    def test_error_when_response_body_contains_non_string_data(self):
        def app(env, callback):
            callback('200 OK', [('Content-Type', 'text/plain')])
            return [_B("Hello"), None]
        #
        http = WSGITest(app)
        if python2 or python30 or python31:
            try:
                resp = http.GET('/foo')
                resp.body_binary
            except ValueError:
                ex = sys.exc_info()[1]
                errmsg = "Unexpected response body data type: <type 'NoneType'> (None)"
                if python30 or python31:
                    errmsg = errmsg.replace('<type', '<class')
                assert str(ex) == errmsg
            else:
                assert False, "ValueError expected, but not raised."
        elif python3:
            try:
                resp = http.GET('/foo')
                resp.body_binary
            except AssertionError:
                ex = sys.exc_info()[1]
                assert str(ex) == "Iterator yielded non-bytestring (None)"
            else:
                assert False, "assertion error expected, but not raised."

    def test___iter__(self):
        http = WSGITest(_app)
        status, headers, body = http.GET('/hello')
        assert status == '201 Created'
        assert type(status) is str
        assert headers == [('Content-Type', 'image/jpeg')]
        assert type(headers) is list
        if python2:
            assert body == [_B("OK <input=''>")]
        elif python3:
            assert body == [_B("OK <input=b''>")]



if __name__ == '__main__':
    unittest.main()

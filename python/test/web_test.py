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
from oktest.web import WSGITest, WSGIStartResponse, WSGIResponse, MultiPart
from oktest.tracer import Tracer


def _app(environ, start_response):
    input = environ['wsgi.input']
    content = "OK"
    is_multipart = environ.get('CONTENT_TYPE', '').startswith('multipart/form-data')
    if input and not is_multipart:
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

    def test__call___params(self):
        resp = self.http.GET('/hello', params={'q':"SOS", 'page':'1'})
        if python2:
            assert resp.body_binary  == _B("OK <input=''>")
            assert resp.body_unicode == _U("OK <input=''>")
        elif python3:
            assert resp.body_binary  == _B("OK <input=b''>")
            assert resp.body_unicode == _U("OK <input=b''>")
        assert resp._environ['QUERY_STRING'] in ("q=SOS&page=1", "page=1&q=SOS")
        assert 'CONTENT_TYPE' not in resp._environ
        assert 'CONTENT_LENGTH' not in resp._environ
        #
        resp = self.http.POST('/hello', params={'q':"SOS", 'page':'1'})
        if python2:
            assert resp.body_binary in ("OK <input='q=SOS&page=1'>",
                                        "OK <input='page=1&q=SOS'>",)
        elif python3:
            assert resp.body_binary in (_B("OK <input=b'q=SOS&page=1'>"),
                                        _B("OK <input=b'page=1&q=SOS'>"),)
        assert resp._environ['QUERY_STRING'] == ""
        assert resp._environ['CONTENT_TYPE'] == 'application/x-www-form-urlencoded'
        assert resp._environ['CONTENT_LENGTH'] == str(len('q=SOS&page=1'))
        #
        mp = MultiPart("qwerty")
        mp.add("name1", "val1")
        mp.add("name2", "xyz", "ex.tmp", "application/text")
        resp = self.http.POST('/hello', params=mp)
        assert resp._environ['QUERY_STRING'] == ""
        assert resp._environ['CONTENT_TYPE'] == 'multipart/form-data; boundary=qwerty'
        ##---
        if sys.version.startswith(('3.0', '3.1')):
            sys.stderr.write("\033[0;31m*** skip due to bug of cgi.py\033[0m\n")
            return
        ##---
        import cgi
        form = cgi.FieldStorage(resp._environ['wsgi.input'], environ=resp._environ)
        assert form['name1'].value    == "val1"
        assert form['name1'].filename == None
        assert form['name1'].type     == "text/plain"
        assert form['name2'].value    == _B("xyz")
        assert form['name2'].filename == "ex.tmp"
        assert form['name2'].type     == "application/text"
        #
        try:
            self.http.GET('/hello', params={}, query={})
        except TypeError:
            ex = sys.exc_info()[1]
            self.assertEqual(str(ex), "Both `params' and `query' are specified for GET method.")
        else:
            self.fail("TypeError should be raised, but not.")
        #
        try:
            self.http.POST('/hello', params={}, form={})
        except TypeError:
            ex = sys.exc_info()[1]
            self.assertEqual(str(ex), "Both `params' and `form' are specified for POST method.")
        else:
            self.fail("TypeError should be raised, but not.")

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

    def test__call___multipart(self):
        mp = MultiPart("qwerty")
        mp.add("name1", "val1")
        mp.add("name2", "xyz", "ex.tmp", "application/text")
        resp = self.http.POST('/hello', multipart=mp)
        self.assertEqual(resp._environ['QUERY_STRING'], "")
        self.assertEqual(resp._environ['CONTENT_TYPE'], 'multipart/form-data; boundary=qwerty')
        ##---
        if sys.version.startswith(('3.0', '3.1')):
            sys.stderr.write("\033[0;31m*** skip due to bug of cgi.py\033[0m\n")
            return
        ##---
        stdin = resp._environ['wsgi.input']
        import cgi
        form = cgi.FieldStorage(stdin, environ=resp._environ)
        self.assertEqual(form['name1'].value   , "val1")
        self.assertEqual(form['name1'].filename, None)
        self.assertEqual(form['name1'].type    , "text/plain")
        self.assertEqual(form['name2'].value   , _B("xyz"))
        self.assertEqual(form['name2'].filename, "ex.tmp")
        self.assertEqual(form['name2'].type    , "application/text")

    def test__call___headers(self):
        def app(environ, start_response):
            start_response('200 OK', [('Content-Type', 'text/plain')])
            return [
                _B("HTTP_COOKIE: %r"           % environ['HTTP_COOKIE']),
                _B("HTTP_X_REQUESTED_WITH: %r" % environ['HTTP_X_REQUESTED_WITH']),
            ]
        http = WSGITest(app)
        resp = http.GET('/', headers={'Cookie': 'name=val', 'X-Requested-With': 'XMLHttpRequest'})
        expected = [_B("HTTP_COOKIE: 'name=val'"),
                    _B("HTTP_X_REQUESTED_WITH: 'XMLHttpRequest'")]
        self.assertEqual(list(resp.body_iterable), expected)
        #
        resp = http.GET('/', headers={'HTTP_COOKIE': 'name=val', 'HTTP_X_REQUESTED_WITH': 'XMLHttpRequest'})
        self.assertEqual(list(resp.body_iterable), expected)

    def test__call___environ(self):
        def app(environ, start_response):
            start_response('200 OK', [('Content-Type', 'text/plain')])
            return [_B(environ['REQUEST_METHOD']), _B(environ['REMOTE_ADDR'])]
        http = WSGITest(app)
        resp = http.GET('/', environ={'REQUEST_METHOD': 'PATCH', 'REMOTE_ADDR': '192.168.0.1'})
        expected = [_B('PATCH'), _B('192.168.0.1')]
        self.assertEqual(list(resp.body_iterable), expected)

    def test__call___cookies(self):
        def app(environ, start_response):
            start_response('200 OK', [('Content-Type', 'text/plain')])
            return [_B(environ['HTTP_COOKIE'])]
        http = WSGITest(app)
        resp = http.GET('/', cookies={'x': '1', 'y':'2'})
        body = list(resp.body_iterable)
        assert body == [_B('x=1; y=2')] or body == [_B('y=2; x=1')]

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

    def test_nonascii_chars_in_urlpath(self):
        urlpath  = '/wiki/トップ_1-1.html'                               # native string
        pathinfo = '/wiki/\xe3\x83\x88\xe3\x83\x83\xe3\x83\x97_1-1.html' # native string
        resp = self.http.GET(urlpath)
        self.assertEqual(resp._environ['PATH_INFO'], pathinfo)


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

    def test_body_json(self):
        def app(environ, start_response):
            start_response('200 OK', [('Content-Type', 'application/json')])
            return [_B('''{"status": "OK"}''')]
        http = WSGITest(app)
        resp = http.GET('/')
        self.assertEqual(resp.body_json, {"status":"OK"})
        #
        def app(environ, start_response):
            start_response('200 OK', [('Content-Type', 'text/javascript')])
            return [_B('''{"status": "OK"}''')]
        http = WSGITest(app)
        resp = http.GET('/')
        try:
            resp.body_json
        except AssertionError:
            ex = sys.exc_info()[1]
            self.assertEqual(str(ex), "Content-Type is expected 'application/json' but got 'text/javascript'")
        else:
            raise AssertionFailed("assertion expected but not raised")

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


class MultiPart_TC(unittest.TestCase):

    def test___init__(self):
        ## can take boundary
        boundary = "---abcdef"
        assert MultiPart(boundary).boundary == boundary
        ## generates boundary when not specified
        mp = MultiPart()
        assert isinstance(mp.boundary, "".__class__)
        assert len(mp.boundary) > 30
        ## boundary should be random value
        d = {}
        for _ in range(100):
            d[MultiPart().boundary] = True
        assert len(d) == 100

    def test_add(self):
        mp = MultiPart()
        ## can add string value
        mp.add("name1", "val1")
        self.assertEqual(mp._data, [(_B("name1"), _B("val1"), None, None)])
        ## can add file value
        mp.add("name2", "val2", "ex.jpg", "image/jpeg")
        self.assertEqual(mp._data, [(_B("name1"), _B("val1"), None, None),
                                    (_B("name2"), _B("val2"), _B("ex.jpg"), _B("image/jpeg"))])
        ## returns self
        assert mp.add("name3", "val3") is mp

    def test_content_type(self):
        mp = MultiPart("abcdef")
        ## returns content type string
        self.assertEqual(mp.content_type, "multipart/form-data; boundary=abcdef")

    def test_build(self):
        mp = MultiPart("abcdef")
        ## returns multipart form data as binary data
        mp.add("name1", "value1")     # add string value
        mp.add("file1", "XYZ", "ex.jpg", "image/jpeg")  # add file
        expected = (
            '--abcdef\r\n'
            'Content-Disposition: form-data; name="name1"\r\n'
            '\r\n'
            'value1\r\n'
            '--abcdef\r\n'
            'Content-Disposition: form-data; name="file1"; filename="ex.jpg"\r\n'
            'Content-Type: image/jpeg\r\n'
            '\r\n'
            'XYZ\r\n'
            '--abcdef--\r\n'
        )
        if python3:
            binary = bytes
            expected = expected.encode('latin-1')
        self.assertEqual(mp.build(), expected)
        ## should return binary data
        if python2:
            binary = str
        elif python3:
            binary = bytes
        assert isinstance(mp.build(), binary)



if __name__ == '__main__':
    unittest.main()

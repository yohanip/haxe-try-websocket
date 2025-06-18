#if sys
import hx.ws.SecureSocketImpl;
import hx.ws.HttpResponse;
import hx.ws.HttpHeader;
import hx.ws.HttpRequest;
import hx.ws.Log;
import hx.ws.State;
import hx.ws.WebSocketCommon;
import hx.ws.Types;
#if sys
#if (haxe_ver >= 4)
import sys.thread.Thread;
#elseif neko
import neko.vm.Thread;
#elseif cpp
import cpp.vm.Thread;
#end
import haxe.crypto.Base64;
import haxe.io.Bytes;

class WebSock extends WebSocketCommon {
	public var _host:String;
	public var _port:Int;
	public var _uri:String;

	private var _processThread:Thread;
	private var _encodedKey:String = "wskey";

	public var binaryType:BinaryType;

	public var additionalHeaders(get, null):Map<String, String>;

	public function new(uri:String, immediateOpen = true) {
		var uriRegExp = ~/^(\w+?):\/\/([\w\.-]+)(:(\d+))?(\/.*)?$/;

		if (!uriRegExp.match(uri))
			throw 'Uri not matching websocket uri "${uri}"';

		var proto = uriRegExp.matched(1);
		if (proto == "wss") {
			#if (java || cs)
			throw "Secure sockets not implemented";
			#else
			_port = 443;
			var s = new SecureSocketImpl();
			super(s);
			#end
		} else if (proto == "ws") {
			_port = 80;
			super();
		} else {
			throw 'Unknown protocol $proto';
		}

		_host = uriRegExp.matched(2);
		var parsedPort = Std.parseInt(uriRegExp.matched(4));
		if (parsedPort > 0) {
			_port = parsedPort;
		}
		_uri = uriRegExp.matched(5);
		if (_uri == null || _uri.length == 0) {
			_uri = "/";
		}

		if (immediateOpen) {
			open();
		}
	}

	public function open() {
		if (state != State.Handshake) {
			throw "Socket already connected";
		}
		_socket.setBlocking(true);
		_socket.connect(new sys.net.Host(_host), _port);
		_socket.setBlocking(false);

		// haxe.MainLoop.addThread(function() {
		// 	Log.debug("Thread started", this.id);
		// 	processLoop(this);
		// 	Log.debug("Thread ended", this.id);
		// });

		sendHandshake();
	}

	private function processThread() {
		Log.debug("Thread started", this.id);
		var ws:WebSock = Thread.readMessage(true);
		processLoop(ws);
		Log.debug("Thread ended", this.id);
	}

	private function processLoop(ws:WebSock) {
		while (ws.state != State.Closed) { // TODO: should think about mutex
			ws.process();
			Sys.sleep(.01);
		}
	}

    public function hxd_update() {
        this.process();
    }

	function get_additionalHeaders() {
		if (additionalHeaders == null) {
			additionalHeaders = new Map<String, String>();
		}
		return additionalHeaders;
	}

	public function sendHandshake() {
		var httpRequest = new HttpRequest();
		httpRequest.method = "GET";
		httpRequest.uri = _uri;
		httpRequest.httpVersion = "HTTP/1.1";

		httpRequest.headers.set(HttpHeader.HOST, _host + ":" + _port);
		httpRequest.headers.set(HttpHeader.USER_AGENT, "hxWebSockets");
		httpRequest.headers.set(HttpHeader.SEC_WEBSOSCKET_VERSION, "13");
		httpRequest.headers.set(HttpHeader.UPGRADE, "websocket");
		httpRequest.headers.set(HttpHeader.CONNECTION, "Upgrade");
		httpRequest.headers.set(HttpHeader.PRAGMA, "no-cache");
		httpRequest.headers.set(HttpHeader.CACHE_CONTROL, "no-cache");
		httpRequest.headers.set(HttpHeader.ORIGIN, _socket.host().host.toString() + ":" + _socket.host().port);

		_encodedKey = generateWSKey();
		httpRequest.headers.set(HttpHeader.SEC_WEBSOCKET_KEY, _encodedKey);

		if (additionalHeaders != null) {
			for (k in additionalHeaders.keys()) {
				httpRequest.headers.set(k, additionalHeaders[k]);
			}
		}

		sendHttpRequest(httpRequest);
	}

	private override function handleData() {
		switch (state) {
			case State.Handshake:
				var httpResponse = recvHttpResponse();
				if (httpResponse == null) {
					return;
				}

				handshake(httpResponse);
				handleData();
			case _:
				super.handleData();
		}
	}

	private function handshake(httpResponse:HttpResponse) {
		if (httpResponse.code != 101) {
			if (onerror != null) {
				onerror(httpResponse.headers.get(HttpHeader.X_WEBSOCKET_REJECT_REASON));
			}
			close();
			return;
		}

		var secKey = httpResponse.headers.get(HttpHeader.SEC_WEBSOSCKET_ACCEPT);
		if (secKey != makeWSKeyResponse(_encodedKey)) {
			if (onerror != null) {
				onerror("Error during WebSocket handshake: Incorrect 'Sec-WebSocket-Accept' header value");
			}
			close();
			return;
		}

		_onopenCalled = false;
		state = State.Head;
	}

	private function generateWSKey():String {
		var b = Bytes.alloc(16);
		for (i in 0...16) {
			b.set(i, Std.random(255));
		}
		return Base64.encode(b);
	}
}
#end
#end
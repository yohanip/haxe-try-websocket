import haxe.MainLoop;
import hx.ws.Log;
import hx.ws.WebSocket;
import hx.ws.WebSocketServer;
import hx.ws.Types.MessageType;
import hx.ws.WebSocketHandler;

class ServerHandler2 extends WebSocketHandler {
	public function new(s) {
		super(s);

		onclose = function() {
			trace('client $id disconnected');
		}

		onerror = function(e) {
			trace('client $id error: $e');
		}

		onmessage = function(mt:MessageType) {
			switch (mt) {
				case BytesMessage(content):
					trace('client sent bytes: ${content.readAllAvailableBytes().toString()}');
				case StrMessage(content):
					trace('client sent string: $content');
			}
		}

		onopen = function() {
			trace('client $id connected');
			send("hello");
		}
	}
}

#if js
function setup_js(host:String, port:Int) {
	var client = new WebSocket('ws://$host:$port', true);
	setup_client(client);
}
#end

#if sys
function setup_sys(host:String, port:Int) {
	try {
		var server = new WebSocketServer<ServerHandler2>(host, port, 15);
		server.start();
	} catch (e:Dynamic) {
		#if debug
		var client = new WebSock('ws://$host:$port', true);
		#else
		var client = new WebSocket('ws://$host:$port', true);
		#end

		setup_client(client);

		#if debug
		MainLoop.add(function() {
			client.hxd_update();
		});
		#end
	}
}
#end

function setup_client(c:Any) {
	#if js
	var client:WebSocket = cast c;
	#else
	#if debug
	var client:WebSock = cast c;
	#else
	var client:WebSocket = cast c;
	#end
	#end

	client.onclose = function() {
		trace('disconnected from server');
	}

	client.onerror = function(e) {
		trace('connection to server error: $e');
	}

	client.onmessage = function(mt:MessageType) {
		switch (mt) {
			case BytesMessage(content):
				trace('received from server bytes: ${content.readAllAvailableBytes().toString()}');
			case StrMessage(content):
				trace('received from server string: $content');
		}
	}

	client.onopen = function() {
		trace('connected to server');
		client.send("Hello-Server");
	}
}

class Application extends hxd.App {
	override function init() {
		var host = "localhost";
		var port = 8787;
		var max_connections = 1;

		Log.mask = Log.DEBUG | Log.INFO;

		#if js
		setup_js(host, port);
		#else
		setup_sys(host, port);
		#end
	}
}

class MainSys {
	public static var app:Application;

	public static function main() {
		app = new Application();
	}
}

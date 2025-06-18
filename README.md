- hashlink
  select from vscode: 
 - debug hl1 to run the hl server
 - debug hl2 to run the hl client
- js
  remember to run the server first!
  - debug launch chrome

## why creating WebSock derived from hx.ws.WebSocket?
Because debugging a threaded haxe makes the app unstable, i use mainloop instead to update the socket

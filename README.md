# Hello
## How to run
1. In `VSCode` select configuration  `sys.build.hxml`
2. Go to debug panel
    - Select **HL1**, press debug
	- Select **HL2**, press debug
	- Select **Launch Chrome**, press debug
 3. Voila!
## Why
Because debugging a threaded `Haxe` makes the app unstable, I use `haxe.Mainloop` instead to update the socket

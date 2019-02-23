#  SwiftyLetsMove

This project is heavily inspired by [LetsMove](https://github.com/potionfactory/LetsMove). However, LetsMove appears to have abandoned support and isn't currently compatible with the current version of Xcode.

I basically copied the entire code design, but implemented in Swift instead. I removed a lot of fringe cases, primarily covering older OS releases and simply focused on what's current now. I don't know what the oldest OS release it is compatible with, but I would assume at least as far back as 10.11.

It should be compatible with Carthage

	github "mredig/SwiftyLetsMove"
	
Then run `carthage update` and put `LetsMove.shared.moveToApplicationsFolderIfNecesary()` in your `applicationDidFinishLaunching` in your AppDelegate.

Unit tests are not comprehensive, but there's a decent start to them.


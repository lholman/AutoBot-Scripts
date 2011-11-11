# AutoBot-Scripts
A collection of community PowerShell scripts for [AutoBot](https://github.com/lholman/AutoBot).
[AutoBot](https://github.com/lholman/AutoBot) is inspired by GitHub's splendid [HUBOT](http://hubot.github.com/) and a childhood love of [Transformers](http://en.wikipedia.org/wiki/Autobot), [AutoBot](https://github.com/lholman/AutoBot) however is a chat bot for the Windows crew. 

+ The core bot engine is written in C# (.NET 4), his functionality and extensibility is provided by the addition of PowerShell 2.0 script modules which are dynamically loaded and executed at runtime.
+ AutoBot currently chats only with the [XMPP](http://xmpp.org/about-xmpp/) powered awesomeness that is [HipChat](http://www.hipchat.com) using the [jabber-net](http://code.google.com/p/jabber-net/) library

_WARNING_: AutoBot is an infant and has some obvious (and other not so obvious) restrictions/issues/flaws, please take a look at [AutoBot's current issues](https://github.com/lholman/AutoBot/issues?labels=AutoBot.Engine&sort=created&direction=desc&state=open&page=1) before continuing.

## Writing Scripts
AutoBot's scripts are written in [PowerShell 2.0](http://en.wikipedia.org/wiki/Windows_PowerShell) as [Script Modules](http://msdn.microsoft.com/en-us/library/windows/desktop/dd878340(v=vs.85).aspx) utilising the power of [Advanced Functions](http://technet.microsoft.com/en-us/magazine/hh413265.aspx) for consistent documentation. 

AutoBot comes with a [couple of simple scripts](https://github.com/lholman/AutoBot/tree/master/src/AutoBot.Cmd/Scripts) to get you started, so have a look there first and of course check the ones [here](https://github.com/lholman/AutoBot-Scripts/src).

Scripts can come from [here](https://github.com/lholman/AutoBot-Scripts), as part of the [AutoBot build](https://github.com/lholman/AutoBot), or from your own repository, however they must ultimately sit in the AutoBot\Scripts folder of your AutoBot installation.  We tend to use TeamCity[http://www.jetbrains.com/teamcity/] to munge all the above together and output our deployable version of AutoBot with Scripts included. 
 
### Guidelines
These are the current guidelines for writing scripts and should give you the best chance of getting a sensible response from AutoBot.

+ Scripts must be a script module, i.e. Get-Help.psm1
+ The main returning function must have the same name as the script itself

		function Get-Help {
		...
		}
	
+ Scripts must utilise [Advanced Functions](http://technet.microsoft.com/en-us/magazine/hh413265.aspx) to aid in discoverability and consistency of documentation

_Note:_ Some of the above are optional, however for inclusion here we ask that they are all adhered to.
	
## Contributing To AutoBot Scripts
1. [Fork it](http://help.github.com/fork-a-repo/).
1. Commit your changes (git commit -am "Added cool feature")
1. Send us a [Pull Request](http://help.github.com/send-pull-requests/)

## Building Your AutoBot 
1. Head on over to [AutoBot](https://github.com/lholman/AutoBot/blob/master/README.markdown)

## Running Your AutoBot
1. Head on over to [AutoBot](https://github.com/lholman/AutoBot/blob/master/README.markdown)

## Contributing To AutoBot's Core Engine
1. Head on over to [AutoBot](https://github.com/lholman/AutoBot/blob/master/README.markdown)

## Disclaimer
NO warranty, expressed or written
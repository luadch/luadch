--[[

	cmd_talk by pulsar
    
        v0.7:
            - changed rightclick style
            
        v0.6:
            - export scriptsettings to "/cfg/cfg.tbl"
            
        v0.5:
            - cleaning code
            
        v0.4:
            - Multilanguage Support
            - Absofort Bestandteil der Revision (ab rev279)
            
        v0.3:
            - Code-Kosmetik
            - Hinzugefügt: Help Feature (hub.import "cmd_help")
            
        v0.2:
            - Das Script ermöglicht das 'talken' ohne Nicknamen im Mainchat,
              die Nachricht wird vom Hubbot gesendet.

]]--



--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_talk"
local scriptversion = "0.7"

local cmd = "talk"

local minlevel = cfg.get "cmd_talk_minlevel"


----------
--[CODE]--
----------

local scriptlang = cfg.get "language"
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local help_title = lang.help_title or "Talk"
local help_usage = lang.help_usage or "[+!#]talk <msg>"
local help_desc = lang.help_desc or "Im Main chatten ohne Nick"

local msg_denied = lang.msg_denied or "Du bist nicht berechtigt diesen Befehl zu nutzen!"
local ucmd_menu = lang.ucmd_menu or { "User", "Messages", "Talk" }
local ucmd_what = lang.ucmd_what or "Nachricht:"

local utf_match = utf.match

hub.setlistener( "onBroadcast", {},
    function( user, adccmd, txt )
        local cmd1, cmd2 = utf_match( txt, "^[+!#](%a+) (.+)" )
        local user_level = user:level()
        local hub_getbot = hub.getbot()
        if cmd1 == cmd and cmd2 then
            if user_level >= minlevel then
                hub.broadcast( cmd2, hub_getbot )
            else
                user:reply( msg_denied, hub_getbot )
            end
            return PROCESSED
        end
        return nil
    end
)

hub.setlistener( "onStart", {},
    function()
        local help = hub.import "cmd_help"
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub.import "etc_usercommands"
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { "%[line:"..ucmd_what.."]" }, { "CT1" }, minlevel )
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )

---------
--[END]--
---------
--[[

	cmd_ascii by pulsar

        v0.4
            - export scriptsettings to "/cfg/cfg.tbl"
            
        v0.3
            - cleaning code
            
        v0.2
            - ASCII Script zum Senden von Bildern in den Main
        
        v0.1
            - first test
]]--



--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_ascii"
local scriptversion = "0.4"

local cmd = "ascii"  --> Befehl
local minlevel = cfg.get "cmd_ascii_minlevel"


----------
--[CODE]--
----------

local utf_match = utf.match
local lang, err = cfg.loadlanguage( cfg.get"language", scriptname ); err = err and hub.debug( err )

local hub_getbot = hub.getbot()

hub.setlistener( "onStart", {},
    function()
        local help = hub.import"cmd_help"
        if help then
            local tmp = {}
            for opt,_ in pairs( lang.pics ) do
                table.insert( tmp, opt )
                table.sort( tmp )
            end
            local list = table.concat( tmp, ", " )
            help.reg( lang.help_title, lang.help_usage, lang.help_desc .. list, minlevel )
        end
        local ucmd = hub.import"etc_usercommands"
        if ucmd then
            local menu = lang.ucmd_menu
            local tmp = {}
            for opt,_ in pairs( lang.pics ) do
                table.insert( tmp, opt )
            end
            table.sort( tmp )
            for i,opt in pairs( tmp ) do
                menu[#menu + 1] = opt
                ucmd.add( menu, cmd, { opt }, { "CT1" }, minlevel )
                menu[#menu] = nil
                table.remove( menu, 1 )
            end
        end
        return nil
    end
)

hub.setlistener( "onBroadcast", {},
    function( user, adccmd, txt )
        local command, opt = utf_match( txt, "^[+!#](%a+) (.+)" )
        if command == cmd then
            if user:level() >= minlevel then
                if lang.pics[opt] then
                    hub.broadcast( lang.pics[opt]( hub.escapefrom( user:nick() ) ), hub_getbot )
                    return PROCESSED
                else
                    user:reply( lang.help_err, hub_getbot )
                    return PROCESSED
                end
            end
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )

---------
--[END]--
---------
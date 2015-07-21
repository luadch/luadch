--[[

    cmd_restart.lua by blastbeat

        - this script adds a command "restart" to restart the hub
        - usage: [+!#]restart

        v0.07: by pulsar
            - add table lookups
            - clean code
            - removed "cmd_restart_minlevel" import
                - using util.getlowestlevel( tbl ) instead of "cmd_restart_minlevel"
        
        v0.06: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"
            
        v0.05: by pulsar
            - add ascii countdown mode
            - toggle countown on/off
            
        v0.04: by blastbeat
            - updated script api
            - renamed command
            - regged hubcommand
            
        v0.03: by blastbeat
            - added language files and ucmd
            
        v0.02: by blastbeat
            - updated script api

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_restart"
local scriptversion = "0.07"

local cmd = "restart"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_getbot = hub.getbot()
local hub_import = hub.import
local hub_restart = hub.restart
local hub_broadcast = hub.broadcast
local utf_match = utf.match
local os_time = os.time
local os_difftime = os.difftime
local util_getlowestlevel = util.getlowestlevel

--// imports
local hubcmd
local scriptlang = cfg_get( "language" )
local permission = cfg_get( "cmd_restart_permission" )
local toggle_countdown = cfg_get( "cmd_restart_toggle_countdown" )

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local help_title = lang.help_title or "cmd_restart.lua"
local help_usage = lang.help_usage or "[+!#]restart"
local help_desc = lang.help_desc or "Restarts hub"

local ucmd_menu = lang.ucmd_menu or { "Hub", "Core", "Hub restart", "CLICK" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_ok = lang.msg_ok or "Hub restarted."
local msg_countdown = lang.msg_countdown or "*** Hubrestart in ***"


----------
--[CODE]--
----------

local digital = {

    [0] = [[
                                                        ####
                                                        #     #
                                                        #     #
                                                        #     #
                                                        ####
        ]],
    [1] = [[
                                                           #
                                                           #
                                                           #
                                                           #
                                                           #
        ]],
    [2] = [[
                                                        ####
                                                               #
                                                        ####
                                                        #    
                                                        ####
        ]],
    [3] = [[
                                                        ####
                                                               #
                                                        ####
                                                               #
                                                        ####
        ]],
    [4] = [[
                                                        #     #
                                                        #     #
                                                        ####
                                                               #
                                                               #
        ]],
    [5] = [[
                                                        ####
                                                        #    
                                                        ####
                                                               #
                                                        ####
        ]],
    [6] = [[
                                                        ####
                                                        #    
                                                        ####
                                                        #     #
                                                        ####
        ]],
    [7] = [[
                                                        ####
                                                               #
                                                               #
                                                               #
                                                               #
        ]],
    [8] = [[
                                                        ####
                                                        #     #
                                                        ####
                                                        #     #
                                                        ####
        ]],
    [9] = [[
                                                        ####
                                                        #     #
                                                        ####
                                                               #
                                                               #
        ]],
}

local minlevel = util_getlowestlevel( permission )
local list = { }
local delay = 9  --> delay in sec (max. 9)
local countdown = delay - 1

local onbmsg = function( user, command )
    if not permission[ user:level() ] then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    if toggle_countdown then
        list[ os_time() ] = function()
            hub_restart()
        end
    else
        user:reply( msg_ok, hub_getbot )
        hub_restart()
    end
    return PROCESSED
end

hub.setlistener("onTimer", {},
    function()
        for time, func in pairs( list ) do
            if os_difftime( os_time() - time ) >= delay then
                func()
                list[ time ] = nil
            end
            if digital[ countdown ] then
                hub_broadcast( msg_countdown .. "\n\n" .. digital[ countdown ], hub_getbot )
                countdown = countdown - 1
            end
            if digital[ countdown ] == nil then
                countdown = countdown - 1
            end
        end
        return nil
    end
)

hub.setlistener( "onStart", { },
    function( )
        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub_import( "etc_usercommands" )  -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { }, { "CT1" }, minlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )  -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
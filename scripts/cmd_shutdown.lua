--[[

    cmd_shutdown.lua by blastbeat

        - this script adds a command "shutdown" to shutdown the hub
        - usage: [+!#]shutdown

        v0.07: by pulsar
            - add table lookups
            - clean code
            - removed "cmd_shutdown_minlevel" import
                - using util.getlowestlevel( tbl ) instead of "cmd_shutdown_minlevel"
        
        v0.06: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"
            
        v0.05: by pulsar
            - add ascii countdown mode
            - toggle countown on/off
            
        v0.04: by blastbeat
            - updated script api
            - regged hubcommand
            
        v0.03: by blastbeat
            - added language files and ucmd
            
        v0.02: by blastbeat
            - updated script api

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_shutdown"
local scriptversion = "0.07"

local cmd = "shutdown"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_getbot = hub.getbot()
local hub_import = hub.import
local hub_broadcast = hub.broadcast
local hub_exit = hub.exit
local os_time = os.time
local os_difftime = os.difftime
local utf_match = utf.match
local util_getlowestlevel = util.getlowestlevel

--// imports
local hubcmd
local scriptlang = cfg_get( "language" )
local permission = cfg_get( "cmd_shutdown_permission" )
local toggle_countdown = cfg_get( "cmd_shutdown_toggle_countdown" )

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )

local help_title = lang.help_title or "shutdown"
local help_usage = lang.help_usage or "[+!#]shutdown"
local help_desc = lang.help_desc or "shutdowns hub"

local ucmd_menu = lang.ucmd_menu or { "Shutdown hub" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_ok = lang.msg_ok or "Shutdown hub..."
local msg_countdown = lang.msg_countdown or "*** Hubshutdown in ***"


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
            hub_exit()
        end
    else
        user:reply( msg_ok, hub_getbot )
        hub_exit()
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
                hub_broadcast( msg_countdown.."\n\n"..digital[ countdown ], hub_getbot )
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
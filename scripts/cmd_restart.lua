--[[

    cmd_restart.lua by blastbeat

        - this script adds a command "restart" to restart the hub
        - usage: [+!#]restart [<MSG>]

        v0.09: by pulsar
            - added "update_lastlogout" function
            - removed table lookups

        v0.08: by pulsar
            - possibility to send optional mass msg  / thx Sopor

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
local scriptversion = "0.09"

local cmd = "restart"

--// imports
local hubcmd
local scriptlang = cfg.get( "language" )
local permission = cfg.get( "cmd_restart_permission" )
local toggle_countdown = cfg.get( "cmd_restart_toggle_countdown" )

--// msgs
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local help_title = lang.help_title or "cmd_restart.lua"
local help_usage = lang.help_usage or "[+!#]restart [<MSG>]"
local help_desc = lang.help_desc or "Restarts hub"

local ucmd_menu = lang.ucmd_menu or { "Hub", "Core", "Hub restart", "CLICK" }
local ucmd_msg = lang.ucmd_msg or "Mass Message (optional)"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_ok = lang.msg_ok or "Hub restarted."
local msg_countdown = lang.msg_countdown or "*** Hubrestart in ***"
local msg_restart = lang.msg_restart or [[


=== HUB RESTART ======================================================================================================

  %s

====================================================================================================== HUB RESTART ===

  ]]


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

local minlevel = util.getlowestlevel( permission )
local list = { }
local delay = 9  --> delay in sec (max. 9)
local countdown = delay - 1

local update_lastlogout = function()
    local user_tbl = hub.getregusers()
    for i, v in pairs( user_tbl ) do
        if ( user_tbl[ i ].is_bot ~= 1 ) and ( user_tbl[ i ].is_online == 1 ) then
            user_tbl[ i ].lastlogout = util.date()
        end
    end
    cfg.saveusers( user_tbl )
end

local onbmsg = function( user, command, parameters )
    if not permission[ user:level() ] then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    local comment = utf.match( parameters, "^(.*)" )
    if comment ~= "" then hub.broadcast( utf.format( msg_restart, comment ), hub.getbot(), hub.getbot() ) end
    if toggle_countdown then
        list[ os.time() ] = function()
            update_lastlogout()
            hub.restart()
        end
    else
        user:reply( msg_ok, hub.getbot() )
        update_lastlogout()
        hub.restart()
    end
    return PROCESSED
end

hub.setlistener("onTimer", {},
    function()
        for time, func in pairs( list ) do
            if os.difftime( os.time() - time ) >= delay then
                func()
                list[ time ] = nil
            end
            if digital[ countdown ] then
                hub.broadcast( msg_countdown .. "\n\n" .. digital[ countdown ], hub.getbot() )
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
        local help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub.import( "etc_usercommands" )  -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { "%[line:" .. ucmd_msg .. "]" }, { "CT1" }, minlevel )
        end
        hubcmd = hub.import( "etc_hubcommands" )  -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
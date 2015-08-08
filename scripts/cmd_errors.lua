--[[

    cmd_errors.lua by blastbeat

        - this script adds a command "errors" to get hub errors
        - usage: [+!#]errors
        
        v0.10: by pulsar
            - improve rightclick entries  / thx Sopor
        
        v0.09: by pulsar
            - removed "cmd_errors_minlevel" import
                - using util.getlowestlevel( tbl ) instead of "cmd_errors_minlevel"
        
        v0.08: by pulsar
            - add table lookups
            - send msg instead of " " if error.log is empty
        
        v0.07: by pulsar
            - changed rightclick style

        v0.06: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"
            
        v0.05: by blastbeat
            - fixed small bug

        v0.04: by blastbeat
            - updated script api
            - regged hubcommand

        v0.03: by blastbeat
            - some clean ups

        v0.02: by blastbeat
            - added language files and ucmd

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_errors"
local scriptversion = "0.10"

local cmd = "errors"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_getbot = hub.getbot()
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_import = hub.import
local hub_debug = hub.debug
local utf_match = utf.match
local util_getlowestlevel = util.getlowestlevel

--// imports
local scriptlang = cfg_get( "language" )
local permission = cfg_get( "cmd_errors_permission" )
local path = "log/error.log"

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local help_title = lang.help_title or "cmd_errors.lua"
local help_usage = lang.help_usage or "[+!#]errors"
local help_desc = lang.help_desc or "Sends error.log"

local ucmd_menu = lang.ucmd_menu or { "Hub", "Logs", "show", "error.log" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_noerrors = lang.msg_noerrors or "No errors"


----------
--[CODE]--
----------

local minlevel = util_getlowestlevel( permission )

local onbmsg = function( user, command, parameters )
    if not permission[ user:level() ] then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    local log
    local file, err = io.open( path, "r" )
    if file then
        log = file:read( "*a" )
        file:close()
    end
    if not log or log == "" then
        user:reply( msg_noerrors, hub_getbot )
    else
        user:reply( "\n\n" .. log .. "\n\n", hub_getbot, hub_getbot )
    end
    return PROCESSED
end

hub.setlistener( "onStart", { },
    function( )
        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { }, { "CT1" }, minlevel )
        end
        local hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
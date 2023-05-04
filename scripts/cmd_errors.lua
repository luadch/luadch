--[[

    cmd_errors.lua by blastbeat

        - this script adds a command "errors" to get hub errors, it also feeds errors to hubowners
        - usage: [+!#]errors

        v0.12: by pulsar
            - removed table lookups
            - removed unused code
            - changed visuals

        v0.11: by pulsar
            - added "onError" listener to feed errors to hubowners
            - added maxlines limit to send

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
local scriptversion = "0.12"

local cmd = "errors"

local maxlines = 200

--// imports
local scriptlang = cfg.get( "language" )
local permission = cfg.get( "cmd_errors_permission" )
local path = "log/error.log"

--// msgs
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local help_title = lang.help_title or "cmd_errors.lua"
local help_usage = lang.help_usage or "[+!#]errors"
local help_desc = lang.help_desc or "Sends error.log"

local ucmd_menu = lang.ucmd_menu or { "Hub", "Logs", "show", "error.log" }

local msg_denied = lang.msg_denied or "[ ERRORS ]--> You are not allowed to use this command."
local msg_noerrors = lang.msg_noerrors or "[ ERRORS ]--> No errors."


----------
--[CODE]--
----------

local minlevel = util.getlowestlevel( permission )
local report_send

local onbmsg = function( user, command, parameters )
    if not permission[ user:level() ] then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    local tbl = {}
    local file, err = io.open( path, "r" )
    if file then
        for line in file:lines() do tbl[ #tbl + 1 ] = line end
        file:close()
    end
    if next( tbl ) == nil then
        user:reply( msg_noerrors, hub.getbot() )
    else
        if #tbl < maxlines then
            user:reply( "\n\n" .. table.concat( tbl, "\n" ) .. "\n", hub.getbot(), hub.getbot() )
        else
            local s, e, msg = 1, #tbl - maxlines, ""
            for k, v in ipairs( tbl ) do
                if s >= e then msg = msg .. v .. "\n" end
                s = s + 1
            end
            user:reply( "\n\n" .. msg .. "\n", hub.getbot(), hub.getbot() )
        end
    end
    return PROCESSED
end

hub.setlistener( "onError", { },  -- when this function produces any error, it won't be reported to avoid endless loops
    function( msg )
        report_send( true, true, false, 100, msg )  -- new method
    end
)

hub.setlistener( "onStart", { },
    function( )
        local help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { }, { "CT1" }, minlevel )
        end
        local hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        local report = hub.import( "etc_report" )
        assert( report )
        report_send = report.send
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
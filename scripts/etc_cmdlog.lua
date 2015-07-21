--[[

    etc_cmdlog by pulsar

        Description: logs commands and saves it to a log file (who, what, when)
        
        v1.0:
            - add table lookups
            - cleaning code
            - change date style
        
        v0.9:
            - changed visual output style

        v0.8:
            - removed "etc_cmdlog_label_top" and "etc_cmdlog_label_bottom" var
            - changed visual output style
            - code cleaning
            - table lookups

        v0.7:
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.6:
            - removed main output

        v0.5:
            - added file exists check

        v0.4:
            - added lang feature

        v0.3:
            - code cleaning
            - help feature

        v0.2:
            - some optical changes
            - choose: send to main/pm

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_cmdlog"
local scriptversion = "1.0"

local cmd = "cmdlog"
local cmd_p = "show"


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
local utf_format = utf.format
local os_date = os.date

--// imports
local logfile = "log/cmd.log"
local minlevel = cfg_get( "etc_cmdlog_minlevel" )
local command_tbl = cfg_get( "etc_cmdlog_command_tbl" ) or {}
local scriptlang = cfg_get( "language" )

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )

local help_title = lang.help_title or "etc_cmdlog.lua"
local help_usage = lang.help_usage or "[+!#]cmdlog show"
local help_desc = lang.help_desc or "Shows the command log"

local msg_denied = lang.failmsg1 or "You are not allowed to use this command."
local msg_nofile = lang.failmsg2 or "No 'cmd.log' found."
local msg_usage = lang.msg_usage or "Usage: [+!#]cmdlog show"

local msg1 = lang.msg1 or "   |   Command: [+!#]"
local msg2 = lang.msg2 or "   |   used by: "

local msg_out = lang.msg_out or [[[

    
=== COMMAND LOGGER ========================================================================================

%s
======================================================================================== COMMAND LOGGER ===

      ]]

local ucmd_menu = lang.ucmd_menu or { "Hub", "Logs", "Show", "Show cmd.log" }


----------
--[CODE]--
----------

hub.setlistener( "onBroadcast", {},
    function( user, adccmd, txt )
        local s1, s2 = utf_match( txt, "^[+!#](%S+) (.+)" )
        for command, _ in pairs( command_tbl ) do
            if s1 == command and s2 then
                local f = io.open( logfile, "a" )
                local user_nick = user:nick()
                f:write( os_date( "  [ %Y-%m-%d / %H:%M:%S ]" ) .. msg1 .. s1 .. " " .. s2 .. msg2 .. user_nick .. "\n" )
                f:close()
            end
        end
    end
)

local onbmsg = function( user, adccmd, parameters, txt )
    local id = utf_match( parameters, "^(%S+)$" )
    if id == cmd_p then
        if user:level() >= minlevel then
            local msg, msg_log
            local file, err = io.open( logfile, "r" )
            if file then
                msg = file:read( "*a" )
                file:close()
                msg_log = utf_format( msg_out, msg )
                user:reply( msg_log, hub_getbot, hub_getbot )
                return PROCESSED
            else
                user:reply( msg_nofile, hub_getbot )
                return PROCESSED
            end
        else
            user:reply( msg_denied, hub_getbot )
            return PROCESSED
        end
    else
        user:reply( msg_usage, hub_getbot )
        return PROCESSED
    end
end

local hubcmd

hub.setlistener("onStart", {},
    function()
        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { cmd_p }, { "CT1" }, minlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

---------
--[END]--
---------
--[[

    etc_log_cleaner.lua by pulsar

        usage: [+!#]cleanlog error|cmd
        
        v0.8:
            - improved rightclick entries  / thx Sopor
            - improved some parts of code (table lookups etc)
            - changed "help_usage"
            - added "msg_usage"

        v0.7:
            - changed rightclick style

        v0.6:
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.5:
            - cleaning code

        v0.4:
            - added lang feature

        v0.3:
            - added help feature

        v0.2:
            - added "cmd.log"

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_log_cleaner"
local scriptversion = "0.8"

local cmd = "cleanlog"

local cmd_p_error = "error"
local cmd_p_cmd = "cmd"
local cmd_p_event = "event"



----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_import = hub.import
local hub_getbot = hub.getbot()
local utf_match = utf.match
local io_open = io.open

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )
local minlevel = cfg_get( "etc_log_cleaner_minlevel" )
local activate_error = cfg_get( "etc_log_cleaner_activate_error" )
local activate_cmd = cfg_get( "etc_log_cleaner_activate_cmd" )
local activate_event = cfg_get( "etc_log_cleaner_activate_event" )


local logfile_error = "log/error.log"
local logfile_cmd = "log/cmd.log"
local logfile_event = "log/event.log"


--// msgs
local help_title = lang.help_title or "etc_log_cleaner.lua"
local help_usage = lang.help_usage or "[+!#]cleanlog error|cmd|event"
local help_desc = lang.help_desc or "Cleans logfiles"

local failmsg = lang.failmsg or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or "Usage: [+!#]cleanlog error|cmd|event"

local activate_error_msg = lang.activate_error_msg or "The 'error.log' cleaner is disabled"
local activate_cmd_msg = lang.activate_cmd_msg or "The 'cmd.log' cleaner is disabled"
local activate_event_msg = lang.activate_event_msg or "The 'event.log' cleaner is disabled"

local logfile_error_msg = lang.logfile_error_msg or "The 'error.log' was cleaned"
local logfile_cmd_msg = lang.logfile_cmd_msg or "The 'cmd.log' was cleaned"
local logfile_event_msg = lang.logfile_event_msg or "The 'event.log' was cleaned"

local ucmd_menu_error = lang.ucmd_menu_error or { "Hub", "Logs", "clean", "error.log" }
local ucmd_menu_cmd = lang.ucmd_menu_cmd or { "Hub", "Logs", "clean", "cmd.log" }
local ucmd_menu_event = lang.ucmd_menu_event or { "Hub", "Logs", "clean", "event.log" }


----------
--[CODE]--
----------

local cleanlog = function( log )
    local f = io_open( log, "w+" )
    f:write()
    f:close()
end

local onbmsg = function( user, adccmd, parameters, txt )
    local user_level = user:level()
    local id = utf_match( parameters, "^(%S+)$" )
    if user_level < minlevel then
        user:reply( failmsg, hub_getbot )
        return PROCESSED
    end
    if id == cmd_p_error then
        if activate_error then
            cleanlog( logfile_error )
            user:reply( logfile_error_msg, hub_getbot )
        else
            user:reply( activate_error_msg, hub_getbot )
        end
        return PROCESSED
    end
    if id == cmd_p_cmd then
        if activate_cmd then
            cleanlog( logfile_cmd )
            user:reply( logfile_cmd_msg, hub_getbot )
        else
            user:reply( activate_cmd_msg, hub_getbot )
        end
        return PROCESSED
    end
    if id == cmd_p_event then
        if activate_cmd then
            cleanlog( logfile_event )
            user:reply( logfile_event_msg, hub_getbot )
        else
            user:reply( activate_event_msg, hub_getbot )
        end
        return PROCESSED
    end

    user:reply( msg_usage, hub_getbot )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_error, cmd, { cmd_p_error }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_cmd, cmd, { cmd_p_cmd }, { "CT1" }, minlevel )
        end
        local hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

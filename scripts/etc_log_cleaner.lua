--[[

    etc_log_cleaner by pulsar

        v0.7
            - changed rightclick style

        v0.6
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.5
            - cleaning code

        v0.4
            - added lang feature

        v0.3
            - added help feature

        v0.2
            - added "cmd.log"

]]--



--------------
--[SETTINGS]--
--------------

local scriptname = "etc_log_cleaner"
local scriptversion = "0.7"

--> Befehl
--> command
local cmd = "cleanlog"

--> Parameter für 'error.log'
--> parameter for 'error.log'
local cmd_p_error = "error"

--> Befehlsparameter für 'cmd.log'
--> parameter for 'cmd.log'
local cmd_p_cmd = "cmd"


local minlevel = cfg.get "etc_log_cleaner_minlevel"
local activate_error = cfg.get "etc_log_cleaner_activate_error"
local activate_cmd = cfg.get "etc_log_cleaner_activate_cmd"

--> Dateiname/Pfad 'error.log'
--> filename/path 'error.log'
local logfile_error = "log/error.log"

--> Dateiname/Pfad 'cmd.log'
--> filename/path 'cmd.log'
local logfile_cmd = "log/cmd.log"


----------
--[CODE]--
----------

local scriptlang = cfg.get "language"
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local help_title = lang.help_title or "Log Cleaner"
local help_usage = lang.help_usage or "[+!#]cleanlog error / [+!#]cleanlog cmd"
local help_desc = lang.help_desc or "Löscht den Inhalt von Logdateien"

local failmsg = lang.failmsg or "Du bist nicht befugt diesen Befehl zu nutzen!"

local activate_error_msg = lang.activate_error_msg or "Der 'error.log' Cleaner ist deaktiviert!"
local activate_cmd_msg = lang.activate_cmd_msg or "Der 'cmd.log' Cleaner ist deaktiviert!"

local logfile_error_msg = lang.logfile_error_msg or "Der Inhalt der 'error.log' wurde gelöscht!"
local logfile_cmd_msg = lang.logfile_cmd_msg or "Der Inhalt der 'cmd.log' wurde gelöscht!"

local ucmd_menu_error = lang.ucmd_menu_error or { "Hub", "Logs", "clean", "clean error.log" }
local ucmd_menu_cmd = lang.ucmd_menu_cmd or { "Hub", "Logs", "clean", "clean cmd.log" }

local onbmsg = function( user, adccmd, parameters, txt )
    local user_level = user:level()
    local hub_getbot = hub.getbot()
    local utf_match = utf.match
    local id = utf_match( parameters, "^(%S+)$" )
    if id == cmd_p_error then
        if user_level >= minlevel then
            if activate_error == true then
                local f = io.open( logfile_error, "w+" )
                f:write()
                f:close()
                user:reply( logfile_error_msg, hub_getbot )
            else
                user:reply( activate_error_msg, hub_getbot )
            end
        else
            user:reply( failmsg, hub_getbot )
        end
    end
    if id == cmd_p_cmd then
        if user_level >= minlevel then
            if activate_cmd == true then
                local f = io.open( logfile_cmd, "w+" )
                f:write()
                f:close()
                user:reply( logfile_cmd_msg, hub_getbot )
            else
                user:reply( activate_cmd_msg, hub_getbot )
            end
        else
            user:reply( failmsg, hub_getbot )
        end
    end
    return PROCESSED
end

local hubcmd

hub.setlistener( "onStart", {},
    function()
        local help = hub.import "cmd_help"
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub.import "etc_usercommands"
        if ucmd then
            ucmd.add( ucmd_menu_error, cmd, { cmd_p_error }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_cmd, cmd, { cmd_p_cmd }, { "CT1" }, minlevel )
        end
        hubcmd = hub.import "etc_hubcommands"
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )

---------
--[END]--
---------
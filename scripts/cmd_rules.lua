--[[

    cmd_rules.lua by blastbeat

        - this script adds a command "rules" for hub rules
        - usage: [+!#]rules

        v0.06: by pulsar
            - removed "cmd_rules_rules" from "/cfg/cfg.tbl"
            - added rules msg to the lang files

        v0.05: by pulsar
            - possibility to set target (main/pm/both)
            - add new table lookups
            - code cleaning

        v0.04: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.03: by blastbeat
            - updated script api
            - regged hubcommand

        v0.02: by blastbeat
            - added language files and ucmd

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_rules"
local scriptversion = "0.06"

local cmd = "rules"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_getbot = hub.getbot()
local hub_debug = hub.debug
local hub_import = hub.import

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )
local minlevel = cfg_get( "cmd_rules_minlevel" )
local destination_main = cfg_get( "cmd_rules_destination_main" )
local destination_pm = cfg_get( "cmd_rules_destination_pm" )

--// msgs
local help_title = lang.help_title or "rules"
local help_usage = lang.help_usage or "[+!#]rules"
local help_desc = lang.help_desc or "sends the hub rules to user"

local ucmd_menu = lang.ucmd_menu or  { "General", "Rules" }

local msg_rules = lang.msg_rules or [[  no rules ]]


----------
--[CODE]--
----------

local onbmsg = function( user )
    local user_level = user:level()
    if user_level >= minlevel then
        if destination_main then user:reply( msg_rules, hub_getbot ) end
        if destination_pm then user:reply( msg_rules, hub_getbot, hub_getbot ) end
    end
    return PROCESSED
end

hub.setlistener( "onStart", { },
    function( )
        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )  -- reg help
        end
        local ucmd = hub_import( "etc_usercommands" )  -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { }, { "CT1" }, minlevel )
        end
        local hubcmd = hub_import( "etc_hubcommands" )  -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
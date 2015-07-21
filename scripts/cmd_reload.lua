--[[

    cmd_reload.lua by blastbeat

        - this script adds a command "reload" to reload cfg, user db and scripts
        - usage: [+!#]reload
        
        v0.03: by pulsar
            - add table lookups
            - clean code
            - removed "cmd_reg_minlevel" import
                - using util.getlowestlevel( tbl ) instead of "cmd_reload_minlevel"
        
        v0.02: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"
            
        v0.01: by blastbeat

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_reload"
local scriptversion = "0.03"

local cmd = "reload"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_getbot = hub.getbot()
local hub_import = hub.import
local hub_reloadcfg = hub.reloadcfg
local hub_restartscripts = hub.restartscripts
local hub_reloadusers = hub.reloadusers
local utf_match = utf.match
local util_getlowestlevel = util.getlowestlevel

--// imports
local hubcmd
local scriptlang = cfg_get( "language" )
local permission = cfg_get( "cmd_reload_permission" )

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local help_title = lang.help_title or "cmd_reload.lua"
local help_usage = lang.help_usage or "[+!#]reload"
local help_desc = lang.help_desc or "reloads complete configuration: cfg.tbl, user.tbl, scripts"

local ucmd_menu = lang.ucmd_menu or { "Hub", "Core", "Hub reload" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_ok = lang.msg_ok or "Configuration reloaded."


----------
--[CODE]--
----------

local minlevel = util_getlowestlevel( permission )

local onbmsg = function( user, command )
    if not permission[ user:level( ) ] then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    hub_reloadcfg()
    hub_reloadusers()
    hub_restartscripts()
    user:reply( msg_ok, hub.getbot() )
    return PROCESSED
end

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
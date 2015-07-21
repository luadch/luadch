--[[

    cmd_rules.lua

        - this script adds a command "rules" for hub rules
        - usage: [+!#]rules

        - v0.04: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"
            
        - v0.03: by blastbeat
            - updated script api
            - regged hubcommand

        - v0.02: by blastbeat
            - added language files and ucmd

]]--

--// settings begin //--

local scriptname = "cmd_rules"
local scriptversion = "0.04"
local scriptlang = cfg.get "language"

local cmd = "rules"

local minlevel = cfg.get "cmd_rules_minlevel"

local rules = cfg.get "cmd_rules_rules"

--// settings end //--

local utf_match = utf.match

local hub_getbot = hub.getbot

--// infos for the help command //--

local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local help_title = lang.help_title or "rules"
local help_usage = lang.help_usage or "[+!#]rules"
local help_desc = lang.help_desc or "sends the hub rules to user"

local ucmd_menu = lang.ucmd_menu or { "Rules" }

local hubcmd

local onbmsg = function( user )
    user:reply( rules, hub_getbot( ), hub_getbot( ) )
    return PROCESSED
end

hub.setlistener( "onStart", { },
    function( )
        local help = hub.import "cmd_help"
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )    -- reg help
        end
        local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { }, { "CT1" }, minlevel )
        end
        hubcmd = hub.import "etc_hubcommands"    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )
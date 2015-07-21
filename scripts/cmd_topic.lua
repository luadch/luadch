--[[

    cmd_topic.lua

        - this script adds a command "topic"
        - usage: [+!#]topic <newtopic>
        
        v0.02: by pulsar
            - export permission to "/cfg/cfg.tbl"
            - add lang feature
            - add topic database
            - some changes and code cleaning

		v0.01: by Night
            - add topic command

]]--


--// settings begin //--

local scriptname = "cmd_topic"
local scriptversion = "0.02"

local cmd = "topic"

--// settings end //--


--// imports
local help, hubcmd

--// table lookups
local hub_getbot = hub.getbot()
local hub_broadcast = hub.broadcast
local hub_escapeto = hub.escapeto
local hub_sendtoall = hub.sendtoall
local hub_loadsettings = hub.reloadcfg
local hub_import = hub.import
local hub_debug = hub.debug

local util_loadtable = util.loadtable
local util_savetable = util.savetable

local utf_match = utf.match
local utf_format = utf.format

local cfg_get = cfg.get

--// permission
local minlevel = cfg_get( "cmd_topic_minlevel" )

--// database
local topic_file = "scripts/data/cmd_topic.tbl"
local topic_tbl = util_loadtable( topic_file ) or {}
local default_topic = cfg_get( "hub_description" )

--// lang, msgs
local scriptlang = cfg_get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local help_title = lang.help_title or "Topic"
local help_usage = lang.help_usage or "[+!#]topic <newtopic>"
local help_desc = lang.help_desc or "Sets hub topic"

local msg_topic_changed = lang.msg_topic_changed or "%s changed hub topic to: %s   |   old topic was: %s"
local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or "Usage: [+!#]topic <newtopic>"

local ucmd_menu = lang.ucmd_menu or { "Hub", "Core", "Hub set topic" }
local ucmd_popup = lang.ucmd_popup or "New Topic:"

--// flags
local old, new = "old", "new"

local ontopic = function( user, command, parameters )
    local user_level = user:level()
    local user_nick = user:nick()
    local topic = parameters
	if user_level < minlevel then
		user:reply( msg_denied, hub_getbot )
		return PROCESSED
	end
    if topic == "" then
        user:reply( msg_usage, hub_getbot )
        return PROCESSED
    end
    if topic_tbl[ new ] then
        topic_tbl[ old ] = topic_tbl[ new ]
        topic_tbl[ new ] = topic
    else
        topic_tbl[ old ] = default_topic
        topic_tbl[ new ] = topic
    end
    util_savetable( topic_tbl, "topic_tbl", topic_file ) 
    hub_sendtoall( "IINF DE" .. hub_escapeto( topic ) .. "\n" )
    hub_broadcast( utf_format( msg_topic_changed, user_nick, topic, topic_tbl[ old ] ), hub_getbot )
    return PROCESSED
end

hub.setlistener( "onLogin", { },
    function( user )
        local topic
        if topic_tbl[ new ] then
            topic = topic_tbl[ new ]
        else
            topic = default_topic
        end
        user:send( "IINF DE" .. hub_escapeto( topic ) .. "\n" )
        return nil
    end
)

hub.setlistener( "onStart", { },
    function( )
	    help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )    -- reg help
        end
		local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
			ucmd.add( ucmd_menu, cmd, { "%[line: " .. ucmd_popup .. "]" }, { "CT1" }, minlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, ontopic ) )
        return nil
    end
)

hub_debug( "** Loaded "..scriptname.." "..scriptversion.." **" )
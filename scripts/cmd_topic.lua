--[[

    cmd_topic.lua by Night

        - this script adds a command "topic"
        - usage: [+!#]topic <NEW-TOPIC>|default

        v0.03: by pulsar
            - add possibility to reset topic to default  / requested by Sopor
            - using report import functionality now

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
local scriptversion = "0.03"

local cmd = "topic"

--// settings end //--


--// imports
local help, ucmd, hubcmd

--// table lookups
local hub_getbot = hub.getbot()
local hub_broadcast = hub.broadcast
local hub_escapeto = hub.escapeto
local hub_sendtoall = hub.sendtoall
local hub_import = hub.import
local hub_debug = hub.debug
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local utf_match = utf.match
local utf_format = utf.format
local cfg_get = cfg.get

--// permission
local scriptlang = cfg_get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local minlevel = cfg_get( "cmd_topic_minlevel" )
local report = hub_import( "etc_report" )
local report_activate = cfg_get( "cmd_topic_report" )
local report_hubbot = cfg_get( "cmd_topic_report_hubbot" )
local report_opchat = cfg_get( "cmd_topic_report_opchat" )
local llevel = cfg_get( "cmd_topic_llevel" )

--// database
local topic_file = "scripts/data/cmd_topic.tbl"
local topic_tbl = util_loadtable( topic_file ) or {}
local default_topic = cfg_get( "hub_description" )

--// lang, msgs
local help_title = lang.help_title or "etc_topic.lua"
local help_usage = lang.help_usage or "[+!#]topic <NEW-TOPIC>|default"
local help_desc = lang.help_desc or "Sets a new hub topic or resets it to default"

local msg_topic_changed = lang.msg_topic_changed or "%s  changed hub topic to: %s   |   old topic was: %s"
local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or "Usage: [+!#]topic <NEW-TOPIC>|default"
local msg_topic_reset = lang.msg_topic_reset or "%s  reset hub topic to default: %s"

local ucmd_menu = lang.ucmd_menu or { "Hub", "Core", "Hub topic", "set new topic" }
local ucmd_menu2 = lang.ucmd_menu2 or { "Hub", "Core", "Hub topic", "set to default" }
local ucmd_popup = lang.ucmd_popup or "New Topic:"

--// flags
local old, new = "old", "new"

--// CODE
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
    if topic == "default" then
        topic_tbl = {}
        util_savetable( topic_tbl, "topic_tbl", topic_file )
        hub_sendtoall( "IINF DE" .. hub_escapeto( default_topic ) .. "\n" )
        local msg = utf_format( msg_topic_reset, user_nick, default_topic )
        user:reply( msg, hub_getbot )
        report.send( report_activate, report_hubbot, report_opchat, llevel, msg )
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
    local msg = utf_format( msg_topic_changed, user_nick, topic, topic_tbl[ old ] )
    user:reply( msg, hub_getbot )
    report.send( report_activate, report_hubbot, report_opchat, llevel, msg )
    return PROCESSED
end

hub.setlistener( "onLogin", { },
    function( user )
        if topic_tbl[ new ] then
            user:send( "IINF DE" .. hub_escapeto( topic_tbl[ new ] ) .. "\n" )
        end
        return nil
    end
)

hub.setlistener( "onStart", { },
    function( )
	    help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )    -- reg help
        end
		ucmd = hub_import( "etc_usercommands" )    -- add usercommand
        if ucmd then
			ucmd.add( ucmd_menu, cmd, { "%[line: " .. ucmd_popup .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu2, cmd, { "default" }, { "CT1" }, minlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, ontopic ) )
        return nil
    end
)

hub_debug( "** Loaded "..scriptname.." "..scriptversion.." **" )
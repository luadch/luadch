--[[

        cmd_help.lua by blastbeat

        - this script adds a command "help"
        - it exports also a module to reg a help text which will be shown by help
        - usage: [+!#]help

        v0.06: by pulsar
            - small typo fix
            - some small code changes
            - add table lookups

        v0.05: by pulsar
            - changed visual output style

        v0.04: by blastbeat
            - updated script api
            - regged hubcommand

        v0.03: by blastbeat
            - some clean ups

        v0.02: by blastbeat
            - added language files and ucmd

]]--


local scriptname = "cmd_help"
local scriptversion = "0.06"

local cmd = "help"

local minlevel = 0    -- minimum level to get the help

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_import = hub.import
local hub_debug = hub.debug
local hub_getbot = hub.getbot
local hub_debug = hub.debug
local utf_match = utf.match
local utf_format = utf.format
local table_concat = table.concat

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

--// msgs
local help_title = lang.help_title or "cmd_help.lua"
local help_usage = lang.help_usage or "[+!#]help"
local help_desc = lang.help_desc or "Shows this help for hub commands"

local msg_usage = lang.msg_usage or "Usage:"
local msg_description = lang.msg_description or "Description:"
local msg_minlevel = lang.msg_minlevel or "Min. Level:"
local msg_out = lang.msg_out or [[


=== AVAILABLE COMMANDS =================================================================================
%s
================================================================================= AVAILABLE COMMANDS ===
  ]]

local ucmd_menu = lang.ucmd_menu or { "General", "Help" }

--// code
local help = {}

local reghelp = function( title, usage, desc, level )
    title, usage, desc = tostring( title ), tostring( usage ), tostring( desc )
    level = tonumber( level ) or 0
    help[ #help + 1 ] = { title = title, usage = usage, desc = desc, level = level }
end

local onbmsg = function( user, command, parameters )
    local tmp = {}
    local level = user:level()
    for id, tbl in ipairs( help ) do
        if level >= tbl.level then
            tmp[ #tmp + 1 ] = "\n" ..
                              tbl.title .. "\n" ..
                              msg_usage .. "\t\t" .. tbl.usage .. "\n" ..
                              msg_description .. "\t" .. tbl.desc .. "\n" ..
                              msg_minlevel .. "\t" .. tbl.level .. "\n"
        end
    end
    tmp = table_concat( tmp )
    local msg = utf_format( msg_out, tmp )
    user:reply( msg, hub_getbot(), hub_getbot() )
    return PROCESSED
end

hub.setlistener( "onStart", { },
    function( )
        local ucmd = hub_import( "etc_usercommands" )    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { }, { "CT1" }, minlevel )
        end
        local hubcmd = hub_import( "etc_hubcommands" )    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

reghelp( help_title, help_usage, help_desc, minlevel )

hub_debug( "** Loaded "..scriptname.." "..scriptversion.." **" )

--// public //--

return {

    reg = reghelp,

}
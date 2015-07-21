--[[

        cmd_help.lua by blastbeat

        - this script adds a command "help"
        - it exports also a module to reg a help text which will be shown by help
        - usage: [+!#]help

        - v0.05: by pulsar
            - changed visual output style
            
        - v0.04: by blastbeat
          - updated script api
          - regged hubcommand

        - v0.03: by blastbeat
          - some clean ups

        - v0.02: by blastbeat
          - added language files and ucmd

]]--

--// settings begin //--

local scriptname = "cmd_help"
local scriptversion = "0.05"
local scriptlang = cfg.get( "language" )

local cmd = "help"

--// settings end //--

local hub_getbot = hub.getbot
local utf_match = utf.match
local utf_format = utf.format

local help = {}
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local msg_usage = lang.msg_usage or "Usage: "
local msg_description = lang.msg_description or "Description: "
local msg_minlevel = lang.msg_minlevel or "Level: "
local msg_out = lang.msg_out or [[


=== AVAILABLE COMMANDS =================================================================================
%s


================================================================================= AVAILABLE COMMANDS ===
  ]]

local help_title = lang.help_title or "help"
local help_usage = lang.help_usage or "[+!#]help"
local help_desc = lang.help_desc or "shows help for hub commands"

local help_level = 0    -- minimum level to get the help

local ucmd_menu = lang.ucmd_menu or { "Help" }

local reghelp = function( title, usage, desc, level )
    title, usage, desc = tostring( title ), tostring( usage ), tostring( desc )
    level = tonumber( level ) or 0
    help[ #help + 1 ] = { title = title, usage = usage, desc = desc, level = level }
end

local hubcmd

local onbmsg = function( user, command, parameters )
    local tmp = {}
    local level = user:level()
    for id, tbl in ipairs( help ) do
        if level >= tbl.level then
            tmp[ #tmp + 1 ] = "\n\n" .. tbl.title .. "\n" .. msg_usage .. "\t\t" .. tbl.usage .. "\n" .. msg_description .. "\t" .. tbl.desc .. "\n" .. msg_minlevel .. "\t\t" .. tbl.level
        end
    end
    tmp = table.concat( tmp )
    local msg = utf_format( msg_out, tmp )
    user:reply( msg, hub_getbot(), hub_getbot() )
    return PROCESSED
end

hub.setlistener( "onStart", { },
    function( )
        local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { }, { "CT1" }, help_level )
        end
        hubcmd = hub.import "etc_hubcommands"    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

reghelp( help_title, help_usage, help_desc, help_level )

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )

--// public //--

return {

    reg = reghelp,

}
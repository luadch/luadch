--[[

    cmd_mass.lua by blastbeat

        - this script adds a command "mass" to send a pm mass message
        - usage: [+!#]mass <MSG>  /  [+!#]masslvl <LEVEL> <MSG>
        
        v0.15: by pulsar
            - removed "cmd_mass_minlevel" import
                - using util.getlowestlevel( tbl ) instead of "cmd_mass_minlevel"
                
        v0.14: by pulsar
            - changed date style in output messages to: yyyy-mm-dd
            - code cleaning
        
        v0.13: by pulsar
            - changed visual output style
        
        v0.12: by pulsar
            - send mass to specific levels for ops
            - code cleaning
            - table lookups
            
        v0.11: by pulsar
            - changed visual output style
            - table lookups

        v0.10: by pulsar
            - changed rightclick style
        
        v0.09: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"
        
        v0.08: by blastbeat
            - updated script api
            - regged hubcommand

        v0.07: by blastbeat
            - mass will be send by hub bot now
            - fixed 'sends first word only' bug

        v0.06: by blastbeat
            - some clean ups

        v0.05: by blastbeat
            - added language files and ucmd

        v0.04: by blastbeat
            - updated script api

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_mass"
local scriptversion = "0.15"

local cmd = "mass"
local cmd_lvl = "masslvl"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local hub_broadcast = hub.broadcast
local hub_import = hub.import
local hub_debug = hub.debug
local utf_match = utf.match
local utf_format = utf.format
local os_date = os.date
local util_getlowestlevel = util.getlowestlevel

--// imports
local help, ucmd, hubcmd
local oplevel = cfg_get( "cmd_mass_oplevel" )
local permission = cfg_get( "cmd_mass_permission" )
local levels = cfg_get( "levels" )
local scriptlang = cfg_get( "language" )

--// functions
local dateparser
local onbmsg
local onbmsg_op

--// msgs

local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local help_title = lang.help_title or "mass"
local help_usage = lang.help_usage or "[+!#]mass <message>"
local help_desc = lang.help_desc or "sends a pm with <message> to all users"

local help_title_op = lang.help_title_op or "masslvl"
local help_usage_op = lang.help_usage_op or "[+!#]masslvl <level> <message>"
local help_desc_op = lang.help_desc_op or "sends a pm with <message> to all users with specific level"

local ucmd_menu = lang.ucmd_menu or { "User", "Messages", "Mass", "to all" }
local ucmd_menu_1 = lang.ucmd_menu_1 or "User"
local ucmd_menu_2 = lang.ucmd_menu_2 or "Messages"
local ucmd_menu_3 = lang.ucmd_menu_3 or "Mass"
local ucmd_menu_4 = lang.ucmd_menu_4 or "to level"
local ucmd_what = lang.ucmd_what or "Message:"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or "Usage: [+!#]mass <message>"
local msg_usage_op = lang.msg_usage_op or "Usage: [+!#]masslvl <level> <message>"
local msg_lvl_exists = lang.msg_lvl_exists or "Level %s does not exists."
local msg_ok = lang.msg_ok or "Mass was send to all users with level: "
local msg_out = lang.msg_out or [[


=== MASS MESSAGE ======================================================================================================

Sender:  %s   |   Date:  %s   |   Time:  %s

Message:  %s

====================================================================================================== MASS MESSAGE ===
  ]]
  
local msg_out_op = lang.msg_out_op or [[


=== MASS MESSAGE ======================================================================================================

Sender:  %s   |   Date:  %s   |   Time:  %s  |  Sends to all users with level:  %s

Message:  %s

====================================================================================================== MASS MESSAGE ===
  ]]


----------
--[CODE]--
----------

local minlevel = util_getlowestlevel( permission )

dateparser = function()
    if scriptlang == "de" then
        local wochentage = {
            ["Monday"] = "Montag",
            ["Tuesday"] = "Dienstag",
            ["Wednesday"] = "Mittwoch",
            ["Thursday"] = "Donnerstag",
            ["Friday"] = "Freitag",
            ["Saturday"] = "Samstag",
            ["Sunday"] = "Sonntag",
        }
        local monate = {
            ["January"] = "Januar",
            ["February"] = "Februar",
            ["March"] = "März",
            ["April"] = "April",
            ["May"] = "Mai",
            ["June"] = "Juni",
            ["July"] = "Juli",
            ["August"] = "August",
            ["September"] = "September",
            ["October"] = "Oktober",
            ["November"] = "November",
            ["December"] = "Dezember",
        }
        local day = os_date( "%d" )
        local month = os_date( "%B" )
        local year = os_date( "%Y" )
        local weekday = os_date( "%A" )
        local time = os_date( "%X" )
        local wochentag = wochentage[ weekday ]
        local monat = monate[ month ]
        local datum = wochentag .. ", der " .. day .. "." .. monat .. "." .. year
        return datum, time
    elseif scriptlang == "en" then
        local day = os_date( "%d" )
        local month = os_date( "%m" )
        local year = os_date( "%Y" )
        local time = os_date( "%X" )
        local date = year .. "-" .. month .. "-" .. day
        return date, time
    else
        local day = os_date( "%d" )
        local month = os_date( "%m" )
        local year = os_date( "%Y" )
        local time = os_date( "%X" )
        local date = year .. "-" .. month .. "-" .. day
        return date, time
    end
end

onbmsg = function( user, command, msg )
    local msg = utf_match( msg, "(.+)" )
    if not permission[ user:level() ] then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    if not msg then
        user:reply( msg_usage, hub_getbot )
        return PROCESSED
    else
        local nick = user:nick()
        local date, time = dateparser()
        local mass = utf_format( msg_out, nick, date, time, msg )
        hub_broadcast( mass, user, hub_getbot )
    end
    return PROCESSED
end

onbmsg_op = function( user, command, msg )
    local lvl, msg = utf_match( msg, "(%d+) (.+)" )
    local lvl = tonumber( lvl )
    if user:level() < oplevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    if not lvl then
        user:reply( msg_usage_op, hub_getbot )
        return PROCESSED
    end
    if not levels[ lvl ] then
        local txt = utf_format( msg_lvl_exists, lvl )
        user:reply( txt, hub_getbot )
        return PROCESSED
    end
    if not msg then
        user:reply( msg_usage_op, hub_getbot )
        return PROCESSED
    else
        local nick = user:nick()
        local date, time = dateparser()
        local levelname = cfg_get( "levels" )[ lvl ] or "UNREG"
        local mass = utf_format( msg_out_op, nick, date, time, lvl .. " [ " .. levelname .. " ]", msg )
        for sid, target in pairs( hub_getusers() ) do
            if not target:isbot() then
                if target:level() == lvl then
                    target:reply( mass, user, hub_getbot )
                end
            end
        end
        user:reply( msg_ok .. lvl .. " [ " .. levelname .. " ]", hub_getbot )
        return PROCESSED
    end  
end

hub.setlistener( "onStart", { },
    function( )
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
            help.reg( help_title_op, help_usage_op, help_desc_op, oplevel )
        end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { "%[line:" .. ucmd_what .. "]" }, { "CT1" }, minlevel )
            local tbl = {}
            local i = 1
            for k, v in pairs( levels ) do
                if k > 0 then
                    tbl[ i ] = k
                    i = i + 1
                end
            end
            table.sort( tbl )
            for _, level in pairs( tbl ) do
                ucmd.add( { ucmd_menu_1, ucmd_menu_2, ucmd_menu_3, ucmd_menu_4, levels[ level ] }, cmd_lvl, { level, "%[line:" .. ucmd_what .. "]" }, { "CT1" }, oplevel )
            end
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        assert( hubcmd.add( cmd_lvl, onbmsg_op ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
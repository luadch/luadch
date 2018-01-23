--[[

    usr_uptime.lua by pulsar  / requested by Sopor

        usage: [+!#]useruptime [CT1 <FIRSTNICK> | CT2 <NICK>]

        v0.4
            - fixed showing uptime of wrong user when selecting user from userlist
            - saves uptime table every 10 minutes

        v0.3:
            - fixed get_useruptime() function (output msg)  / thx WitchHunter

        v0.2:
            - added "usr_uptime_minlevel"  / requested by WitchHunter
                - possibility to show your own uptime stats for minlevel

        v0.1:
            - this script counts the online time of the users
            - it also exports the users uptime database table for other scripts

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "usr_uptime"
local scriptversion = "0.4"

local cmd = "useruptime"

local uptime_file = "scripts/data/usr_uptime.tbl"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_getbot = hub.getbot()
local hub_isnickonline = hub.isnickonline
local hub_import = hub.import
local utf_match = utf.match
local utf_format = utf.format
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local util_getlowestlevel = util.getlowestlevel
local util_formatseconds = util.formatseconds
local os_date = os.date
local os_time = os.time
local os_difftime = os.difftime
local string_rep = string.rep

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )
local uptime_tbl = util_loadtable( uptime_file )
local minlevel = cfg_get( "usr_uptime_minlevel" )
local permission = cfg_get( "usr_uptime_permission" )

--// msgs
local help_title = lang.help_title or "usr_uptime.lua"
local help_usage = lang.help_usage or "[+!#]useruptime"
local help_desc = lang.help_desc or "Shows your uptime stats"

local help_title_op = lang.help_title_op or "usr_uptime.lua - Operators"
local help_usage_op = lang.help_usage_op or "[+!#]useruptime CT1 <FIRSTNICK> | CT2 <NICK>"
local help_desc_op = lang.help_desc_op or "Shows the uptime stats of a user"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or "[+!#]useruptime CT1 <FIRSTNICK> | CT2 <NICK>"
local msg_notfound = lang. msg_notfound or "User not found."
local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"
local msg_label = lang.msg_label or "\tYEAR\t\tMONTH\t\tUPTIME"

local ucmd_menu_ct1 = lang.ucmd_menu_ct1 or { "User", "Uptime stats" }
local ucmd_menu_ct1_2 = lang.ucmd_menu_ct1_2 or { "About You", "show Uptime stats" }
local ucmd_menu_ct2 = lang.ucmd_menu_ct2 or { "Show", "Uptime stats" }
local ucmd_desc = lang.ucmd_desc or "Users nick without nicktag:"

local month_name = lang.month_name or {

    [ 1 ] = "January\t",
    [ 2 ] = "February\t",
    [ 3 ] = "March\t",
    [ 4 ] = "April\t",
    [ 5 ] = "May\t",
    [ 6 ] = "June\t",
    [ 7 ] = "July\t",
    [ 8 ] = "August\t",
    [ 9 ] = "September",
    [ 10 ] = "October\t",
    [ 11 ] = "November",
    [ 12 ] = "December",
}

local msg_uptime = lang.msg_uptime or [[


=== USER UPTIME ========================================================================

        Uptime stats about:  %s

%s
%s
%s
======================================================================== USER UPTIME ===
  ]]


----------
--[CODE]--
----------

local delay = 10 * 60
local start = os_time()

local oplevel = util_getlowestlevel( permission )

local new_entry = function( user )
    if not user:isbot() then
        local month, year = tonumber( os_date( "%m" ) ), tonumber( os_date( "%Y" ) )
        if type( uptime_tbl[ user:firstnick() ] ) == "nil" then
            uptime_tbl[ user:firstnick() ] = {}
        end
        if type( uptime_tbl[ user:firstnick() ][ year ] ) == "nil" then
            uptime_tbl[ user:firstnick() ][ year ] = {}
        end
        if type( uptime_tbl[ user:firstnick() ][ year ][ month ] ) == "nil" then
            uptime_tbl[ user:firstnick() ][ year ][ month ] = {}
            uptime_tbl[ user:firstnick() ][ year ][ month ][ "session_start" ] = os_time()
            uptime_tbl[ user:firstnick() ][ year ][ month ][ "complete" ] = 0
        end
    end
end

local set_start = function( user )
    new_entry( user )
    if not user:isbot() then
        local month, year = tonumber( os_date( "%m" ) ), tonumber( os_date( "%Y" ) )
        uptime_tbl[ user:firstnick() ][ year ][ month ][ "session_start" ] = os_time()
        util_savetable( uptime_tbl, "uptime", uptime_file )
        start = os_time()
    end
end

local set_stop = function( user )
    new_entry( user )
    if not user:isbot() then
        local month, year = tonumber( os_date( "%m" ) ), tonumber( os_date( "%Y" ) )
        local session_start = uptime_tbl[ user:firstnick() ][ year ][ month ][ "session_start" ]
        local old_complete = uptime_tbl[ user:firstnick() ][ year ][ month ][ "complete" ]
        local new_complete = os_difftime( os_time(), session_start ) + old_complete
        uptime_tbl[ user:firstnick() ][ year ][ month ][ "complete" ] = new_complete
        util_savetable( uptime_tbl, "uptime", uptime_file )
        start = os_time()
    end
end

local get_useruptime = function( firstnick )
    if type( uptime_tbl[ firstnick ] ) == "nil" then return false end
    local msg = ""
    for i_1 = 2015, 2100, 1 do
        for year, month_tbl in pairs( uptime_tbl[ firstnick ] ) do
            if year == i_1 then
                msg = msg .. "\n"
                for i_2 = 1, 12, 1 do
                    for month, v in pairs( month_tbl ) do
                        if month == i_2 then
                            local d, h, m, s = util_formatseconds( v[ "complete" ] )
                            local uptime = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
                            msg = msg .. "\t" .. year .. "\t" .. month_name[ month ] .. "\t" .. uptime .. "\n"
                        end
                    end
                end
            end
        end
    end
    local msg_sep = "\t" .. string_rep( "-", 140 )
    return utf_format( msg_uptime, firstnick, msg_label, msg_sep, msg )
end

--// export function
local tbl = function()
    if type( uptime_tbl ) == "nil" then
        return false, "usr_uptime.lua: error: file not found"
    else
        return uptime_tbl
    end
end

local onbmsg = function( user, command, parameters )
    local user_level, user_firstnick = user:level(), user:firstnick()
    local param1, param2 = utf_match( parameters, "^?(%S+) ?(%S+)$" )
    if not ( param1 and param2 ) then
        if user_level >= minlevel then
            local uptime = get_useruptime( user_firstnick )
            if uptime then
                user:reply( uptime, hub_getbot )
                return PROCESSED
            else
                user:reply( msg_notfound, hub_getbot )
                return PROCESSED
            end
        else
            user:reply( msg_denied, hub_getbot )
            return PROCESSED
        end
    end
    if not permission[ user_level ] then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    if ( command == cmd ) and ( param1 == "CT1" ) and param2 then
        local uptime = get_useruptime( param2 )
        if uptime then
            user:reply( uptime, hub_getbot )
            return PROCESSED
        else
            user:reply( msg_notfound, hub_getbot )
            return PROCESSED
        end
    end
    if ( command == cmd ) and ( param1 == "CT2" ) and param2 then
        local target = hub_isnickonline( param2 )
        if target then
            local uptime = get_useruptime( target:firstnick() )
            if uptime then
                user:reply( uptime, hub_getbot )
                return PROCESSED
            else
                user:reply( msg_notfound, hub_getbot )
                return PROCESSED
            end
        end
    end
    user:reply( msg_usage, hub_getbot )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
            help.reg( help_title_op, help_usage_op, help_desc_op, oplevel )
        end
        local ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct1,   cmd, { "CT1", "%[line:" .. ucmd_desc .. "]" }, { "CT1" }, oplevel )
            ucmd.add( ucmd_menu_ct1_2, cmd, { }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct2,   cmd, { "CT2", "%[userNI]" }, { "CT2" }, oplevel )
        end
        local hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.setlistener( "onExit", { },
    function()
        --// save database
        util_savetable( uptime_tbl, "uptime", uptime_file )
        return nil
    end
)

hub.setlistener( "onLogin", {},
    function( user )
        set_start( user )
        return nil
    end
)

hub.setlistener( "onLogout", {},
    function( user )
        set_stop( user )
        return nil
    end
)

hub.setlistener( "onTimer", {},
    function( )
        if os_difftime( os_time() - start ) >= delay then
            util_savetable( uptime_tbl, "uptime", uptime_file )
            start = os_time()
        end
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

--// public //--

return {    -- export bans

    tbl = tbl,  -- use: local usersuptime = hub.import( "usr_uptime"); local uptime_tbl = usersuptime.tbl() in other scripts to get the users uptime database table

}

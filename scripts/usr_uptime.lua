--[[

    usr_uptime.lua by pulsar  / requested by Sopor

        usage: [+!#]useruptime [CT1 <FIRSTNICK> | CT2 <NICK>]

        v0.8: by pulsar
            - commented out debug line

        v0.7: by pulsar
            - removed table lookups
            - small change in "msg_label"
            - fix #39 -> https://github.com/luadch/luadch/issues/39

        v0.6: by blastbeat
            - only send feed to opchat, if opchat is active

        v0.5:
            - reduce timer to 1 minute
            - fix: https://github.com/luadch/luadch/issues/81
                - add "opchat.feed()" function to report corrupt or missing database file

        v0.4:
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
local scriptversion = "0.8"

local cmd = { "useruptime", "uu" }

local uptime_file = "scripts/data/usr_uptime.tbl"


--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local uptime_tbl = util.loadtable( uptime_file )
local minlevel = cfg.get( "usr_uptime_minlevel" )
local permission = cfg.get( "usr_uptime_permission" )
local opchat = hub.import( "bot_opchat" )

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
local msg_label = lang.msg_label or "\tYEAR\tMONTH\t\tUPTIME"
local msg_err = lang.msg_err or "usr_uptime.lua: error: database file (usr_uptime.tbl) corrupt or missing, a new one was created."

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

local delay = 1 * 60
local start = os.time()

local oplevel = util.getlowestlevel( permission )

local new_entry = function( user )
    if not user:isbot() then
        if type( uptime_tbl ) == "nil" then
            uptime_tbl = {}
            util.savetable( uptime_tbl, "uptime", uptime_file )
            if opchat then opchat.feed( msg_err ) end
        else
            local month, year = tonumber( os.date( "%m" ) ), tonumber( os.date( "%Y" ) )
            if type( uptime_tbl[ user:firstnick() ] ) == "nil" then
                uptime_tbl[ user:firstnick() ] = {}
            end
            if type( uptime_tbl[ user:firstnick() ][ year ] ) == "nil" then
                uptime_tbl[ user:firstnick() ][ year ] = {}
            end
            if type( uptime_tbl[ user:firstnick() ][ year ][ month ] ) == "nil" then
                uptime_tbl[ user:firstnick() ][ year ][ month ] = {}
                uptime_tbl[ user:firstnick() ][ year ][ month ][ "session_start" ] = os.time()
                uptime_tbl[ user:firstnick() ][ year ][ month ][ "complete" ] = 0
            end
        end
    end
end

local set_start = function( user )
    new_entry( user )
    if not user:isbot() then
        local month, year = tonumber( os.date( "%m" ) ), tonumber( os.date( "%Y" ) )
        uptime_tbl[ user:firstnick() ][ year ][ month ][ "session_start" ] = os.time()
        util.savetable( uptime_tbl, "uptime", uptime_file )
        start = os.time()
    end
end

local set_stop = function( user )
    new_entry( user )
    if not user:isbot() then
        local month, year = tonumber( os.date( "%m" ) ), tonumber( os.date( "%Y" ) )
        local session_start = uptime_tbl[ user:firstnick() ][ year ][ month ][ "session_start" ]
        local old_complete = uptime_tbl[ user:firstnick() ][ year ][ month ][ "complete" ]
        local new_complete = os.difftime( os.time(), session_start ) + old_complete
        uptime_tbl[ user:firstnick() ][ year ][ month ][ "complete" ] = new_complete
        util.savetable( uptime_tbl, "uptime", uptime_file )
        start = os.time()
    end
end

local get_useruptime = function( firstnick )
    --hub.broadcast( "firstnick: " .. firstnick, hub.getbot() )  -- debug
    if type( uptime_tbl ) == "nil" then
        uptime_tbl = {}
        util.savetable( uptime_tbl, "uptime", uptime_file )
        if opchat then opchat.feed( msg_err ) end
    end
    if type( uptime_tbl[ firstnick ] ) == "nil" then return false end
    local msg = ""
    for i_1 = 2015, 2100, 1 do
        for year, month_tbl in pairs( uptime_tbl[ firstnick ] ) do
            if year == i_1 then
                msg = msg .. "\n"
                for i_2 = 1, 12, 1 do
                    for month, v in pairs( month_tbl ) do
                        if month == i_2 then
                            if v[ "complete" ] ~= 0 then
                                local new_complete = os.difftime( os.time(), v[ "complete" ] )
                                local d, h, m, s = util.formatseconds( new_complete )
                                local uptime = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
                                msg = msg .. "\t" .. year .. "\t" .. month_name[ month ] .. "\t" .. uptime .. "\n"
                            else

                                local new_complete = os.difftime( os.time(), v[ "session_start" ] )
                                local d, h, m, s = util.formatseconds( new_complete )
                                local uptime = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
                                msg = msg .. "\t" .. year .. "\t" .. month_name[ month ] .. "\t" .. uptime .. "\n"
                            end
                        end
                    end
                end
            end
        end
    end
    local msg_sep = "\t" .. string.rep( "-", 140 )
    return utf.format( msg_uptime, firstnick, msg_label, msg_sep, msg )
end

--// export function
local tbl = function()
    if type( uptime_tbl ) == "nil" then
        uptime_tbl = {}
        util.savetable( uptime_tbl, "uptime", uptime_file )
        return false, msg_err
    else
        return uptime_tbl
    end
end

local onbmsg = function( user, command, parameters )
    local user_level, user_firstnick = user:level(), user:firstnick()
    local param1, param2 = utf.match( parameters, "^(%S+) (%S+)$" )
    if not ( param1 and param2 ) then
        if user_level >= minlevel then
            local uptime = get_useruptime( user_firstnick )
            if uptime then
                user:reply( uptime, hub.getbot() )
                return PROCESSED
            else
                user:reply( msg_notfound, hub.getbot() )
                return PROCESSED
            end
        else
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        end
    end
    if not permission[ user_level ] then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    if ( param1 == "CT1" ) and param2 then
        local uptime = get_useruptime( param2 )
        if uptime then
            user:reply( uptime, hub.getbot() )
            return PROCESSED
        else
            user:reply( msg_notfound, hub.getbot() )
            return PROCESSED
        end
    end
    if ( param1 == "CT2" ) and param2 then
        local target = hub.isnickonline( param2 )
        if target then
            local uptime = get_useruptime( target:firstnick() )
            if uptime then
                user:reply( uptime, hub.getbot() )
                return PROCESSED
            else
                user:reply( msg_notfound, hub.getbot() )
                return PROCESSED
            end
        end
    end
    user:reply( msg_usage, hub.getbot() )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        local help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
            help.reg( help_title_op, help_usage_op, help_desc_op, oplevel )
        end
        local ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct1,   cmd[1], { "CT1", "%[line:" .. ucmd_desc .. "]" }, { "CT1" }, oplevel )
            ucmd.add( ucmd_menu_ct1_2, cmd[1], { }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct2,   cmd[1], { "CT2", "%[userNI]" }, { "CT2" }, oplevel )
        end
        local hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.setlistener( "onExit", { },
    function()
        --// save database
        util.savetable( uptime_tbl, "uptime", uptime_file )
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
        if os.difftime( os.time() - start ) >= delay then
            util.savetable( uptime_tbl, "uptime", uptime_file )
            start = os.time()
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

--// public //--

return {    -- export bans

    tbl = tbl,  -- use: local usersuptime = hub.import( "usr_uptime"); local uptime_tbl, err = usersuptime.tbl() in other scripts to get the users uptime database table

}

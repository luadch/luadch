--[[

	cmd_usercleaner.lua by pulsar

        - This script shows and removes no longer used and never used accounts from "cfg/users.tbl"

        usage:

            [+!#]usercleaner showall               -- List of all offline users, sorted by offline time in days (used accounts)
            [+!#]usercleaner showexpired           -- List of all expired offline users, sorted by offline time in days (used accounts)
            [+!#]usercleaner showghosts            -- List of all expired offline users, sorted by reg time in days (unused accounts)
            [+!#]usercleaner delexpired            -- Delete all expired offline users (ghosts excludet, with nick and level protection)
            [+!#]usercleaner delghosts             -- Delete all expired accounts who never been used (with nick protection, but without level protection)
            [+!#]usercleaner addexception <NICK>   -- Add user account to exception list
            [+!#]usercleaner delexception <NICK>   -- Delete user account from exceptions list
            [+!#]usercleaner delexceptionall       -- Delete all user accounts from exceptions list
            [+!#]usercleaner showexceptions        -- Show nick exceptions and level exceptions
            [+!#]usercleaner setdays <DAYS>        -- Change the expired days (default = 365)


        v0.3:
            - changed "help_title"
            - changed "msg_exceptions_level"

        v0.2:
            - small optical adjustment

        v0.1:
            - first checkout

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_usercleaner"
local scriptversion = "0.3"

--// command
local cmd = "usercleaner"

--// command parameters
local cmd_p1 = "showall"
local cmd_p2 = "showexpired"
local cmd_p3 = "showghosts"
local cmd_p4 = "delexpired"
local cmd_p5 = "delghosts"
local cmd_p6 = "addexception"
local cmd_p7 = "delexception"
local cmd_p8 = "delexceptionall"
local cmd_p9 = "showexceptions"
local cmd_p10 = "setdays"

--// imports
local help, ucmd, hubcmd
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local report = hub.import( "etc_report" )
local cfg_levels = cfg.get( "levels" )

local report_activate = cfg.get( "cmd_usercleaner_report" )
local report_level = cfg.get( "cmd_usercleaner_report_llevel" )
local report_hubbot = cfg.get( "cmd_usercleaner_report_hubbot" )
local report_opchat = cfg.get( "cmd_usercleaner_report_opchat" )

local exception_file = "scripts/data/cmd_usercleaner_exceptions.tbl"
local settings_file = "scripts/data/cmd_usercleaner_settings.tbl"
local exception_tbl = util.loadtable( exception_file )
local settings_tbl = util.loadtable( settings_file )

local activate = cfg.get( "cmd_usercleaner_activate" )
local permission = cfg.get( "cmd_usercleaner_permission" )
local minlevel = util.getlowestlevel( permission )
local expired_days = settings_tbl[ "expired_days" ] or 365
local protected_levels = cfg.get( "cmd_usercleaner_protected_levels" )

--// msgs
local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or "Usage: [+!#]usercleaner showall | showexpired | showghosts | delexpired | delghosts | addexception <NICK> | delexception <NICK> | delexceptionall | showexceptions | setdays <DAYS>"
local msg_nousers = lang.msg_nousers or "[ No users found ]"

local help_title = lang.help_title or "cmd_usercleaner.lua"
local help_usage = lang.help_usage or "[+!#]usercleaner showall | showexpired | showghosts | delexpired | delghosts | addexception <NICK> | delexception <NICK> | delexceptionall | showexceptions | setdays <DAYS>"
local help_desc = lang.help_desc or "Shows and removes used and unused offline accounts"

local msg_delreg_expired = lang.msg_delreg_expired or "[ Usercleaner ]--> User:  %s  was delregged because: expired offline time:  %s  days"
local msg_delreg_unused = lang.msg_delreg_unused or "[ Usercleaner ]--> User:  %s  was delregged because: unused since  %s  days"
local msg_delreg_exception = lang.msg_delreg_exception or "[ Usercleaner ]--> The following user is on the exception list and cannot be deleted: "
local msg_delreg_exception_level = lang.msg_delreg_exception_level or "[ Usercleaner ]--> The following user has a protected level and cannot be deleted: %s | protected level: %s"

local msg_exceptions_add = lang.msg_exceptions_add or "[ Usercleaner ]--> Nick was added to exceptions: "
local msg_exceptions_add_taken = lang.msg_exceptions_add_taken or "[ Usercleaner ]--> Nick has already been added: "
local msg_exceptions_level = lang.msg_exceptions_level or "[ Usercleaner ]--> The following user has already a protected level and cannot be added: %s | protected level: %s"
local msg_exceptions_del = lang.msg_exceptions_del or "[ Usercleaner ]--> Nick was removed from exceptions: "
local msg_exceptions_delall = lang.msg_exceptions_delall or "[ Usercleaner ]--> The exception list was cleared by: "
local msg_exceptions_del_notfound = lang.msg_exceptions_del_notfound or "[ Usercleaner ]--> Nick was not found: "
local msg_exceptions_show = lang.msg_exceptions_show or "[ No exceptions found ]"

local msg_settings_setdays = lang.msg_settings_setdays or "[ Usercleaner ]--> Change the expired days to: "

local ucmd_menu_ct1_1 = lang.ucmd_menu_ct1_1 or { "User", "Control", "Usercleaner", "Show", "Offline accounts (used)" }
local ucmd_menu_ct1_2 = lang.ucmd_menu_ct1_2 or { "User", "Control", "Usercleaner", "Show", "Expired offline accounts (used)" }
local ucmd_menu_ct1_3 = lang.ucmd_menu_ct1_3 or { "User", "Control", "Usercleaner", "Show", "Expired offline accounts (unused)" }
local ucmd_menu_ct1_4 = lang.ucmd_menu_ct1_4 or { "User", "Control", "Usercleaner", "Delete", "Expired offline accounts (used)", "OK" }
local ucmd_menu_ct1_5 = lang.ucmd_menu_ct1_5 or { "User", "Control", "Usercleaner", "Delete", "Expired offline accounts (unused)", "OK" }
local ucmd_menu_ct1_6 = lang.ucmd_menu_ct1_6 or { "User", "Control", "Usercleaner", "Exceptions", "Add user" }
local ucmd_menu_ct1_7 = lang.ucmd_menu_ct1_7 or { "User", "Control", "Usercleaner", "Exceptions", "Del user" }
local ucmd_menu_ct1_8 = lang.ucmd_menu_ct1_8 or { "User", "Control", "Usercleaner", "Exceptions", "Del all users" }
local ucmd_menu_ct1_9 = lang.ucmd_menu_ct1_9 or { "User", "Control", "Usercleaner", "Exceptions", "Show" }
local ucmd_menu_ct1_10 = lang.ucmd_menu_ct1_10 or { "User", "Control", "Usercleaner", "Settings", "Change expiring time in days (default=365)" }

local ucmd_nick = lang.ucmd_nick or "Nickname:"
local ucmd_days = lang.ucmd_days or "Days:"

local msg_out_all = lang.msg_out_all or [[


=== USERCLEANER ===================================================================================

   [ List of all offline users, sorted by offline time in days ]

               Days offline              Nick protected         Level protected        Nickname
        -------------------------------------------------------------------------------------------------------------------------------------------------------------------

%s
        -------------------------------------------------------------------------------------------------------------------------------------------------------------------
               Days offline              Nick protected         Level protected        Nickname

   [ List of all offline users, sorted by offline time in days ]

=================================================================================== USERCLEANER ===

  ]]

local msg_out_expired = lang.msg_out_expired or [[


=== USERCLEANER ===================================================================================

   [ List of all expired offline users, sorted by offline time in days ]

   Expired time in days:  %s

               Days offline              Nick protected         Level protected        Nickname
        -------------------------------------------------------------------------------------------------------------------------------------------------------------------

%s
        -------------------------------------------------------------------------------------------------------------------------------------------------------------------
               Days offline              Nick protected         Level protected        Nickname

   Expired time in days:  %s

   [ List of all expired offline users, sorted by offline time in days ]

=================================================================================== USERCLEANER ===

  ]]

local msg_out_ghosts = lang.msg_out_ghosts or [[


=== USERCLEANER ===========================================================

   [ List of all unused expired offline users, sorted by reg time in days ]

   Expired time in days:  %s

                  Days since registration          Nick protected         Nickname
        ---------------------------------------------------------------------------------------------------------------------

%s
        ---------------------------------------------------------------------------------------------------------------------
                  Days since registration          Nick protected         Nickname

   Expired time in days:  %s

   [ List of all unused expired offline users, sorted by reg time in days ]

=========================================================== USERCLEANER ===

  ]]

local msg_out_exceptions = lang.msg_out_exceptions or [[


=== USERCLEANER ======================================================

   [ List of Nick exceptions ]

                               Nickname
                  -------------------------------------------------------------------------------------------

%s

   [ List of Level exceptions ]

                               Protected                  Level
                  -------------------------------------------------------------------------------------------

%s
====================================================== USERCLEANER ===

  ]]


----------
--[CODE]--
----------

if not activate then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return
end

--// check if table key exists
local keyExists = function( tbl, key )
    return tbl[ key ] ~= nil
end

--// check if table is empty
local isEmpty = function( tbl )
    if next( tbl ) == nil then return true else return false end
end

--// sort table by value if key is a string and value is a number
local vPairs = function( tbl, mode )
    local t, i = {}, 0
    for k, v in pairs( tbl ) do t[ #t + 1 ] = k end
    if mode then
        table.sort( t, function( a, b ) return mode( tbl, a, b ) end )
    else
        table.sort( t )
    end
    return function()
        i = i + 1
        if t[ i ] then return t[ i ], tbl[ t[ i ] ] end
    end
end

--// get time in days
local getTime = function( nTime, sDate )
    if nTime and string.len( tostring( nTime ) ) == 14 then
        local sec, y, d, h, m, s = util.difftime( util.date(), nTime )
        d = d + ( y * 365 )
        return d
    end
    if nTime and string.len( tostring( nTime ) ) ~= 14 then
        local lastconnect = util.convertepochdate( nTime )
        local sec, y, d, h, m, s = util.difftime( util.date(), lastconnect )
        d = d + ( y * 365 )
        return d
    end
    if sDate then --> that will be really ugly but we have to go through that
        local Y, M, D, h, m, s
        if string.find( sDate, "-" ) then --> new style, e.g.: "2017-12-27 / 17:13:01"
            Y = string.sub( sDate,  1,  4 ); M = string.sub( sDate,  6,  7 ); D = string.sub( sDate,  9, 10 )
            h = string.sub( sDate, 14, 15 ); m = string.sub( sDate, 17, 18 ); s = string.sub( sDate, 20, 21 )
        elseif string.len( sDate ) == 21 then --> older style, e.g.: "27.12.2017 / 17:13:01"
            Y = string.sub( sDate,  7, 10 ); M = string.sub( sDate,  4,  5 ); D = string.sub( sDate,  1,  2 )
            h = string.sub( sDate, 14, 15 ); m = string.sub( sDate, 17, 18 ); s = string.sub( sDate, 20, 21 )
        elseif string.len( sDate ) == 10 then --> oldest style, e.g.: "27.12.2017"
            Y = string.sub( sDate,  7, 10 ); M = string.sub( sDate,  4,  5 ); D = string.sub( sDate,  1,  2 )
            h = "00"; m = "00"; s = "00"
        else
            return 0
        end
        local regdate = tonumber( Y .. M .. D .. h .. m .. s )
        local sec, y, d, h, m, s = util.difftime( util.date(), regdate )
        d = d + ( y * 365 )
        return d
    end
    return false
end

local checkUsers = function( all, expired, ghosts, level )
    local users = {}
    local user_tbl = hub.getregusers()
    for i, v in ipairs( user_tbl ) do
        if ( user_tbl[ i ].is_bot ~= 1 ) and ( user_tbl[ i ].is_online ~= 1 ) then
            local reg_date = getTime( false, user_tbl[ i ].date )
            local user_lastseen = getTime( user_tbl[ i ].lastseen, false )
            local user_lastconnect = getTime( user_tbl[ i ].lastconnect, false )

            if all then --> List of all offline users, sorted by offline time in days (ghosts excludet)
                if user_lastseen then users[ user_tbl[ i ].nick ] = user_lastseen end
                if ( not user_lastseen ) and user_lastconnect then users[ user_tbl[ i ].nick ] = user_lastconnect end
            end
            if expired then --> List of all expired offline users, sorted by offline time in days
                if user_lastseen and ( user_lastseen >= expired_days ) then users[ user_tbl[ i ].nick ] = user_lastseen end
                if ( not user_lastseen ) and user_lastconnect and ( user_lastconnect >= expired_days ) then users[ user_tbl[ i ].nick ] = user_lastconnect end
            end
            if ghosts then --> List of all expired offline accounts who never been used, sorted by reg time in days
                if ( not user_lastseen ) and ( not user_lastconnect ) and ( reg_date >= expired_days ) then users[ user_tbl[ i ].nick ] = reg_date end
            end
            if level then
                users[ user_tbl[ i ].nick ] = user_tbl[ i ].level
            end
        end
    end
    return users
end

local showUsers = function( all, expired, ghosts )
    local msg = ""
    local tbl_users_level = checkUsers( false, false, false, true )
    if all then --> List of all offline users, sorted by offline time in days (ghosts excludet)
        local tbl_users_all = checkUsers( true, false, false, false )
        for nick, days in vPairs( tbl_users_all, function( t, a, b ) return t[ b ] < t[ a ] end ) do
            if exception_tbl[ nick ] then
                msg = msg .. "\t" .. days .. "\t\t" .. "true" .. "\t\t" .. "false" .. "\t\t" .. nick .. "\n"
            elseif protected_levels[ tbl_users_level[ nick ] ] then
                msg = msg .. "\t" .. days .. "\t\t" .. "false" .. "\t\t" .. "true" .. "\t\t" .. nick .. "\n"
            else
                msg = msg .. "\t" .. days .. "\t\t" .. "false" .. "\t\t" .. "false" .. "\t\t" .. nick .. "\n"
            end
        end
        if msg == "" then msg = "\t" .. msg_nousers .. "\n" end
        return utf.format( msg_out_all, msg )
    end
    if expired then --> List of all expired offline users, sorted by offline time in days
        local tbl_users_expired = checkUsers( false, true, false, false )
        for nick, days in vPairs( tbl_users_expired, function( t, a, b ) return t[ b ] < t[ a ] end ) do
            if exception_tbl[ nick ] then
                msg = msg .. "\t" .. days .. "\t\t" .. "true" .. "\t\t" .. "false" .. "\t\t" .. nick .. "\n"
            elseif protected_levels[ tbl_users_level[ nick ] ] then
                msg = msg .. "\t" .. days .. "\t\t" .. "false" .. "\t\t" .. "true" .. "\t\t" .. nick .. "\n"
            else
                msg = msg .. "\t" .. days .. "\t\t" .. "false" .. "\t\t" .. "false" .. "\t\t" .. nick .. "\n"
            end
        end
        if msg == "" then msg = "\t" .. msg_nousers .. "\n" end
        return utf.format( msg_out_expired, expired_days, msg, expired_days )
    end
    if ghosts then --> List of all expired offline accounts who never been used, sorted by reg time in days
        local tbl_users_ghosts = checkUsers( false, false, true, false )
        for nick, days in vPairs( tbl_users_ghosts, function( t, a, b ) return t[ b ] < t[ a ] end ) do
            if exception_tbl[ nick ] then
                msg = msg .. "\t\t" .. days .. "\t\t" .. "true" .. "\t\t" .. nick .. "\n"
            else
                msg = msg .. "\t\t" .. days .. "\t\t" .. "false" .. "\t\t" .. nick .. "\n"
            end
        end
        if msg == "" then msg = "\t" .. msg_nousers .. "\n" end
        return utf.format( msg_out_ghosts, expired_days, msg, expired_days )
    end
end

local delUsers = function( expired, ghosts, user )
    local tbl_users_level = checkUsers( false, false, false, true )
    if expired then --> Delete all expired offline users (ghosts excludet)
        local tbl_users_expired = checkUsers( false, true, false )
        for nick, days in vPairs( tbl_users_expired, function( t, a, b ) return t[ b ] < t[ a ] end ) do
            if exception_tbl[ nick ] then
                user:reply( msg_delreg_exception .. nick, hub.getbot() )
            elseif protected_levels[ tbl_users_level[ nick ] ] then
                user:reply( utf.format( msg_delreg_exception_level, nick, tbl_users_level[ nick ] ), hub.getbot() )
            else
                hub.delreguser( nick )
                user:reply( utf.format( msg_delreg_expired, nick, days ), hub.getbot() )
                report.send( report_activate, report_hubbot, report_opchat, report_level, utf.format( msg_delreg_expired, nick, days ) )
            end
        end
    end
    if ghosts then --> Delete all expired offline users, never been used
        local tbl_users_ghosts = checkUsers( false, false, true, false )
        for nick, days in vPairs( tbl_users_ghosts, function( t, a, b ) return t[ b ] < t[ a ] end ) do
            if exception_tbl[ nick ] then
                user:reply( msg_delreg_exception .. nick, hub.getbot() )
            else
                hub.delreguser( nick )
                user:reply( utf.format( msg_delreg_unused, nick, days ), hub.getbot() )
                report.send( report_activate, report_hubbot, report_opchat, report_level, utf.format( msg_delreg_unused, nick, days ) )
            end
        end
    end
end

local userExceptions = function( add, del, delall, show, user, nick )
    if add then --> addexception
        local tbl_users_level = checkUsers( false, false, false, true )
        if keyExists( exception_tbl, nick ) then
            user:reply( msg_exceptions_add_taken .. nick, hub.getbot() )
        elseif protected_levels[ tbl_users_level[ nick ] ] then
            user:reply( utf.format( msg_exceptions_level, nick, tbl_users_level[ nick ] ), hub.getbot() )
        else
            exception_tbl[ nick ] = user:firstnick()
            util.savetable( exception_tbl, "exception_tbl", exception_file )
            user:reply( msg_exceptions_add .. nick, hub.getbot() )
        end
    end
    if del then --> delexception
        if keyExists( exception_tbl, nick ) then
            exception_tbl[ nick ] = nil
            util.savetable( exception_tbl, "exception_tbl", exception_file )
            user:reply( msg_exceptions_del .. nick, hub.getbot() )
        else
            user:reply( msg_exceptions_del_notfound .. nick, hub.getbot() )
        end
    end
    if delall then --> delexceptionall
        exception_tbl = {}
        util.savetable( exception_tbl, "exception_tbl", exception_file )
        user:reply( msg_exceptions_delall .. user:nick(), hub.getbot() )
    end
    if show then --> showexceptions
        local msg_exc, msg_lvl, l = "", "", 0
        if isEmpty( exception_tbl ) then
            msg_exc = "\t\t" .. msg_exceptions_show .. "\n"
        else
            for k, v in util.spairs( exception_tbl ) do
                msg_exc = msg_exc .. "\t\t" .. k .. "\n"
            end
        end
        for i = 1, 100, 1 do
            if keyExists( protected_levels, i ) then
                if protected_levels[ i ] then l = "true" else l = "false" end
                msg_lvl = msg_lvl .. "\t\t" .. l .. "\t\t" .. i .. "  [ " .. cfg_levels[ i ] .. " ]" .. "\n"
            end
        end
        user:reply( utf.format( msg_out_exceptions, msg_exc, msg_lvl ), hub.getbot(), hub.getbot() )
    end
end

local changeSettings = function( days, user )
    if days then --> setdays
        expired_days = tonumber( days )
        settings_tbl[ "expired_days" ] = expired_days
        util.savetable( settings_tbl, "settings_tbl", settings_file )
        user:reply( msg_settings_setdays .. expired_days, hub.getbot() )
    end
end

local onbmsg = function( user, command, parameters )
    if not permission[ user:level() ] then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end

    local param = utf.match( parameters, "^(%S+)" )
    local nick = utf.match( parameters, "^%S+ (%S+)" )
    local days = utf.match( parameters, "^%S+ (%d+)" )

    if ( param == cmd_p1 ) then --> showall
        user:reply( showUsers( true, false, false ), hub.getbot(), hub.getbot() )
        return PROCESSED
    end
    if ( param == cmd_p2 ) then --> showexpired
        user:reply( showUsers( false, true, false ), hub.getbot(), hub.getbot() )
        return PROCESSED
    end
    if ( param == cmd_p3 ) then --> showghosts
        user:reply( showUsers( false, false, true ), hub.getbot(), hub.getbot() )
        return PROCESSED
    end
    if ( param == cmd_p4 ) then --> delexpired
        delUsers( true, false, user )
        return PROCESSED
    end
    if ( param == cmd_p5 ) then --> delghosts
        delUsers( false, true, user )
        return PROCESSED
    end
    if ( param == cmd_p6 ) and nick then --> addexception
        userExceptions( true, false, false, false, user, nick )
        return PROCESSED
    end
    if ( param == cmd_p7 ) and nick then --> delexception
        userExceptions( false, true, false, false, user, nick )
        return PROCESSED
    end
    if ( param == cmd_p8 ) then --> delexceptionall
        userExceptions( false, false, true, false, user, false )
        return PROCESSED
    end
    if ( param == cmd_p9 ) then --> showexceptions
        userExceptions( false, false, false, true, user, false )
        return PROCESSED
    end
    if ( param == cmd_p10 ) and days then --> setdays
        changeSettings( days, user )
        return PROCESSED
    end
    user:reply( msg_usage, hub.getbot() )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct1_1, cmd, { cmd_p1 }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_2, cmd, { cmd_p2 }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_3, cmd, { cmd_p3 }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_4, cmd, { cmd_p4 }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_5, cmd, { cmd_p5 }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_6, cmd, { cmd_p6, "%[line:" .. ucmd_nick .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_7, cmd, { cmd_p7, "%[line:" .. ucmd_nick .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_8, cmd, { cmd_p8 }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_9, cmd, { cmd_p9 }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_10, cmd, { cmd_p10, "%[line:" .. ucmd_days .. "]" }, { "CT1" }, minlevel )
        end
        hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( { cmd }, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
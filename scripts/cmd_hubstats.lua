--[[

    cmd_hubstats.lua by pulsar

        v0.5:
            - added "month_name" table to lang files and removed unneeded "getMonth()" function

        v0.4:
            - small style fix

        v0.3:
            - small changes in showStats() function

        v0.2:
            - added util.formatbytes and removed the old one

        v0.1:
            - shows statistics about the hub
                - shows user average
                - shows share average
                - shows regs/delregs/bans/unbans

        note: this script must be above "cmd_reg.lua", "cmd_delreg.lua", "cmd_ban.lua", "cmd_unban.lua" in scriptlist
]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_hubstats"
local scriptversion = "0.5"

local cmd = "hubstats"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_getbot = hub.getbot()
local hub_debug = hub.debug
local hub_import = hub.import
local hub_getusers = hub.getusers
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local utf_match = utf.match
local string_format = string.format
local string_rep = string.rep
local table_insert = table.insert
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local util_formatbytes = util.formatbytes
local utf_format = utf.format

local os_time = os.time
local os_difftime = os.difftime
local os_date = os.date

--// save delay
local time = 1  -- default refresh time in hours (for tests use: 0.002)
local delay = time * 60 * 60
local start = os_time()

--// imports
local help, ucmd, hubcmd, hubstats_tbl
local scriptlang = cfg_get( "language" )
local oplevel = cfg_get( "cmd_hubstats_oplevel" )

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )

local help_title = lang.help_title or "hubstats"
local help_usage = lang.help_usage or "[+!#]hubstats"
local help_desc = lang.help_desc or "shows statistics about the hub"

local msg_denied = lang.msg_denied or "You are not allowed to use this command!"
local msg_empty_tbl = lang.msg_empty_tbl or "\n\n\tThe first stats will shown at the begin of the next month.\n"
local msg_label = lang.msg_label or "\tYEAR\t\tMONTH\t\tØ USERS\tØ SHARE\tREG's\t\tDELREG's\tBAN's\t\tUNBAN's"
local ucmd_menu_ct1 = lang.ucmd_menu_ct1 or { "Hub", "etc", "Hubstats" }
local msg_stats = lang.msg_stats or [[


=== HUBSTATS ========================================================================================================================

%s
%s
%s
======================================================================================================================== HUBSTATS ===
  ]]

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

--// databases
local hubstats_file = "scripts/data/cmd_hubstats.tbl"
local users_day_file = "scripts/data/cmd_hubstats_users_day.tbl"
local users_week_file = "scripts/data/cmd_hubstats_users_week.tbl"
local users_month_file = "scripts/data/cmd_hubstats_users_month.tbl"
local share_day_file = "scripts/data/cmd_hubstats_share_day.tbl"
local share_week_file = "scripts/data/cmd_hubstats_share_week.tbl"
local share_month_file = "scripts/data/cmd_hubstats_share_month.tbl"


----------
--[CODE]--
----------

--// get current user amount and hubshare
local getCurrents = function()
    local ucount, hshare = 0, 0
    for sid, user in pairs( hub_getusers() ) do
        ucount = ucount + 1
        hshare = hshare + user:share()
    end
    return ucount, hshare
end

--// sort weekdays in the right order
local sortWeekday = function( n )
    local wdays = {

        [ 0 ] = 7,
        [ 1 ] = 1,
        [ 2 ] = 2,
        [ 3 ] = 3,
        [ 4 ] = 4,
        [ 5 ] = 5,
        [ 6 ] = 6,
    }
    return wdays[ n ]
end

--// create basic table structure for hubstats_tbl
local makeTableEntrys = function()
    local hubstats_tbl = util_loadtable( hubstats_file ) or {}
    local current_month = tonumber( os_date( "%m" ) )
    local current_year = tonumber( os_date( "%Y" ) )
    local newMonth, newYear, month, year = false, false, 0, 0

    for k, v in pairs( hubstats_tbl ) do
        if k > year then
            year = k
        end
        if k == current_year then
            for key, value in pairs( v ) do
                if key > month then
                    month = key
                end
            end
        end
    end

    if current_month > month then newMonth = true end
    if current_year > year then newYear = true end

    if newYear then
        hubstats_tbl[ current_year ] = {}
        hubstats_tbl[ current_year ][ current_month ] = {}
        hubstats_tbl[ current_year ][ current_month ][ "users" ] = {}
        hubstats_tbl[ current_year ][ current_month ][ "share" ] = {}
        hubstats_tbl[ current_year ][ current_month ][ "cmds" ] = {}
        hubstats_tbl[ current_year ][ current_month ][ "users" ] = 0
        hubstats_tbl[ current_year ][ current_month ][ "share" ] = 0
        hubstats_tbl[ current_year ][ current_month ][ "cmds" ][ "reg" ] = 0
        hubstats_tbl[ current_year ][ current_month ][ "cmds" ][ "delreg" ] = 0
        hubstats_tbl[ current_year ][ current_month ][ "cmds" ][ "ban" ] = 0
        hubstats_tbl[ current_year ][ current_month ][ "cmds" ][ "unban" ] = 0
        util_savetable( hubstats_tbl, "hubstats_tbl", hubstats_file )
    else
        if newMonth then
            hubstats_tbl[ current_year ][ current_month ] = {}
            hubstats_tbl[ current_year ][ current_month ][ "users" ] = {}
            hubstats_tbl[ current_year ][ current_month ][ "share" ] = {}
            hubstats_tbl[ current_year ][ current_month ][ "cmds" ] = {}
            hubstats_tbl[ current_year ][ current_month ][ "users" ] = 0
            hubstats_tbl[ current_year ][ current_month ][ "share" ] = 0
            hubstats_tbl[ current_year ][ current_month ][ "cmds" ][ "reg" ] = 0
            hubstats_tbl[ current_year ][ current_month ][ "cmds" ][ "delreg" ] = 0
            hubstats_tbl[ current_year ][ current_month ][ "cmds" ][ "ban" ] = 0
            hubstats_tbl[ current_year ][ current_month ][ "cmds" ][ "unban" ] = 0
            util_savetable( hubstats_tbl, "hubstats_tbl", hubstats_file )
        end
    end
end
makeTableEntrys()

--// get and save stats
local saveStats = function()
    local hubstats_tbl = util_loadtable( hubstats_file ) or {}
    local users_day_tbl = util_loadtable( users_day_file ) or {}
    local users_week_tbl = util_loadtable( users_week_file ) or {}
    local users_month_tbl = util_loadtable( users_month_file ) or {}
    local share_day_tbl = util_loadtable( share_day_file ) or {}
    local share_week_tbl = util_loadtable( share_week_file ) or {}
    local share_month_tbl = util_loadtable( share_month_file ) or {}

    local current_weekday = sortWeekday( tonumber( os_date( "%w" ) ) )
    local current_month = tonumber( os_date( "%m" ) )
    local current_year = tonumber( os_date( "%Y" ) )

    local uamount = select( 1, getCurrents() )
    local hshare = select( 2, getCurrents() )

    local u, cu, s, cs
    local user_average_amount_day, user_average_amount_week, user_average_amount_month, user_average_amount_year
    local share_average_amount_day, share_average_amount_week, share_average_amount_month, share_average_amount_year

    -- day
    local newDay = false

    for k, v in pairs( users_day_tbl ) do
        if current_weekday ~= k then
            newDay = true
        end
    end
    for k, v in pairs( share_day_tbl ) do
        if current_weekday ~= k then
            newDay = true
        end
    end

    local user_entrys, share_entrys = next( users_day_tbl ), next( share_day_tbl )
    if not user_entrys then users_day_tbl[ current_weekday ] = {} end
    if not share_entrys then share_day_tbl[ current_weekday ] = {} end

    if not newDay then
        table_insert( users_day_tbl[ current_weekday ], uamount )
        table_insert( share_day_tbl[ current_weekday ], hshare )

        util_savetable( users_day_tbl, "users_day_tbl", users_day_file )
        util_savetable( share_day_tbl, "share_day_tbl", share_day_file )
    else
        user_average_amount_day, share_average_amount_day, u, cu, s, cs = 0, 0, 0, 0, 0, 0

        for k, v in pairs( users_day_tbl ) do
            for index, amount in ipairs( v ) do
                u = u + 1
                cu = cu + amount
            end
        end
        for k, v in pairs( share_day_tbl ) do
            for index, share in ipairs( v ) do
                s = s + 1
                cs = cs + share
            end
        end

        user_average_amount_day = cu / u
        user_average_amount_day = tonumber( string_format( "%.2f", user_average_amount_day ) )
        users_day_tbl = {}

        share_average_amount_day = cs / s
        share_average_amount_day = tonumber( string_format( "%.2f", share_average_amount_day ) )
        share_day_tbl = {}

        util_savetable( users_day_tbl, "users_day_tbl", users_day_file )
        util_savetable( share_day_tbl, "share_day_tbl", share_day_file )

        -- week
        local newWeek = false

        for k, v in pairs( users_week_tbl ) do
            if current_weekday < k then
                newWeek = true
            end
        end
        for k, v in pairs( share_week_tbl ) do
            if current_weekday < k then
                newWeek = true
            end
        end

        if not newWeek then
            users_week_tbl[ current_weekday ] = user_average_amount_day
            share_week_tbl[ current_weekday ] = share_average_amount_day

            util_savetable( users_week_tbl, "users_week_tbl", users_week_file )
            util_savetable( share_week_tbl, "share_week_tbl", share_week_file )
        else
            user_average_amount_week, share_average_amount_week, u, cu, s, cs = 0, 0, 0, 0, 0, 0

            for wdays, amount in pairs( users_week_tbl ) do
                u = u + 1
                cu = cu + amount
            end
            for wdays, share in pairs( share_week_tbl ) do
                s = s + 1
                cs = cs + share
            end

            user_average_amount_week = cu / u
            user_average_amount_week = tonumber( string_format( "%.2f", user_average_amount_week ) )
            users_week_tbl = {}
            users_week_tbl[ current_weekday ] = user_average_amount_day

            share_average_amount_week = cs / s
            share_average_amount_week = tonumber( string_format( "%.2f", share_average_amount_week ) )
            share_week_tbl = {}
            share_week_tbl[ current_weekday ] = share_average_amount_day

            util_savetable( users_week_tbl, "users_week_tbl", users_week_file )
            util_savetable( users_week_tbl, "share_week_tbl", share_week_file )
        end

        -- month
        local newMonth = false

        for k, v in pairs( users_month_tbl ) do
            if k == 4 then
                newMonth = true
            end
        end
        for k, v in pairs( share_month_tbl ) do
            if k == 4 then
                newMonth = true
            end
        end

        if not newMonth then
            table_insert( users_month_tbl, user_average_amount_week )
            table_insert( share_month_tbl, share_average_amount_week )

            util_savetable( users_month_tbl, "users_month_tbl", users_month_file )
            util_savetable( share_month_tbl, "share_month_tbl", share_month_file )
        else
            user_average_amount_month, share_average_amount_month, u, cu, s, cs = 0, 0, 0, 0, 0, 0

            for weeks, amount in pairs( users_month_tbl ) do
                u = u + 1
                cu = cu + amount
            end
            for weeks, share in pairs( share_month_tbl ) do
                s = s + 1
                cs = cs + share
            end

            user_average_amount_month = cu / u
            user_average_amount_month = tonumber( string_format( "%.0f", user_average_amount_month ) )
            users_month_tbl = {}
            table_insert( users_month_tbl, user_average_amount_week )

            share_average_amount_month = cs / s
            share_average_amount_month = tonumber( string_format( "%.2f", share_average_amount_month ) )
            share_month_tbl = {}
            table_insert( share_month_tbl, share_average_amount_week )

            util_savetable( users_month_tbl, "users_month_tbl", users_month_file )
            util_savetable( share_month_tbl, "share_month_tbl", share_month_file )

            -- year
            hubstats_tbl[ current_year ][ current_month ][ "users" ] = user_average_amount_month
            hubstats_tbl[ current_year ][ current_month ][ "share" ] = share_average_amount_month
            util_savetable( hubstats_tbl, "hubstats_tbl", hubstats_file )
        end
    end
end

--// read and show the stats
local showStats = function()
    local hubstats_tbl = util_loadtable( hubstats_file ) or {}
    local current_month = tonumber( os_date( "%m" ) )
    local current_year = tonumber( os_date( "%Y" ) )
    local users, share, reg, delreg, ban, unban
    local msg = ""

    for i_1 = 2000, 2100, 1 do
        for year, v in pairs( hubstats_tbl ) do
            if year == i_1 then
                for i_2 = 1, 12, 1 do
                    if not ( ( year == current_year ) and ( i_2 == current_month ) ) then
                        for m, u in pairs( v ) do
                            if m == i_2 then
                                users = u[ "users" ] or 0
                                share = util_formatbytes( u[ "share" ] )
                                if share == "0 B" then share = "0 B \t" end
                                reg = u[ "cmds" ][ "reg" ] or 0
                                delreg = u[ "cmds" ][ "delreg" ] or 0
                                ban = u[ "cmds" ][ "ban" ] or 0
                                unban = u[ "cmds" ][ "unban" ] or 0

                                msg = msg .. "\n" ..
                                "\t" .. year ..
                                "\t\t" .. month_name[ m ] ..
                                "\t" .. users ..
                                "\t\t" .. share ..
                                "\t" .. reg ..
                                "\t\t" .. delreg ..
                                "\t\t" .. ban ..
                                "\t\t" .. unban
                            end
                        end
                    end
                end
                msg = msg .. "\n"
            end
        end
    end
    local msg_sep = "\t" .. string_rep( "-", 240 )
    local msg_out = utf_format( msg_stats, msg_label, msg_sep, msg )
    return msg_out
end

hub.setlistener( "onTimer", {},
    function()
        if os_difftime( os_time() - start ) >= delay then
            makeTableEntrys()
            saveStats()
            start = os_time()
        end
        return nil
    end
)

local onbmsg = function( user, command, parameters )
    local user_level = user:level()
    if user_level < oplevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    user:reply( showStats(), hub_getbot )
    return PROCESSED
end

hub.setlistener( "onBroadcast", {},
    function( user, adccmd, txt )
        local s1, s2 = utf_match( txt, "^[+!#](%a+) (.+)" )
        local current_month = tonumber( os_date( "%m" ) )
        local current_year = tonumber( os_date( "%Y" ) )
        local command_tbl = {

            [ 1 ] = "reg",
            [ 2 ] = "delreg",
            [ 3 ] = "ban",
            [ 4 ] = "unban",
        }
        for k, v in pairs( command_tbl ) do
            if s1 == v and s2 then
                makeTableEntrys()
                local cmd, hubstats_tbl = s1, util_loadtable( hubstats_file ) or {}
                hubstats_tbl[ current_year ][ current_month ][ "cmds" ][ cmd ] =
                hubstats_tbl[ current_year ][ current_month ][ "cmds" ][ cmd ] + 1
                util_savetable( hubstats_tbl, "hubstats_tbl", hubstats_file )
            end
        end
    end
)

hub.setlistener( "onStart", {},
    function()
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, oplevel )
        end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct1, cmd, {}, { "CT1" }, oplevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
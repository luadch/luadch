--[[

    cmd_pm2offliners.lua by pulsar

        Description: sends a PM to an offline User

        v0.5:
            - additional ct1 rightclick
            - add some new table lookups
            - possibility to toggle advanced ct2 rightclick (shows complete userlist)
                - export var to "cfg/cfg.tbl"
        
        v0.4:
            - add delay timer - set the seconds after login before send
            - cleaning code
            - table lookups
        
        v0.3:
            - rename scriptname from "cmd_pm2offliners" to "cmd_pm2offliners"
            - rename databasename from "etc_pm2offliners_messages.tbl" to "cmd_pm2offliners_messages.tbl"
            - export scriptsettings to "cfg/cfg.tbl"
            
        v0.2:
            - changed rightclick style
            - changed database path and filename
            - from now on all scripts uses the same database folder
            
        v0.1:
            - checks if user is regged
            - checks if user is already online
            - added lang feature
            - added help feature

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_pm2offliners"
local scriptversion = "0.5"

local cmd = "pm"
local cmd_p_add = "add"
local cmd_p_del = "del"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_import = hub.import
local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local hub_getregusers = hub.getregusers

local utf_match = utf.match
local utf_format = utf.format
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local os_date = os.date
local os_time = os.time
local os_difftime = os.difftime
local table_maxn = table.maxn
local table_insert = table.insert
local table_sort = table.sort

--// database
local pm_file = "scripts/data/cmd_pm2offliners_messages.tbl"
local pm_tbl = util_loadtable( pm_file ) or {}

--// table flags
local tNick = "tNick"
local tDate = "tDate"
local tMsg = "tMsg"

--// imports
local minlevel = cfg_get( "cmd_pm2offliners_minlevel" )
local oplevel = cfg_get( "cmd_pm2offliners_oplevel" )
local delay = cfg_get( "cmd_pm2offliners_delay" )
local scriptlang = cfg_get( "language" )
local advanced_rc = cfg_get( "cmd_pm2offliners_advanced_rc" )

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local help_title = lang.help_title or "pm2offliners"
local help_usage = lang.help_usage or "[+!#]pm add <nick> <msg>  / or: [+!#]pm del"
local help_desc = lang.help_desc or  "sends a PM to an offline User if he is regged"

local ucmd_menu_add_1 = lang.ucmd_menu_add_1 or "User"
local ucmd_menu_add_2 = lang.ucmd_menu_add_2 or "Messages"
local ucmd_menu_add_3 = lang.ucmd_menu_add_3 or "PM to Offliner"
local ucmd_menu_add_4 = lang.ucmd_menu_add_4 or "send message"
local ucmd_menu_add_5 = lang.ucmd_menu_add_5 or "to Nick from list"
local ucmd_menu_add_6 = lang.ucmd_menu_add_6 or { "User", "Messages", "PM to Offliner", "send message", "to Nick" }
local ucmd_menu_del = lang.ucmd_menu_del or { "User", "Messages", "PM to Offliner", "clean database" }
local ucmd_popup = lang.ucmd_popup or "Message:"
local ucmd_popup2 = lang.ucmd_popup2 or "Nickname:"

local msg_denied = lang.msg_denied or "You are not allowed to use this command!"
local msg_usage = lang.msg_usage or "Usage: [+!#]pm add <nick> <msg>  / or: [+!#]pm del"
local msg_fail_1 = lang.msg_fail_1 or "User is not regged."
local msg_fail_2 = lang.msg_fail_2 or "User is already online."
local msg_ok = lang.msg_ok or "Message was saved."
local msg_del_1 = lang.msg_del_1 or "Database was cleaned."
local msg_del_2 = lang.msg_del_2 or "Database already empty."
local msg_reply = lang.msg_reply or "There are [%s] new offline messages send to you."
local msg_pm_1 = lang.msg_pm_1 or "Offline PM No. %s  |  "
local msg_pm_2 = lang.msg_pm_2 or "Sender: %s  |  Date: %s \n\n"
local msg_pm_3 = lang.msg_pm_3 or "Message: %s \n\n"


----------
--[CODE]--
----------

--// parse date output
local dateparser = function()
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
        local Datum = wochentag .. ", der " .. day .. "." .. monat .. "." .. year .. "   Zeit: " .. time
        return Datum
    elseif scriptlang == "en" then
        local day = os_date( "%d" )
        local month = os_date( "%m" )
        local year = os_date( "%Y" )
        local time = os_date( "%X" )
        local Date = month .. "/" .. day .. "/" .. year .. "  Time: " .. time
        return Date
    else
        local day = os_date( "%d" )
        local month = os_date( "%m" )
        local year = os_date( "%Y" )
        local time = os_date( "%X" )
        local Date = month .. "/" .. day .. "/" .. year .. "  Time: " .. time
        return Date
    end
end

hub.setlistener( "onBroadcast", { },
    function( user, adccmd, txt )
        local s1, s2, s3, s4 = utf_match( txt, "^[+!#](%S+) ?(%S*) ?(%S*) ?(.*)" )
        local user_nick = user:nick()
        local user_level = user:level()
        if s1 == cmd then
            if s2 == cmd_p_add then
                if user_level >= minlevel then
                    if s3 then
                        local user_isregged = false
                        local regusers, reggednicks, reggedcids = hub_getregusers()
                        for i, user in ipairs( regusers ) do
                            if ( user.is_bot ~= 1 ) and user.nick then
                                if s3 == user.nick then
                                    user_isregged = true
                                end
                            end
                        end
                        if user_isregged then
                            local user_isonline = false
                            for sid, target in pairs( hub_getusers() ) do
                                if not target:isbot() then
                                    local target_nick = target:firstnick()
                                    if s3 == target_nick then
                                        user_isonline = true
                                    end
                                end
                            end
                            if not user_isonline then
                                if s4 then
                                    local user_isintable = false
                                    for k, v in pairs( pm_tbl ) do
                                        if k == s3 then
                                            user_isintable = true
                                        end
                                    end
                                    if not user_isintable then
                                        local i = 1
                                        pm_tbl[ s3 ] = {}
                                        pm_tbl[ s3 ][ i ] = {}
                                        pm_tbl[ s3 ][ i ].tNick = user_nick
                                        pm_tbl[ s3 ][ i ].tDate = tostring( dateparser() )
                                        pm_tbl[ s3 ][ i ].tMsg = tostring( s4 )
                                        util_savetable( pm_tbl, "pm_tbl", pm_file )
                                    else
                                        local n = table_maxn( pm_tbl[ s3 ] )
                                        local i = n + 1
                                        pm_tbl[ s3 ][ i ] = {}
                                        pm_tbl[ s3 ][ i ].tNick = user_nick
                                        pm_tbl[ s3 ][ i ].tDate = tostring( dateparser() )
                                        pm_tbl[ s3 ][ i ].tMsg = tostring( s4 )
                                        util_savetable( pm_tbl, "pm_tbl", pm_file )
                                    end
                                    user:reply( msg_ok, hub_getbot )
                                    return PROCESSED
                                else
                                    user:reply( msg_usage, hub_getbot )
                                    return PROCESSED
                                end
                            else
                                user:reply( msg_fail_2, hub_getbot )
                                return PROCESSED
                            end
                        else
                            user:reply( msg_fail_1, hub_getbot )
                            return PROCESSED
                        end
                    else
                        user:reply( msg_usage, hub_getbot )
                        return PROCESSED
                    end
                else
                    user:reply( msg_denied, hub_getbot )
                    return PROCESSED
                end
            elseif s2 == cmd_p_del then
                if user_level >= oplevel then
                    local tbl_isempty = true
                    for k, v in pairs( pm_tbl ) do
                        if k then
                            tbl_isempty = false
                            pm_tbl[ k ] = nil
                        end
                    end
                    util_savetable( pm_tbl, "pm_tbl", pm_file )
                    if tbl_isempty then
                        user:reply( msg_del_2, hub_getbot )
                        return PROCESSED
                    else
                        user:reply( msg_del_1, hub_getbot )
                        return PROCESSED
                    end
                else
                    user:reply( msg_denied, hub_getbot )
                    return PROCESSED
                end
            else
                user:reply( msg_usage, hub_getbot )
                return PROCESSED
            end
        end
        return nil
    end
)

local list = {}

local sendPM = function( user, k, v  )
    list[ os_time() ] = function()
        local n = table_maxn( pm_tbl[ k ] )
        local msg = utf_format( msg_reply, n )
        user:reply( msg, hub_getbot )
        for index, infos in ipairs( v ) do
            local Nick = v[ index ].tNick
            local Date = v[ index ].tDate
            local Msg = v[ index ].tMsg
            local pm_1 = utf_format( msg_pm_1, index )
            local pm_2 = utf_format( msg_pm_2, Nick, Date )
            local pm_3 = utf_format( msg_pm_3, Msg )
            user:reply( pm_1 .. pm_2 .. pm_3, hub_getbot, hub_getbot )
        end
        pm_tbl[ k ] = nil
        util_savetable( pm_tbl, "pm_tbl", pm_file )
    end
end

hub.setlistener( "onLogin", {},
    function( user )
        local user_nick = user:firstnick()
        for k, v in pairs( pm_tbl ) do
            if k == user_nick then
                sendPM( user, k, v )
            end
        end
    end
)

hub.setlistener("onTimer", {},
    function()
        for time, func in pairs( list ) do
            if os_difftime( os_time() - time ) >= delay then
                func()
                list[ time ] = nil
            end
        end
        return nil
    end
)

hub.setlistener( "onStart", {},
    function()
        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_add_6, cmd, { cmd_p_add, "%[line:" .. ucmd_popup2 .. "]", "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, minlevel )
            if advanced_rc then
                local regusers, reggednicks, reggedcids = hub_getregusers()
                local usertbl = {}
                for i, user in ipairs( regusers ) do
                    if ( user.is_bot ~= 1 ) and user.nick then
                        table_insert( usertbl, user.nick )
                    end
                end
                table_sort( usertbl )
                for _, nick in pairs( usertbl ) do
                    ucmd.add( { ucmd_menu_add_1, ucmd_menu_add_2, ucmd_menu_add_3, ucmd_menu_add_4, ucmd_menu_add_5, nick }, cmd, { cmd_p_add, nick, "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, minlevel )
                end
            end
            ucmd.add( ucmd_menu_del, cmd, { cmd_p_del }, { "CT1" }, oplevel )
        end
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. ".lua **" )

---------
--[END]--
---------
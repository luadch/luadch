--[[

    cmd_pm2offliners.lua by pulsar

        Description: sends a PM to an offline User

        v0.8: by blastbeat
            - added new feature: if offline pm was received by target, the source of the message gets a offline notification; it will be delivered if source is online

        v0.7: by blastbeat
            - fixed error reported by sopor; if we use a delay here, we MUST CHECK whether upvalues did change in the meantime.
              users might be offline again, or delregged; the pm_tbl database might be cleaned;
              in the end it is a BAD idea to use a delay, makes things complicated, has zero benefits (-_-)
            - tried to clean up a bit, but not too much, who knows what breaks next

        v0.6:
            - removed dateparser() function
            - removed deprecated table.maxn() lua function
            - send a confirmation msg to the sender if he's online  / requested by WitchHunter
            - send date and message too  / requested by Sopor

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
local scriptversion = "0.8"

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
local hub_isnickonline = hub.isnickonline
local utf_match = utf.match
local utf_format = utf.format
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local os_date = os.date
local os_time = os.time
local os_difftime = os.difftime
local table_insert = table.insert
local table_sort = table.sort
local next = next

--// database
local pm_file = "scripts/data/cmd_pm2offliners_messages.tbl"
local pm_tbl = util_loadtable( pm_file ) or { }

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

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or "Usage: [+!#]pm add <nick> <msg>  / or: [+!#]pm del"
local msg_fail_1 = lang.msg_fail_1 or "User is not regged."
local msg_fail_2 = lang.msg_fail_2 or "User is already online."
local msg_ok = lang.msg_ok or "Message was saved."
local msg_del_1 = lang.msg_del_1 or "Database was cleaned."
local msg_del_2 = lang.msg_del_2 or "Database already empty."
local msg_reply = lang.msg_reply or "You have [%s] new offline message(s) waiting for you."
local msg_pm_1 = lang.msg_pm_1 or "Offline PM No. %s  |  "
local msg_pm_2 = lang.msg_pm_2 or "Sender: %s  |  Date: %s \n\n"
local msg_pm_3 = lang.msg_pm_3 or "Message: %s \n\n"      -- btw this is pure insanity, why splitting one message in 3?! fix this shit, but dont want the deal with the language files, so..

local msg_pm = msg_pm_1 .. msg_pm_2 .. msg_pm_3     -- ..like this

local msg_confirm = lang.msg_confirm or "The offline PM you sent to  %s  has arrived.\n\nDate: %s\nMessage: %s"


----------
--[CODE]--
----------

local add_new_record = function( source, target, msg )
    pm_tbl[ target ] = pm_tbl[ target ] or { }       -- use old entry or create a new one
    local record = { }      -- new record
    record.tNick = source
    record.tDate = os_date( "%Y-%m-%d / %H:%M:%S" )
    record.tMsg = tostring( msg )
    pm_tbl[ target ][ #pm_tbl[ target ]  + 1 ] = record      -- add record to the other messages
    util_savetable( pm_tbl, "pm_tbl", pm_file )
end

hub.setlistener( "onBroadcast", { },
    function( user, adccmd, txt )
        local s1, s2, s3, s4 = utf_match( txt, "^[+!#](%S+) ?(%S*) ?(%S*) ?(.*)" )
        local user_level = user:level()
        if s1 == cmd then
            if s2 == cmd_p_add then
                if ( user_level >= minlevel ) and user:isregged( ) then
                    if s3 then
                        local _, reggednicks, _ = hub_getregusers()
                        local profile = reggednicks[ s3 ]
                        if profile and ( profile.is_bot ~= 1 ) then
                            if profile.is_online == 0 then
                                if s4 then
                                    add_new_record( user:regnick( ), s3, s4 )
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
                    if next( pm_tbl ) == nil then       -- table is empty, get out of here...
                        user:reply( msg_del_2, hub_getbot )
                        return PROCESSED
                    end
                    pm_tbl = { }        -- create empty table, save stuff, get out of here.
                    util_savetable( pm_tbl, "pm_tbl", pm_file )
                    user:reply( msg_del_1, hub_getbot )
                    return PROCESSED
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

local listener, sendPM

local list = { }

sendPM = function( user, regnick, v  )
    list[ os_time() ] = function( )     -- as this function is supposed to run via timer, we must take care about that some objects might change during the delay ( e.g. user, pm_tbl, etc )
        local _, regnicks, _ = hub_getregusers( )
        local profile = regnicks[ regnick ]     -- pick userprofile
        if not profile then     -- user is not regged anymore. maybe he was delregged in the meantime. abort operation and all delete messages for him.
            pm_tbl[ regnick ] = nil
            return
        end
        if user.waskilled or ( not profile.is_online ) then      -- first check whether user is still online.
            return      -- no? get the fuck out of here.
        end
        local n = #v
        local msg = utf_format( msg_reply, n )
        user:reply( msg, hub_getbot )
        for index, infos in ipairs( v ) do
            local Nick = v[ index ].tNick
            local Date = v[ index ].tDate
            local Msg = v[ index ].tMsg
            local pm = utf_format( msg_pm, index, Nick, Date, Msg )
            user:reply( pm, hub_getbot, hub_getbot )
            local sender_msg = utf_format( msg_confirm, regnick, Date, Msg )
            if Nick ~= scriptname then
                add_new_record( scriptname, Nick, sender_msg )
                local p = regnicks[ Nick ]
                if p and p.is_online then
                    local users = hub.getusers( )
                    for sid, user in pairs( users ) do      -- ugly ..
                        if user:regnick( ) == Nick then listener( user ); break end
                    end
                end
            end
        end
        pm_tbl[ regnick ] = nil
        util_savetable( pm_tbl, "pm_tbl", pm_file )
    end
end

listener = function( user )
    if not user:isregged( ) then        -- non-regged users cannot receive offline pms, so..
        return      -- ..get the fuck out of here.
    end
    local regnick = user:regnick( )       -- to avoid clusterfucks with nick-tag scripts, we will use the unique reg nick of the user, which cannot change (should not! one might think about a script,
                                          -- which can change the reg nick of the user without delreg/newreg...)
    for k, v in pairs( pm_tbl ) do
        if k == regnick then
            sendPM( user, regnick, v )
            break       -- there should only be one entry in the pm_tbl for each reguser
        end
    end
end

hub.setlistener( "onLogin", { }, listener )

hub.setlistener("onTimer", { },
    function( )
        for time, func in pairs( list ) do
            if os_difftime( os_time( ) - time ) >= delay then
                func( )
                list[ time ] = nil
            end
        end
        return nil
    end
)

hub.setlistener( "onStart", { },
    function( )
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
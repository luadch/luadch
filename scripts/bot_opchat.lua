--[[

    bot_opchat by pulsar

        - this script regs an op chat with chat history
        - it exports also a module to access the op chat from other scripts

        v0.12: by pulsar
            - change date style in history
            - remove dateparser() function
            
        v0.11: by pulsar
            - add "bot_opchat_activate"
                - possibility to activate/deactivate the chat
        
        v0.10: by pulsar
            - possibility to activate/deactivate chat history
        
        v0.09: by pulsar
            - ok this is a complete new script based on my bot_advanced_chat_v0.5
            - the script brings a chat history functionality and some other useful features

        v0.08: by pulsar
            - add "msg_denied" message
            - add some new table lookups
            - add "activate" var (possibility to activate/deactivate the opchat)

        v0.07: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.06: by pulsar
            - code cleanup

        v0.05: by blastbeat
            - updated script api

        v0.04: by blastbeat
            - updated script api, cached table lookups, removed global vars

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "bot_opchat"
local scriptversion = "0.12"

--// command in main
local cmd = "opchat"
local cmd_p_help = "help"
local cmd_p_history = "history"
local cmd_p_historyall = "historyall"

--// commands in chat
local cmd_help = "help"
local cmd_history = "history"
local cmd_historyall = "historyall"

--// history: default amount of posts to show
local default_lines = 5
--// history: chat arrivals to save history_tbl
local saveit = 2


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_getbot = hub.getbot
local hub_getuser = hub.getuser
local hub_getusers = hub.getusers
local hub_regbot = hub.regbot
local hub_import = hub.import
local hub_debug = hub.debug
local utf_match = utf.match
local utf_format = utf.format
local util_loadtable = util.loadtable
local util_savearray = util.savearray
local table_insert = table.insert
local table_remove = table.remove
local string_byte = string.byte
local string_find = string.find
local os_date = os.date

--// imports
local help, ucmd, hubcmd
local activate = cfg_get( "bot_opchat_activate" )
local nick = cfg_get( "bot_opchat_nick" )
local desc = cfg_get( "bot_opchat_desc" )
local enable_history = cfg_get( "bot_opchat_history" )
local max_lines = cfg_get( "bot_opchat_max_entrys" )
local permission = cfg_get( "bot_opchat_permission" )
local scriptlang = cfg_get( "language" )

--// functions
local getPermission, checkPermission, feed, client, onbmsg, buildlog

--// database
local history_file = "scripts/data/bot_opchat_history.tbl"
local history_tbl = util_loadtable( history_file ) or {}

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local help_title = lang.help_title or "OpChat"
local help_desc = lang.help_desc or "Chat for Operators"

local msg_help_1 = lang.msg_help_1 or "  [+!#]help \t | List of available commands in chat"
local msg_help_2 = lang.msg_help_2 or "  [+!#]history \t | Shows the last posts from chat"
local msg_help_3 = lang.msg_help_3 or "  [+!#]historyall \t | Shows all saved posts from chat"

local msg_help_4 = lang.msg_help_4 or "  [+!#]opchat help"
local msg_help_5 = lang.msg_help_5 or "  [+!#]opchat history"
local msg_help_6 = lang.msg_help_6 or "  [+!#]opchat historyall"

local ucmd_menu_ct1_help = lang.ucmd_menu_ct1_help or { "User", "Messages", "Chats", "OpChat", "show help" }
local ucmd_menu_ct1_history = lang.ucmd_menu_ct1_history or { "User", "Messages", "Chats", "OpChat", "show chat history (latest)" }
local ucmd_menu_ct1_historyall = lang.ucmd_menu_ct1_historyall or { "User", "Messages", "Chats", "OpChat", "show chat history (all saved)" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command!"
local msg_denied_2 = lang.msg_denied_2 or "You are not allowed to use this chat!"
local msg_intro = lang.msg_intro or "\t\t\t\t   The last %s posts from chat:"

local msg_history = lang.msg_history or [[


========== CHATLOG ==============================================================================
%s
%s
============================================================================== CHATLOG ==========
  ]]

local msg_help_op = lang.msg_help_op or [[


=== HELP ==========================================

List of all in-chat commands:

%s
%s
%s

List of all main commands:

%s
%s
%s

========================================== HELP ===
  ]]


----------
--[CODE]--
----------

getPermission = function()
    local level = 100
    for k, v in pairs( permission ) do
        if v then if k < level then level = k end end
    end
    return level
end

--// check user permission
checkPermission = function( user )
    if permission[ user:level() ] then return true end
    return false
end

--// create history (by Motnahp)
buildlog = function( amount_lines )
    local amount = ( amount_lines or default_lines )
    if amount >= max_lines then
        amount = max_lines
    end
    local log_msg = "\n"
    local lines_msg = ""
    local x = amount
    if amount > #history_tbl then
        x,amount = #history_tbl,#history_tbl
    end
    x = #history_tbl - x
    for i,v in ipairs( history_tbl ) do
        if i > x then
            log_msg = log_msg .. " [" .. i .. "] - [ " .. v[ 1 ] .. " ] <" .. v[ 2 ] .. "> " .. v[ 3 ] .. "\n"
        end
    end
    lines_msg = utf_format( msg_intro, amount )
    log_msg = utf_format( msg_history, lines_msg, log_msg )
    return log_msg
end

local opchat, err
feed = function( msg, dispatch )
    local from, pm
    if dispatch ~= "send" then
        dispatch = "reply"
        pm = opchat or hub_getbot()
        from = hub_getbot() or opchat
    end
    for sid, user in pairs( hub_getusers() ) do
        if checkPermission( user ) then
            user[ dispatch ]( nil, msg, from, pm )
        end
    end
    if enable_history then
        local str = string_find( msg, "EMSG" )
        if not str then
            local t = { [1] = os_date( "%Y-%m-%d / %H:%M:%S" ), [2] = " ", [3] = msg }
            table_insert( history_tbl,t )
            util_savearray( history_tbl, history_file )
        end
    end
end

if activate then
    client = function( bot, cmd )
        if cmd:fourcc() == "EMSG" then
            local user = hub_getuser( cmd:mysid() )
            if not user then
                return true
            end
            if not checkPermission( user ) then
                user:reply( msg_denied_2, opchat, opchat )
                return true
            end
            cmd:setnp( "PM", bot:sid() )
            feed( cmd:adcstring(), "send" )
        end
        return true
    end
end

local savehistory = 0

if activate then
    if enable_history then
        onbmsg = function( user, command, parameters )
            local param, id = utf_match( parameters, "^(%S+) (%S+)$" )
            local param2 = utf_match( parameters, "^(%S+)$" )
            local user_level = user:level()
            local user_nick = user:nick()
            if not permission[ user:level() ] then
                user:reply( msg_denied, hub_getbot() )
                return PROCESSED
            end
            if param2 == cmd_p_help then
                local msg = utf_format( msg_help_op, msg_help_1, msg_help_2, msg_help_3, msg_help_4, msg_help_5, msg_help_6 )
                user:reply( msg, hub_getbot() )
                return PROCESSED
            end
            if param2 == cmd_p_history then
                user:reply( buildlog( default_lines ), hub_getbot() )
                return PROCESSED
            end
            if param2 == cmd_p_historyall then
                user:reply( buildlog( max_lines ), hub_getbot() )
                return PROCESSED
            end
        end

        hub.setlistener( "onPrivateMessage", {},
            function( user, targetuser, adccmd, msg )
                local cmd = utf_match( msg, "^[+!#](%S+)" )
                local cmd2, id = utf_match( msg, "^[+!#](%S+) (%S+)" )
                local user_level = user:level()
                if msg then
                    if targetuser == opchat then
                        local result = 48
                        result = string_byte( msg, 1 )
                        if result ~= 33 and result ~= 35 and result ~= 43 then
                            savehistory = savehistory + 1
                            local data = utf_match(  msg, "(.+)" )
                            local t = {
                                [1] = os_date( "%Y-%m-%d / %H:%M:%S" ),
                                [2] = user:nick( ),
                                [3] = data
                            }
                            table_insert( history_tbl,t )
                            for x = 1, #history_tbl -  max_lines do
                                table_remove( history_tbl, 1 )
                            end
                            if savehistory >= saveit then
                                savehistory = 0
                                util_savearray( history_tbl, history_file )
                            end
                        end
                        if checkPermission( user ) then
                            if cmd == cmd_help then
                                local msg = utf_format( msg_help_op, msg_help_1, msg_help_2, msg_help_3, msg_help_4, msg_help_5, msg_help_6 )
                                user:reply( msg, opchat, opchat )
                                return PROCESSED
                            end
                            if cmd == cmd_history then
                                user:reply( buildlog( default_lines ), opchat, opchat )
                                return PROCESSED
                            end
                            if cmd == cmd_historyall then
                                user:reply( buildlog( max_lines ), opchat, opchat )
                                return PROCESSED
                            end
                        end
                    end
                end
                return nil
            end
        )

        hub.setlistener( "onStart", {},
            function()
                help = hub_import( "cmd_help" )
                if help then
                    local help_usage = utf_format( msg_help_op, msg_help_1, msg_help_2, msg_help_3, msg_help_4, msg_help_5, msg_help_6 )
                    help.reg( help_title, help_usage, help_desc, getPermission() )
                end
                ucmd = hub_import( "etc_usercommands" )
                if ucmd then
                    ucmd.add( ucmd_menu_ct1_help, cmd, { cmd_p_help }, { "CT1" }, getPermission() )
                    ucmd.add( ucmd_menu_ct1_history, cmd, { cmd_p_history }, { "CT1" }, getPermission() )
                    ucmd.add( ucmd_menu_ct1_historyall, cmd, { cmd_p_historyall }, { "CT1" }, getPermission() )
                end
                hubcmd = hub_import( "etc_hubcommands" )
                assert( hubcmd )
                assert( hubcmd.add( cmd, onbmsg ) )
                return nil
            end
        )

        hub.setlistener( "onExit", {},
            function()
                util_savearray( history_tbl, history_file )
            end
        )
    end
end

if activate then
    opchat, err = hub_regbot{ nick = nick, desc = desc, client = client }
    err = err and error( err )
end

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

--// public //--

return {

    feed = feed,    -- use opchat = hub.import "bot_opchat"; opchat.feed( msg ) in other scripts to send a normal message to the opchat

}
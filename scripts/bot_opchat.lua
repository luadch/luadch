--[[

    bot_opchat.lua by blastbeat

        - this script regs a op chat with chat history
        - it exports also a module to access the op chat from other scripts

        v0.17: by pulsar
            - completed the 'hide bot on missing permission' part

        v0.16: by pulsar
            - removed table lookups

        v0.15: by blastbeat:
            - simplify 'activate' logic
            - expose bot object via interface

        v0.14: by pulsar
            - send help msg if no parameter is specified  / thx Sopor
            - add command to reset history  / thx Sopor

        v0.13: by pulsar
            - typo fix  / thx Kaas

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
local scriptversion = "0.17"

--// command in main
local cmd = "opchat"
local cmd_p_help = "help"
local cmd_p_history = "history"
local cmd_p_historyall = "historyall"
local cmd_p_historyclear = "historyclear"

--// commands in chat
local cmd_help = "help"
local cmd_history = "history"
local cmd_historyall = "historyall"
local cmd_historyclear = "historyclear"

--// history: default amount of posts to show
local default_lines = 5
--// history: chat arrivals to save history_tbl
local saveit = 1

--// imports
local help, ucmd, hubcmd
local activate = cfg.get( "bot_opchat_activate" )

if not activate then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return nil
end

local nick = cfg.get( "bot_opchat_nick" )
local desc = cfg.get( "bot_opchat_desc" )
local enable_history = cfg.get( "bot_opchat_history" )
local max_lines = cfg.get( "bot_opchat_max_entrys" )
local permission = cfg.get( "bot_opchat_permission" )
local scriptlang = cfg.get( "language" )
local oplevel = cfg.get( "bot_opchat_oplevel" )

--// functions
local getPermission, checkPermission, feed, client, onbmsg, buildlog, clear_history

--// database
local history_file = "scripts/data/bot_opchat_history.tbl"
local history_tbl = util.loadtable( history_file ) or {}

--// msgs
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local help_title = lang.help_title or "OpChat"
local help_desc = lang.help_desc or "Chat for Operators"

local msg_help_1 = lang.msg_help_1 or "  [+!#]help \t | List of available commands in chat"
local msg_help_2 = lang.msg_help_2 or "  [+!#]history \t | Shows the last posts from chat"
local msg_help_3 = lang.msg_help_3 or "  [+!#]historyall \t | Shows all saved posts from chat"
local msg_help_7 = lang.msg_help_7 or "  [+!#]historyclear \t | Clear history"

local msg_help_4 = lang.msg_help_4 or "  [+!#]opchat help"
local msg_help_5 = lang.msg_help_5 or "  [+!#]opchat history"
local msg_help_6 = lang.msg_help_6 or "  [+!#]opchat historyall"
local msg_help_8 = lang.msg_help_8 or "  [+!#]opchat historyclear"

local ucmd_menu_ct1_help = lang.ucmd_menu_ct1_help or { "User", "Messages", "Chats", "OpChat", "show help" }
local ucmd_menu_ct1_history = lang.ucmd_menu_ct1_history or { "User", "Messages", "Chats", "OpChat", "show chat history (latest)" }
local ucmd_menu_ct1_historyall = lang.ucmd_menu_ct1_historyall or { "User", "Messages", "Chats", "OpChat", "show chat history (all saved)" }
local ucmd_menu_ct1_historyclear = lang.ucmd_menu_ct1_historyclear or { "User", "Messages", "Chats", "OpChat", "clear history" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command!"
local msg_denied_2 = lang.msg_denied_2 or "You are not allowed to use this chat!"
local msg_intro = lang.msg_intro or "\t\t\t\t   The last %s posts from chat:"
local msg_clear = lang.msg_clear or "Chat history was cleared."

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
%s

List of all main commands:

%s
%s
%s
%s

========================================== HELP ===
  ]]


----------
--[CODE]--
----------

clear_history = function()
    history_tbl = {}
    util.savearray( history_tbl, history_file )
end

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
    lines_msg = utf.format( msg_intro, amount )
    log_msg = utf.format( msg_history, lines_msg, log_msg )
    return log_msg
end

local opchat, err
feed = function( msg, dispatch )
    local from, pm
    if dispatch ~= "send" then
        dispatch = "reply"
        pm = opchat or hub.getbot()
        from = hub.getbot() or opchat
    end
    for sid, user in pairs( hub.getusers() ) do
        if checkPermission( user ) then
            user[ dispatch ]( nil, msg, from, pm )
        end
    end
    if enable_history then
        local str = string.find( msg, "EMSG" )
        if not str then
            local t = { [1] = os.date( "%Y-%m-%d / %H:%M:%S" ), [2] = " ", [3] = msg }
            table.insert( history_tbl,t )
            util.savearray( history_tbl, history_file )
        end
    end
end

client = function( bot, cmd )
    if cmd:fourcc() == "EMSG" then
        local user = hub.getuser( cmd:mysid() )
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

local savehistory = 0

if enable_history then
    onbmsg = function( user, command, parameters )
        local param, id = utf.match( parameters, "^(%S+) (%S+)$" )
        local param2 = utf.match( parameters, "^(%S+)$" )
        local user_level = user:level()
        if not permission[ user_level ] then
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        end
        if param2 == cmd_p_help then
            local msg = utf.format( msg_help_op, msg_help_1, msg_help_2, msg_help_3, msg_help_7, msg_help_4, msg_help_5, msg_help_6, msg_help_8 )
            user:reply( msg, hub.getbot() )
            return PROCESSED
        end
        if param2 == cmd_p_history then
            user:reply( buildlog( default_lines ), hub.getbot() )
            return PROCESSED
        end
        if param2 == cmd_p_historyall then
            user:reply( buildlog( max_lines ), hub.getbot() )
            return PROCESSED
        end
        if param2 == cmd_p_historyclear then
            if user_level >= oplevel then
                clear_history()
                user:reply( msg_clear, hub.getbot() )
            else
                user:reply( msg_denied, hub.getbot() )
            end
            return PROCESSED
        end
        local msg = utf.format( msg_help_op, msg_help_1, msg_help_2, msg_help_3, msg_help_7, msg_help_4, msg_help_5, msg_help_6, msg_help_8 )
        user:reply( msg, hub.getbot() )
        return PROCESSED
    end
    hub.setlistener( "onPrivateMessage", {},
        function( user, targetuser, adccmd, msg )
            local cmd = utf.match( msg, "^[+!#](%S+)" )
            local cmd2, id = utf.match( msg, "^[+!#](%S+) (%S+)" )
            local user_level = user:level()
            if msg then
                if targetuser == opchat then
                    local result = 48
                    result = string.byte( msg, 1 )
                    if result ~= 33 and result ~= 35 and result ~= 43 then
                        savehistory = savehistory + 1
                        local data = utf.match(  msg, "(.+)" )
                        local t = {
                            [1] = os.date( "%Y-%m-%d / %H:%M:%S" ),
                            [2] = user:nick( ),
                            [3] = data
                        }
                        table.insert( history_tbl,t )
                        for x = 1, #history_tbl -  max_lines do
                            table.remove( history_tbl, 1 )
                        end
                        if savehistory >= saveit then
                            savehistory = 0
                            util.savearray( history_tbl, history_file )
                        end
                    end
                    if checkPermission( user ) then
                        if cmd == cmd_help then
                            local msg = utf.format( msg_help_op, msg_help_1, msg_help_2, msg_help_3, msg_help_7, msg_help_4, msg_help_5, msg_help_6, msg_help_8 )
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
                    if cmd == cmd_historyclear then
                        if user_level >= oplevel then
                            clear_history()
                            user:reply( msg_clear , opchat, opchat )
                        else
                            user:reply( msg_denied, opchat, opchat )
                        end
                        return PROCESSED
                    end
                end
            end
            return nil
        end
    )
    hub.setlistener( "onExit", {},
        function()
            util.savearray( history_tbl, history_file )
        end
    )
end

hub.setlistener( "onStart", {},
    function()
        -- hide bot in userlist (fake a disconnect)
        for sid, user in pairs( hub.getusers() ) do
            if not user:isbot() and not permission[ user:level() ] then
                user:send( "IQUI " .. opchat:sid() .. "\n")
            end
        end
        help = hub.import( "cmd_help" )
        if help then
            local help_usage = utf.format( msg_help_op, msg_help_1, msg_help_2, msg_help_3, msg_help_7, msg_help_4, msg_help_5, msg_help_6, msg_help_8 )
            help.reg( help_title, help_usage, help_desc, getPermission() )
        end
        if enable_history then
            ucmd = hub.import( "etc_usercommands" )
            if ucmd then
                ucmd.add( ucmd_menu_ct1_help, cmd, { cmd_p_help }, { "CT1" }, getPermission() )
                ucmd.add( ucmd_menu_ct1_history, cmd, { cmd_p_history }, { "CT1" }, getPermission() )
                ucmd.add( ucmd_menu_ct1_historyall, cmd, { cmd_p_historyall }, { "CT1" }, getPermission() )
                ucmd.add( ucmd_menu_ct1_historyclear, cmd, { cmd_p_historyclear }, { "CT1" }, oplevel )
            end
        end
        hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)


opchat, err = hub.regbot{ nick = nick, desc = desc, client = client }
err = err and error( err )

hub.setlistener( "onLogin", {},
    function( user )
        if not permission[ user:level() ] then
           user:send( "IQUI " .. opchat:sid() .. "\n" )
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

--// public //--

return {

    bot = opchat,  -- expose opchat bot object
    feed = feed,    -- use opchat = hub.import "bot_opchat"; opchat.feed( msg ) in other scripts to send a normal message to the opchat

}
--[[

    bot_session_chat by pulsar

        - this script can reg session chats

        - permissions:
            - if an user creates a session chat then only he has the permission to add/remove members
            - only members can read/write

        v0.4:
            - fix #26 / thx Sopor

        v0.3:
            - rename some function names
            - add new function: remove_chats()
                - if hub restarts then all session chats will be removed
            - add some new table lookups and clean some parts of code

        v0.2:
            - this script is now a part of Luadch
            - export scriptsettings to "cfg/cfg.tbl"

        v0.1:
            - command: [+!#]sessionchat <chatname>
            - chat command: [+!#]help
            - chat command: [+!#]members
            - chat owner command: [+!#]add <nick>
            - chat owner command: [+!#]del <nick>

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "bot_session_chat"
local scriptversion = "0.4"

--// command in main (rightclick)
local cmd = "sessionchat"
local cmd_p = "delall"

--// commands in chat
local cmd_help = "help"
local cmd_members = "members"
local cmd_add = "add"
local cmd_del = "del"


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
local hub_broadcast = hub.broadcast
local hub_escapefrom = hub.escapefrom
local hub_escapeto = hub.escapeto
local hub_isnickonline = hub.isnickonline
local utf_match = utf.match
local utf_format = utf.format
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local table_concat = table.concat
local table_insert = table.insert
local table_remove = table.remove
local string_find = string.find

--// imports
local help, ucmd, hubcmd
local minlevel = cfg_get( "bot_session_chat_minlevel" )
local masterlevel = cfg_get( "bot_session_chat_masterlevel" )
local chatprefix = cfg_get( "bot_session_chat_chatprefix" )
local scriptlang = cfg_get( "language" )

--// functions
local feed, client, onbmsg
local reg_chats_onstart, check_If_chat_exists, check_if_member, check_if_owner,
      get_members, check_if_online, refresh_bot, msg_to_members, remove_chats

--// database
local sessions_file = "scripts/data/bot_session_chat.tbl"
local sessions_tbl = util_loadtable( sessions_file ) or {}

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local help_title = lang.help_title or "Session Chat"
local help_usage = lang.help_usage or"[+!#]sessionchat <chatname>"
local help_desc = lang.help_desc or "Session Chats are temporary chats for one user session"

local msg_help_1 = lang.msg_help_1 or "  [+!#]help  \t| List of available commands in chat"
local msg_help_2 = lang.msg_help_2 or "  [+!#]members\t| List of all members"
local msg_help_3 = lang.msg_help_3 or "  [+!#]add <nick>\t| add a new member"
local msg_help_4 = lang.msg_help_4 or "  [+!#]del <nick>\t| remove an existing member"

local ucmd_menu_ct1_create = lang.ucmd_menu_ct1_create or { "User", "Messages", "Chats", "Session Chat", "create a chat for this session" }
local ucmd_menu_ct1_remove = lang.ucmd_menu_ct1_remove or { "Hub", "etc", "Session Chat", "remove all session chats" }
local ucmd_popup = lang.ucmd_popup or "Chatname (no whitespaces!)"

local chatdesc = lang.chatdesc or "by: %s | members: %s"

local msg_denied = lang.msg_denied or "You are not allowed to use this command!"
local msg_denied_2 = lang.msg_denied_2 or "You are not allowed to use this chat!"
local msg_denied_3 = lang.msg_denied_3 or "You can not remove yourself."
local msg_usage = lang.msg_usage or "Usage: [+!#]sessionchat <chatname>"
local msg_already = lang.msg_already or "User is already a member: "
local msg_nomember = lang.msg_nomember or "User is not a member: "
local msg_notonline = lang.msg_notonline or "User is not online: "
local msg_welcome = lang.msg_welcome or "Welcome "
local msg_new_member = lang.msg_new_member or "The following user was added as member: "
local msg_del = lang.msg_del or "The following user is no longer a member: "
local msg_del_2 = lang.msg_del_2 or "You are no longer a member of this chat."
local msg_delall = lang.msg_delall or "All Session Chats removed."
local msg_create = lang.msg_create or "%s has added a new Session Chat: %s"
local msg_create2 = lang.msg_create2 or "You have added a new Session Chat: %s"
local msg_create3 = lang.msg_create3 or "You are the only one who can add or remove members in your chat!"
local msg_chatexists = lang.msg_chatexists or "Chat already exists."

local msg_members = lang.msg_members or [[


=== MEMBERS ==============================

%s

============================== MEMBERS ===
  ]]

local msg_help_owner = lang.msg_help_owner or [[


=== OWNER HELP ===================================

List of all in-chat commands:

%s
%s
%s
%s

=================================== OWNER HELP ===
  ]]

local msg_help_member = lang.msg_help_member or [[


=== MEMBERS HELP =================================

List of all in-chat commands:

%s
%s

================================= MEMBERS HELP ===
  ]]


----------
--[CODE]--
----------

local sessionchat, err

--// flags
local owner, members = "owner", "members"

--// reg session chats on scriptstart
reg_chats_onstart = function()
    sessions_tbl = util_loadtable( sessions_file )
    local i = 0
    for k, v in pairs( sessions_tbl ) do
        if k then
            local err, sessionchat
            local chatname = k
            local owner = sessions_tbl[ k ].owner
            for k, v in pairs( v ) do
                if k == "members" then
                    for k, v in pairs( v ) do
                        i = i + 1
                    end
                end
            end
            local description = utf_format( chatdesc, owner, i )
            local nick, desc = chatname, description
            sessionchat, err = hub_regbot{ nick = nick, desc = desc, client = client }
            i = 0
        end
    end
end

--// check if chat exists
check_If_chat_exists = function( chat )
    sessions_tbl = util_loadtable( sessions_file )
    for k, v in pairs( sessions_tbl ) do
        if k == chat then
            return true
        end
    end
    return false
end

--// check if user is member
check_if_member = function( user, chat )
    sessions_tbl = util_loadtable( sessions_file )
    for k, v in pairs( sessions_tbl ) do
        if k == chat then
            for k, v in pairs( v ) do
                if k == "members" then
                    for i, usr in pairs( v ) do
                        if usr == user then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

--// check if user is chat owner
check_if_owner = function( user, chat )
    sessions_tbl = util_loadtable( sessions_file )
    local user_nick = user:nick()
    for k, v in pairs( sessions_tbl ) do
        if k == chat then
            for k, v in pairs( v ) do
                if k == "owner" then
                    if v == user_nick then
                        return true
                    end
                end
            end
        end
    end
    return false
end

--// get all members from chat
get_members = function( chat )
    sessions_tbl = util_loadtable( sessions_file )
    local tbl = {}
    for k, v in pairs( sessions_tbl ) do
        if k == chat then
            for k, v in pairs( v ) do
                if k == "members" then
                    for i, usr in pairs( v ) do
                        tbl[ i ] = "\t" .. usr
                    end
                end
            end
        end
    end
    local msg = table_concat( tbl, "\n" )
    return msg
end

--// check if user is online and not a bot
check_if_online = function( user )
    for sid, onlineuser in pairs( hub_getusers() ) do
        if not onlineuser:isbot() then
            if onlineuser == user then
                return true
            end
        end
    end
    return false
end

--// refresh members count of chats
refresh_bot = function( chat )
    sessions_tbl = util_loadtable( sessions_file )
    local i = 0
    for k, v in pairs( sessions_tbl ) do
        if k == chat then
            --// kill the bot
            chat = hub_isnickonline( k )
            chat:kill( "ISTA 230 " )
            --// reg him new -> ok this is an ugly hack
            local err, sessionchat
            local chatname = k
            local owner = sessions_tbl[ k ].owner
            for k, v in pairs( v ) do
                if k == "members" then
                    for k, v in pairs( v ) do
                        i = i + 1
                    end
                end
            end
            local description = utf_format( chatdesc, owner, i )
            --local desc = hub_escapeto( description )
            --chatname:inf():setnp( "DE", desc )
            local nick, desc = chatname, description
            sessionchat, err = hub_regbot{ nick = nick, desc = desc, client = client }
        end
    end
end

--// send msg to all members
msg_to_members = function( chat, msg )
    sessions_tbl = util_loadtable( sessions_file )
    for k, v in pairs( sessions_tbl ) do
        if k == chat then
            local bot_name = hub_isnickonline( chat )
            for k, v in pairs( v ) do
                if k == "members" then
                    for i, usr in pairs( v ) do
                        local user = hub_isnickonline( usr ) or false
                        if user then
                            user:reply( msg, bot_name, bot_name )
                        end
                    end
                end
            end
        end
    end
end

--// remove all session chats
remove_chats = function()
    sessions_tbl = {}
    util_savetable( sessions_tbl, "sessions_tbl", sessions_file )
end

feed = function( msg, dispatch, chat, cmd )
    local from, pm
    if dispatch ~= "send" then
        dispatch = "reply"
        pm = chat or hub_getbot()
        from = hub_getbot() or chat
    end
    local txt_adc = hub_escapefrom( cmd:pos( 4 ) )
    local txt  = utf_match( txt_adc, "^[+!#](%S+)" ) or ""
    local txt2 = utf_match( txt_adc, "^[+!#]%S+ (%S+)" )
    for sid, user in pairs( hub_getusers() ) do
        local bot_nick = chat:nick()
        local user_nick = user:nick()
        if check_if_member( user_nick, bot_nick ) then
            if txt == ( cmd_help or cmd_members ) then
                -- do not send chat commands to users
            elseif txt == ( cmd_add and txt2 ) or ( cmd_del and txt2 ) then
                -- do not send chat commands to users
            else
                user[ dispatch ]( nil, msg, from, pm )
            end
        end
    end
end

client = function( bot, cmd )
    if cmd:fourcc() == "EMSG" then
        local user = hub_getuser( cmd:mysid() )
        if not user then
            return true
        end
        local user_nick = user:nick()
        if not check_if_member( user_nick, bot:nick() ) then
            user:reply( msg_denied_2, bot, bot )
            return true
        end
        cmd:setnp( "PM", bot:sid() )
        feed( cmd:adcstring(), "send", bot, cmd )
        local bot_name = hub_isnickonline( bot:nick() )
        local msg = hub_escapefrom( cmd:pos( 4 ) )
        local cmd = utf_match( msg, "^[+!#](%S+)" )
        local cmd2, id = utf_match( msg, "^[+!#](%S+) (%S+)" )
        if cmd == cmd_help then
            if check_if_owner( user, bot:nick() ) then
                local msg_help = utf_format( msg_help_owner, msg_help_1, msg_help_2, msg_help_3, msg_help_4 )
                user:reply( msg_help, bot_name, bot_name )
            else
                local msg_help = utf_format( msg_help_member, msg_help_1, msg_help_2 )
                user:reply( msg_help, bot_name, bot_name )
            end
        end
        if cmd == cmd_members then
            local msg = utf_format( msg_members, get_members( bot:nick() ) )
            user:reply( msg, bot_name, bot_name )
        end
        if cmd2 == cmd_add and id then
            if check_if_owner( user, bot:nick() ) then
                local target = hub_isnickonline( id ) or false
                if target then
                    if not check_if_member( id, bot:nick() ) then
                        sessions_tbl = util_loadtable( sessions_file ) or {}
                        --// add user
                        table_insert( sessions_tbl[ bot:nick() ][ members ], id )
                        util_savetable( sessions_tbl, "sessions_tbl", sessions_file )
                        --// msg to existing members
                        msg_to_members( bot:nick(), msg_new_member .. id )
                        --// msg to new member
                        local msg_help = utf_format( msg_help_member, msg_help_1, msg_help_2 )
                        target:reply( msg_help, bot_name, bot_name )
                        target:reply( msg_welcome .. id, bot_name, bot_name )
                        --// refresh members count in description
                        refresh_bot( bot:nick() )
                    else
                        user:reply( msg_already .. id, bot_name, bot_name )
                    end
                else
                    user:reply( msg_notonline .. id, bot_name, bot_name )
                end

            else
                user:reply( msg_denied, bot_name, bot_name )
            end
        end
        if cmd2 == cmd_del and id then
            if check_if_owner( user, bot:nick() ) then
                if check_if_member( id, bot:nick() ) then
                    sessions_tbl = util_loadtable( sessions_file ) or {}
                    if user_nick ~= id then
                        for k, v in pairs( sessions_tbl ) do
                            if k == bot:nick() then
                                for k, v in pairs( v ) do
                                    if k == "members" then
                                        for i, usr in pairs( v ) do
                                            if id == usr then
                                                --// del user
                                                table_remove( sessions_tbl[ bot:nick() ][ members ], i )
                                                util_savetable( sessions_tbl, "sessions_tbl", sessions_file )
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        --// msg to still existing members
                        msg_to_members( bot:nick(), msg_del .. id )
                        --// msg to member
                        local target = hub_isnickonline( id ) or false
                        if target then
                            target:reply( msg_del_2, bot_name, bot_name )
                        end
                        --// refresh members count in description
                        refresh_bot( bot:nick() )
                    else
                        user:reply( msg_denied_3, bot_name, bot_name )
                    end
                else
                    user:reply( msg_nomember .. id, bot_name, bot_name )
                end
            else
                user:reply( msg_denied, bot_name, bot_name )
            end
        end
    end
    return true
end

onbmsg = function( user, command, parameters )
    sessions_tbl = util_loadtable( sessions_file ) or {}
    local chatname = utf_match( parameters, "^(%S+)$" )
    local user_level = user:level()
    local user_nick = user:nick()
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot() )
        return PROCESSED
    end
    if chatname == cmd_p then
        if user_level >= masterlevel then
            sessions_tbl = util_loadtable( sessions_file ) or {}
            for k, v in pairs( sessions_tbl ) do
                if k then
                    local chat = hub_isnickonline( k )
                    chat:kill( "ISTA 230 " )
                    sessions_tbl[ k ] = nil
                    util_savetable( sessions_tbl, "sessions_tbl", sessions_file )
                end
            end
            user:reply( msg_delall, hub_getbot() )
            return PROCESSED
        else
            user:reply( msg_denied, hub_getbot() )
            return PROCESSED
        end
    elseif chatname then
        --// check if chatname already exists
        local chat = chatprefix .. chatname
        if check_If_chat_exists( chat ) then
            user:reply( msg_chatexists, hub_getbot() )
            return PROCESSED
        else
            --// reg the chat
            local description = utf_format( chatdesc, user_nick, 1 )
            local nick, desc = chatprefix .. chatname, description
            sessionchat, err = hub_regbot{ nick = nick, desc = desc, client = client }
            err = err and error( err )
            --// save chat infos to tbl
            sessions_tbl[ nick ] = {}
            sessions_tbl[ nick ].owner = user_nick
            sessions_tbl[ nick ].members = {}
            table_insert( sessions_tbl[ nick ][ members ], user_nick )
            util_savetable( sessions_tbl, "sessions_tbl", sessions_file )
            --// send msg to all
            local msg = utf_format( msg_create, user_nick, nick )
            hub_broadcast( msg, hub_getbot() )
            --// send info msg to chat-owner
            local msg2 = utf_format( msg_create2, nick )
            local msg_help = utf_format( msg_help_owner, msg_help_1, msg_help_2, msg_help_3, msg_help_4 )
            local bot_name = hub_isnickonline( nick )
            user:reply( msg_help, bot_name, bot_name )
            user:reply( msg2, bot_name, bot_name )
            user:reply( msg_create3, bot_name, bot_name )
            return PROCESSED
        end
    end
    user:reply( msg_usage, hub_getbot() )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        reg_chats_onstart()
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct1_create, cmd, { "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_remove, cmd, { cmd_p }, { "CT1" }, masterlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.setlistener( "onLogout", {},
    function( user )
        sessions_tbl = util_loadtable( sessions_file )
        local user_nick = user:nick()
        local chat
        for k, v in pairs( sessions_tbl ) do
            if k then
                if sessions_tbl[ k ].owner == user_nick then
                    chat = hub_isnickonline( k )
                    chat:kill( "ISTA 230 " )
                    sessions_tbl[ k ] = nil
                    util_savetable( sessions_tbl, "sessions_tbl", sessions_file )
                end
            end
        end
    end
)

hub.setlistener( "onExit", {},
    function()
        remove_chats()
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
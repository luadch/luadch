--[[

        cmd_gag.lua by motnahp

            - this script adds a command "gag" to mute or kennylize a user
            - usage: [+!#]gag mute|kennylize|ungag|show <NICK>

            v0.06: by pulsar
                - removed send_report() function, using report import functionality now
                - fix command declaration in messages

            v0.05: by pulsar
                - removed "cmd_gag_minlevel" import
                    - using util.getlowestlevel( tbl ) instead of "cmd_gag_minlevel"

            v0.04: by pulsar
                - check if opchat is activated

            v0.03: by pulsar
                - added some new table lookups
                - added possibility to send report as feed to opchat

            v0.02: by Motnahp
                - small fix in "onBroadcast" listener

]]--


--// settings begin //--

local scriptname = "cmd_gag"
local scriptversion = "0.06"

local cmd = "gag"
local prm0 = "mute"
local prm1 = "kennylize"
local prm2 = "show"
local prm3 = "ungag"

--// table lookups
local hub_isnickonline = hub.isnickonline
local hub_bot = hub.getbot()
local hub_broadcast = hub.broadcast
local hub_getusers = hub.getusers
local utf_match = utf.match
local utf_format = utf.format
local util_loadtable = util.loadtable
local util_savearray =util.savearray
local util_getlowestlevel = util.getlowestlevel
local table_remove = table.remove
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_import = hub.import

--// imports
local hubcmd, help, ucmd
local scriptlang = cfg_get("language")
local lang, err = cfg_loadlanguage(scriptlang, scriptname); lang = lang or {}; err = err and hub_debug(err)
local permission = cfg_get("cmd_gag_permission")
local hub_bot_nick = cfg_get("hub_bot")
local op_chat_nick = cfg_get("bot_opchat_nick")
local reg_chat_nick = cfg_get("bot_regchat_nick")
local op_chat_permission = cfg_get("bot_opchat_permission")
local reg_chat_permission = cfg_get("bot_regchat_permission")
local report = hub_import( "etc_report" )
local report_activate = cfg_get( "cmd_gag_report" )
local llevel = cfg_get("cmd_gag_llevel")
local report_hubbot = cfg_get( "cmd_gag_report_hubbot" )
local report_opchat = cfg_get( "cmd_gag_report_opchat" )


local char_tbl = {

    a = "*abfl* ", b = "*Вumf* ", c = "*Coh* ", d = "*umfl* ", e = "*uff* ", f = "*offl* ", g = "*omhg* ",
    h = "*umulum* ", i = "*mm* ", j = "*luh* ", k = "*lumf* ", l = "*egll* ", m = "*umlum* ", n = "*uuuh* ",
    o = "*pfffl* ", p = "*mflo* ", q = "*ugugu* ", r = "*olol* ", s = "*uhgg* ", t = "*blll* ", u = "*aggah* ",
    v = "*hugh* ", w = "*ähll* ", x = "*tuguh* ", y = "*uumh* ", z = "*omph* ",

    A = "*abfl* ", B = "*Вumf* ", C = "*Coh* ", D = "*umfl* ", E = "*uff* ", F = "*offl* ", G = "*omhg* ",
    H = "*umulum* ", I = "*mm* ", J = "*luh* ", K = "*lumf* ", L = "*egll* ", M = "*umlum* ", N = "*uuuh* ",
    O = "*pfffl* ", P = "*mflo* ", Q = "*ugugu* ", R = "*olol* ", S = "*uhgg* ", T = "*blll* ", U = "*aggah* ",
    V = "*hugh* ", W = "*ähll* ", X = "*tuguh* ", Y = "*uumh* ", Z = "*omph* ",

}
--// settings end //--

--// database
local gag_path = "scripts/data/cmd_gag.tbl"
local gag_tbl = util_loadtable(gag_path)

--// msgs
local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or  "usage: [+!#]gag mute|kennylize|ungag|show <NICK>"
local msg_off = lang.msg_off or "User not found/regged."
local msg_god = lang.msg_god or "You cannot touch gods."

local msg_show_users = lang.msg_show_users or [[

=== GAG =========================

Muted users: (%s)
%s

Kennylized users: (%s)
%s

========================= GAG ===
  ]]

local msg_add_user = lang.msg_add_user or "User %s was gagged with mode %s by %s"
local msg_remove_user = lang.msg_remove_user or "User %s was ungagged by %s"
local msg_error_in = lang.msg_error_in or "User already gagged,  remove his restrictions before adding another one."
local msg_error_out = lang.msg_error_out or "User %s has no restriction set."
local msg_user_restriction_added = lang.msg_user_restriction_added or "You are now under talk restriction: %s"
local msg_user_restriction_removed = lang.msg_user_restriction_removed or "Your talk restrictions were removed."


local help_title = lang.help_title or "gag"
local help_usage = lang.help_usage or "[+!#]gag mute|kennylize|ungag|show <NICK>"
local help_desc = lang.help_desc or "mute, kennyzlize or ungag a user; or just show you the restricted users"

local ucmd_nick = lang.ucmd_nick or "Nick:"

local ucmd_menu_ct0 = lang.ucmd_menu_ct0 or { "Gag", "Mute User" }
local ucmd_menu_ct1 = lang.ucmd_menu_ct1 or { "Gag", "Kennylize User" }
local ucmd_menu_ct2 = lang.ucmd_menu_ct2 or { "User", "Control", "Gag", "show Users" }
local ucmd_menu_ct3 = lang.ucmd_menu_ct3 or { "User", "Control", "Gag", "ungag User by nick" }
local ucmd_menu_ct4 = lang.ucmd_menu_ct4 or { "Gag", "Ungag User" }

--// functions // --
local show_users
local add_user
local remove_user
local check_user_input
local save
local replace_chars


local minlevel = util_getlowestlevel( permission )

local onbmsg = function(user, command, parameters)
    local level = user:level()
    if level < minlevel then
        user:reply(msg_denied, hub_bot)
        return PROCESSED
    end
    local prm, target = utf_match(parameters, "^(%S+) (.+)")
    local prm_2 = utf_match(parameters, "^(%S+)")

    if prm == prm0 or prm == prm1 or prm == prm3 then
        target = hub_isnickonline(target)
        if not target then
            user:reply(msg_off, hub_bot)
            return PROCESSED
        end
        if target:level() > permission[user:level()] then
            user:reply(msg_god, hub_bot)
            return PROCESSED
        end
        if target:firstnick() == user:firstnick() then
            user:reply(msg_god, hub_bot)
            return PROCESSED
        end
    end

    if prm == prm0 then -- mute
        user:reply(add_user(target, "mute", user), hub_bot)
    end

    if prm == prm1 then -- kennylize
        user:reply(add_user(target, "kennylize", user), hub_bot)
    end

    if prm_2 == prm2 then -- show
        user:reply(show_users(), hub_bot)
    end

    if prm == prm3 then -- ungag
        user:reply(remove_user(target, user), hub_bot)
    end

    return PROCESSED
end

hub.setlistener( "onBroadcast", { },
    function(user, adccmd, msg)
        if #gag_tbl > 0 then
            local restricted, mode, answer = check_user_input(user, msg)
            if restricted then
                if mode == "kennylize" then
                    hub_broadcast(answer, user)
                    return PROCESSED
                elseif mode == "mute" then
                    return PROCESSED
                end
            end
        end
    end
)

hub.setlistener( "onPrivateMessage", { },
    function(user, targetuser, adccmd, msg)
        if #gag_tbl > 0 then
            local restricted, mode, answer = check_user_input(user, msg)
            if restricted then
                if mode == "kennylize" then
                    local targetuser_nick = targetuser:firstnick()
                    if targetuser:isbot() and not (targetuser_nick == hub_bot_nick)  then
                        local permission
                        local send = false
                        if targetuser_nick == op_chat_nick then
                            permission = op_chat_permission
                            send = true
                        elseif targetuser_nick == reg_chat_nick then
                            permission = reg_chat_permission
                            send = true
                        end
                        if send and permission[user:level()] then
                            for sid, tuser in pairs(hub_getusers()) do
                                if send and permission[tuser:level()] then
                                    tuser:reply(answer, user, targetuser)
                                end
                            end
                        end
                        return PROCESSED
                    else
                        user:reply(answer, user, targetuser)
                        targetuser:reply(answer, user, user)
                        return PROCESSED
                    end
                elseif mode == "mute" then
                    return PROCESSED
                end
            end
        end
    end
)

hub.setlistener( "onStart", { },
    function()
        help = hub_import("cmd_help")  -- add help
        if help then
            help.reg(help_title, help_usage, help_desc, minlevel)  -- reg help
        end
        ucmd = hub_import("etc_usercommands")  -- add usercommand
        if ucmd then
           ucmd.add(ucmd_menu_ct0, cmd, {prm0, "%[userNI]"}, {"CT2"}, minlevel)  -- mute
           ucmd.add(ucmd_menu_ct1, cmd, {prm1, "%[userNI]" }, { "CT2" }, minlevel)  -- kennylize
           ucmd.add(ucmd_menu_ct2, cmd, {prm2}, {"CT1"}, minlevel)  -- show
           ucmd.add(ucmd_menu_ct3, cmd, {prm3, "%[line:"..ucmd_nick.."]" }, { "CT1" }, minlevel)  -- ungag
           ucmd.add(ucmd_menu_ct4, cmd, {prm3, "%[userNI]"}, {"CT2"}, minlevel)  -- ungag
        end
        hubcmd = hub_import("etc_hubcommands")  -- add hubcommand
        assert(hubcmd)
        assert(hubcmd.add(cmd, onbmsg))
        return nil
    end
)

-- functions --
show_users = function()
	local msg_mute = ""
	local msg_kennylize = ""
    local count_mute = 0
    local count_kennylize = 0

	for i, tbl in ipairs(gag_tbl) do
        if tbl.mode == "mute" then
            count_mute = count_mute + 1
            msg_mute = msg_mute.."\n\t"..(tbl.user_nick or " ")
        elseif tbl.mode == "kennylize" then
            count_kennylize = count_kennylize + 1
            msg_kennylize = msg_kennylize.."\n\t"..(tbl.user_nick or " ")
        end
	end
	return utf_format(msg_show_users, count_mute ,msg_mute, count_kennylize, msg_kennylize)
end

add_user = function(target, mode, user)
    local nick = target:firstnick()
	local msg, key, except, inlist
	for i, tbl in ipairs(gag_tbl) do  -- is user restricted?
		if tbl.user_nick == nick then
			inlist = true
			break
		end
	end

	if not inlist then
		gag_tbl[ #gag_tbl + 1 ] = {
			user_nick = nick,
			mode = mode
		}
        save()
        target:reply(utf_format(msg_user_restriction_added, mode), hub_bot, hub_bot)
		msg = utf_format(msg_add_user, target:nick(), mode, user:nick())
        report.send( report_activate, report_hubbot, report_opchat, llevel, msg )
	else
		msg = utf_format(msg_error_in, nick)
	end
	return msg
end

remove_user = function(target, user)
    local target_nick = target:nick()
    local target_firstnick = target:firstnick()
    local user_nick = user:nick()

    local key, inlist, msg
	for i, tbl in ipairs(gag_tbl) do  -- is user in restricted?
		key = i
        if tbl.user_nick == target_firstnick then
			inlist = true
			break
		end
	end
	if inlist then  -- to check if he is in the list yet, if yes remove him
		table_remove(gag_tbl, key)
		save()
        target:reply(msg_user_restriction_removed, hub_bot, hub_bot)
		msg = utf_format(msg_remove_user, target_nick, user_nick)
        report.send( report_activate, report_hubbot, report_opchat, llevel, msg )
	else
		msg = utf_format(msg_error_out, target_nick)
	end
    return msg
end

check_user_input = function(target, msg)
    local nick = target:firstnick()
    for i, tbl in ipairs( gag_tbl ) do  -- is user in restricted?
        if tbl.user_nick == nick then
			if tbl.mode == "mute" then
                return true, tbl.mode, msg
            elseif tbl.mode == "kennylize" then
                return true, tbl.mode, replace_chars(msg)
            end
		end
	end
end

save = function()
    util_savearray( gag_tbl, gag_path )
    hub_debug("saved gag tbl")
end

replace_chars = function(msg)
    local output = ""
    for c in string.gmatch(msg, ".") do
		if char_tbl[c] then
            output = output..char_tbl[c]
        end
	end
    return output
end

hub_debug( "** Loaded "..scriptname.." "..scriptversion.." **" )
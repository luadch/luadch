--[[

    cfg.lua by blastbeat

        v0.45: by pulsar
            - cmd_gag settings:
                - added "cmd_gag_user_notifiy" function
            - cmd_rules.lua settings:
                - removed "cmd_rules_rules" function
            - etc_banner.lua settings:
                - removed "etc_banner_banner" function
            - usr_hide_share.lua settings:
                - added "usr_hide_share_restrictions" function
                - changed "usr_hide_share_permission" function

        v0.44: by pulsar
            - hub_runtime.lua settings:
                - added "hub_runtime_minlevel" function
                - added "hub_runtime_report" function
                - added "hub_runtime_report_opchat" function
                - added "hub_runtime_report_hubbot" function
                - added "hub_runtime_llevel" function
            - cmd_setpass.lua settings:
                - renamed "cmd_setpas_permission" to "cmd_setpass_permission"
                - renamed "cmd_setpas_advanced_rc" to "cmd_setpass_advanced_rc"
                - renamed "cmd_setpas_min_length" to "cmd_setpass_min_length"
            - etc_cmdlog.lua settings:
                - changed "etc_cmdlog_command_tbl"
            - improved out_error messages

        v0.43: by blastbeat
            - changes in saveusers() function

        v0.42: by pulsar
            - etc_trafficmanager.lua settings:
                - added "etc_trafficmanager_send_loop" function
                - added "etc_trafficmanager_loop_time" function
            - cmd_topic.lua settings:
                - added "cmd_topic_report" function
                - added "cmd_topic_report_hubbot" function
                - added "cmd_topic_report_opchat" function
                - added "cmd_topic_llevel" function
            - cmd_setpas.lua settings:
                - added "cmd_setpas_min_length" function
            - cmd_unban.lua settings:
                - removed "cmd_unban_report" function
                - removed "cmd_unban_report_hubbot" function
                - removed "cmd_unban_report_opchat" function
                - removed "cmd_unban_llevel" function
            - etc_motd.lua settings:
                - added "etc_motd_activate" function
            - added "cmd_sslinfo.lua settings"
                - added "cmd_sslinfo_minlevel" function
            - etc_userlogininfo.lua settings:
                - added "etc_userlogininfo_activate" function
            - cmd_myinf.lua settings:
                - added "cmd_myinf_permission"
            - bot_regchat.lua settings:
                - added "bot_regchat_oplevel" function
            - bot_opchat.lua settings:
                - added "bot_opchat_oplevel" function
            - scripts table:
                - changed the order of some scripts
                - renamed "cmd_setpas.lua" to "cmd_setpass.lua"
                - added "cmd_sslinfo.lua"
                - added "cmd_myinf.lua"
            - removed "hub_pass" function

        v0.41: by pulsar
            - usr_redirect.lua settings:
                - changed comment title part from "usr_redirect.lua settings" to "cmd_redirect.lua settings"
                - changed var names:
                    - from "usr_redirect_activate"      to "cmd_redirect_activate"
                    - from "usr_redirect_permission"    to "cmd_redirect_permission"
                    - from "usr_redirect_level"         to "cmd_redirect_level"
                    - from "usr_redirect_url"           to "cmd_redirect_url"
                    - from "usr_redirect_report"        to "cmd_redirect_report"
                    - from "usr_redirect_report_opchat" to "cmd_redirect_report_opchat"
                    - from "usr_redirect_report_hubbot" to "cmd_redirect_report_hubbot"
                    - from "usr_redirect_llevel"        to "cmd_redirect_llevel"
            - changed "usr_redirect.lua" to "cmd_redirect.lua" in scripttable
            - added "cafile" param to the SSL parameter settings
            - etc_motd.lua settings:
                - add "etc_motd_destination_main" function
                - add "etc_motd_destination_pm" function
            - cmd_rules.lua settings:
                - add "cmd_rules_destination_main" function
                - add "cmd_rules_destination_pm" function

        v0.40: by pulsar
            - usr_redirect.lua settings:
                - add "usr_redirect_permission" function

        v0.39: by pulsar
            - etc_trafficmanager.lua settings:
                - add "etc_trafficmanager_permission" function
                - add "etc_trafficmanager_report" function
                - add "etc_trafficmanager_report_hubbot" function
                - add "etc_trafficmanager_report_opchat" function
                - add "etc_trafficmanager_llevel" function
            - etc_msgmanager.lua settings:
                - add "etc_msgmanager_activate" function
                - add "etc_msgmanager_permission" function
                - add "etc_msgmanager_report" function
                - add "etc_msgmanager_report_hubbot" function
                - add "etc_msgmanager_report_opchat" function
                - add "etc_msgmanager_llevel" function
            - etc_cmdlog.lua settings:
                - added "trafficmanager" to command table
            - cmd_ban.lua settings:
                - removed "cmd_ban_minlevel" function
            - cmd_unban.lua settings:
                - removed "cmd_unban_minlevel" function
            - cmd_reg.lua settings:
                - removed "cmd_reg_minlevel" function
            - cmd_delreg.lua settings:
                - removed "cmd_delreg_minlevel" function
            - cmd_upgrade.lua settings:
                - removed "cmd_upgrade_minlevel" function
            - cmd_accinfo.lua settings:
                - removed "cmd_accinfo_minlevel" function
                - removed "cmd_accinfo_oplevel" function
            - cmd_setpas.lua settings:
                - removed "cmd_setpas_oplevel" function
            - cmd_userinfo.lua settings:
                - removed "cmd_userinfo_minlevel" function
            - cmd_gag.lua settings:
                - removed "cmd_gag_minlevel" function
            - cmd_reload.lua settings:
                - removed "cmd_reload_minlevel" function
            - cmd_restart.lua settings:
                - removed "cmd_restart_minlevel" function
            - cmd_shutdown.lua settings:
                - removed "cmd_shutdown_minlevel" function
            - cmd_errors.lua settings:
                - removed "cmd_errors_minlevel" function
            - cmd_mass.lua settings:
                - removed "cmd_mass_minlevel" function
            - etc_chatlog.lua settings:
                - removed "etc_chatlog_min_level" function
            - etc_offlineusers.lua settings:
                - removed "etc_offlineusers_min_level" function

        v0.38: by pulsar
            - added: level 55 [SBOT] to all script permissions
            - changing default permission values of some scripts

        v0.37: by pulsar
            - added: functions for "usr_redirect.lua settings"
            - added: "usr_redirect.lua" to scripttable

        v0.36: by pulsar
            - etc_trafficmanager.lua settings:
                - add "etc_trafficmanager_sharecheck"

        v0.35: by pulsar
            - add "hub_runtime.lua" to scripttable
            - removed "cmd_error.lua" from scripttable

        v0.34: by pulsar
            - usr_hubs.lua settings:  / thx DerWahre
                - add "usr_hubs_report" function
                - add "usr_hubs_report_hubbot" function
                - add "usr_hubs_report_opchat" function
                - add "usr_hubs_llevel" function
            - cmd_accinfo.lua settings:
                - add "cmd_accinfo_minlevel" function
            - etc_offlineusers.lua settings:
                - add "etc_offlineusers_max_offline_days_auto" function
                - add "etc_offlineusers_report" function
                - add "etc_offlineusers_report_hubbot" function
                - add "etc_offlineusers_report_opchat" function
                - add "etc_offlineusers_llevel" function
            - bot_regchat.lua settings:
                - add "bot_regchat_activate" function
            - bot_opchat.lua settings:
                - add "bot_opchat_activate" function

        v0.33: by pulsar
            - changes in "ssl_params"

        v0.32: by pulsar
            - add "etc_ccpmblocker.lua" function
            - add "etc_ccpmblocker.lua" to scripttable

        v0.31: by pulsar
            - changing TLS Cipher from: "AES256-SHA" to "ECDHE-RSA-AES256-SHA"

        v0.30: by pulsar
            - removed: cmd_managebans.lua functions
            - removed: cmd_managebans.lua from scriptlist
            - etc_dhtblocker.lua settings:
                - add "etc_dhtblocker.lua" to scripttable
                - add "etc_dhtblocker_activate" function
                - add "etc_dhtblocker_block_level" function
                - add "etc_dhtblocker_block_time" function
                - add "etc_dhtblocker_report" function
                - add "etc_dhtblocker_report_toopchat" function
                - add "etc_dhtblocker_report_hubbot" function
                - add "etc_dhtblocker_report_level" function

        v0.29: by pulsar
            - bot_regchat.lua settings:
                - add "bot_regchat_history" function
                - add "bot_regchat_max_entrys" function
            - bot_opchat.lua settings:
                - add "bot_opchat_history" function
                - add "bot_opchat_max_entrys" function

        v0.28: by pulsar
            - bot_opchat.lua settings:
                - removed "bot_opchat_activate" function
            - bot_regchat.lua settings:
                - removed "bot_regchat_activate" function

        v0.27: by pulsar
            - etc_banner.lua settings:
                - added "etc_banner_activate" function
            - cmd_delreg.lua settings:
                - changing type of permission table function (array of integer instead of array of boolean)
            - add level 0 to "min_share" function
            - add level 0 to "max_share" function
            - add level 0 to "min_slots" function
            - add level 0 to "max_slots" function
            - add level 0 to "cmd_ban_permission" function
            - add level 0 to "cmd_unban_permission" function
            - add level 0 to "cmd_reg_permission" function
            - add level 0 to "cmd_delreg_permission" function
            - add level 0 to "cmd_upgrade_permission" function
            - add level 0 to "cmd_accinfo_permission" function
            - add level 0 to "cmd_setpas_permission" function
            - add level 0 to "cmd_userinfo_permission" function
            - add level 0 to "cmd_gag_permission" function

        v0.26: by pulsar
            - usr_share.lua settings:
                - remove "usr_share_godlevel" function
                - change "min_share" function
                - change "max_share" function
            - usr_slots.lua settings:
                - remove "usr_slots_godlevel" function
                - change "min_slots" function
                - change "max_slots" function

        v0.25: by pulsar
            - cmd_ban.lua settings:
                - added "cmd_ban_report_hubbot" function
                - added "cmd_ban_report_opchat" function
            - cmd_unban.lua settings:
                - added "cmd_unban_report_hubbot" function
                - added "cmd_unban_report_opchat" function
            - cmd_reg.lua settings:
                - added "cmd_reg_report_hubbot" function
                - added "cmd_reg_report_opchat" function
            - cmd_delreg.lua settings:
                - added "cmd_delreg_report_hubbot" function
                - added "cmd_delreg_report_opchat" function
            - cmd_disconnect.lua settings:
                - added "cmd_disconnect_report_hubbot" function
                - added "cmd_disconnect_report_opchat" function
            - cmd_gag.lua settings:
                - added "cmd_gag_report" function
                - added "cmd_gag_report_hubbot" function
                - added "cmd_gag_report_opchat" function
            - cmd_nickchange.lua settings:
                - added "cmd_nickchange_report_hubbot" function
                - added "cmd_nickchange_report_opchat" function
            - cmd_upgrade.lua settings:
                - added "cmd_upgrade_report" function
                - added "cmd_upgrade_report_hubbot" function
                - added "cmd_upgrade_report_opchat" function
                - added "cmd_upgrade_llevel" function

        v0.24: by pulsar
            - added "etc_msgmanager.lua" to scripttable
            - added "etc_msgmanager.lua" functions

        v0.23: by pulsar
            - added "cmd_pm2offliners_advanced_rc" function
            - added "cmd_accinfo_advanced_rc" function
            - added "cmd_setpas_advanced_rc" function
            - added "cmd_nickchange_advanced_rc" function
            - added "cmd_upgrade_advanced_rc" function

        v0.22: by pulsar
            - small permission fix in "bot_pm2ops.lua settings"
            - added "bot_regchat.lua" function
            - added "bot_opchat.lua" function

        v0.21: by pulsar
            - added "bot_pm2ops.lua" to scripttable
            - added "bot_pm2ops.lua" functions

        v0.20: by pulsar
            - added "usr_hide_share.lua" to scripttable
            - added "usr_hide_share.lua" functions

        v0.19: by pulsar
            - added permission table to: "usr_nick_prefix.lua"
                - possibility to choose which levels should be tagged
            - added permission table to: "usr_desc_prefix.lua"
                - possibility to choose which levels should be tagged
            - added "cmd_hubstats.lua" to scripttable
            - added "cmd_hubstats.lua" function

        v0.18: by pulsar
            - added "etc_records.lua" to scripttable
            - added "etc_records.lua" functions
            - added "bot_session_chat.lua" to scripttable
            - added "bot_session_chat.lua" functions
            - added "cmd_myip.lua" to scripttable

        v0.17: by pulsar
            - added "cmd_nickchange.lua" to scripttable
            - added "cmd_nickchange.lua" functions
            - added "nickchange" to "etc_cmdlog_command_tbl"
            - added "etc_trafficmanager.lua" to scripttable
            - added "etc_trafficmanager.lua" functions
            - added "cmd_gag.lua" to scripttable
            - added "cmd_gag.lua" functions

        v0.16: by pulsar
            - added "cmd_slots.lua" to scripttable
            - added "cmd_slots_minlevel" permission

        v0.15: by pulsar
            - added "max_hubs" permission for script: "usr_hubs.lua"
            - added "bot_regchat.lua" to scripttable

        v0.14: by pulsar
            - added "hub_bot_cleaner.lua" to scripttable

        v0.13: by pulsar
            - added "cmd_usersearch.lua" functions
            - added "cmd_usersearch.lua" to scripttable
            - added "cmd_uptime.lua" function
            - added "cmd_uptime.lua" to scripttable
            - added "cmd_setpas_oplevel" function

        v0.12: by pulsar
            - added "onlogin" function for script: "cmd_hubinfo.lua"
            - removed "etc_userlogininfo_line" function

        v0.11: by pulsar
            - added "cmd_mass_oplevel" function

        v0.10: by pulsar
            - renamed "cmd_version.lua" to "cmd_hubinfo.lua" in scriptlist
            - renamed "cmd_version_minlevel" to "cmd_hubinfo_minlevel" function

        v0.09: by pulsar
            - added "cmd_topic.lua" function
            - added "cmd_topic.lua" to scripttable
            - added "etc_chatlog.lua" functions
            - added "etc_chatlog.lua" to scripttable

        v0.08: by pulsar
            - removed "etc_cmdlog_label_top" and "etc_cmdlog_label_bottom" function

        v0.07: by pulsar
            - added "cmd_pm2offliners.lua" functions

        v0.06: by pulsar
            - rename scriptname from "etc_pm2offliners" to "cmd_pm2offliners"
            - import scriptsettings from "scripts/cmd_pm2offliners.lua"

        v0.05: by pulsar
            - added "etc_pm2offliners.lua" to scripttable

        v0.04: by pulsar
            - removed "hub_user_ranks.lua" from scripttable

        v0.03: by pulsar
            - added scriptsettings to "/cfg/cfg.tbl"

        v0.02: by pulsar
            - added keyprint feature

        v0.01: by blastbeat
            - this script manages the configuration files

]]--

----------------------------------// DECLARATION //--

--// lua functions //--

local type = use "type"
local pairs = use "pairs"
local ipairs = use "ipairs"
local assert = use "assert"
local tostring = use "tostring"

--// lua lib methods //--

local os_date = use "os".date

--// core scripts //--

local out

local util = use "util"
local const = use "const"

local types = use "types"

--// core methods //--

local out_error

local util_savetable = util.savetable
local util_loadtable = util.loadtable
local util_savearray = util.savearray

local types_utf8 = types.utf8
local types_table = types.get "table"
local types_number = types.get "number"
local types_boolean = types.get "boolean"

local types_adcstr

local CONFIG_PATH = const.CONFIG_PATH

--// functions //--

local set
local get
local init
local checkcfg
local reload
local loadusers
local saveusers
local loadlanguage
local registerevent
local checklanguage
local loadcfgprofile

--// tables //--

local _event

local _settings
local _defaultsettings

--// simple data types //--

local _

local _cfgfile
--local _cfgfile_basic
--local _cfgfile_expert
local _cfgbackup
--local _cfgbackup_basic
--local _cfgbackup_expert

----------------------------------// DEFINITION //--

_settings = { }
_event = { reload = { } }

_cfgfile = CONFIG_PATH .. "cfg.tbl"
--_cfgfile_basic = CONFIG_PATH .. "cfg_basic.tbl"
--_cfgfile_expert = CONFIG_PATH .. "cfg_expert.tbl"
_cfgbackup = CONFIG_PATH .. "cfg.tbl.backup"
--_cfgbackup_basic = CONFIG_PATH .. "cfg_basic.tbl.backup"
--_cfgbackup_expert = CONFIG_PATH .. "cfg_expert.tbl.backup"

_defaultsettings = {

    ---------------------------------------------------------------------------------------------------------------------------------
    --// Basic Settings

    hub_name = { "Luadch Hub",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    hub_description = { "your hub description",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    hub_bot = { "[BOT]HubSecurity",
        function( value )
            if not types_adcstr( value, nil, true ) or #value == 0 then
                return false
            end
            return true
        end
    },
    hub_bot_desc = { "[ BOT ] hub security",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    hub_hostaddress = { "your.host.addy.org",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    tcp_ports = { { 5000 },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not types_number( k, nil, true ) then
                        return false
                    end
                end
            end
            return true
        end
    },
    ssl_ports = { { 5001 },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not types_number( k, nil, true ) then
                        return false
                    end
                end
            end
            return true
        end
    },
    use_ssl = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    use_keyprint = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    keyprint_type = { "/?kp=SHA256/",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    keyprint_hash = { "<your_kp>",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    hub_website = { "http://yourwebsite.org",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    hub_network = { "your hubnetwork name",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    hub_owner = { "you",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    reg_only = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    nick_change = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    max_users = { 100,
        function( value )
            return types_number( value, nil, true )
        end
    },
    user_path = { CONFIG_PATH,
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    reg_level = { 20,
        function( value )
            return types_number( value, nil, true )
        end
    },
    key_level = { 50,
        function( value )
            return types_number( value, nil, true )
        end
    },
    bot_level = { 55,
        function( value )
            return types_number( value, nil, true )
        end
    },
    debug = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    log_errors = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    log_events = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    log_scripts = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    log_path = { "././log/",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    language = { "en",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    core_lang_path = { "lang/",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    scripts_lang_path = { "././scripts/lang/",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    --[[
    hub_pass = { "jsjfjs87374737472374jdjdfj384",
        function( value )
            return types_boolean( value, nil, true ) or types_adcstr( value, nil, true )
        end
    },
    ]]
    max_bad_password = { 5,
        function( value )
            return types_number( value, nil, true )
        end
    },
    bad_pass_timeout = { 300,
        function( value )
            return types_number( value, nil, true )
        end
    },
    no_cid_taken = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    ranks = { {

        "Bot",
        "Reg",
        "Op",
        "Admin",
        "Owner",

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in ipairs( value ) do
                    if not types_utf8( k, nil, true ) then
                        return false
                    end
                end
            end
            return true
        end
    },
    bot_rank = { 1,
        function( value )
            return types_number( value, nil, true )
        end
    },
    reg_rank = { 2,
        function( value )
            return types_number( value, nil, true )
        end
    },
    op_rank = { 4,
        function( value )
            return types_number( value, nil, true )
        end
    },
    admin_rank = { 8,
        function( value )
            return types_number( value, nil, true )
        end
    },
    owner_rank = { 16,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// Your hub levels with level names (array of strings)

    levels = { {

        [ 0 ] = "UNREG",
        [ 10 ] = "GUEST",
        [ 20 ] = "REG",
        [ 30 ] = "VIP",
        [ 40 ] = "SVIP",
        [ 50 ] = "SERVER",
        [ 55 ] = "SBOT",
        [ 60 ] = "OPERATOR",
        [ 70 ] = "SUPERVISOR",
        [ 80 ] = "ADMIN",
        [ 100 ] = "HUBOWNER",

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_utf8( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// bot_regchat.lua settings

    bot_regchat_activate = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    bot_regchat_nick = { "[CHAT]RegChat",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    bot_regchat_desc = { "[ CHAT ] chatroom for reg users",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    bot_regchat_history = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    bot_regchat_max_entrys = { 300,
        function( value )
            return types_number( value, nil, true )
        end
    },
    bot_regchat_oplevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },
    bot_regchat_permission = { {

        [ 0 ] = false,
        [ 10 ] = false,
        [ 20 ] = true,
        [ 30 ] = true,
        [ 40 ] = true,
        [ 50 ] = true,
        [ 55 ] = true,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// bot_opchat.lua settings

    bot_opchat_activate = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    bot_opchat_nick = { "[CHAT]OpChat",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    bot_opchat_desc = { "[ CHAT ] chatroom for operators",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    bot_opchat_history = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    bot_opchat_max_entrys = { 300,
        function( value )
            return types_number( value, nil, true )
        end
    },
    bot_opchat_oplevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },
    bot_opchat_permission = { {

        [ 0 ] = false,
        [ 10 ] = false,
        [ 20 ] = false,
        [ 30 ] = false,
        [ 40 ] = false,
        [ 50 ] = false,
        [ 55 ] = false,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// bot_pm2ops.lua settings

    bot_pm2ops_activate = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    bot_pm2ops_nick = { "[CHAT]PmToOps",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    bot_pm2ops_desc = { "[ CHAT ] send msg to all ops",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    bot_pm2ops_permission = { {

        [ 0 ] = false,
        [ 10 ] = true,
        [ 20 ] = true,
        [ 30 ] = true,
        [ 40 ] = true,
        [ 50 ] = true,
        [ 55 ] = false,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_accinfo.lua settings

    cmd_accinfo_permission = { {

    [ 0 ] = 0,
    [ 10 ] = 0,
    [ 20 ] = 0,
    [ 30 ] = 0,
    [ 40 ] = 0,
    [ 50 ] = 0,
    [ 55 ] = 0,
    [ 60 ] = 50,
    [ 70 ] = 60,
    [ 80 ] = 70,
    [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    cmd_accinfo_advanced_rc = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_ascii.lua settings

    cmd_ascii_minlevel = { 20,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_slots.lua settings

    cmd_slots_minlevel = { 0,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_ban.lua settings

    cmd_ban_default_time = { 20,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_ban_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_ban_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_ban_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_ban_permission = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 50,
        [ 70 ] = 60,
        [ 80 ] = 70,
        [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    cmd_ban_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_delreg.lua settings

    cmd_delreg_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_delreg_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_delreg_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_delreg_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_delreg_permission = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 0,
        [ 70 ] = 0,
        [ 80 ] = 0,
        [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_disconnect.lua settings

    cmd_disconnect_minlevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_disconnect_sendmainmsg = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_disconnect_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_disconnect_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_disconnect_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_disconnect_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_errors.lua settings

    cmd_errors_permission = { {

        [ 0 ] = false,
        [ 10 ] = false,
        [ 20 ] = false,
        [ 30 ] = false,
        [ 40 ] = false,
        [ 50 ] = false,
        [ 55 ] = false,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_mass.lua settings

    cmd_mass_permission = { {

        [ 0 ] = false,
        [ 10 ] = false,
        [ 20 ] = false,
        [ 30 ] = true,
        [ 40 ] = true,
        [ 50 ] = true,
        [ 55 ] = true,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    cmd_mass_oplevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_reg.lua settings

    cmd_reg_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_reg_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_reg_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_reg_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_reg_permission = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 20,
        [ 70 ] = 30,
        [ 80 ] = 60,
        [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_reload.lua settings

    cmd_reload_permission = { {

        [ 0 ] = false,
        [ 10 ] = false,
        [ 20 ] = false,
        [ 30 ] = false,
        [ 40 ] = false,
        [ 50 ] = false,
        [ 55 ] = false,
        [ 60 ] = false,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_restart.lua settings

    cmd_restart_permission = { {

        [ 0 ] = false,
        [ 10 ] = false,
        [ 20 ] = false,
        [ 30 ] = false,
        [ 40 ] = false,
        [ 50 ] = false,
        [ 55 ] = false,
        [ 60 ] = false,
        [ 70 ] = false,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    cmd_restart_toggle_countdown = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_rules.lua settings

    cmd_rules_minlevel = { 0,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_rules_destination_main = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_rules_destination_pm = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_setpass.lua settings

    cmd_setpass_permission = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 0,
        [ 70 ] = 0,
        [ 80 ] = 0,
        [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    cmd_setpass_advanced_rc = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_setpass_min_length = { 10,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_nickchange.lua settings

    cmd_nickchange_minlevel = { 20,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_nickchange_oplevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_nickchange_maxnicklength = { 50,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_nickchange_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_nickchange_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_nickchange_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_nickchange_advanced_rc = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_shutdown.lua settings

    cmd_shutdown_permission = { {

        [ 0 ] = false,
        [ 10 ] = false,
        [ 20 ] = false,
        [ 30 ] = false,
        [ 40 ] = false,
        [ 50 ] = false,
        [ 55 ] = false,
        [ 60 ] = false,
        [ 70 ] = false,
        [ 80 ] = false,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    cmd_shutdown_toggle_countdown = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_talk.lua settings

    cmd_talk_minlevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_pm2offliners.lua settings

    cmd_pm2offliners_minlevel = { 30,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_pm2offliners_oplevel = { 100,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_pm2offliners_delay = { 7,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_pm2offliners_advanced_rc = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_unban.lua settings

    cmd_unban_permission = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 60,
        [ 70 ] = 70,
        [ 80 ] = 80,
        [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_upgrade.lua settings

    cmd_upgrade_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_upgrade_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_upgrade_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_upgrade_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_upgrade_permission = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 0,
        [ 70 ] = 0,
        [ 80 ] = 0,
        [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    cmd_upgrade_advanced_rc = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_userinfo.lua settings

    cmd_userinfo_permission = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 50,
        [ 70 ] = 60,
        [ 80 ] = 70,
        [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_userlist.lua settings

    cmd_userlist_minlevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_usersearch.lua settings

    cmd_usersearch_minlevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_usersearch_max_limit = { 20,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_hubinfo.lua settings

    cmd_hubinfo_minlevel = { 10,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_hubinfo_onlogin = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_uptime.lua settings

    cmd_uptime_minlevel = { 0,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_banner.lua settings

    etc_banner_activate = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_banner_time = { 1,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_banner_destination_main = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_banner_destination_pm = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_banner_permission = { {

        [ 0 ] = true,
        [ 10 ] = true,
        [ 20 ] = true,
        [ 30 ] = true,
        [ 40 ] = true,
        [ 50 ] = true,
        [ 55 ] = false,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_chatlog.lua settings

    etc_chatlog_min_level_adv = { 100,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_chatlog_permission = { {

        [ 0 ] = false,
        [ 10 ] = false,
        [ 20 ] = true,
        [ 30 ] = true,
        [ 40 ] = true,
        [ 50 ] = true,
        [ 55 ] = false,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    etc_chatlog_max_lines = { 200,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_chatlog_default_lines = { 5,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_blacklist.lua settings

    etc_blacklist_oplevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_blacklist_masterlevel = { 100,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_cmdlog.lua settings

    etc_cmdlog_minlevel = { 100,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_cmdlog_command_tbl = { {

        [ "reg" ] = true,
        [ "delreg" ] = true,
        [ "disconnect" ] = true,
        [ "ban" ] = true,
        [ "unban" ] = true,
        [ "upgrade" ] = true,
        [ "accinfo" ] = true,
        [ "nickchange" ] = true,
        [ "reload" ] = true,
        [ "restart" ] = true,
        [ "shutdown" ] = true,
        [ "trafficmanager" ] = true,
    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_utf8( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_log_cleaner.lua settings

    etc_log_cleaner_minlevel = { 100,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_log_cleaner_activate_error = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_log_cleaner_activate_cmd = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_motd.lua settings

    etc_motd_activate = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_motd_permission = { {

        [ 0 ] = true,
        [ 10 ] = true,
        [ 20 ] = true,
        [ 30 ] = true,
        [ 40 ] = true,
        [ 50 ] = true,
        [ 55 ] = false,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    etc_motd_destination_main = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_motd_destination_pm = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_motd_motd = { "\n\n\tthis is the motd message\n\n",
        function( value )
            return types_utf8( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_offlineusers.lua settings

    etc_offlineusers_min_level_owner = { 100,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_offlineusers_permission = { {

        [ 0 ] = false,
        [ 10 ] = false,
        [ 20 ] = false,
        [ 30 ] = false,
        [ 40 ] = false,
        [ 50 ] = false,
        [ 55 ] = false,
        [ 60 ] = false,
        [ 70 ] = false,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    etc_offlineusers_max_offline_days_auto = { {

        [ 0 ] = 7,
        [ 10 ] = 90,
        [ 20 ] = 90,
        [ 30 ] = 90,
        [ 40 ] = 180,
        [ 50 ] = 180,
        [ 55 ] = 180,
        [ 60 ] = 360,
        [ 70 ] = 360,
        [ 80 ] = 999,
        [ 100 ] = 999,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    etc_offlineusers_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_offlineusers_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_offlineusers_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_offlineusers_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_usercommands.lua settings

    etc_usercommands_toplevelmenu = { "Luadch Commands",
        function( value )
            return types_utf8( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_userlogininfo.lua settings

    etc_userlogininfo_activate = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_userlogininfo_permission = { {

        [ 0 ] = false,
        [ 10 ] = true,
        [ 20 ] = true,
        [ 30 ] = true,
        [ 40 ] = true,
        [ 50 ] = true,
        [ 55 ] = false,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    etc_userlogininfo_show_hubversion = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// usr_nick_prefix.lua settings

    usr_nick_prefix_activate = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    usr_nick_prefix_prefix_table = { {

        [ 0 ] = "[UNREG]",
        [ 10 ] = "[GUEST]",
        [ 20 ] = "[REG]",
        [ 30 ] = "[VIP]",
        [ 40 ] = "[SVIP]",
        [ 50 ] = "[SERVER]",
        [ 55 ] = "[SBOT]",
        [ 60 ] = "[OPERATOR]",
        [ 70 ] = "[SUPERVISOR]",
        [ 80 ] = "[ADMIN]",
        [ 100 ] = "[HUBOWNER]",

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_utf8( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    usr_nick_prefix_permission = { {

        [ 0 ] = false,
        [ 10 ] = true,
        [ 20 ] = true,
        [ 30 ] = true,
        [ 40 ] = true,
        [ 50 ] = true,
        [ 55 ] = true,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// usr_desc_prefix.lua settings

    usr_desc_prefix_activate = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    usr_desc_prefix_prefix_table = { {

        [ 0 ] = "[ UNREG ] ",
        [ 10 ] = "[ GUEST ] ",
        [ 20 ] = "[ REG ] ",
        [ 30 ] = "[ VIP ] ",
        [ 40 ] = "[ SVIP ] ",
        [ 50 ] = "[ SERVER ] ",
        [ 55 ] = "[ SBOT ] ",
        [ 60 ] = "[ OPERATOR ] ",
        [ 70 ] = "[ SUPERVISOR ] ",
        [ 80 ] = "[ ADMIN ] ",
        [ 100 ] = "[ HUBOWNER ] ",

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_utf8( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    usr_desc_prefix_permission = { {

        [ 0 ] = false,
        [ 10 ] = true,
        [ 20 ] = true,
        [ 30 ] = true,
        [ 40 ] = true,
        [ 50 ] = true,
        [ 55 ] = true,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// usr_slots.lua settings

    min_slots = { {

        [ 0 ] = 2,
        [ 10 ] = 2,
        [ 20 ] = 2,
        [ 30 ] = 2,
        [ 40 ] = 2,
        [ 50 ] = 2,
        [ 55 ] = 0,
        [ 60 ] = 0,
        [ 70 ] = 0,
        [ 80 ] = 0,
        [ 100 ] = 0,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    max_slots = { {

        [ 0 ] = 20,
        [ 10 ] = 20,
        [ 20 ] = 20,
        [ 30 ] = 20,
        [ 40 ] = 20,
        [ 50 ] = 20,
        [ 55 ] = 20,
        [ 60 ] = 20,
        [ 70 ] = 20,
        [ 80 ] = 20,
        [ 100 ] = 20,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// usr_share.lua settings

    min_share = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 0,
        [ 70 ] = 0,
        [ 80 ] = 0,
        [ 100 ] = 0,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    max_share = { {

        [ 0 ] = 200,
        [ 10 ] = 200,
        [ 20 ] = 200,
        [ 30 ] = 200,
        [ 40 ] = 200,
        [ 50 ] = 200,
        [ 55 ] = 200,
        [ 60 ] = 200,
        [ 70 ] = 200,
        [ 80 ] = 200,
        [ 100 ] = 200,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// usr_hubs.lua settings

    max_hubs = { 20,
        function( value )
            return types_number( value, nil, true )
        end
    },

    max_user_hubs = { 20,
        function( value )
            return types_number( value, nil, true )
        end
    },

    max_reg_hubs = { 20,
        function( value )
            return types_number( value, nil, true )
        end
    },

    max_op_hubs = { 20,
        function( value )
            return types_number( value, nil, true )
        end
    },

    usr_hubs_godlevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    usr_hubs_block_time = { 15,
        function( value )
            return types_number( value, nil, true )
        end
    },

    usr_hubs_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    usr_hubs_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    usr_hubs_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    usr_hubs_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// usr_topic.lua settings

    cmd_topic_minlevel = { 100,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_topic_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_topic_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_topic_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_topic_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_trafficmanager.lua settings

    etc_trafficmanager_activate = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_trafficmanager_permission = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 40,
        [ 70 ] = 60,
        [ 80 ] = 70,
        [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    etc_trafficmanager_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_trafficmanager_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_trafficmanager_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_trafficmanager_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_trafficmanager_blocklevel_tbl = { {

        [ 0 ] = true,
        [ 10 ] = true,
        [ 20 ] = false,
        [ 30 ] = false,
        [ 40 ] = false,
        [ 50 ] = false,
        [ 55 ] = false,
        [ 60 ] = false,
        [ 70 ] = false,
        [ 80 ] = false,
        [ 100 ] = false,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    etc_trafficmanager_sharecheck = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_trafficmanager_oplevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_trafficmanager_block_ctm = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_trafficmanager_block_rcm = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_trafficmanager_block_sch = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_trafficmanager_login_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_trafficmanager_report_main = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_trafficmanager_report_pm = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_trafficmanager_send_loop = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_trafficmanager_loop_time = { 6,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_msgmanager.lua settings

    etc_msgmanager_activate = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_msgmanager_permission = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 40,
        [ 70 ] = 60,
        [ 80 ] = 70,
        [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    etc_msgmanager_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_msgmanager_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_msgmanager_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_msgmanager_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_msgmanager_permission_pm = { {

        [ 0 ] = true,
        [ 10 ] = true,
        [ 20 ] = true,
        [ 30 ] = true,
        [ 40 ] = true,
        [ 50 ] = true,
        [ 55 ] = true,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    etc_msgmanager_permission_main = { {

        [ 0 ] = true,
        [ 10 ] = true,
        [ 20 ] = true,
        [ 30 ] = true,
        [ 40 ] = true,
        [ 50 ] = true,
        [ 55 ] = true,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// usr_hide_share.lua settings

    usr_hide_share_activate = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    usr_hide_share_restrictions = { {

        [ 0 ] = true,
        [ 10 ] = true,
        [ 20 ] = false,
        [ 30 ] = false,
        [ 40 ] = false,
        [ 50 ] = false,
        [ 55 ] = false,
        [ 60 ] = false,
        [ 70 ] = false,
        [ 80 ] = false,
        [ 100 ] = false,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    usr_hide_share_permission = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 40,
        [ 70 ] = 60,
        [ 80 ] = 70,
        [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_gag.lua settings

    cmd_gag_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_gag_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_gag_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_gag_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    cmd_gag_permission = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 50,
        [ 70 ] = 60,
        [ 80 ] = 70,
        [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    cmd_gag_user_notifiy = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_records.lua settings

    etc_records_min_level = { 20,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_records_whereto_main = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_records_whereto_pm = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_records_reportlvl = { 20,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_records_sendMain = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_records_sendPM = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_records_delay = { 300,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_records_min_level_reset = { 100,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// bot_session_chat.lua settings

    bot_session_chat_minlevel = { 20,
        function( value )
            return types_number( value, nil, true )
        end
    },

    bot_session_chat_masterlevel = { 100,
        function( value )
            return types_number( value, nil, true )
        end
    },

    bot_session_chat_chatprefix = { "[SESSION-CHAT]",
        function( value )
            return types_utf8( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_hubstats.lua settings

    cmd_hubstats_oplevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_dhtblocker.lua settings

    etc_dhtblocker_activate = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_dhtblocker_block_level = { {

        [ 0 ] = true,
        [ 10 ] = true,
        [ 20 ] = true,
        [ 30 ] = true,
        [ 40 ] = true,
        [ 50 ] = true,
        [ 55 ] = true,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    etc_dhtblocker_block_time = { 15,
        function( value )
            return types_number( value, nil, true )
        end
    },

    etc_dhtblocker_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_dhtblocker_report_toopchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_dhtblocker_report_tohubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    etc_dhtblocker_report_level = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// etc_ccpmblocker.lua settings

    etc_ccpmblocker_block_level = { {

        [ 0 ] = true,
        [ 10 ] = true,
        [ 20 ] = false,
        [ 30 ] = false,
        [ 40 ] = false,
        [ 50 ] = false,
        [ 55 ] = false,
        [ 60 ] = false,
        [ 70 ] = false,
        [ 80 ] = false,
        [ 100 ] = false,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_redirect.lua settings

    cmd_redirect_activate = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_redirect_permission = { {

        [ 0 ] = 0,
        [ 10 ] = 0,
        [ 20 ] = 0,
        [ 30 ] = 0,
        [ 40 ] = 0,
        [ 50 ] = 0,
        [ 55 ] = 0,
        [ 60 ] = 50,
        [ 70 ] = 60,
        [ 80 ] = 70,
        [ 100 ] = 100,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_number( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    cmd_redirect_level = { {

        [ 0 ] = true,
        [ 10 ] = false,
        [ 20 ] = false,
        [ 30 ] = false,
        [ 40 ] = false,
        [ 50 ] = false,
        [ 55 ] = false,
        [ 60 ] = false,
        [ 70 ] = false,
        [ 80 ] = false,
        [ 100 ] = false,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    cmd_redirect_url = { "adc://addy:port",
        function( value )
            return types_utf8( value, nil, true )
        end
    },

    cmd_redirect_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_redirect_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_redirect_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    cmd_redirect_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_sslinfo.lua settings

    cmd_sslinfo_minlevel = { 10,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// cmd_myinf.lua settings

    cmd_myinf_permission = { {

        [ 0 ] = false,
        [ 10 ] = false,
        [ 20 ] = false,
        [ 30 ] = false,
        [ 40 ] = false,
        [ 50 ] = false,
        [ 55 ] = false,
        [ 60 ] = true,
        [ 70 ] = true,
        [ 80 ] = true,
        [ 100 ] = true,

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in pairs( value ) do
                    if not ( types_boolean( k, nil, true ) and types_number( i, nil, true ) ) then
                        return false
                    end
                end
            end
            return true
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// hub_runtime.lua settings

    hub_runtime_minlevel = { 100,
        function( value )
            return types_number( value, nil, true )
        end
    },

    hub_runtime_report = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    hub_runtime_report_opchat = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    hub_runtime_report_hubbot = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    hub_runtime_llevel = { 60,
        function( value )
            return types_number( value, nil, true )
        end
    },

    ---------------------------------------------------------------------------------------------------------------------------------
    --// user scripts (string array); scripts will be executed in this order!

    scripts = { {

        "hub_cmd_manager.lua",  -- must be the first script in the table!
        "etc_cmdlog.lua",  -- must be the second script in the table!
        "bot_opchat.lua", -- must be above all other scripts who wants to use the opchat import
        "etc_report.lua", -- must be above all other scripts who wants to use the report import / needs opchat
        "cmd_ban.lua", -- must be above all other scripts who wants to use the ban import / needs report

        "hub_inf_manager.lua",
        "hub_runtime.lua",
        "bot_regchat.lua",
        "bot_session_chat.lua",
        "bot_pm2ops.lua",
        "usr_slots.lua",
        "usr_share.lua",
        "usr_hubs.lua",
        "usr_nick_prefix.lua",
        "usr_desc_prefix.lua",
        "usr_hide_share.lua",
        "cmd_help.lua",
        "cmd_redirect.lua",
        "cmd_uptime.lua",
        "cmd_hubinfo.lua",
        "cmd_hubstats.lua",
        "cmd_myip.lua",
        "cmd_myinf.lua",
        "cmd_rules.lua",
        "cmd_userinfo.lua",
        "cmd_usersearch.lua",
        "cmd_slots.lua",
        "cmd_accinfo.lua",
        "cmd_setpass.lua",
        "cmd_nickchange.lua",
        "cmd_mass.lua",
        "cmd_talk.lua",
        "cmd_pm2offliners.lua",
        "cmd_topic.lua",
        "cmd_userlist.lua",
        "cmd_disconnect.lua",
        "cmd_reg.lua",
        "cmd_upgrade.lua",
        "cmd_delreg.lua",
        "cmd_errors.lua",
        "cmd_reload.lua",
        "cmd_restart.lua",
        "cmd_shutdown.lua",
        "cmd_ascii.lua",
        "cmd_gag.lua",
        "cmd_sslinfo.lua",
        "etc_hubcommands.lua",
        "etc_usercommands.lua",
        "etc_blacklist.lua",
        "etc_log_cleaner.lua",
        "etc_motd.lua",
        "etc_userlogininfo.lua",
        "etc_banner.lua",
        "etc_offlineusers.lua",
        "etc_chatlog.lua",
        "etc_msgmanager.lua",
        "etc_trafficmanager.lua",
        "etc_records.lua",
        "etc_dhtblocker.lua",
        "etc_ccpmblocker.lua",

        "hub_bot_cleaner.lua",
        "etc_unknown_command.lua",

    },
        function( value )
            if not types_table( value ) then
                return false
            else
                for i, k in ipairs( value ) do
                    if not types_utf8( k, nil, true ) then
                        return false
                    end
                end
            end
            return true
        end
    },
    script_path = { "././scripts/",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    ssl_params = { {

        mode = "server",  -- do not touch this
        key = "certs/serverkey.pem",  -- your ssl key
        certificate = "certs/servercert.pem",  -- your cert
        cafile = "certs/cacert.pem",  -- your ca file
        options = { "no_sslv2", "no_sslv3" },  -- do not touch this
        curve = "prime256v1",  -- do not touch this

        protocol = "tlsv1_2",
        ciphers = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256",  -- TLSv1.2 with AES128 + AES256

    }, function( ) return true end },
    scripts_cfg_profile = { "default",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    scripts_cfg_path = { "././scripts/cfg/",
        function( value )
            return types_utf8( value, nil, true )
        end
    },
    no_global_scripting = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },
    kill_wrong_ips = { false,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

    --// PING //--

    use_ping = { true,
        function( value )
            return types_boolean( value, nil, true )
        end
    },

}

checkcfg = function( )
    for key, value in pairs( _settings ) do
        local dst = _defaultsettings[ key ]
        if not ( dst and dst[ 2 ]( value ) ) then
            out_error( "cfg.lua: function 'checkcfg': corrupt cfg.tbl: invalid key/value: ", key, "/", value, "; using default cfg" )
            _settings = { }
            break
        end
    end
end

checklanguage = function( lang )
    --[[for i, k in pairs( lang ) do
        if not ( types_utf8( k, nil, true ) and types_utf8( i, nil, true ) ) then
            out_error( "cfg.lua: function 'checklanguage': error while loading hub language: invalid key/value: ", i, "/", k, "; using default" )
            return { }
        end
    end]]
    return lang
end
--[[
set = function( target, newvalue )
    local dst = _defaultsettings[ target ]
    if dst and dst[ 2 ]( newvalue ) then
        _settings[ target ] = newvalue
        local _, err = util_savetable( _settings, "settings", _cfgbackup .. "." .. os_date( "[%d.%m.%y.%H.%M.%S]" ) )
        _ = err and out_error( "cfg.lua: function 'set': error while backup hub settings: ", err )
        local _, err = util_savetable( _settings, "settings", _cfgfile )
        _ = err and out_error( "cfg.lua: function 'set': error while saving hub settings: ", err )
        return err
    else
        out_error( "cfg.lua: function 'set': invalid access to settings: invalid target/newvalue: ", target, "/", newvalue, "; using old value" )
        return "invalid target or newvalue"
    end
end
]]
get = function( target )
    if _settings[ target ] == nil then
        return _defaultsettings[ target ][ 1 ]
    end
    return _settings[ target ]
end

loadusers = function( )
    local users, err = util_loadtable( get "user_path" .. "user.tbl" )
    _ = err and out_error( "cfg.lua: function 'loadusers': error while loading users: ", err )
    return ( users or { } ), err
end

saveusers = function( regusers )
    --local _, err = util_savearray( regusers, get( "user_path" ) .. "user.tbl.BACKUP." .. os_date( "[%d.%m.%y.%H.%M.%S]" ) )
    --local _, err
    --_ = err and out_error( "cfg.lua: error while backup user db: ", err )
    local _, err = util_savearray( regusers, get( "user_path" ) .. "user.tbl" )
    _ = err and out_error( "cfg.lua: function 'saveusers': error while saving user db: ", err )
    if err then
        return false, err
    else
        return true
    end
end

loadlanguage = function( language, name )
    language = tostring( language or get "language" )    -- default language
    local path
    if not name then
        path = get "core_lang_path" .. language .. ".tbl"
    else
        path = get "scripts_lang_path" .. tostring( name ) .. ".lang." .. language
    end
    local ret, err = util_loadtable( path )
    _ = err and out_error( "cfg.lua: function 'loadlanguage': error while loading language: ", err )
    return checklanguage( ret or { } ), err
end

loadcfgprofile = function( profile, name )
    profile = tostring( profile or get "scripts_cfg_profile" )    -- default profile
    ret, err = util_loadtable( get "scripts_cfg_path" .. tostring( name ) .. ".cfg." .. profile )
    _ = err and out_error( "cfg.lua: function 'loadcfgprofile': error while loading cfg profile: ", err )
    return ret, err
end

registerevent = function( what, listener )
    assert( type( listener ) == "function" )
    _event[ what ] = _event[ what ] or { }
    local tbl = _event[ what ]
    _event[ what ][ #tbl + 1 ] = listener
end

reload = function( )
    local err
    _settings, err = util_loadtable( _cfgfile )
    _settings = _settings or { }
    _ = err and out_error( "cfg.lua: function 'reload': error while reloading hub settings: ", err, "; using default cfg" )
    checkcfg( )
    for i, func in ipairs( _event.reload ) do
        func( )
    end
    return _settings, err
end

init = function( )

    types_adcstr = types.get "adcstr"

    out = use "out"
    out_error = out.error
    local err
    _settings, err = util_loadtable( _cfgfile )
    _settings = _settings or { }
    _ = err and out_error( "cfg.lua: function 'init': error while loading hub settings: ", err, "; using default cfg" )
    checkcfg( )
end

----------------------------------// BEGIN //--

----------------------------------// PUBLIC INTERFACE //--

return {

    init = init,

    --set = set,
    get = get,
    reload = reload,
    loadusers = loadusers,
    saveusers = saveusers,
    loadlanguage = loadlanguage,
    registerevent = registerevent,
    loadcfgprofile = loadcfgprofile,

}

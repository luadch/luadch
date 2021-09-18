--[[

        etc_userlogininfo.lua by pulsar

        v0.18: by pulsar
            - using lastseen instead of lastlogout

        v0.17: by blastbeat:
            - attemp to make this script sane again

        v0.16: by blastbeat:
            - removed CCPM stuff

        v0.15:
            - changes in get_lastlogin() function

        v0.14:
            - added "TLS Mode" info
            - added "TLS Cipher" info
            - possibility to activate/deactivate the script  / requested by Sopor

        v0.13:
            - using new luadch date style

        v0.12:
            - improved get_lastseen() function

        v0.11:
            - added info about CCPM permission
            - added lastlogout info
            - code cleaning and new table lookups

        v0.10:
            - changed visual output style

        v0.09:
            - changed visual output style
            - code cleaning
            - table lookups
            - removed "msg_user_on", "msg_user_max", "msg_slots_min", "msg_slots_max"

        v0.08
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.07
            - small bugfix

        v0.06
            - added: Hubname + Version (Toggle on/off)
            - added: Registriert von, Registriert am
            - added: Users Online, Users Max.
            - added: Min. Slots, Max. Slots

        v0.05
            - added: Hubname + Version

        v0.04
            - added: Client Mode
            - added: Client SSL Check

        v0.03
            - added: Levelnummer
            - added: Client Version

        v0.02
            - added Multilanguage Support

        v0.01
            - send a basic userinfo on login
]]--

--// settings

local scriptname = "etc_userlogininfo"
local scriptversion = "0.18"

local scriptlang = cfg.get "language"
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local permission = cfg.get "etc_userlogininfo_permission"
local activate = cfg.get "etc_userlogininfo_activate"

local client_mode_a = lang.client_mode_a or "active"
local client_mode_p = lang.client_mode_p or "passive"
local client_ssl_n = lang.client_ssl_n or "no ( please activate it! )"
local client_ssl_y = lang.client_ssl_y or "yes"

local msg_years = lang.msg_years or " years, "
local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"

local msg_unknown = lang.msg_unknown or "<unknown>"
local msg_info = lang.msg_info or [[


=== USER LOGIN INFO ==============================

        Your Nick:	%s
        Your IP:	%s
        Your Level:	%s  [ %s ]

        Client Version:	%s
        Client Mode:	%s

        Regged by:	%s
        Regged on:	%s

        Last visit:  %s

        Client SSL:	%s
        TLS Mode:	%s
        TLS Cipher:	%s

============================== USER LOGIN INFO ===
   ]]

local get_lastseen = function( profile )
    local lastseen
    local ll = profile.lastseen -- or profile.lastconnect
    if ll then
        local sec, y, d, h, m, s = util.difftime( util.date(), ll )
        lastseen = y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    else
        lastseen = msg_unknown
    end
    return lastseen
end

hub.setlistener( "onLogin", { },
    function( user )
        local user_level = user:level( )
        if ( activate and user:isregged( ) and permission[ user_level ] ) then
            local user_firstnick = user:firstnick( )
            local user_ip = user:ip( )
            local user_version = user:version( )
            local level_name = cfg.get( "levels" )[ user_level ] or "Unreg"
            local clientv = hub.escapefrom( user_version ) or "<unknown>"
            local mode = ( ( user:hasfeature( "TCP4" ) or user:hasfeature( "TCP6" ) ) and client_mode_a ) or client_mode_p
            local user_ssl = ( user:ssl( ) and client_ssl_y ) or client_ssl_n
            local profile = user:profile( )
            local reg_by = profile.by or "Luadch"
            local reg_date = profile.date or "<UNKNOWN>"
            local protocol, cipher = "", ""
            local sslinfo = user:sslinfo( )
            if sslinfo then
                protocol = sslinfo.protocol
                cipher = sslinfo.cipher
            end
            local msg = utf.format(
                msg_info,
                user_firstnick,
                user_ip,
                user_level, level_name,
                clientv,
                mode,
                reg_by,
                reg_date,
                get_lastseen( profile ),
                user_ssl,
                protocol,
                cipher
            )
            user:reply( msg, hub.getbot( ) )
        end
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

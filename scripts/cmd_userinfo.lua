--[[

    cmd_userinfo.lua by blastbeat

        - this script adds a command "userinfo" get infos about an user
        - usage: [+!#]userinfo sid|nick|cid <sid>|<nick>|<cid>
        - no arguments means you get info about yourself

        v0.22: by pulsar
            - fix typo

        v0.21: by pulsar
            - changed msg_god / thx Sopor

        v0.20: by pulsar
            - added levelname
            - using tabs for cleaner look
            - removed table lookups

        v0.19: by pulsar
            - fix typo / thx Sopor
            - removed the "CID" parts

        v0.18: by pulsar
            - changes in get_lastconnect() function

        v0.17: by pulsar
            - removed "cmd_userinfo_minlevel" import
                - using util.getlowestlevel( tbl ) instead of "cmd_userinfo_minlevel"

        v0.16: by pulsar
            - using new luadch date style

        v0.15: by pulsar
            - add users KP

        v0.14: by pulsar
            - improved get_lastconnect() function

        v0.13: by pulsar
            - add users uptime
            - fix problem with utf.match

        v0.12: by pulsar
            - removed function: convertBytes()
                - now using: util.formatbytes()

        v0.11: by pulsar
            - fix typo in language files
            - convert client traffic to the right unit
            - convert user share to the right unit
            - caching some new table lookups
            - code cleaning

        v0.10: by pulsar
            - fix minlevel output to help and ucmd

        v0.09: by pulsar
            - changed visual output style

        v0.08: by pulsar
            - changed rightclick style

        v0.07: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.06: by blastbeat
            - some bugfixes; added stats

        v0.05: by blastbeat
            - updated script api
            - regged hubcommand

        v0.04: by blastbeat
            - added SU

        v0.03: by blastbeat
            - added language files, ucmd

        v0.02: by blastbeat
            - added share, email, slots, hubs, version in info

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_userinfo"
local scriptversion = "0.22"

local cmd = "userinfo"

--// imports
local help, ucmd, hubcmd
local scriptlang = cfg.get( "language" )
local permission = cfg.get( "cmd_userinfo_permission" )

--// msgs
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or  "Usage: [+!#]userinfo sid|nick <sid>|<nick>"
local msg_off = lang.msg_off or "User not found."
local msg_god = lang.msg_god or "You are not allowed to check the userinfo from this user"
local msg_unknown = lang.msg_unknown or "<UNKNOWN>"
local msg_years = lang.msg_years or " years, "
local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"
local msg_userinfo = lang.msg_userinfo or [[


=== USERINFO =============================================================================

Nick: %s
1. Nick: %s
Desc:  %s
Share:  %s
Email:  %s
Slots:  %s
Hubs:  %s
Version:  %s
SID:  %s
CID: %s
KP: %s
Hash:  %s
IP: %s
Port: %s
Srvport: %s
SSL: %s
SU: %s
Bot: %s
Rank: %s
Level: %s  [ %s ]
Regged: %s

Sent:        %s
Received: %s

Uptime: %s

============================================================================= USERINFO ===

  ]]

local help_title = lang.help_title or "userinfo"
local help_usage = lang.help_usage or "[+!#]userinfo sid|nick <sid>|<nick>"
local help_desc = lang.help_desc or "Sends info about a user by SID or NICK; no argument -> about yourself"

local ucmd_menu_ct1 = lang.ucmd_menu_ct1 or { "About You", "show Userinfo" }
local ucmd_menu_ct2 = lang.ucmd_menu_ct2 or { "Show", "Userinfo" }


----------
--[CODE]--
----------

local minlevel = util.getlowestlevel( permission )

local get_lastconnect = function( user )
    if not user:isregged( ) then
        return msg_unknown
    end
    local lastconnect
    local profile = user:profile()
    local lc = profile.lastconnect
    if lc then
        local lc_str = tostring( lc )
        if #lc_str == 14 then
            local sec, y, d, h, m, s = util.difftime( util.date(), lc )
            lastconnect = y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        else
            local d, h, m, s = util.formatseconds( os.difftime( os.time(), lc ) )
            lastconnect = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        end
    else
        lastconnect = msg_unknown
    end
    return lastconnect
end

local onbmsg = function( user, command, parameters )
    local level = user:level()
    local me = utf.match( parameters, "^(%S+)" )
    local by, id = utf.match( parameters, "^(%S+) (.*)" )
    local target
    if ( me == nil ) then
        target = user
    else
        if not ( ( by == "sid" or by == "nick" ) and id ) then
            user:reply( msg_usage, hub.getbot() )
            return PROCESSED
        else
            target = ( by == "nick" and hub.isnickonline( id ) ) or ( by == "sid" and hub.issidonline( id ) )
        end
    end
    if not target then
        user:reply( msg_off, hub.getbot() )
        return PROCESSED
    end
    if not ( user == target ) and ( ( permission[ level ] or 0 ) < target:level() ) then
        user:reply( msg_god, hub.getbot() )
        return PROCESSED
    end
    local rstat, sstat = user:client():getstats()
    local hn, hr, ho = target.hubs()
    local inf = target:inf()
    local target_kp = inf:getnp "KP" or ""
    local level_name = cfg.get( "levels" )[ target:level() ] or "Unreg"
    local userinfo = utf.format(
        msg_userinfo,
        "\t\t" .. hub.escapefrom( target:nick() ),
        "\t\t" .. hub.escapefrom( target:firstnick() ),
        "\t\t" .. hub.escapefrom( target.description() or msg_unknown ),
        "\t\t" .. util.formatbytes( tonumber( target.share() ) ) or msg_unknown,
        "\t\t" .. hub.escapefrom( target.email() or msg_unknown ),
        "\t\t" .. target.slots( ) or msg_unknown,
        "\t\t" .. ( hn or msg_unknown ) .. "/" .. ( hr or msg_unknown ) .. "/" .. ( ho or msg_unknown ),
        "\t\t" .. hub.escapefrom( target.version() or msg_unknown ),
        "\t\t" .. target:sid(),
        "\t\t" .. target:cid(),
        "\t\t" .. target_kp,
        "\t\t" .. target:hash(),
        "\t\t" .. target:ip(),
        "\t\t" .. target:clientport(),
        "\t\t" .. target:serverport(),
        "\t\t" .. tostring( target:ssl() ),
        "\t\t" .. tostring( target:features() ),
        "\t\t" .. tostring( target:isbot() ),
        "\t\t" .. target:rank(),
        "\t\t" .. target:level(), level_name,
        "\t\t" .. tostring( user:isregged() ),
        "\t" .. tostring( util.formatbytes( rstat ) ),
        "\t" .. tostring( util.formatbytes( sstat ) ),
        "\t\t" .. get_lastconnect( target )
    )
    user:reply( userinfo, hub.getbot(), hub.getbot() )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function( )
        help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, 0 )    -- reg help
        end
        ucmd = hub.import( "etc_usercommands" )    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu_ct1, cmd, {}, { "CT1" }, 0 )
            ucmd.add( ucmd_menu_ct2, cmd, { "sid", "%[userSID]" }, { "CT2" }, minlevel )
        end
        hubcmd = hub.import( "etc_hubcommands" )    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

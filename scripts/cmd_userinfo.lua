--[[

    cmd_userinfo.lua by blastbeat

        - this script adds a command "userinfo" get infos about an user
        - usage: [+!#]userinfo sid|nick|cid <sid>|<nick>|<cid>
        - no arguments means you get info about yourself
        
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
local scriptversion = "0.17"

local cmd = "userinfo"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local utf_match = utf.match
local hub_import = hub.import
local hub_debug = hub.debug
local hub_getbot = hub.getbot
local hub_escapefrom = hub.escapefrom
local hub_issidonline = hub.issidonline
local hub_iscidonline = hub.iscidonline
local hub_isnickonline = hub.isnickonline
local string_format = string.format
local util_formatbytes = util.formatbytes
local os_time = os.time
local util_formatseconds = util.formatseconds
local os_difftime = os.difftime
local util_date = util.date
local util_difftime = util.difftime
local util_getlowestlevel = util.getlowestlevel

--// imports
local help, ucmd, hubcmd
local scriptlang = cfg_get( "language" )
local permission = cfg_get( "cmd_userinfo_permission" )

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or  "Usage: [+!#]userinfo sid|nick|cid <sid>|<nick>|<cid>"
local msg_off = lang.msg_off or "User not found."
local msg_god = lang.msg_god or "You cannot investigate gods."
local msg_unknown = lang.msg_unknown or "<unknown>"
local msg_years = lang.msg_years or " years, "
local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"
local msg_userinfo = lang.msg_userinfo or [[

    
=== USERINFO ==============================================================

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
Level: %s
Regged: %s

Sended: %s
Received: %s

Uptime: %s

============================================================== USERINFO ===

  ]]

local help_title = lang.help_title or "userinfo"
local help_usage = lang.help_usage or "[+!#]userinfo sid|nick|cid <sid>|<nick>|<cid>"
local help_desc = lang.help_desc or "get info about an user by sid or nick or cid; no arguments -> about yourself"

local ucmd_menu_ct1 = lang.ucmd_menu_ct1 or { "About You", "show Userinfo" }
local ucmd_menu_ct2 = lang.ucmd_menu_ct2 or { "Show", "Userinfo" }


----------
--[CODE]--
----------

local minlevel = util_getlowestlevel( permission )

local get_lastconnect = function( user )
    local lastconnect
    local profile = user:profile()
    local lc = profile.lastconnect
    local lc_str = tostring( lc )
    if not lc then
        lastconnect = msg_unknown
    else
        if #lc_str == 14 then
            local sec, y, d, h, m, s = util_difftime( util_date(), lc )
            lastconnect = y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        else
            local d, h, m, s = util_formatseconds( os_difftime( os_time(), lc ) )
            lastconnect = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        end
    end
    return lastconnect
end

local onbmsg = function( user, command, parameters )
    local level = user:level()
    --[[
    if level < minlevel then
        user:reply( msg_denied, hub_getbot() )
        return PROCESSED
    end
    ]]
    local me = utf_match( parameters, "^(%S+)" )
    local by, id = utf_match( parameters, "^(%S+) (.*)" )
    local target
    if ( me == nil ) then
        target = user
    else
        if not ( ( by == "sid" or by == "nick" or by == "cid" ) and id ) then
            user:reply( msg_usage, hub_getbot() )
            return PROCESSED
        else
            target = (
            by == "nick" and hub_isnickonline( id ) ) or
            ( by == "sid" and hub_issidonline( id ) ) or
            ( by == "cid" and hub_iscidonline( id ) )
        end
    end
    if not target then
        user:reply( msg_off, hub_getbot() )
        return PROCESSED
    end
    if not ( user == target ) and ( ( permission[ level ] or 0 ) < target:level() ) then
        user:reply( msg_god, hub_getbot() )
        return PROCESSED
    end
    local rstat, sstat = user:client():getstats()
    local hn, hr, ho = target.hubs()
    local inf = target:inf()
    local target_kp = inf:getnp "KP" or ""
    local userinfo = utf.format(
        msg_userinfo,
        hub_escapefrom( target:nick() ),
        hub_escapefrom( target:firstnick() ),
        hub_escapefrom( target.description() or msg_unknown ),
        util_formatbytes( tonumber( target.share() ) ) or msg_unknown,
        hub_escapefrom( target.email() or msg_unknown ),
        target.slots( ) or msg_unknown,
        ( hn or msg_unknown ) .. "/" .. ( hr or msg_unknown ) .. "/" .. ( ho or msg_unknown ),
        hub_escapefrom( target.version() or msg_unknown ),
        target:sid(),
        target:cid(),
        target_kp,
        target:hash(),
        target:ip(),
        target:clientport(),
        target:serverport(),
        tostring( target:ssl() ),
        tostring( target:features() ),
        tostring( target:isbot() ),
        target:rank(),
        target:level(),
        tostring( user:isregged() ),
        tostring( util_formatbytes( rstat ) ),
        tostring( util_formatbytes( sstat ) ),
        get_lastconnect( target )
    )
    user:reply( userinfo, hub_getbot(), hub_getbot() )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function( )
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, 0 )    -- reg help
        end
        ucmd = hub_import( "etc_usercommands" )    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu_ct1, cmd, {}, { "CT1" }, 0 )
            ucmd.add( ucmd_menu_ct2, cmd, { "sid", "%[userSID]" }, { "CT2" }, minlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
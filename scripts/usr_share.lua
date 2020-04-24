--[[

    usr_share.lua by blastbeat

        - this script checks the share size of an user

        v0.10: by pulsar
            - added "usr_share_redirect"
                - use redirect instead of disconnect

        v0.09: by pulsar
            - added "etc_trafficmanager_check_minshare"
                - block user instead of disconnect if usershare < minshare

        v0.08: by pulsar
            - improved user:kill()

        v0.07: by pulsar
            - using min/max share tables to check share separate for each level

        v0.06: by pulsar
            - fix share check  / thx Kaas
            - add table lookups
            - new output msg

        v0.05: by pulsar
            - changed calc of share

        v0.04: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.03: by blastbeat
            - updated script api

        v0.02: by blastbeat
            - added language files

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "usr_share"
local scriptversion = "0.10"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_getbot = hub.getbot()
local hub_debug = hub.debug
local hub_escapeto = hub.escapeto
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local utf_format = utf.format
local util_formatbytes = util.formatbytes

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )
local min_share = cfg_get( "min_share" )
local max_share = cfg_get( "max_share" )
local minsharecheck = cfg_get( "etc_trafficmanager_check_minshare" )
local trafficmanager_activate = cfg_get( "etc_trafficmanager_activate" )
local usr_share_redirect = cfg_get( "usr_share_redirect" )
local redirect_url = cfg_get( "cmd_redirect_url" )

--// msgs
local msg_sharelimits = lang.msg_minmax or "Hub min share: %s  |  Hub max share: %s  |  Your share: %s"
local msg_redirect = lang.msg_redirect or "You got redirected because: "


----------
--[CODE]--
----------

local check = function( user )
    local user_level = user:level()
    local user_share = user:share()
    local min = min_share[ user_level ] * 1024 * 1024 * 1024
    local max = max_share[ user_level ] * 1024 * 1024 * 1024 * 1024
    if user_share > max then
        if usr_share_redirect then
            local msg_out = hub_escapeto( utf_format( msg_sharelimits, util_formatbytes( min ), util_formatbytes( max ), util_formatbytes( user_share ) ) )
            local msg_redirect = hub_escapeto( msg_redirect )
            user:redirect( redirect_url, msg_redirect .. msg_out )
            return PROCESSED
        else
            local msg_out = hub_escapeto( utf_format( msg_sharelimits, util_formatbytes( min ), util_formatbytes( max ), util_formatbytes( user_share ) ) )
            user:kill( "ISTA 120 " .. msg_out .. "\n", "TL300" )
            return PROCESSED
        end
    end
    if user_share < min then
        if usr_share_redirect then
            local msg_out = hub_escapeto( utf_format( msg_sharelimits, util_formatbytes( min ), util_formatbytes( max ), util_formatbytes( user_share ) ) )
            local msg_redirect = hub_escapeto( msg_redirect )
            user:redirect( redirect_url, msg_redirect .. msg_out )
            return PROCESSED
        else
            if not ( trafficmanager_activate and minsharecheck ) then
                local msg_out = hub_escapeto( utf_format( msg_sharelimits, util_formatbytes( min ), util_formatbytes( max ), util_formatbytes( user_share ) ) )
                user:kill( "ISTA 120 " .. msg_out .. "\n", "TL300" )
                return PROCESSED
            end
        end
    end
    return nil
end

hub.setlistener( "onInf", {},
    function( user, cmd )
        if cmd:getnp "SS" then
            return check( user )
        end
        return nil
    end
)

hub.setlistener( "onConnect", {},
    function( user )
        return check( user )
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
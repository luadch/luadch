--[[

    usr_share.lua by blastbeat

        - this script checks the share size of an user

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
local scriptversion = "0.07"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_debug = hub.debug
local hub_escapeto = hub.escapeto
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local utf_format = utf.format
local util_formatbytes = util.formatbytes

--// imports
local min_share = cfg_get( "min_share" )
local max_share = cfg_get( "max_share" )
local scriptlang = cfg_get( "language" )

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )
local msg_sharelimits = lang.msg_minmax or "Hub min share: %s  |  Hub max share: %s  |  Your share: %s"


----------
--[CODE]--
----------

local check = function( user )
    local user_level = user:level()
    local user_share = user:share()
    local min = min_share[ user_level ] * 1024 * 1024 * 1024
    local max = max_share[ user_level ] * 1024 * 1024 * 1024 * 1024
    if ( user_share < min ) or ( user_share > max ) then
        local msg_out = hub_escapeto( utf_format( msg_sharelimits, util_formatbytes( min ), util_formatbytes( max ), util_formatbytes( user_share ) ) )
        user:kill( "ISTA 120 " .. msg_out .. "\n" )
        return PROCESSED
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
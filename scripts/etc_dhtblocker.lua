--[[

    etc_dhtblocker.lua by pulsar

        v0.5:
            - check if opchat is activated
        
        v0.4:
            - export scriptsettings to "cfg/cfg.tbl"
        
        v0.3:
            - small typo fix
            - small permission fix
                - add check table to choose which levels should be checked

        v0.2:
            - using ban instead of disconnect
                - prevents possible report message spams
            - check onConnect
            - possibility to send report as feed to opchat
            - caching table lookups
            - add multilanguage support

        v0.1:
            - check if user has active DHT function

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_dhtblocker"
local scriptversion = "0.5"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_import = hub.import
local hub_debug = hub.debug
local hub_getusers = hub.getusers
local hub_getbot = hub.getbot()
local hub_broadcast = hub.broadcast
local hub_escapeto = hub.escapeto
local util_loadtable = util.loadtable
local util_savearray = util.savearray
local os_date = os.date
local os_time = os.time
local utf_format = utf.format

--// imports
local opchat = hub_import( "bot_opchat" )
local opchat_activate = cfg_get( "bot_opchat_activate" )
local bans_path = "scripts/data/cmd_ban_bans.tbl"
local bans = util_loadtable( bans_path ) or {}
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local activate = cfg_get( "etc_dhtblocker_activate" )
local block_level = cfg_get( "etc_dhtblocker_block_level" )
local block_time = cfg_get( "etc_dhtblocker_block_time" )
local report = cfg_get( "etc_dhtblocker_report" )
local report_tohubbot = cfg_get( "etc_dhtblocker_report_tohubbot" )
local report_toopchat = cfg_get( "etc_dhtblocker_report_toopchat" )
local report_level = cfg_get( "etc_dhtblocker_report_level" )

--// msgs
local block_msg = lang.block_msg or "You were banned for %s minutes because of active DHT function in your client. deactivate this function, and try again after bantime."
local report_msg = lang.report_msg or "%s were banned for %s minutes because of active DHT function."


----------
--[CODE]--
----------

local addban = function( target, reason )
    local bantime = block_time * 60
    bans[ #bans + 1 ] = {
        nick = target:nick() or "nick",
        cid = target:cid() or "cid",
        hash = target:hash() or "hash",
        ip = target:ip() or "ip",
        time = bantime,
        start = os_time( os_date( "*t" ) ),
        reason = reason,
        by_nick = scriptname,
        by_level = 100
    }
    util_savearray( bans, bans_path )
end

local send_report = function( nick )
    if report then
        local msg_out = utf_format( report_msg, nick, block_time )
        if report_tohubbot then
            for sid, user in pairs( hub_getusers() ) do
                local user_level = user:level()
                if user_level >= report_level then
                    user:reply( msg_out, hub_getbot, hub_getbot )
                end
            end
        end
        if report_toopchat then
            if opchat_activate then
                opchat.feed( msg_out )
            end
        end
    end
end

local check_dht = function( user )
    local dht1 = user:supports( "DHT0" )
    local dht2 = user:supports( "ADDHT0" )
    local user_nick = user:nick()
    local user_level = user:level()
    if dht1 or dht2 then
        if block_level[ user_level ] then
            local msg_out = utf_format( block_msg, block_time )
            addban( user, msg_out )
            user:reply( msg_out, hub_getbot, hub_getbot )
            user:kill( "ISTA 230 " .. hub_escapeto( msg_out ) .. "\n" )
            send_report( user_nick )
            hub.restartscripts()
            hub.reloadusers()
            return PROCESSED
        end
    end
end

if activate then
    hub.setlistener( "onInf", {},
        function( user, cmd )
            if cmd:getnp "NI" then
                check_dht( user )
            end
            return nil
        end
    )
    hub.setlistener( "onConnect", {},
        function( user )
            local isbanned, user_nick = false, user:nick()
            for k, v in ipairs( bans ) do
                if v[ "nick" ] == user_nick then isbanned = true break end
            end
            if not isbanned then check_dht( user ) end
            return nil
        end
    )
    hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
end
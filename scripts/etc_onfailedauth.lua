--[[

    etc_onfailedauth.lua by pulsar

        - this script sends a report if a user failed Auth

        v0.3:
            - added "cid" to listener "onFailedAuth"

        v0.2:
            - changed visuals

        v0.1:
            - first checkout

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_onfailedauth"
local scriptversion = "0.3"

--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local report = hub.import( "etc_report" )
local report_activate = cfg.get( "etc_onfailedauth_report" )
local report_hubbot = cfg.get( "etc_onfailedauth_report_hubbot" )
local report_opchat = cfg.get( "etc_onfailedauth_report_opchat" )
local report_llevel = cfg.get( "etc_onfailedauth_llevel" )

--// msgs
local report_msg = lang.report_msg or "[ FAILED AUTHENTICATION ]--> User:  %s  |  IP:  %s  | CID:  %s  |  Reason:  %s"


----------
--[CODE]--
----------

hub.setlistener( "onFailedAuth", {},
    function( nick, ip, cid, reason )
        local msg = utf.format( report_msg, nick, ip, cid, reason )
        report.send( report_activate, report_hubbot, report_opchat, report_llevel, msg )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

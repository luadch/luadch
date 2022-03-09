--[[

    usr_nick_length.lua by blastbeat

        - this script checks for proper nicknames on connect

]]--


local scriptname = "usr_nick_length.lua"
local scriptversion = "0.01"

cfg.get( "cmd_ban_report_opchat" )

-- add prefix to connecting user
hub.setlistener( "onConnect", { },
    function( user )
        local len = #user:nick() -- todo: doesn't consider utf8 codepoints
        if ( cfg.get "min_nickname_length" <= len ) and ( len <= cfg.get " max_nickname_length" ) then
            return nil
        end
        --remember: never fire listenter X inside listener X; will cause infinite loop
        scripts.firelistener( "onFailedAuth", user:nick( ), user:ip( ), user:cid( ), "Invalid nick length: " .. len ) -- todo: i18n
        user:kill( "ISTA 221 " .. hub.escapeto( "Invalid nick length." ) .. "\n", "TL300" )
        return PROCESSED
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

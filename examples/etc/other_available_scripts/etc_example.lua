--[[

        etc_example.lua v0.03 by blastbeat
 
]]--

local scriptname = "etc_example"
local scriptversion = "0.03"

local check_failed = function( user, rank )
    if not user:isregged( ) or user:rank( ) < rank then        
        return true            
    end
    return false
end

hub.setlistener( "onLogin", { },
    function( user )
        --if user:supports( "UCMD" ) or user:supports( "UCM0" ) then
            if cfg.get( "nick_change" ) then
                user:send( "ICMD Nick\\sChange\\\\here TTBMSG\\s%[mySID]\\s+nick\\\\s%[line:Nick]\\n CT1\n" )    --// send usercommand
            end
            if not check_failed( user, cfg.get "admin_rank" ) then 
                user:send( "ICMD Reg\\suser TTBMSG\\s%[mySID]\\s+reg\\\\s%[userCID]\\\\s%[line:Password]\\\\s%[line:Level]\\n CT2\n" )                
            end
        --end
        return nil
    end

)

hub.setlistener( "onBroadcast", { },                                 --// chatarrival..
    function( user, adccmd, txt )
        local adc_msg = adccmd:pos( 3 )                            --// text, adc formatted
        local msg = hub.escapefrom( adc_msg )                        --// text, normal formatted
        --hub:debug( "Escaped ADC msg: ", msg )                        --// debugs to hub cl..
        --hub:debug( "Normal string: ", hub:escapeFrom( msg ) )    
        return nil    
    end
)

hub.setlistener( "onBroadcast", { },                                     
    function( user, adccmd, txt )
        local msg = hub.escapefrom( adccmd:pos( 3 ) ) or ""                
        local command, parameters = utf.match( msg, "^[+!#](%a+) ?(.*)" )
        if command == "test" then
            user:reply( "Test ok.", hub.getbot( ) )
            return PROCESSED
        elseif command == "regcid" then
            if check_failed( user, cfg.get "op_rank" ) then user:reply( "You are not allowed to use this command.", hub.getbot( ) ) return PROCESSED end                
            local cid, password, rank = utf.match( parameters, "^(%S+) (%S+) (%d+)" )
            rank = tonumber( rank )
            if not ( cid and password and rank ) then
                user:reply( "Usage: +regcid <cid> <password> <rank>", hub.getbot( ) )
                return PROCESSED
            end
            if user:rank( ) < rank then
                user:reply( "Rank must be lower than " .. rank .. ".", hub.getbot( ) )
                return PROCESSED
            end        
            local bol, err = hub.reguser{ cid = cid, hash = "TIGR", password = password, rank = rank }
            user:reply( err or "regged", hub.getbot( ) )
            return PROCESSED
        end
        return nil            
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )
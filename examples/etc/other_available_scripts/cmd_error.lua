--// quick .. //--

local onbmsg
local report_send

local cmd = "error"

onbmsg = function( )
    a = b + c    -- produce error
end

hub.setlistener( "onError", { },    -- when this function produces any error, it wont be reported to avoid endless loops
    function( msg )
        --a = b + c    -- wont reported
        report_send( msg, 100, 100, hub.getbot( ), hub.getbot( ) )    -- send any error to hubowner
    end
)

hub.setlistener( "onStart", { },
    function( )
        local report = hub.import "etc_report"
        local hubcmd = hub.import "etc_hubcommands"
        assert( report and hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        report_send = report.send
        return nil
    end
)

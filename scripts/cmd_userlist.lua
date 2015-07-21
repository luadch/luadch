--[[

    cmd_userlist.lua by blastbeat

        - this script shows all regged users sorted by level
        - usage: [+!#]userlist [bydate]

        v0.08: by pulsar
            - fix permission level in help function  / thx Kaas
        
        v0.07: by blastbeat
            - added "bydate"; sorts userlist by registration date

        v0.06: by pulsar
            - changed visual output style
            - code cleaning
            - table lookups
        
        v0.05: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"
            
        v0.04: by Motnahp
            - bugfix with level read as string in user.tbl
            
        v0.03: by Motnahp
            - removed nick and cid
            - sorted by level
            
        v0.02: by Motnahp
            - regged hubcommand
        
        v0.01: by blastbeat

]]--

--// settings begin //--

local scriptname = "cmd_userlist"
local scriptversion = "0.08"

local minlevel = cfg.get "cmd_userlist_minlevel"
local cmd = "userlist"

local scriptlang = cfg.get "language"
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_userlist = lang.msg_userlist or "Userlist:"
local msg_useramount = lang.msg_useramount or "User amount in the levels:\n"

local help_title = lang.help_title or "userlist"
local help_usage = lang.help_usage or "[+!#]userlist [bydate]"
local help_desc = lang.help_desc or "get list of regged users"

local ucmd_menu = lang.ucmd_menu or { "Userlist" }
local ucmd_menu_bydate = lang.ucmd_menu_bydate or { "Userlist by date" }

--// settings end //--

--// functions
local hubcmd
local bylevel
local byregdate

--// table lookups
local hub_getbot = hub.getbot
local hub_getregusers = hub.getregusers
local utf_match = utf.match
local table_concat = table.concat
local table_sort = table.sort


local onbmsg = function( user, command, parameter )
    local level = user:level( )
    if level < minlevel then
        user:reply( msg_denied, hub_getbot( ) )
        return PROCESSED
    end
    local regusers, reggednicks, reggedcids = hub_getregusers( )
    local tmp
    if parameter == "bydate" then
        tmp = byregdate( regusers )
    else
        tmp = bylevel( regusers ) 					   
	end
    user:reply( "\n\n" .. msg_userlist .. "\n\n" .. table_concat( tmp, "\n" ) .. "\n", hub_getbot( ), hub_getbot( ) )
    return PROCESSED
end

hub.setlistener( "onStart", { },
    function( )
        local help = hub.import "cmd_help"
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )    -- reg help
        end

        local ucmd = hub.import "etc_usercommands"    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_bydate, cmd, { "bydate" }, { "CT1" }, minlevel )
        end
        hubcmd = hub.import "etc_hubcommands"    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

byregdate = function( regusers )
    local i, list = 1, { }
    for _, usertbl in ipairs( regusers ) do
        if ( usertbl.is_bot ~= 1 ) and usertbl.nick then
            local date = usertbl.date or "00.00.0000"
            local dd, mm, yyyy = date:sub( 1, 2 ), date:sub( 4, 5 ), date:sub( 7, 10 )
            list[ #list + 1 ] =  yyyy .. "-" .. mm .. "-" .. dd .. "\t" ..usertbl.nick
        end
    end
    table_sort( list )
    return list 
end

bylevel = function ( regusers ) 
    local tmp = { } 
    local levels = { }
    local levelnames = { }
    local tmp2 = { }

    -- get number and name of levels
    for x = 0, 1000, 1 do
        if cfg.get( "levels" )[ x ] then
            levels[ #levels + 1 ] = x 
            levelnames[ #levelnames+1 ] = ( tostring( cfg.get( "levels" )[ x ] ) )
        end
    end
    -- get users sorted by level
    for i, user in ipairs( regusers ) do
        if not user.is_bot then
            if tmp2[ tonumber( user.level ) ] then
                tmp2[ tonumber( user.level ) ][ #tmp2[ tonumber( user.level ) ] + 1 ] = user.nick
            else
                tmp2[ tonumber( user.level ) ] = { } 
                tmp2[ tonumber( user.level ) ][ #tmp2[ tonumber( user.level ) ] + 1 ] = user.nick
            end
        end
    end
    -- add empty fields for unused levels, sort entries
    for x = 1, #levelnames, 1 do
        if not tmp2[ levels[ x ] ] then
            tmp2[ levels[ x ] ] = { }
        end    
        table_sort( tmp2[ levels[ x ] ] )
    end
    -- build tbl for output
    for x = 1, #levelnames, 1 do
        tmp[ #tmp + 1 ] = " "
        tmp[ #tmp + 1 ] = "================================="
        tmp[ #tmp + 1 ] = levelnames[ x ] .. "   |   Level: " .. levels[ x ] .. "\n"
        
        for y = 1, #tmp2[ levels[ x ] ], 1 do
            tmp[ #tmp + 1 ] = "   " .. tmp2[ levels[ x ] ][ y ]
        end
    end
    tmp[ #tmp + 1 ] = "\n======================="
    tmp[ #tmp + 1 ] = msg_useramount
    for x = 1, #levelnames, 1 do
        tmp[ #tmp + 1 ] = levelnames[ x ] .. ": " .. #tmp2[ levels[ x ] ]
    end
    tmp[ #tmp + 1 ] = "=======================\n"
    
	return tmp
end

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
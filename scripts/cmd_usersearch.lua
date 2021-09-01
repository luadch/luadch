--[[

    cmd_usersearch.lua by Night (originally name: cmd_listreg)

        usage: [+!#]usersearch <searchstring>

        v1.3: by pulsar
            - removed table lookups
            - fix #53
                - show userlist in alphabetical order sorted by firstnick

        v1.2: by HypoManiac
            - Only shows nick for users with same or higher level.

        v1.1: by blastbeat
            - password only revealed for lower level users  / thx Sopor

        v1.0: by pulsar
            - escape magic chars to prevent errors in "string.find"  / thx Sopor

        v0.9: by pulsar
            - fix problem with "profile.is_online"

        v0.8: by pulsar
            - using new luadch date style

        v0.7: by pulsar
            - small fix with lang  / thx Sopor

        v0.6: by pulsar
            - improved get_user_times() function

        v0.5: by pulsar
            - added lastlogout info to output message

        v0.4: by pulsar
            - small permission fix  / thx Kungen

        v0.3: by pulsar
            - added Last user connect to output  / thx fly out to Kungen for the idea
            - check if user is online and if send info instead of time
            - check if user never been logged
            - caching some new table lookups

        v0.2: by pulsar
            - renamed scriptname
            - added multilanguage support

        v0.1: by Night
            - adds listreg command

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_usersearch"
local scriptversion = "1.3"

local cmd = "usersearch"

-- Should details be hidden for users of same or higher level
local hide_details_for_same_or_higher = false

--// imports
local help, ucmd, hubcmd
local prefix_table = cfg.get( "usr_nick_prefix_prefix_table" )
local activate = cfg.get( "usr_nick_prefix_activate" )
local minlevel = cfg.get( "cmd_usersearch_minlevel" )
local max_limit = cfg.get( "cmd_usersearch_max_limit" )
local scriptlang = cfg.get( "language" )

--// msgs
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local help_title = lang.help_title or "usersearch"
local help_usage = lang.help_usage or "[+!#]usersearch <searchstring>"
local help_desc = lang.help_desc or "Search for user in reg list"

local msg_max_limit = lang.msg_max_limit or "\n\t<Max limit for showing reached, use more spesific search string>"

local ucmd_menu = lang.ucmd_menu or { "Hub", "etc", "Usersearch" }
local ucmd_popup = lang.ucmd_popup or "Search registered nick"

local msg_result = lang.msg_result or "\n\tNick: %s \n\tLevel: %s\n\tPassword: %s\n\tRegged by: %s\n\tRegged since: %s\n\tLast seen: %s"
local msg_result_nick = lang.msg_result_nick or "\n\tNick: %s"
local msg_no_matches = lang.msg_no_matches or "No matches found"
local msg_no_allowed = lang.msg_no_allowed or "<Not allowed to view>"
local msg_unknown = lang.msg_unknown or "<unknown>"
local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_online = lang.msg_online or "user is online"

local msg_years = lang.msg_years or " years, "
local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"


----------
--[CODE]--
----------

local get_lastlogout = function( profile )
    local lastlogout
    local ll = profile.lastlogout or profile.lastconnect
    local ll_str = tostring( ll )
    local found = false
    for sid, user in pairs( hub.getusers() ) do
        if user:firstnick() == profile.nick then found = true break end
    end
    if found then
        lastlogout = msg_online
    elseif ll then
        if #ll_str == 14 then
            local sec, y, d, h, m, s = util.difftime( util.date(), ll )
            lastlogout = y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        else
            local d, h, m, s = util.formatseconds( os.difftime( os.time(), ll ) )
            lastlogout = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        end
    else
        lastlogout = msg_unknown
    end
    return lastlogout
end

--// like ipairs for alphabetical indices
local spairs = function( tbl, func )
    local arr = {}
    for n in pairs( tbl ) do
        table.insert( arr, n )
    end
    table.sort( arr, func )
    local i = 0
    local iter = function()
        i = i + 1
        if arr[ i ] == nil then
            return nil
        else
            return arr[ i ], tbl[ arr[ i ] ]
        end
    end
    return iter
end

local onbmsg = function( user, command, parameters )
    local user_level = user:level( )
    if user_level < minlevel then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    parameters = parameters:gsub( "[%%^$().[%]*+?-]", "%%%0" )  -- escape magic chars
    local show_all = false
    if not parameters then
        show_all = true
    end
    local ret = {}
    local count = 0
    local max_limit_reached = false
    local regusers, _, __ = hub.getregusers( )
    for i, u in ipairs( regusers ) do
        local found = show_all or string.find( u.nick:lower(), parameters:lower() )
        if found and not u.is_bot then
            if count <= max_limit then
                count = count + 1
                if u.level >= user_level and hide_details_for_same_or_higher then
                    ret[ u.nick ] = utf.format( msg_result_nick, u.nick )
                else
                    ret[ u.nick ] = utf.format(
                        msg_result,
                        u.nick,
                        u.level or msg_unknown,
                        ( ( user_level == 100 ) or ( user_level > ( u.level or 0 ) ) ) and ( u.password or msg_unknown ) or msg_no_allowed,
                        u.by or msg_unknown,
                        u.date or msg_unknown,
                        get_lastlogout( u ) )
                end
            else
                max_limit_reached = true
            end
        end
    end
    local msg = "\n"
    local hasres = false
    for k, v in spairs( ret ) do
        hasres = true
        msg = msg .. v .. "\n"
    end
    if hasres then
        if max_limit_reached then
            msg = msg .. msg_max_limit
        end
        user:reply( msg, hub.getbot() )
        return PROCESSED
    end
    user:reply( msg_no_matches, hub.getbot() )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function( )
        help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        ucmd = hub.import( "etc_usercommands" )    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, minlevel )
        end
        hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

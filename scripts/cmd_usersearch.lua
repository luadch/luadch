--[[

    cmd_usersearch.lua by Night (originally name: cmd_listreg)

        usage: [+!#]usersearch <searchstring>

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
local scriptversion = "1.0"

local cmd = "usersearch"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local hub_getregusers = hub.getregusers
local hub_isnickonline = hub.isnickonline
local hub_import = hub.import
local hub_escapeto = hub.escapeto
local utf_format = utf.format
local string_find = string.find
local table_insert = table.insert
local util_formatseconds = util.formatseconds
local os_difftime = os.difftime
local os_time = os.time
local util_date = util.date
local util_difftime = util.difftime

--// imports
local help, ucmd, hubcmd
local prefix_table = cfg_get( "usr_nick_prefix_prefix_table" )
local activate = cfg_get( "usr_nick_prefix_activate" )
local minlevel = cfg_get( "cmd_usersearch_minlevel" )
local max_limit = cfg_get( "cmd_usersearch_max_limit" )
local scriptlang = cfg_get( "language" )

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )

local help_title = lang.help_title or "usersearch"
local help_usage = lang.help_usage or "[+!#]usersearch <searchstring>"
local help_desc = lang.help_desc or "Search for user in reg list"

local msg_max_limit = lang.msg_max_limit or "\n\t<Max limit for showing reached, use more spesific search string>"

local ucmd_menu = lang.ucmd_menu or { "Hub", "etc", "Usersearch" }
local ucmd_popup = lang.ucmd_popup or "Search registered nick"

local msg_result = lang.msg_result or "\n\tNick: %s \n\tLevel: %s\n\tPassword: %s\n\tRegged by: %s\n\tRegged since: %s\n\tLast seen: %s"
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
    --[[
    if profile.is_online == 1 then
        lastlogout = msg_online
    elseif ll then
        if #ll_str == 14 then
            local sec, y, d, h, m, s = util_difftime( util_date(), ll )
            lastlogout = y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        else
            local d, h, m, s = util_formatseconds( os_difftime( os_time(), ll ) )
            lastlogout = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        end
    else
        lastlogout = msg_unknown
    end
    ]]
    local found = false
    for sid, user in pairs( hub_getusers() ) do
        if user:firstnick() == profile.nick then found = true break end
    end
    if found then
        lastlogout = msg_online
    elseif ll then
        if #ll_str == 14 then
            local sec, y, d, h, m, s = util_difftime( util_date(), ll )
            lastlogout = y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        else
            local d, h, m, s = util_formatseconds( os_difftime( os_time(), ll ) )
            lastlogout = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        end
    else
        lastlogout = msg_unknown
    end
    return lastlogout
end

local onbmsg = function( user, command, parameters )
    local user_level = user:level( )
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot )
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
    local regusers, _, __ = hub_getregusers( )
    for i, u in ipairs( regusers ) do
        local found = show_all or string_find( u.nick:lower(), parameters:lower() )
        if found and not u.is_bot then
            if count <= max_limit then
                count = count + 1
                table_insert( ret, utf_format(
                    msg_result,
                    u.nick,
                    u.level or msg_unknown,
                    ( user_level >= u.level ) and ( u.password or msg_unknown ) or msg_no_allowed,
                    u.by or msg_unknown,
                    u.date or msg_unknown,
                    get_lastlogout( u )
                ))
            else
                max_limit_reached = true
            end
        end
    end
    local msg = "\n"
    local hasres = false
    for i, b in ipairs( ret ) do
        hasres = true
        msg = msg .. b .. "\n"
    end
    if hasres then
        if max_limit_reached then
            msg = msg .. msg_max_limit
        end
        user:reply( msg, hub_getbot )
        return PROCESSED
    end
    user:reply( msg_no_matches, hub_getbot )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function( )
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        ucmd = hub_import( "etc_usercommands" )    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, minlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
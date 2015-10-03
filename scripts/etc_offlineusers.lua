--[[

    etc_offlineusers.lua by Motnahp

    Usage:

	- on parameter 'show' it posts you a table with all users who have been offline for a set time periode
	- on parameter 'addexception' you can add an user to exceptions, this means he can't be deleted
	- on parameter 'removeexception' you can delete a users ecxeption
	- on parameter 'showexceptions' you can see all protected ( users in exceptions) users
	- on parameter 'delete' you can delete all users with the numbers you entered , example: '+offline delete 13 24 27' deletes user 13, 24 and 27 of the given table
	- on parameter 'showdeleted' it posts you a table with all deleted users
	- on parameter 'autoclean' it deletes all users who are longer offline as allowed ( depends on t_settings )
	- on parameter 'showsettings' it shows you all settings
	- on parameter 'set' and additional parameter
		'toggleautoclean' to enable periodic auto clean
		'maxlvl' you may set the maximum level to check for methode getofflineusers( )
		'days' you may set the maximum days to be apart for methode getofflineusers( )
	- on parameter 'help' it shows an overview of all parameters

    Go and edit "scripts/data/etc_offlineusers_settings.tbl"

    only Users who have at least been online once will be deleted


    v1.3: by pulsar
        - removed send_report() function, using report import functionality now
        - fixed "onbmsg" function
        - changed "help_err_wrong_id"
        - added "addedby" to exception reason  / requested by Sopor
        - added "neverbeenonline"  / requested by Sopor
            - shows a string instead of date if a user was never been online

    v1.2: by pulsar
        - renamed some vars for a better understanding  / requested by Sopor

    v1.1: by pulsar
        - removed "etc_offlineusers_min_level" import
            - using util.getlowestlevel( tbl ) instead of "etc_offlineusers_min_level"

    v1.0: by pulsar
        - using new luadch date style

    v0.9: by pulsar
        - changes in deleteuser() function
            - counting delregs and add them to hubstats "scripts/data/cmd_hubstats.tbl"

    v0.8: by pulsar
        - prevent possible errors on missing params
        - changes in lang msgs

    v0.7: by pulsar
        - typo fixes  / thx Sopor
        - using a sorted level list for help msg
        - exclude "max_offline_days_auto" from "t_settings" file and include it in "cfg/cfg.tbl"
        - add "etc_offlineusers_report"
        - add "etc_offlineusers_report_hubbot"
        - add "etc_offlineusers_report_opchat"
        - add "etc_offlineusers_llevel"
        - check if opchat is activated
        - add "send_report()" function
        - add table lookups

    v0.6: by pulsar
        - using lastlogout instead of lastconnect

    v0.5: by pulsar
        - changed database path and filenames
        - from now on all scripts uses the same database folder

    v0.4.4: by pulsar
        - export scriptsettings to "/cfg/cfg.tbl"

    v0.4.3: by Motnahp
        - cleanup

	v0.4.2: by Motnahp
	    - added parameter autoclean

	v0.4.1: by Motnahp
        - added timer for shedule autoclean ( disabled on default )
        - added import of opchat to feed deleted users
        - added parameter showsettings
        - added parameterset to set settings
        - added parameter help
        - changed methode MinutesToTime( ) to SecondsToTime( ) // changed something before and it caused incompatibility -.-

	v0.3: by Motnahp
        - fixed ucmd

	v0.2: by Motnahp
        - fixed methode getofflineusers( )

	v0.1: by Motnahp
        - adds command offline with parameters show, addexception, removeexception, showexception, delete and showdeleted
        - adds help
        - adds ucmd
        - adds language support

]]--

--[[ Settings ]]--

-- nicht Editieren -- do not edit --

local scriptname = "etc_offlineusers"
local scriptversion = "1.3"

-- cmd --
local cmd = "offline"

-- parameters --
local prm1 = "show"
local prm1_1 = "check"
local prm2 = "addexception"
local prm3 = "removeexception"
local prm4 = "showexceptions"
local prm5 = "delete"
local prm6 = "showdeleted"
local prm7 = "autoclean"
local prm8 = "showsettings"
local prm9 = "set"
local prm10 = "help"

local prm9_1 = "maxlvl"
local prm9_2 = "days"
local prm9_3 = "toggleautoclean"

-- table lookups --
local os_time = os.time
local os_difftime = os.difftime
local utf_match = utf.match
local utf_format = utf.format
local table_remove = table.remove
local util_loadtable = util.loadtable
local util_savearray = util.savearray
local util_savetable =util.savetable
local util_date = util.date
local util_difftime = util.difftime
local util_getlowestlevel = util.getlowestlevel
local hub_getuser = hub.getuser
local hub_getusers = hub.getusers
local hub_getregusers = hub.getregusers
local hub_isnickonline = hub.isnickonline
local hub_bot = hub.getbot( )
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_import = hub.import
local start = os_time( )

-- permissions --
local min_level_owner = cfg_get( "etc_offlineusers_min_level_owner" )
local permission = cfg_get( "etc_offlineusers_permission" )

-- includes // renames --
local report = hub_import( "etc_report" )
local report_activate = cfg_get( "etc_offlineusers_report" )
local report_hubbot = cfg_get( "etc_offlineusers_report_hubbot" )
local report_opchat = cfg_get( "etc_offlineusers_report_opchat" )
local llevel = cfg_get( "etc_offlineusers_llevel" )

local hubcmd

--local tabel and storage path --
local exceptions_path = "scripts/data/etc_offlineusers_exceptions.tbl"
local t_exceptions = util_loadtable( exceptions_path ) or { }

local backup_path = "scripts/data/etc_offlineusers_backup.tbl"
local t_backup = util_loadtable( backup_path ) or { }   -- load the left ones

local settings_path = "scripts/data/etc_offlineusers_settings.tbl"
local t_settings = util_loadtable( settings_path ) or { }

local t_autoclean = cfg_get( "etc_offlineusers_max_offline_days_auto" )

local lastfound = { }

-- load lang file
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )

-- functions --
local getofflineusers
local showexcluded
local showdeleted
local addexception
local removeexception
local deleteuser
local getusertbl
local filterusertbl
local autocleanusers -- implementieren
local SecondsToTime
local changesettings
local showsettings
local returnhelp

local day = 60 * 60 * 24

-->> nachfolgende Settings sind editierbar -->> you may edit the following settings -->>

-- ucmd_menu --
local ucmd_menu_addexception1 = lang.ucmd_menu_addexception1 or { "Hub", "Offline Users", "Protect a User" }
local ucmd_menu_addexception2 = lang.ucmd_menu_addexception2 or { "Hub", "Offline Users", "Protect this User" }
local ucmd_menu_removeexception1 = lang.ucmd_menu_removeexception1 or { "Hub", "Offline Users", "Unprotect a User" }
local ucmd_menu_removeexception2 = lang.ucmd_menu_removeexception2 or { "Hub", "Offline Users", "Unprotect this User" }
local ucmd_menu_showexception = lang.ucmd_menu_showexception or { "Hub", "Offline Users", "Show protected Users" }
local ucmd_menu_show = lang.ucmd_menu_show or { "Hub", "Offline Users", "Manual clean", "Show offline Users" }
local ucmd_menu_delete = lang.ucmd_menu_delete or { "Hub", "Offline Users", "Manual clean", "Delete Users" }
local ucmd_menu_showdeleted = lang.ucmd_menu_showdeleted or { "Hub", "Offline Users", "Show deleted Users" }
local ucmd_menu_auto_check = lang.ucmd_menu_auto_check or { "Hub", "Offline Users", "Automatic clean", "check" }
local ucmd_menu_auto_clean = lang.ucmd_menu_auto_clean or { "Hub", "Offline Users", "Automatic clean", "clean" }
local ucmd_menu_showsettings = lang.ucmd_menu_showsettings or { "Hub", "Offline Users", "Show settings" }
local ucmd_menu_help = lang.ucmd_menu_help or { "Hub", "Offline Users", "Help" }

--settings--
local ucmd_menu_set_check_below = lang.ucmd_menu_set_check_below or { "Hub", "Offline Users", "Settings - manual clean", "Set max level to check" }
local ucmd_menu_set_max_offlinedays_manual = lang.ucmd_menu_set_max_offlinedays_manual or { "Hub", "Offline Users", "Settings - manual clean", "set max offline days " }
local ucmd_menu_set_toggle = lang.ucmd_menu_set_toggle or { "Hub", "Offline Users", "Settings - automatic clean", "Toggle full automatic" }

--msgs-
local ucmd_level = lang.ucmd_level or "Level: "
local ucmd_days = lang.ucmd_days or "Days: "
local ucmd_numbers = lang.ucmd_numbers or "Enter numbers of users to delete. Seperate with whitespace"
local ucmd_who = lang.ucmd_who or "Username: "
local ucmd_why = lang.ucmd_why or "Reason: "

-- help --
local help_title = lang.help_title or "Offline Users"
local help_usage = lang.help_usage or "[+!#]offline [show|addexception|removeexceptions|showexceptions|delete [a, b, c, ...] | showdeleted | autoclean | showsettings | set [ toggleautoclean | maxlvl <value> | days <value> ] | help]"
local help_desc = lang.help_desc or "Allows you to [ shows all users offline for to long | add an exception | remove an exception | delete users by number| shows all by this script deleted users | start autoclean | show settings | set [ toggle auto clean schedule | max level to check (manual clean) | max offline days (manual clean)] ]."

-- error msgs --
local help_err = lang.help_err or "You are not allowed to use this command."
local help_err_wrong_id = lang.help_err_wrong_id or "You have entered one or more wrong parameters, try one of these: \n\n %s \n\n %s "
local help_err_in = lang.help_err_in or "The user  %s  is already protected."
local help_err_out = lang.help_err_out or "The user  %s  is not protected."
local help_err_off = lang.help_err_off or "User  %s  was not found."

-- msgs --
local showmsg = lang.showmsg or "\n\nAll users who have been offline for more than  %s  days:\n"
local addexceptionmsg = lang.addexceptionmsg or "Added protection for user:  %s  |  Reason: %s"
local removeexceptionmsg = lang.removeexceptionmsg or "Removed protection from user:  %s"
local showexceptedmsg = lang.showexceptedmsg or "\n\nAll protected users at the moment:\n"
local deleteusermsg = lang.deleteusermsg or "Offline User  |  %s  |  The User  %s  was delregged."
local delete_error = lang.delete_error or "The Number  %s  does not exist."
local delete_errorprotect = lang.delete_errorprotect or "The User  %s  is protected."
local showdeletedmsg = lang.showdeletedmsg or "\n\nAll users who have been deleted: \n[Nick] [Pw] [Level] [Date] "
local changesettingsmsg = lang.changesettingsmsg or "%s  has been set to  %s"
local showsettingsmsgprt1 = lang.showsettingsmsgprt1 or "\n\nThe settings: \n\tThe maximum offline days per level for AUTOMATIC clean:\n\t Full auto clean: %s\n\t"
local showsettingsmsgprt2 = lang.showsettingsmsgprt2 or " Level %s: %s days\n\t"
local showsettingsmsgprt3 = lang.showsettingsmsgprt3 or "\n\n\tThe settings for MANUAL clean:\n\t Offline days to see a user: %s\n\t".." Check all users below level: %s\n"
local tableheader = lang.tableheader or "[ # ]\t[ nick ]\t\t[ level_nr ]\t[ level_name ]\t[ ever been connected ]\t[ protected ]\t[ offline time ]"
local addedby = lang.addedby or " | added by: "
local neverbeenonline = lang.neverbeenonline or "The user was never been online"

local helpmsg = lang.helpmsg or [[


An Overview of all parameters of "etc_offlineuser.lua"
	usage is [+!#]offline <parameter> <additional parameter>
	- on parameter 'show' it posts you a table with all users who have been offline for a set time period
	- on parameter 'addexception' you can add an user to exceptions, this means he can't be deleted
	- on parameter 'removeexception' you can delete a users exception
	- on parameter 'showexceptions' you can see all protected ( users in exceptions) users
	- on parameter 'delete' you can delete all users with the numbers you entered , example: '+offline delete 13 24 27' deletes user 13, 24 and 27 of the given table
	- on parameter 'showdeleted' it posts you a table with all deleted users
	- on parameter 'autoclean' it deletes all users who are longer offline as allowed ( depends on t_settings )
	- on parameter 'showsettings' it shows you all settings
	- on parameter 'set' and additional parameter
		'toggleautoclean' to enable periodic auto clean
		'maxlvl' you may set the maximum level to check for methode getofflineusers( )
		'days' you may set the maximum days to be apart for methode getofflineusers( )
	- on parameter 'help' it shows this msg
]]

--<< ende des editierbaren Teils --<< end of editable settings --<<


--[[   Code   ]]--

local min_level = util_getlowestlevel( permission )

local onbmsg = function( user, adccmd, parameters)
	local local_prms = parameters.." "
	local user_level = user:level( )
	if not permission[user_level] then
		user:reply( help_err, hub_bot )
		return PROCESSED
	else
	    local id, others = utf_match( local_prms, "^(%S+) (.*)")
        local str_1, str_2
        if others then str_1, str_2 = utf_match( others, "(%S+) (.*)" ) end
        -- local nick = utf_match( others, "(%S+)" )

		if id == prm1 then	-- shows users longer offline than 't_settings.max_offlinedays_manual'
			user:reply( getofflineusers( false ), hub_bot, hub_bot )
			return PROCESSED
		end
		if id == prm1_1 then	-- shows users longer offline than 't_settings.max_offlinedays_manual'
			user:reply( getofflineusers( true ), hub_bot, hub_bot )
			return PROCESSED
		end
		if id == prm6 then -- show deleted users
			user:reply( showdeleted( ), hub_bot, hub_bot )
			return PROCESSED
		end
		if id == prm7 then -- autoclean
			if user_level < min_level_owner then
				user:reply( help_err, hub_bot )
			else
                report.send( report_activate, report_hubbot, report_opchat, llevel, autocleanusers( false ) )
			end
			return PROCESSED
		end
		if id == prm8 then -- shows all settings
			user:reply( showsettings( ), hub_bot, hub_bot )
			return PROCESSED
		end
		if id == prm10 then -- show help
			user:reply( returnhelp(), hub_bot, hub_bot)
			return PROCESSED
		end
        if others then
            if ( id == prm2 ) and ( str_1 ~= "" ) and ( str_2 ~= "" ) then -- add exception	-- only online users atm
                user:reply( addexception( others, user:firstnick() ), hub_bot )
                return PROCESSED
            end
            if ( id == prm3 ) and ( str_1 ~= "" ) and ( str_2 ~= "" ) then -- remove exception -- only online users atm
                user:reply( removeexception( others, user ), hub_bot )
                return PROCESSED
            end
            if id == prm4 then -- show exception
                user:reply( showexcluded( ), hub_bot, hub_bot )
                return PROCESSED
            end
            if ( id == prm5 ) and ( str_1 ~= "" ) and ( str_2 ~= "" ) then -- delete users with numbers
                if user_level < min_level_owner then
                    user:reply( help_err, hub_bot )
                else
                    report.send( report_activate, report_hubbot, report_opchat, llevel, deleteuser( others, user ) )
                end
                return PROCESSED
            end
            if ( id == prm9 ) and ( str_1 ~= "" ) and ( str_2 ~= "" ) then -- change settings
                if user_level < min_level_owner then
                    user:reply( help_err, hub_bot )
                else
                    user:reply( changesettings( others, user ), hub_bot)
                end
                return PROCESSED
            end
        end
		user:reply( utf_format( help_err_wrong_id, help_usage, help_desc ), hub_bot )	-- if no id hittes
		return PROCESSED

	end
end

hub.setlistener( "onStart", { },
    function( )
        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, min_level )    -- reg help
        end
        local ucmd = hub_import( "etc_usercommands" )   -- add usercommand
        if ucmd then

            ucmd.add( ucmd_menu_show, cmd, { prm1 }, { "CT1" }, min_level )
            ucmd.add( ucmd_menu_delete, cmd, { prm5, "%[line:" .. ucmd_numbers .. "]" }, { "CT1" }, min_level_owner )
			ucmd.add( ucmd_menu_auto_check, cmd, { prm1_1 }, { "CT1" }, min_level_owner )
			ucmd.add( ucmd_menu_auto_clean, cmd, { prm7 }, { "CT1" }, min_level_owner )

            ucmd.add( ucmd_menu_showexception, cmd, { prm4 }, { "CT1" }, min_level )
            ucmd.add( ucmd_menu_showdeleted, cmd, { prm6 }, { "CT1" }, min_level )
            ucmd.add( ucmd_menu_showsettings, cmd, { prm8}, { "CT1" }, min_level )

            ucmd.add( ucmd_menu_addexception1, cmd, { prm2,  "%[line:" .. ucmd_who .. "]", 1, "%[line:" .. ucmd_why .. "]" }, { "CT1" }, min_level )
            ucmd.add( ucmd_menu_addexception2, cmd, { prm2, "%[userNI]", 2, "%[line:" .. ucmd_why .. "]" }, { "CT2" }, min_level )
            ucmd.add( ucmd_menu_removeexception1, cmd, { prm3, "%[line:" .. ucmd_who .. "]", 1 }, { "CT1" }, min_level )
            ucmd.add( ucmd_menu_removeexception2, cmd, { prm3, "%[userNI]", 2 }, { "CT2" }, min_level )

            ucmd.add( ucmd_menu_set_check_below, cmd, { prm9, prm9_1, "%[line:" .. ucmd_level .. "]" }, { "CT1" }, min_level_owner )
            ucmd.add( ucmd_menu_set_max_offlinedays_manual, cmd, { prm9, prm9_2, "%[line:" .. ucmd_days .. "]" }, { "CT1" }, min_level_owner )
            ucmd.add( ucmd_menu_set_toggle, cmd, { prm9, prm9_3, 100 }, { "CT1" }, min_level_owner )

			ucmd.add( ucmd_menu_help, cmd, { prm10 }, { "CT1" }, min_level )
		end
        hubcmd = hub_import( "etc_hubcommands" )   -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.setlistener( "onTimer", { },
    function( )
        if os_difftime( os_time( ) - start ) >= ( day ) then
			if t_settings.autoclean then
				hub.broadcast( autocleanusers( true ),hub_bot )
                start = os_time( )
			end
        end
        return nil
    end
)

-- functions --

getofflineusers = function ( mode )

	local profile, protected, gonefor
	local msg = utf_format( showmsg, t_settings.max_offlinedays_manual ).."\n"
    local regusers, reggednicks, reggedcids = hub.getregusers( )

	lastfound = { }

	-- get data --
	lastfound = getusertbl( )
	-- kick good ones --
    if mode then
        lastfound = filterusertbl( lastfound, t_settings.check_below, true )
    else
        lastfound = filterusertbl( lastfound, t_settings.check_below, false )
    end
	-- sort data --
	table.sort( lastfound, function(a, b) return (a.lastentry > b.lastentry) end )

	-- format output --
    msg = msg..tableheader
	for i, user in ipairs( lastfound ) do  -- format output
		local protected, nick, cid, hash = false, user.nick, user.cid, user.hash
		for i, excepttbl in ipairs( t_exceptions ) do  -- is user in t_exceptions?
            if excepttbl.user_nick == nick then
                protected = true	-- to check if he is in the list
				break
            end
        end
        gonefor = SecondsToTime( user.lastentry, user.enter )
		local tabs = string.len( user.nick )
		if tabs > 8 then
			tabs = "\t"
		else
			tabs = "\t\t"
		end
		msg = msg.."\n["..tostring(i).."]\t".."["..user.nick.."]"..tabs.."["..tostring( user.level_nr ).."]\t\t".."["..user.level_name.."]\t\t\t".."["..tostring( user.enter ).."]\t\t".."["..tostring( protected ).."]\t\t".."["..gonefor.."]"
	end
	return msg
end


addexception = function ( others, nick )
	local user, ct, reason = utf_match( others, "(%S+) (%d+) (.+)" )
    local inlist = false
    local nick

    if tonumber(ct) == 1 then
        nick = user
    else
        user = hub_isnickonline( user )
        nick = user:firstnick( )
    end

    local msg, key, except

    for i, excepttbl in ipairs( t_exceptions ) do  -- is user in t_exceptions?
        key = i
        except = excepttbl
        if except.user_nick == nick then
            inlist = true	-- to check if he is in the list and want to leave
            break
        end
    end
    if not reason then
        reason = "none"
    end
    if not inlist then
        t_exceptions[ #t_exceptions + 1 ] = {
            user_nick = nick,
            reason = reason .. addedby .. nick
        }
        util_savearray( t_exceptions, exceptions_path )
        msg = utf_format( addexceptionmsg, nick, reason )
    else
        msg = utf_format( help_err_in, nick )
    end
    return msg
end

removeexception = function ( others )
	local user, ct = utf_match( others, "(%S+) (%d+)" )
    local inlist = false
    local nick

    if tonumber(ct) == 1 then
        nick = user
    else
        user = hub_isnickonline( user )
        nick = user:firstnick( )
    end

	local msg, key, except

	for i, excepttbl in ipairs( t_exceptions ) do  -- is user in t_exceptions?
		key = i
		except = excepttbl
		if except.user_nick == nick then
			inlist = true	-- to check if he is in the list and want to leave
			break
		end
	end
	if inlist then		-- to check if he is in the list yet, if yes remove him of t_exceptions
		table_remove( t_exceptions, key )
		util_savearray( t_exceptions, exceptions_path )
		msg = utf_format( removeexceptionmsg, nick )
	else
		msg = utf_format( help_err_out, nick )
	end
	return msg
end

showexcluded = function ( )

	local msg = showexceptedmsg

	for i, excepttbl in ipairs( t_exceptions ) do
		msg = msg.."\n "..( excepttbl.user_nick or " ").." - "..( excepttbl.reason or " " )
	end
	return msg
end

showdeleted = function ( )

	local msg = showdeletedmsg

	for i, backuptbl in ipairs( t_backup ) do
		msg = msg.."\n "..backuptbl.nick .." - "..backuptbl.password.." - "..( backuptbl.level or "20" ).." - "..backuptbl.date
	end
	return msg
end

deleteuser = function ( numbers )
	local msg =""
    local count = 0

	-- split numbers in single digits --
	local digits = { }
	for k, v in string.gmatch(numbers, "%w+") do
		digits[#digits + 1 ] = { [1] = k }
	end

	-- check if the insert digits are in the list and ready to delete; also formats a return string--
	for j, digitstbl in pairs( digits ) do
		msg = msg.."\n"
		if ( #lastfound >= tonumber( digitstbl[1] ) ) then
			local protected = false
			local number = tonumber( digitstbl[1] )
			local nick = lastfound[number].nick
			local level = lastfound[number].level_nr

			-- is user protected? --
			for i, excepttbl in ipairs( t_exceptions ) do  -- is user in t_exceptions?
				if excepttbl.user_nick == nick then
					protected = true	-- to check if he is in the list
					break
				end
			end

			-- delete if not protected --
			if not protected then
				local password = lastfound[number].password
				t_backup[ #t_backup +1 ] = {
					nick = nick,
					password = password,
					level = level,
					date = os.date( "%d.%m.%y" )
				}
				util_savearray( t_backup, backup_path )
				hub.delreguser( nick )
				msg = msg..utf_format( deleteusermsg, "Manual-Clean", nick )
                count = count + 1
			else
				msg = msg..utf_format( delete_errorprotect, nick )
			end
		else
			msg = msg..utf_format( delete_error, tostring( digitstbl[1] ) )
		end
	end

    if count > 0 then
        local hubstats_file = "scripts/data/cmd_hubstats.tbl"
        local hubstats_tbl = util_loadtable( hubstats_file )

        local year = tonumber( os.date( "%Y" ) )
        local month = tonumber( ( os.date( "%m" ):gsub( "0", "" ) ) )

        local old_count = hubstats_tbl[ year ][ month ][ "cmds" ][ "delreg" ]
        local new_count = old_count + count

        hubstats_tbl[ year ][ month ][ "cmds" ][ "delreg" ] = new_count
        util_savetable( hubstats_tbl, "hubstats_tbl", hubstats_file )
    end

	return msg
end

SecondsToTime = function(iSeconds, mode)
    local sTime
    -- Build table with time fields
    local T = os.date("!*t", tonumber(iSeconds));
    -- Format to string
    if mode then
        sTime = string.format("%i y, %i m, %i d, %i h, %i min", (T.year-1970), T.month-1, T.day-1, T.hour, T.min)
    else
        sTime = "The user was never been online"
    end
    -- Small stat?
    return sTime
end

changesettings = function( others )
    -- check id and change --
	local id2, level = utf_match( others, "(%S+) (%d+)")

	level = tonumber( level)
	if id2 == prm9_1 then
		t_settings.check_below = level
	elseif id2 == prm9_2 then
		t_settings.max_offlinedays_manual = level
	elseif id2 == prm9_3 then
		if t_settings.autoclean then
			t_settings.autoclean = false
			level = "false"
		else
			t_settings.autoclean = true
			level = "true"
		end
	end
	-- save settings --
	util_savetable( t_settings, "t_settings", settings_path )

	return utf_format( changesettingsmsg, id2, level )
end

showsettings = function ( )
    -- build output --
    local msg = utf_format( showsettingsmsgprt1, tostring ( t_settings.autoclean )) .. "\n\t"
    -- check levels and value --
        local tbl = {}
        for i = 0, 100 do
            if t_autoclean[ i ] ~= nil then
                table.insert( tbl, utf_format( showsettingsmsgprt2, tostring( i ), tostring( t_autoclean[ i ] ) ) )
                i = i + 1
            end
        end
        for levels, value in ipairs( tbl ) do
            msg = msg..value
        end
        msg = msg..utf_format(showsettingsmsgprt3, t_settings.max_offlinedays_manual, t_settings.check_below )
	return msg
end

autocleanusers = function ( mode )
    local msg
	if mode then
		msg = "full-automatic clean\n"
	else
		msg = "semi-automatic clean\n"
	end
	lastfound = { }

	-- get data --
	lastfound = getusertbl( )
	-- kick good ones --
	lastfound = filterusertbl( lastfound, t_settings.check_below, true )
	-- sort data --
	table.sort( lastfound, function(a, b) return (a.lastentry > b.lastentry) end )

    -- ggf noch einfügen wieviele nicht gelöscht wurden..
    for var = #lastfound, 1, -1 do
        -- only users who have been online will be deleted --
        if lastfound[var].enter then
            msg = msg..deleteuser(var)
        end
    end

    return msg
end

returnhelp = function( )
	return helpmsg
end

getusertbl = function( )
    local regusers, reggednicks, reggedcids = hub.getregusers( )
	local lastlogout, bot, lastentry
	local maxofflinetime = t_settings.max_offlinedays_manual * day

	local tbl = { }
	for i, user in ipairs( regusers ) do
		lastlogout = user.lastlogout or user.lastconnect
        local ll_str = tostring( lastlogout )
		if ( user.is_bot ) then
			bot = true
		else
			bot = false
		end
		if lastlogout then
            if #ll_str == 14 then
                local sec, y, d, h, m, s = util_difftime( util_date(), lastlogout )
                lastentry = sec
            else
                lastentry = os_difftime( os_time(), lastlogout )
            end
			tbl[ #tbl + 1 ] = {
				nick = user.nick,
                lastentry = lastentry,
				enter = true,
				level_nr = user.level,
				level_name = cfg_get( "levels" )[ tonumber( user.level ) ] or "Unreg",
                password = user.password,
				bot = bot
			}
		else
			tbl[ #tbl + 1 ] = {
				nick = user.nick,
				lastentry = ( maxofflinetime * 10 ),
				enter = false,
				level_nr = user.level,
				level_name = cfg_get( "levels" )[ tonumber( user.level ) ] or "Unreg",
                password = user.password,
				bot = bot
			}
		end
	end
	return tbl
end

filterusertbl = function( tbl, below, mode )
    local offline_max, check_if_lower
    offline_max = t_settings.max_offlinedays_manual * day
    if mode then
        check_if_lower = 100
    else
        check_if_lower = below
    end

	for var = #tbl, 1, -1 do
		local last_connect = tbl[var].lastentry

		local lvl
		local removed = false
		if tonumber( tbl[var].level_nr ) then
			lvl = tonumber( tbl[var].level_nr )
		else
			lvl = 100
		end
		if mode then
            offline_max = t_autoclean[lvl] * day or t_settings.max_offlinedays_manual * day
        end
		if ( last_connect < offline_max ) then
			table_remove( tbl, var )
			removed = true
		elseif ( lvl >= check_if_lower ) then
			table_remove( tbl, var )
			removed = true
		elseif tbl[var].is_bot then
			table_remove( tbl, var )
			removed = true
		elseif not removed then
			for sid, onlineuser in pairs( hub_getusers( ) ) do
				if tbl[var].nick == onlineuser:firstnick( ) then
				table_remove( tbl, var )
				break
				end
			end
		end
	end
	return tbl
end

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. ".lua **" )

--[[   End    ]]--
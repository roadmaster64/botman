--[[
    Botman - A collection of scripts for managing 7 Days to Die servers
    Copyright (C) 2018  Matthew Dwyer
	           This copyright applies to the Lua source code in this Mudlet profile.
    Email     smegzor@gmail.com
    URL       http://botman.nz
    Source    https://bitbucket.org/mhdwyer/botman
--]]

function thirtySecondTimer()
	local k, v, cmd

	windowMessage(server.windowDebug, "30 second timer\n")

	if botman.botDisabled then
		return
	end

	if customThirtySecondTimer ~= nil then
		-- read the note on overriding bot code in custom/custom_functions.lua
		if customThirtySecondTimer() then
			return
		end
	end

	if botman.botOffline then
		return
	end

	if tonumber(botman.playersOnline) ~= 0 then
		send("gt")
	end

	if not server.botsIP then
		send("pm IPCHECK")
	end

	if (botman.announceBot == true) then
		fixMissingServer() -- test for missing values

		message("say [" .. server.chatColour .. "]" .. server.botName .. " is online. Command me. :3[-]")
		botman.announceBot = false
	end

	math.randomseed( os.time() )

	if (botman.initError == true) then
		gatherServerData()
		botman.initError = false
		botman.announceBot = true
	end

	if tonumber(server.rebootHour) == tonumber(botman.serverHour) and tonumber(server.rebootMinute) == tonumber(botman.serverMinute) and botman.scheduledRestart == false and server.allowReboot then
		message("say [" .. server.chatColour .. "]The server will reboot in 15 minutes.[-]")
		botman.scheduledRestartPaused = false
		botman.scheduledRestart = true
		botman.scheduledRestartTimestamp = os.time() + 900
	end

	if not server.lagged then
		newDay()

		-- scan player inventories
		for k, v in pairs(igplayers) do
			if (igplayers[k].killTimer == nil) then igplayers[k].killTimer = 9 end

			if tonumber(igplayers[k].killTimer) < 2 then
				cmd = "si " .. k
				if botman.dbConnected then conn:execute("INSERT into commandQueue (command, steam) VALUES ('" .. cmd .. "'," .. k .. ")") end
			end
		end

		cmd = "DoneInventory"
		if botman.dbConnected then conn:execute("INSERT into commandQueue (command) VALUES ('" .. cmd .. "')") end

		if tonumber(botman.playersOnline) > 9 then
			if server.coppi then
				for k,v in pairs(igplayers) do
					if tonumber(players[k].accessLevel) > 2 and not players[k].newPlayer then
						if server.scanNoclip then
							-- check for noclipped players
							send("pug " .. k)

							if botman.getMetrics then
								metrics.telnetCommands = metrics.telnetCommands + 1
							end
						end

						if not server.playersCanFly then
							-- check for flying players
							send("pgd " .. k)

							if botman.getMetrics then
								metrics.telnetCommands = metrics.telnetCommands + 1
							end
						end
					end
				end
			end
		end

		-- test for telnet command lag as it can creep up on busy servers or when there are lots of telnet errors going on
		if not botman.botOffline and not botman.botDisabled then
			if server.enableLagCheck then
				botman.lagCheckTime = os.time()
				send("pm LagCheck " .. os.time())
			end

			if botman.getMetrics then
				metrics.telnetCommands = metrics.telnetCommands + 1
			end
		else
			if server.enableLagCheck then
				botman.lagCheckTime = os.time()
			end

			server.lagged = false
		end
	end

	-- update the shared database (bots) server table (mainly for players online and a timestamp so others can see we're still online
	updateBotsServerTable()
end

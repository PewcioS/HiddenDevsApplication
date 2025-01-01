local TeleportGame = {}
local TPS = game:GetService("TeleportService") 

function TeleportGame.New(LobbyData : {})
	local self = setmetatable({},{__index = TeleportGame})
	self.MaxAttempts = 5
	self.Attempts = 0
	self.Players = LobbyData.Players
	self.Status = false
	--self.JobId =
	--self.AccessCode = TPS:ReserveServer(self.JobId)

	task.spawn(function()
		self:TeleportPlayers()
	end)

	return self
end

function TeleportGame:TeleportPlayers(...)
	while #self.Players > 0 and self.Attempts < self.MaxAttempts do
		task.wait(1)
		self.Attempts += 1
		for _,player in pairs(self.Players) do
			local plr = game.Players:FindFirstChild(player)
			if plr then
				local succes,err = pcall(function()
					TPS:TeleportToPrivateServer(self.JobId,self.AccessCode,{plr})
				end)
				if succes then
					print("Player teleported successfully: " .. player)
					table.remove(self.Players,table.find(self.Players,player))
				else
					warn("Failed to teleport player: " .. player .. " | Error: " ..err)
				end
			end
		end
		if self.Attempts > self.MaxAttempts then
			break
		end
	end

	if #self.Players == 0 then
		print("All players teleported successfully!")
	else
		self:HandleTeleportError()
	end

	self.Status = true
end

function TeleportGame:HandleTeleportError(err : String)
	for _,Player in pairs(self.Players) do
		local plr = game.Players:FindFirstChild(Player)
		if plr then
			plr:Kick("Error while teleporting reason: "..self:CheckErrorType(err).." please rejoin and try again!")
		end
	end
end

function TeleportGame:CheckErrorType(err)
	return if typeof(err) == "table" then err else "Uknown"
end

return TeleportGame

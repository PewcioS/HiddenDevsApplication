--//Veriables
local LobbysFolder = game.Workspace.Lobbys
local Players = game:GetService("Players")
local Rs = game:GetService("ReplicatedStorage")
local Ss = game:GetService("ServerStorage")
local LobbysDataTable = {}

--//Folders
local Events = Rs.Events
local ClientRemotes = Events.Client

local Assets = Ss.Assets
local ModelsFolder = Assets.Models

--//Modules
local TeleportGameHandler = require(script.TeleportGameHandler)
local ImageHandler = require(script.ImageHandler)

--//Remotes
local LobbyRemote = ClientRemotes.LobbyRemote

type LobbyData = {
	Players: {string},
	Info: {
		MaxPlayers: number,
		TeleportTime: number,
		CanEnter: boolean
	},
	Nodes: {
		TeleportHolderNode: Instance,
		TeleportBackNode: Instance
	},
	Sounds: {
		CountDownSFX: Sound,
		CountDownSFXLobbyRoom: Sound
	},
	TextLabels: {
		InLobby: TextLabel,
		TimeLobby: TextLabel,
		TimeLobbyRoom: TextLabel
	},
	Models: {
		LobbyRoom: Model
	},
	Frames: {
		ImageHolder: Frame
	}
}

Players.PlayerRemoving:Connect(function(player)
	for _, LobbyData in pairs(LobbysDataTable) do
		local player = table.find(LobbyData.Players, player.Name)
		if player then
			
			local InLobby = LobbyData.TextLabels.InLobby
			local TimeLobby = LobbyData.TextLabels.TimeLobby
			local TimeLobbyRoom = LobbyData.TextLabels.TimeLobbyRoom
			local LobbyRoom = LobbyData.Models.LobbyRoom
			local ImageFrame = LobbyData.Frames.ImageHolder
			
			table.remove(LobbyData.Players, player)
			ImageHandler.New(player,ImageFrame,true)
			
			InLobby.Text = (#LobbyData.Players.."/"..LobbyData.Info.MaxPlayers)
			
			if #LobbyData.Players == 0 and LobbyData.TimeCor ~= nil then
				CloseLobby(LobbyData)
			end
		end
	end
end)

for _,Lobby in pairs(LobbysFolder:GetChildren()) do
	--//Models
	local LobbyRoom = ModelsFolder.LobbyRoom:Clone()


	--//TouchParts
	local LobbyEnter = Lobby.LobbyEnter
	local LobbyExit = LobbyRoom.LobbyExit

	--//Nodes	
	local TeleportBackNode = Lobby.TeleportBack
	local TeleportHolderNode = Lobby.TeleportHolder
	local LobbyRoomPosNode = Lobby.LobbyRoomPosNode


	--//LobbyRoom
	LobbyRoom.Parent = Lobby
	LobbyRoom:MoveTo(LobbyRoomPosNode.Position)
	LobbyRoom.Parent = nil


	local MaxPlayers = Lobby:GetAttribute("MaxPeople")
	local TimeToTeleport = Lobby:GetAttribute("TimeToTeleport")


	--//Ui Parts
	local UiPart = Lobby.UiPart
	local LobbyInfoUi = UiPart.LobbyInfo
	
	--//BilboardsGuis
	local UiPartRoom = LobbyRoom.LobbyRoomUiPart
	local LobbyUi = UiPartRoom.LobbyInfo

 	--//Text Info
	local InLobby = LobbyInfoUi.InLobby
	local TimeLobby = LobbyInfoUi.TimeInfo
	local TimeLobbyRoom = LobbyUi.TimeInfo
	
	--//Frames
	local ImageHolderFrame = LobbyInfoUi.ImageHolder

	local TimeCor

	local CountDownSFX =  UiPart.CountDownSFX
	local CountDownSFXRoom = UiPartRoom.CountDownSFX

	--//Table
	LobbysDataTable[Lobby.Name] = { 
		Players = {},
		Info = {
			MaxPlayers = tonumber(MaxPlayers),
			TeleportTime = tonumber(TimeToTeleport),
			CanEnter = true
		},
		Nodes = {
			TeleportHolderNode = TeleportHolderNode,
			TeleportBackNode = TeleportBackNode
		},
		Sounds = {
			CountDownSFX = CountDownSFX,
			CountDownSFXLobbyRoom = CountDownSFXRoom
		},
		TextLabels = {
			InLobby = InLobby,
			TimeLobby = TimeLobby,
			TimeLobbyRoom = TimeLobbyRoom
		},
		Models = {
			LobbyRoom = LobbyRoom
		},
		Frames = {
			ImageHolder = ImageHolderFrame
		},
		TimeCor = nil
	}

	local LobbyData = LobbysDataTable[Lobby.Name]

	InLobby.Text = "0/"..LobbyData.Info.MaxPlayers
	TimeLobby.Text = LobbyData.Info.TeleportTime.." SEC"


	LobbyEnter.Touched:Connect(function(hit)
		local db = false
		local Humanoid = hit.Parent:FindFirstChild("Humanoid")

			if not db 
			and not (#LobbyData.Players >= LobbyData.Info.MaxPlayers) 
			and Humanoid and Humanoid.Health ~= 0 
			and not table.find(LobbyData.Players,hit.Parent.Name) 
			and LobbyData.Info.CanEnter then
			
			warn(hit.Parent.Name,"Has joined",Lobby.Name)

			db = true

			if LobbyRoom.Parent == nil then
				LobbyRoom.Parent = Lobby
			end

			if not table.find(LobbyData.Players,hit.Parent.Name) then
				table.insert(LobbyData.Players,hit.Parent.Name)
			end

			--[[if #LobbyData.Players > 1 then
				for _,PlayerName in pairs(LobbyData.Players) do
					local player = Players:FindFirstChild(PlayerName)
					LobbyRemote:FireClient(player,{Status = "JoinPlayer",LobbyData = LobbyData})
				end
			end]]

			if TimeCor ~= nil and coroutine.status(TimeCor) == "dead" then
				TimeCor = nil
			end
			
			if LobbyData.TimeCor == nil then
				LobbyData.TimeCor = coroutine.create(function()
					TeleportSequance(LobbyData)
				end)
				coroutine.resume(LobbyData.TimeCor)
			end

			InLobby.Text = (#LobbyData.Players.."/"..LobbyData.Info.MaxPlayers)

			local Player = Players:GetPlayerFromCharacter(hit.Parent)

			if table.find(LobbyData.Players,hit.Parent.Name) then
				LobbyRemote:FireClient(Player,{Status = "TeleportTransition"})
				task.spawn(function()
					task.spawn(function()
						TeleportPlayer({TeleportBack = false,Player = hit.Parent},LobbyData)
					end)
				end)
			end
			
			ImageHandler.New(Player,ImageHolderFrame,false)

			task.wait(.2)
			db = false
		end
	end)

	LobbyExit.Touched:Connect(function(hit)
		local db = false
		local Humanoid = hit.Parent:FindFirstChild("Humanoid")

		if not db and table.find(LobbyData.Players,hit.Parent.Name) 
			and Humanoid and Humanoid.Health ~= 0 then

			db = true
			local Player = Players:GetPlayerFromCharacter(hit.Parent)

			LobbyRemote:FireClient(Player,{Status = "TeleportTransition"})

			table.remove(LobbyData.Players,table.find(LobbyData.Players,hit.Parent.Name))

			task.spawn(function()
				TeleportPlayer({TeleportBack = true,Player = hit.Parent},LobbyData)
				task.wait(1)
				ImageHandler.New(Player,ImageHolderFrame,true)
			end)

			if #LobbyData.Players == 0 and LobbyData.TimeCor ~= nil then
				CloseLobby(LobbyData)
			end
			
			LobbyInfoUi.InLobby.Text = #LobbyData.Players.."/"..LobbyData.Info.MaxPlayers

			task.wait(.2)
			db = false
		end
	end)
end

--[[
@id:     TeleportPlayer
@desc:   Teleports player to lobby room,or teleports from lobby room to main lobby
@param:  Table : Data - Table with info what to do, Table: LobbyData - All stuff with in the lobby table
@return: ~
--]]
function TeleportPlayer(Data : {},LobbyData : LobbyData)
	task.wait(1)
	local Player = Data.Player or nil
	local Nodes = LobbyData.Nodes
	local Models = LobbyData.Models
	
	if Data.TeleportBack ~= nil then
		if Data.TeleportBack then
			local Hrp = Player:FindFirstChild("HumanoidRootPart")

			Hrp.CFrame = Nodes.TeleportBackNode.CFrame:ToWorldSpace(CFrame.new(0,0,0))
		else
			local LobbyStuff = Models.LobbyRoom.LobbyTeleport:GetChildren()
			local TeleportNode = LobbyStuff[math.random(1,#LobbyStuff)]
			local Hrp = Player:FindFirstChild("HumanoidRootPart")

			Hrp.CFrame = TeleportNode.CFrame:ToWorldSpace(CFrame.new(0,0,0))
		end
	else
		for _,player in pairs(LobbyData.Players) do
			local plr = game.Players:FindFirstChild(player)
			if plr and plr.Character then
				local Hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if Hrp then
					Hrp.Position = Nodes.TeleportHolderNode.Position
					task.wait(0.2)
					Hrp.Anchored = true
				end
			end
		end
	end
end

--[[
@id:     CloseLobby
@desc:   Closes lobby and sets all values to deafult
@param:  Table: LobbyData - All stuff with in the lobby table
@return: ~
--]]
function CloseLobby(LobbyData : LobbyData)
	local InLobby = LobbyData.TextLabels.InLobby
	local TimeLobby = LobbyData.TextLabels.TimeLobby
	local TimeLobbyRoom = LobbyData.TextLabels.TimeLobbyRoom
	local LobbyRoom = LobbyData.Models.LobbyRoom
	local ImageFrame = LobbyData.Frames.ImageHolder
	
	LobbyData.Info.CanEnter = false
	coroutine.close(LobbyData.TimeCor)
	LobbyData.TimeCor = nil
	task.wait(1)
	
	if LobbyData.Models.LobbyRoom.Parent ~= nil then
		LobbyData.Models.LobbyRoom.Parent = nil
	end

	ImageHandler:DestroyImages(ImageFrame)
	TimeLobby.Text = LobbyData.Info.TeleportTime .. " SEC"
	TimeLobbyRoom.Text = "STARTING IN: " .. LobbyData.Info.TeleportTime
	InLobby.Text = "0/" .. LobbyData.Info.MaxPlayers
	LobbyData.Info.CanEnter = true
end

--[[
@id:     TeleportSequance
@desc:   Starts countdown and other important stuff :)
@param:  Table: LobbyData - All stuff with in the lobby table
@return: ~
--]]
function TeleportSequance(LobbyData : LobbyData)	
	local InLobby = LobbyData.TextLabels.InLobby
	local TimeLobby = LobbyData.TextLabels.TimeLobby

	local TimeLobbyRoom = LobbyData.TextLabels.TimeLobbyRoom

	local LobbyRoom = LobbyData.Models.LobbyRoom

	for i = LobbyData.Info.TeleportTime,0,-1 do
		task.wait(1)
		TimeLobby.Text = i.." SEC"
		TimeLobbyRoom.Text = "STARTING IN: " ..i
		for _,Sounds in pairs(LobbyData.Sounds) do
			Sounds:Play()
		end
		if i <= 1 then
			for _,player in pairs(LobbyData.Players) do
				local plr = game.Players:FindFirstChild(player)
				if plr then
					LobbyRemote:FireClient(plr,{Status = "CountDownEffect"})
				end
			end
		end
	end

	LobbyData.Info.CanEnter = false
	local TeleportHandler = TeleportGameHandler.New(LobbyData)
	
	repeat 
		for dots = 1, 3 do
			TimeLobby.Text = string.rep(".", dots)
			task.wait(0.2)
		end
	until TeleportHandler.Status == true

	TeleportPlayer({TeleportBack = nil},LobbyData)
	
	ImageHandler:DestroyImages(LobbyData.Frames.ImageHolder)

	LobbyRoom.Parent = nil
	TimeLobby.Text = LobbyData.Info.TeleportTime.." SEC"
	TimeLobbyRoom.Text = "STARTING IN: " ..LobbyData.Info.TeleportTime
	InLobby.Text = "0/"..LobbyData.Info.MaxPlayers
	LobbyData.Info.CanEnter = true
end

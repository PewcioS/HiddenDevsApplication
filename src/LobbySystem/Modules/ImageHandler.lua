local ImageHandler = {}
local Players = game:GetService("Players") 
local PlayerImage = script.PlayerImage

function ImageHandler.New(Player : Player,Parent : Frame,DestroyImage : BoolValue)
	local self = setmetatable({},{__index = ImageHandler})
	self.Destroy = DestroyImage
	self.Player = Player
	self.UserId = Player.UserId
	self.Image = self:GetImage()
	self.ImageParent = Parent
	self.ImageClone = PlayerImage:Clone()

	task.spawn(function()
		self:_InitImage()
	end)

	return self
end

function ImageHandler:_InitImage()
	local playerImage = self.ImageParent:FindFirstChild(self.Player.Name)

	if self.Destroy and playerImage then
		playerImage:Destroy()
	elseif not self.Destroy and not playerImage then
		self.ImageClone.Image = self.Image
		self.ImageClone.Parent = self.ImageParent
		self.ImageClone.Name = self.Player.Name
	end
end

function ImageHandler:DestroyImages(Parent : Instance)
	for _,v in pairs(Parent:GetChildren()) do
		if v and v:IsA("ImageLabel") then
			v:Destroy()
		end
	end
end

function ImageHandler:GetImage()
	local success, result = pcall(function()
		return Players:GetUserThumbnailAsync(self.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	return result
end

return ImageHandler

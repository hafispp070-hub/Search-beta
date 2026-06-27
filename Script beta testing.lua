local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Request = (syn and syn.request) or (http and http.request) or http_request or request
if not Request then
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = "Script Hub Error",
			Text = "Executor lu ga support HTTP",
			Duration = 5
		})
	end)
	return
end

pcall(function() if CoreGui:FindFirstChild("ScriptHubUI") then CoreGui.ScriptHubUI:Destroy() end end)

-- ===== CONFIG AI =====
local GROQ_API_KEY = "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" -- ISI API KEY LU DISINI
local GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
local AI_MODEL = "llama-3.3-70b-versatile" -- MODEL TERBARU GROQ, ANTI ERROR
local MAX_AI_MEMORY = 6

-- ===== SAVE SYSTEM =====
local function SaveFile(name, data)
	if writefile then pcall(function() writefile("ScriptHub_"..name..".json", HttpService:JSONEncode(data)) end) end
end

local function LoadFile(name)
	if isfile and isfile("ScriptHub_"..name..".json") then
		local s, d = pcall(function() return HttpService:JSONDecode(readfile("ScriptHub_"..name..".json")) end)
		if s then return d end
	end
	return {}
end

local Favorites = LoadFile("Favorites")
local History = LoadFile("History")
local AIChatHistory = LoadFile("AIChatHistory")

local function IsFavorited(scriptId)
	for _, v in ipairs(Favorites) do
		if v._id == scriptId then return true end
	end
	return false
end

local function ToggleFavorite(scriptData)
	for i, v in ipairs(Favorites) do
		if v._id == scriptData._id then
			table.remove(Favorites, i)
			SaveFile("Favorites", Favorites)
			return false
		end
	end
	table.insert(Favorites, scriptData)
	SaveFile("Favorites", Favorites)
	return true
end

-- Image cache
local ImageCache = {}
local function GetImageAsset(url)
	if not url or url == "" then return "rbxasset://textures/ui/GuiImagePlaceholder.png" end
	if ImageCache[url] then return ImageCache[url] end
	local success, result = pcall(function()
		if getcustomasset then
			local fileName = "hub_thumb_".. HttpService:GenerateGUID(false).. ".png"
			local imageData = game:HttpGet(url)
			writefile(fileName, imageData)
			return getcustomasset(fileName)
		else
			return url
		end
	end)
	if success then
		ImageCache[url] = result
		return result
	else
		return "rbxasset://textures/ui/GuiImagePlaceholder.png"
	end
end

-- ===== UI UTAMA =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScriptHubUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 480, 0, 380)
Main.Position = UDim2.new(0.5, -240, 0.5, -190)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.ZIndex = 1
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

-- DRAG MANUAL BUAT HP
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
	local delta = input.Position - dragStart
	Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

-- Topbar
local Topbar = Instance.new("Frame", Main)
Topbar.Size = UDim2.new(1, 0, 0, 30)
Topbar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Topbar.Active = true
Topbar.ZIndex = 2

Topbar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

Topbar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then updateDrag(input) end
end)

local Title = Instance.new("TextLabel", Topbar)
Title.Text = " Script Hub"
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.ZIndex = 3

local MinBtn = Instance.new("TextButton", Topbar)
MinBtn.Text = "–"
MinBtn.Size = UDim2.new(0, 30, 1, 0)
MinBtn.Position = UDim2.new(1, -60, 0, 0)
MinBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.BorderSizePixel = 0
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.ZIndex = 3
MinBtn.Active = true

local CloseBtn = Instance.new("TextButton", Topbar)
CloseBtn.Text = "×"
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.BorderSizePixel = 0
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.ZIndex = 3
CloseBtn.Active = true

-- Mini ball
local MiniBall = Instance.new("TextButton", ScreenGui)
MiniBall.Size = UDim2.new(0, 45, 0, 45)
MiniBall.Position = UDim2.new(0, 15, 0.5, -22)
MiniBall.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
MiniBall.Text = "Hub"
MiniBall.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBall.Font = Enum.Font.GothamBold
MiniBall.TextSize = 11
MiniBall.Visible = false
MiniBall.Active = true
MiniBall.Draggable = true
MiniBall.ZIndex = 10
Instance.new("UICorner", MiniBall).CornerRadius = UDim.new(1, 0)

-- Tabs
local TabFrame = Instance.new("Frame", Main)
TabFrame.Size = UDim2.new(1, -16, 0, 26)
TabFrame.Position = UDim2.new(0, 8, 0, 38)
TabFrame.BackgroundTransparency = 1
TabFrame.ZIndex = 4
TabFrame.Active = false

local function CreateTab(name, pos)
	local btn = Instance.new("TextButton", TabFrame)
	btn.Text = name
	btn.Size = UDim2.new(0, 80, 1, 0)
	btn.Position = UDim2.new(0, pos, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	btn.TextColor3 = Color3.fromRGB(180, 180, 180)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 11
	btn.ZIndex = 5
	btn.Active = true
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	return btn
end

local SearchTab = CreateTab("Search", 0)
local FavTab = CreateTab("Favorit", 85)
local HistoryTab = CreateTab("History", 170)
local AITab = CreateTab("AI Chat", 255)

-- Container
local ContentContainer = Instance.new("Frame", Main)
ContentContainer.Size = UDim2.new(1, -16, 1, -72)
ContentContainer.Position = UDim2.new(0, 8, 0, 68)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 3
ContentContainer.Active = false

local SearchFrame = Instance.new("Frame", ContentContainer)
SearchFrame.Size = UDim2.new(1, 0, 1, 0)
SearchFrame.BackgroundTransparency = 1
SearchFrame.ZIndex = 4
SearchFrame.Active = false

local FavFrame = Instance.new("Frame", ContentContainer)
FavFrame.Size = UDim2.new(1, 0, 1, 0)
FavFrame.BackgroundTransparency = 1
FavFrame.Visible = false
FavFrame.ZIndex = 4
FavFrame.Active = false

local HistoryFrame = Instance.new("Frame", ContentContainer)
HistoryFrame.Size = UDim2.new(1, 0, 1, 0)
HistoryFrame.BackgroundTransparency = 1
HistoryFrame.Visible = false
HistoryFrame.ZIndex = 4
HistoryFrame.Active = false

local AIFrame = Instance.new("Frame", ContentContainer)
AIFrame.Size = UDim2.new(1, 0, 1, 0)
AIFrame.BackgroundTransparency = 1
AIFrame.Visible = false
AIFrame.ZIndex = 4
AIFrame.Active = false

local ContentFrames = {
	[SearchTab] = SearchFrame,
	[FavTab] = FavFrame,
	[HistoryTab] = HistoryFrame,
	[AITab] = AIFrame
}

local function SetActiveTab(tab)
	for _, btn in ipairs(TabFrame:GetChildren()) do
		if btn:IsA("TextButton") then
			btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
			btn.TextColor3 = Color3.fromRGB(180, 180, 180)
		end
	end
	tab.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	tab.TextColor3 = Color3.fromRGB(255, 255, 255)
	
	for _, frame in pairs(ContentFrames) do
		frame.Visible = false
	end
	ContentFrames[tab].Visible = true
end

-- ===== SEARCH FRAME =====
local SearchBox = Instance.new("TextBox", SearchFrame)
SearchBox.PlaceholderText = "Cari script..."
SearchBox.Text = ""
SearchBox.Size = UDim2.new(1, -100, 0, 28)
SearchBox.Position = UDim2.new(0, 0, 0, 0)
SearchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 12
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 10
SearchBox.Active = true
SearchBox.TextEditable = true
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)

local SearchBtn = Instance.new("TextButton", SearchFrame)
SearchBtn.Text = "Cari"
SearchBtn.Size = UDim2.new(0, 90, 0, 28)
SearchBtn.Position = UDim2.new(1, -90, 0, 0)
SearchBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 12
SearchBtn.ZIndex = 10
SearchBtn.Active = true
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 6)

local ScrollFrame = Instance.new("ScrollingFrame", SearchFrame)
ScrollFrame.Size = UDim2.new(1, 0, 1, -35)
ScrollFrame.Position = UDim2.new(0, 0, 0, 35)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.ZIndex = 5
ScrollFrame.Active = false
local UIListLayout = Instance.new("UIListLayout", ScrollFrame)
UIListLayout.Padding = UDim.new(0, 6)

local FavScroll = Instance.new("ScrollingFrame", FavFrame)
FavScroll.Size = UDim2.new(1, 0, 1, 0)
FavScroll.BackgroundTransparency = 1
FavScroll.BorderSizePixel = 0
FavScroll.ScrollBarThickness = 3
FavScroll.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
FavScroll.ZIndex = 5
FavScroll.Active = false
local FavListLayout = Instance.new("UIListLayout", FavScroll)
FavListLayout.Padding = UDim.new(0, 6)

local HistoryScroll = Instance.new("ScrollingFrame", HistoryFrame)
HistoryScroll.Size = UDim2.new(1, 0, 1, 0)
HistoryScroll.BackgroundTransparency = 1
HistoryScroll.BorderSizePixel = 0
HistoryScroll.ScrollBarThickness = 3
HistoryScroll.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
HistoryScroll.ZIndex = 5
HistoryScroll.Active = false
local HistoryListLayout = Instance.new("UIListLayout", HistoryScroll)
HistoryListLayout.Padding = UDim.new(0, 6)

-- ===== POPUP KOMENTAR =====
local CommentFrame = nil
local function OpenCommentPopup(scriptId, scriptTitle, totalComments)
	if CommentFrame then CommentFrame:Destroy() end
	CommentFrame = Instance.new("Frame", ScreenGui)
	CommentFrame.Size = UDim2.new(0, 450, 0, 300)
	CommentFrame.Position = UDim2.new(0.5, -225, 0.5, -150)
	CommentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	CommentFrame.BorderSizePixel = 0
	CommentFrame.Active = true
	CommentFrame.Draggable = true
	CommentFrame.ZIndex = 20
	Instance.new("UICorner", CommentFrame).CornerRadius = UDim.new(0, 12)
	
	local Header = Instance.new("Frame", CommentFrame)
	Header.Size = UDim2.new(1, 0, 0, 35)
	Header.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	Header.ZIndex = 21
	Header.Active = true
	Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)
	
	local Title = Instance.new("TextLabel", Header)
	Title.Text = "Komentar [".. totalComments.. "]"
	Title.Size = UDim2.new(1, -40, 1, 0)
	Title.Position = UDim2.new(0, 10, 0, 0)
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.BackgroundTransparency = 1
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 12
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextTruncate = Enum.TextTruncate.AtEnd
	Title.ZIndex = 22
	
	local CloseBtn = Instance.new("TextButton", Header)
	CloseBtn.Text = "×"
	CloseBtn.Size = UDim2.new(0, 30, 0, 30)
	CloseBtn.Position = UDim2.new(1, -35, 0, 2)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 18
	CloseBtn.ZIndex = 22
	CloseBtn.Active = true
	Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
	CloseBtn.MouseButton1Click:Connect(function() CommentFrame:Destroy() end)
	
	local Scroll = Instance.new("ScrollingFrame", CommentFrame)
	Scroll.Size = UDim2.new(1, -16, 1, -45)
	Scroll.Position = UDim2.new(0, 8, 0, 40)
	Scroll.BackgroundTransparency = 1
	Scroll.BorderSizePixel = 0
	Scroll.ScrollBarThickness = 4
	Scroll.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
	Scroll.ZIndex = 21
	Scroll.Active = false
	
	local UIList = Instance.new("UIListLayout", Scroll)
	UIList.Padding = UDim.new(0, 6)
	
	local Loading = Instance.new("TextLabel", Scroll)
	Loading.Text = "Loading komentar..."
	Loading.Size = UDim2.new(1, 0, 0, 30)
	Loading.TextColor3 = Color3.fromRGB(200, 200, 200)
	Loading.BackgroundTransparency = 1
	Loading.Font = Enum.Font.Gotham
	Loading.TextSize = 11
	Loading.ZIndex = 22
	
	task.spawn(function()
		local url = "https://scriptblox.com/api/comment/".. scriptId.. "?page=1&max=20"
		local success, res = pcall(function()
			return Request({Url = url, Method = "GET"})
		end)
		Loading:Destroy()
		if success and res.StatusCode == 200 then
			local data = HttpService:JSONDecode(res.Body)
			local comments = data.result.comments or {}
			if #comments == 0 then
				local NoComment = Instance.new("TextLabel", Scroll)
				NoComment.Text = "Belum ada komentar"
				NoComment.Size = UDim2.new(1, 0, 0, 40)
				NoComment.TextColor3 = Color3.fromRGB(150, 150, 150)
				NoComment.BackgroundTransparency = 1
				NoComment.Font = Enum.Font.Gotham
				NoComment.TextSize = 11
				NoComment.ZIndex = 22
			else
				for i, c in ipairs(comments) do
					local CFrame = Instance.new("Frame", Scroll)
					CFrame.Size = UDim2.new(1, -8, 0, 0)
					CFrame.AutomaticSize = Enum.AutomaticSize.Y
					CFrame.BackgroundColor3 = Color3.fromRGB(40, 40)
					CFrame.ZIndex = 22
					CFrame.Active = false
					Instance.new("UICorner", CFrame).CornerRadius = UDim.new(0, 6)
					local pad = Instance.new("UIPadding", CFrame)
					pad.PaddingLeft = UDim.new(0, 6)
					pad.PaddingRight = UDim.new(0, 6)
					pad.PaddingTop = UDim.new(0, 5)
					pad.PaddingBottom = UDim.new(0, 5)
					
					local User = Instance.new("TextLabel", CFrame)
					User.Text = "@".. (c.commentBy.username or "anon")
					User.Size = UDim2.new(1, 0, 0, 16)
					User.TextColor3 = Color3.fromRGB(88, 166, 255)
					User.Font = Enum.Font.GothamBold
					User.TextSize = 11
					User.TextXAlignment = Enum.TextXAlignment.Left
					User.BackgroundTransparency = 1
					User.ZIndex = 23
					
					local Text = Instance.new("TextLabel", CFrame)
					Text.Text = c.text or ""
					Text.Size = UDim2.new(1, 0, 0, 0)
					Text.AutomaticSize = Enum.AutomaticSize.Y
					Text.Position = UDim2.new(0, 0, 0, 18)
					Text.TextColor3 = Color3.fromRGB(220, 220, 220)
					Text.Font = Enum.Font.Gotham
					Text.TextSize = 10
					Text.TextWrapped = true
					Text.TextXAlignment = Enum.TextXAlignment.Left
					Text.BackgroundTransparency = 1
					Text.ZIndex = 23
				end
			end
			Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 10)
		end
	end)
end

-- ===== FUNGSI BIKIN CARD SCRIPT + TULISAN GAME =====
local function CreateScriptCard(data, parent)
	local Card = Instance.new("Frame", parent)
	Card.Size = UDim2.new(1, -8, 0, 85) -- DITINGGIIN DIKIT BUAT GAME
	Card.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	Card.ZIndex = 6
	Card.Active = false
	Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
	
	local Thumb = Instance.new("ImageLabel", Card)
	Thumb.Size = UDim2.new(0, 65, 0, 65)
	Thumb.Position = UDim2.new(0, 8, 0, 10)
	Thumb.BackgroundTransparency = 1
	Thumb.Image = GetImageAsset(data.image)
	Thumb.ZIndex = 7
	Instance.new("UICorner", Thumb).CornerRadius = UDim.new(0, 6)
	
	local Title = Instance.new("TextLabel", Card)
	Title.Text = data.title or "No Title"
	Title.Size = UDim2.new(1, -210, 0, 18)
	Title.Position = UDim2.new(0, 80, 0, 8)
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 11
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.BackgroundTransparency = 1
	Title.TextTruncate = Enum.TextTruncate.AtEnd
	Title.ZIndex = 7
	
	-- TULISAN GAME BARU
	local GameLabel = Instance.new("TextLabel", Card)
	GameLabel.Text = "Game: ".. (data.game and data.game.name or "Universal")
	GameLabel.Size = UDim2.new(1, -210, 0, 14)
	GameLabel.Position = UDim2.new(0, 80, 0, 26)
	GameLabel.TextColor3 = Color3.fromRGB(88, 166, 255)
	GameLabel.Font = Enum.Font.GothamBold
	GameLabel.TextSize = 9
	GameLabel.TextXAlignment = Enum.TextXAlignment.Left
	GameLabel.BackgroundTransparency = 1
	GameLabel.ZIndex = 7
	
	local Info = Instance.new("TextLabel", Card)
	Info.Text = "by ".. (data.owner or "Unknown").. " | Views: ".. (data.views or 0)
	Info.Size = UDim2.new(1, -210, 0, 14)
	Info.Position = UDim2.new(0, 80, 0, 40)
	Info.TextColor3 = Color3.fromRGB(180, 180, 180)
	Info.Font = Enum.Font.Gotham
	Info.TextSize = 9
	Info.TextXAlignment = Enum.TextXAlignment.Left
	Info.BackgroundTransparency = 1
	Info.ZIndex = 7
	
	local Desc = Instance.new("TextLabel", Card)
	Desc.Text = data.description or "No description"
	Desc.Size = UDim2.new(1, -210, 0, 28)
	Desc.Position = UDim2.new(0, 80, 0, 54)
	Desc.TextColor3 = Color3.fromRGB(150, 150, 150)
	Desc.Font = Enum.Font.Gotham
	Desc.TextSize = 9
	Desc.TextXAlignment = Enum.TextXAlignment.Left
	Desc.TextYAlignment = Enum.TextYAlignment.Top
	Desc.TextWrapped = true
	Desc.BackgroundTransparency = 1
	Desc.ZIndex = 7
	
	local GetBtn = Instance.new("TextButton", Card)
	GetBtn.Text = "GET"
	GetBtn.Size = UDim2.new(0, 50, 0, 22)
	GetBtn.Position = UDim2.new(1, -190, 0, 8)
	GetBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	GetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	GetBtn.Font = Enum.Font.GothamBold
	GetBtn.TextSize = 10
	GetBtn.ZIndex = 7
	GetBtn.Active = true
	Instance.new("UICorner", GetBtn).CornerRadius = UDim.new(0, 6)
	
	local ExecBtn = Instance.new("TextButton", Card)
	ExecBtn.Text = "EXEC"
	ExecBtn.Size = UDim2.new(0, 50, 0, 22)
	ExecBtn.Position = UDim2.new(1, -135, 0, 8)
	ExecBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
	ExecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ExecBtn.Font = Enum.Font.GothamBold
	ExecBtn.TextSize = 10
	ExecBtn.ZIndex = 7
	ExecBtn.Active = true
	Instance.new("UICorner", ExecBtn).CornerRadius = UDim.new(0, 6)
	
	local FavBtn = Instance.new("TextButton", Card)
	FavBtn.Text = IsFavorited(data._id) and "★" or "☆"
	FavBtn.Size = UDim2.new(0, 22, 0, 22)
	FavBtn.Position = UDim2.new(1, -80, 0, 8)
	FavBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	FavBtn.TextColor3 = IsFavorited(data._id) and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(200, 200, 200)
	FavBtn.Font = Enum.Font.GothamBold
	FavBtn.TextSize = 14
	FavBtn.ZIndex = 7
	FavBtn.Active = true
	Instance.new("UICorner", FavBtn).CornerRadius = UDim.new(0, 6)
	
	local CommentBtn = Instance.new("TextButton", Card)
	CommentBtn.Text = "Chat ".. (data.commentCount or 0)
	CommentBtn.Size = UDim2.new(0, 70, 0, 22)
	CommentBtn.Position = UDim2.new(1, -190, 0, 38)
	CommentBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	CommentBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	CommentBtn.Font = Enum.Font.Gotham
	CommentBtn.TextSize = 9
	CommentBtn.ZIndex = 7
	CommentBtn.Active = true
	Instance.new("UICorner", CommentBtn).CornerRadius = UDim.new(0, 6)
	
	GetBtn.MouseButton1Click:Connect(function()
		setclipboard(data.script or "-- No script found")
		GetBtn.Text = "COPIED!"
		task.wait(1)
		GetBtn.Text = "GET"
	end)
	
	ExecBtn.MouseButton1Click:Connect(function()
		local s, e = pcall(function() loadstring(data.script or "")() end)
		ExecBtn.Text = s and "DONE!" or "ERROR"
		task.wait(1)
		ExecBtn.Text = "EXEC"
		table.insert(History, 1, data)
		if #History > 20 then table.remove(History) end
		SaveFile("History", History)
	end)
	
	FavBtn.MouseButton1Click:Connect(function()
		local isFav = ToggleFavorite(data)
		FavBtn.Text = isFav and "★" or "☆"
		FavBtn.TextColor3 = isFav and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(200, 200, 200)
	end)
	
	CommentBtn.MouseButton1Click:Connect(function()
		OpenCommentPopup(data._id, data.title, data.commentCount or 0)
	end)
end

-- ===== FUNGSI SEARCH SCRIPTBLOX =====
local function SearchScriptBlox(query)
	for _, v in pairs(ScrollFrame:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end
	
	local Loading = Instance.new("TextLabel", ScrollFrame)
	Loading.Text = "Nyari script..."
	Loading.Size = UDim2.new(1, 0, 0, 40)
	Loading.TextColor3 = Color3.fromRGB(200, 200, 200)
	Loading.BackgroundTransparency = 1
	Loading.Font = Enum.Font.Gotham
	Loading.TextSize = 13
	Loading.ZIndex = 6
	
	local url = "https://scriptblox.com/api/script/search?q=".. HttpService:UrlEncode(query).. "&max=20"
	
	local success, res = pcall(function()
		return Request({Url = url, Method = "GET"})
	end)
	
	Loading:Destroy()
	
	if success and res.StatusCode == 200 then
		local data = HttpService:JSONDecode(res.Body)
		local scripts = data.result.scripts or {}
		
		if #scripts == 0 then
			local Empty = Instance.new("TextLabel", ScrollFrame)
			Empty.Text = "Gak ketemu script: ".. query
			Empty.Size = UDim2.new(1, 0, 0, 40)
			Empty.TextColor3 = Color3.fromRGB(200, 100, 100)
			Empty.BackgroundTransparency = 1
			Empty.Font = Enum.Font.Gotham
			Empty.TextSize = 13
			Empty.ZIndex = 6
		else
			for _, script in ipairs(scripts) do
				CreateScriptCard(script, ScrollFrame)
			end
		end
		ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
	else
		local Error = Instance.new("TextLabel", ScrollFrame)
		Error.Text = "Error: ScriptBlox down / cek koneksi"
		Error.Size = UDim2.new(1, 0, 0, 40)
		Error.TextColor3 = Color3.fromRGB(200, 100, 100)
		Error.BackgroundTransparency = 1
		Error.Font = Enum.Font.Gotham
		Error.TextSize = 13
		Error.ZIndex = 6
	end
end

SearchBtn.MouseButton1Click:Connect(function()
	if SearchBox.Text ~= "" then
		SearchScriptBlox(SearchBox.Text)
	end
end)

SearchBox.FocusLost:Connect(function(enter)
	if enter and SearchBox.Text ~= "" then
		SearchScriptBlox(SearchBox.Text)
	end
end)

-- ===== FUNGSI LOAD FAVORIT - FIX SPAM =====
function LoadFavorites()
	for _, v in pairs(FavScroll:GetChildren()) do
		if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end
	end
	if #Favorites == 0 then
		local Empty = Instance.new("TextLabel", FavScroll)
		Empty.Text = "Belum ada favorit"
		Empty.Size = UDim2.new(1, 0, 0, 40)
		Empty.TextColor3 = Color3.fromRGB(150, 150, 150)
		Empty.BackgroundTransparency = 1
		Empty.Font = Enum.Font.Gotham
		Empty.TextSize = 13
		Empty.ZIndex = 6
	else
		for _, script in ipairs(Favorites) do
			CreateScriptCard(script, FavScroll)
		end
	end
	FavScroll.CanvasSize = UDim2.new(0, 0, 0, FavListLayout.AbsoluteContentSize.Y + 10)
end

-- ===== FUNGSI LOAD HISTORY - FIX SPAM =====
function LoadHistory()
	for _, v in pairs(HistoryScroll:GetChildren()) do
		if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end
	end
	if #History == 0 then
		local Empty = Instance.new("TextLabel", HistoryScroll)
		Empty.Text = "Belum ada history"
		Empty.Size = UDim2.new(1, 0, 0, 40)
		Empty.TextColor3 = Color3.fromRGB(150, 150)
		Empty.BackgroundTransparency = 1
		Empty.Font = Enum.Font.Gotham
		Empty.TextSize = 13
		Empty.ZIndex = 6
	else
		for _, script in ipairs(History) do
			CreateScriptCard(script, HistoryScroll)
		end
	end
	HistoryScroll.CanvasSize = UDim2.new(0, 0, 0, HistoryListLayout.AbsoluteContentSize.Y + 10)
end

-- ===== ISI FRAME AI CHAT =====
local AIChatScroll = Instance.new("ScrollingFrame", AIFrame)
AIChatScroll.Size = UDim2.new(1, 0, 1, -40)
AIChatScroll.Position = UDim2.new(0, 0, 0, 0)
AIChatScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
AIChatScroll.BorderSizePixel = 0
AIChatScroll.ScrollBarThickness = 3
AIChatScroll.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
AIChatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
AIChatScroll.ZIndex = 5
AIChatScroll.Active = false
Instance.new("UICorner", AIChatScroll).CornerRadius = UDim.new(0, 6)

local AIListLayout = Instance.new("UIListLayout", AIChatScroll)
AIListLayout.Padding = UDim.new(0, 6)
AIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
local padding = Instance.new("UIPadding", AIChatScroll)
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.PaddingLeft = UDim.new(0, 6)
padding.PaddingRight = UDim.new(0, 6)

local AIInputFrame = Instance.new("Frame", AIFrame)
AIInputFrame.Size = UDim2.new(1, 0, 0, 32)
AIInputFrame.Position = UDim2.new(0, 0, 1, -32)
AIInputFrame.BackgroundTransparency = 1
AIInputFrame.ZIndex = 5
AIInputFrame.Active = false

local UploadBtn = Instance.new("TextButton", AIInputFrame)
UploadBtn.Text = "+"
UploadBtn.Size = UDim2.new(0, 32, 1, 0)
UploadBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
UploadBtn.TextColor3 = Color3.fromRGB(255, 255)
UploadBtn.Font = Enum.Font.GothamBold
UploadBtn.TextSize = 18
UploadBtn.ZIndex = 6
UploadBtn.Active = true
Instance.new("UICorner", UploadBtn).CornerRadius = UDim.new(0, 6)

local AITextBox = Instance.new("TextBox", AIInputFrame)
AITextBox.PlaceholderText = "Tanya AI / Upload file..."
AITextBox.Text = ""
AITextBox.Size = UDim2.new(1, -107, 1, 0)
AITextBox.Position = UDim2.new(0, 37, 0, 0)
AITextBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
AITextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
AITextBox.Font = Enum.Font.Gotham
AITextBox.TextSize = 12
AITextBox.ClearTextOnFocus = false
AITextBox.ZIndex = 6
AITextBox.Active = true
AITextBox.Selectable = true
AITextBox.TextEditable = true
Instance.new("UICorner", AITextBox).CornerRadius = UDim.new(0, 6)

local AISendBtn = Instance.new("TextButton", AIInputFrame)
AISendBtn.Text = "Send"
AISendBtn.Size = UDim2.new(0, 65, 1, 0)
AISendBtn.Position = UDim2.new(1, -65, 0, 0)
AISendBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
AISendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AISendBtn.Font = Enum.Font.GothamBold
AISendBtn.TextSize = 12
AISendBtn.ZIndex = 6
AISendBtn.Active = true
Instance.new("UICorner", AISendBtn).CornerRadius = UDim.new(0, 6)

-- ===== FITUR WEB SEARCH =====
local function WebSearch(query)
	local url = "https://api.duckduckgo.com/?q=".. HttpService:UrlEncode(query).. "&format=json&no_html=1&skip_disambig=1"
	local success, res = pcall(function()
		return Request({Url = url, Method = "GET"})
	end)
	
	if success and res.StatusCode == 200 then
		local data = HttpService:JSONDecode(res.Body)
		local hasil = ""
		if data.AbstractText and data.AbstractText ~= "" then
			hasil = data.AbstractText
			if data.AbstractSource then
				hasil = hasil.. "\nSumber: ".. data.AbstractSource
			end
		elseif data.RelatedTopics and #data.RelatedTopics > 0 then
			for i = 1, math.min(3, #data.RelatedTopics) do
				if data.RelatedTopics[i].Text then
					hasil = hasil.. "- ".. data.RelatedTopics[i].Text.. "\n"
				end
			end
		else
			hasil = "Gak nemu info real-time tentang '".. query.."'. Coba keyword lain."
		end
		return hasil
	end
	return "Gagal search web. Cek koneksi internet lu."
end

-- ===== CODEBLOCK HITAM + TOMBOL SALIN/RUN =====
local function CreateCodeBlock(parent, code, lang)
	local CodeFrame = Instance.new("Frame", parent)
	CodeFrame.Size = UDim2.new(1, -16, 0, 0)
	CodeFrame.AutomaticSize = Enum.AutomaticSize.Y
	CodeFrame.BackgroundColor3 = Color3.fromRGB(13, 17, 23) -- HITAM PEKAT
	CodeFrame.BorderSizePixel = 0
	CodeFrame.ZIndex = 7
	CodeFrame.Active = false
	Instance.new("UICorner", CodeFrame).CornerRadius = UDim.new(0, 6)
	
	local LangLabel = Instance.new("TextLabel", CodeFrame)
	LangLabel.Text = string.upper(lang == "" and "TEXT" or lang)
	LangLabel.Size = UDim2.new(0, 50, 0, 18)
	LangLabel.Position = UDim2.new(1, -54, 0, 4)
	LangLabel.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
	LangLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	LangLabel.Font = Enum.Font.Code
	LangLabel.TextSize = 10
	LangLabel.ZIndex = 8
	Instance.new("UICorner", LangLabel).CornerRadius = UDim.new(0, 4)
	
	-- PAKE TEXTBOX BIAR BISA DI SELECT + SALIN MANUAL
	local CodeText = Instance.new("TextBox", CodeFrame)
	CodeText.Text = code
	CodeText.Size = UDim2.new(1, 0, 0, 0)
	CodeText.AutomaticSize = Enum.AutomaticSize.Y
	CodeText.TextColor3 = Color3.fromRGB(201, 209, 217)
	CodeText.Font = Enum.Font.Code
	CodeText.TextSize = 12
	CodeText.TextXAlignment = Enum.TextXAlignment.Left
	CodeText.TextYAlignment = Enum.TextYAlignment.Top
	CodeText.BackgroundTransparency = 1
	CodeText.TextWrapped = false
	CodeText.ClearTextOnFocus = false
	CodeText.TextEditable = false -- BIAR GABISA DIEDIT TAPI BISA DISELECT
	CodeText.ZIndex = 8
	CodeText.Active = true
	CodeText.Selectable = true
	
	local pad = Instance.new("UIPadding", CodeText)
	pad.PaddingTop = UDim.new(0, 26)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	
	if lang == "lua" or lang == "luau" or lang == "" then
		local BtnFrame = Instance.new("Frame", CodeFrame)
		BtnFrame.Size = UDim2.new(1, -16, 0, 24)
		BtnFrame.Position = UDim2.new(0, 8, 1, -28)
		BtnFrame.BackgroundTransparency = 1
		BtnFrame.ZIndex = 8
		BtnFrame.Active = false
		
		local RunBtn = Instance.new("TextButton", BtnFrame)
		RunBtn.Text = "RUN"
		RunBtn.Size = UDim2.new(0, 60, 1, 0)
		RunBtn.BackgroundColor3 = Color3.fromRGB(35, 134, 54)
		RunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		RunBtn.Font = Enum.Font.GothamBold
		RunBtn.TextSize = 11
		RunBtn.ZIndex = 9
		RunBtn.Active = true
		Instance.new("UICorner", RunBtn).CornerRadius = UDim.new(0, 6)
		
		RunBtn.MouseButton1Click:Connect(function()
			local s,e = pcall(function() loadstring(code)() end)
			RunBtn.Text = s and "DONE!" or "ERROR"
			RunBtn.BackgroundColor3 = s and Color3.fromRGB(35, 134, 54) or Color3.fromRGB(200, 50, 50)
			task.wait(1)
			RunBtn.Text = "RUN"
			RunBtn.BackgroundColor3 = Color3.fromRGB(35, 134, 54)
		end)
		
		local CopyBtn = Instance.new("TextButton", BtnFrame)
		CopyBtn.Text = "SALIN"
		CopyBtn.Size = UDim2.new(0, 60, 1, 0)
		CopyBtn.Position = UDim2.new(0, 66, 0, 0)
		CopyBtn.BackgroundColor3 = Color3.fromRGB(31, 111, 235)
		CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		CopyBtn.Font = Enum.Font.GothamBold
		CopyBtn.TextSize = 11
		CopyBtn.ZIndex = 9
		CopyBtn.Active = true
		Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)
		
		CopyBtn.MouseButton1Click:Connect(function()
			setclipboard(code)
			CopyBtn.Text = "COPIED!"
			task.wait(1) CopyBtn.Text = "SALIN"
		end)
		pad.PaddingBottom = UDim.new(0, 32)
	else
		local CopyBtn = Instance.new("TextButton", CodeFrame)
		CopyBtn.Text = "SALIN"
		CopyBtn.Size = UDim2.new(0, 60, 0, 22)
		CopyBtn.Position = UDim2.new(1, -68, 1, -26)
		CopyBtn.BackgroundColor3 = Color3.fromRGB(31, 111, 235)
		CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		CopyBtn.Font = Enum.Font.GothamBold
		CopyBtn.TextSize = 11
		CopyBtn.ZIndex = 9
		CopyBtn.Active = true
		Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)
		
		CopyBtn.MouseButton1Click:Connect(function()
			setclipboard(code)
			CopyBtn.Text = "COPIED!"
			task.wait(1) CopyBtn.Text = "SALIN"
		end)
		pad.PaddingBottom = UDim.new(0, 32)
	end
	return CodeFrame
end

local CurrentUpload = nil

local function AddChatBubble(text, isUser, imageAsset)
	local bubble = Instance.new("Frame", AIChatScroll)
	bubble.Size = UDim2.new(0.85, 0, 0, 0)
	bubble.AutomaticSize = Enum.AutomaticSize.Y
	bubble.BackgroundColor3 = isUser and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(45, 45, 50)
	bubble.Position = isUser and UDim2.new(0.15, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
	bubble.ZIndex = 6
	bubble.Active = false
	Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 8)
	
	local list = Instance.new("UIListLayout", bubble)
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	
	local pad = Instance.new("UIPadding", bubble)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	
	if imageAsset then
		local ImageLabel = Instance.new("ImageLabel", bubble)
		ImageLabel.Size = UDim2.new(1, 0, 0, 200)
		ImageLabel.BackgroundTransparency = 1
		ImageLabel.Image = imageAsset
		ImageLabel.ScaleType = Enum.ScaleType.Fit
		ImageLabel.ZIndex = 7
		Instance.new("UICorner", ImageLabel).CornerRadius = UDim.new(0, 6)
	end
	
	local lastEnd = 1
	local hasCode = false
	
	for codeStart, lang, code, codeEnd in string.gmatch(text, "()```([%w]*)\n?(.-)\n?```()") do
		hasCode = true
		if codeStart > lastEnd then
			local normalText = string.sub(text, lastEnd, codeStart - 1)
			if normalText:match("%S") then
				local label = Instance.new("TextLabel", bubble)
				label.Text = normalText:gsub("^%s+", ""):gsub("%s+$", "")
				label.Size = UDim2.new(1, 0, 0, 0)
				label.AutomaticSize = Enum.AutomaticSize.Y
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
				label.Font = Enum.Font.Gotham
				label.TextSize = 12
				label.TextWrapped = true
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.BackgroundTransparency = 1
				label.ZIndex = 7
			end
		end
		
		CreateCodeBlock(bubble, code:gsub("^%s+", ""):gsub("%s+$", ""), lang)
		lastEnd = codeEnd
	end
	
	if lastEnd <= #text then
		local remainingText = string.sub(text, lastEnd)
		if remainingText:match("%S") then
			local label = Instance.new("TextLabel", bubble)
			label.Text = remainingText:gsub("^%s+", ""):gsub("%s+$", "")
			label.Size = UDim2.new(1, 0, 0, 0)
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.Font = Enum.Font.Gotham
			label.TextSize = 12
			label.TextWrapped = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.BackgroundTransparency = 1
			label.ZIndex = 7
		end
	end
	
	if not hasCode and not imageAsset then
		local label = Instance.new("TextLabel", bubble)
		label.Text = text
		label.Size = UDim2.new(1, 0, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.Gotham
		label.TextSize = 12
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1
		label.ZIndex = 7
	end
	
	task.wait()
	AIChatScroll.CanvasSize = UDim2.new(0, 0, 0, AIListLayout.AbsoluteContentSize.Y + 12)
	AIChatScroll.CanvasPosition = Vector2.new(0, AIChatScroll.CanvasSize.Y.Offset)
end

UploadBtn.MouseButton1Click:Connect(function()
	if not getcustomasset or not readfile then
		AddChatBubble("Executor lu ga support upload file. Pake Delta/KRNL/Synapse.", false)
		return
	end
	AddChatBubble("Paste path file lu di chat.\nContoh: /storage/emulated/0/Download/script.lua\nAtau paste link gambar langsung", false)
	CurrentUpload = "WAITING_FILE"
end)

local function AskAI(prompt)
	if GROQ_API_KEY == "" then
		AddChatBubble("❌ ERROR: API Key kosong!\n\n1. Buka console.groq.com\n2. Buat API Key gratis\n3. Paste di baris 11 script ini\nGROQ_API_KEY = \"gsk_xxx\"", false)
		return
	end
	
	AddChatBubble(prompt, true)
	AITextBox.Text = ""
	
	local thinking = Instance.new("TextLabel", AIChatScroll)
	thinking.Text = "AI lagi mikir..."
	thinking.Size = UDim2.new(0.85, 0, 0, 28)
	thinking.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	thinking.TextColor3 = Color3.fromRGB(150, 150, 150)
	thinking.Font = Enum.Font.Gotham
	thinking.TextSize = 11
	thinking.ZIndex = 7
	Instance.new("UICorner", thinking).CornerRadius = UDim.new(0, 8)
	
	local finalPrompt = prompt
	local lprompt = string.lower(prompt)
	if string.match(lprompt, "siapa") or string.match(lprompt, "kapan") or string.match(lprompt, "dimana") or string.match(lprompt, "2024") or string.match(lprompt, "2025") or string.match(lprompt, "2026") or string.match(lprompt, "terbaru") or string.match(lprompt, "sekarang") or string.match(lprompt, "presiden") or string.match(lprompt, "harga") or string.match(lprompt, "script") or string.match(lprompt, "game") then
		thinking.Text = "Browsing info terbaru..."
		local searchResult = WebSearch(prompt)
		finalPrompt = "DATA TERBARU DARI INTERNET:\n"..searchResult.."\n\nPERTANYAAN: ".. prompt.. "\n\nJAWAB PAKE DATA DI ATAS. JANGAN HALU. Kalo ada kode, pake ```lua"
	end
	
	local messages = {
		{role = "system", content = "Kamu asisten AI coding Roblox Lua. Tanggal sekarang: ".. os.date("%d %B %Y")..". WAJIB jawab berdasarkan info dari internet yang dikasih. Jawab singkat bahasa gaul. Kalo user minta coding, WAJIB pake format ```lua"}
	}
	
	for _, msg in ipairs(AIChatHistory) do
		table.insert(messages, msg)
	end
	
	table.insert(messages, {role = "user", content = finalPrompt})
	
	local headers = {
		["Content-Type"] = "application/json",
		["Authorization"] = "Bearer ".. GROQ_API_KEY
	}
	
	local data = {
		model = AI_MODEL,
		messages = messages,
		max_tokens = 800,
		temperature = 0.7
	}
	
	local success, response = pcall(function()
		return Request({
			Url = GROQ_API_URL,
			Method = "POST",
			Headers = headers,
			Body = HttpService:JSONEncode(data)
		})
	end)
	
	thinking:Destroy()
	
	if success and response.StatusCode == 200 then
		local decoded = HttpService:JSONDecode(response.Body)
		local reply = decoded.choices[1].message.content
		AddChatBubble(reply, false)
		
		table.insert(AIChatHistory, {role = "user", content = prompt})
		table.insert(AIChatHistory, {role = "assistant", content = reply})
		
		if #AIChatHistory > MAX_AI_MEMORY * 2 then
			table.remove(AIChatHistory, 1)
			table.remove(AIChatHistory, 1)
		end
		SaveFile("AIChatHistory", AIChatHistory)
	else
		local errMsg = "❌ AI ERROR:\n"
		if not success then
			errMsg = errMsg.. "Request gagal: ".. tostring(response)
		elseif response.StatusCode == 401 then
			errMsg = errMsg.. "API Key salah/kadaluarsa!\nCek di console.groq.com"
		elseif response.StatusCode == 404 then
			errMsg = errMsg.. "Model "..AI_MODEL.." ga ketemu!\nUdah dihapus Groq"
		elseif response.StatusCode == 429 then
			errMsg = errMsg.. "Rate limit! Kebanyakan request\nTunggu 1 menit"
		else
			errMsg = errMsg.. "Status: ".. response.StatusCode.. "\n".. response.StatusMessage
		end
		AddChatBubble(errMsg, false)
	end
	CurrentUpload = nil
end

AISendBtn.MouseButton1Click:Connect(function()
	if AITextBox.Text ~= "" then
		if CurrentUpload == "WAITING_FILE" then
			local path = AITextBox.Text
			if isfile and isfile(path) then
				local content = readfile(path)
				AskAI("Tolong jelasin/edit file ini:\n\n```lua\n"..content.."\n```")
			elseif string.match(path, "http") then
				AddChatBubble("Jelasin gambar ini:", true, path)
				AskAI("Jelasin gambar ini")
			else
				AddChatBubble("File ga ketemu di: "..path, false)
			end
			CurrentUpload = nil
		else
			AskAI(AITextBox.Text)
		end
	end
end)

AITextBox.FocusLost:Connect(function(enter)
	if enter and AITextBox.Text ~= "" then
		if CurrentUpload == "WAITING_FILE" then
			local path = AITextBox.Text
			if isfile and isfile(path) then
				local content = readfile(path)
				AskAI("Tolong jelasin/edit file ini:\n\n```lua\n"..content.."\n```")
			elseif string.match(path, "http") then
				AddChatBubble("Jelasin gambar ini:", true, path)
				AskAI("Jelasin gambar ini")
			else
				AddChatBubble("File ga ketemu di: "..path, false)
			end
			CurrentUpload = nil
		else
			AskAI(AITextBox.Text)
		end
	end
end)

for _, msg in ipairs(AIChatHistory) do
	AddChatBubble(msg.content, msg.role == "user")
end

SearchTab.MouseButton1Click:Connect(function() SetActiveTab(SearchTab) end)
FavTab.MouseButton1Click:Connect(function() SetActiveTab(FavTab) LoadFavorites() end)
HistoryTab.MouseButton1Click:Connect(function() SetActiveTab(HistoryTab) LoadHistory() end)
AITab.MouseButton1Click:Connect(function() SetActiveTab(AITab) end)

MinBtn.MouseButton1Click:Connect(function()
	Main.Visible = false
	MiniBall.Visible = true
end)

MiniBall.MouseButton1Click:Connect(function()
	Main.Visible = true
	MiniBall.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

LoadFavorites()
LoadHistory()
SetActiveTab(SearchTab)

-- ===== FIX TEXTBOX + DRAG + BUG SPAM =====
task.wait(1)
SearchBox.Selectable = true
SearchBox.TextEditable = true
SearchBox.Active = true
SearchBox:CaptureFocus()
SearchBox:ReleaseFocus()

SearchBtn.Active = true
AISendBtn.Active = true
AITextBox.Selectable = true
AITextBox.TextEditable = true
AITextBox.Active = true

print("✅ Script Hub v1.3.5 loaded! AI FIXED + Game Label + Anti Spam + Drag Jalan")>
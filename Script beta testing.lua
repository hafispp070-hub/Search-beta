local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Request = (syn and syn.request) or (http and http.request) or http_request or request
if not Request then
	game.StarterGui:SetCore("SendNotification", {
		Title = "Zazz Hub Error",
		Text = "Executor lu ga support HTTP",
		Duration = 5
	})
	return
end

pcall(function() if CoreGui:FindFirstChild("ScriptbloxUI") then CoreGui.ScriptbloxUI:Destroy() end end)

-- ===== CONFIG AI =====
local GROQ_API_KEY = "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" -- GANTI INI
local GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
local AI_MODEL = "llama-3.1-8b-instant"
local MAX_AI_MEMORY = 6

-- ===== SAVE SYSTEM =====
local function SaveFile(name, data)
	if writefile then pcall(function() writefile("Scriptblox_"..name..".json", HttpService:JSONEncode(data)) end) end
end

local function LoadFile(name)
	if isfile and isfile("Scriptblox_"..name..".json") then
		local s, d = pcall(function() return HttpService:JSONDecode(readfile("Scriptblox_"..name..".json")) end)
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
			local fileName = "zazz_thumb_".. HttpService:GenerateGUID(false).. ".png"
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
ScreenGui.Name = "ScriptbloxUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 480, 0, 350)
Main.Position = UDim2.new(0.5, -240, 0.5, -175)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

-- Topbar
local Topbar = Instance.new("Frame", Main)
Topbar.Size = UDim2.new(1, 0, 0, 30)
Topbar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)

local Title = Instance.new("TextLabel", Topbar)
Title.Text = " Zazz Hub"
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13

local MinBtn = Instance.new("TextButton", Topbar)
MinBtn.Text = "–"
MinBtn.Size = UDim2.new(0, 30, 1, 0)
MinBtn.Position = UDim2.new(1, -60, 0, 0)
MinBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.BorderSizePixel = 0
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18

local CloseBtn = Instance.new("TextButton", Topbar)
CloseBtn.Text = "×"
CloseBtn.Size = UDim2.new(0, 30, 1, 0)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.BorderSizePixel = 0
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18

-- Mini ball
local MiniBall = Instance.new("TextButton", ScreenGui)
MiniBall.Size = UDim2.new(0, 45, 0, 45)
MiniBall.Position = UDim2.new(0, 15, 0.5, -22)
MiniBall.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
MiniBall.Text = "Zazz"
MiniBall.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBall.Font = Enum.Font.GothamBold
MiniBall.TextSize = 11
MiniBall.Visible = false
MiniBall.Active = true
MiniBall.Draggable = true
Instance.new("UICorner", MiniBall).CornerRadius = UDim.new(1, 0)

-- Tabs
local TabFrame = Instance.new("Frame", Main)
TabFrame.Size = UDim2.new(1, -16, 0, 26)
TabFrame.Position = UDim2.new(0, 8, 0, 38)
TabFrame.BackgroundTransparency = 1

local function CreateTab(name, pos)
	local btn = Instance.new("TextButton", TabFrame)
	btn.Text = name
	btn.Size = UDim2.new(0, 80, 1, 0)
	btn.Position = UDim2.new(0, pos, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	btn.TextColor3 = Color3.fromRGB(180, 180, 180)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 11
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

local SearchFrame = Instance.new("Frame", ContentContainer)
SearchFrame.Size = UDim2.new(1, 0, 1, 0)
SearchFrame.BackgroundTransparency = 1

local FavFrame = Instance.new("Frame", ContentContainer)
FavFrame.Size = UDim2.new(1, 0, 1, 0)
FavFrame.BackgroundTransparency = 1
FavFrame.Visible = false

local HistoryFrame = Instance.new("Frame", ContentContainer)
HistoryFrame.Size = UDim2.new(1, 0, 1, 0)
HistoryFrame.BackgroundTransparency = 1
HistoryFrame.Visible = false

local AIFrame = Instance.new("Frame", ContentContainer)
AIFrame.Size = UDim2.new(1, 0, 1, 0)
AIFrame.BackgroundTransparency = 1
AIFrame.Visible = false

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
SearchBox.Size = UDim2.new(1, -100, 0, 28)
SearchBox.Position = UDim2.new(0, 0, 0, 0)
SearchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 12
SearchBox.ClearTextOnFocus = false
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)

local SearchBtn = Instance.new("TextButton", SearchFrame)
SearchBtn.Text = "Cari"
SearchBtn.Size = UDim2.new(0, 90, 0, 28)
SearchBtn.Position = UDim2.new(1, -90, 0, 0)
SearchBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 12
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 6)

local ScrollFrame = Instance.new("ScrollingFrame", SearchFrame)
ScrollFrame.Size = UDim2.new(1, 0, 1, -35)
ScrollFrame.Position = UDim2.new(0, 0, 0, 35)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
local UIListLayout = Instance.new("UIListLayout", ScrollFrame)
UIListLayout.Padding = UDim.new(0, 6)

-- Scroll buat Favorit & History
local FavScroll = ScrollFrame:Clone()
FavScroll.Parent = FavFrame
local FavListLayout = FavScroll:FindFirstChild("UIListLayout")

local HistoryScroll = ScrollFrame:Clone()
HistoryScroll.Parent = HistoryFrame
local HistoryListLayout = HistoryScroll:FindFirstChild("UIListLayout")

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
	Instance.new("UICorner", CommentFrame).CornerRadius = UDim.new(0, 12)
	
	local Header = Instance.new("Frame", CommentFrame)
	Header.Size = UDim2.new(1, 0, 0, 35)
	Header.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
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
	
	local CloseBtn = Instance.new("TextButton", Header)
	CloseBtn.Text = "×"
	CloseBtn.Size = UDim2.new(0, 30, 0, 30)
	CloseBtn.Position = UDim2.new(1, -35, 0, 2)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 18
	Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
	CloseBtn.MouseButton1Click:Connect(function() CommentFrame:Destroy() end)
	
	local Scroll = Instance.new("ScrollingFrame", CommentFrame)
	Scroll.Size = UDim2.new(1, -16, 1, -45)
	Scroll.Position = UDim2.new(0, 8, 0, 40)
	Scroll.BackgroundTransparency = 1
	Scroll.BorderSizePixel = 0
	Scroll.ScrollBarThickness = 4
	Scroll.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
	
	local UIList = Instance.new("UIListLayout", Scroll)
	UIList.Padding = UDim.new(0, 6)
	
	local Loading = Instance.new("TextLabel", Scroll)
	Loading.Text = "Loading komentar..."
	Loading.Size = UDim2.new(1, 0, 0, 30)
	Loading.TextColor3 = Color3.fromRGB(200, 200, 200)
	Loading.BackgroundTransparency = 1
	Loading.Font = Enum.Font.Gotham
	Loading.TextSize = 11
	
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
			else
				for i, c in ipairs(comments) do
					local CFrame = Instance.new("Frame", Scroll)
					CFrame.Size = UDim2.new(1, -8, 0, 0)
					CFrame.AutomaticSize = Enum.AutomaticSize.Y
					CFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
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
				end
			end
			Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 10)
		end
	end)
end

-- ===== FUNGSI BIKIN CARD SCRIPT =====
local function CreateScriptCard(data, parent)
	local Card = Instance.new("Frame", parent)
	Card.Size = UDim2.new(1, -8, 0, 75)
	Card.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
	
	local Thumb = Instance.new("ImageLabel", Card)
	Thumb.Size = UDim2.new(0, 55, 0, 55)
	Thumb.Position = UDim2.new(0, 8, 0, 10)
	Thumb.BackgroundTransparency = 1
	Thumb.Image = GetImageAsset(data.image)
	Instance.new("UICorner", Thumb).CornerRadius = UDim.new(0, 6)
	
	local Title = Instance.new("TextLabel", Card)
	Title.Text = data.title or "No Title"
	Title.Size = UDim2.new(1, -210, 0, 18)
	Title.Position = UDim2.new(0, 70, 0, 8)
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 11
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.BackgroundTransparency = 1
	Title.TextTruncate = Enum.TextTruncate.AtEnd
	
	local Game = Instance.new("TextLabel", Card)
	Game.Text = "Game: "..(data.game and data.game.name or "Universal")
	Game.Size = UDim2.new(1, -210, 0, 14)
	Game.Position = UDim2.new(0, 70, 0, 26)
	Game.TextColor3 = Color3.fromRGB(150, 150, 150)
	Game.Font = Enum.Font.Gotham
	Game.TextSize = 9
	Game.TextXAlignment = Enum.TextXAlignment.Left
	Game.BackgroundTransparency = 1
	
	local Views = Instance.new("TextLabel", Card)
	Views.Text = "Views: "..(data.views or 0).." | Likes: "..(data.likes or 0)
	Views.Size = UDim2.new(1, -210, 0, 14)
	Views.Position = UDim2.new(0, 70, 0, 40)
	Views.TextColor3 = Color3.fromRGB(120, 120, 120)
	Views.Font = Enum.Font.Gotham
	Views.TextSize = 9
	Views.TextXAlignment = Enum.TextXAlignment.Left
	Views.BackgroundTransparency = 1
	
	-- Tombol Favorit
	local FavBtn = Instance.new("TextButton", Card)
	FavBtn.Text = IsFavorited(data._id) and "★" or "☆"
	FavBtn.Size = UDim2.new(0, 25, 0, 25)
	FavBtn.Position = UDim2.new(1, -130, 0, 8)
	FavBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	FavBtn.TextColor3 = IsFavorited(data._id) and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(200, 200, 200)
	FavBtn.Font = Enum.Font.GothamBold
	FavBtn.TextSize = 16
	Instance.new("UICorner", FavBtn).CornerRadius = UDim.new(0, 6)
	
	FavBtn.MouseButton1Click:Connect(function()
		local isFav = ToggleFavorite(data)
		FavBtn.Text = isFav and "★" or "☆"
		FavBtn.TextColor3 = isFav and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(200, 200, 200)
		LoadFavorites()
	end)
	
	-- Tombol Komentar
	local CommentBtn = Instance.new("TextButton", Card)
	CommentBtn.Text = "Chat "..(data.comments or 0)
	CommentBtn.Size = UDim2.new(0, 55, 0, 25)
	CommentBtn.Position = UDim2.new(1, -100, 0, 8)
	CommentBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	CommentBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	CommentBtn.Font = Enum.Font.Gotham
	CommentBtn.TextSize = 10
	Instance.new("UICorner", CommentBtn).CornerRadius = UDim.new(0, 6)
	
	CommentBtn.MouseButton1Click:Connect(function()
		OpenCommentPopup(data._id, data.title, data.comments or 0)
	end)
	
	-- Tombol GET
	local GetBtn = Instance.new("TextButton", Card)
	GetBtn.Text = "GET"
	GetBtn.Size = UDim2.new(0, 55, 0, 22)
	GetBtn.Position = UDim2.new(1, -65, 0, 40)
	GetBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	GetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	GetBtn.Font = Enum.Font.GothamBold
	GetBtn.TextSize = 10
	Instance.new("UICorner", GetBtn).CornerRadius = UDim.new(0, 6)
	
	GetBtn.MouseButton1Click:Connect(function()
		local url = "https://scriptblox.com/api/script/"..data._id
		local success, res = pcall(function()
			return Request({Url = url, Method = "GET"})
		end)
		if success and res.StatusCode == 200 then
			local scriptData = HttpService:JSONDecode(res.Body)
			if scriptData.script then
				setclipboard(scriptData.script)
				GetBtn.Text = "COPIED!"
				task.wait(1)
				GetBtn.Text = "GET"
			end
		end
	end)
	
	-- Tombol EXEC
	local ExecBtn = Instance.new("TextButton", Card)
	ExecBtn.Text = "EXEC"
	ExecBtn.Size = UDim2.new(0, 55, 0, 22)
	ExecBtn.Position = UDim2.new(1, -65, 0, 10)
	ExecBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
	ExecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ExecBtn.Font = Enum.Font.GothamBold
	ExecBtn.TextSize = 10
	Instance.new("UICorner", ExecBtn).CornerRadius = UDim.new(0, 6)
	
	ExecBtn.MouseButton1Click:Connect(function()
		local url = "https://scriptblox.com/api/script/"..data._id
		local success, res = pcall(function()
			return Request({Url = url, Method = "GET"})
		end)
		if success and res.StatusCode == 200 then
			local scriptData = HttpService:JSONDecode(res.Body)
			if scriptData.script then
				table.insert(History, 1, data)
				if #History > 50 then table.remove(History) end
				SaveFile("History", History)
				LoadHistory()
				
				loadstring(scriptData.script)()
				ExecBtn.Text = "DONE!"
				task.wait(1)
				ExecBtn.Text = "EXEC"
			end
		end
	end)
end

-- ===== FUNGSI SEARCH =====
local function SearchScript(query)
	for _, v in pairs(ScrollFrame:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end
	
	local Loading = Instance.new("TextLabel", ScrollFrame)
	Loading.Text = "Loading..."
	Loading.Size = UDim2.new(1, 0, 0, 30)
	Loading.TextColor3 = Color3.fromRGB(200, 200, 200)
	Loading.BackgroundTransparency = 1
	Loading.Font = Enum.Font.Gotham
	Loading.TextSize = 12
	
	local url = "https://scriptblox.com/api/script/search?q="..HttpService:UrlEncode(query).."&max=20"
	local success, res = pcall(function()
		return Request({Url = url, Method = "GET"})
	end)
	
	Loading:Destroy()
	
	if success and res.StatusCode == 200 then
		local data = HttpService:JSONDecode(res.Body)
		if data.result and data.result.scripts then
			if #data.result.scripts == 0 then
				local NoResult = Instance.new("TextLabel", ScrollFrame)
				NoResult.Text = "Gak ada hasil buat: "..query
				NoResult.Size = UDim2.new(1, 0, 0, 30)
				NoResult.TextColor3 = Color3.fromRGB(150, 150, 150)
				NoResult.BackgroundTransparency = 1
				NoResult.Font = Enum.Font.Gotham
				NoResult.TextSize = 12
			else
				for _, script in ipairs(data.result.scripts) do
					CreateScriptCard(script, ScrollFrame)
				end
			end
		end
	else
		local Error = Instance.new("TextLabel", ScrollFrame)
		Error.Text = "Error: Gagal load ScriptBlox"
		Error.Size = UDim2.new(1, 0, 0, 30)
		Error.TextColor3 = Color3.fromRGB(255, 100, 100)
		Error.BackgroundTransparency = 1
		Error.Font = Enum.Font.Gotham
		Error.TextSize = 12
	end
	
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end

SearchBtn.MouseButton1Click:Connect(function()
	if SearchBox.Text ~= "" then SearchScript(SearchBox.Text) end
end)

SearchBox.FocusLost:Connect(function(enter)
	if enter and SearchBox.Text ~= "" then SearchScript(SearchBox.Text) end
end)

-- ===== FUNGSI LOAD FAVORIT =====
function LoadFavorites()
	for _, v in pairs(FavScroll:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end
	if #Favorites == 0 then
		local Empty = Instance.new("TextLabel", FavScroll)
		Empty.Text = "Belum ada favorit"
		Empty.Size = UDim2.new(1, 0, 0, 40)
		Empty.TextColor3 = Color3.fromRGB(150, 150, 150)
		Empty.BackgroundTransparency = 1
		Empty.Font = Enum.Font.Gotham
		Empty.TextSize = 13
	else
		for _, script in ipairs(Favorites) do
			CreateScriptCard(script, FavScroll)
		end
	end
	FavScroll.CanvasSize = UDim2.new(0, 0, 0, FavListLayout.AbsoluteContentSize.Y + 10)
end

-- ===== FUNGSI LOAD HISTORY =====
function LoadHistory()
	for _, v in pairs(HistoryScroll:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end
	if #History == 0 then
		local Empty = Instance.new("TextLabel", HistoryScroll)
		Empty.Text = "Belum ada history"
		Empty.Size = UDim2.new(1, 0, 0, 40)
		Empty.TextColor3 = Color3.fromRGB(150, 150, 150)
		Empty.BackgroundTransparency = 1
		Empty.Font = Enum.Font.Gotham
		Empty.TextSize = 13
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

local AITextBox = Instance.new("TextBox", AIInputFrame)
AITextBox.PlaceholderText = "Tanya AI... Enter buat kirim"
AITextBox.Size = UDim2.new(1, -70, 1, 0)
AITextBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
AITextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
AITextBox.Font = Enum.Font.Gotham
AITextBox.TextSize = 12
AITextBox.ClearTextOnFocus = false
Instance.new("UICorner", AITextBox).CornerRadius = UDim.new(0, 6)

local AISendBtn = Instance.new("TextButton", AIInputFrame)
AISendBtn.Text = "Send"
AISendBtn.Size = UDim2.new(0, 65, 1, 0)
AISendBtn.Position = UDim2.new(1, -65, 0, 0)
AISendBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
AISendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AISendBtn.Font = Enum.Font.GothamBold
AISendBtn.TextSize = 12
Instance.new("UICorner", AISendBtn).CornerRadius = UDim.new(0, 6)

-- ===== FUNGSI AI CHAT =====
local function AddChatBubble(text, isUser)
	local bubble = Instance.new("Frame", AIChatScroll)
	bubble.Size = UDim2.new(0.85, 0, 0, 0)
	bubble.AutomaticSize = Enum.AutomaticSize.Y
	bubble.BackgroundColor3 = isUser and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(45, 45, 50)
	bubble.Position = isUser and UDim2.new(0.15, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
	Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 8)
	
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
	
	local pad = Instance.new("UIPadding", label)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	
	task.wait()
	AIChatScroll.CanvasSize = UDim2.new(0, 0, 0, AIListLayout.AbsoluteContentSize.Y + 12)
	AIChatScroll.CanvasPosition = Vector2.new(0, AIChatScroll.CanvasSize.Y.Offset)
end

local function AskAI(prompt)
	if GROQ_API_KEY == "gsk_xxx" then
		AddChatBubble("Ganti API Key dulu di baris 11!\nAmbil di: console.groq.com", false)
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
	Instance.new("UICorner", thinking).CornerRadius = UDim.new(0, 8)
	
	local messages = {
		{role = "system", content = "Kamu asisten coding Roblox Lua. Jawab singkat pake bahasa gaul Indonesia. Kasih script kalo diminta."}
	}
	
	for _, msg in ipairs(AIChatHistory) do
		table.insert(messages, msg)
	end
	table.insert(messages, {role = "user", content = prompt})
	
	local headers = {
		["Content-Type"] = "application/json",
		["Authorization"] = "Bearer ".. GROQ_API_KEY
	}
	
	local data = {
		model = AI_MODEL,
		messages = messages,
		max_tokens = 600,
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
		AddChatBubble("Error: Cek API key / koneksi lu", false)
	end
end

AISendBtn.MouseButton1Click:Connect(function()
	if AITextBox.Text ~= "" then AskAI(AITextBox.Text) end
end)

AITextBox.FocusLost:Connect(function(enter)
	if enter and AITextBox.Text ~= "" then AskAI(AITextBox.Text) end
end)

-- Load chat history lama
for _, msg in ipairs(AIChatHistory) do
	AddChatBubble(msg.content, msg.role == "user")
end

-- ===== EVENT TOMBOL =====
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

-- Load data awal
LoadFavorites()
LoadHistory()
SetActiveTab(SearchTab)

print("✅ Zazz Hub loaded! Semua emoji batu udah dihapus")
-- ZAZZ AI v8.6 FINAL - LENGKAP POL
if getgenv().ZAZZ_AI_LOADED then ScreenGui:Destroy() end
getgenv().ZAZZ_AI_LOADED = true

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local Request = (syn and syn.request) or (http and http.request) or http_request or request
if not Request then return warn("Executor ga support") end

if CoreGui:FindFirstChild("ZAZZ_AI_UI") then CoreGui.ZAZZ_AI_UI:Destroy() end

-- ===== CONFIG =====
local GROQ_API_KEY = getgenv().GROQ_API_KEY
if not GROQ_API_KEY then return warn("Set key: getgenv().GROQ_API_KEY = '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'") end
local MODEL = "llama-3.1-8b-instant"

-- ===== SAVE SYSTEM =====
local function SaveFile(name, data)
	if writefile then writefile("ZAZZ_"..name..".json", HttpService:JSONEncode(data)) end
end
local function LoadFile(name)
	if isfile and isfile("ZAZZ_"..name..".json") then
		return HttpService:JSONDecode(readfile("ZAZZ_"..name..".json"))
	end
	return {}
end
local Favorites = LoadFile("Favorites")
local History = LoadFile("History")

local function IsFavorited(scriptId)
	for _, v in ipairs(Favorites) do
		if v._id == scriptId then return true end
	end
	return false
end

-- ===== IMAGE CACHE =====
local ImageCache = {}
local function GetImageAsset(url)
	if not url or url == "" then return "rbxasset://textures/ui/GuiImagePlaceholder.png" end
	if ImageCache[url] then return ImageCache[url] end
	local success, result = pcall(function()
		if getcustomasset then
			local fileName = "zazz_thumb_"..HttpService:GenerateGUID(false)..".png"
			local imageData = game:HttpGet(url)
			writefile(fileName, imageData)
			return getcustomasset(fileName)
		else
			return url
		end
	end)
	if success then ImageCache[url] = result return result else return "rbxasset://textures/ui/GuiImagePlaceholder.png" end
end

-- ===== COMMAND AI =====
local Commands = {
    ["godmode"] = function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.MaxHealth = math.huge hum.Health = math.huge end
        return "Godmode ON"
    end,
    ["fly"] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
        return "Fly aktif"
    end,
    ["noclip"] = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Lukashhxd/Nolifs/main/noclip"))()
        return "Noclip ON"
    end
}

-- ===== SEARCH SCRIPTBLOX =====
local function SearchScriptblox(query)
    local url = "https://scriptblox.com/api/script/search?q="..HttpService:UrlEncode(query)
    local success, res = pcall(function()
        return Request({Url = url, Method = "GET"})
    end)
    if success and res.StatusCode == 200 then
        local data = HttpService:JSONDecode(res.Body)
        return data.result.scripts or {}
    end
    return {}
end

-- ===== PROMPT AI PENDEK =====
local function GetSystemPrompt()
    local cmdList = ""
    for cmd,_ in pairs(Commands) do cmdList = cmdList..cmd..", " end
    return "You are ZAZZ AI. Rules: 1. Indonesian. 2. NO EMOJI. 3. MAX 3 KATA. 4. TO THE POINT. 5. Fitur: "..cmdList.."6. Run = [RUN:command]."
end

-- ===== UI 350x320 =====
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "ZAZZ_AI_UI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 350, 0, 320)
Main.Position = UDim2.new(1, -360, 0, 10)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 6)

-- Topbar
local Topbar = Instance.new("Frame", Main)
Topbar.Size = UDim2.new(1, 0, 0, 25)
Topbar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Instance.new("UICorner", Topbar).CornerRadius = UDim.new(0, 6)

local Title = Instance.new("TextLabel", Topbar)
Title.Text = " ZAZZ HUB v8.6 - FINAL"
Title.Size = UDim2.new(1, -50, 1, 0)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11

local MinBtn = Instance.new("TextButton", Topbar)
MinBtn.Text = "–"
MinBtn.Size = UDim2.new(0, 25, 1, 0)
MinBtn.Position = UDim2.new(1, -50, 0, 0)
MinBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.BorderSizePixel = 0
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18

local CloseBtn = Instance.new("TextButton", Topbar)
CloseBtn.Text = "×"
CloseBtn.Size = UDim2.new(0, 25, 1, 0)
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.BorderSizePixel = 0
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18

-- Mini Ball
local MiniBall = Instance.new("TextButton", ScreenGui)
MiniBall.Size = UDim2.new(0, 40, 0, 40)
MiniBall.Position = UDim2.new(0, 10, 0.5, -20)
MiniBall.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
MiniBall.Text = "ZZ"
MiniBall.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBall.Font = Enum.Font.GothamBold
MiniBall.TextSize = 11
MiniBall.Visible = false
MiniBall.Active = true
MiniBall.Draggable = true
Instance.new("UICorner", MiniBall).CornerRadius = UDim.new(1, 0)

MinBtn.MouseButton1Click:Connect(function() Main.Visible = false MiniBall.Visible = true end)
MiniBall.MouseButton1Click:Connect(function() Main.Visible = true MiniBall.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() getgenv().ZAZZ_AI_LOADED = false end)

-- Tabs
local TabFrame = Instance.new("Frame", Main)
TabFrame.Size = UDim2.new(1, -10, 0, 22)
TabFrame.Position = UDim2.new(0, 5, 0, 28)
TabFrame.BackgroundTransparency = 1

local function CreateTab(name, pos)
	local btn = Instance.new("TextButton", TabFrame)
	btn.Text = name
	btn.Size = UDim2.new(0, 75, 1, 0)
	btn.Position = UDim2.new(0, pos, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	btn.TextColor3 = Color3.fromRGB(180, 180, 180)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 10
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
	return btn
end

local SearchTab = CreateTab("Search", 0)
local AITab = CreateTab("AI", 80)
local FavTab = CreateTab("Favorit", 160)
local HistoryTab = CreateTab("History", 240)

local function SetActiveTab(tab)
	for _, btn in ipairs(TabFrame:GetChildren()) do
		if btn:IsA("TextButton") then
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			btn.TextColor3 = Color3.fromRGB(180, 180, 180)
		end
	end
	tab.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	tab.TextColor3 = Color3.fromRGB(255, 255, 255)
end
SetActiveTab(SearchTab)

-- Search Components
local SearchBox = Instance.new("TextBox", Main)
SearchBox.PlaceholderText = "Cari script..."
SearchBox.Size = UDim2.new(1, -60, 0, 22)
SearchBox.Position = UDim2.new(0, 5, 0, 55)
SearchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 10
SearchBox.ClearTextOnFocus = false
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 4)

local SearchBtn = Instance.new("TextButton", Main)
SearchBtn.Text = "Cari"
SearchBtn.Size = UDim2.new(0, 45, 0, 22)
SearchBtn.Position = UDim2.new(1, -50, 0, 55)
SearchBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 10
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 4)

-- Results Frame
local ScrollFrame = Instance.new("ScrollingFrame", Main)
ScrollFrame.Size = UDim2.new(1, -10, 1, -85)
ScrollFrame.Position = UDim2.new(0, 5, 0, 82)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
local UIListLayout = Instance.new("UIListLayout", ScrollFrame)
UIListLayout.Padding = UDim.new(0, 4)

-- AI Chat Frame
local AIChatFrame = Instance.new("ScrollingFrame", Main)
AIChatFrame.Size = UDim2.new(1, -10, 1, -110)
AIChatFrame.Position = UDim2.new(0, 5, 0, 82)
AIChatFrame.BackgroundTransparency = 1
AIChatFrame.BorderSizePixel = 0
AIChatFrame.ScrollBarThickness = 3
AIChatFrame.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
AIChatFrame.Visible = false
local AIUIListLayout = Instance.new("UIListLayout", AIChatFrame)
AIUIListLayout.Padding = UDim.new(0, 4)

local AITextBox = Instance.new("TextBox", Main)
AITextBox.PlaceholderText = "Chat AI / Run command..."
AITextBox.Size = UDim2.new(1, -50, 0, 22)
AITextBox.Position = UDim2.new(0, 5, 1, -27)
AITextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
AITextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
AITextBox.Font = Enum.Font.Gotham
AITextBox.TextSize = 10
AITextBox.ClearTextOnFocus = false
AITextBox.Visible = false
Instance.new("UICorner", AITextBox).CornerRadius = UDim.new(0, 4)

local AISendBtn = Instance.new("TextButton", Main)
AISendBtn.Text = ">"
AISendBtn.Size = UDim2.new(0, 35, 0, 22)
AISendBtn.Position = UDim2.new(1, -40, 1, -27)
AISendBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
AISendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AISendBtn.Font = Enum.Font.GothamBold
AISendBtn.TextSize = 14
AISendBtn.Visible = false
Instance.new("UICorner", AISendBtn).CornerRadius = UDim.new(0, 4)

-- Popup Komentar
local CommentFrame = nil
local function OpenCommentPopup(scriptId, totalComments)
	if CommentFrame then CommentFrame:Destroy() end
	CommentFrame = Instance.new("Frame", ScreenGui)
	CommentFrame.Size = UDim2.new(0, 320, 0, 280)
	CommentFrame.Position = UDim2.new(0.5, -160, 0.5, -140)
	CommentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	CommentFrame.Active = true
	CommentFrame.Draggable = true
	Instance.new("UICorner", CommentFrame).CornerRadius = UDim.new(0, 8)
	
	local Header = Instance.new("Frame", CommentFrame)
	Header.Size = UDim2.new(1, 0, 0, 25)
	Header.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)
	
	local Title = Instance.new("TextLabel", Header)
	Title.Text = " Komentar ["..totalComments.."]"
	Title.Size = UDim2.new(1, -30, 1, 0)
	Title.Position = UDim2.new(0, 5, 0, 0)
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.BackgroundTransparency = 1
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 10
	Title.TextXAlignment = Enum.TextXAlignment.Left
	
	local CloseBtn = Instance.new("TextButton", Header)
	CloseBtn.Text = "×"
	CloseBtn.Size = UDim2.new(0, 25, 0, 25)
	CloseBtn.Position = UDim2.new(1, -25, 0, 0)
	CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 16
	Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
	CloseBtn.MouseButton1Click:Connect(function() CommentFrame:Destroy() end)
	
	local Scroll = Instance.new("ScrollingFrame", CommentFrame)
	Scroll.Size = UDim2.new(1, -10, 1, -35)
	Scroll.Position = UDim2.new(0, 5, 0, 30)
	Scroll.BackgroundTransparency = 1
	Scroll.BorderSizePixel = 0
	Scroll.ScrollBarThickness = 3
	Scroll.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
	local UIList = Instance.new("UIListLayout", Scroll)
	UIList.Padding = UDim.new(0, 5)
	
	local Loading = Instance.new("TextLabel", Scroll)
	Loading.Text = "Loading..."
	Loading.Size = UDim2.new(1, 0, 0, 30)
	Loading.TextColor3 = Color3.fromRGB(200, 200, 200)
	Loading.BackgroundTransparency = 1
	Loading.Font = Enum.Font.Gotham
	Loading.TextSize = 10
	
	task.spawn(function()
		local url = "https://scriptblox.com/api/comment/"..scriptId.."?page=1&max=10"
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
				NoComment.TextSize = 10
			else
				for i, c in ipairs(comments) do
					local CFrame = Instance.new("Frame", Scroll)
					CFrame.Size = UDim2.new(1, -5, 0, 0)
					CFrame.AutomaticSize = Enum.AutomaticSize.Y
					CFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
					Instance.new("UICorner", CFrame).CornerRadius = UDim.new(0, 4)
					Instance.new("UIPadding", CFrame).PaddingLeft = UDim.new(0, 5)
					Instance.new("UIPadding", CFrame).PaddingRight = UDim.new(0, 5)
					Instance.new("UIPadding", CFrame).PaddingTop = UDim.new(0, 4)
					Instance.new("UIPadding", CFrame).PaddingBottom = UDim.new(0, 4)
					
					local User = Instance.new("TextLabel", CFrame)
					User.Text = "@"..(c.commentBy.username or "anon")
					User.Size = UDim2.new(1, 0, 0, 12)
					User.TextColor3 = Color3.fromRGB(88, 166, 255)
					User.Font = Enum.Font.GothamBold
					User.TextSize = 9
					User.TextXAlignment = Enum.TextXAlignment.Left
					User.BackgroundTransparency = 1
					
					local Text = Instance.new("TextLabel", CFrame)
					Text.Text = c.text or ""
					Text.Size = UDim2.new(1, 0, 0, 0)
					Text.AutomaticSize = Enum.AutomaticSize.Y
					Text.Position = UDim2.new(0, 0, 0, 14)
					Text.TextColor3 = Color3.fromRGB(220, 220, 220)
					Text.Font = Enum.Font.Gotham
					Text.TextSize = 9
					Text.TextWrapped = true
					Text.TextXAlignment = Enum.TextXAlignment.Left
					Text.BackgroundTransparency = 1
				end
			end
			Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 5)
		end
	end)
end

-- Add Result
local function AddResult(data)
	local Frame = Instance.new("Frame", ScrollFrame)
	Frame.Size = UDim2.new(1, 0, 0, 80)
	Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 4)
	
	local Thumb = Instance.new("ImageLabel", Frame)
	Thumb.Size = UDim2.new(0, 70, 0, 70)
	Thumb.Position = UDim2.new(0, 5, 0, 5)
	Thumb.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Thumb.Image = GetImageAsset(data.image or data.game and data.game.imageUrl or "")
	Instance.new("UICorner", Thumb).CornerRadius = UDim.new(0, 4)
	
	local Title = Instance.new("TextLabel", Frame)
	Title.Text = data.title or "No Title"
	Title.Size = UDim2.new(1, -85, 0, 18)
	Title.Position = UDim2.new(0, 80, 0, 5)
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 10
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.BackgroundTransparency = 1
	Title.TextTruncate = Enum.TextTruncate.AtEnd
	
	local Desc = Instance.new("TextLabel", Frame)
	Desc.Text = data.game and data.game.name or "Universal"
	Desc.Size = UDim2.new(1, -85, 0, 12)
	Desc.Position = UDim2.new(0, 80, 0, 23)
	Desc.TextColor3 = Color3.fromRGB(150, 150, 150)
	Desc.Font = Enum.Font.Gotham
	Desc.TextSize = 9
	Desc.TextXAlignment = Enum.TextXAlignment.Left
	Desc.BackgroundTransparency = 1
	
	local RunBtn = Instance.new("TextButton", Frame)
	RunBtn.Text = "Run"
	RunBtn.Size = UDim2.new(0, 50, 0, 20)
	RunBtn.Position = UDim2.new(0, 80, 0, 55)
	RunBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	RunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	RunBtn.Font = Enum.Font.GothamBold
	RunBtn.TextSize = 10
	Instance.new("UICorner", RunBtn).CornerRadius = UDim.new(0, 4)
	
	local CommentBtn = Instance.new("TextButton", Frame)
	CommentBtn.Text = "💬 "..(data.commentCount or 0)
	CommentBtn.Size = UDim2.new(0, 50, 0, 20)
	CommentBtn.Position = UDim2.new(0, 135, 0, 55)
	CommentBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	CommentBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	CommentBtn.Font = Enum.Font.Gotham
	CommentBtn.TextSize = 9
	Instance.new("UICorner", CommentBtn).CornerRadius = UDim.new(0, 4)
	
	local FavBtn = Instance.new("TextButton", Frame)
	FavBtn.Text = IsFavorited(data._id) and "★" or "☆"
	FavBtn.Size = UDim2.new(0, 25, 0, 20)
	FavBtn.Position = UDim2.new(0, 190, 0, 55)
	FavBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	FavBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
	FavBtn.Font = Enum.Font.GothamBold
	FavBtn.TextSize = 14
	Instance.new("UICorner", FavBtn).CornerRadius = UDim.new(0, 4)
	
	RunBtn.MouseButton1Click:Connect(function()
		local scriptCode = data.script
		if scriptCode then
			table.insert(History, 1, data)
			SaveFile("History", History)
			loadstring(scriptCode)()
		end
	end)
	
	CommentBtn.MouseButton1Click:Connect(function()
		OpenCommentPopup(data._id, data.commentCount or 0)
	end)
	
	FavBtn.MouseButton1Click:Connect(function()
		if IsFavorited(data._id) then
			for i, v in ipairs(Favorites) do
				if v._id == data._id then table.remove(Favorites, i) break end
			end
			FavBtn.Text = "☆"
		else
			table.insert(Favorites, data)
			FavBtn.Text = "★"
		end
		SaveFile("Favorites", Favorites)
	end)
end

-- Add AI Chat
local function AddAIChat(text, isUser)
    local msg = Instance.new("TextLabel", AIChatFrame)
    msg.Size = UDim2.new(1, -5, 0, 0)
    msg.AutomaticSize = Enum.AutomaticSize.Y
    msg.BackgroundColor3 = isUser and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(30, 30, 35)
    msg.TextColor3 = Color3.new(1,1,1)
    msg.Font = Enum.Font.Gotham
    msg.TextSize = 9
    msg.Text = text
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    local padding = Instance.new("UIPadding", msg)
    padding.PaddingTop = UDim.new(0, 3)
    padding.PaddingBottom = UDim.new(0, 3)
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    Instance.new("UICorner", msg).CornerRadius = UDim.new(0, 4)
    task.wait()
    AIChatFrame.CanvasPosition = Vector2.new(0, 9999)
end

-- Ask AI
local function AskAI(question)
    AddAIChat(question, true)
    AITextBox.Text = ""
    AddAIChat("...", false)

    local body = HttpService:JSONEncode({
        model = MODEL,
        messages = {
            {role = "system", content = GetSystemPrompt()},
            {role = "user", content = question}
        },
        temperature = 0,
        max_tokens = 10
    })

    local success, response = pcall(function()
        return Request({
            Url = "https://api.groq.com/openai/v1/chat/completions",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer "..GROQ_API_KEY
            },
            Body = body
        })
    end)

    AIChatFrame:GetChildren()[#AIChatFrame:GetChildren()]:Destroy()

    if success and response and response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        local reply = data.choices[1].message.content
        local command = reply:match("%[RUN:(.-)%]")
        reply = reply:gsub("%[RUN:.-%]", "")
        reply = reply:gsub("[\128-\255]", "")
        reply = reply:gsub("^%s+", ""):gsub("%s+$", "")
        if command and Commands[command] then
            local output = Commands[command]()
            if output then reply = output end
        end
        if reply == "" then reply = "Done" end
        AddAIChat(reply, false)
    else
        AddAIChat("Error", false)
    end
end

-- Tab Logic
local function LoadTabContent(tabName)
	for _,v in pairs(ScrollFrame:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end
	
	if tabName == "Search" then
		ScrollFrame.Visible = true
		AIChatFrame.Visible = false
		AITextBox.Visible = false
		AISendBtn.Visible = false
		SearchBox.Visible = true
		SearchBtn.Visible = true
	elseif tabName == "AI" then
		ScrollFrame.Visible = false
		AIChatFrame.Visible = true
		AITextBox.Visible = true
		AISendBtn.Visible = true
		SearchBox.Visible = false
		SearchBtn.Visible = false
	elseif tabName == "Favorit" then
		ScrollFrame.Visible = true
		AIChatFrame.Visible = false
		AITextBox.Visible = false
		AISendBtn.Visible = false
		SearchBox.Visible = false
		SearchBtn.Visible = false
		for _,script in pairs(Favorites) do AddResult(script) end
		ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
	elseif tabName == "History" then
		ScrollFrame.Visible = true
		AIChatFrame.Visible = false
		AITextBox.Visible = false
		AISendBtn.Visible = false
		SearchBox.Visible = false
		SearchBtn.Visible = false
		for _,script in pairs(History) do AddResult(script) end
		ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
	end
end

SearchTab.MouseButton1Click:Connect(function()
	SetActiveTab(SearchTab)
	LoadTabContent("Search")
end)
AITab.MouseButton1Click:Connect(function()
	SetActiveTab(AITab)
	LoadTabContent("AI")
end)
FavTab.MouseButton1Click:Connect(function()
	SetActiveTab(FavTab)
	LoadTabContent("Favorit")
end)
HistoryTab.MouseButton1Click:Connect(function()
	SetActiveTab(HistoryTab)
	LoadTabContent("History")
end)

-- SEARCH CUMA CARI, GA AUTO RUN
SearchBtn.MouseButton1Click:Connect(function()
	local query = SearchBox.Text
	if query == "" then return end
	
	for _,v in pairs(ScrollFrame:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end
	
	local results = SearchScriptblox(query)
	if #results == 0 then
		local NoResult = Instance.new("TextLabel", ScrollFrame)
		NoResult.Text = "Script ga ketemu"
		NoResult.Size = UDim2.new(1, 0, 0, 30)
		NoResult.TextColor3 = Color3.fromRGB(150, 150, 150)
		NoResult.BackgroundTransparency = 1
		NoResult.Font = Enum.Font.Gotham
		NoResult.TextSize = 10
	else
		for _,script in pairs(results) do
			AddResult(script)
		end
	end
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end)

AISendBtn.MouseButton1Click:Connect(function()
    if AITextBox.Text ~= "" then AskAI(AITextBox.Text) end
end)

AITextBox.FocusLost:Connect(function(enter)
    if enter and AITextBox.Text ~= "" then AskAI(AITextBox.Text) end
end)

AddAIChat("Ready", false)
-- ========================================================
-- Music Control Thai | WindUI Edition (Full Features)
-- Includes: Music Player, Skateboard Fly, Anti Systems, Teleport & Spectate
-- ========================================================
local AUTHOR = "YourName"

-- ป้องกัน Executor ค้างจากการ Request รูป Thumbnail / ข้อมูลผู้ใช้
local originalNamecall = nil
if typeof(hookmetamethod) == "function" then
	originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if method == "GetUserThumbnailAsync" then
			return "rbxassetid://0", true
		end
		return originalNamecall(self, ...)
	end)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ไฟล์บันทึกข้อมูลเพลง
local DATA_FILE = "MusicControlThai/music_library.json"

local function trim(value)
	return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function assetId(value)
	local text = tostring(value or "")
	return text:match("rbxassetid://(%d+)")
		or text:match("[?&]id=(%d+)")
		or text:match("^(%d+)$")
		or ""
end

local function notify(title, content, icon)
	WindUI:Notify({ Title = title, Content = content, Duration = 3, Icon = icon or "music" })
end

local data = { songs = {}, recents = {}, last = nil }

local function loadData()
	if not isfile(DATA_FILE) then return end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(readfile(DATA_FILE))
	end)
	if not ok or type(decoded) ~= "table" then return end

	data.last = decoded.last

	if type(decoded.recents) == "table" then
		data.recents = decoded.recents
	elseif type(decoded.last) == "table" and decoded.last.id then
		data.recents = {
			{
				id = decoded.last.id,
				source = "ดูดมา",
				detail = decoded.last.player or "ไม่ทราบชื่อ",
				time = os.date("%H:%M"),
			}
		}
	else
		data.recents = {}
	end

	if type(decoded.songs) == "table" then
		data.songs = decoded.songs
	elseif type(decoded.albums) == "table" then
		data.songs = {}
		for _, alb in pairs(decoded.albums) do
			local sList = alb.songs or alb
			if type(sList) == "table" then
				for _, s in ipairs(sList) do
					if type(s) == "table" and s.name and s.id then
						table.insert(data.songs, s)
					end
				end
			end
		end
	end
end

local function saveData()
	local ok, err = pcall(function()
		writefile(DATA_FILE, HttpService:JSONEncode(data))
	end)
	if not ok then notify("บันทึกข้อมูลไม่สำเร็จ", tostring(err), "circle-alert") end
	return ok
end

loadData()

-- Remote ของเกม Brookhaven
local RE = ReplicatedStorage:FindFirstChild("RE")
local ToolEvent = RE and RE:FindFirstChild("PlayerToolEvent")
local ScooterEvent = RE and RE:FindFirstChild("1NoMo1torVeh1icle1s")

local function hasSkateboard()
	local char = Players.LocalPlayer.Character
	if not char then return false end
	for _, child in ipairs(char:GetChildren()) do
		if child.Name == "NoMotorVehicleModel" then return true end
	end
	return false
end

-- ระบบกันจมดินเมื่อลบสเก็ตบอร์ด
local function fixGroundCollision()
	local char = Players.LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	
	if hum and hrp then
		hum.HipHeight = 2.0
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		hrp.CFrame = hrp.CFrame + Vector3.new(0, 1.2, 0)
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CanCollide = (p.Name == "HumanoidRootPart" or p.Name == "UpperTorso" or p.Name == "LowerTorso")
			end
		end
	end
end

local function monitorCharacterVehicle(char)
	if not char then return end
	char.ChildRemoved:Connect(function(child)
		if child.Name == "NoMotorVehicleModel" then
			task.wait(0.05)
			fixGroundCollision()
		end
	end)
end

if Players.LocalPlayer.Character then
	monitorCharacterVehicle(Players.LocalPlayer.Character)
end
Players.LocalPlayer.CharacterAdded:Connect(monitorCharacterVehicle)

-- ตรวจสอบการกดปุ่ม Exit บนหน้าจอของเกม
task.spawn(function()
	local pgui = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
	if not pgui then return end
	local mainGui = pgui:WaitForChild("MainGUIHandler", 10)
	if not mainGui then return end
	local ctrl = mainGui:WaitForChild("NoMotorVehicleControl", 10)
	if not ctrl then return end
	local exitBtn = ctrl:FindFirstChild("Exit", true)
	if exitBtn and exitBtn:IsA("GuiButton") then
		exitBtn.Activated:Connect(function()
			task.wait(0.1)
			fixGroundCollision()
		end)
	end
end)

-- Glitch บินสเก็ตบอร์ด 0.1 วิ แล้วหยุด
local function executeSkateboardGlitch()
	local char = Players.LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local bp = Instance.new("BodyPosition")
	bp.Name = "SkateGlitchBP"
	bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bp.Position = hrp.Position + Vector3.new(0, 8, 0)
	bp.D = 500
	bp.P = 50000
	bp.Parent = hrp

	local bg = Instance.new("BodyGyro")
	bg.Name = "SkateGlitchBG"
	bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	bg.CFrame = hrp.CFrame
	bg.Parent = hrp

	task.wait(0.1)

	if bp and bp.Parent then bp.Position = hrp.Position end

	task.wait(0.1)

	if bp and bp.Parent then bp:Destroy() end
	if bg and bg.Parent then bg:Destroy() end
end

local function getBoomboxTool()
	local char = Players.LocalPlayer.Character
	if char then
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("Tool") and string.lower(child.Name):find("boombox", 1, true) then
				return child
			end
		end
	end
	local bp = Players.LocalPlayer:FindFirstChildOfClass("Backpack")
	if bp then
		for _, child in ipairs(bp:GetChildren()) do
			if child:IsA("Tool") and string.lower(child.Name):find("boombox", 1, true) then
				return child
			end
		end
	end
	return nil
end

local isEquippingBoombox = false
local function equipBoombox()
	local tool = getBoomboxTool()
	if not tool then
		if ToolEvent then
			isEquippingBoombox = true
			ToolEvent:FireServer("Boombox")
			task.wait(0.5)
			isEquippingBoombox = false
			tool = getBoomboxTool()
		end
	end
	if tool and tool.Parent ~= Players.LocalPlayer.Character then
		local hum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:EquipTool(tool)
			task.wait(0.2)
		end
	end
	return tool
end

local function stopMusic()
	local tool = getBoomboxTool()
	if tool then
		local re = tool:FindFirstChild("Server") or tool:FindFirstChildOfClass("RemoteEvent")
		if re then re:FireServer("Stop") end
	end
	if ScooterEvent then ScooterEvent:FireServer("PickingScooterMusicStop", "", nil) end
end

local function getGuiObjectFromElement(el)
	if typeof(el) == "Instance" then return el end
	if type(el) == "table" then
		for _, key in ipairs({ "Instance", "Frame", "Element", "Object", "Container", "Button", "Holder" }) do
			if typeof(el[key]) == "Instance" then return el[key] end
		end
		for _, v in pairs(el) do
			if typeof(v) == "Instance" then return v end
		end
	end
	return nil
end

-- สร้างหน้าต่างหลัก WindUI
local Window = WindUI:CreateWindow({
	Title = "Music Control Thai",
	Icon = "music",
	Author = AUTHOR,
	Folder = "MusicControlThai",
	Size = UDim2.fromOffset(580, 460),
	Transparent = true,
	Theme = "Dark",
	Keybind = Enum.KeyCode.RightControl,
})

local InfoTab = Window:Tab({ Title = "ข้อมูล", Icon = "info" })
local MainTab = Window:Tab({ Title = "หน้าหลัก", Icon = "music" })
local PlayerTab = Window:Tab({ Title = "วาร์ป & ส่อง", Icon = "user" })
local LibraryTab = Window:Tab({ Title = "คลังเพลง", Icon = "library-big" })
local HistoryTab = Window:Tab({ Title = "ประวัติ", Icon = "history" })
local AntiTab = Window:Tab({ Title = "ระบบป้องกัน", Icon = "shield-check" })

-- ข้อมูล
InfoTab:Paragraph({
	Title = "ข้อความจากผู้จัดทำ",
	Content = "ระบบควบคุมเพลงสมบูรณ์แบบ รองรับลำโพงและสเก็ตบอร์ด พร้อมระบบความปลอดภัยและระบบผู้เล่น",
})

InfoTab:Paragraph({
	Title = "เกี่ยวกับระบบ",
	Content = "พัฒนาโดย: " .. AUTHOR .. "\nเวอร์ชัน: 3.1 (Full)\nปุ่มลัด: RightControl หรือปุ่มลูกแก้ว 🎵 บนหน้าจอ",
})

-- หน้าหลัก
local currentInputId = ""
local selectedDevice = "1. ลำโพง (Boombox)"
local setMainId = nil

local MusicIdInput = MainTab:Input({
	Title = "รหัสเพลง (Music ID)",
	Desc = "เฉพาะตัวเลขเท่านั้น",
	Placeholder = "วางไอดีเพลงที่นี่",
	Value = "",
	Callback = function(val)
		currentInputId = val
	end,
})

setMainId = function(id, autoPlay)
	currentInputId = tostring(id or "")
	if MusicIdInput and MusicIdInput.SetValue then
		MusicIdInput:SetValue(currentInputId)
	elseif MusicIdInput and MusicIdInput.Set then
		MusicIdInput:Set(currentInputId)
	end
end

MainTab:Dropdown({
	Title = "อุปกรณ์เล่นเพลง",
	Desc = "เลือกว่าจะเปิดผ่านลำโพง หรือเสกสเก็ตบอร์ดพร้อมบั๊กบิน",
	Values = { "1. ลำโพง (Boombox)", "2. สเก็ตบอร์ด (Skateboard)" },
	Value = "1. ลำโพง (Boombox)",
	Callback = function(val)
		selectedDevice = val
	end,
})

local addRecentRecord = nil

local function handleSmartPlayMusic()
	local cleanedId = assetId(currentInputId)
	if cleanedId == "" then cleanedId = tostring(currentInputId or ""):gsub("%D", "") end

	if cleanedId == "" then
		notify("แจ้งเตือน", "กรุณาใส่รหัสเพลงก่อนกดเล่น", "circle-alert")
		return
	end

	if addRecentRecord then
		addRecentRecord({
			id = cleanedId,
			source = "ใส่รหัสเอง",
			time = os.date("%H:%M"),
		})
	end

	if selectedDevice == "2. สเก็ตบอร์ด (Skateboard)" then
		if not hasSkateboard() then
			notify("ระบบ", "กำลังเสกสเก็ตบอร์ด...", "skateboard")
			if ScooterEvent then
				ScooterEvent:FireServer("PickingScooter", "Skateboard")
			end
			local waited = 0
			while not hasSkateboard() and waited < 3 do
				task.wait(0.1)
				waited = waited + 0.1
			end
		end

		executeSkateboardGlitch()

		if ScooterEvent then
			ScooterEvent:FireServer("PickingScooterMusic", cleanedId, 1)
			notify("กำลังเล่นเพลง", "เล่นผ่านสเก็ตบอร์ด: " .. cleanedId, "music")
		end
	else
		local tool = equipBoombox()
		if not tool then
			notify("ข้อผิดพลาด", "ไม่พบลำโพงในตัวละครหรือกระเป๋า", "circle-alert")
			return
		end

		local re = tool:FindFirstChild("Server") or tool:FindFirstChildOfClass("RemoteEvent")
		if re then
			re:FireServer("Play", cleanedId)
			notify("กำลังเล่นเพลง", "เล่นผ่านลำโพง: " .. cleanedId, "music")
		end
	end
end

local function getNearestPlayerWithMusic()
	local myChar = Players.LocalPlayer.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
	local myPos = myChar.HumanoidRootPart.Position

	local nearest = nil
	local minDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= Players.LocalPlayer and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - myPos).Magnitude
				for _, obj in ipairs(player.Character:GetDescendants()) do
					if obj:IsA("Sound") and obj.IsPlaying and obj.SoundId ~= "" then
						local sId = assetId(obj.SoundId)
						if sId ~= "" and dist < minDistance then
							minDistance = dist
							nearest = { player = player.DisplayName .. " (@" .. player.Name .. ")", id = sId, distance = dist }
						end
					end
				end
			end
		end
	end
	return nearest
end

MainTab:Button({
	Title = "ดูดเพลงจากคนที่อยู่ใกล้ที่สุด",
	Desc = "หาเพลงที่กำลังเล่นของผู้เล่นใกล้เคียง แล้วนำรหัสมาใส่ในหน้าหลักทันที",
	Icon = "download",
	Callback = function()
		local nearest = getNearestPlayerWithMusic()
		if not nearest then
			notify("ไม่พบเพลง", "ไม่มีผู้เล่นใกล้เคียงที่กำลังเปิดเพลงอยู่", "circle-alert")
			return
		end

		setMainId(nearest.id, false)
		if addRecentRecord then
			addRecentRecord({
				id = nearest.id,
				source = "ดูดมา",
				detail = nearest.player,
				time = os.date("%H:%M"),
			})
		end
		notify("ดูดรหัสเพลงสำเร็จ", nearest.player .. " • " .. math.floor(nearest.distance) .. " studs", "download")
	end,
})

MainTab:Button({
	Title = "▶ เล่นเพลง",
	Desc = "เริ่มเล่นเพลงตามอุปกรณ์ที่เลือก (ลำโพง หรือ สเก็ตบอร์ด)",
	Callback = handleSmartPlayMusic,
})

MainTab:Button({
	Title = "■ หยุดเพลง",
	Desc = "หยุดการเล่นเพลงปัจจุบัน",
	Callback = function()
		stopMusic()
		notify("หยุดเล่นเพลงแล้ว", "", "square")
	end,
})

-- ========================================================
-- แท็บ วาร์ป & ส่องผู้เล่น (PLAYER / TELEPORT & SPECTATE)
-- ========================================================
PlayerTab:Paragraph({
	Title = "ระบบวาร์ปและส่องมุมมองผู้เล่น",
	Content = "เลือกผู้เล่นจากรายการด้านล่าง เพื่อดูข้อมูลโปรไฟล์, เทเลพอร์ตไปหา หรือส่องมุมมองกล้อง",
})

local selectedTargetPlayer = nil
local playerDropdown = nil
local profileAvatarImg = nil
local profileTitleLabel = nil
local profileDescLabel = nil

-- การ์ดแสดงโปรไฟล์ผู้เล่นที่เลือก (มีหน้าโปรไฟล์, ชื่อเล่น, ชื่อจริง)
local ProfileCard = PlayerTab:Paragraph({
	Title = "ยังไม่ได้เลือกผู้เล่น",
	Desc = "กรุณาเลือกผู้เล่นจากรายการด้านล่าง เพื่อดูโปรไฟล์ วาร์ป หรือส่อง",
	Image = "rbxassetid://0",
	ImageSize = 54,
})

local profileGui = getGuiObjectFromElement(ProfileCard)
if profileGui then
	for _, child in ipairs(profileGui:GetDescendants()) do
		if child:IsA("ImageLabel") and child.Name == "ImageLabel" then
			profileAvatarImg = child
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 10)
			c.Parent = child
		elseif child:IsA("TextLabel") then
			if child.Text == "ยังไม่ได้เลือกผู้เล่น" then
				profileTitleLabel = child
			elseif child.Text:find("กรุณาเลือกผู้เล่น") then
				profileDescLabel = child
			end
		end
	end
end

-- ฟังก์ชันอัปเดตข้อมูลโปรไฟล์ผู้เล่น
local function updatePlayerProfile(player)
	selectedTargetPlayer = player
	if not player then
		if ProfileCard.SetTitle then ProfileCard:SetTitle("ยังไม่ได้เลือกผู้เล่น") end
		if ProfileCard.SetDesc then ProfileCard:SetDesc("กรุณาเลือกผู้เล่นจากรายการด้านล่าง") end
		if profileTitleLabel then profileTitleLabel.Text = "ยังไม่ได้เลือกผู้เล่น" end
		if profileDescLabel then profileDescLabel.Text = "กรุณาเลือกผู้เล่นจากรายการด้านล่าง" end
		if profileAvatarImg then profileAvatarImg.Image = "rbxassetid://0" end
		return
	end

	local thumbUrl = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
	if profileAvatarImg then
		profileAvatarImg.Image = thumbUrl
	end

	local distText = "ไม่พบตัวละคร"
	local hpText = "100%"
	local myChar = Players.LocalPlayer.Character
	local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local pChar = player.Character
	local pHrp = pChar and pChar:FindFirstChild("HumanoidRootPart")
	local pHum = pChar and pChar:FindFirstChildOfClass("Humanoid")

	if myHrp and pHrp then
		distText = tostring(math.floor((pHrp.Position - myHrp.Position).Magnitude)) .. " studs"
	end
	if pHum then
		hpText = tostring(math.floor(pHum.Health)) .. "/" .. tostring(math.floor(pHum.MaxHealth))
	end

	local titleStr = player.DisplayName .. " (@" .. player.Name .. ")"
	local descStr = "ชื่อจริง: @" .. player.Name .. " • UserID: " .. player.UserId .. "\nระยะห่าง: " .. distText .. " • พลังชีวิต: " .. hpText

	if ProfileCard.SetTitle then ProfileCard:SetTitle(titleStr) end
	if ProfileCard.SetDesc then ProfileCard:SetDesc(descStr) end
	if profileTitleLabel then profileTitleLabel.Text = titleStr end
	if profileDescLabel then profileDescLabel.Text = descStr end
end

-- ดึงรายชื่อผู้เล่นในเซิร์ฟเวอร์
local function getPlayerListValues()
	local values = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Players.LocalPlayer then
			table.insert(values, p.DisplayName .. " (@" .. p.Name .. ")")
		end
	end
	if #values == 0 then
		table.insert(values, "ไม่มีผู้เล่นอื่นในเซิร์ฟเวอร์")
	end
	return values
end

local function findPlayerFromValue(val)
	if not val or val == "ไม่มีผู้เล่นอื่นในเซิร์ฟเวอร์" then return nil end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= Players.LocalPlayer then
			local entry = p.DisplayName .. " (@" .. p.Name .. ")"
			if entry == val or p.Name == val or p.DisplayName == val then
				return p
			end
		end
	end
	return nil
end

-- ระบบส่องผู้เล่น (Spectate)
local isSpectating = false
local spectateCharConn = nil

local function updateSpectateCamera()
	if not isSpectating then return end
	local camera = workspace.CurrentCamera
	if not camera then return end

	if selectedTargetPlayer and selectedTargetPlayer.Character then
		local hum = selectedTargetPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			camera.CameraSubject = hum
			return
		end
	end

	local myHum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if myHum then
		camera.CameraSubject = myHum
	end
end

local function setSpectating(state)
	isSpectating = state
	local camera = workspace.CurrentCamera
	if isSpectating then
		if not selectedTargetPlayer then
			notify("แจ้งเตือน", "กรุณาเลือกผู้เล่นก่อนเปิดโหมดส่อง", "circle-alert")
			return
		end

		updateSpectateCamera()

		if spectateCharConn then spectateCharConn:Disconnect() end
		spectateCharConn = selectedTargetPlayer.CharacterAdded:Connect(function()
			task.wait(0.2)
			if isSpectating then
				updateSpectateCamera()
			end
		end)

		notify("โหมดส่อง (Spectate)", "กำลังส่องมุมมองของ " .. selectedTargetPlayer.DisplayName, "user")
	else
		if spectateCharConn then
			spectateCharConn:Disconnect()
			spectateCharConn = nil
		end
		if camera and Players.LocalPlayer.Character then
			local myHum = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if myHum then
				camera.CameraSubject = myHum
			end
		end
		notify("โหมดส่อง (Spectate)", "หยุดส่องแล้ว กลับสู่มุมมองของคุณ", "user")
	end
end

-- ตัวเลือก Dropdown ด้านบน
local playerList = getPlayerListValues()
local initialVal = playerList[1] or "ไม่มีผู้เล่นอื่นในเซิร์ฟเวอร์"

playerDropdown = PlayerTab:Dropdown({
	Title = "เลือกผู้เล่นเป้าหมาย",
	Desc = "เลือกเพื่อดูโปรไฟล์, วาร์ป หรือส่องมุมมอง",
	Values = playerList,
	Value = initialVal,
	SearchBarEnabled = true,
	Callback = function(val)
		local target = findPlayerFromValue(val)
		if target then
			updatePlayerProfile(target)
			if isSpectating then
				if spectateCharConn then spectateCharConn:Disconnect() end
				spectateCharConn = target.CharacterAdded:Connect(function()
					task.wait(0.2)
					if isSpectating then updateSpectateCamera() end
				end)
				updateSpectateCamera()
				notify("เปลี่ยนเป้าหมายส่อง", "ส่องมุมมองของ " .. target.DisplayName, "user")
			end
		end
	end,
})

local firstTarget = findPlayerFromValue(initialVal)
if firstTarget then
	updatePlayerProfile(firstTarget)
end

-- ปุ่ม เทเลพอร์ตไปยังผู้เล่น
PlayerTab:Button({
	Title = "วาร์ปไปหาผู้เล่น (Teleport)",
	Desc = "เทเลพอร์ตตัวละครของคุณไปยังตำแหน่งของผู้เล่นที่เลือกทันที",
	Icon = "user",
	Callback = function()
		if not selectedTargetPlayer then
			notify("แจ้งเตือน", "กรุณาเลือกผู้เล่นก่อนวาร์ป", "circle-alert")
			return
		end
		local myChar = Players.LocalPlayer.Character
		local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not myHrp then
			notify("ข้อผิดพลาด", "ไม่พบตัวละครของคุณ", "circle-alert")
			return
		end
		local tChar = selectedTargetPlayer.Character
		local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
		if not tHrp then
			notify("ข้อผิดพลาด", selectedTargetPlayer.DisplayName .. " ยังไม่เกิดหรือไม่มีตัวละคร", "circle-alert")
			return
		end

		myHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3)
		notify("วาร์ปสำเร็จ", "เทเลพอร์ตไปหา " .. selectedTargetPlayer.DisplayName .. " แล้ว", "user")
	end,
})

-- ปุ่ม สลับโหมดส่องผู้เล่น (Spectate)
local spectateToggle = PlayerTab:Toggle({
	Title = "ส่องมุมมองผู้เล่น (Spectate Camera)",
	Desc = "เปิดเพื่อดูกล้องของผู้เล่นที่เลือก / ปิดเพื่อกลับสู่มุมมองเดิม",
	Value = false,
	Callback = function(state)
		setSpectating(state)
	end,
})

-- ปุ่ม กู้คืนมุมมองกล้อง
PlayerTab:Button({
	Title = "รีเซ็ตกล้องกลับสู่ตัวเอง",
	Desc = "กู้คืนมุมมองกล้องทันทีหากกล้องค้างหรือผู้เล่นออกเกม",
	Icon = "user",
	Callback = function()
		setSpectating(false)
		if spectateToggle and spectateToggle.SetValue then
			spectateToggle:SetValue(false)
		end
	end,
})

-- ปุ่ม รีเฟรชรายชื่อผู้เล่น
local function refreshPlayerDropdown()
	if not playerDropdown then return end
	local vals = getPlayerListValues()
	if playerDropdown.Refresh then
		playerDropdown:Refresh(vals)
	elseif playerDropdown.SetValues then
		playerDropdown:SetValues(vals)
	end
end

PlayerTab:Button({
	Title = "รีเฟรชรายชื่อผู้เล่น",
	Desc = "อัปเดตรายชื่อผู้เล่นทั้งหมดในเซิร์ฟเวอร์",
	Icon = "refresh-cw",
	Callback = function()
		refreshPlayerDropdown()
		notify("อัปเดตแล้ว", "รีเฟรชรายชื่อผู้เล่นในเซิร์ฟเวอร์สำเร็จ", "refresh-cw")
	end,
})

-- อัปเดตรายชื่อผู้เล่นอัตโนมัติเมื่อมีคนเข้าหรือออก
Players.PlayerAdded:Connect(function()
	task.wait(1)
	refreshPlayerDropdown()
end)

Players.PlayerRemoving:Connect(function(player)
	if selectedTargetPlayer == player then
		if isSpectating then
			setSpectating(false)
			if spectateToggle and spectateToggle.SetValue then
				spectateToggle:SetValue(false)
			end
		end
		selectedTargetPlayer = nil
		updatePlayerProfile(nil)
		notify("แจ้งเตือน", player.DisplayName .. " ออกจากเกมแล้ว", "circle-alert")
	end
	task.wait(0.5)
	refreshPlayerDropdown()
end)

-- ลูปอัปเดตระยะห่างและเลือดของผู้เล่นที่เลือกแบบ Real-time
task.spawn(function()
	while true do
		task.wait(1)
		if selectedTargetPlayer and selectedTargetPlayer.Parent == Players then
			local myChar = Players.LocalPlayer.Character
			local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
			local pChar = selectedTargetPlayer.Character
			local pHrp = pChar and pChar:FindFirstChild("HumanoidRootPart")
			local pHum = pChar and pChar:FindFirstChildOfClass("Humanoid")

			local distText = "ไม่พบตัวละคร"
			local hpText = "100%"
			if myHrp and pHrp then
				distText = tostring(math.floor((pHrp.Position - myHrp.Position).Magnitude)) .. " studs"
			end
			if pHum then
				hpText = tostring(math.floor(pHum.Health)) .. "/" .. tostring(math.floor(pHum.MaxHealth))
			end

			local descStr = "ชื่อจริง: @" .. selectedTargetPlayer.Name .. " • UserID: " .. selectedTargetPlayer.UserId .. "\nระยะห่าง: " .. distText .. " • พลังชีวิต: " .. hpText
			if ProfileCard.SetDesc then ProfileCard:SetDesc(descStr) end
			if profileDescLabel then profileDescLabel.Text = descStr end
		end
	end
end)

-- ========================================================
-- แท็บ คลังเพลง (LIBRARY)
-- ========================================================
LibraryTab:Paragraph({
	Title = "คลังเพลงส่วนตัว",
	Content = "บันทึกและจัดการเพลงโปรดของคุณ สามารถกดฟังหรือกดลบเพลงได้จากปุ่ม X ที่มุมขวา",
})

local saveSongName = ""
local saveSongId = ""
local libraryElements = {}
local renderLibraryList

local function clearLibraryElements()
	for _, el in ipairs(libraryElements) do
		pcall(function() el:Destroy() end)
	end
	libraryElements = {}
end

local function createLibrarySongItem(song)
	local songDeleting = false

	local songBtn = LibraryTab:Button({
		Title = "♪ " .. song.name,
		Desc = song.id .. " — กดส่งรหัสไปหน้าหลัก",
		Callback = function()
			if songDeleting then return end
			setMainId(song.id, false)
			notify("เลือกเพลงแล้ว", song.name .. " ถูกส่งไปหน้าหลัก", "music")
		end,
	})
	table.insert(libraryElements, songBtn)

	local gui = getGuiObjectFromElement(songBtn)
	if gui then
		for _, child in ipairs(gui:GetDescendants()) do
			if child:IsA("ImageLabel") and child.Position.X.Scale > 0.7 then
				child.Visible = false
			end
		end

		local xBtn = Instance.new("TextButton")
		xBtn.Name = "DeleteSongBtn"
		xBtn.Text = "X"
		xBtn.Size = UDim2.fromOffset(24, 24)
		xBtn.AnchorPoint = Vector2.new(1, 0.5)
		xBtn.Position = UDim2.new(1, -12, 0.5, 0)
		xBtn.BackgroundColor3 = Color3.fromRGB(240, 50, 50)
		xBtn.BackgroundTransparency = 0.8
		xBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
		xBtn.Font = Enum.Font.GothamBold
		xBtn.TextSize = 13
		xBtn.ZIndex = 30
		xBtn.AutoButtonColor = true

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = xBtn

		xBtn.MouseEnter:Connect(function()
			xBtn.BackgroundTransparency = 0.2
			xBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		end)
		xBtn.MouseLeave:Connect(function()
			xBtn.BackgroundTransparency = 0.8
			xBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
		end)

		xBtn.MouseButton1Down:Connect(function() songDeleting = true end)
		xBtn.MouseButton1Click:Connect(function()
			songDeleting = true
			for i, s in ipairs(data.songs) do
				if s == song or (s.id == song.id and s.name == song.name) then
					table.remove(data.songs, i)
					break
				end
			end
			saveData()
			notify("ลบเพลงเรียบร้อยแล้ว", song.name, "trash-2")
			renderLibraryList()
			task.wait(0.2)
			songDeleting = false
		end)
		xBtn.Parent = gui
	end
end

renderLibraryList = function()
	clearLibraryElements()
	for _, song in ipairs(data.songs) do
		if type(song) == "table" and song.name and song.id then
			createLibrarySongItem(song)
		end
	end
end

LibraryTab:Input({
	Title = "ตั้งชื่อเพลงที่จะบันทึก",
	Placeholder = "เช่น เพลงแดนซ์",
	Value = "",
	Callback = function(val) saveSongName = val end,
})

LibraryTab:Input({
	Title = "รหัสเพลง (Music ID) ที่จะบันทึก",
	Desc = "ปล่อยว่างไว้ได้ หากต้องการใช้รหัสเพลงล่าสุด",
	Placeholder = "วางไอดีเพลง ",
	Value = "",
	Callback = function(val) saveSongId = val end,
})

LibraryTab:Button({
	Title = "+ บันทึกเพลงลงคลัง",
	Desc = "บันทึกเพลงจากรหัสที่กรอก หรือรหัสล่าสุดที่ดูดมา",
	Icon = "save",
	Callback = function()
		local name = trim(saveSongName)
		local id = assetId(saveSongId)
		if id == "" then id = tostring(saveSongId or ""):gsub("%D", "") end
		if id == "" and data.last then id = data.last.id end

		if name == "" or id == "" then
			notify("ข้อมูลไม่ครบ", "กรุณาใส่ชื่อเพลง และรหัสเพลง (Music ID)", "circle-alert")
			return
		end

		local newSong = { name = name, id = id }
		table.insert(data.songs, newSong)
		if saveData() then
			createLibrarySongItem(newSong)
			notify("บันทึกเพลงแล้ว", name .. " • " .. id, "save")
		end
	end,
})

renderLibraryList()

-- ========================================================
-- แท็บ ประวัติ (HISTORY)
-- ========================================================
HistoryTab:Paragraph({
	Title = "ประวัติการใช้เพลง",
	Content = "บันทึกประวัติเพลงต่อเนื่องไม่จำกัด • กดที่ตัวกรอบเพื่อส่งรหัสไปหน้าหลัก • กดปุ่ม X มุมขวาเพื่อลบทีละรายการ",
})

local recentElements = {}
local renderHistoryList

local function clearRecentElements()
	for _, el in ipairs(recentElements) do
		pcall(function() el:Destroy() end)
	end
	recentElements = {}
end

local function renderHistoryItem(item)
	local isDeleting = false

	local sourceTag
	if item.source == "ดูดมา" then
		sourceTag = "[ดูดมา] จาก: " .. (item.detail or "ไม่ทราบชื่อ")
	else
		sourceTag = "[ใส่รหัสเอง]"
	end

	local descText = sourceTag .. " • เวลา " .. (item.time or "--:--") .. " — กดส่งไปหน้าหลัก"

	local itemBtn = HistoryTab:Button({
		Title = "♪ " .. item.id,
		Desc = descText,
		Callback = function()
			if isDeleting then return end
			setMainId(item.id, false)
			notify("ส่งรหัสเพลงไปหน้าหลักแล้ว", item.id, "music")
		end,
	})
	table.insert(recentElements, itemBtn)

	local gui = getGuiObjectFromElement(itemBtn)
	if gui then
		for _, child in ipairs(gui:GetDescendants()) do
			if child:IsA("ImageLabel") and child.Position.X.Scale > 0.7 then
				child.Visible = false
			end
		end

		local xBtn = Instance.new("TextButton")
		xBtn.Name = "DeleteRecentBtn"
		xBtn.Text = "X"
		xBtn.Size = UDim2.fromOffset(24, 24)
		xBtn.AnchorPoint = Vector2.new(1, 0.5)
		xBtn.Position = UDim2.new(1, -12, 0.5, 0)
		xBtn.BackgroundColor3 = Color3.fromRGB(240, 50, 50)
		xBtn.BackgroundTransparency = 0.8
		xBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
		xBtn.Font = Enum.Font.GothamBold
		xBtn.TextSize = 13
		xBtn.ZIndex = 30
		xBtn.AutoButtonColor = true

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = xBtn

		xBtn.MouseEnter:Connect(function()
			xBtn.BackgroundTransparency = 0.2
			xBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		end)
		xBtn.MouseLeave:Connect(function()
			xBtn.BackgroundTransparency = 0.8
			xBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
		end)

		xBtn.MouseButton1Down:Connect(function() isDeleting = true end)
		xBtn.MouseButton1Click:Connect(function()
			isDeleting = true
			for i, r in ipairs(data.recents) do
				if r == item or (r.id == item.id and r.time == item.time) then
					table.remove(data.recents, i)
					break
				end
			end
			saveData()
			notify("ลบประวัติเพลงแล้ว", item.id, "trash-2")
			renderHistoryList()
			task.wait(0.2)
			isDeleting = false
		end)
		xBtn.Parent = gui
	end
end

renderHistoryList = function()
	clearRecentElements()
	for _, item in ipairs(data.recents) do
		if item and item.id then
			renderHistoryItem(item)
		end
	end
end

HistoryTab:Button({
	Title = "ล้างประวัติทั้งหมด",
	Desc = "ลบรายการประวัติเพลงล่าสุดทั้งหมดในหน้านี้",
	Icon = "trash-2",
	Callback = function()
		data.recents = {}
		data.last = nil
		saveData()
		renderHistoryList()
		notify("ล้างประวัติเพลงทั้งหมดเรียบร้อยแล้ว", "", "check")
	end,
})

addRecentRecord = function(item)
	if #data.recents == 0 or data.recents[1].id ~= item.id or data.recents[1].source ~= item.source then
		table.insert(data.recents, 1, item)
		saveData()
		renderHistoryList()
	end
end

renderHistoryList()

-- ========================================================
-- แท็บ ระบบป้องกัน (ANTI)
-- ========================================================
AntiTab:Paragraph({
	Title = "ระบบความปลอดภัยและการป้องกัน",
	Content = "เปิด/ปิดระบบเพื่อป้องกันการรบกวน, กันหลุด AFK, กันโดนชนปลิว และล้างของสแปมในกระเป๋า",
})

-- 1. Anti-AFK
local antiAfkEnabled = false
local antiAfkConnection = nil

local function toggleAntiAfk(state)
	antiAfkEnabled = state
	if antiAfkEnabled then
		if not antiAfkConnection then
			antiAfkConnection = Players.LocalPlayer.Idled:Connect(function()
				if antiAfkEnabled then
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new())
				end
			end)
		end
		notify("Anti-AFK", "เปิดใช้งานป้องกันการตัดการเชื่อมต่อ (AFK)", "shield-check")
	else
		if antiAfkConnection then
			antiAfkConnection:Disconnect()
			antiAfkConnection = nil
		end
		notify("Anti-AFK", "ปิดใช้งาน Anti-AFK", "shield-alert")
	end
end

AntiTab:Toggle({
	Title = "ป้องกันการหลุดจากการอยู่นิ่ง (Anti-AFK)",
	Desc = "ป้องกันเกมตัดการเชื่อมต่อเมื่อยืนนิ่งเกิน 20 นาที",
	Value = false,
	Callback = toggleAntiAfk,
})

-- 2. Anti-Sit
local antiSitEnabled = false
local antiSitConnection = nil

local function applyAntiSit(character)
	if not character then return end
	local humanoid = character:WaitForChild("Humanoid", 3) or character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if antiSitEnabled then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
			if humanoid.Sit then
				humanoid.Sit = false
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		else
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		end
	end
end

local function toggleAntiSit(state)
	antiSitEnabled = state
	local character = Players.LocalPlayer.Character
	if character then
		applyAntiSit(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if state then
				if antiSitConnection then antiSitConnection:Disconnect() end
				antiSitConnection = humanoid.Seated:Connect(function(isSeated)
					if isSeated and antiSitEnabled then
						humanoid.Sit = false
						humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
					end
				end)
			else
				if antiSitConnection then
					antiSitConnection:Disconnect()
					antiSitConnection = nil
				end
			end
		end
	end
	notify("Anti-Sit", state and "เปิดใช้งานป้องกันการนั่งแล้ว" or "ปิดใช้งานป้องกันการนั่งแล้ว", state and "shield-check" or "shield-alert")
end

Players.LocalPlayer.CharacterAdded:Connect(function(char)
	if antiSitEnabled then
		task.wait(0.5)
		applyAntiSit(char)
		local hum = char:WaitForChild("Humanoid", 3) or char:FindFirstChildOfClass("Humanoid")
		if hum and antiSitEnabled then
			if antiSitConnection then antiSitConnection:Disconnect() end
			antiSitConnection = hum.Seated:Connect(function(isSeated)
				if isSeated and antiSitEnabled then
					hum.Sit = false
					hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end)
		end
	end
end)

AntiTab:Toggle({
	Title = "ป้องกันการนั่ง (Anti-Sit)",
	Desc = "ป้องกันตัวละครเผลอนั่งเก้าอี้อัตโนมัติ (ปิดเมื่อต้องการขับพาหนะที่ต้องนั่ง)",
	Value = false,
	Callback = toggleAntiSit,
})

-- 3. Anti-Fling (ป้องกันเรือ/รถ/เครื่องบิน/ลูกบอลชนปลิว + คืนค่าได้ 100%)
local antiFlingEnabled = false
local antiFlingStepped = nil
local antiFlingHeartbeat = nil
local disabledFlingParts = {}

local function isMyVehicleOrPart(part)
	local char = Players.LocalPlayer.Character
	if not char then return false end
	if part:IsDescendantOf(char) then return true end
	local noMotor = char:FindFirstChild("NoMotorVehicleModel")
	if noMotor then
		if noMotor:IsA("ObjectValue") and noMotor.Value and part:IsDescendantOf(noMotor.Value) then return true end
		if part:IsDescendantOf(noMotor) then return true end
	end
	return false
end

local function toggleAntiFling(state)
	antiFlingEnabled = state
	if antiFlingEnabled then
		disabledFlingParts = {}

		antiFlingStepped = RunService.Stepped:Connect(function()
			if not antiFlingEnabled then return end
			local char = Players.LocalPlayer.Character
			if not char then return end

			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then
					p.CanCollide = false
				end
			end

			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= Players.LocalPlayer and player.Character then
					for _, part in ipairs(player.Character:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide then
							disabledFlingParts[part] = true
							part.CanCollide = false
						end
					end
				end
			end
		end)

		antiFlingHeartbeat = RunService.Heartbeat:Connect(function()
			if not antiFlingEnabled then return end
			local char = Players.LocalPlayer.Character
			if not char or not char:FindFirstChild("HumanoidRootPart") then return end
			local hrp = char.HumanoidRootPart
			local myPos = hrp.Position

			for _, part in ipairs(workspace:GetPartBoundsInRadius(myPos, 30)) do
				if part:IsA("BasePart") and not isMyVehicleOrPart(part) then
					local isVehicle = false
					local cur = part
					while cur and cur ~= workspace do
						local name = cur.Name:lower()
						if name:find("car") or name:find("boat") or name:find("plane") or name:find("heli") or name:find("vehicle") or name:find("ball") or name:find("ship") or name:find("yacht") then
							isVehicle = true
							break
						end
						cur = cur.Parent
					end

					if isVehicle or part.AssemblyLinearVelocity.Magnitude > 15 or part.AssemblyAngularVelocity.Magnitude > 15 then
						if part.CanCollide then
							disabledFlingParts[part] = true
							part.CanCollide = false
						end
					end
				end
			end
		end)

		notify("Anti-Fling", "เปิดใช้งานป้องกันการชนปลิวแล้ว", "shield-check")
	else
		if antiFlingStepped then antiFlingStepped:Disconnect(); antiFlingStepped = nil end
		if antiFlingHeartbeat then antiFlingHeartbeat:Disconnect(); antiFlingHeartbeat = nil end

		local char = Players.LocalPlayer.Character
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then
					if p.Name == "HumanoidRootPart" or p.Name == "UpperTorso" or p.Name == "LowerTorso" then
						p.CanCollide = true
					end
				end
			end
		end

		for part, _ in pairs(disabledFlingParts) do
			if part and part.Parent then
				pcall(function() part.CanCollide = true end)
			end
		end
		disabledFlingParts = {}

		notify("Anti-Fling", "ปิดใช้งาน คืนค่าระบบการชนกลับสู่ปกติแล้ว", "shield-alert")
	end
end

AntiTab:Toggle({
	Title = "ป้องกันการโดนชน/ปัดปลิว (Anti-Fling)",
	Desc = "ป้องกันเรือ, เครื่องบิน, รถ, ลูกบอล หรือผู้เล่นอื่นพุ่งมาปัดปลิวออกนอกแมพ",
	Value = false,
	Callback = toggleAntiFling,
})

-- 4. Anti-Spam ของและเอฟเฟกต์ (ลบทุกอย่างในกระเป๋าด้วย)
local isSpamCleanerActive = false
local cleanerHiddenData = {}
local cleanerConnections = {}

local function isBombOrWeapon(obj)
	if obj:IsA("Explosion") then return true end
	local name = obj.Name:lower()
	return name:find("bomb") or name:find("explos") or name:find("trip") or name:find("wall") or name:find("grenade") or name:find("c4") or name:find("rocket") or name:find("mine")
end

local function hideSpamObject(obj, fromBackpack)
	if not obj or not isSpamCleanerActive then return end

	if isEquippingBoombox and obj:IsA("Tool") and string.lower(obj.Name):find("boombox", 1, true) then
		return
	end

	if fromBackpack or (obj:IsA("Tool") and obj.Parent and obj.Parent:IsA("Backpack")) then
		for _, item in ipairs(cleanerHiddenData) do
			if item.Obj == obj then return end
		end
		table.insert(cleanerHiddenData, {Obj = obj, OldParent = obj.Parent})
		pcall(function() obj.Parent = nil end)
		return
	end

	for _, item in ipairs(cleanerHiddenData) do
		if item.Obj == obj then return end
	end

	if isBombOrWeapon(obj) or obj:IsA("Tool") then
		table.insert(cleanerHiddenData, {Obj = obj, OldParent = obj.Parent})
		pcall(function() obj.Parent = nil end)
	elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Highlight") then
		if obj.Enabled then
			table.insert(cleanerHiddenData, {Obj = obj, IsEffect = true})
			obj.Enabled = false
		end
	elseif obj:IsA("ScreenGui") and obj.Name ~= "WindUI" and obj.Name ~= "MusicControlMobileBall" and obj.Name ~= "SmoothCleanerGUI" then
		local gName = obj.Name:lower()
		if gName:find("gun") or gName:find("bomb") or gName:find("tool") or gName:find("weapon") or gName:find("trip") then
			table.insert(cleanerHiddenData, {Obj = obj, OldParent = obj.Parent})
			pcall(function() obj.Parent = nil end)
		end
	end
end

local function initialSpamScan()
	for _, player in ipairs(Players:GetPlayers()) do
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			for _, tool in ipairs(backpack:GetChildren()) do
				hideSpamObject(tool, true)
			end
		end

		if player ~= Players.LocalPlayer then
			local char = player.Character
			if char then
				for _, tool in ipairs(char:GetChildren()) do hideSpamObject(tool) end
			end

			local pgui = player:FindFirstChildOfClass("PlayerGui")
			if pgui then
				for _, gui in ipairs(pgui:GetChildren()) do hideSpamObject(gui) end
			end
		end
	end

	for _, obj in ipairs(workspace:GetDescendants()) do
		hideSpamObject(obj)
	end
end

local function toggleSpamCleaner(state)
	isSpamCleanerActive = state
	if isSpamCleanerActive then
		initialSpamScan()

		local conn1 = workspace.DescendantAdded:Connect(function(obj)
			task.wait()
			hideSpamObject(obj)
		end)
		table.insert(cleanerConnections, conn1)

		for _, player in ipairs(Players:GetPlayers()) do
			local backpack = player:FindFirstChildOfClass("Backpack")
			if backpack then
				local conn2 = backpack.ChildAdded:Connect(function(child)
					task.wait()
					hideSpamObject(child, true)
				end)
				table.insert(cleanerConnections, conn2)
			end
		end

		local charConn = Players.LocalPlayer.CharacterAdded:Connect(function(char)
			local bp = Players.LocalPlayer:WaitForChild("Backpack", 3)
			if bp and isSpamCleanerActive then
				local connBp = bp.ChildAdded:Connect(function(child)
					task.wait()
					hideSpamObject(child, true)
				end)
				table.insert(cleanerConnections, connBp)
			end
		end)
		table.insert(cleanerConnections, charConn)

		notify("Anti-Spam", "เปิดใช้งานลบของสแปม + ลบทุกอย่างในกระเป๋าแล้ว", "shield-check")
	else
		for _, conn in ipairs(cleanerConnections) do
			conn:Disconnect()
		end
		cleanerConnections = {}

		for _, item in ipairs(cleanerHiddenData) do
			if item.Obj then
				pcall(function()
					if item.IsEffect then
						item.Obj.Enabled = true
					elseif item.OldParent then
						item.Obj.Parent = item.OldParent
					end
				end)
			end
		end
		cleanerHiddenData = {}
		notify("Anti-Spam", "ปิดการทำงาน คืนค่าของในกระเป๋าและเอฟเฟกต์แล้ว", "shield-alert")
	end
end

AntiTab:Toggle({
	Title = "ลบของสแปม + ทุกอย่างในกระเป๋า (Anti-Spam & Lag)",
	Desc = "ลบระเบิด/อาวุธ/ของตกพื้น เอฟเฟกต์แลค และลบของทั้งหมดในกระเป๋า (Backpack)",
	Value = false,
	Callback = toggleSpamCleaner,
})

-- 5. ถือของทุกอย่างในกระเป๋าพร้อมกัน (Equip All My Backpack)
AntiTab:Button({
	Title = "ถือของทุกอย่างในกระเป๋า (Equip All My Backpack)",
	Desc = "หยิบไอเทมทุกชิ้นในกระเป๋าออกมาถือพร้อมกันทั้งหมด (รวมถึงของชิ้นเดิมที่ซ้ำกัน)",
	Icon = "hand",
	Callback = function()
		local player = Players.LocalPlayer
		local character = player.Character
		local backpack = player:FindFirstChildOfClass("Backpack")
		if not character or not backpack then
			notify("ไม่สามารถถือของได้", "ตัวละครหรือกระเป๋าไม่พร้อม", "circle-alert")
			return
		end

		local count = 0
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				tool.Parent = character
				count = count + 1
			end
		end

		if count > 0 then
			notify("ถือไอเทมทั้งหมดแล้ว", "หยิบของออกมาถือทั้งหมด " .. count .. " ชิ้น", "hand")
		else
			notify("กระเป๋าว่างเปล่า", "ไม่มีไอเทมอยู่ในกระเป๋าให้ถือ", "circle-alert")
		end
	end,
})

-- ปุ่มลอยพกพาสะดวกสำหรับมือถือ/คอม (Mobile Ball 🎵)
local function createMobileToggleBall()
	local oldBall = CoreGui:FindFirstChild("MusicControlMobileBall") or (Players.LocalPlayer:FindFirstChild("PlayerGui") and Players.LocalPlayer.PlayerGui:FindFirstChild("MusicControlMobileBall"))
	if oldBall then oldBall:Destroy() end

	local ballGui = Instance.new("ScreenGui")
	ballGui.Name = "MusicControlMobileBall"
	ballGui.ResetOnSpawn = false
	local pcallOk = pcall(function() ballGui.Parent = CoreGui end)
	if not pcallOk then ballGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

	local btn = Instance.new("ImageButton")
	btn.Name = "OpenButton"
	btn.Size = UDim2.fromOffset(45, 45)
	btn.Position = UDim2.new(0, 15, 0.5, -22)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	btn.BackgroundTransparency = 0.2
	btn.Active = true
	btn.Draggable = true
	btn.Parent = ballGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 170, 255)
	stroke.Thickness = 2
	stroke.Parent = btn

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.fromScale(1, 1)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = "🎵"
	iconLabel.TextSize = 22
	iconLabel.Parent = btn

	btn.MouseButton1Click:Connect(function()
		pcall(function()
			if Window.Toggle then
				Window:Toggle()
			elseif Window.IsOpen ~= nil then
				Window:Toggle()
			end
		end)
	end)
end

createMobileToggleBall()

notify("ระบบพร้อมใช้งาน", "กด Ctrl หรือแตะปุ่ม 🎵 เพื่อเปิด/ปิดหน้าต่าง", "music")

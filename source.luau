-- Script made by globallzin <3
--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")


--VARIABLES
local game_data = ReplicatedStorage.GameData
local pickups = game_data.Pickups
local match_ended = pickups.MatchEnded
local match_running = pickups.Running
local rev_pickup = ReplicatedStorage.Remotes.Pickups
local player = Players.LocalPlayer
local selected_team = nil
local selected_position = nil

--TEAMS
local red_players = pickups.RedPlayers
local blue_players = pickups.BluePlayers


--CREATING UI
do
	local gui = Instance.new("ScreenGui")
	gui.Name = game:GetService("HttpService"):GenerateGUID(false)
	gui.Parent = game:GetService("CoreGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.1, 0.05)
	frame.AnchorPoint = Vector2.new(1, 0.5)
	frame.Position = UDim2.fromScale(1, 0.5)
	frame.BackgroundTransparency = 1
	frame.Parent = gui

	local redteam = Instance.new("TextButton")
	redteam.Font = Enum.Font.SourceSansBold
	redteam.TextScaled = true
	redteam.Text = "Red"
	redteam.Position = UDim2.fromScale(0, 0)
	redteam.Size = UDim2.fromScale(0.3, 1)
	redteam.BackgroundColor3 = Color3.new(1, 0.32549, 0.415686)
	redteam.TextColor3 = Color3.new(0,0,0)
	redteam.Parent = frame
	local redstroke = Instance.new("UIStroke", redteam)
	local redcorner = Instance.new("UICorner", redteam)
	redstroke.Thickness = 2
	redstroke.Color = Color3.new(0,0,0)
	redstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	redstroke.Enabled = false
	redcorner.CornerRadius = UDim.new(0.1, 0)

	local blueteam = Instance.new("TextButton")
	blueteam.Font = Enum.Font.SourceSansBold
	blueteam.TextScaled = true
	blueteam.Text = "Blue"
	blueteam.AnchorPoint = Vector2.new(1, 0)
	blueteam.Position = UDim2.fromScale(1, 0)
	blueteam.Size = UDim2.fromScale(0.3, 1)
	blueteam.TextColor3 = Color3.new(0,0,0)
	blueteam.BackgroundColor3 = Color3.new(0.243137, 0.345098, 1)
	blueteam.Parent = frame
	local bluestroke = Instance.new("UIStroke", blueteam)
	local bluecorner = Instance.new("UICorner", blueteam)
	bluestroke.Thickness = 2
	bluestroke.Color = Color3.new(0,0,0)
	bluestroke.Enabled = false
	bluestroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	bluecorner.CornerRadius = UDim.new(0.1, 0)

	local positionbox = Instance.new("TextBox")
	positionbox.Font = Enum.Font.SourceSans
	positionbox.TextScaled = true
	positionbox.PlaceholderText = "Position"
	positionbox.Size = UDim2.fromScale(0.3, 1)
	positionbox.AnchorPoint = Vector2.new(0.5, 0)
	positionbox.Position = UDim2.fromScale(0.5, 0)
	positionbox.TextColor3 = Color3.new(0,0,0)
	positionbox.PlaceholderColor3 = Color3.new(0.211765, 0.211765, 0.211765)
	positionbox.TextStrokeTransparency = 1
	positionbox.Parent = frame

	local function ToggleTeam(team: string)
		if selected_team then
			bluestroke.Enabled = false
			redstroke.Enabled = false
		end

		if team == "Blue" then
			bluestroke.Enabled = true
		else
			redstroke.Enabled = true
		end

		selected_team = team
	end

	local function PositionChanged()
		local num = tonumber(positionbox.Text)

		if num then
			local clamped_pos = math.clamp(num, 1, 6)
			if num ~= clamped_pos then
				positionbox.Text = ""
			else 
				selected_position = clamped_pos
			end
		else
			positionbox.Text = ""
		end
	end

	redteam.Activated:Connect(function()
		ToggleTeam("Red")
	end)

	blueteam.Activated:Connect(function()
		ToggleTeam("Blue")
	end)

	positionbox.Changed:Connect(PositionChanged)
end


--FUNCTIONS
function JoinTeam()
	if not selected_team or not selected_position then return end
	
	local args = {
		[1] = "JoinTeam",
		[2] = {
			["teamName"] = selected_team.."Players",
			["position"] = selected_position
		}
	}

	rev_pickup:FireServer(unpack(args))
end


--RUNTIME
match_running.Changed:Connect(function()
	if match_running.Value == false then
		--Match just started
		JoinTeam()
	end
end)
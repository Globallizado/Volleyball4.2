--[[
{globallzin}
	
	Script made for game: Volleyball 4.2
	Educational purposes only!!
	I don't care if you get banned using this, and I'm not reponsible either.
	
	Last updated on: 1/15 
	
	Source code on github: Globallzin
	
]]

if getgenv().VOLLEYBALL_SCRIPT_LOADED then
	getgenv().VOLLEYBALL_SCRIPT_LOADED:Destroy()
end


--EXEC
local exec = {}


--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")


--VARIABLES
local connections = {} :: {RBXScriptConnection}
local game_data = ReplicatedStorage.GameData
local pickups = game_data.Pickups
local match_ended = pickups.MatchEnded
local match_running = pickups.Running
local rev_pickup = ReplicatedStorage.Remotes.Pickups
local player = Players.LocalPlayer
local selected_team = nil
local selected_position = nil
local line_fault = workspace.ServeLF
local rev_player_action = ReplicatedStorage.Remotes.PlayerAction
local backrow_line_fault = workspace.BackrowLF



--TEAMS
local red_players = pickups.RedPlayers
local blue_players = pickups.BluePlayers


--CREATING UI

local gui = Instance.new("ScreenGui")
gui.Name = HttpService:GenerateGUID(false)
gui.Parent = CoreGui

-- Team & Position selector UI
do
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

-- Notification UI
do
	local notification_frame = Instance.new("Frame")
	notification_frame.AnchorPoint = Vector2.new(1, 1)
	notification_frame.Size = UDim2.fromScale(0.2, 0.5)
	notification_frame.Position = UDim2.fromScale(1, 1)
	notification_frame.BackgroundTransparency = 1
	notification_frame.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Parent = notification_frame

	local notify_placeholder = Instance.new("TextLabel")
	notify_placeholder.Size = UDim2.fromScale(1, 0.1)
	notify_placeholder.TextScaled = true
	notify_placeholder.Font = Enum.Font.SourceSans
	notify_placeholder.BackgroundTransparency = 1
	notify_placeholder.TextColor3 = Color3.new(0, 0, 0)

	local text_constraint = Instance.new("UITextSizeConstraint")
	text_constraint.MaxTextSize = 20

	function CreateNotification(text: string)
		local new_notification = notify_placeholder:Clone()
		new_notification.Text = text
		new_notification.Parent = notification_frame
		
		Debris:AddItem(new_notification, 5)
	end
end


--FUNCTIONS

function JoinTeam()
	if not selected_team or not selected_position then 
		return 
	end

	local args = {
		[1] = "JoinTeam",
		[2] = {
			["teamName"] = selected_team.."Players",
			["position"] = selected_position
		}
	}

	rev_pickup:FireServer(unpack(args))
end

function BallTeleport()
	local function getNearBall(char)
    local balls = {}
    for _,ball in next, workspace:GetChildren() do
        if ball.Name == "Ball" then
            table.insert(balls, {
                ball = ball,
                distance = (char.PrimaryPart.Position - ball.BallPart.Position).Magnitude
              })
        end
    end

    local nearest = math.huge
    local chosen
    for _,ball in balls do
        if ball.distance < nearest then
            chosen = ball.ball
            nearest = ball.distance
        end
    end

    return chosen.BallPart
	end

	local char = player.Character
	local cached = char.PrimaryPart.CFrame
	local team = player.Team.Name
	local teams = {"Blue", "Red"}
	table.remove(teams, table.find(teams, team))
	team = teams[1]

	local objective = workspace._PositionAreas[team.."Players"]["1"]
	local _ball = getNearBall(char)
	rev_player_action:FireServer("Spiking")
	wait()
	char:PivotTo(CFrame.new(_ball.Position, objective.Position))
	wait()
	char:PivotTo(cached)
end


--EXEC FUNCTIONS
function exec:Destroy()
	gui:Destroy()
	
	for _,connection in next, connections do
		connection:Disconnect()
	end
end


--SETTINGS
local KEYBINDS = {
	BALL_TELEPORT_KEY = {
		BindTo = Enum.KeyCode.Y,
		Function = BallTeleport
	}
}


--RUNTIME
getgenv().VOLLEYBALL_SCRIPT_LOADED = exec

-- Remove line faults
line_fault.Position = Vector3.new(0, -1, 0)
backrow_line_fault.Position = Vector3.new(0, -1, 0)

table.insert(
	connections, 
	match_running.Changed:Connect(function()
		if match_running.Value == false then
			--Match just started
			JoinTeam()
		end
	end)
)

CreateNotification("Started auto join")
CreateNotification("Removed Backrow and Serve line fault")

table.insert(
	connections, 
	UserInputService.InputBegan:Connect(function(input, GPE)
		local respective_function

		for _,key in KEYBINDS do
			if key.BindTo == input.KeyCode then
				respective_function = key.Function
				break
			end
		end

		if not GPE and respective_function then
			local success, error_message = pcall(respective_function)

			if error_message then
				warn(error_message)
			end
		end
	end)
)
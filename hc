-- [[ Services & Vars ]] --
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")

-- [[ Config ]] --
local ForceHit = {
    Enabled = true,  
    BlankShots = false,
    HitPart = "Head",  
    Keybind = Enum.KeyCode.C,

    FOV = {
        Visible = true,
        Transparency = 0.5,
        Thickness = 1,
        Radius = 400,
        Color = Color3.fromRGB(0, 255, 0)
    }
}

-- [[ Drawings ]] -- 
local Fov = Drawing.new("Circle")
Fov.Color = ForceHit.FOV.Color
Fov.Thickness = ForceHit.FOV.Thickness
Fov.Filled = false
Fov.Transparency = ForceHit.FOV.Transparency
Fov.Radius = ForceHit.FOV.Radius

local Highlight = Instance.new("Highlight")
Highlight.Parent = game.CoreGui
Highlight.FillColor = Color3.fromRGB(0, 255, 0)
Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
Highlight.FillTransparency = 0.5
Highlight.OutlineTransparency = 0
Highlight.Enabled = false

-- [[ Functions ]] --
local function GetClosestPlayer()
    local ClosestDistance, ClosestPart, ClosestCharacter = nil, nil, nil
    local MousePosition = UserInput:GetMouseLocation()

    for _, Player in next, Players:GetPlayers() do
        if Player ~= LocalPlayer and Player.Character then
            local Character = Player.Character
            local HitPart = Character:FindFirstChild(ForceHit.HitPart)
            local Humanoid = Character:FindFirstChild("Humanoid")
            local ForceField = Character:FindFirstChildOfClass("ForceField")

            if HitPart and Humanoid and Humanoid.Health > 0 and not ForceField then
                local ScreenPosition, Visible = workspace.CurrentCamera:WorldToScreenPoint(HitPart.Position)
                if Visible then
                    local Distance = (MousePosition - Vector2.new(ScreenPosition.X, ScreenPosition.Y)).Magnitude
                    if Distance <= ForceHit.FOV.Radius and (not ClosestDistance or Distance < ClosestDistance) then
                        ClosestDistance, ClosestPart, ClosestCharacter = Distance, HitPart, Character
                    end
                end
            end
        end
    end
    return ClosestPart, ClosestCharacter
end

-- [[ Rendering ]] --
RunService.RenderStepped:Connect(function()
    if ForceHit.Enabled then
        Fov.Visible = ForceHit.FOV.Visible
        Fov.Position = UserInput:GetMouseLocation()
        Fov.Radius = ForceHit.FOV.Radius

        local target, character = SelectedTarget or CachedClosestPlayer, nil
        if target and target.Parent then
            character = target.Parent
        end
        if character then
            Highlight.Adornee = character
            Highlight.Enabled = true
        else
            Highlight.Enabled = false
        end
    else
        Fov.Visible = false
        Highlight.Enabled = false
    end
end)

RunService.Heartbeat:Connect(function()
    if not ForceHit.Enabled then return end 
    local ClosestPart, ClosestCharacter = GetClosestPlayer()
    CachedClosestPlayer = ClosestPart
end)

-- [[ Hook ]] --
local OriginalNameCall; OriginalNameCall = hookmetamethod(game, "__namecall", function(Object, ...)
    local Arguments = {...}
    local NameCallMethod = getnamecallmethod()

    if not ForceHit.Enabled then
        return OriginalNameCall(Object, ...)
    end

    if NameCallMethod == "InvokeServer" and Object.Name == "MainFunction" and #Arguments > 0 and Arguments[1] == "GunCheck" then
        return nil
    end

    if NameCallMethod == "FireServer" and Object.Name == "MainEvent" and #Arguments > 0 and Arguments[1] == "Shoot" then
        local AimPart = SelectedTarget or CachedClosestPlayer
        if AimPart then
            if Arguments[2] and #Arguments[2] > 0 then
                for _, Table in pairs(Arguments[2][1]) do
                    Table["Instance"] = AimPart
                end
                for _, Table in pairs(Arguments[2][2]) do
                    Table["thePart"] = AimPart
                    Table["theOffset"] = CFrame.new()
                end
            end
            return OriginalNameCall(Object, unpack(Arguments))
        end
    end
    
    return OriginalNameCall(Object, ...)
end)
-- [[ Nigger]] --
RunService.Heartbeat:Connect(function()
    if not ForceHit.BlankShots then return end 

    local HasTool = false
    for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            HasTool = true
            break
        end
    end

    if not HasTool then return end 

    local AimPart = CachedClosestPlayer
    local AimChar = AimPart and AimPart.Parent
    if AimChar then
        local ForceField = AimChar:FindFirstChildOfClass("ForceField")
        if not ForceField then  
            if AimPart and MainEvent then
                local args = {
                    "Shoot",
                    {
                        {
                            [1] = {
                                ["Instance"] = AimPart,
                                ["Normal"] = Vector3.new(0.9937344193458557, 0.10944880545139313, -0.022651424631476402),
                                ["Position"] = Vector3.new(-141.78562927246094, 33.89368438720703, -365.6424865722656)
                            },
                            [2] = {
                                ["Instance"] = AimPart,
                                ["Normal"] = Vector3.new(0.9937344193458557, 0.10944880545139313, -0.022651424631476402),
                                ["Position"] = Vector3.new(-141.78562927246094, 33.89368438720703, -365.6424865722656)
                            },
                            [3] = {
                                ["Instance"] = AimPart,
                                ["Normal"] = Vector3.new(0.9937343597412109, 0.10944879800081253, -0.022651422768831253),
                                ["Position"] = AimPart.Position 
                            },
                            [4] = {
                                ["Instance"] = AimPart,
                                ["Normal"] = Vector3.new(0.9937344193458557, 0.10944880545139313, -0.022651424631476402),
                                ["Position"] = AimPart.Position 
                            },
                            [5] = {
                                ["Instance"] = AimPart,
                                ["Normal"] = Vector3.new(0.9937344193458557, 0.10944880545139313, -0.022651424631476402),
                                ["Position"] = Vector3.new(-141.79481506347656, 34.033607482910156, -365.369384765625)
                            }
                        },
                        {
                            [1] = {
                                ["thePart"] = AimPart,
                                ["theOffset"] = CFrame.new(0, 0, 0)
                            },
                            [2] = {
                                ["thePart"] = AimPart,
                                ["theOffset"] = CFrame.new(0, 0, 0)
                            },
                            [3] = {
                                ["thePart"] = AimPart,
                                ["theOffset"] = CFrame.new(0, 0, 0)
                            },
                            [4] = {
                                ["thePart"] = AimPart,
                                ["theOffset"] = CFrame.new(0, 0, 0)
                            },
                            [5] = {
                                ["thePart"] = AimPart,
                                ["theOffset"] = CFrame.new(0, 0, 0)
                            }
                        },
                        Players.LocalPlayer.Character.Head.Position,
                        Players.LocalPlayer.Character.Head.Position,
                        workspace:GetServerTimeNow()
                    }
                }

                MainEvent:FireServer(unpack(args))
            end
        end
    end
end)

-- [[ Keybind  ]] --
UserInput.InputBegan:Connect(function(Input, GameProcessed)
    if not GameProcessed and Input.KeyCode == ForceHit.Keybind then
        ForceHit.Enabled = not ForceHit.Enabled
    end
end)
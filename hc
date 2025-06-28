-- [[ Services & Vars ]] --
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
local Camera = workspace.CurrentCamera

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
Fov.Visible = ForceHit.FOV.Visible
Fov.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local Highlight = Instance.new("Highlight")
Highlight.Parent = game.CoreGui
Highlight.FillColor = Color3.fromRGB(0, 255, 0)
Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
Highlight.FillTransparency = 0.5
Highlight.OutlineTransparency = 0
Highlight.Enabled = false

-- [[ Functions ]] --
local function GetClosestPlayer()
    local ClosestDistance, ClosestPart, ClosestCharacter = math.huge, nil, nil
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Character = Player.Character
            local HitPart = Character:FindFirstChild(ForceHit.HitPart)
            local Humanoid = Character:FindFirstChild("Humanoid")
            local ForceField = Character:FindFirstChildOfClass("ForceField")

            if HitPart and Humanoid and Humanoid.Health > 0 and not ForceField then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(HitPart.Position)
                if OnScreen then
                    local Distance = (ScreenCenter - Vector2.new(ScreenPos.X, ScreenPos.Y)).Magnitude
                    if Distance <= ForceHit.FOV.Radius and Distance < ClosestDistance then
                        ClosestDistance = Distance
                        ClosestPart = HitPart
                        ClosestCharacter = Character
                    end
                end
            end
        end
    end

    return ClosestPart, ClosestCharacter
end

-- [[ Runtime ]] --
local CachedClosestPlayer = nil

RunService.RenderStepped:Connect(function()
    if ForceHit.Enabled then
        Fov.Visible = ForceHit.FOV.Visible
        Fov.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        Fov.Radius = ForceHit.FOV.Radius

        local target, character = CachedClosestPlayer, nil
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
    local Arguments = { ... }
    local Method = getnamecallmethod()

    if not ForceHit.Enabled then
        return OriginalNameCall(Object, ...)
    end

    if Method == "InvokeServer" and Object.Name == "MainFunction" and Arguments[1] == "GunCheck" then
        return nil
    end

    if Method == "FireServer" and Object.Name == "MainEvent" and Arguments[1] == "Shoot" then
        local AimPart = CachedClosestPlayer
        if AimPart and Arguments[2] and #Arguments[2] > 0 then
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

    return OriginalNameCall(Object, ...)
end)

-- [[ BlankShots ]] --
RunService.Heartbeat:Connect(function()
    if not ForceHit.BlankShots then return end

    local HasTool = false
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            HasTool = true
            break
        end
    end

    if not HasTool then return end

    local AimPart = CachedClosestPlayer
    local AimChar = AimPart and AimPart.Parent
    if AimChar and not AimChar:FindFirstChildOfClass("ForceField") then
        if AimPart and MainEvent then
            local args = {
                "Shoot",
                {
                    {
                        [1] = { ["Instance"] = AimPart, ["Normal"] = Vector3.new(), ["Position"] = AimPart.Position },
                        [2] = { ["Instance"] = AimPart, ["Normal"] = Vector3.new(), ["Position"] = AimPart.Position },
                        [3] = { ["Instance"] = AimPart, ["Normal"] = Vector3.new(), ["Position"] = AimPart.Position },
                        [4] = { ["Instance"] = AimPart, ["Normal"] = Vector3.new(), ["Position"] = AimPart.Position },
                        [5] = { ["Instance"] = AimPart, ["Normal"] = Vector3.new(), ["Position"] = AimPart.Position },
                    },
                    {
                        [1] = { ["thePart"] = AimPart, ["theOffset"] = CFrame.new() },
                        [2] = { ["thePart"] = AimPart, ["theOffset"] = CFrame.new() },
                        [3] = { ["thePart"] = AimPart, ["theOffset"] = CFrame.new() },
                        [4] = { ["thePart"] = AimPart, ["theOffset"] = CFrame.new() },
                        [5] = { ["thePart"] = AimPart, ["theOffset"] = CFrame.new() },
                    },
                    LocalPlayer.Character.Head.Position,
                    LocalPlayer.Character.Head.Position,
                    workspace:GetServerTimeNow()
                }
            }

            MainEvent:FireServer(unpack(args))
        end
    end
end)

-- [[ Keybind ]] --
UserInput.InputBegan:Connect(function(Input, GameProcessed)
    if not GameProcessed and Input.KeyCode == ForceHit.Keybind then
        ForceHit.Enabled = not ForceHit.Enabled
    end
end)
-- // Services & Vars
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")

-- // Config
local ForceHit = {
    Enabled = true,
    BlankShots = false,
    HitPart = "Head",
    Keybind = Enum.KeyCode.C,
    FOV = {
        Visible = true,
        Transparency = 1,
        Thickness = 1,
        Radius = 200,
        Color = Color3.fromRGB(255, 0, 0)
    }
}

-- // Drawings
local Fov = Drawing.new("Circle")
Fov.Color = ForceHit.FOV.Color
Fov.Thickness = ForceHit.FOV.Thickness
Fov.Filled = false
Fov.Transparency = ForceHit.FOV.Transparency
Fov.Radius = ForceHit.FOV.Radius
Fov.Visible = ForceHit.FOV.Visible
Fov.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local RedDot = Drawing.new("Circle")
RedDot.Color = Color3.fromRGB(255, 0, 0)
RedDot.Thickness = 2
RedDot.Filled = true
RedDot.Radius = 5
RedDot.Visible = false

-- // Get Closest Target (skip forcefield)
local function GetClosestPlayer()
    local ClosestDistance, ClosestPart = math.huge, nil
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Character = Player.Character
            local HitPart = Character:FindFirstChild(ForceHit.HitPart)
            local Humanoid = Character:FindFirstChild("Humanoid")
            local Shield = Character:FindFirstChildOfClass("ForceField")

            -- Skip players with ForceField active
            if Shield then
                continue
            end

            if HitPart and Humanoid and Humanoid.Health > 0 then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(HitPart.Position)
                if OnScreen then
                    local Distance = (ScreenCenter - Vector2.new(ScreenPos.X, ScreenPos.Y)).Magnitude
                    if Distance <= ForceHit.FOV.Radius and Distance < ClosestDistance then
                        ClosestDistance = Distance
                        ClosestPart = HitPart
                    end
                end
            end
        end
    end

    return ClosestPart
end

-- // Update FOV circle and red dot
RunService.RenderStepped:Connect(function()
    Fov.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    Fov.Radius = ForceHit.FOV.Radius
    Fov.Visible = ForceHit.Enabled and ForceHit.FOV.Visible

    local target = GetClosestPlayer()
    if target then
        local screenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
        if onScreen then
            RedDot.Position = Vector2.new(screenPos.X, screenPos.Y)
            RedDot.Visible = true
        else
            RedDot.Visible = false
        end
    else
        RedDot.Visible = false
    end
end)

-- // Monitor forcefields to shoot immediately after they disappear
local lastSeenForceFieldTargets = {}

RunService.Heartbeat:Connect(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local shield = plr.Character:FindFirstChildOfClass("ForceField")
            if shield then
                lastSeenForceFieldTargets[plr] = true
            elseif lastSeenForceFieldTargets[plr] then
                -- ForceField just disappeared, clear flag to allow shooting immediately
                lastSeenForceFieldTargets[plr] = nil
            end
        end
    end
end)

-- // Triggerbot + ForceHit logic
task.spawn(function()
    while true do
        task.wait(0.1)
        if not ForceHit.Enabled then continue end

        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if not tool then continue end

        -- Find target ignoring forcefield players, but shoot immediately if their forcefield just disappeared
        local AimPart, AimPlayer = nil, nil
        local closestDistance = math.huge
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local char = plr.Character
                local shield = char:FindFirstChildOfClass("ForceField")
                local hitPart = char:FindFirstChild(ForceHit.HitPart)
                local humanoid = char:FindFirstChild("Humanoid")
                if hitPart and humanoid and humanoid.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hitPart.Position)
                    if onScreen then
                        local dist = (screenCenter - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if dist <= ForceHit.FOV.Radius and dist < closestDistance then
                            if shield then
                                -- Skip shooting if forcefield active unless it just disappeared
                                if lastSeenForceFieldTargets[plr] then
                                    -- Still skip until forcefield disappears
                                else
                                    -- ForceField disappeared, allow shooting immediately
                                    AimPart = hitPart
                                    AimPlayer = plr
                                    closestDistance = dist
                                end
                            else
                                AimPart = hitPart
                                AimPlayer = plr
                                closestDistance = dist
                            end
                        end
                    end
                end
            end
        end

        if AimPart and MainEvent then
            local args = {
                "Shoot",
                {
                    {
                        [1] = { Instance = AimPart, Normal = Vector3.new(), Position = AimPart.Position },
                        [2] = { Instance = AimPart, Normal = Vector3.new(), Position = AimPart.Position },
                        [3] = { Instance = AimPart, Normal = Vector3.new(), Position = AimPart.Position },
                        [4] = { Instance = AimPart, Normal = Vector3.new(), Position = AimPart.Position },
                        [5] = { Instance = AimPart, Normal = Vector3.new(), Position = AimPart.Position },
                    },
                    {
                        [1] = { thePart = AimPart, theOffset = CFrame.new() },
                        [2] = { thePart = AimPart, theOffset = CFrame.new() },
                        [3] = { thePart = AimPart, theOffset = CFrame.new() },
                        [4] = { thePart = AimPart, theOffset = CFrame.new() },
                        [5] = { thePart = AimPart, theOffset = CFrame.new() },
                    },
                    LocalPlayer.Character.Head.Position,
                    LocalPlayer.Character.Head.Position,
                    workspace:GetServerTimeNow()
                }
            }
            MainEvent:FireServer(unpack(args))

            -- Ammo UI fix
            if tool and tool.Activated then
                pcall(function()
                    tool:Activate()
                end)
            end
        end
    end
end)

-- // Toggle Key
UserInput.InputBegan:Connect(function(Input, GameProcessed)
    if not GameProcessed and Input.KeyCode == ForceHit.Keybind then
        ForceHit.Enabled = not ForceHit.Enabled
    end
end)
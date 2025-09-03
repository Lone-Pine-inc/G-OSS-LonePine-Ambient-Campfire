include("shared.lua")

local SOUND_PATH = "lonepine_campfire/"

function ENT:Initialize()
end

function ENT:Think()
    if self:GetFireEnabled() then
        if not self.FireSound or self.CurrentSound ~= self:GetSoundName() then
            if self.FireSound then self.FireSound:Stop() end
            self.CurrentSound = self:GetSoundName()
            self.FireSound = CreateSound(self, SOUND_PATH .. self.CurrentSound .. ".mp3")
            self.FireSound:PlayEx(0, 100)
        end
        if self.FireSound then
            -- Ensure continuous playback even if the source file doesn't loop
            if not self.FireSound:IsPlaying() then
                self.FireSound:PlayEx(0, 100)
            end
            local ply = LocalPlayer()
            local dist = ply:GetPos():Distance(self:GetPos())
            local maxDist = 600
            local vol = math.Clamp(1 - dist / maxDist, 0, 1) * self:GetIntensity()
            self.FireSound:ChangeVolume(vol, 0)
        end
        local dlight = DynamicLight(self:EntIndex())
        if dlight then
            local intensity = self:GetIntensity()
            -- Subtle, non-uniform flicker
            local t = CurTime() * 12 + self:EntIndex()
            local flicker = 0.9 + 0.1 * math.sin(t) + 0.05 * math.sin(t * 0.37) + math.Rand(-0.02, 0.02)
            flicker = math.Clamp(flicker, 0.8, 1.2)

            -- Tamed brightness/size mapping so Intensity=1 isn't overblown
            local baseBrightness = 0.9 + intensity * 0.5 -- ~1.4 at 1.0
            local baseSize = 80 + intensity * 60         -- ~140 at 1.0

            dlight.pos = self:GetPos() + Vector(0,0,20)
            dlight.r = 255
            dlight.g = 140 + 10 * flicker
            dlight.b = 40 + 5 * flicker
            dlight.brightness = baseBrightness * flicker
            local computedSize = baseSize * (0.95 + 0.1 * math.sin(t * 0.7))
            dlight.Size = computedSize
            dlight.Decay = computedSize * 5
            dlight.DieTime = CurTime() + 0.5
        end
    else
        if self.FireSound then
            self.FireSound:FadeOut(1)
            self.FireSound = nil
        end
    end
    self:NextThink(CurTime())
    return true
end

net.Receive("lp_campfire_open", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Campfire Settings")
    frame:SetSize(300,150)
    frame:Center()
    frame:MakePopup()

    local slider = vgui.Create("DNumSlider", frame)
    slider:SetPos(10,30)
    slider:SetSize(280,40)
    slider:SetText("Intensity")
    slider:SetMin(0.1)
    slider:SetMax(5)
    slider:SetValue(ent:GetIntensity())

    local combo = vgui.Create("DComboBox", frame)
    combo:SetPos(10,70)
    combo:SetSize(280,20)
    combo:SetValue(ent:GetSoundName())
    combo:AddChoice("fire1")
    combo:AddChoice("fire2")
    combo:AddChoice("fire3")

    local btn = vgui.Create("DButton", frame)
    btn:SetPos(10,100)
    btn:SetSize(280,20)
    btn:SetText("Apply")
    btn.DoClick = function()
        net.Start("lp_campfire_update")
        net.WriteEntity(ent)
        net.WriteFloat(slider:GetValue())
        net.WriteString(combo:GetSelected() or ent:GetSoundName())
        net.SendToServer()
        frame:Close()
    end
end)

function ENT:OnRemove()
    if self.FireSound then self.FireSound:Stop() end
end

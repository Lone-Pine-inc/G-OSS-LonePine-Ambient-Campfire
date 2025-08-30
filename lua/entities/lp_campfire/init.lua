AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

util.AddNetworkString("lp_campfire_open")
util.AddNetworkString("lp_campfire_update")

function ENT:Initialize()
    self:SetModel("models/props_unique/firepit_campground.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:SetFireEnabled(false)
    self:SetIntensity(0.5)
    self:SetSoundName("fire1")

    self.UsePlayers = {}
end

function ENT:Use(activator)
    if not activator:IsPlayer() then return end
    self.UsePlayers[activator] = self.UsePlayers[activator] or CurTime()
end

function ENT:Think()
    for ply, start in pairs(self.UsePlayers) do
        if not IsValid(ply) then
            self.UsePlayers[ply] = nil
        elseif ply:KeyDown(IN_USE) then
            if CurTime() - start >= 3 then
                net.Start("lp_campfire_open")
                net.WriteEntity(self)
                net.Send(ply)
                self.UsePlayers[ply] = nil
            end
        else
            self.UsePlayers[ply] = nil
            self:ToggleFire()
        end
    end
    self:NextThink(CurTime())
    return true
end

function ENT:ToggleFire()
    local enabled = not self:GetFireEnabled()
    self:SetFireEnabled(enabled)
    if enabled then
        self:StartFire()
    else
        self:StopFire()
    end
end

function ENT:StartFire()
    if IsValid(self.FireEntity) then self.FireEntity:Remove() end
    local fire = ents.Create("env_fire")
    if not IsValid(fire) then return end
    fire:SetPos(self:GetPos() + Vector(0,0,10))
    fire:SetKeyValue("firesize", tostring(math.Clamp(64 * self:GetIntensity(), 0, 128)))
    fire:SetKeyValue("fireattack", "4")
    fire:SetKeyValue("health", "0")
    fire:SetKeyValue("damagescale", "0")
    fire:SetKeyValue("spawnflags", "133")
    fire:SetParent(self)
    fire:Spawn()
    fire:Activate()
    fire:Fire("StartFire", "", 0)
    self.FireEntity = fire
end

function ENT:StopFire()
    if IsValid(self.FireEntity) then
        self.FireEntity:Fire("Extinguish", "", 0)
        self.FireEntity:Remove()
        self.FireEntity = nil
    end
end

function ENT:UpdateFire()
    if self:GetFireEnabled() then
        self:StartFire()
    else
        self:StopFire()
    end
end

net.Receive("lp_campfire_update", function(len, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) or ent:GetClass() ~= "lp_campfire" then return end
    if ent:GetPos():Distance(ply:GetPos()) > 200 then return end

    local intensity = math.Clamp(net.ReadFloat(), 0.1, 5)
    local snd = net.ReadString()

    ent:SetIntensity(intensity)
    ent:SetSoundName(snd)
    ent:UpdateFire()
end)

function ENT:OnRemove()
    self:StopFire()
end

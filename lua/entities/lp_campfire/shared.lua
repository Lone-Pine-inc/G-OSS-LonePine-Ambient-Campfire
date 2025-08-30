ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "LonePine Campfire"
ENT.Category = "Server"
ENT.Spawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "FireEnabled")
    self:NetworkVar("Float", 0, "Intensity")
    self:NetworkVar("String", 0, "SoundName")
end

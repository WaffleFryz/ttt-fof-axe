AddCSLuaFile("shared.lua")

sound.Add({
	name="Axe.HitWorld",
	channel=CHAN_STATIC,
	volume=1,
	level=75,
	pitch=100,
	sound="weapons/axe/crowbar_impact2.wav"
})

ENT.PrintName			= "Hatchet"
ENT.Type				= "anim"
ENT.Base				= "base_anim"

//spawnable
ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.AdminSpawnable		= false
ENT.CanPickup 			= false

local ttt_fof_axe_throw_damage = CreateConVar(
	"ttt_fof_axe_throw_damage", "40", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Damage of Axe SecondaryFire (Default: 40 / FoF Value: 50)"
)

function ENT:Initialize()
	
	self:SetModel("models/weapons/w_axe_proj.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	self.Weaponised = false
	self.InFlight = true
	self.Damage = ttt_fof_axe_throw_damage:GetFloat()
	
	self.FleshHit = {
		Sound("physics/body/body_medium_break3.wav")
	}
end

if SERVER then

	function ENT:PhysicsCollide(data, phys)
		self.InFlight = false
		
		local attacker
		if IsValid(self.Owner) then
			attacker = self.Owner
		else
			attacker = self.Entity
			return
		end
		
		local target = data.HitEntity

		if target:IsWorld() then
			util.Decal("ManhackCut", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal)
			self:EmitSound("Axe.HitWorld")
		elseif target:Health() then
			target:TakeDamage(self.Damage, attacker, self.Entity)
			phys:EnableCollisions(false)
			if target:IsPlayer() or target:IsNPC() then
				self:EmitSound("Axe.Hit")
				self:EmitSound(self.FleshHit[1])
			else
				self:EmitSound("Axe.HitWorld")
			end
		end
		
		self.Owner = nil

		if not self.Weaponised then
			self:BecomeWeaponDelayed(data.HitEntity)
		end
	end
		
	function ENT:BecomeWeapon(target)
		self.Weaponised = true
		
		local wep = ents.Create("weapon_ttt_fof_axe")
		wep:SetPos(self:GetPos()) 
		wep:SetAngles(self:GetAngles() + Angle(0,0,-90))
		
		wep.IsDropped = true
		
		self:Remove()

		wep:Spawn()

		// Too unpredictable. Leads to weird interactions
		-- wep:GetPhysicsObject():SetVelocity(self:GetVelocity())

		return wep
	end
	
	function ENT:BecomeWeaponDelayed(target)
      -- delay the weapon-replacement a tick because Source gets very angry
      -- if you do fancy stuff in a physics callback
      local knife = self
      timer.Simple(0,
                   function()
                      if IsValid(knife) and not knife.Weaponised then
                         knife:BecomeWeapon(target)
                      end
                   end)
    end
end

function ENT:Use(activator)
	if not self.InFlight and activator:IsPlayer() then
		activator:Give("weapon_ttt_fof_axe")
		self.Entity:Remove()
	end
end
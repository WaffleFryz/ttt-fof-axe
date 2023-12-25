AddCSLuaFile()

sound.Add({
	name="Brass.Hit",
	channel=CHAN_WEAPON,
	volume=1,
	level=75,
	pitch=100,
	sound={
	  "weapons/fists/fists_punch_brass.wav",
	  "weapons/fists/fists_punch_brass2.wav"
	}
})

local ttt_fof_brass_damage = CreateConVar(
	"ttt_fof_brass_damage", "35", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Damage of Brass Knuckles PrimaryFire (Default: 35 / FoF Value: 35)"
)

local ttt_fof_brass_disarm_chance = CreateConVar(
   "ttt_fof_brass_disarm_chance", "0.5", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Chance of Brass Knuckles disarming. 0 = Never, 1 = Always (Default: 0.5)"
)

local ttt_fof_fists_delay = GetConVar("ttt_fof_fists_delay")

if not EQUIP_DUSTERS then
	EQUIP_DUSTERS = GenerateNewEquipmentID()
	
	local dusters = {
		id = EQUIP_DUSTERS,
		type = "item_passive",
		material = "vgui/ttt/brassknuckles/ic_brassknuckles",
		name = "Brass Knuckles",
		desc = "Makes you chuckle",
	}
	
	table.insert(EquipmentItems[ROLE_TRAITOR], dusters)
	table.insert(EquipmentItems[ROLE_DETECTIVE], dusters)
end

SWEP.HoldType = "fist"

if CLIENT then
   SWEP.PrintName            = "Brass Knuckles"
   SWEP.Slot                 = 0

   SWEP.DrawCrosshair        = false
   SWEP.ViewModelFlip        = false
   SWEP.ViewModelFOV         = 54

   SWEP.Icon                 = "vgui/ttt/brassknuckles/ic_brassknuckles"
end

SWEP.Base                    = "weapon_tttbase"

SWEP.UseHands                = true
SWEP.ViewModel               = "models/weapons/v_brass_knuckles.mdl"
SWEP.WorldModel              = ""

SWEP.Primary.Damage          = ttt_fof_brass_damage:GetFloat()
SWEP.Primary.ClipSize        = -1
SWEP.Primary.DefaultClip     = -1
SWEP.Primary.Automatic       = true
SWEP.Primary.Delay           = ttt_fof_fists_delay:GetFloat()
SWEP.Primary.Ammo            = "none"

SWEP.Secondary.Automatic       = true
SWEP.Secondary.Delay         = 5

SWEP.HeadshotMultiplier 	 = 1.4
SWEP.Kind                    = WEAPON_MELEE
SWEP.WeaponID                = AMMO_CROWBAR
SWEP.InLoadoutFor            = nil

SWEP.NoSights                = true
SWEP.IsSilent                = false

SWEP.AutoSpawnable           = false

SWEP.AllowDelete             = false -- never removed for weapon reduction
SWEP.AllowDrop               = false

local sound_single = Sound("weapons/slam/throw.wav")

local ttt_fof_walkspeed_crowbar = GetConVar("ttt_fof_walkspeed_crowbar")

function SWEP:Equip()
   local ply = self:GetOwner()
   local lastActiveWep = ply:GetActiveWeapon()

   ply:StripWeapon("weapon_ttt_fof_fists")
   
   if lastActiveWep:GetClass() == "weapon_ttt_fof_fists" then
      ply:SelectWeapon("weapon_ttt_fof_brass")
   end
end

function SWEP:ManipulateOwnerMoveData(ply, mv)
	local speed = ttt_fof_walkspeed_crowbar:GetFloat()

	if speed == 220
		or ply:GetMoveType() ~= MOVETYPE_WALK
		or ply:InVehicle()
		or mv:GetSideSpeed() ~= 0
		or mv:GetForwardSpeed() <= 0
		or not ply:OnGround()
	then
		return
	end

	speed = mv:GetMaxSpeed() * (speed / 220)

	mv:SetMaxSpeed(speed)
	mv:SetMaxClientSpeed(speed)
end

function SWEP:PrimaryAttack()
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )

   if not IsValid(self:GetOwner()) then return end

   if self:GetOwner().LagCompensation then -- for some reason not always true
      self:GetOwner():LagCompensation(true)
   end

   local spos = self:GetOwner():GetShootPos()
   local sdest = spos + (self:GetOwner():GetAimVector() * 70)

   local tr_main = util.TraceLine({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL})
   local hitEnt = tr_main.Entity

   self.Weapon:EmitSound("Fists.Miss")

   if IsValid(hitEnt) or tr_main.HitWorld then
      self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )

      if not (CLIENT and (not IsFirstTimePredicted())) then
         local edata = EffectData()
         edata:SetStart(spos)
         edata:SetOrigin(tr_main.HitPos)
         edata:SetNormal(tr_main.Normal)
         edata:SetSurfaceProp(tr_main.SurfaceProps)
         edata:SetHitBox(tr_main.HitBox)
         --edata:SetDamageType(DMG_CLUB)
         edata:SetEntity(hitEnt)

         if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
            util.Effect("BloodImpact", edata)

            self:EmitSound("Brass.Hit")

            -- does not work on players rah
            --util.Decal("Blood", tr_main.HitPos + tr_main.HitNormal, tr_main.HitPos - tr_main.HitNormal)

            -- do a bullet just to make blood decals work sanely
            -- need to disable lagcomp because firebullets does its own
            self:GetOwner():LagCompensation(false)
            self:GetOwner():FireBullets({Num=1, Src=spos, Dir=self:GetOwner():GetAimVector(), Spread=Vector(0,0,0), Tracer=0, Force=1, Damage=0})
         else
            util.Effect("Impact", edata)
         end
      end
   else
      self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
   end


   if CLIENT then
      -- used to be some shit here
   else -- SERVER

      -- Do another trace that sees nodraw stuff like func_button
      local tr_all = nil
      tr_all = util.TraceLine({start=spos, endpos=sdest, filter=self:GetOwner()})
      
      self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

      if hitEnt and hitEnt:IsValid() then
         local disarm = math.random(1,100) / 100
         local dmg = DamageInfo()
         dmg:SetDamage(self.Primary.Damage)
         dmg:SetAttacker(self:GetOwner())
         dmg:SetInflictor(self.Weapon)
         dmg:SetDamageForce(self:GetOwner():GetAimVector() * 1500)
         dmg:SetDamagePosition(self:GetOwner():GetPos())
         dmg:SetDamageType(DMG_GENERIC)

         hitEnt:DispatchTraceAttack(dmg, spos + (self:GetOwner():GetAimVector() * 3), sdest)

         local wep = hitEnt:IsPlayer() and hitEnt:GetActiveWeapon() or nil 

         if IsValid(wep) and wep.AllowDrop then
            if disarm <= ttt_fof_brass_disarm_chance:GetFloat() then
               hitEnt:SelectWeapon("weapon_ttt_unarmed")
               local vel = self:GetOwner():GetAimVector() * 300
               vel.z = vel.z + 300

               hitEnt:DropWeapon(wep, nil, vel)

            end
         end

--         self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )         

--         self:GetOwner():TraceHullAttack(spos, sdest, Vector(-16,-16,-16), Vector(16,16,16), 30, DMG_CLUB, 11, true)
--         self:GetOwner():FireBullets({Num=1, Src=spos, Dir=self:GetOwner():GetAimVector(), Spread=Vector(0,0,0), Tracer=0, Force=1, Damage=20})
      
      else
--         if tr_main.HitWorld then
--            self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )
--         else
--            self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
--         end

         -- See if our nodraw trace got the goods
         if tr_all.Entity and tr_all.Entity:IsValid() then
            self:OpenEnt(tr_all.Entity)
         end
      end
   end

   if self:GetOwner().LagCompensation then
      self:GetOwner():LagCompensation(false)
   end
end

function SWEP:SecondaryAttack()
   self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay/2 )
   self.Weapon:SetNextSecondaryFire( CurTime() + 0.1 )

   if self:GetOwner().LagCompensation then
      self:GetOwner():LagCompensation(true)
   end

   local tr = self:GetOwner():GetEyeTrace(MASK_SHOT)

   if tr.Hit and IsValid(tr.Entity) and tr.Entity:IsPlayer() and (self:GetOwner():EyePos() - tr.HitPos):Length() < 100 then
      local ply = tr.Entity

      if SERVER and (not ply:IsFrozen()) then
         local pushvel = tr.Normal * GetConVar("ttt_crowbar_pushforce"):GetFloat()

         -- limit the upward force to prevent launching
         pushvel.z = math.Clamp(pushvel.z, 50, 100)

         ply:SetVelocity(ply:GetVelocity() + pushvel)
         self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

         ply.was_pushed = {att=self:GetOwner(), t=CurTime(), wep=self:GetClass()} --, infl=self}
      end

      self.Weapon:EmitSound(sound_single)      
      self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )

      self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
      self.Weapon:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
   end
   
   if self:GetOwner().LagCompensation then
      self:GetOwner():LagCompensation(false)
   end
end

local host_timescale = GetConVar("host_timescale")

function SWEP:GetViewModelPosition(pos, ang)
	local owner = self:GetOwner()

	local kick

	if IsValid(owner) then
		kick = owner:GetNW2Float("TTT_FOF_Kicking")
   else return end

	local curtime = self.fCurrentTime
		and self.fCurrentTime + (SysTime() - self.fCurrentSysTime) * game.GetTimeScale() * host_timescale:GetFloat()
		or CurTime()

	if curtime > kick then
		return self.BaseClass.GetViewModelPosition(self, pos, ang)
	end

	local mult = math.Clamp(kick - curtime, 0, 1)

	mult = mult < 2 / 3
		and math.ease.InOutQuad(mult * 1.5)
		or math.ease.OutQuad((1 - mult) * 3)

	local rgt, fwd, up = ang:Right(), ang:Forward(), ang:Up()

	if self.IronSightsAng then
		ang:RotateAroundAxis(rgt, 15 * mult)
		ang:RotateAroundAxis(up, -2 * mult)
	end

	rgt:Mul(2 * mult)
	fwd:Mul(-5 * mult)
	up:Mul(-5 * mult)

	pos:Add(rgt)
	pos:Add(fwd)
	pos:Add(up)

	return self.BaseClass.GetViewModelPosition(self, pos, ang)
end

function SWEP:GetClass()
	return "weapon_ttt_fof_brass"
end

local ttt_fof_axe_glow_distance = GetConVar("ttt_fof_axe_glow_distance")

function SWEP:Think()
   if CLIENT then
      ply = self:GetOwner()

      local function getNearbyAxes()
         axes = {}
         for i, ent in ipairs(ents.FindByClass("weapon_ttt_fof_axe")) do
            if not ply:HasWeapon("weapon_ttt_fof_axe")   -- ply no have axe
               and not ent:GetOwner():IsPlayer()         -- not owned by a player
               and ply:GetPos():Distance(ent:GetPos()) <= ttt_fof_axe_glow_distance:GetFloat() then 
                  table.insert(axes, ent)
            end
         end
         return axes
      end

      hook.Add("PreDrawHalos", "AddAxeHalos", function()
         ground_axes = getNearbyAxes()
         halo.Add(ground_axes,
         Color(0,255,0), 
         2, -- blurX
         2, -- blurY
         2 -- passes
         )
      end)
   end
end
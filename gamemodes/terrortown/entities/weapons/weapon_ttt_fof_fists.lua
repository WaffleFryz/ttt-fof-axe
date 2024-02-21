AddCSLuaFile()

sound.Add({
	name="Fists.Miss",
	channel=CHAN_WEAPON,
	volume=1,
	level=75,
	pitch=100,
	sound={
      "weapons/fists/fists_miss1.wav",
      "weapons/fists/fists_miss2.wav",
      "weapons/fists/fists_miss3.wav",
      "weapons/fists/fists_miss4.wav"
   }
})

sound.Add({
	name="Fists.Hit",
	channel=CHAN_WEAPON,
	volume=1,
	level=75,
	pitch=100,
	sound={
      "weapons/fists/fists_punch1.wav",
      "weapons/fists/fists_punch2.wav",
      "weapons/fists/fists_punch3.wav",
      "weapons/fists/fists_punch4.wav"
   }
})

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

local ttt_fof_fists_damage = CreateConVar(
	"ttt_fof_fists_damage", "25", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Damage of Fists PrimaryFire (Default: 25 / FoF Value: 25)"
)

local ttt_fof_fists_delay = CreateConVar(
	"ttt_fof_fists_delay", "0.8", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Delay of Fists PrimaryFire (Default: 0.8)"
)

-- if not EQUIP_DUSTERS then
-- 	EQUIP_DUSTERS = GenerateNewEquipmentID()
	
-- 	local boots = {
-- 		id = EQUIP_DUSTERS,
-- 		type = "item_passive",
-- 		material = "!ttt_fof_icons/weapon_ttt_fof_boots",
-- 		name = "Brass Knuckles",
-- 		desc = "Makes you chuckle",
-- 	}
	
-- 	table.insert(EquipmentItems[ROLE_TRAITOR], boots)
-- 	table.insert(EquipmentItems[ROLE_DETECTIVE], boots)
-- end

SWEP.HoldType = "fist"

if CLIENT then
   SWEP.PrintName            = "Fists"
   SWEP.Slot                 = 0

   SWEP.DrawCrosshair        = false
   SWEP.ViewModelFlip        = false
   SWEP.ViewModelFOV         = 54

   SWEP.Icon                 = "vgui/ttt/icon_cbar"
end

SWEP.Base                    = "weapon_tttbase"

SWEP.UseHands                = true
SWEP.ViewModel               = "models/weapons/v_fists.mdl"
SWEP.WorldModel              = ""

SWEP.Primary.Damage          = ttt_fof_fists_damage:GetFloat()
SWEP.Primary.ClipSize        = -1
SWEP.Primary.DefaultClip     = -1
SWEP.Primary.Automatic       = true
SWEP.Primary.Delay           = ttt_fof_fists_delay:GetFloat()
SWEP.Primary.Ammo            = "none"

SWEP.Secondary.Automatic       = true

SWEP.HeadshotMultiplier 	 = 1.4
SWEP.Kind                    = WEAPON_MELEE
SWEP.WeaponID                = AMMO_CROWBAR
SWEP.InLoadoutFor            = {ROLE_INNOCENT, ROLE_TRAITOR, ROLE_DETECTIVE}

SWEP.NoSights                = true
SWEP.IsSilent                = false

SWEP.AutoSpawnable           = false

SWEP.AllowDelete             = false -- never removed for weapon reduction
SWEP.AllowDrop               = false

local sound_single = Sound("weapons/slam/throw.wav")

-- Copied movement speed from axe
local ttt_fof_walkspeed_crowbar = CreateConVar(
	"ttt_fof_walkspeed_crowbar", "235", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Walking speed while crowbar is held (recommended: 235)"
)

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

			   self:EmitSound("Fists.Hit")
            -- if self:GetOwner():HasEquipmentItem(EQUIP_DUSTERS) then
            --    self:EmitSound("Brass.Hit")
            -- else
            --    self:EmitSound("Fists.Hit")
            -- end

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

         local dmg = DamageInfo()
         dmg:SetDamage(self.Primary.Damage)
         dmg:SetAttacker(self:GetOwner())
         dmg:SetInflictor(self.Weapon)
         dmg:SetDamageForce(self:GetOwner():GetAimVector() * 1500)
         dmg:SetDamagePosition(self:GetOwner():GetPos())
         dmg:SetDamageType(DMG_SLASH)

         hitEnt:DispatchTraceAttack(dmg, spos + (self:GetOwner():GetAimVector() * 3), sdest)

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
   self:PrimaryAttack()
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
	return "weapon_ttt_fof_fists"
end

local ttt_fof_axe_glow_distance = CreateConVar(
	"ttt_fof_axe_glow_distance", "200", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Max distance pickup-able axes glow (Default: 200)"
)

function SWEP:Think()
   if CLIENT then
      ply = self:GetOwner()

      local function getNearbyAxes()
         axes = {}
         for i, ent in ipairs(ents.GetAll()) do
            if (ent:GetClass() == "weapon_ttt_fof_axe"      -- is an axe
              and not ply:HasWeapon("weapon_ttt_fof_axe")   -- ply no have axe
              and not ent:GetOwner():IsPlayer()) then 
                  if ply:GetPos():Distance(ent:GetPos()) <= ttt_fof_axe_glow_distance:GetFloat() then
                     table.insert(axes, ent)
                  end
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
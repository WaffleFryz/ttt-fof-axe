AddCSLuaFile()

local ttt_fof_axe_damage = CreateConVar(
	"ttt_fof_axe_damage", "40", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Damage of Axe PrimaryFire (Default: 40 / FoF Value: 40)"
)

local ttt_fof_axe_delay_hit = CreateConVar(
	"ttt_fof_axe_delay_hit", "0.72", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Delay (in seconds) of Axe PrimaryFire Hit (Default: 0.72)"
)

local ttt_fof_axe_delay_miss = CreateConVar(
	"ttt_fof_axe_delay_miss", "1.0", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Delay (in seconds) of Axe PrimaryFire Miss (Default: 1.0)"
)

sound.Add({
	name = "Weapon_Crowbar.Single",
	channel = CHAN_WEAPON,
	volume = 0.5,
	level = 75,
	pitch = 100,
	sound = "weapons/iceaxe/iceaxe_swing1.wav",
})

sound.Add({
	name="Axe.HitWorld",
	channel=CHAN_WEAPON,
	volume=1,
	level=75,
	pitch=100,
	sound="weapons/axe/crowbar_impact2.wav"
})

SWEP.HoldType                = "melee"

if CLIENT then
   SWEP.PrintName            = "Hatchet"
   SWEP.Slot                 = 0

   SWEP.DrawCrosshair        = false
   SWEP.ViewModelFlip        = false
   SWEP.ViewModelFOV         = 54

   SWEP.Icon                 = "vgui/ttt/icon_cbar"
end

SWEP.Base                    = "weapon_tttbase"

SWEP.UseHands                = true
SWEP.ViewModel               = "models/weapons/v_crowbar_axe.mdl"
SWEP.WorldModel              = "models/weapons/w_crowbar_axe.mdl"

SWEP.Primary.Damage          = ttt_fof_axe_damage:GetFloat()
SWEP.Primary.ClipSize        = -1
SWEP.Primary.DefaultClip     = -1
SWEP.Primary.Automatic       = true
SWEP.Primary.Delay           = ttt_fof_axe_delay_hit:GetFloat()
DelayMiss                    = ttt_fof_axe_delay_miss:GetFloat()
SWEP.Primary.Ammo            = "none"

SWEP.Secondary.Damage        = 40
SWEP.Secondary.ClipSize      = -1
SWEP.Secondary.DefaultClip   = -1
SWEP.Secondary.Automatic     = true
SWEP.Secondary.Ammo          = "none"
SWEP.Secondary.Delay         = 1

SWEP.HeadshotMultiplier 	 = 1.4

SWEP.Kind                    = WEAPON_MELEE
SWEP.WeaponID                = AMMO_CROWBAR
SWEP.InLoadoutFor            = {ROLE_INNOCENT, ROLE_TRAITOR, ROLE_DETECTIVE}

SWEP.NoSights                = true
SWEP.IsSilent                = false

SWEP.Weight                  = 5
SWEP.AutoSpawnable           = false

SWEP.AllowDelete             = false -- never removed for weapon reduction
SWEP.AllowDrop               = true

local sound_single = Sound("Weapon_Crowbar.Single")
local sound_open = Sound("DoorHandles.Unlocked3")

if SERVER then
   CreateConVar("ttt_crowbar_unlocks", "1", FCVAR_ARCHIVE)
   CreateConVar("ttt_crowbar_pushforce", "395", FCVAR_NOTIFY)
end

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

-- only open things that have a name (and are therefore likely to be meant to
-- open) and are the right class. Opening behaviour also differs per class, so
-- return one of the OPEN_ values
local function OpenableEnt(ent)
   local cls = ent:GetClass()
   if ent:GetName() == "" then
      return OPEN_NO
   elseif cls == "prop_door_rotating" then
      return OPEN_ROT
   elseif cls == "func_door" or cls == "func_door_rotating" then
      return OPEN_DOOR
   elseif cls == "func_button" then
      return OPEN_BUT
   elseif cls == "func_movelinear" then
      return OPEN_NOTOGGLE
   else
      return OPEN_NO
   end
end


local function CrowbarCanUnlock(t)
   return not GAMEMODE.crowbar_unlocks or GAMEMODE.crowbar_unlocks[t]
end

-- will open door AND return what it did
function SWEP:OpenEnt(hitEnt)
   -- Get ready for some prototype-quality code, all ye who read this
   if SERVER and GetConVar("ttt_crowbar_unlocks"):GetBool() then
      local openable = OpenableEnt(hitEnt)

      if openable == OPEN_DOOR or openable == OPEN_ROT then
         local unlock = CrowbarCanUnlock(openable)
         if unlock then
            hitEnt:Fire("Unlock", nil, 0)
         end

         if unlock or hitEnt:HasSpawnFlags(256) then
            if openable == OPEN_ROT then
               hitEnt:Fire("OpenAwayFrom", self:GetOwner(), 0)
            end
            hitEnt:Fire("Toggle", nil, 0)
         else
            return OPEN_NO
         end
      elseif openable == OPEN_BUT then
         if CrowbarCanUnlock(openable) then
            hitEnt:Fire("Unlock", nil, 0)
            hitEnt:Fire("Press", nil, 0)
         else
            return OPEN_NO
         end
      elseif openable == OPEN_NOTOGGLE then
         if CrowbarCanUnlock(openable) then
            hitEnt:Fire("Open", nil, 0)
         else
            return OPEN_NO
         end
      end
      return openable
   else
      return OPEN_NO
   end
end

-- Swap out the fists for axe
function SWEP:Equip(ply)
   local active_wep = ply:GetActiveWeapon()
   if IsValid(active_wep) and active_wep:GetClass() == "weapon_ttt_fof_fists" then
      ply:SelectWeapon("weapon_ttt_fof_axe")  
   end
   ply:StripWeapon("weapon_ttt_fof_fists")
end

function SWEP:PrimaryAttack()
	
	PrimaryAttackHelper(self)

	if self:GetActivity() == ACT_VM_MISSCENTER then
		self:SetNextPrimaryFire(CurTime() + DelayMiss)

		local owner = self:GetOwner()
		local vm = IsValid(owner) and owner:GetViewModel()

		if IsValid(vm) then
			vm:SetPlaybackRate(2 / 3)
		end
	end
end

function PrimaryAttackHelper(self)
   self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

   if not IsValid(self:GetOwner()) then return end

   if self:GetOwner().LagCompensation then -- for some reason not always true
      self:GetOwner():LagCompensation(true)
   end

   local spos = self:GetOwner():GetShootPos()
   local sdest = spos + (self:GetOwner():GetAimVector() * 70)

   local tr_main = util.TraceLine({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL})
   local hitEnt = tr_main.Entity

   self.Weapon:EmitSound(sound_single)

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
			   self:EmitSound("Axe.Hit")

            -- does not work on players rah
            --util.Decal("Blood", tr_main.HitPos + tr_main.HitNormal, tr_main.HitPos - tr_main.HitNormal)

            -- do a bullet just to make blood decals work sanely
            -- need to disable lagcomp because firebullets does its own
            self:GetOwner():LagCompensation(false)
            self:GetOwner():FireBullets({Num=1, Src=spos, Dir=self:GetOwner():GetAimVector(), Spread=Vector(0,0,0), Tracer=0, Force=1, Damage=0})
         else
            util.Effect("Impact", edata)
            self:EmitSound("Axe.HitWorld")
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
         if self:OpenEnt(hitEnt) == OPEN_NO and tr_all.Entity and tr_all.Entity:IsValid() then
            -- See if there's a nodraw thing we should open
            self:OpenEnt(tr_all.Entity)
         end

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

local TimeToThrow = 0
local Throwing = false

-- THROW THE AXE
function SWEP:SecondaryAttack()
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )

   self.Weapon:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

   Throwing = true

   local function Throw()
      Throwing = false
   
      if SERVER then
         local AxeProj = ents.Create("thrown_axe")
         if not IsValid(AxeProj) then return end
         
         ply = self:GetOwner()
   
         local ang = ply:EyeAngles() -- TTT Knife math here
   
         if ang.p < 90 then
            ang.p = -10 + ang.p * ((90 + 10) / 90)
         else
            ang.p = 360 - ang.p
            ang.p = -10 + ang.p * -((90 + 10) / 90)
         end
   
         local vfw = ang:Forward()
         local vrt = ang:Right()
   
         local src = ply:GetPos() + (ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset())
   
         src = src + (vfw * 1) + (vrt * 3)
   
         local knife_ang = Angle(-28,0,0) + ang
         AxeProj:SetPos(src)
         AxeProj:SetAngles(knife_ang)
         
         AxeProj:Spawn()
         
         AxeProj:SetOwner(ply)
         
         local AxePhys = AxeProj:GetPhysicsObject()
         
         if IsValid(AxePhys) then
            AxeProj:EmitSound("Axe.Throw")
            AxePhys:SetVelocity(ply:GetAimVector() * 1200)
            AxePhys:Wake()
            ply:StripWeapon("weapon_ttt_fof_axe")
            ply:Give("weapon_ttt_fof_fists")
            ply:SelectWeapon("weapon_ttt_fof_fists")
         end
      end
   end

   timer.Simple(0.5, Throw)
end


function SWEP:Holster()
   if Throwing then
      return false -- no switching during throw
   end
   return true
end

-- kicking code from FoT
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
	return "weapon_ttt_fof_axe"
end

sound.Add({
	name="Axe.Hit",
	channel=CHAN_WEAPON,
	volume=1,
	level=75,
	pitch=100,
	sound={
	  "weapons/axe/axe_hit1.wav",
	  "weapons/axe/axe_hit2.wav",
	  "weapons/axe/axe_hit3.wav"
	}
})

sound.Add({
	name="Axe.Throw",
	channel=CHAN_STATIC,
	volume=1,
	level=75,
	pitch=100,
	sound="weapons/axe/axe_throw.wav"
})

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

CreateConVar(
	"ttt_fof_axe_glow_distance", "200", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Max distance pickup-able axes glow (Default: 200)"
)

CreateConVar(
	"ttt_fof_fists_delay", "0.8", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Delay of Fists PrimaryFire (Default: 0.8)"
)

CreateConVar(
	"ttt_fof_walkspeed_crowbar", "225", FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED,
	"Walking speed while crowbar is held (recommended: 235)"
)
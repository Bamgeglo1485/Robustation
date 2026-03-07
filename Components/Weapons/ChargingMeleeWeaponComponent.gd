class_name ChargingMeleeWeaponComponent extends MeleeWeapon

@export var max_charge_time: float = 3
@export var base_charge_time: = 1
@export var min_charge: float = 0.3
@export var exponential: bool = true
@export var exponent_divider: float = 1.2
@export var charging_effect: Node2D
@export var hitstop_charge: float = 1.5
@export var hitstop_divider: float = 2.5
@export var charging_sound: AudioStreamPlayer2D
@export var full_charge_sound: AudioStreamPlayer2D
var charging: bool = false
var charge: float = 0
var npc: bool = true
@export var weapon_inhand_texture: DirectionalSprite
var player_weapon_user: PlayerWeaponUserComponent
var fullcharge: bool = false

func _ready() -> void:
	super._ready()
	player_weapon_user = parent.get_node_or_null("PlayerWeaponUserComponent")
	throw_speed = 0
	self_throw_speed = 0

func _physics_process(delta: float) -> void:
	if !charging:
		return
	if charge < max_charge_time:
		charge += delta
		clamp(charge, 0, max_charge_time)
	elif !fullcharge:
		fullcharge = true
		if full_charge_sound:
			full_charge_sound.play()
	if charge > min_charge and charging_effect and !charging_effect.visible:
		charging_effect.visible = true
	if weapon_inhand_texture:
		var mod: float = 1 + charge / base_charge_time
		weapon_inhand_texture.modulate = Color(mod, mod, mod, 1.0)
		if main_weapon and player_weapon_user:
			player_weapon_user.weapon_icon.modulate = Color(mod, mod, mod, 1.0)

func on_release(raiser) -> void:
	fullcharge = false
	charging = false
	can_switch = true
	EventBusManager.update_weapon_icon.emit(parent, self)
	if charging_effect:
		charging_effect.visible = false
	if charging_sound:
		charging_sound.stop()
	if weapon_inhand_texture:
		weapon_inhand_texture.modulate = Color(1.0, 1.0, 1.0, 1.0)
		weapon_inhand_texture.use_parent_material = true
		if main_weapon and player_weapon_user:
			player_weapon_user.weapon_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if min_charge > charge:
		return
	if exponential:
		var charge_ratio = charge / base_charge_time
		var exp_multiplier = exp(charge_ratio) - 0.5
		minor_damage_modifiers["Charge"] = exp_multiplier / exponent_divider
	else:
		minor_damage_modifiers["Charge"] = charge / base_charge_time
	var mod: float = charge / base_charge_time
	@warning_ignore_start("narrowing_conversion")
	throw_speed = base_throw_speed * mod
	self_throw_speed = base_self_throw_speed * mod
	var targets = await _attack(raiser, npc)
	if targets.is_empty():
		return
	if hitstop_charge != 0 and hitstop_charge < charge:
		var hitstop_cof = charge / hitstop_charge / hitstop_divider
		attack_sound.volume_db = hitstop_cof * 6
		EventBusManager.request_impact_frame.emit(hitstop_cof / modify_damage_by_speed_hitscan_divider, 0.0, true, false)

func attack(_raiser, _npc = true) -> Dictionary:
	if charging:
		return {}
	charge = 0.0
	can_switch = false
	charging = true
	npc = _npc
	if charging_sound:
		charging_sound.play()
	if weapon_inhand_texture:
		weapon_inhand_texture.use_parent_material = false
	EventBusManager.update_weapon_icon.emit(parent, self)
	return {}

func _attack(raiser, _npc = true) -> Dictionary:
	return await super.attack(raiser, _npc)

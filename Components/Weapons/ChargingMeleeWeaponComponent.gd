class_name ChargingMeleeWeaponComponent extends MeleeWeapon

@export var max_charge_time: float = 1
@export var base_charge_time: float = 0.5
@export var min_charge: float = 0.2
@export var exponential: bool = true
@export var exponent_divider: float = 1.2
@export var charging_effect: Node2D
@export var hitstop_charge: float = 0.7
@export var charging_sound: AudioStreamPlayer2D
@export var full_charge_sound: AudioStreamPlayer2D
@export var remove_overheat_weapon: RangeWeapon
var charging: bool = false
var charge: float = 0
var npc: bool = true
var fullcharge: bool = false

func _ready() -> void:
	super._ready()
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
		print(exp_multiplier / exponent_divider)
	else:
		minor_damage_modifiers["Charge"] = charge / base_charge_time
	var mod: float = charge / base_charge_time
	@warning_ignore_start("narrowing_conversion")
	throw_speed = base_throw_speed * mod
	self_throw_speed = base_self_throw_speed * mod
	var targets = await _attack(raiser, npc)
	if remove_overheat_weapon:
		remove_overheat_weapon.overheat = 0
	if targets.is_empty():
		return
	if hitstop_charge != 0 and hitstop_charge < charge:
		var hitstop_cof = charge / hitstop_charge * 0.2
		attack_sound.volume_db = hitstop_cof
		EventBusManager.request_impact_frame.emit(hitstop_cof, 0.0, true, false)

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

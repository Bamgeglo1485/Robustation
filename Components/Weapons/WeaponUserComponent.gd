class_name WeaponUserComponent extends Component

@onready var weapon_sprite: WeaponSpriteComponent = parent.get_node_or_null("Texture").get_node_or_null("WeaponSpriteComponent")
@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")

@export var selected_weapon: Weapon : set = select_weapon
@export var timers_timescaled: bool = true

@export var block_when_fallen: bool = true
@export var block_when_flying: bool = true

@export var damage_modifier: float = 1.0
@export var minor_damage_modifiers: Dictionary[String, float]
@export var minor_damage_modifier: float = 1.0
@export var knockback_modifier: int = 0
@export var cooldown_modifier: float = 1.0

@export var overheat_per_shoot_modifier: float = 1.0
@export var extra_shots: int = 0

@export var qte_perfect_heal_modifier_from_max_modifier: float = 1.0
@export var qte_time_mod: float = 3.0

@export var can_attack: bool = true
var ignore_setter: bool = false

func _ready() -> void:
	if selected_weapon:
		select_weapon(selected_weapon)

func force_select_weapon(new_weapon: Weapon):
	if new_weapon and new_weapon is RangeWeapon:
		if overheat_per_shoot_modifier != 1.0 and new_weapon.overheat_enabled:
			new_weapon.overheat_per_shoot_modifier = overheat_per_shoot_modifier
		if extra_shots != 0 and new_weapon and new_weapon.shots != 1:
			new_weapon.extra_shots = extra_shots
	elif new_weapon and new_weapon is MeleeWeapon:
		new_weapon.qte_time_mod = qte_time_mod
		new_weapon.qte_perfect_heal_modifier_from_max_modifier = qte_perfect_heal_modifier_from_max_modifier
	ignore_setter = true
	selected_weapon = new_weapon
	selected_weapon.timers_timescaled = timers_timescaled
	
	if selected_weapon.equipped_texture and weapon_sprite and weapon_sprite.weapon_texture:
		weapon_sprite.change_weapon_texture(selected_weapon.equipped_texture, selected_weapon.icon_texture, selected_weapon.equipped_scale)

func select_weapon(new_weapon: Weapon) -> void:
	if selected_weapon:
		selected_weapon.swapped.emit(new_weapon)
	if ignore_setter:
		ignore_setter = false
		selected_weapon = new_weapon
		return
	if !new_weapon or (selected_weapon and selected_weapon.swinging) or (selected_weapon and !selected_weapon.can_switch):
		return
	if (selected_weapon and selected_weapon.alt_attack and selected_weapon.alt_attack.swinging) or (selected_weapon and selected_weapon.alt_attack and !selected_weapon.alt_attack.can_switch):
		return
	if selected_weapon and selected_weapon is MeleeWeapon and selected_weapon.qte_active:
		return
	
	force_select_weapon(new_weapon)

func attack(raiser, npc: bool = true, weapon: Weapon = null) -> bool:
	if !can_attack:
		return false
	if !weapon:
		weapon = selected_weapon
	if weapon.get_cooldown():
		return false
	
	if mob_mover_component:
		if mob_mover_component.fallen and block_when_fallen:
			return false
		if mob_mover_component.flying and block_when_flying:
			return false
	
	weapon.damage_modifier = damage_modifier * minor_damage_modifier
	weapon.cooldown_modifier = cooldown_modifier
	weapon.attack(raiser, npc)
	
	return true

func release() -> void:
	selected_weapon._on_release()

func set_minor_modifier(key: String, value: float):
	minor_damage_modifiers[key] = value
	var minor_mod: float = 1.0
	for modifier in minor_damage_modifiers.values():
		minor_mod *= modifier
	minor_damage_modifier = minor_mod

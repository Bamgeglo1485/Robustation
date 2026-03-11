class_name WeaponUserComponent extends Component

@onready var weapon_sprite: WeaponSpriteComponent = parent.get_node_or_null("Texture").get_node_or_null("WeaponSpriteComponent")
@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")

@export var selected_weapon: Weapon : set = select_weapon
@export var timers_timescaled: bool = true

@export var block_when_fallen: bool = true
@export var block_when_flying: bool = true

@export var damage_modifier: float = 1.0
@export var knockback_modifier: int = 0
@export var cooldown_modifier: float = 1.0

@export var can_attack: bool = true
var ignore_setter: bool = false

func _ready() -> void:
	if selected_weapon:
		select_weapon(selected_weapon)

func force_select_weapon(new_weapon: Weapon):
	ignore_setter = true
	selected_weapon = new_weapon
	selected_weapon.timers_timescaled = timers_timescaled
	
	if selected_weapon.equipped_texture and weapon_sprite and weapon_sprite.weapon_texture:
		weapon_sprite.change_weapon_texture(selected_weapon.equipped_texture, selected_weapon.icon_texture, selected_weapon.equipped_scale)

func select_weapon(new_weapon: Weapon) -> void:
	if ignore_setter:
		ignore_setter = false
		selected_weapon = new_weapon
		return
	if !new_weapon or (selected_weapon and selected_weapon.swinging) or (selected_weapon and !selected_weapon.can_switch):
		return
	if (selected_weapon and selected_weapon.alt_attack and selected_weapon.alt_attack.swinging) or (selected_weapon and selected_weapon.alt_attack and !selected_weapon.alt_attack.can_switch):
		return
	if selected_weapon:
		selected_weapon.swapped.emit(new_weapon)
	
	force_select_weapon(new_weapon)

func attack(raiser, npc: bool = true) -> void:
	if !can_attack:
		return
	if selected_weapon.get_cooldown():
		return
	
	if mob_mover_component:
		if mob_mover_component.fallen and block_when_fallen:
			return
		if mob_mover_component.flying and block_when_flying:
			return
	
	selected_weapon.damage_modifier = damage_modifier
	selected_weapon.cooldown_modifier = cooldown_modifier
	selected_weapon.attack(raiser, npc)

func release() -> void:
	selected_weapon._on_release()

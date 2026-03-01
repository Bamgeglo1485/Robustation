class_name WeaponUserComponent extends Component

@onready var weapon_texture: DirectionalSprite = parent.get_node_or_null("WeaponTexture")
@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")

@export var selected_weapon: Weapon : set = select_weapon
@export var timers_timescaled: bool = true

@export var block_when_fallen: bool = true
@export var block_when_flying: bool = true

@export var damage_modifier: float = 1.0
@export var knockback_modifier: int = 0
@export var cooldown_modifier: float = 1.0

@export var can_attack: bool = true

func _ready() -> void:
	if selected_weapon:
		select_weapon(selected_weapon)

func select_weapon(new_weapon: Weapon) -> void:
	if !new_weapon or (selected_weapon and selected_weapon.swinging):
		return
	
	selected_weapon = new_weapon
	selected_weapon.timers_timescaled = timers_timescaled
	
	if selected_weapon.equipped_texture and weapon_texture:
		weapon_texture.texture = selected_weapon.equipped_texture

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

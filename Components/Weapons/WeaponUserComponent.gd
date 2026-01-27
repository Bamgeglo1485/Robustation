class_name WeaponUserComponent extends Component

@onready var weapon_texture: DirectionalSprite = parent.get_node("WeaponTexture")
@onready var mob_mover_component: MobMoverComponent = parent.get_node("MobMoverComponent")

@export var selected_weapon: Weapon : set = select_weapon
@export var timers_timescaled: bool = true

@export var block_when_fallen: bool = true
@export var block_when_flying: bool = true

@export var damage_modifier: float = 1

func _ready() -> void:
	if weapon_texture == null:
		weapon_texture = DirectionalSprite.new()
		weapon_texture.region_enabled = true
		parent.add_child(weapon_texture)
	
	if selected_weapon != null:
		select_weapon(selected_weapon)

func select_weapon(new_weapon: Weapon):
	if new_weapon == null or (selected_weapon != null and selected_weapon.swinging == true):
		return
	
	selected_weapon = new_weapon
	selected_weapon.timers_timescaled = timers_timescaled
	
	if selected_weapon.equipped_texture != null and weapon_texture != null:
		weapon_texture.texture = selected_weapon.equipped_texture

func attack(raiser, npc = true):
	if selected_weapon.get_cooldown() == true:
		return
	
	if mob_mover_component != null:
		if mob_mover_component.fallen == true and block_when_fallen == true:
			return
		if mob_mover_component.flying == true and block_when_flying == true:
			return
	
	selected_weapon.damage_modifier = damage_modifier
	selected_weapon.attack(raiser, npc)

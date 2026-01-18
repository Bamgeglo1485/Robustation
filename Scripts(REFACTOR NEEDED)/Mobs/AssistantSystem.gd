extends "res://Scripts/Mobs/EnemySystem.gd"

func _ready() -> void:
	_random_weapon()

func _enemy_logic(_delta):
	_enemy_attack()

func _random_weapon():
	var children = get_children(false)
	var weapons = []
	
	for child in children:
		if child.has_method("is_weapon"):
			weapons.append(child)
	
	change_weapon(weapons.pick_random())

func _enemy_attack():
	if player == null:
		return
	
	if swinging == true:
		return
	
	if (global_position - player.global_position).length() <= 64:
		if selected_weapon.can_attack == false:
			return
		
		swing()
		return

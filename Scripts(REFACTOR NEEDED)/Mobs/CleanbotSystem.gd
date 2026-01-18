extends "res://Scripts/Mobs/EnemySystem.gd"

var cleaning: bool = false
var rage: bool = false

@onready var cleanbot_texture = sprite.texture
@onready var rage_sound = $CleanbotRageSound
@export var cleanbot_rage_texture: Resource

func _enemy_logic(_delta):
	if rage == true:
		if target == null:
			rage = false
			sprite.texture = cleanbot_texture
			
			if rage_sound != null:
				var _sound_tween = create_tween()
				_sound_tween.tween_property(material, "volume_db", -20, 0.5)
			
			var _tween = create_tween()
			_tween.tween_property(material, "shader_parameter/aura_opacity", 0, 0.5)
			
			health_damage_modifier = 1
			damage_modifier = 1
			return
		
		if selected_weapon.can_attack == false:
			return
		
		if (target.global_position - global_position).length() < 64 and swinging == false and selected_weapon.can_attack == true:
			swing()
		return
	
	if cleaning == true and target != null:
		if (target.global_position - global_position).length() > 48:
			return
		
		if selected_weapon.can_attack == false:
			return
		
		_melee_attack_target(null, selected_weapon, 1, (target.global_position - global_position).normalized())
		target.clean_health -= 1
		
		var progress = 1.0 - float(target.clean_health) / target.max_clean_health
		
		var start_color = Color(0.7, 0.1, 0.1, 1.0)
		var end_color = Color(0.0, 0.0, 1.0, 0.1)
		
		var new_color = start_color.lerp(end_color, progress)
		
		var _tween = create_tween()
		_tween.tween_property(target, "self_modulate", new_color, 0.2)
		
		if target.clean_health <= 0:
			target.queue_free()
			target = null
		return
	elif cleaning == true and target == null:
		cleaning = false
	
	var all_nodes = scene.get_children()
	var blood_pools = []
	
	for node in all_nodes:
		if node.has_method("is_blood"):
			blood_pools.append(node)
	
	if blood_pools.is_empty():
		target = null
		cleaning = false
		return
	
	var closest_pool = null
	var closest_distance = INF
	
	for pool in blood_pools:
		var distance = global_position.distance_to(pool.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_pool = pool
	
	if closest_pool != null:
		cleaning = true
		target = closest_pool
	else:
		cleaning = false
		target = null

@warning_ignore("unused_parameter")
func on_damage(damage, _damager):
	if rage == true:
		return
	
	rage = true
	cleaning = false
	target = _damager
	
	health_damage_modifier = 0.2
	damage_modifier = 1.5
	
	if cleanbot_rage_texture != null:
		sprite.texture = cleanbot_rage_texture
	var _tween = create_tween()
	_tween.tween_property(material, "shader_parameter/aura_opacity", 0.8, 0.5)
	if rage_sound != null:
		rage_sound.volume_db = 0
		rage_sound.play()

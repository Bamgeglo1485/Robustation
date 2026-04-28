extends Node

@warning_ignore_start("unused_signal")
signal health_changed(emitter: Node2D, health: float, new_health: float)
signal damaged(emitter: Node2D, taked_damage: float, damager: Node2D)
signal gibbed(emitter: Node2D)
signal parry(emitter: Node2D, type: String, enemy: bool)
signal projectile_miss(emitter: Node2D, projectile: Node2D)
signal projectile_hit(emitter: Node2D, projectile: Node2D)
signal try_melee_attack(emitter: Node2D, weapon: Weapon)
signal melee_miss(emitter: Node2D, weapon: Weapon)
signal stamina_damaged(emitter: Node2D, damage: float, damager: Node2D)
signal stamina_changed(emitter: Node2D, stamina: int, new_stamina: int)
signal on_fall()
signal weapon_cooldown(emitter: Node2D, weapon: Weapon)
signal bullets_end(emitter: Node2D, weapon: Weapon)
signal swinging_start(emitter: Node2D, weapon: Weapon)
signal weapon_cooldown_reset(emitter: Node2D, weapon: Weapon)
signal body_to_body_collision(emitter: Node2D, body: Node2D, damage: float, body_health: HealthComponent)
signal invincibility_damage_block(emitter: Node2D)

signal projectile_shoot(emitter: Node2D, weapon: Weapon, direction: Vector2, projectile: Node2D)

signal explosion(explosion_node: Node2D)
signal tendency_changed(emitter: Node2D)
signal tendency_stage_changed(emitter: Node2D)

signal kick_dash_combo(emitter: Node2D)

signal raged(emitter: Node2D)
signal request_impact_frame(impact_time, wait_time, modify_color, distort_audio)

signal field_of_view_changed(value: int)
signal fullscreen_changed(fullscreen: bool)
signal glow_changed(glow: bool)
signal parallax_changed(parallax: bool)
signal unpaused()

signal update_weapon_icon(emitter: Node2D, weapon: Weapon)
signal change_player(new_player: Node2D, wait_time: float)

signal on_perk_choosed()
signal player_death()

signal introduction_subject_on_screen(emitter: Node2D)

signal weapon_selected(weapon: Weapon)
signal weapon_slot_changed(number: int)

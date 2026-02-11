extends Node

@warning_ignore_start("unused_signal")
signal health_changed(emitter, health, new_health)
signal damaged(emitter, taked_damage, damager)
signal gibbed(emitter)
signal parry(emitter, type: String)
signal projectile_miss(emitter, projectile)
signal projectile_hit(emitter, projectile)
signal melee_miss(emitter, weapon)
signal on_fall()
signal stamina_damaged(emitter, damage, damager)

signal projectile_shoot(emitter, weapon, direction, projectile)

signal explosion(explosion_node)
signal tendency_changed(emitter)
signal tendency_section_changed(emitter)

signal kick_dash_combo(emitter)

signal raged(emitter)

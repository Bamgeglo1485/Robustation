extends Node

@warning_ignore_start("unused_signal")
signal health_changed(emitter, health, new_health)
signal damaged(emitter, taked_damage, damager)
signal gibbed(emitter)
signal parry(emitter)
signal projectile_miss(emitter, projectile)
signal melee_miss(emitter, weapon)
signal on_fall()

signal explosion(explosion_node)
signal tendency_changed(emitter)
signal tendency_section_changed(emitter)

signal kick_dash_combo(emitter)

signal raged(emitter)

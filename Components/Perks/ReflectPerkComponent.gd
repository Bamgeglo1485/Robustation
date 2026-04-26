class_name ReflectPerkComponent extends BasePerkComponent

@export var reflect_sound: AudioStream = preload("res://Audio/Effects/glass_crack4.ogg")
var reflect_sound_player: AudioStreamPlayer2D

@export var base_chance: float = 0.05
@export var base_chance_decrease: float = 0.05
@export var reflect_to_attacker: bool = true
var chance: float = 0.0
var extra_chance: float = 0.0
var apply_opposite: bool = true
var is_updating: bool = false

func _ready() -> void:
	super._ready()
	if !reflect_sound:
		return
	
	reflect_sound_player = AudioStreamPlayer2D.new()
	reflect_sound_player.stream = reflect_sound
	parent.add_child.call_deferred(reflect_sound_player)

func free() -> void:
	if reflect_sound_player:
		reflect_sound_player.queue_free()

func _init() -> void:
	untranslated_perk_name = "Mirror Shard or (Shard of Mirror)"
	perk_desc = "[color=green]Increases your bullet reflect chance by 5%[/color], but [color=crimson]decreases your melee reflect chance by 5%[/color]"
	perk_icon = preload("res://Textures/Perks/mirror_shard.png")
	perk_equipped_texture = preload("res://Textures/Perks/mirror_shard_equipped.png")
	rarity = rarity_classes.ADMINABUSE
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

func apply_modifiers() -> void:
	if is_updating:
		return
	
	is_updating = true
	
	chance = base_chance * amount + extra_chance
	set_minor_stat("[color=crimson]Projectile Reflect Chance:[/color] " + str(chance * 100) + "%", "projectile_reflect_chance")
	
	if !parent:
		is_updating = false
		return
	
	var reflect_melee: ReflectMeleePerkComponent = parent.get_node_or_null("ReflectMeleePerkComponent")
	if reflect_melee and apply_opposite:
		reflect_melee.extra_chance = -base_chance_decrease * amount
		reflect_melee.apply_opposite = false
		reflect_melee.apply_modifiers()
		reflect_melee.apply_opposite = true
		reflect_melee.set_minor_stat("[color=crimson]Melee Reflect Chance:[/color] " + str(reflect_melee.chance * 100) + "%", "melee_reflect_chance")
	
	is_updating = false

func on_reflect() -> void:
	if reflect_sound_player:
		reflect_sound_player.play()

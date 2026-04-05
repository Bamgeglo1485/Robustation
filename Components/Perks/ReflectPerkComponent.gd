class_name ReflectPerkComponent extends BasePerkComponent

@export var reflect_sound: AudioStream = preload("res://Audio/Effects/glass_crack4.ogg")
var reflect_sound_player: AudioStreamPlayer2D

@export var base_chance: float = 0.03
@export var reflect_to_attacker: bool = true
var chance: float = base_chance

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
	perk_desc = "[color=green]Increases your bullet reflect chance by 3%[/color]"
	perk_icon = preload("res://Textures/Perks/mirror_shard.png")
	perk_equipped_texture = preload("res://Textures/Perks/mirror_shard_equipped.png")
	rarity = rarity_classes.ROBUST
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

func apply_modifiers() -> void:
	chance = base_chance * amount

func on_reflect() -> void:
	if reflect_sound_player:
		reflect_sound_player.play()

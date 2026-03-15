class_name ReflectMeleePerkComponent extends BasePerkComponent

@export var reflect_sound: AudioStream = preload("res://Audio/Weapon/parry.ogg")
var reflect_sound_player: AudioStreamPlayer2D

@export var base_chance: float = 0.03
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
	perk_name = "Bitch Ball"
	perk_desc = "[color=green]Increases your melee attack reflect chance by 3%[/color]"
	perk_icon = preload("res://Textures/Perks/bitch_ball.png")
	rarity = rarity_classes.ROBUST

func apply_modifiers() -> void:
	chance = base_chance * amount

func reflect(attacker: PhysicsBody2D, weapon: MeleeWeapon) -> void:
	if !attacker or !weapon:
		return
	var direction: Vector2 = attacker.global_position - parent.global_position
	weapon._melee_attack_target(attacker, direction, false)
	
	if reflect_sound_player:
		reflect_sound_player.play()

class_name ReflectMeleePerkComponent extends BasePerkComponent

@export var reflect_sound: AudioStream = preload("res://Audio/Weapon/parry.ogg")
var reflect_sound_player: AudioStreamPlayer2D

@export var base_chance: float = 0.05
@export var base_chance_decrease: float = 0.05
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
	untranslated_perk_name = "Bitch Ball"
	perk_desc = "[color=green]Increases your melee attack reflect chance by 5%[/color], but [color=crimson]decreases your bullet reflect chance by 5%[/color]"
	perk_icon = preload("res://Textures/Perks/bitch_ball.png")
	rarity = rarity_classes.ROBUST
	perk_name = tr(untranslated_perk_name)
	perk_desc = tr(perk_desc)

func apply_modifiers() -> void:
	chance = base_chance * amount
	if !parent:
		return
	var reflect_perk: ReflectPerkComponent = parent.get_node_or_null("ReflectPerkComponent")
	if reflect_perk:
		chance -= base_chance_decrease * reflect_perk.amount

func reflect(attacker: PhysicsBody2D, weapon: MeleeWeapon) -> void:
	if !attacker or !weapon:
		return
	var direction: Vector2 = attacker.global_position - parent.global_position
	weapon._melee_attack_target(attacker, direction, false)
	
	if reflect_sound_player:
		reflect_sound_player.play()

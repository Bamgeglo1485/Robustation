class_name RegenerationPerkComponent extends BasePerkComponent

func _init() -> void:
	perk_name = "Medical Belt"
	perk_desc = "Increases your regeneration by 2 units per second"
	perk_icon = preload("res://Textures/Perks/med_belt.png")
	perk_equipped_texture = preload("res://Textures/Perks/med_belt_equipped.png")
	rarity = rarity_classes.COMMON

@onready var health_component: HealthComponent = parent.get_node("HealthComponent")
@export var base_regeneration: int = 2

# Cooldown after damage
@export var cooldown_delay: float = 4.0
var cooldown: bool = false
var regeneration_timer: Timer

var regeneration: int = 2

func apply_modifiers() -> void:
	regeneration = base_regeneration * amount


func _ready() -> void:
	super._ready()
	if !health_component:
		return
	
	regeneration_timer = Timer.new()
	regeneration_timer.wait_time = 1.0
	regeneration_timer.one_shot = true
	regeneration_timer.timeout.connect(_regenerate)
	regeneration_timer.ignore_time_scale = true
	add_child(regeneration_timer)
	regeneration_timer.start()
	
	EventBusManager.damaged.connect(_on_damaged)

func _regenerate():
	if cooldown:
		return
	
	regeneration_timer.start()
	
	if health_component.health >= health_component.max_health:
		return
	
	health_component.set_health(health_component.health + regeneration)

func _on_damaged(source, _damage, _damager):
	if source == parent:
		_cooldown()

func _cooldown():
	if cooldown_delay != 0:
		cooldown = true
		await get_tree().create_timer(cooldown_delay, true, false, true).timeout
		cooldown = false

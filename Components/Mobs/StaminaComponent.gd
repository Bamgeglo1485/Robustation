class_name StaminaComponent extends Component

@export var max_stamina: int = 100
@export var stun_time: float = 4
@export var stamina_recover: int = 20
@export var stun_effect: PackedScene = preload("res://Scenes/Effects/Particles/Stun.tscn")
@export var after_damage_recover_cooldown_delay: float = 3
var stamina: int = max_stamina
var can_recover: bool = true
var stunned: bool = false
var stamina_recover_timer: Timer

@onready var animation_component: AnimationComponent = parent.get_node_or_null("AnimationComponent")
@onready var mob_mover_component: MobMoverComponent = parent.get_node_or_null("MobMoverComponent")

func _ready():
	stamina = max_stamina
	stamina_recover_timer = Timer.new()
	stamina_recover_timer.wait_time = 1.0
	stamina_recover_timer.one_shot = true
	stamina_recover_timer.timeout.connect(_recover_stamina)
	add_child(stamina_recover_timer)
	stamina_recover_timer.start()
	
	if mob_mover_component:
		mob_mover_component.minor_modifiers["stamina_modifier"] = 1.0

func _recover_stamina():
	stamina_recover_timer.start()
	if stamina == max_stamina or stunned or !can_recover:
		return
	
	set_stamina(stamina + stamina_recover)

func take_stamina_damage(damage, damager):
	set_stamina(stamina - damage)
	_can_recover_cooldown()
	EventBusManager.stamina_damaged.emit(parent, damage, damager)
	if animation_component:
		animation_component.flash(1, Color(0.597, 0.682, 1.0, 1.0))
	if stun_effect:
		var inst = stun_effect.instantiate()
		parent.add_child.call_deferred(inst)
		
func set_stamina(new_stamina):
	stamina = new_stamina
	stamina = clamp(stamina, 0, max_stamina)
	
	if mob_mover_component:
		mob_mover_component.minor_modifiers["stamina_modifier"] = float(stamina) / max_stamina
	
	if stamina == 0:
		stun()

func stun():
	stunned = true
	if mob_mover_component:
		mob_mover_component.drop(stun_time, true)
	if stun_effect:
		var inst = stun_effect.instantiate()
		parent.add_child.call_deferred(inst)
		if inst.has_node("Delete"):
			inst.get_node("Delete").wait_time = stun_time
	get_tree().create_timer(stun_time).timeout.connect(unstun)

func unstun():
	stunned = false
	set_stamina(max_stamina)

func _can_recover_cooldown():
	can_recover = false
	await get_tree().create_timer(after_damage_recover_cooldown_delay).timeout
	can_recover = true

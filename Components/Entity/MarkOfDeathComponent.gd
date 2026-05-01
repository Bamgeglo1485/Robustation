class_name MarkOfDeathComponent extends Component

@export var sprite: Sprite2D
var delay: float = 0.0
var heal: float = 0.0
var damage: float = 0.0
var hard_damage: float = 0.0
var marked: bool = false
@onready var health_comp: HealthComponent = parent.get_node_or_null("HealthComponent")

func _ready() -> void:
	if health_comp:
		health_comp.damaged.connect(_on_damaged)

func _on_damaged(taked_damage: float, damager: Node2D) -> void:
	if !marked or !damager:
		return
	await tree.physics_frame
	var damager_weapon_user: WeaponUserComponent = damager.get_node_or_null("WeaponUserComponent")
	if damager_weapon_user.last_attacked_weapon is not MeleeWeapon or !damager_weapon_user.last_attacked_weapon.can_clear_mark:
		return
	
	var damager_health: HealthComponent = damager.get_node_or_null("HealthComponent")
	if damager_health:
		damager_health.hard_damage *= hard_damage
		damager_health.take_damage(-damager_health.health * heal, null, "Heal", true)
	var prev_damage: float = damage
	remove_mark()
	health_comp.take_damage(taked_damage * prev_damage, damager)

func _process(delta: float) -> void:
	if delay == 0.0 and !marked:
		return
	elif delay <= 0.0 and marked:
		remove_mark()
	delay -= delta

func set_mark(new_delay: float, new_heal: float, new_damage: float, new_hard_damage: float) -> void:
	marked = true
	delay = new_delay
	heal = new_heal
	damage = new_damage
	hard_damage = new_hard_damage
	sprite.visible = true

func remove_mark() -> void:
	marked = false
	sprite.visible = false

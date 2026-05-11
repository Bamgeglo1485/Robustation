class_name RandomWeaponRarityComponent extends Component

@export var adminabuse_chance: float = 0.0
@export var robust_chance: float = 0.0
@export var common_chance: float = 0.0
@export var shitty_chance: float = 0.0

@export var adminabuse_multiplier: float = 1.0
@export var robust_multiplier: float = 1.0
@export var common_multiplier: float = 1.0
@export var shitty_multiplier: float = 1.0

@export var adminabuse_parry_extra_bounces: int = 0
@export var adminabuse_parry_extra_penetrations: int = 0
@export var adminabuse_extra_bounces: int = 0
@export var adminabuse_extra_penetrations: int = 0

@export var adminabuse_second_multiplier: float = 1.0
@export var robust_second_multiplier: float = 1.0
@export var common_second_multiplier: float = 1.0
@export var shitty_second_multiplier: float = 1.0

func _ready() -> void:
	var rand: float = randf()
	
	var cumulative: float = 0.0
	
	cumulative += shitty_chance
	if rand < cumulative:
		_multiply(shitty_multiplier, shitty_second_multiplier)
		parent.weapon_rarity = Weapon.rarity_classes.SHITTY
		return
	
	cumulative += common_chance
	if rand < cumulative:
		_multiply(common_multiplier, common_second_multiplier)
		parent.weapon_rarity = Weapon.rarity_classes.COMMON
		return
	
	cumulative += robust_chance
	if rand < cumulative:
		_multiply(robust_multiplier, robust_second_multiplier)
		parent.weapon_rarity = Weapon.rarity_classes.ROBUST
		return
	
	cumulative += adminabuse_chance
	if rand < cumulative:
		_multiply(adminabuse_multiplier, adminabuse_second_multiplier)
		parent.weapon_rarity = Weapon.rarity_classes.ADMINABUSE
		if parent is MeleeWeapon:
			parent.parry_extra_bounces += adminabuse_parry_extra_bounces
			parent.parry_extra_penetrations += adminabuse_parry_extra_penetrations
		elif parent is RangeWeapon:
			parent.extra_bounces += adminabuse_extra_bounces
			parent.extra_penetrations += adminabuse_extra_penetrations

func _multiply(value: float, second_value: float) -> void:
	if value == 1.0 and second_value == 1.0:
		return
	parent.cooldown_delay *= second_value
	parent.swing_delay *= second_value
	parent.set_multiplier("damage", "rarity", value)
	
	if parent is MeleeWeapon:
		parent.throw_speed *= value
		parent.drop_enemy_delay *= value
		parent.parry_force *= value
	elif parent is RangeWeapon:
		parent.overheat_per_shoot *= second_value
		parent.bullets_recovery_delay *= second_value

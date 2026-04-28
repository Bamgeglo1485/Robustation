class_name DodgeBonusRangeWeaponComponent extends RangeWeapon

func _ready() -> void:
	super._ready()
	EventBusManager.invincibility_damage_block.connect(invincibility_block)

func invincibility_block(emitter: Node2D) -> void:
	if emitter != parent:
		return
	
	_on_bullets_recover()
	shots = bullets
	EventBusManager.update_weapon_icon.emit(parent, self)

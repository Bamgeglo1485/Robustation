class_name RevolverWeaponCharger extends RangeWeapon

@export var cartridge_fall: PackedScene

func _ready() -> void:
	super._ready()
	if !main_weapon or main_weapon is not RevolverWeapon:
		return

func attack(_raiser, _npc = true) -> void:
	if !main_weapon:
		return
	if main_weapon.empty_cartridges > 0:
		for i in main_weapon.bullets + main_weapon.empty_cartridges:
			var inst: Node2D = cartridge_fall.instantiate()
			inst.global_position = parent.global_position
			scene.add_child(inst)
		main_weapon.empty_cartridges = 0
		main_weapon.bullets = 0
	elif main_weapon.bullets < main_weapon.bullets_max_count:
		main_weapon.bullets += 1
		EventBusManager.update_weapon_icon.emit(parent, main_weapon)
		if main_weapon.bullets_recover_sound:
			main_weapon.bullets_recover_sound.play()

class_name RevolverWeapon extends RangeWeapon

var empty_cartridges: int = 0

signal bullets_changed()

func set_bullets(new_value) -> void:
	if new_value < bullets:
		empty_cartridges += bullets - new_value
	
	bullets = new_value
	clamp(bullets, 0, new_value)
	if shared_bullets_weapon:
		shared_bullets_weapon.bullets += new_value - bullets
	bullets_changed.emit()

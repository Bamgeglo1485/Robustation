class_name AdditionalStaminaPerkComponent extends BasePerkComponent

@export var base_stamina: int = 20

func _init() -> void:
	perk_name = "Student Diet"
	perk_desc = "Increases your stamina by 20 units"
	perk_icon = preload("res://Textures/Perks/student_diet.png")
	
@onready var stamina_component: StaminaComponent = parent.get_node_or_null("StaminaComponent")

func apply_modifiers() -> void:
	if !stamina_component:
		return
	
	var additional_stamina_amount: int = base_stamina * amount
	stamina_component.max_stamina += additional_stamina_amount
	stamina_component.set_stamina(stamina_component.stamina + additional_stamina_amount)

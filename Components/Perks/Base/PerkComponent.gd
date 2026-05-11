class_name PerkComponent extends Component

@export var perk_data: PerkData
@export var amount: int = 1
var sprite: DirectionalSprite

@export var minor_stat_control_scene: PackedScene = preload("res://Scenes/UI/IngameInterface/BaseMinorStat.tscn")
var second_minor_stat_control: Control
var minor_stat_container: Container

func _ready() -> void:
	if !perk_data or !parent:
		return
	
	perk_data.perk_name = tr(perk_data.perk_id + "_name")
	perk_data.perk_description = tr(perk_data.perk_id + "_desc")
	_update_modifiers()
	
	if perk_data.equipped_texture:
		sprite = DirectionalSprite.new()
		sprite.texture = perk_data.equipped_texture
		sprite.region_enabled = true
		parent.add_child(sprite)

func _exit_tree() -> void:
	if sprite:
		sprite.queue_free()
	amount = 0
	_update_modifiers()

func _update_modifiers() -> void:
	if !parent.has_node("PerkOwnerComponent"):
		return
	_apply_base_modifiers()
	apply_custom_modifiers()

# Метод чтобы применять кастомные множители, невозможные базовыми возможностями
# A method to apply custom multipliers that are not possible with the base features
func apply_custom_modifiers() -> void:
	pass

func _apply_base_modifiers() -> void:
	for modifier in perk_data.modifiers:
		var component: Component = parent.get_node_or_null(modifier.target_component)
		if !component:
			if modifier.ensure_component:
				var component_script = load(modifier.target_component) as Script
				if component_script:
					component = component_script.new()
					component.name = modifier.target_component
					parent.add_child.call_deferred(component)
			else:
				continue
		
		# Всегда используем только словари для избежания конфликтов и невозможности откатить перк
		# Always use only dictionaries to avoid conflicts and inability to revert the perk
		match modifier.operation:
			modifier.operations.MULTIPLY:
				component.set_multiplier(modifier.property, perk_data.perk_id, modifier.value ** amount)
			modifier.operations.ADD:
				component.set_addendum(modifier.property, perk_data.perk_id, modifier.value * amount)
		_add_minor_stat(modifier)

func _add_minor_stat(modifier: PerkModifier) -> void:
	if !minor_stat_container:
		return
	
	var component: Component = parent.get_node_or_null(modifier.target_component)
	if !component:
		return
	
	var property_name_with_operation: String
	
	var text: String = modifier.property + ": "
	match modifier.operation:
		modifier.operations.MULTIPLY:
			property_name_with_operation = modifier.property + "_multiplier"
			var property = component.get(property_name_with_operation)
			text += str(property * 100) + "%"
		modifier.operations.ADD:
			property_name_with_operation = modifier.property + "_addendum"
			var property = component.get(property_name_with_operation)
			text += str(property) + "u"
	
	var already_exist: Control = minor_stat_container.get_node_or_null(property_name_with_operation)
	if !already_exist:
		var inst: Control = minor_stat_control_scene.instantiate()
		minor_stat_container.add_child.call_deferred(inst)
		inst.text = text
		inst.name = property_name_with_operation
	else:
		already_exist.text = text

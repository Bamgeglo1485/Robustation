class_name StatisticsProgressComponent extends Component

@export var component_name: String
@export var variable_name: String
@export var divider_variable_name: String
@export var off_if_X_not_visible: Control
@export var recursive: bool = false
var component: Component

func _ready() -> void:
	var node_parent: Node = get_parent()
	if node_parent is not PhysicsBody2D:
		while node_parent is not PhysicsBody2D:
			node_parent = node_parent.get_parent()
			if !node_parent:
				break
	
	if node_parent:
		component = node_parent.get_node_or_null(component_name)

func _physics_process(_delta: float) -> void:
	if off_if_X_not_visible and !off_if_X_not_visible.visible:
		return
	if !component:
		return
	var variable = component.get(variable_name)
	var divider_variable = component.get(divider_variable_name)
	if component and variable:
		if divider_variable:
			if !recursive:
				parent.value = float(variable) / float(divider_variable) * 100
			else:
				parent.value = float(divider_variable) / float(variable) * 100
		else:
			if !recursive:
				parent.value = variable * 100
			else:
				parent.value = (2.0 - float(variable)) * 100

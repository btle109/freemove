extends Area3D
@export var label : Label
func use()->void:
	label.text = "im a prop"
	label.reset()

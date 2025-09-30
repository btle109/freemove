extends Area3D
@export var label : Label
func use():
	label.text = "im a healing prop"
	label.reset()
	return 1

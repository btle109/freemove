extends Node
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Reset"):
		if (get_tree().paused == false):
			get_tree().reload_current_scene()
		else:
			get_tree().quit()
	if event.is_action_pressed("Pause"):
		if (get_tree().paused == true):
			get_tree().paused = false
			$"../UI/Info".text = ""
			print("game unpause")
		else:
			get_tree().paused = true
			$"../UI/Info".text = "Game paused."
			print("game pause")

	if event.is_action_pressed("free"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				#get_tree().paused = false
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				#get_tree().paused = false

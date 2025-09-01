extends Label
	
func reset():
	$Timer.start()
	
func _on_timer_timeout() -> void:
	text = ""

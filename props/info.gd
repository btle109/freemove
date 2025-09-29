extends Label
	
func reset():
	$Timer.stop()
	$Timer.start()
	
func setText(string : String)->void:
	text = string
	reset()
func addText(string : String)->void:
	text += string
	reset()

func _on_timer_timeout() -> void:
	text = ""

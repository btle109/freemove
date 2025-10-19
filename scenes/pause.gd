extends Node
var partyScreen = false;
@onready var player =$"../Character";
@onready var infoArr = [$"../UI/PartyMenu/charM1", $"../UI/PartyMenu/charM2", $"../UI/PartyMenu/charM3", $"../UI/PartyMenu/charM4"]
@onready var labelArr = [$"../UI/PartyMenu/charM1/l1", $"../UI/PartyMenu/charM2/l2", $"../UI/PartyMenu/charM3/l3", $"../UI/PartyMenu/charM4/l4"]
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Reset"):
		if (get_tree().paused == false):
			get_tree().reload_current_scene()
		else:
			get_tree().quit()
	if event.is_action_pressed("Pause"):
		if (partyScreen):
			$"../UI/PartyMenu".visible=false
			partyScreen = false;
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
	if event.is_action_pressed("Party"):
		updatePartyData()
		if (is_inside_tree()):
			if (get_tree().paused == true and partyScreen == false):
				return
		if (partyScreen):
			$"../UI/PartyMenu".visible=false
			partyScreen = false;
			if (is_inside_tree()):
				get_tree().paused = false
		elif (!partyScreen):
			$"../UI/PartyMenu".visible=true
			partyScreen = true;
			if (is_inside_tree()):
				get_tree().paused = true
		print("game pause")	
func updatePartyData()->void:
	for elem in labelArr:
		elem.text = ""
	for elem in player.party:
		if (!elem.dead):
			labelArr[elem.index].text = elem.charName
			labelArr[elem.index].text += "\n"
			labelArr[elem.index].text += elem.charClass
			labelArr[elem.index].text += "\nHP:"
			labelArr[elem.index].text += str(elem.HP)
			labelArr[elem.index].text += "/"
			labelArr[elem.index].text += str(elem.maxHP)
			labelArr[elem.index].text += "\n"

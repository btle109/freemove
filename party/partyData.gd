extends Node
class_name partyData
#var playerClass = 0
var weaponSkill = 100;
var coolDown = 0.5
var atkready = true;
#var weapon := Node3D
#var spells/inventory
func attack()->void:
	#atk logic
	atkready = false;
	print("indirect attack!")

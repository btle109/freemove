extends Node
class_name partyData
#var playerClass = 0
var weaponSkill = 100;
var damage = 10
var coolDown = 2
var atkready = true;
#var weapon := Node3D
#var spells/inventory
func attack()->bool:
	#atk logic
	atkready = false;
	print("indirect attack!")
	return (randi()%100 < weaponSkill/1.5)

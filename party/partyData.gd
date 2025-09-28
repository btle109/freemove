extends Node
class_name partyData
#var playerClass = 0
@export var weaponSkill: int = 100
var damage = 10
var coolDown = 0.6
var atkready = true;
var HP = 100.0
var maxHP = HP
var dead = false;
var index = 0
var hasBow = true
#var weapon := Node3D
#var spells/inventory
func hurt(dmg)->void:
	HP -= dmg;
	if (HP <= 0):
		dead = true;
		atkready = false;
	print("curr health: ", HP)

func attack()->bool:
	#atk logic
	atkready = false;
	print("indirect attack!")
	return (randi()%100 < weaponSkill/1.5)

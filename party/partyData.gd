extends Node
class_name partyData
#var playerClass = 0
@export var weaponSkill: int = 100
@export var charName = "Bach"
var damage = 25 #2d6
var coolDown = 0.6
var atkready = true;
var HP = 100.0
var maxHP = HP
var dead = false;
var index = 0
var hasBow = true
#var weapon := Node3D
#var spells/inventory
func hurt(dmg):
	dmg += -3 + randi() % 7
	HP -= dmg;
	if (HP <= 0):
		dead = true;
		atkready = false;
	print("curr health: ", HP)
	return [true, dmg]

func attack()->bool:
	#atk logic
	atkready = false;
	print("indirect attack!")
	return (randi()%100 < weaponSkill/1.5)

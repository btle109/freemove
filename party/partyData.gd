extends Node
class_name partyData
#var playerClass = 0
@export var weaponSkill: int = 100
@export var charName = "Bach"
var damage = 10 #2d6
var coolDown = 0.6
var atkready = true;
var HP = 100.0
var maxHP = HP
var dead = false;
var index = 0
var hasBow = true
#var weapon := Node3D
#var spells/inventory
func heal(amt):
	if (HP + amt >= maxHP):
		HP = maxHP
	else:
		HP = HP + amt
func hurt(dmg):
	var ret = false
	var prob = randi()% 100 + 1
	if (prob < weaponSkill/3.0): #block chance
		dmg += -7 + randi() % 4		
	else:
		dmg += -3 + randi() % 7
		ret = true
	if (dmg <= 0):
		return [false, -1]
	else:
		HP -= dmg;
	if (HP <= 0):
		dead = true;
		atkready = false;

	#print("curr health: ", HP)
	return [ret, dmg]

func attack()->bool:
	#atk logic
	atkready = false;
	print("indirect attack!")
	return (randi()%100 < weaponSkill/1.5)

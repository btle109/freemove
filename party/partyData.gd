extends Node
class_name partyData
#var playerClass = 0
@export var weaponSkill: int = 100
@export var charName = "Bach"
@export var charClass = "Warrior"
var damage = 10 #2d6
var coolDown = 0.6
var atkready = true;
var HP = 100.0
var maxHP = HP
var dead = false;
var index = 0
var hitPriority = 12
var hasBow = false
var xp = 0
#var weapon := Node3D
#var spells/inventory
func setClass(playClass : int)->void:
	charClass = Global.classList[playClass]
	if playClass == 0: #warrior
		weaponSkill = 100
		HP = 100.0
		maxHP = 100.0
	if playClass == 1: #hunter
		hasBow = true
		weaponSkill = 70
		HP = 80.0
		maxHP = 80.0
	if playClass == 2: #thrall
		weaponSkill = 90
		HP = 110.0
		maxHP = 110.0
	if playClass == 3: #bard
		weaponSkill = 50
		HP = 70.0
		maxHP = 70.0
	if playClass == 4: #thief
		weaponSkill = 80
		HP = 70.0
		maxHP = 70.0
		hitPriority = 6
	if playClass == 5: #peddler
		weaponSkill = 50
		HP = 70.0
		maxHP = 70.0
	if playClass == 6: #adventurer
		HP = 90.0
		maxHP = 90.0
		weaponSkill = 85
		hasBow = true
	if playClass == 7: #killer
		HP = 70.0
		maxHP = 70.0
		weaponSkill = 90
	
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
	print("indirect attack!")
	return (randi()%100 < weaponSkill/1.5)

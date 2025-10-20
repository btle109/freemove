extends Node
class_name partyData
#var playerClass = 0
@export var weaponSkill: int = 100
@export var charName = "Bach"
@export var charClass = "Warrior"
var weapon = preload("res://party/weaponData.gd").new()
var index = 0

var attributes = {"STR" : 10, "CON" : 10, "AGI" : 10, "END" : 10, "CHA" : 10, "INT" : 10}

var skills = {"SWORD" : 0, "SPEAR" : 0, "AXE" : 0, "MACE" : 0, "SHIELD" : 0, "BOW" : 0,
"LEATHER" : 1, "MAIL" : 0, "PLATE" : 0,
"FURY" : 0, "ROGUERY" : 0, "HEROISM" : 0,
"MUSIC" : 0, "MEDITATION": 0,
"ID ITEM" : 0, "DISARM TRAP":0, "RHETORIC" : 0, "HAGGLING" : 0}

var damage = weapon.damage #2d6
# damage  = 5 + STR/2 + classBonus (warrior, nomad, adventurer, killer + 3)
var coolDown = 0.6
var bowCoolDown = 0.6
# coolDown = 8000/(40+ AGI^2 + classBonus)
var atkready = true;
var HP = 100.0
var speed = 1
# HP = 50 + CONST * 4 + classBonus
var maxHP = 100.0
var dead = false;
var hitPriority = 12
# 12 +- classBonus, thrall + 2, thief - 4
var hasBow = false
var xp = 0
var xpNext = 600
var level = 1
#var weapon := Node3D
#var spells/inventory
func setClass(playClass : int)->void:
	charClass = Global.classList[playClass]
	if playClass == 0: #warrior
		attributes = {"STR" : 8, "CON" : 8, "AGI" : 4, "END" : 6, "CHA" : 8, "INT" : 0}
		skills = {"SWORD" : 2, "SPEAR" : 2, "AXE" : 0, "MACE" : 0, "SHIELD" : 2, "BOW" : 0,
"LEATHER" : 1, "MAIL" : 2, "PLATE" : 0,
"FURY" : 0, "ROGUERY" : -1, "HEROISM" : 0,
"MUSIC" : -1, "MEDITATION": -1,
"ID ITEM" : 1, "DISARM TRAP":0, "RHETORIC" : 0, "HAGGLING" : 0}
		maxHP = 50 + attributes["CON"] * 4 + 18
		HP = 50 + attributes["CON"] * 4 + 18
		damage += 3
		damage += ceil(attributes["STR"]/3.0)
		damage += ceil(skills[weapon.type]/3.0)
		coolDown = 8000.0/((50.0 + attributes["AGI"]**2))**2
		#temp, when we get equip weapon/inventory func this will change
		weaponSkill = 50 + skills["SWORD"] * 10 + attributes["AGI"]^2
		
	if playClass == 1: #hunter
		attributes = {"STR" : 5, "CON" : 5, "AGI" : 8, "END" : 6, "CHA" : 4, "INT" : 0}
		skills = {"SWORD" : 2, "SPEAR" : 0, "AXE" : 0, "MACE" : 0, "SHIELD" : 0, "BOW" : 3,
"LEATHER" : 1, "MAIL" : 1, "PLATE" : -1,
"FURY" : 0, "ROGUERY" : 0, "HEROISM" : 0,
"MUSIC" : -1, "MEDITATION": -1,
"ID ITEM" : 1, "DISARM TRAP":2, "RHETORIC" : 0, "HAGGLING" : 0}
		hasBow = true
		bowCoolDown = 8000.0/((30+ attributes["AGI"]**2 + 15*skills["BOW"])**2)
		weaponSkill = 70
		damage += ceil(attributes["STR"]/3.0)
		damage += ceil(skills[weapon.type]/3.0)
		coolDown = 8000.0/((50+ attributes["AGI"]**2)**2)
		maxHP = 50 + attributes["CON"] * 4
		HP =  50 + attributes["CON"] * 4
	if playClass == 2: #thrall
		attributes = {"STR" : 10, "CON" : 8, "AGI" : 6, "END" : 8, "CHA" : 2, "INT" : 0}
		skills = {"SWORD" : 2, "SPEAR" : 0, "AXE" : 2, "MACE" : 0, "SHIELD" : 0, "BOW" : 0,
"LEATHER" : 1, "MAIL" : -1, "PLATE" : -1,
"FURY" : 2, "ROGUERY" : 0, "HEROISM" : 0,
"MUSIC" : 0, "MEDITATION": 0,
"ID ITEM" : 1, "DISARM TRAP":2, "RHETORIC" : 0, "HAGGLING" : 0}
		weaponSkill = 60

		coolDown = 8000.0/((50.0+ attributes["AGI"]**2 + 5*skills["FURY"])**2)
		maxHP = 50 + attributes["CON"] * 4 + 10
		HP =  50 + attributes["CON"] * 4 + 10
		weapon.weaponMesh = load("res://props/axce.res")
		weapon.damage = 8
		damage += ceil(attributes["STR"]/3.0)
		damage += ceil(skills[weapon.type]/3.0)
		damage = weapon.damage
		weapon.collisionParam = 1.5
	if playClass == 3: #bard
		attributes = {"STR" : 3, "CON" : 3, "AGI" : 6, "END" : 3, "CHA" : 8, "INT" : 8}
		skills = {"SWORD" : 1, "SPEAR" : 0, "AXE" : -1, "MACE" : -1, "SHIELD" : 0, "BOW" : 0,
"LEATHER" : 1, "MAIL" : 0, "PLATE" : -1,
"FURY" : -1, "ROGUERY" : 0, "HEROISM" : -1,
"MUSIC" : 4, "MEDITATION": 4,
"ID ITEM" : 1, "DISARM TRAP":0, "RHETORIC" : 4, "HAGGLING" : 0}
		weaponSkill = 70
		damage += attributes["STR"]/2
		coolDown = 8000/((50 + attributes["AGI"]**2)**2)
		maxHP = 50 + attributes["CON"] * 4 
		HP =  50 + attributes["CON"] * 4 
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
	speed += ceil(float(attributes["AGI"])/3.0)
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

func updateStats()->void:
	xpNext = 600  + 500*log(level+1)

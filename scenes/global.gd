extends Node
var party = []
var classList = ["Warrior", "Hunter", "Thrall","Bard", "Thief", "Peddler", "Adventurer", "Killer"]
func _ready()->void:
	#party2.HP = 20.0
	#party3.HP = 10.0
	#party4.HP = 10.0

	
	for elem in party:
	#	print(elem.index, " weaponSkill: ", elem.weaponSkill)
		elem.coolDown = 9000.0 / ((elem.weaponSkill) * (elem.weaponSkill))

extends Node2D
@onready var summonButtons = [$PartySelect/summon2, $PartySelect/summon3, $PartySelect/summon4]
@onready var partyInit = [$partyInit1, $partyInit2, $partyInit3, $partyInit4]
@onready var returnButtons = [$partyInit2/RETURN, $partyInit3/RETURN, $partyInit4/RETURN]
@onready var nameEntry = [$partyInit1/nameEntry, $partyInit2/nameEntry, $partyInit3/nameEntry, $partyInit4/nameEntry]
@onready var classEntry = [$partyInit1/ClassEntry,$partyInit2/ClassEntry,$partyInit3/ClassEntry,$partyInit4/ClassEntry ]
@onready var classDescription = [$partyInit1/Label, $partyInit2/Label, $partyInit3/Label, $partyInit4/Label]
var descriptions = ["Perhaps long ago you were a warrior in a lord's army. You were left to rot among the bodies of your comrades.
Your primary attributes are:
STR, CON, CHA
Your primary skills are:
SWORD, SPEAR, MAIL",
"In life you were a hunter. You were slain by your quarry deep in the woods.
Your primary attributes are:
AGI , END, STR
Your primary skills are:
BOW, SWORD, DISARM TRAP",
 "You were a wretched thrall, stolen from your homeland. You were killed by your own master in a fit of rage.
Your primary attributes are:
STR, CONST,  END
Your primary skills are:
AXE, SWORD, FURY", "You were a bard, somewhat middling in terms of musical skill. You were murdered in a drunken tavern brawl.
Your primary attributes are:
INT, CHA, AGI
Your primary skills are:
MUSIC, RHETORIC, ID ITEM", "dog", "dog", "dog", "dog"
]

var party1 = preload("res://party/partyData.gd").new()
var party2 = preload("res://party/partyData.gd").new()
var party3 = preload("res://party/partyData.gd").new()
var party4 = preload("res://party/partyData.gd").new()

var tempParty = [party1,party2,party3, party4]
var party = [party1]
var sumIndex = 0
var returnIndex = 0
func _ready()->void:
	party2.charName = "Darren"
	party3.charName = "Buddy"
	party4.charName = "Evan"
	party2.charClass = "Hunter"
	party3.charClass = "Thrall"
	party4.charClass = "Bard"
	party2.index = 1
	party3.index = 2
	party4.index = 3

func summon()->void:
	summonButtons[sumIndex].visible = false;
	partyInit[sumIndex+1].visible = true
	for elem in returnButtons:
		elem.visible = false
	returnButtons[returnIndex].visible = true
	party.append(tempParty[sumIndex+1])
	print("SUMINDEX:", sumIndex)
	sumIndex += 1;
	returnIndex += 1;
	if (sumIndex < 3):
		summonButtons[sumIndex].visible = true;
	print("PARTY MEMBERS:")
	for elem in party:
		print(elem.index)
		
	
func _on_summon_pressed() -> void:
	summon()
	
func _on_return_pressed()->void:
	if (sumIndex == 3):
		sumIndex -= 1
		summonButtons[sumIndex].visible = true
	else:
		summonButtons[sumIndex].visible = false
		sumIndex -= 1
		summonButtons[sumIndex].visible = true
	partyInit[returnIndex].visible = false
	returnButtons[returnIndex-1].visible = false
	party.erase(party[returnIndex])
	print("PARTY MEMBERS:")
	for elem in party:
		print(elem.index)
	returnIndex -= 1
	partyInit[returnIndex].visible = true
	returnButtons[returnIndex-1].visible = true

func _on_continue_pressed() -> void:
	for elem in party:
		if (nameEntry[elem.index].text == ""):
			pass
		else:
			elem.charName = nameEntry[elem.index].text
		elem.charClass = Global.classList[classEntry[elem.index].selected]
		elem.setClass(classEntry[elem.index].selected)
		print(elem.charClass)
	Global.party = party
	get_tree().change_scene_to_file("res://scenes/test_world.tscn")


func _on_class_entry_item_selected(index: int) -> int:
	print(Global.classList[index])
	print(classEntry[0].selected)
	for i in range(0,4):
		classDescription[i].text = descriptions[classEntry[i].selected]
	return index

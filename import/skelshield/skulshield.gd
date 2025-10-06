extends "res://import/skeleton/skeleton.gd"
var bashSound = preload("res://sound/shield_impact-2-382412.mp3")
func _ready()->void:
	navigation_agent.avoidance_priority = randf_range(0.3, 0.7)
	walk_rot_speed = randf_range(6.0, 8.0)
	attack_rot_speed = randf_range(6.0, 8.0)
	MoveSpeed = 2.5
	DEF_CHANCE = 70
	ATK_CHANCE = 50
	walkName = "walk"
	atkName = "skelAttack"
	stunName = "stun"
	dieName = "die"
	restName = "rest"
	sound = load("res://import/skelshield/skelescream.mp3")
	attackZone = $attackZone
	add_to_group(group)
	if enemyRange:
		enemyRange.body_entered.connect(_on_enemy_range_body_entered)
		enemyRange.body_exited.connect(_on_enemy_range_body_exited)

	if attackZone:
		attackZone.body_entered.connect(_on_attack_zone_body_entered)
		attackZone.body_exited.connect(_on_attack_zone_body_exited)
		
	$AnimationPlayer.animation_finished.connect( _on_animation_player_animation_finished)

func hurt(_enemyName, dmg: int):

	if !alive:
		return 
	var prob = randi() % 100 + 1
	if prob < DEF_CHANCE:
		prob = randi() % 100 + 1
		var dmgAmt =  int(0.4 * dmg + randi() % 4)
		HP -= dmgAmt
		#$"../../UI/Info".addText(charName + " for " + str(dmgAmt) + " damage.")
		print("ENEMY ", HP, " - DEFENDED")
		$hitsounds.stream = clashsound
		$hitsounds.play()
		if HP <= 0:
			alive = false
		return [false, dmgAmt]
	else:
		print("stun!")
		stunned = true
		set_state(EnemyState.STUNNED)
		var dmgAmt = int(dmg + randi() % 7)
		HP -= dmgAmt
		#$"../../UI/Info".addText(charName + " for " + str(dmgAmt) + " damage.")
		print("ENEMY ", HP, " - HIT")
		$hitsounds.stream = smashsound
		$hitsounds.play()
		if HP <= 0:
			alive = false
		return [true, dmgAmt]
		
func block()->void:	
	$hitsounds.stream = bashSound
	$hitsounds.play()
		

extends "res://import/skeleton/skeleton.gd"
@onready var bowName = "skelAttack_bow"
@export var arrowScene : PackedScene
func _ready()->void:
	navigation_agent.avoidance_priority = randf_range(0.3, 0.7)
	walk_rot_speed = randf_range(6.0, 8.0)
	attack_rot_speed = randf_range(6.0, 8.0)
	MoveSpeed = 2.5
	DEF_CHANCE = 15
	ATK_CHANCE = 60
	walkName = "walk"
	atkName = "skelAttack_melee"
	stunName = "stun"
	dieName = "die"
	restName = "rest"
	
	attackZone = $attackZone
	add_to_group(group)
	if enemyRange:
		enemyRange.body_entered.connect(_on_enemy_range_body_entered)
		enemyRange.body_exited.connect(_on_enemy_range_body_exited)

	if attackZone:
		attackZone.body_entered.connect(_on_attack_zone_body_entered)
		attackZone.body_exited.connect(_on_attack_zone_body_exited)
		
	$AnimationPlayer.animation_finished.connect( _on_animation_player_animation_finished)

func _physics_process(delta: float) -> void:
	# If dead, lock in DEAD state
	if not alive:
		if state != EnemyState.DEAD:
			set_state(EnemyState.DEAD)
		return

	clean_dead_targets()
	
	# If stunned, stop movement
	if stunned:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	choose_target()
	velocity = Vector3.ZERO

	# --- If we have a target, calculate desired position with offset ---
	var desired_target: Vector3 = Vector3.ZERO
	var dist_to_target: float = 0.0

	if atkTarget:
		var offset_angle = float(get_instance_id() % 360) * 0.01745 # radians
		var offset = Vector3(cos(offset_angle), 0, sin(offset_angle)) * offset_strength
		desired_target = atkTarget.global_position + offset
		dist_to_target = global_position.distance_to(atkTarget.global_position)

		# --- RANGED ATTACK ---
		if dist_to_target > 5.0 and in_range:
			set_state(EnemyState.ATTACKING)

			# Rotate toward target
			var face_dir = (atkTarget.global_position - global_position).normalized()
			face_dir.y = 0
			var attack_yaw = atan2(face_dir.x, face_dir.z)
			rotation.y = lerp_angle(rotation.y, attack_yaw, attack_rot_speed * delta)

			# Trigger bow attack animation
			if can_change_state:
				can_change_state = false
				play_animation(bowName, false)

		# --- MELEE ATTACK ---
		elif dist_to_target <= 5.0 and in_attack_zone:
			set_state(EnemyState.ATTACKING)

			var face_dir = (atkTarget.global_position - global_position).normalized()
			face_dir.y = 0
			var attack_yaw = atan2(face_dir.x, face_dir.z)
			rotation.y = lerp_angle(rotation.y, attack_yaw, attack_rot_speed * delta)

			if can_change_state:
				can_change_state = false
				play_animation(atkName, false)

		# --- WALK TOWARD TARGET ---
		elif in_range and dist_to_target > 1.5:
			set_state(EnemyState.WALKING)
			handle_movement(delta, desired_target)

	# --- RETURN TO ORIGIN ---
	elif global_position.distance_to(orig.global_position) > 0.5:
		set_state(EnemyState.WALKING)
		handle_movement(delta, orig.global_position)

	# --- IDLE ---
	else:
		set_state(EnemyState.IDLE)
		velocity = Vector3.ZERO

	move_and_slide()

func shoot() -> void:
	if (!atkTarget):
		return
	else:
		var aim = atkTarget.global_position + Vector3(0,0.5,0)
		var arrowDir = (aim - $skelChar/arrowOrigin.global_position).normalized()
		var arrow = arrowScene.instantiate()
		arrow.messaging = false
		arrow.shooter = "Skeleton Archer"
		arrow.damage = damage/2
		get_parent().add_child(arrow)
		arrow.global_position =$skelChar/arrowOrigin.global_position
		arrow.set_direction(arrowDir)
		
	

extends CharacterBody3D

# === CONFIG ===
@export var MoveSpeed: float = 3
@export var walk_rot_speed: float = 8.0  # default
@export var attack_rot_speed: float = 12.0  # default

@export var HP = 125
@export var orig : Node3D
@export var group = "Enemy"
@export var killGroup = "Player"
@export var charName = "Skeleton Swordsman"
@export var enemyRange : Area3D
@export var damage = 18
var attackZone : Area3D
var walkName = "skelChar|Walk"
var atkName = "skelChar|skelAttack"
var stunName = "newAnimfbx/skelChar|Stun"
var dieName = "newAnimfbx/skelChar|die"
var restName = "skelChar|rest"
@export var label : Label 
var atkArr = []
var killArr = []
var atkTarget
var offset_strength = 1.1
# === NODES ===
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var screaming_audio: AudioStreamPlayer3D = $screaming
@onready var steps_audio: AudioStreamPlayer3D = $steps
 
# === CONSTANTS ===
var DEF_CHANCE = 50
var ATK_CHANCE = 70

# === STATES ===
enum EnemyState { IDLE, WALKING, ATTACKING, STUNNED, DEAD }
var state: EnemyState = EnemyState.IDLE

# === FLAGS ===
var alive = true
var in_range = false     # ← From enemyRange
var in_attack_zone = false  # ← From attackZone
var stunned = false
var dead = false
var can_change_state := true

# === AUDIO ===
var sound = preload("res://import/skeleton/skeletonscream.mp3")
var sound2 = preload("res://import/skeleton/skeletonscream2.mp3")
var smashsound = preload("res://sound/smashsound.mp3")
var clashsound = preload("res://sound/swordclashshort.mp3")
var swingSound = preload("res://sound/sound2.mp3")
# === REFERENCES ===
var player: Node3D = null

# === READY ===
func _ready() -> void:
	#player = get_tree().get_nodes_in_group("Player")[0]
	walk_rot_speed = randf_range(6.0, 10.0)
	attack_rot_speed = randf_range(8.0, 12.0)
	navigation_agent.avoidance_priority = randf_range(0, 0.5)
	attackZone = $attackZone
	add_to_group(group)
	if enemyRange:
		enemyRange.body_entered.connect(_on_enemy_range_body_entered)
		enemyRange.body_exited.connect(_on_enemy_range_body_exited)

	if attackZone:
		attackZone.body_entered.connect(_on_attack_zone_body_entered)
		attackZone.body_exited.connect(_on_attack_zone_body_exited)

func set_state(new_state: EnemyState) -> void:
	if state == new_state:
		return
	if !can_change_state and new_state not in [EnemyState.STUNNED, EnemyState.DEAD]:
		return
	
	state = new_state

	match state:
		EnemyState.IDLE:
			play_animation(restName)

		EnemyState.WALKING:
			play_animation(walkName, true)

		EnemyState.ATTACKING:
			# The action is now handled in _physics_process.
			# We can leave this empty.
			pass

		EnemyState.STUNNED:
			can_change_state = false
			play_animation(stunName, false)

		EnemyState.DEAD:
			die()

func play_animation(anim_name: String, loop := false) -> void:
	var anim = animation_player.get_animation(anim_name)
	if anim:
		if (loop):
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			anim.loop_mode = Animation.LOOP_NONE
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)
			
func choose_target() -> void:
	if atkArr.is_empty():
		atkTarget = null
		return
	# If current target is invalid (not in list or dead), replace it
	if atkTarget == null or not atkArr.has(atkTarget) or atkTarget.dead:
		# Clean up invalid targets
		atkArr = atkArr.filter(func(t): return t != null and not t.dead)

		if atkArr.is_empty():
			atkTarget = null
			return

		atkTarget = atkArr.pick_random()
			
func clean_dead_targets() -> void:
	atkArr = atkArr.filter(func(t): return t != null and not t.dead)
	killArr = killArr.filter(func(t): return t != null and not t.dead)

	if atkArr.is_empty():
		in_range = false
		atkTarget = null

	if killArr.is_empty():
		in_attack_zone = false
		
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

	# Default velocity
	velocity = Vector3.ZERO

	# --- If we have a target, calculate desired position with offset ---
	var desired_target: Vector3 = Vector3.ZERO
	if atkTarget != null:
		var offset_angle = float(get_instance_id() % 360) * 0.01745 # radians
		var offset = Vector3(cos(offset_angle), 0, sin(offset_angle)) * offset_strength
		desired_target = atkTarget.global_position + offset

	# --- ATTACK ZONE ---
	if in_attack_zone and atkTarget != null:
		set_state(EnemyState.ATTACKING)

		# Rotate toward target
		var face_dir = (desired_target - global_position).normalized()
		face_dir.y = 0
		var attack_yaw = atan2(face_dir.x, face_dir.z)
		rotation.y = lerp_angle(rotation.y, attack_yaw, attack_rot_speed * delta)

		# Trigger attack animation
		if can_change_state:
			can_change_state = false
			play_animation(atkName, false)

	# --- WALKING TOWARD TARGET ---
	elif in_range and atkTarget != null:
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

	
func handle_movement(delta: float, target_pos: Vector3 = player.global_position) -> void:
	if (dead):
		velocity = Vector3.ZERO
		return;
	var offset_angle = float(get_instance_id() % 360) * 0.01745 # convert to radians
	var offset = Vector3(cos(offset_angle), 0, sin(offset_angle)) * offset_strength
	navigation_agent.set_target_position(target_pos + offset)
	
	if navigation_agent.is_navigation_finished():
		set_state(EnemyState.IDLE)
		velocity = Vector3.ZERO
		return

	var next_position = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	direction.y = 0
	direction = direction.normalized()

	if direction.length() > 0.01:
		var look_dir = (target_pos - global_position).normalized()
		look_dir.y = 0
		var target_yaw = atan2(look_dir.x, look_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, walk_rot_speed * delta)
  # tweak 4–8 range
		#var target_rotation = atan2(direction.x, direction.z)
		#rotation.y = lerp_angle(rotation.y, target_rotation, 8 * delta)
		velocity = direction * MoveSpeed
	else:
		velocity = Vector3.ZERO

func animAttack() -> void:
	if !screaming_audio.is_playing():
		screaming_audio.stream = sound
		screaming_audio.play()

func attack() -> void:
	# Clean up dead or invalid targets
	killArr = killArr.filter(func(t): return t != null and not t.dead)
	print(killArr)
	print(atkArr)
	if killArr.is_empty():
		in_attack_zone = false
		return

	var killTarget = killArr.pick_random()
	if killTarget:
		var prob = randi()%100 + 1
		if (prob < ATK_CHANCE):
			killTarget.hurt(charName, damage)
		else:
			$hitsounds.stream =  swingSound
			$hitsounds.play()
			killTarget.hurt(charName, -1)
		

func hurt(_enemyName, dmg: int):

	if !alive:
		return 
	var prob = randi() % 100 + 1
	if prob < DEF_CHANCE:
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
		


func die() -> void:
	$removeArea/removeBox.disabled = false
	if dead:
		return
	dead = true
	animation_player.play(dieName)
	await get_tree().create_timer(5).timeout
	queue_free()

func _on_enemy_range_body_entered(body: Node3D) -> void:
	if body.is_in_group(killGroup):
		atkArr.append(body)
		in_range = true

func _on_enemy_range_body_exited(body: Node3D) -> void:
	if body.is_in_group(killGroup):
		atkArr.erase(body)
		if body == atkTarget:
			atkTarget = null
		if atkArr.is_empty():
			in_range = false

		
func _on_attack_zone_body_entered(body: Node3D) -> void:
	if (atkArr.find(body) != -1):
		killArr.append(body)
		in_attack_zone = true

func _on_attack_zone_body_exited(body: Node3D) -> void:
	if killArr.has(body):
		killArr.erase(body)
		if killArr.is_empty():
			in_attack_zone = false
		
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	can_change_state = true

	if anim_name == stunName:
		stunned = false
	# Do not force a new state — let _physics_process naturally re-evaluate

	 		
func use() -> void:
	label.text = "A skeleton."
	queue_free()

extends CharacterBody3D

# === CONFIG ===
@export var MoveSpeed: float = 3
@export var HP = 100
@export var orig : Node3D
@export var group = "Enemy"
@export var killGroup = "Player"

@export var enemyRange : Area3D
var attackZone : Area3D
@export var label : Label 
var atkArr = []
var killArr = []
var atkTarget

# === NODES ===
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var screaming_audio: AudioStreamPlayer3D = $screaming
@onready var steps_audio: AudioStreamPlayer3D = $steps

# === CONSTANTS ===
const DEF_CHANCE = 50
const ATK_CHANCE = 50

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
# === REFERENCES ===
var player: Node3D = null

# === READY ===
func _ready() -> void:
	#player = get_tree().get_nodes_in_group("Player")[0]
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
	#print("transition from: ", state, " to ", new_state)
	state = new_state

	match state:
		EnemyState.IDLE:
			play_animation("skelChar|rest")

		EnemyState.WALKING:
			play_animation("skelChar|Walk", true)

		EnemyState.ATTACKING:
			can_change_state = false
			play_animation("skelChar|skelAttack", false)

		EnemyState.STUNNED:
			can_change_state = false
			play_animation("newAnimfbx/skelChar|Stun", false)

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
	if atkTarget == null or not atkArr.has(atkTarget) or atkTarget.dead:
		if atkArr.is_empty():
			atkTarget = null
		else:
			atkTarget = atkArr.pick_random()
			
func _physics_process(delta: float) -> void:
	#global_position.y = 0
	if !alive:
		if state != EnemyState.DEAD:
			set_state(EnemyState.DEAD)
		move_and_slide()
		return

	# Movement & state handling
	if stunned:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Priority: ATTACK > WALK > IDLE
	if in_attack_zone:
		velocity = Vector3.ZERO
		set_state(EnemyState.ATTACKING)
	elif in_range:
		choose_target()
		if atkTarget != null:
			handle_movement(delta, atkTarget.global_position)
			set_state(EnemyState.WALKING)
	else:
	# If not in range and not at origin, return to origin
		if global_position.distance_to(orig.global_position) > 0.5:
			handle_movement(delta, orig.global_position)
			set_state(EnemyState.WALKING)
		else:
			velocity = Vector3.ZERO
			set_state(EnemyState.IDLE)

	move_and_slide()
	
func handle_movement(delta: float, target_pos: Vector3 = player.global_position) -> void:

	navigation_agent.set_target_position(target_pos)
	
	if navigation_agent.is_navigation_finished():
		set_state(EnemyState.IDLE)
		velocity = Vector3.ZERO
		return

	var next_position = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	direction.y = 0
	direction = direction.normalized()

	if direction.length() > 0.01:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 8 * delta)
		velocity = direction * MoveSpeed
	else:
		velocity = Vector3.ZERO

func animAttack() -> void:
	if !screaming_audio.is_playing():
		screaming_audio.stream = sound
		screaming_audio.play()
func attack()->void:
	if (killArr.is_empty()):
		return
	var killTarget = killArr.pick_random()
	if killTarget.dead:
		killArr.erase(killTarget)
		atkArr.erase(killTarget)
		if (killArr.is_empty()):
			in_attack_zone = false
		if (atkArr.is_empty()):
			in_range = false 
	killTarget.hurt(10)

func hurt(dmg: int) -> void:
	if !alive:
		return

	var prob = randi() % 100 + 1
	if prob < DEF_CHANCE:
		HP -= int(0.4 * dmg + randi() % 4)
		print("ENEMY ", HP, " - DEFENDED")
		$hitsounds.stream = clashsound
		$hitsounds.play()
		
	else:
		print("stun!")
		stunned = true
		set_state(EnemyState.STUNNED)
		HP -= int(dmg + randi() % 7)
		print("ENEMY ", HP, " - HIT")
		$hitsounds.stream = smashsound
		$hitsounds.play()
		
	if HP <= 0:
		alive = false

func die() -> void:
	$removeArea/removeBox.disabled = false
	if dead:
		return
	dead = true
	animation_player.play("newAnimfbx/skelChar|die")
	await get_tree().create_timer(5).timeout
	queue_free()

func _on_enemy_range_body_entered(body: Node3D) -> void:
	if body.is_in_group(killGroup):
		atkArr.append(body)
		in_range = true

func _on_enemy_range_body_exited(body: Node3D) -> void:
	if body.is_in_group(killGroup):
		atkArr.erase(body)
	if (atkArr.is_empty()):
		in_range = false
		
func _on_attack_zone_body_entered(body: Node3D) -> void:
	if (atkArr.find(body) != -1):
		killArr.append(body)
		in_attack_zone = true

func _on_attack_zone_body_exited(body: Node3D) -> void:
	if (atkArr.find(body) != -1):
		killArr.erase(body)
	if (killArr.is_empty()):
		in_attack_zone = false
		
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	can_change_state = true

	if anim_name == "newAnimfbx/skelChar|Stun":
		stunned = false
	# Do not force a new state — let _physics_process naturally re-evaluate
	elif anim_name == "skelChar|skelAttack":
		if in_attack_zone:
			set_state(EnemyState.ATTACKING)
			play_animation("skelChar|skelAttack", false)
			
func use() -> void:
	label.text = "A skeleton."
	queue_free()

# COPYRIGHT Colormatic Studios
# MIT license
# Quality Godot First Person Controller v2


extends CharacterBody3D


#region Character Export Group

## The settings for the character's movement and feel.
@export_category("Character")
## The speed that the character moves at without crouching or sprinting.
@export var base_speed : float = 3.0
## The speed that the character moves at when sprinting.
@export var sprint_speed : float = 6.0
## The speed that the character moves at when crouching.
@export var crouch_speed : float = 1.0

## How fast the character speeds up and slows down when Motion Smoothing is on.
@export var acceleration : float = 10.0
## How high the player jumps.
@export var jump_velocity : float = 4.5
## How far the player turns when the mouse is moved.
@export var mouse_sensitivity : float = 0.1
## Invert the X axis input for the camera.
@export var invert_camera_x_axis : bool = false
## Invert the Y axis input for the camera.
@export var invert_camera_y_axis : bool = false
## Whether the player can use movement inputs. Does not stop outside forces or jumping. See Jumping Enabled.
@export var immobile : bool = false
## The reticle file to import at runtime. By default are in res://addons/fpc/reticles/. Set to an empty string to remove.
@export_file var default_reticle

#endregion

#region Nodes Export Group

@export_group("Nodes")
## A reference to the camera for use in the character script. This is the parent node to the camera and is rotated instead of the camera for mouse input.
#@export var HEAD : Node3D
## A reference to the camera for use in the character script.
#@export var CAMERA : Camera3D
## A reference to the headbob animation for use in the character script.
@export var HEADBOB_ANIMATION : AnimationPlayer
## A reference to the jump animation for use in the character script.
@export var JUMP_ANIMATION : AnimationPlayer
## A reference to the crouch animation for use in the character script.
@export var CROUCH_ANIMATION : AnimationPlayer
## A reference to the the player's collision shape for use in the character script.
#@export var COLLISION_MESH : CollisionShape3D

@onready var HEAD = $Head
@onready var CAMERA = $Head/Camera
@onready var COLLISION_MESH = $Collision

@onready var swingSound = load("res://sound/sound2.mp3")
@export var arrowScene : PackedScene
var bowSound = preload("res://sound/65733__erdie__bow01.wav")
var hurtSound = preload("res://sound/sound.wav")
var clashSound = preload("res://sound/swordclashshort.mp3")
#@onready var hurtSound = load("res://sound/sound.wav")
var atkArr = []

#endregion

#region Controls Export Group

# We are using UI controls because they are built into Godot Engine so they can be used right away
@export_group("Controls")
## Use the Input Map to map a mouse/keyboard input to an action and add a reference to it to this dictionary to be used in the script.
@export var controls : Dictionary = {
	LEFT = "ui_left",
	RIGHT = "ui_right",
	FORWARD = "ui_up",
	BACKWARD = "ui_down",
	JUMP = "ui_accept",
	CROUCH = "crouch",
	SPRINT = "sprint",
	PAUSE = "ui_cancel"
	}
@export_subgroup("Controller Specific")
## This only affects how the camera is handled, the rest should be covered by adding controller inputs to the existing actions in the Input Map.
@export var controller_support : bool = false
## Use the Input Map to map a controller input to an action and add a reference to it to this dictionary to be used in the script.
@export var controller_controls : Dictionary = {
	LOOK_LEFT = "look_left",
	LOOK_RIGHT = "look_right",
	LOOK_UP = "look_up",
	LOOK_DOWN = "look_down"
	}
## The sensitivity of the analog stick that controls camera rotation. Lower is less sensitive and higher is more sensitive.
@export_range(0.001, 1, 0.001) var look_sensitivity : float = 0.035

#endregion

#region Feature Settings Export Group

@export_group("Feature Settings")
## Enable or disable jumping. Useful for restrictive storytelling environments.
@export var jumping_enabled : bool = true
## Whether the player can move in the air or not.
@export var in_air_momentum : bool = true
## Smooths the feel of walking.
@export var motion_smoothing : bool = true
## Enables or disables sprinting.
@export var sprint_enabled : bool = true
## Toggles the sprinting state when button is pressed or requires the player to hold the button down to remain sprinting.
@export_enum("Hold to Sprint", "Toggle Sprint") var sprint_mode : int = 0
## Enables or disables crouching.
@export var crouch_enabled : bool = false
## Toggles the crouch state when button is pressed or requires the player to hold the button down to remain crouched.
@export_enum("Hold to Crouch", "Toggle Crouch") var crouch_mode : int = 0
## Wether sprinting should effect FOV.
@export var dynamic_fov : bool = true
## If the player holds down the jump button, should the player keep hopping.
@export var continuous_jumping : bool = true
## Enables the view bobbing animation.
@export var view_bobbing : bool = true
## Enables an immersive animation when the player jumps and hits the ground.
@export var jump_animation : bool = true
## This determines wether the player can use the pause button, not wether the game will actually pause.
@export var pausing_enabled : bool = true
## Use with caution.
@export var gravity_enabled : bool = true
## If your game changes the gravity value during gameplay, check this property to allow the player to experience the change in gravity.
@export var dynamic_gravity : bool = false

#endregion

#region Member Variable Initialization

# These are variables used in this script that don't need to be exposed in the editor.
var speed : float = base_speed
var current_speed : float = 0.0
# States: normal, crouching, sprinting
var state : String = "normal"
var low_ceiling : bool = false # This is for when the ceiling is too low and the player needs to crouch.
var was_on_floor : bool = true # Was the player on the floor last frame (for landing animation)
# The reticle should always have a Control node as the root
var RETICLE : Control

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process

# Stores mouse input for rotating the camera in the physics process
var mouseInput : Vector2 = Vector2(0,0)
#endregion

#region party system
var party1 = Global.party[0]
#var party2 = Global.party2
#var party3 = Global.party3
#var party4 = Global.party4
var party = []
#var partyHash = {party1 : 1 ,party2 : 2,party3 : 3, party4 : 4}
@onready var partyImg = [$UserInterface/Party/p_img1, $UserInterface/Party/p_img2, $UserInterface/Party/p_img3, $UserInterface/Party/p_img4]
@onready var partyHighlight = [$UserInterface/Party/party1, $UserInterface/Party/party2, $UserInterface/Party/party3, $UserInterface/Party/party4]
@onready var readyIndicators = [$UserInterface/Party/readyIndicators/readyindicator, $UserInterface/Party/readyIndicators/readyindicator2, $UserInterface/Party/readyIndicators/readyindicator3, $UserInterface/Party/readyIndicators/readyindicator4]
@onready var HPBars = [$UserInterface/Party/HPbar/hp1, $UserInterface/Party/HPbar/hp2, $UserInterface/Party/HPbar/hp3, $UserInterface/Party/HPbar/hp4]
var activePlayer = party1;
var inactiveIndex = -1;
var activeIndex = 0;
var dead = false;

func _ready():
	print(party)
	for elem in Global.party:
		party.append(elem)
	#It is safe to comment this line if your game doesn't start with the mouse captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# If the controller is rotated in a certain direction for game design purposes, redirect this rotation into the head.
	HEAD.rotation.y = rotation.y
	rotation.y = 0
	
	if default_reticle:
		change_reticle(default_reticle)

	initialize_animations()
	check_controls()
	enter_normal_state()

	refreshPlayer()
	if party.size() > 1:
		inactiveIndex = 1
	for elem in party:
		HPBars[elem.index].value = float(elem.HP)/float(elem.maxHP) * 100.0
		partyImg[elem.index].visible = true
		readyIndicators[elem.index].visible=  true
		HPBars[elem.index].visible = true
	#	print(elem.index, " cooldown: ", elem.coolDown)
	
func refreshPlayer() -> void:
	$Head/attacks.speed_scale = activePlayer.weaponSkill/100.0
	
func heal(index, amt)-> void:
	print("heal!")
	if (index == 4):
		for elem in party:
			if !elem.dead:
				elem.heal(amt)
				HPBars[elem.index].value = elem.HP/elem.maxHP * 100

	else:
		if !party[index].dead:
			party[index].heal(amt)
			HPBars[index].value = party[index].HP/party[index].maxHP * 100

func switchActivePlayer(n: int) -> void:
	if ($Head/attacks.is_playing() && $Head/attacks.current_animation != "RESET") || (party[n].dead):
			return
	activeIndex = n
	activePlayer = party[n]
	for i in 4:
		if (i==n):
			partyHighlight[i].color = Color(1, 0.843137, 0, 1)
			partyHighlight[i].show()
			$Head/sword.mesh = party[i].weapon.weaponMesh
			$Head/sword/swordCollision/col_shape.scale = Vector3(party[i].weapon.collisionParam, party[i].weapon.collisionParam, party[i].weapon.collisionParam)
			base_speed = party[i].speed
			sprint_speed = 3 + party[i].speed
			print("SPEED:", base_speed)
		else:
			partyHighlight[i].hide()
	setInactive(n)
	refreshPlayer()

func setInactive(n : int)->void:
	if (n==0):
		if (party[1].atkready):
			partyHighlight[1].color = Color(0.133333, 0.545098, 0.133333, 1)
		else:
			partyHighlight[1].color = Color(0.862745, 0.0784314, 0.235294, 1)
		partyHighlight[1].show()
		inactiveIndex = 1
	else:
		if (party[0].atkready):
			partyHighlight[0].color = Color(0.133333, 0.545098, 0.133333, 1)
		else:
			partyHighlight[0].color = Color(0.862745, 0.0784314, 0.235294, 1)
		partyHighlight[0].show()
		inactiveIndex = 0
	return

func hurt(enemyName, dmg)->void:

	var dmgArr = []
	for elem in party:
		if (!elem.dead):
			dmgArr.append(elem)
	if (dmgArr.is_empty()):
		return
	var rand = dmgArr.pick_random()
	if (randi()%100 + 1 < party[activeIndex].hitPriority):
		rand = party[activeIndex]
		print("active character takes the hit")
	var msg = ""
	if (dmg == -1):
		msg = enemyName + " swings at " + rand.charName + " and misses."
		$"../UI/Info".setText(msg)
	else:
		var ret = rand.hurt(dmg)
		start_cooldown(rand.index, rand.coolDown)
		if (ret):
			if (rand.HP <= 0):
				msg = enemyName + " kills " + rand.charName + "."
			elif (dmg == -1):
				msg = enemyName + " is blocked entirely by " + rand.charName + " . "
				$hurtsfx.stream = clashSound
				$hurtsfx.play()
			elif (ret[0] == false):
				msg = enemyName + " is blocked by " + rand.charName + " for " + str(ret[1]) + " points."
				$hurtsfx.stream = clashSound
				$hurtsfx.play()
			elif (ret[0] == true):
				msg = enemyName + " strikes " + rand.charName + " for " + str(ret[1]) + " points."
				$"../UI/Info".setText(msg)
				$hurtsfx.stream = hurtSound
				$hurtsfx.play()
			HPBars[rand.index].value = float(rand.HP)/float(rand.maxHP) * 100.0
			if(rand.HP <= 0):
				updateDead()

func getAvailable(atk : int)->Array:
	var availableArr = []
	print("active index = ", activeIndex )
	for elem in party:
		if (elem.index != activeIndex and !elem.dead):
			if (atk == 1):
				if (elem.atkready):
					availableArr.append(elem)
			else:
				print("elem index = ", elem.index, " appending")
				availableArr.append(elem)
	print("available members: ")
	for elem in availableArr:
		print(elem.index, " ")
	return availableArr
	
func getNext(type : int)->int:
	var avArr = getAvailable(type) # [1,2,3]
								   #  0 1 2
	var indexArr = []
	for elem in avArr:
		indexArr.append(elem.index)
	var size = indexArr.size()  #3
	if (size == 0):
		return -1
	#wwwwwwww	return indexArr[0]
	#1, 2 MOD 3 = 2 avAr[2] = 3
	var index = indexArr.find(inactiveIndex) # = 0
	print(inactiveIndex, " next is ",avArr[(index+1) % size].index)
	return avArr[(index+1) % size].index
	# 1 -> 2
	# 2 -> 3
	# 3 -> 1
	## attack will pass 0 (looking for next atkready), g will pass 1 (looking for next alive)
	##get available Arr, find your curr inactiveIndex + 1 mod avaiableArrsize . if avaialbleArrsize == 0 or 1 return
	#get next alive that is not active or dead
	#call when pressed F or G.

func updateDead()->void:
	var deadCount = 0;
	for elem in party:
		if elem.dead:
			partyImg[elem.index].visible = false
			readyIndicators[elem.index].visible = false
			HPBars[elem.index].visible = false
			partyHighlight[elem.index].visible = false
			deadCount += 1
			#party.erase(elem)
			if (elem.index == activeIndex):
				print("PARTY ", elem.index, " DEAD")
				var next = getNext(0)
				print ("SWITCHING TO, ", next)
				switchActivePlayer(next)
			#	pass
			elif (elem.index == inactiveIndex): 
				print("PARTY ", elem.index, " DEAD")
				var next = getNext(0)
				print ("SWITCHING TO, ", next)
				inactiveIndex = next
				print ("INACTIVE INDEX: ", next)

			#	pass
		#else:
			#party.insert(elem.index, elem)
	if deadCount == party.size():
		dead = true;
		get_tree().quit()
	
#endregion

#region Main Control Flow


func _process(_delta):
	#if (dragging == true):
	#	mouse_sensitivity = 0.01
	#else:
	#	mouse_sensitivity = 0.1
	if pausing_enabled:
		handle_pausing()		
	update_debug_menu_per_frame()

	if inactiveIndex != -1 and !party[inactiveIndex].dead:
		partyHighlight[inactiveIndex].visible = true
		if party[inactiveIndex].atkready:
			if partyHighlight[inactiveIndex].color != Color(0.133333, 0.545098, 0.133333, 1):
				partyHighlight[inactiveIndex].color = Color(0.133333, 0.545098, 0.133333, 1)
		else:
			if partyHighlight[inactiveIndex].color != Color(0.862745, 0.0784314, 0.235294, 1):
				partyHighlight[inactiveIndex].color = Color(0.862745, 0.0784314, 0.235294, 1)
	else:
		partyHighlight[inactiveIndex].visible = false
		
	for elem in party:
		if elem.dead:
			partyImg[elem.index].visible = false
			
		if elem.atkready and !elem.dead and elem.index != activeIndex:
			if readyIndicators[elem.index].color != Color(0.133333, 0.545098, 0.133333, 1):
				readyIndicators[elem.index].color = Color(0.133333, 0.545098, 0.133333, 1)
		else:
			if (elem.index == activeIndex):
				readyIndicators[elem.index].color = Color(1, 0.843137, 0, 1)
			elif readyIndicators[elem.index].color != Color(0.862745, 0.0784314, 0.235294, 1):
				readyIndicators[elem.index].color = Color(0.862745, 0.0784314, 0.235294, 1)


func _physics_process(delta): # Most things happen here.
	# Gravity
	if dynamic_gravity:
		gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	if not is_on_floor() and gravity and gravity_enabled:
		velocity.y -= gravity * delta

	handle_jumping()

	var input_dir = Vector2.ZERO

	if not immobile: # Immobility works by interrupting user input, so other forces can still be applied to the player
		input_dir = Input.get_vector(controls.LEFT, controls.RIGHT, controls.FORWARD, controls.BACKWARD)

	handle_movement(delta, input_dir)

	handle_head_rotation()

	# The player is not able to stand up if the ceiling is too low
	low_ceiling = $CrouchCeilingDetection.is_colliding()

	handle_state(input_dir)
	if dynamic_fov: # This may be changed to an AnimationPlayer
		update_camera_fov()

	if view_bobbing:
		play_headbob_animation(input_dir)

	if jump_animation:
		play_jump_animation()

	update_debug_menu_per_tick()

	was_on_floor = is_on_floor() # This must always be at the end of physics_process

#endregion

#region Input Handling

func handle_jumping():
	if jumping_enabled:
		if continuous_jumping: # Hold down the jump button
			if Input.is_action_pressed(controls.JUMP) and is_on_floor() and !low_ceiling:
				if jump_animation:
					JUMP_ANIMATION.play("jump", 0.25)
				velocity.y += jump_velocity # Adding instead of setting so jumping on slopes works properly
		else:
			if Input.is_action_just_pressed(controls.JUMP) and is_on_floor() and !low_ceiling:
				if jump_animation:
					JUMP_ANIMATION.play("jump", 0.25)
				velocity.y += jump_velocity


func handle_movement(delta, input_dir):
	var direction = input_dir.rotated(-HEAD.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)
	move_and_slide()

	if in_air_momentum:
		if is_on_floor():
			if motion_smoothing:
				velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
				velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
			else:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
	else:
		if motion_smoothing:
			velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
		else:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed


func handle_head_rotation():
	if invert_camera_x_axis:
		HEAD.rotation_degrees.y -= mouseInput.x * mouse_sensitivity * -1
	else:
		HEAD.rotation_degrees.y -= mouseInput.x * mouse_sensitivity 

	if invert_camera_y_axis:
		HEAD.rotation_degrees.x -= mouseInput.y * mouse_sensitivity * -1
	else:
		HEAD.rotation_degrees.x -= mouseInput.y * mouse_sensitivity

	if controller_support:
		var controller_view_rotation = Input.get_vector(controller_controls.LOOK_DOWN, controller_controls.LOOK_UP, controller_controls.LOOK_RIGHT, controller_controls.LOOK_LEFT) * look_sensitivity # These are inverted because of the nature of 3D rotation.
		if invert_camera_x_axis:
			HEAD.rotation.x += controller_view_rotation.x * -1
		else:
			HEAD.rotation.x += controller_view_rotation.x

		if invert_camera_y_axis:
			HEAD.rotation.y += controller_view_rotation.y * -1
		else:
			HEAD.rotation.y += controller_view_rotation.y

	mouseInput = Vector2(0,0)
	HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func check_controls(): # If you add a control, you might want to add a check for it here.
	# The actions are being disabled so the engine doesn't halt the entire project in debug mode
	if !InputMap.has_action(controls.JUMP):
		push_error("No control mapped for jumping. Please add an input map control. Disabling jump.")
		jumping_enabled = false
	if !InputMap.has_action(controls.LEFT):
		push_error("No control mapped for move left. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(controls.RIGHT):
		push_error("No control mapped for move right. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(controls.FORWARD):
		push_error("No control mapped for move forward. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(controls.BACKWARD):
		push_error("No control mapped for move backward. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(controls.PAUSE):
		push_error("No control mapped for pause. Please add an input map control. Disabling pausing.")
		pausing_enabled = false
	if !InputMap.has_action(controls.CROUCH):
		push_error("No control mapped for crouch. Please add an input map control. Disabling crouching.")
		crouch_enabled = false
	if !InputMap.has_action(controls.SPRINT):
		push_error("No control mapped for sprint. Please add an input map control. Disabling sprinting.")
		sprint_enabled = false

#endregion

#region State Handling

func handle_state(moving):
	if sprint_enabled:
		if sprint_mode == 0:
			if Input.is_action_pressed(controls.SPRINT) and state != "crouching":
				if moving:
					if state != "sprinting":
						enter_sprint_state()
				else:
					if state == "sprinting":
						enter_normal_state()
			elif state == "sprinting":
				enter_normal_state()
		elif sprint_mode == 1:
			if moving:
				# If the player is holding sprint before moving, handle that scenario
				if Input.is_action_pressed(controls.SPRINT) and state == "normal":
					enter_sprint_state()
				if Input.is_action_just_pressed(controls.SPRINT):
					match state:
						"normal":
							enter_sprint_state()
						"sprinting":
							enter_normal_state()
			elif state == "sprinting":
				enter_normal_state()

	if crouch_enabled:
		if crouch_mode == 0:
			if Input.is_action_pressed(controls.CROUCH) and state != "sprinting":
				if state != "crouching":
					enter_crouch_state()
			elif state == "crouching" and !$CrouchCeilingDetection.is_colliding():
				enter_normal_state()
		elif crouch_mode == 1:
			if Input.is_action_just_pressed(controls.CROUCH):
				match state:
					"normal":
						enter_crouch_state()
					"crouching":
						if !$CrouchCeilingDetection.is_colliding():
							enter_normal_state()


# Any enter state function should only be called once when you want to enter that state, not every frame.
func enter_normal_state():
	#print("entering normal state")
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "normal"
	speed = base_speed

func enter_crouch_state():
	#print("entering crouch state")
	state = "crouching"
	speed = crouch_speed
	CROUCH_ANIMATION.play("crouch")

func enter_sprint_state():
	#print("entering sprint state")
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "sprinting"
	speed = sprint_speed

#endregion

#region Animation Handling

func initialize_animations():
	# Reset the camera position
	# If you want to change the default head height, change these animations.
	HEADBOB_ANIMATION.play("RESET")
	JUMP_ANIMATION.play("RESET")
	CROUCH_ANIMATION.play("RESET")

func play_headbob_animation(moving):
	if moving and is_on_floor():
		var use_headbob_animation : String
		match state:
			"normal","crouching":
				use_headbob_animation = "walk"
			"sprinting":
				use_headbob_animation = "sprint"

		var was_playing : bool = false
		if HEADBOB_ANIMATION.current_animation == use_headbob_animation:
			was_playing = true

		HEADBOB_ANIMATION.play(use_headbob_animation, 0.25)
		HEADBOB_ANIMATION.speed_scale = (current_speed / base_speed) * 1.75
		if !was_playing:
			HEADBOB_ANIMATION.seek(float(randi() % 2)) # Randomize the initial headbob direction
			# Let me explain that piece of code because it looks like it does the opposite of what it actually does.
			# The headbob animation has two starting positions. One is at 0 and the other is at 1.
			# randi() % 2 returns either 0 or 1, and so the animation randomly starts at one of the starting positions.
			# This code is extremely performant but it makes no sense.

	else:
		if HEADBOB_ANIMATION.current_animation == "sprint" or HEADBOB_ANIMATION.current_animation == "walk":
			HEADBOB_ANIMATION.speed_scale = 1
			HEADBOB_ANIMATION.play("RESET", 1)

func play_jump_animation():
	if !was_on_floor and is_on_floor(): # The player just landed
		var facing_direction : Vector3 = CAMERA.get_global_transform().basis.x
		var facing_direction_2D : Vector2 = Vector2(facing_direction.x, facing_direction.z).normalized()
		var velocity_2D : Vector2 = Vector2(velocity.x, velocity.z).normalized()

		# Compares velocity direction against the camera direction (via dot product) to determine which landing animation to play.
		var side_landed : int = round(velocity_2D.dot(facing_direction_2D))

		if side_landed > 0:
			JUMP_ANIMATION.play("land_right", 0.25)
		elif side_landed < 0:
			JUMP_ANIMATION.play("land_left", 0.25)
		else:
			JUMP_ANIMATION.play("land_center", 0.25)

#endregion

#region Debug Menu

func update_debug_menu_per_frame():
	$UserInterface/DebugPanel.add_property("FPS", Performance.get_monitor(Performance.TIME_FPS), 0)
	var status : String = state
	if !is_on_floor():
		status += " in the air"
	$UserInterface/DebugPanel.add_property("State", status, 4)


func update_debug_menu_per_tick():
	# Big thanks to github.com/LorenzoAncora for the concept of the improved debug values
	current_speed = Vector3.ZERO.distance_to(get_real_velocity())
	$UserInterface/DebugPanel.add_property("Speed", snappedf(current_speed, 0.001), 1)
	$UserInterface/DebugPanel.add_property("Target speed", speed, 2)
	var cv : Vector3 = get_real_velocity()
	var vd : Array[float] = [
		snappedf(cv.x, 0.001),
		snappedf(cv.y, 0.001),
		snappedf(cv.z, 0.001)
	]
	var readable_velocity : String = "X: " + str(vd[0]) + " Y: " + str(vd[1]) + " Z: " + str(vd[2])
	$UserInterface/DebugPanel.add_property("Velocity", readable_velocity, 3)


#func _unhandled_input(event : InputEvent):
#	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
#		mouseInput.x += event.relative.x
#		mouseInput.y += event.relative.y
#	# Toggle debug menu
#	elif event is InputEventKey:
#		if event.is_released():
			# Where we're going, we don't need InputMap
#			if event.keycode == 4194338: # F7
#				$UserInterface/DebugPanel.visible = !$UserInterface/DebugPanel.visible

#endregion

#region Misc Functions

func change_reticle(reticle): # Yup, this function is kinda strange
	if RETICLE:
		RETICLE.queue_free()

	RETICLE = load(reticle).instantiate()
	RETICLE.character = self
	$UserInterface.add_child(RETICLE)


func update_camera_fov():
	if state == "sprinting":
		CAMERA.fov = lerp(CAMERA.fov, 80.0, 0.3)
	else:
		CAMERA.fov = lerp(CAMERA.fov, 75.0, 0.3)

func handle_pausing():
	pass;
	
	#if Input.is_action_just_pressed(controls.PAUSE):
		# You may want another node to handle pausing, because this player may get paused too.
	#	match Input.mouse_mode:
	#		Input.MOUSE_MODE_CAPTURED:
	#			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				#get_tree().paused = false
	#		Input.MOUSE_MODE_VISIBLE:
	#			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				#get_tree().paused = false

#endregion
var dirVec := Vector2.ZERO
var dragging := false
var swing_ready := true
const SWING_THRESHOLD := 20 

func start_cooldown(index: int, cool: float) -> void:
	var t := get_tree().create_timer(cool)
	party[index].atkready = false
	t.timeout.connect(func():
		party[index].atkready = true
	)
	
func _input(event):
	if event is InputEventMouseButton:
		if Input.is_action_pressed("RMB"):
			if event.pressed:
				dragging = true
				dirVec = Vector2.ZERO
				swing_ready = true
				mouse_sensitivity = 0.01
			else:
				dragging = false
				swing_ready = true
				dirVec = Vector2.ZERO

	elif event is InputEventMouseMotion:
		# Always accumulate mouse movement for mouselook when mouse is captured
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			mouseInput.x += event.relative.x
			mouseInput.y += event.relative.y

		# If dragging with RMB, accumulate drag vector for swing detection
		if dragging:
			dirVec += event.relative
			if dirVec.length() >= SWING_THRESHOLD and swing_ready:
				process_swing()
				mouse_sensitivity = 0.1
				dragging = false

	# Party switching keys
	if (Input.is_action_pressed("1")):
		switchActivePlayer(0)
	if (Input.is_action_pressed("2")):
		switchActivePlayer(1)
	if (Input.is_action_pressed("3")):
		switchActivePlayer(2)
	if (Input.is_action_pressed("4")):
		switchActivePlayer(3)
	if (Input.is_action_pressed("5")):
		pass
		
	if (Input.is_action_just_pressed("F")):
		var next = getNext(1);
		if (next == -1):
			return
		if (!party[inactiveIndex].atkready):
			if (next != -1):
				partyHighlight[inactiveIndex].hide()
				inactiveIndex = next
				#artyHighlight[inactiveIndex].show()
			return
		
		var prevIndex = inactiveIndex
		var cool = party[prevIndex].coolDown
		if (!atkArr.is_empty()):
			var location = $".".global_position
			var meleeArr = []
			for elem in atkArr:
				if (location.distance_to(elem.global_position) <= 5):
					meleeArr.append(elem)
			print(meleeArr)
			if (meleeArr.is_empty()):
				if (party[inactiveIndex].hasBow):
					var target = atkArr.pick_random()
					var aim = target.global_position + Vector3(0,1,0)
					var arrowDir = (aim - $Head/arrowOrigin.global_position).normalized()
					var arrow = arrowScene.instantiate()
					arrow.shooter = party[inactiveIndex].charName
					arrow.damage = (party[inactiveIndex].damage * party[inactiveIndex].weaponSkill/100)/2
					arrow.label = $"../UI/Info"
					get_parent().add_child(arrow)
					arrow.global_position =$Head/arrowOrigin.global_position
					arrow.set_direction(arrowDir)
					$bowsfx.stream = bowSound
					$bowsfx.play()
					cool = party[prevIndex].bowCoolDown
					
				else:
					$soundsfx.stream =  swingSound
					$soundsfx.play()
					var str = party[inactiveIndex].charName + " swings at nothing."
					$"../UI/Info".setText(str)
			else:
				var enemyTarget = meleeArr.pick_random()
				$soundsfx.stream =  swingSound
				$soundsfx.play()
				if (party[inactiveIndex].attack()):
					if (enemyTarget.has_method("hurt")):
						var ret = enemyTarget.hurt(party[inactiveIndex].charName, party[inactiveIndex].damage);
						if (!ret):
							return;
						if (!ret[0]):
							var msg = party[inactiveIndex].charName + " is blocked by " + enemyTarget.charName + " for " + str(ret[1]) + " points."
							$"../UI/Info".setText(msg)
						else:
							var msg = party[inactiveIndex].charName + " strikes " + enemyTarget.charName + " for " + str(ret[1]) + " points."
							$"../UI/Info".setText(msg)
						if (enemyTarget.HP <= 0):
							var msg = party[activeIndex].charName + " kills " + enemyTarget.charName + "."
							$"../UI/Info".setText(msg)
				else:
					var str = party[inactiveIndex].charName + " misses."
					$"../UI/Info".setText(str)
		else:
			var str = party[inactiveIndex].charName + " swings at nothing."
			$"../UI/Info".setText(str)
			$soundsfx.stream =  swingSound
			$soundsfx.play()
			
		partyHighlight[inactiveIndex].hide()
		if (next != -1):
			inactiveIndex = next;
		#wwpartyHighlight[inactiveIndex].show()

		
		print("cool: ", cool)
		if (state == "sprinting"):
			start_cooldown(prevIndex, cool*2)
		else:
			start_cooldown(prevIndex, cool)

	
	if (Input.is_action_just_pressed("G")):
		var next = getNext(0);
		if (next == -1):
			return
		partyHighlight[inactiveIndex].hide()
		inactiveIndex = next;
		partyHighlight[next].show()
		
		##STRONGLY RECOMMEND CODING A GENERIC "GET NEXT" function, that gets the next available.
		##I SUSPECT THE BEST WAY is O(n) search that checks if it is active/inactive/dead
func process_swing():
	if $Head/attacks.is_playing() and $Head/attacks.current_animation != "RESET":
		return
	swing_ready = false  # Prevent re-trigger until next swing
	var direction = dirVec.normalized()
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			$Head/attacks.play("swing_right")
			pass
		else:
			
			$Head/attacks.play("swing_left")
	else:
		if direction.y > 0:
			$Head/attacks.play("swing_down")
			
		else:
			$Head/attacks.play("swing_up")
	$soundsfx.stream =  swingSound
	$soundsfx.play()
	dirVec = Vector2.ZERO
	
func process_bounce(target: Node) ->void:
	if (target == $"."):
		return;
	else:
		$Head/attacks.speed_scale *= -1.25
		await get_tree().create_timer(0.2).timeout
		$Head/attacks.stop()
		refreshPlayer()
	
func _on_sword_collision_area_entered(area: Area3D) -> void:
	return;
	
	print("AREA COLLIDED")
	print(area)
	if $Head/attacks.is_playing() and $Head/attacks.current_animation == "swing_up":
		return
	process_bounce(area)
	

func _on_sword_collision_body_entered(body: Node3D) -> void:
	if (body == $"."):
		return;
		
	print("SWORD BODY COLLIDED")
	print(body)
	if (body.has_method("hurt")):
		#var bounce = true;
		var ret = body.hurt(party[activeIndex].charName, party[activeIndex].damage);
		if (!ret):
			return;
		var msg = ""
		if (ret[0]):
			
			msg = party[activeIndex].charName + " strikes " + body.charName + " for " + str(ret[1]) + " points."
		else:
			msg = party[activeIndex].charName + " is blocked by " + body.charName + " for " + str(ret[1]) + " points."
		if (body.HP <= 0):
			msg = party[activeIndex].charName + " kills " + body.charName + "."
		$"../UI/Info".setText(msg)
		return;
	if ($Head/attacks.is_playing() and $Head/attacks.current_animation == "swing_up") or (body == $"."):
		return
	process_bounce(body)


#func _on_indirect_range_body_entered(body: Node3D) -> void:
#	meleeRange = true

#func _on_indirect_range_body_exited(body: Node3D) -> void:
#	meleeRange = false

func _on_bow_range_body_entered(body: Node3D) -> void:
	if (body.is_in_group("Enemy") and body.alive):
		print(body, " ENTERED")
		atkArr.append(body);

func _on_bow_range_body_exited(body: Node3D) -> void:
	if (atkArr.has(body)):
		print(body, " LEFT")
		atkArr.erase(body)


func _on_attacks_animation_finished(anim_name: StringName) -> void:
	$Head/attacks.play("RESET")

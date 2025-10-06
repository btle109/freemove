extends Area3D
@export var lifetime = 3
@export var speed = 60
var messaging = true;
var label : Label 
var shooter = "Bach"
var damage = 5
var direction = Vector3.FORWARD

func _ready():
	# Start the projectile's movement and set its lifetime
	set_physics_process(true)
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.timeout.connect(queue_free) # Destroy after lifetime
	add_child(timer)
	timer.start()

func _physics_process(delta):
	# Move the projectile in its direction
	global_translate(direction * speed * delta)

func set_direction(new_direction):
	direction = new_direction.normalized()
	look_at(global_transform.origin + direction, Vector3.UP)
func _on_body_entered(body):
	# Handle collision with other bodies (e.g., damage, destroy)
	print("ARROW STRIKES: ", body.name)
	var stri = shooter
	if (body.has_method("block")):
		print ("BODY CAN BLOCK")
		if (randi()%100 + 1 <= 65):
			print ("BODY CAN BLOCK")
			stri += " is blocked entirely by "
			stri += body.charName 
			stri += "."
			body.block()
			if (messaging):
				label.setText(stri)
			queue_free()
			return
		else:
			pass
	if (body.has_method("hurt")):
		var ret = body.hurt(shooter, damage)
		if (!ret):
			queue_free()
			return
		stri += " shoots "
		stri += body.charName 
		stri += " for "
		stri += str(ret[1])
		stri += " points."
	else:
		stri += "nothing."
	if (messaging):
		label.setText(stri)
	queue_free()

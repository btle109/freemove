extends Area3D
@export var lifetime = 3
@export var speed = 60
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
	if (body.has_method("hurt")):
		body.hurt(damage)
	queue_free()

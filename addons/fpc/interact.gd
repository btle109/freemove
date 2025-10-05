extends Camera3D
var mouse = Vector2()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse = event.position
	elif event is InputEventMouseButton and event.pressed:
		mouse = event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			get_selection()

func get_selection() -> void:
	if mouse == Vector2.ZERO:
		return

	var space_state = get_world_3d().direct_space_state
	var start = project_ray_origin(mouse)
	var end = project_position(mouse, 4)

	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = start
	ray_params.to = end
	ray_params.collide_with_areas = true
	ray_params.collide_with_bodies = true
	ray_params.collision_mask = 1 << 1 
	
	var result = space_state.intersect_ray(ray_params)
	print(result)

	if result and result.collider and result.collider.has_method("use"):
		var res = result.collider.use()
		if (res):
			if (res == 1):
				$"../..".heal(4, 999)

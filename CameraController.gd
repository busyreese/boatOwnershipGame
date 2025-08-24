# CameraController.gd - Handles camera movement and zoom
extends Camera3D

var current_fov: float = 55.0
var target_fov: float = 55.0
var camera_min_fov: float = 28.0
var camera_max_fov: float = 70.0
var camera_zoom_speed: float = 1.05

func _ready():
	position = Vector3(0, 12, 25)
	rotation_degrees = Vector3(-20, 0, 0)
	fov = 55
	near = 0.1
	far = 500
	
	# Load saved FOV
	if has_node("/root/SaveManager"):
		var save_mgr = get_node("/root/SaveManager")
		current_fov = save_mgr.get_meta("camera_fov", 55.0)
		target_fov = current_fov
		fov = current_fov

func _input(event):
	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_fov = clamp(target_fov / camera_zoom_speed, camera_min_fov, camera_max_fov)
			save_camera_fov()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_fov = clamp(target_fov * camera_zoom_speed, camera_min_fov, camera_max_fov)
			save_camera_fov()
	
	# Pinch gesture zoom
	elif event is InputEventMagnifyGesture:
		var factor = event.factor
		target_fov = clamp(target_fov / factor, camera_min_fov, camera_max_fov)
		save_camera_fov()

func _process(delta):
	# Smooth zoom
	if abs(current_fov - target_fov) > 0.1:
		current_fov = lerp(current_fov, target_fov, delta * 8.0)
		fov = current_fov

func save_camera_fov():
	if has_node("/root/SaveManager"):
		var save_mgr = get_node("/root/SaveManager")
		save_mgr.set_meta("camera_fov", target_fov)
		save_mgr.save_game()

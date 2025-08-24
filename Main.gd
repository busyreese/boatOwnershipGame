# Main.gd - Main orchestrator for the boat idle game
extends Node3D

# Core systems
var camera_controller: Camera3D
var environment_3d: Node3D
var ui_manager: CanvasLayer
var boat_manager: Node3D
var water_physics: Node

# Animation
var wave_time: float = 0.0

func _ready():
	print("=== MAIN ORCHESTRATOR STARTING ===")
	
	# Initialize water physics
	water_physics = preload("res://WaterPhysics.gd").new()
	add_child(water_physics)
	
	# Setup camera
	camera_controller = preload("res://CameraController.gd").new()
	add_child(camera_controller)
	
	# Setup environment
		# Check if the file exists and load it properly
	var env_script_path = "res://Environment3D.gd"
	if not ResourceLoader.exists(env_script_path):
		push_error("Environment3D.gd not found at: " + env_script_path)
		return
	var EnvironmentScript = load(env_script_path)
	environment_3d = EnvironmentScript.new()
	environment_3d.setup_environment(camera_controller)
	environment_3d.setup_ocean(water_physics)
	environment_3d.setup_underwater_life()
	environment_3d.setup_coastal_town()
	add_child(environment_3d)
	
	# Setup boats
	var BoatManagerScript = preload("res://BoatManager.gd")
	boat_manager = BoatManagerScript.new()
	boat_manager.set_water_physics(water_physics)
	add_child(boat_manager)
	
	# Setup UI
	var UIManagerScript = preload("res://UIManager.gd")
	ui_manager = UIManagerScript.new()
	ui_manager.setup_ui()
	ui_manager.boat_models = boat_manager.boat_models
	add_child(ui_manager)
	
	# Connect UI signals
	ui_manager.cruise_requested.connect(_on_cruise_requested)
	ui_manager.work_requested.connect(_on_work_requested)
	ui_manager.shop_requested.connect(_on_shop_requested)
	ui_manager.mooring_requested.connect(_on_mooring_requested)
	ui_manager.brokerage_requested.connect(_on_brokerage_requested)
	ui_manager.settings_requested.connect(_on_settings_requested)
	
	# Connect GameManager signals
	if GameManager:
		GameManager.money_changed.connect(_on_money_changed)
		GameManager.boat_condition_changed.connect(_on_condition_changed)
		GameManager.day_passed.connect(_on_day_passed)
		GameManager.work_completed.connect(_on_work_completed)
		GameManager.boat_changed.connect(_on_boat_changed)
		GameManager.time_tick.connect(_on_time_tick)
		GameManager.cruise_started.connect(_on_cruise_started)
		GameManager.cruise_completed.connect(_on_cruise_completed)
		GameManager.rental_started.connect(_on_rental_started)
		GameManager.rental_ended.connect(_on_rental_ended)
	
	# Initial updates
	boat_manager.update_boat_display()
	ui_manager.update_ui()
	
	# Show zoom tip if needed
	check_zoom_tip()

func _process(delta):
	wave_time += delta
	
	# Animate environment
	if environment_3d:
		environment_3d.animate_underwater_life(delta, wave_time)
	
	# Animate boats
	if boat_manager:
		boat_manager.animate_boats(delta, wave_time)
	
	# Update UI
	if ui_manager:
		ui_manager.update_ui()
		
		# Update debug overlay if visible
		if ui_manager.debug_overlay and ui_manager.debug_overlay.visible:
			update_debug_info()

func check_zoom_tip():
	if has_node("/root/SaveManager"):
		var save_mgr = get_node("/root/SaveManager")
		var zoom_tip_shown = save_mgr.get_meta("zoom_tip_shown", false)
		if not zoom_tip_shown:
			ui_manager.show_zoom_tip()

func update_debug_info():
	if not GameManager.current_boat in boat_manager.boat_containers:
		return
	
	var boat = boat_manager.boat_containers[GameManager.current_boat]
	if not boat:
		return
	
	var boat_y = boat.position.y
	var water_y = -0.2
	if water_physics:
		water_y += water_physics.get_water_height_at(boat.global_position, wave_time)
	
	ui_manager.update_debug_overlay(boat_y, water_y, 
									boat_manager.boat_draft, 
									boat_manager.boat_bob_strength)

# UI request handlers
func _on_cruise_requested():
	ui_manager.show_cruise_routes()

func _on_work_requested():
	ui_manager.show_work_menu()

func _on_shop_requested():
	ui_manager.show_upgrade_shop()

func _on_mooring_requested():
	ui_manager.handle_mooring_purchase()

func _on_brokerage_requested():
	ui_manager.show_brokerage()

func _on_settings_requested():
	ui_manager.show_settings()
	# Connect settings changes
	if ui_manager.settings_panel and ui_manager.settings_panel.has_signal("settings_changed"):
		ui_manager.settings_panel.settings_changed.connect(_on_settings_changed)

func _on_settings_changed():
	# Update boat physics from settings
	if ui_manager.settings_panel:
		boat_manager.boat_bob_strength = ui_manager.settings_panel.get_boat_bob_strength()
		boat_manager.boat_draft = ui_manager.settings_panel.get_boat_draft()
		
		var show_debug = ui_manager.settings_panel.should_show_debug_overlay()
		ui_manager.set_debug_overlay_visible(show_debug)

# GameManager signal handlers
func _on_money_changed(_amount):
	ui_manager.update_ui()

func _on_condition_changed(_condition):
	ui_manager.update_ui()

func _on_day_passed():
	ui_manager.update_ui()

func _on_work_completed():
	ui_manager.update_ui()

func _on_boat_changed(_boat_name):
	ui_manager.update_ui()
	boat_manager.update_boat_display()

func _on_time_tick(hour: int, minute: int):
	ui_manager.update_time(hour, minute)

func _on_cruise_started(route_name: String = ""):
	# If route_name not provided, try to get it from GameManager
	if route_name == "" and GameManager.current_cruise_route:
		route_name = "Standard Route"  # Default fallback
	
	if route_name == "":
		route_name = "Standard Route"
	
	boat_manager.start_cruise(route_name)
	ui_manager.update_ui()

func _on_cruise_completed():
	boat_manager.end_cruise()
	ui_manager.update_ui()
	
func _on_rental_started(_boat_name):
	boat_manager.update_boat_display()
	ui_manager.update_ui()



func _on_rental_ended(_boat_name):
	boat_manager.update_boat_display()

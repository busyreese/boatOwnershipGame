# SaveManager.gd - Enhanced with manual save button and 5-minute autosave
extends Node

const SAVE_FILE = "user://savegame.json"
const SAVE_VERSION = 1
const AUTOSAVE_INTERVAL = 300.0  # 5 minutes in seconds

var save_data = {}
var is_saving = false
var save_timer: Timer
var autosave_timer: Timer
var last_save_time: float = 0.0

signal save_completed
signal load_completed
signal autosave_triggered

func _ready():
	# Setup debounce timer for manual saves
	save_timer = Timer.new()
	save_timer.wait_time = 5.0  # Debounce saves every 5 seconds max
	save_timer.one_shot = true
	save_timer.timeout.connect(_perform_save)
	add_child(save_timer)
	
	# Setup autosave timer (5 minutes)
	autosave_timer = Timer.new()
	autosave_timer.wait_time = AUTOSAVE_INTERVAL
	autosave_timer.one_shot = false
	autosave_timer.timeout.connect(_perform_autosave)
	add_child(autosave_timer)
	autosave_timer.start()
	
	# Handle app close
	get_tree().auto_accept_quit = false
	
	# Load on startup
	load_game()
	
	print("SaveManager ready - Autosave every 5 minutes enabled")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game_immediate()
		get_tree().quit()

func _perform_autosave():
	print("Autosave triggered (5 minute interval)")
	save_game_immediate()
	autosave_triggered.emit()

func manual_save():
	print("Manual save requested")
	save_game_immediate()
	return true

func get_time_since_last_save() -> String:
	var current_time = Time.get_unix_time_from_system()
	var time_diff = current_time - last_save_time
	
	if time_diff < 60:
		return "%d seconds ago" % int(time_diff)
	elif time_diff < 3600:
		return "%d minutes ago" % int(time_diff / 60)
	else:
		return "%d hours ago" % int(time_diff / 3600)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE)

func save_game(immediate: bool = false):
	if immediate:
		save_game_immediate()
	else:
		# Debounced save
		if not is_saving:
			save_timer.start()

func save_game_immediate():
	is_saving = true
	last_save_time = Time.get_unix_time_from_system()
	
	# Gather all game state
	save_data = {
		"save_version": SAVE_VERSION,
		"timestamp": last_save_time,
		
		# Core game state
		"money": GameManager.money,
		"current_day": GameManager.current_day,
		"days_since_cruise": GameManager.days_since_cruise,
		"current_boat": GameManager.current_boat,
		"owned_boats": GameManager.owned_boats,
		"boat_upgrades": GameManager.boat_upgrades,
		
		# Boat conditions
		"boat_conditions": GameManager.boat_conditions,
		"boats_for_sale": GameManager.boats_for_sale,
		
		# Mooring and rentals
		"has_monthly_mooring": GameManager.has_monthly_mooring,
		"mooring_days_left": GameManager.mooring_days_left,
		"boat_rentals": GameManager.boat_rentals,
		
		# Mechanic
		"has_mechanic": GameManager.has_mechanic,
		
		# Time
		"current_hour": GameManager.current_hour,
		"current_minute": GameManager.current_minute,
		
		# UI state
		"zoom_tip_shown": get_meta("zoom_tip_shown", false),
		"camera_fov": get_meta("camera_fov", 55.0),
		
		# Settings
		"boat_bob_strength": get_meta("boat_bob_strength", 0.15),
		"boat_draft": get_meta("boat_draft", 0.35),
		"show_debug_overlay": get_meta("show_debug_overlay", false),
		"sound_volume": get_meta("sound_volume", 1.0),
		"music_volume": get_meta("music_volume", 0.5)
	}
	
	# Write to file
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Game saved successfully at ", Time.get_datetime_string_from_system())
	else:
		push_error("Failed to save game")
	
	is_saving = false
	save_completed.emit()

func load_game() -> bool:
	if not has_save():
		print("No save file found")
		return false
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		push_error("Failed to open save file")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse save file")
		return false
	
	save_data = json.data
	
	# Update last save time
	if save_data.has("timestamp"):
		last_save_time = save_data.timestamp
	
	# Check version and migrate if needed
	var version = save_data.get("save_version", 0)
	if version != SAVE_VERSION:
		_migrate_save(version)
	
	# Apply loaded data to GameManager
	if save_data.has("money"):
		GameManager.money = save_data.money
	if save_data.has("current_day"):
		GameManager.current_day = save_data.current_day
	if save_data.has("days_since_cruise"):
		GameManager.days_since_cruise = save_data.days_since_cruise
	if save_data.has("current_boat"):
		GameManager.current_boat = save_data.current_boat
	if save_data.has("owned_boats"):
		GameManager.owned_boats = save_data.owned_boats
	if save_data.has("boat_upgrades"):
		GameManager.boat_upgrades = save_data.boat_upgrades
	
	# Boat conditions
	if save_data.has("boat_conditions"):
		GameManager.boat_conditions = save_data.boat_conditions
	if save_data.has("boats_for_sale"):
		GameManager.boats_for_sale = save_data.boats_for_sale
	
	# Mooring and rentals
	if save_data.has("has_monthly_mooring"):
		GameManager.has_monthly_mooring = save_data.has_monthly_mooring
	if save_data.has("mooring_days_left"):
		GameManager.mooring_days_left = save_data.mooring_days_left
	if save_data.has("boat_rentals"):
		GameManager.boat_rentals = save_data.boat_rentals
	
	# Mechanic
	if save_data.has("has_mechanic"):
		GameManager.has_mechanic = save_data.has_mechanic
	
	# Time
	if save_data.has("current_hour"):
		GameManager.current_hour = save_data.current_hour
	if save_data.has("current_minute"):
		GameManager.current_minute = save_data.current_minute
	
	# Store UI state as metadata
	set_meta("zoom_tip_shown", save_data.get("zoom_tip_shown", false))
	set_meta("camera_fov", save_data.get("camera_fov", 55.0))
	
	# Settings
	set_meta("boat_bob_strength", save_data.get("boat_bob_strength", 0.15))
	set_meta("boat_draft", save_data.get("boat_draft", 0.35))
	set_meta("show_debug_overlay", save_data.get("show_debug_overlay", false))
	set_meta("sound_volume", save_data.get("sound_volume", 1.0))
	set_meta("music_volume", save_data.get("music_volume", 0.5))
	
	print("Game loaded successfully")
	load_completed.emit()
	return true

func _perform_save():
	save_game_immediate()

func _migrate_save(from_version: int):
	print("Migrating save from version %d to %d" % [from_version, SAVE_VERSION])
	# Add migration logic here as needed
	save_data["save_version"] = SAVE_VERSION

func reset_save():
	if FileAccess.file_exists(SAVE_FILE):
		var dir = DirAccess.open("user://")
		dir.remove(SAVE_FILE)
		print("Save file deleted")
	
	# Reset all game state to defaults
	GameManager.money = 100.0
	GameManager.current_day = 1
	GameManager.days_since_cruise = 0
	GameManager.current_boat = "Old Rowboat"
	GameManager.owned_boats = ["Old Rowboat"]
	GameManager.boat_upgrades = []
	GameManager.boat_conditions.clear()
	GameManager.initialize_boat_conditions()
	GameManager.boats_for_sale.clear()
	GameManager.generate_boats_for_sale()
	GameManager.has_monthly_mooring = false
	GameManager.mooring_days_left = 0
	GameManager.boat_rentals.clear()
	GameManager.has_mechanic = false
	GameManager.current_hour = 6
	GameManager.current_minute = 0
	
	# Reset metadata
	set_meta("zoom_tip_shown", false)
	set_meta("camera_fov", 55.0)
	set_meta("boat_bob_strength", 0.15)
	set_meta("boat_draft", 0.35)
	set_meta("show_debug_overlay", false)
	
	# Reset last save time
	last_save_time = 0.0
	
	print("Game reset to defaults")

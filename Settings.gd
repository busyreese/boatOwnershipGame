# Settings.gd - Enhanced settings panel with new controls
extends Panel

# UI References
@onready var sound_slider = $VBoxContainer/SoundVolume
@onready var music_slider = $VBoxContainer/MusicVolume
@onready var bob_strength_slider = $VBoxContainer/BobStrength
@onready var boat_draft_slider = $VBoxContainer/BoatDraft
@onready var debug_overlay_check = $VBoxContainer/DebugOverlay
@onready var reset_save_button = $VBoxContainer/ResetSave
@onready var close_button = $VBoxContainer/CloseButton

# Camera zoom settings
var camera_min_fov: float = 28.0
var camera_max_fov: float = 70.0
var camera_zoom_speed: float = 1.05

# Boat physics settings
var boat_bob_strength: float = 0.15
var boat_draft: float = 0.35  # How high boats sit above water

# Debug settings
var show_debug_overlay: bool = false

signal settings_changed

func _ready():
	hide()
	setup_ui()
	load_settings()

func setup_ui():
	# Create UI if it doesn't exist
	if not has_node("VBoxContainer"):
		var vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.position = Vector2(20, 20)
		vbox.size = Vector2(360, 400)
		add_child(vbox)
		
		# Title
		var title = Label.new()
		title.text = "⚙️ Settings"
		title.add_theme_font_size_override("font_size", 18)
		vbox.add_child(title)
		
		vbox.add_child(HSeparator.new())
		
		# Sound Volume
		var sound_label = Label.new()
		sound_label.text = "Sound Volume"
		vbox.add_child(sound_label)
		
		sound_slider = HSlider.new()
		sound_slider.name = "SoundVolume"
		sound_slider.min_value = 0
		sound_slider.max_value = 100
		sound_slider.value = 100
		sound_slider.value_changed.connect(_on_sound_volume_changed)
		vbox.add_child(sound_slider)
		
		# Music Volume
		var music_label = Label.new()
		music_label.text = "Music Volume"
		vbox.add_child(music_label)
		
		music_slider = HSlider.new()
		music_slider.name = "MusicVolume"
		music_slider.min_value = 0
		music_slider.max_value = 100
		music_slider.value = 50
		music_slider.value_changed.connect(_on_music_volume_changed)
		vbox.add_child(music_slider)
		
		vbox.add_child(HSeparator.new())
		
		# Boat Bob Strength
		var bob_label = Label.new()
		bob_label.text = "Boat Bobbing Strength"
		vbox.add_child(bob_label)
		
		bob_strength_slider = HSlider.new()
		bob_strength_slider.name = "BobStrength"
		bob_strength_slider.min_value = 5
		bob_strength_slider.max_value = 30
		bob_strength_slider.value = 15
		bob_strength_slider.value_changed.connect(_on_bob_strength_changed)
		vbox.add_child(bob_strength_slider)
		
		# Boat Draft
		var draft_label = Label.new()
		draft_label.text = "Boat Draft (height above water)"
		vbox.add_child(draft_label)
		
		boat_draft_slider = HSlider.new()
		boat_draft_slider.name = "BoatDraft"
		boat_draft_slider.min_value = 10
		boat_draft_slider.max_value = 60
		boat_draft_slider.value = 35
		boat_draft_slider.value_changed.connect(_on_boat_draft_changed)
		vbox.add_child(boat_draft_slider)
		
		vbox.add_child(HSeparator.new())
		
		# Debug Overlay
		debug_overlay_check = CheckBox.new()
		debug_overlay_check.name = "DebugOverlay"
		debug_overlay_check.text = "Show Debug Overlay (boat/water heights)"
		debug_overlay_check.toggled.connect(_on_debug_overlay_toggled)
		vbox.add_child(debug_overlay_check)
		
		vbox.add_child(HSeparator.new())
		
		# Reset Save button
		reset_save_button = Button.new()
		reset_save_button.name = "ResetSave"
		reset_save_button.text = "🗑️ Reset Save Data"
		reset_save_button.modulate = Color(1, 0.5, 0.5)
		reset_save_button.pressed.connect(_on_reset_save_pressed)
		vbox.add_child(reset_save_button)
		
		# Close button
		close_button = Button.new()
		close_button.name = "CloseButton"
		close_button.text = "Close Settings"
		close_button.pressed.connect(hide)
		vbox.add_child(close_button)

func load_settings():
	# Load from SaveManager metadata if available
	if has_node("/root/SaveManager"):
		var save_mgr = get_node("/root/SaveManager")
		
		boat_bob_strength = save_mgr.get_meta("boat_bob_strength", 0.15)
		boat_draft = save_mgr.get_meta("boat_draft", 0.35)
		show_debug_overlay = save_mgr.get_meta("show_debug_overlay", false)
		
		var sound_vol = save_mgr.get_meta("sound_volume", 1.0)
		var music_vol = save_mgr.get_meta("music_volume", 0.5)
		
		if sound_slider:
			sound_slider.value = sound_vol * 100
		if music_slider:
			music_slider.value = music_vol * 100
		if bob_strength_slider:
			bob_strength_slider.value = boat_bob_strength * 100
		if boat_draft_slider:
			boat_draft_slider.value = boat_draft * 100
		if debug_overlay_check:
			debug_overlay_check.set_pressed(show_debug_overlay)

func save_settings():
	if has_node("/root/SaveManager"):
		var save_mgr = get_node("/root/SaveManager")
		save_mgr.set_meta("boat_bob_strength", boat_bob_strength)
		save_mgr.set_meta("boat_draft", boat_draft)
		save_mgr.set_meta("show_debug_overlay", show_debug_overlay)
		save_mgr.set_meta("sound_volume", sound_slider.value / 100.0 if sound_slider else 1.0)
		save_mgr.set_meta("music_volume", music_slider.value / 100.0 if music_slider else 0.5)
		
		# Trigger a save
		save_mgr.save_game()

func _on_sound_volume_changed(value):
	if AudioManager:
		AudioManager.set_sound_volume(value / 100.0)
	save_settings()

func _on_music_volume_changed(value):
	if AudioManager:
		AudioManager.set_music_volume(value / 100.0)
	save_settings()

func _on_bob_strength_changed(value):
	boat_bob_strength = value / 100.0
	save_settings()
	settings_changed.emit()

func _on_boat_draft_changed(value):
	boat_draft = value / 100.0
	save_settings()
	settings_changed.emit()

func _on_debug_overlay_toggled(pressed):
	show_debug_overlay = pressed
	save_settings()
	settings_changed.emit()

func _on_reset_save_pressed():
	# Show confirmation dialog
	var confirm = ConfirmationDialog.new()
	confirm.title = "Reset Save Data"
	confirm.dialog_text = "Are you sure you want to reset all progress?\nThis cannot be undone!"
	confirm.confirmed.connect(func():
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").reset_save()
			get_tree().reload_current_scene()
	)
	get_parent().add_child(confirm)
	confirm.popup_centered()

func show_settings():
	show()

func get_boat_bob_strength() -> float:
	return boat_bob_strength

func get_boat_draft() -> float:
	return boat_draft

func should_show_debug_overlay() -> bool:
	return show_debug_overlay

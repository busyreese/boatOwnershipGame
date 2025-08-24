# UIManager.gd - Handles all UI elements and dialogs
extends CanvasLayer

# UI references
var ui_panel: Panel
var money_label: Label
var day_label: Label
var clock_label: Label
var warning_label: Label
var condition_label: Label
var condition_bar: ProgressBar
var cruise_button: Button
var work_button: Button
var shop_button: Button
var mooring_button: Button
var brokerage_button: Button
var settings_button: Button
var save_button: Button
var save_status_label: Label
var status_label: Label

# Debug overlay
var debug_overlay: Control
var debug_label: Label

# Dialog systems
var upgrade_shop = null
var ship_brokerage = null
var settings_panel: Panel

# Reference to boat models for brokerage
var boat_models = {}

signal cruise_requested
signal work_requested
signal shop_requested
signal mooring_requested
signal brokerage_requested
signal settings_requested

func setup_ui():
	setup_main_panel()
	setup_time_display()
	setup_debug_overlay()

func setup_main_panel():
	var main_container = Control.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)
	
	# Semi-transparent background panel
	ui_panel = Panel.new()
	ui_panel.modulate = Color(0.1, 0.1, 0.1, 0.7)
	ui_panel.position = Vector2(30, 30)
	ui_panel.size = Vector2(450, 720)  # Increased height for save button
	main_container.add_child(ui_panel)
	
	# Left panel
	var left_panel = VBoxContainer.new()
	left_panel.position = Vector2(50, 50)
	left_panel.custom_minimum_size = Vector2(400, 650)
	main_container.add_child(left_panel)
	
	# Money display
	money_label = Label.new()
	money_label.text = "Money: $100"
	money_label.add_theme_font_size_override("font_size", 18)
	money_label.add_theme_color_override("font_color", Color(1, 1, 1))
	money_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	left_panel.add_child(money_label)
	
	# Day display
	day_label = Label.new()
	day_label.text = "Day 1"
	day_label.add_theme_color_override("font_color", Color(1, 1, 1))
	day_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	left_panel.add_child(day_label)
	
	left_panel.add_child(HSeparator.new())
	
	# Boat condition
	condition_label = Label.new()
	condition_label.text = "Boat Condition: 50%"
	condition_label.add_theme_color_override("font_color", Color(1, 1, 1))
	condition_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	left_panel.add_child(condition_label)
	
	condition_bar = ProgressBar.new()
	condition_bar.value = 50
	left_panel.add_child(condition_bar)
	
	left_panel.add_child(HSeparator.new())
	
	# Action buttons
	cruise_button = Button.new()
	cruise_button.text = "🚤 Take Cruise"
	cruise_button.pressed.connect(_on_cruise_pressed)
	left_panel.add_child(cruise_button)
	
	work_button = Button.new()
	work_button.text = "🔧 Work on Boat"
	work_button.pressed.connect(_on_work_pressed)
	left_panel.add_child(work_button)
	
	shop_button = Button.new()
	shop_button.text = "⚓ Upgrade Shop"
	shop_button.pressed.connect(_on_shop_pressed)
	left_panel.add_child(shop_button)
	
	mooring_button = Button.new()
	mooring_button.text = "⚓ Buy Monthly Mooring ($500)"
	mooring_button.pressed.connect(_on_mooring_pressed)
	left_panel.add_child(mooring_button)
	
	brokerage_button = Button.new()
	brokerage_button.text = "⛵ Ship Brokerage"
	brokerage_button.pressed.connect(_on_brokerage_pressed)
	left_panel.add_child(brokerage_button)
	
	settings_button = Button.new()
	settings_button.text = "⚙️ Settings"
	settings_button.pressed.connect(_on_settings_pressed)
	left_panel.add_child(settings_button)
	
	left_panel.add_child(HSeparator.new())
	
	# Save button and status
	var save_hbox = HBoxContainer.new()
	
	save_button = Button.new()
	save_button.text = "💾 Save Game"
	save_button.modulate = Color(0.7, 1.0, 0.7)  # Light green tint
	save_button.pressed.connect(_on_save_pressed)
	save_hbox.add_child(save_button)
	
	save_status_label = Label.new()
	save_status_label.text = ""
	save_status_label.add_theme_font_size_override("font_size", 11)
	save_status_label.modulate = Color(0.8, 0.8, 0.8)
	save_hbox.add_child(save_status_label)
	
	left_panel.add_child(save_hbox)
	
	left_panel.add_child(HSeparator.new())
	
	# Status label
	status_label = Label.new()
	status_label.text = "Ready to sail!"
	status_label.modulate = Color.GREEN
	left_panel.add_child(status_label)
	
	# Connect to SaveManager for autosave notifications
	if has_node("/root/SaveManager"):
		var save_mgr = get_node("/root/SaveManager")
		save_mgr.autosave_triggered.connect(_on_autosave)
		save_mgr.save_completed.connect(_on_save_completed)

func setup_time_display():
	var main_container = get_child(0)
	
	var time_panel = Panel.new()
	time_panel.modulate = Color(0.1, 0.2, 0.3, 0.9)
	time_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	time_panel.position = Vector2(-220, 10)
	time_panel.size = Vector2(200, 80)
	main_container.add_child(time_panel)
	
	var time_vbox = VBoxContainer.new()
	time_vbox.position = Vector2(10, 5)
	time_panel.add_child(time_vbox)
	
	clock_label = Label.new()
	clock_label.add_theme_font_size_override("font_size", 18)
	clock_label.add_theme_color_override("font_color", Color.WHITE)
	time_vbox.add_child(clock_label)
	
	warning_label = Label.new()
	warning_label.add_theme_font_size_override("font_size", 12)
	warning_label.modulate = Color.YELLOW
	time_vbox.add_child(warning_label)

func setup_debug_overlay():
	debug_overlay = Control.new()
	debug_overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)
	debug_overlay.position = Vector2(10, 100)
	debug_overlay.size = Vector2(400, 200)
	debug_overlay.visible = false
	
	var panel = Panel.new()
	panel.modulate = Color(0, 0, 0, 0.7)
	panel.size = Vector2(400, 150)
	debug_overlay.add_child(panel)
	
	debug_label = Label.new()
	debug_label.position = Vector2(10, 10)
	debug_label.add_theme_font_size_override("font_size", 12)
	debug_label.add_theme_color_override("font_color", Color.GREEN)
	debug_overlay.add_child(debug_label)
	
	add_child(debug_overlay)

func update_ui():
	if money_label and GameManager:
		money_label.text = "Money: $%.2f" % GameManager.money
	
	if day_label and GameManager:
		day_label.text = "Day %d | Last cruise: %d days ago" % [GameManager.current_day, GameManager.days_since_cruise]
	
	if condition_label and GameManager:
		var condition = GameManager.get_current_boat_condition()
		condition_label.text = "Boat: %s | Condition: %d%%" % [GameManager.current_boat, condition.overall]
	
	if condition_bar and GameManager:
		var condition = GameManager.get_current_boat_condition()
		condition_bar.value = condition.overall
	
	if status_label and GameManager:
		if GameManager.is_working:
			status_label.text = "⚙️ Working... %.1fs" % GameManager.work_timer
		elif GameManager.is_cruising:
			var progress = GameManager.get_cruise_progress() * 100
			status_label.text = "🚤 Cruising... %.0f%%" % progress
		else:
			status_label.text = "✅ Ready to sail!"
	
	if warning_label and GameManager:
		var hours = GameManager.get_hours_until_fine()
		if hours <= 24 and not GameManager.has_monthly_mooring:
			warning_label.text = "⚠️ Fine in %.1f hours!" % hours
			warning_label.visible = true
		else:
			warning_label.visible = false
	
	# Update save status
	if save_status_label and has_node("/root/SaveManager"):
		var save_mgr = get_node("/root/SaveManager")
		save_status_label.text = "Last save: " + save_mgr.get_time_since_last_save()

func update_time(hour: int, minute: int):
	if clock_label:
		clock_label.text = "🕐 %02d:%02d" % [hour, minute]

func update_debug_overlay(boat_y: float, water_y: float, boat_draft: float, bob_strength: float):
	if not debug_label:
		return
	
	var delta_y = boat_y - water_y
	
	var debug_text = "=== Boat Physics Debug ===\n"
	debug_text += "Boat Y: %.3f\n" % boat_y
	debug_text += "Water Y: %.3f\n" % water_y
	debug_text += "Delta (boat - water): %.3f\n" % delta_y
	debug_text += "Draft setting: %.3f\n" % boat_draft
	debug_text += "Bob strength: %.3f\n" % bob_strength
	debug_text += "Min clearance: %.3f" % (delta_y - boat_draft)
	
	if delta_y < boat_draft:
		debug_text += "\n⚠️ BOAT TOO LOW!"
		debug_label.modulate = Color.RED
	else:
		debug_label.modulate = Color.GREEN
	
	debug_label.text = debug_text

func set_debug_overlay_visible(visible: bool):
	if debug_overlay:
		debug_overlay.visible = visible

func show_zoom_tip():
	var tip = AcceptDialog.new()
	tip.title = "📸 Camera Controls"
	tip.dialog_text = "Zoom with mouse wheel or pinch gesture!\nEnjoy exploring your marina."
	tip.size = Vector2(400, 150)
	
	tip.confirmed.connect(func():
		if has_node("/root/SaveManager"):
			var save_mgr = get_node("/root/SaveManager")
			save_mgr.set_meta("zoom_tip_shown", true)
			save_mgr.save_game()
	)
	
	add_child(tip)
	tip.popup_centered()
	
	# Auto-dismiss after 4 seconds
	var timer = Timer.new()
	timer.wait_time = 4.0
	timer.one_shot = true
	timer.timeout.connect(func():
		if is_instance_valid(tip):
			tip.queue_free()
		if has_node("/root/SaveManager"):
			var save_mgr = get_node("/root/SaveManager")
			save_mgr.set_meta("zoom_tip_shown", true)
			save_mgr.save_game()
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

# Button handlers
func _on_cruise_pressed():
	cruise_requested.emit()

func _on_work_pressed():
	work_requested.emit()

func _on_shop_pressed():
	shop_requested.emit()

func _on_mooring_pressed():
	mooring_requested.emit()

func _on_brokerage_pressed():
	brokerage_requested.emit()

func _on_settings_pressed():
	settings_requested.emit()

func _on_save_pressed():
	if has_node("/root/SaveManager"):
		var save_mgr = get_node("/root/SaveManager")
		if save_mgr.manual_save():
			status_label.text = "✅ Game saved!"
			status_label.modulate = Color.GREEN

func _on_autosave():
	if status_label:
		status_label.text = "💾 Autosaving..."
		status_label.modulate = Color.YELLOW

func _on_save_completed():
	if status_label:
		# Only update if it was an autosave message
		if status_label.text == "💾 Autosaving...":
			status_label.text = "✅ Autosave complete!"
			status_label.modulate = Color.GREEN
			
			# Reset status after 2 seconds
			var timer = Timer.new()
			timer.wait_time = 2.0
			timer.one_shot = true
			timer.timeout.connect(func():
				status_label.text = "✅ Ready to sail!"
				timer.queue_free()
			)
			add_child(timer)
			timer.start()

# Dialog functions (moved from Main.gd)
func show_cruise_routes():
	if GameManager.is_cruising or GameManager.is_working:
		return
	
	var dialog = AcceptDialog.new()
	dialog.title = "🚤 Select Cruise Route"
	dialog.size = Vector2(600, 500)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	
	var title = Label.new()
	title.text = "Choose your cruise route:"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	for route_name in GameManager.cruise_routes:
		var route = GameManager.cruise_routes[route_name]
		
		if not GameManager.can_take_route(route_name):
			continue
		
		var route_panel = Panel.new()
		route_panel.custom_minimum_size = Vector2(550, 100)
		
		var route_container = MarginContainer.new()
		route_container.add_theme_constant_override("margin_left", 15)
		route_container.add_theme_constant_override("margin_right", 15)
		route_container.add_theme_constant_override("margin_top", 10)
		route_container.add_theme_constant_override("margin_bottom", 10)
		
		var route_vbox = VBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = route_name
		name_label.add_theme_font_size_override("font_size", 14)
		route_vbox.add_child(name_label)
		
		var desc_label = Label.new()
		var income = GameManager.calculate_cruise_income() * route.income_multiplier
		var duration = GameManager.get_cruise_duration(route_name)
		desc_label.text = "%s | Income: $%.2f | Duration: %.1fs" % [
			route.description,
			income,
			duration
		]
		desc_label.modulate = Color(0.8, 0.8, 0.8)
		route_vbox.add_child(desc_label)
		
		var select_btn = Button.new()
		select_btn.text = "Select Route"
		select_btn.pressed.connect(func(): 
			GameManager.start_cruise_with_route(route_name)
			dialog.queue_free()
		)
		route_vbox.add_child(select_btn)
		
		route_container.add_child(route_vbox)
		route_panel.add_child(route_container)
		vbox.add_child(route_panel)
	
	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

func show_work_menu():
	if GameManager.is_working or GameManager.is_cruising:
		return
	
	var dialog = AcceptDialog.new()
	dialog.title = "🔧 Boat Maintenance - %s" % GameManager.current_boat
	dialog.size = Vector2(650, 600)
	
	var vbox = VBoxContainer.new()
	var condition = GameManager.get_current_boat_condition()
	var spec = GameManager.boat_specs[GameManager.current_boat]
	
	vbox.add_child(HSeparator.new())
	
	var tasks = [
		{"name": "Paint Job", "type": "paint", "value": condition.paint, "quality": condition.paint_quality, "available": true},
		{"name": "Seal Leaks", "type": "leaks", "value": condition.leaks, "quality": condition.leaks_quality, "available": true},
		{"name": "Electrical System", "type": "electricity", "value": condition.electricity, "quality": condition.electricity_quality, "available": spec.has_electricity},
		{"name": "Engine Service", "type": "engine", "value": condition.engine, "quality": condition.engine_quality, "available": spec.has_engine}
	]
	
	for task in tasks:
		var task_panel = Panel.new()
		task_panel.custom_minimum_size = Vector2(600, 120)
		
		var task_vbox = VBoxContainer.new()
		task_vbox.add_theme_constant_override("separation", 5)
		
		var header_hbox = HBoxContainer.new()
		var task_label = Label.new()
		
		if not task.available:
			task_label.text = "%s (Not available)" % task.name
			task_label.modulate = Color(0.5, 0.5, 0.5)
		else:
			task_label.text = "%s (Current: %s quality)" % [task.name, task.quality]
		
		task_label.add_theme_font_size_override("font_size", 14)
		header_hbox.add_child(task_label)
		
		if task.available:
			var progress = ProgressBar.new()
			progress.value = task.value
			progress.custom_minimum_size = Vector2(200, 20)
			header_hbox.add_child(progress)
		
		task_vbox.add_child(header_hbox)
		
		if task.available:
			var quality_hbox = HBoxContainer.new()
			
			for quality_name in ["cheap", "standard", "premium"]:
				var cost = GameManager.calculate_work_cost(task.type, quality_name)
				var duration = GameManager.get_work_duration(quality_name)
				
				var quality_btn = Button.new()
				quality_btn.text = "%s ($%.0f, %.1fs)" % [quality_name.capitalize(), cost, duration]
				
				if GameManager.money < cost:
					quality_btn.disabled = true
				
				quality_btn.pressed.connect(func():
					if GameManager.start_work(task.type, quality_name):
						dialog.queue_free()
				)
				
				quality_hbox.add_child(quality_btn)
			
			task_vbox.add_child(quality_hbox)
		
		task_panel.add_child(task_vbox)
		vbox.add_child(task_panel)
	
	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

func show_upgrade_shop():
	if not upgrade_shop:
		var UpgradeShopScript = load("res://UpgradeShop.gd")
		if UpgradeShopScript:
			upgrade_shop = UpgradeShopScript.new()
			add_child(upgrade_shop)
			upgrade_shop.show_shop()

func show_brokerage():
	if not ship_brokerage:
		var ShipBrokerageScript = load("res://ShipBrokerage.gd")
		if ShipBrokerageScript:
			ship_brokerage = ShipBrokerageScript.new()
			ship_brokerage.boat_models = boat_models
			add_child(ship_brokerage)
			ship_brokerage.show_brokerage()

func show_settings():
	if not settings_panel:
		var SettingsScript = load("res://Settings.gd")
		if SettingsScript:
			settings_panel = SettingsScript.new()
			settings_panel.position = Vector2(500, 50)
			settings_panel.size = Vector2(400, 500)
			add_child(settings_panel)
	
	if settings_panel:
		settings_panel.show_settings()

func handle_mooring_purchase():
	if GameManager.buy_monthly_mooring():
		status_label.text = "✅ Monthly mooring purchased!"
		return true
	return false

# ShipBrokerage.gd - Enhanced with 3D Model Previews
extends Control

var boat_models = {}  # Will be set by Main.gd
var model_preview_viewport: SubViewport
var model_preview_camera: Camera3D
var current_preview_model: Node3D

func show_brokerage():
	var dialog = AcceptDialog.new()
	dialog.title = "⛵ Ship Brokerage"
	dialog.size = Vector2(1000, 750)
	
	var main_hbox = HBoxContainer.new()
	
	# Left side - boat listings
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(700, 680)
	
	# Header info
	var header = VBoxContainer.new()
	
	var money_label = Label.new()
	money_label.text = "Your Money: $%.2f" % GameManager.money
	money_label.add_theme_font_size_override("font_size", 18)
	header.add_child(money_label)
	
	var current_boat_label = Label.new()
	current_boat_label.text = "Current Boat: %s (Condition: %.0f%%)" % [
		GameManager.current_boat, 
		GameManager.get_boat_condition_value()
	]
	current_boat_label.add_theme_font_size_override("font_size", 16)
	current_boat_label.modulate = Color.CYAN
	header.add_child(current_boat_label)
	
	# Mechanic status
	if GameManager.has_mechanic:
		var mechanic_label = Label.new()
		mechanic_label.text = "🔧 Mechanic Employed ($100/day)"
		mechanic_label.modulate = Color.GREEN
		header.add_child(mechanic_label)
	
	# Rental income
	if not GameManager.boat_rentals.is_empty():
		var rental_label = Label.new()
		var total_rental_income = 0
		for boat in GameManager.boat_rentals.values():
			total_rental_income += boat.income_per_day
		rental_label.text = "📅 Rental Income: $%.0f/day" % total_rental_income
		rental_label.modulate = Color.YELLOW
		header.add_child(rental_label)
	
	left_vbox.add_child(header)
	left_vbox.add_child(HSeparator.new())
	
	# Tabs
	var tab_container = TabContainer.new()
	tab_container.custom_minimum_size = Vector2(680, 550)
	
	# OWNED BOATS TAB
	var owned_scroll = ScrollContainer.new()
	var owned_list = VBoxContainer.new()
	
	for boat_name in GameManager.owned_boats:
		var panel = create_boat_panel(boat_name, true, dialog)
		owned_list.add_child(panel)
		owned_list.add_child(HSeparator.new())
	
	owned_scroll.add_child(owned_list)
	tab_container.add_child(owned_scroll)
	tab_container.set_tab_title(0, "My Fleet")
	
	# FOR SALE TAB
	var sale_scroll = ScrollContainer.new()
	var sale_list = VBoxContainer.new()
	
	if GameManager.boats_for_sale.is_empty():
		GameManager.generate_boats_for_sale()
	
	for boat_id in GameManager.boats_for_sale.keys():
		var boat_info = GameManager.boats_for_sale[boat_id]
		var panel = create_sale_boat_panel(boat_id, boat_info, dialog)
		sale_list.add_child(panel)
		sale_list.add_child(HSeparator.new())
	
	sale_scroll.add_child(sale_list)
	tab_container.add_child(sale_scroll)
	tab_container.set_tab_title(1, "For Sale")
	
	left_vbox.add_child(tab_container)
	main_hbox.add_child(left_vbox)
	
	# Right side - 3D model preview
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(250, 680)
	
	var preview_label = Label.new()
	preview_label.text = "3D Preview"
	preview_label.add_theme_font_size_override("font_size", 14)
	right_vbox.add_child(preview_label)
	
	# Create completely isolated 3D preview viewport
	var preview_container_panel = Panel.new()
	preview_container_panel.custom_minimum_size = Vector2(240, 240)
	
	var viewport_container = SubViewportContainer.new()
	viewport_container.custom_minimum_size = Vector2(240, 240)
	viewport_container.stretch = true
	
	model_preview_viewport = SubViewport.new()
	model_preview_viewport.size = Vector2(240, 240)
	model_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	model_preview_viewport.transparent_bg = false
	model_preview_viewport.use_debanding = true
	model_preview_viewport.msaa_3d = Viewport.MSAA_2X
	model_preview_viewport.snap_2d_transforms_to_pixel = false
	model_preview_viewport.snap_2d_vertices_to_pixel = false
	
	# CRITICAL: Create completely isolated world for preview
	var preview_world = World3D.new()
	model_preview_viewport.world_3d = preview_world
	
	# Setup isolated camera with clean environment
	model_preview_camera = Camera3D.new()
	model_preview_camera.position = Vector3(0, 1, 4)
	model_preview_camera.look_at(Vector3(0, 0, 0), Vector3(0, 1, 0))
	model_preview_camera.fov = 50
	model_preview_camera.near = 0.1
	model_preview_camera.far = 100
	
	# Create isolated environment that shows ONLY what we want
	var preview_env = Environment.new()
	preview_env.background_mode = Environment.BG_COLOR
	preview_env.background_color = Color(0.9, 0.95, 1.0)  # Light blue
	preview_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	preview_env.ambient_light_color = Color(0.7, 0.8, 0.9)
	preview_env.ambient_light_energy = 0.4
	
	# Disable ALL effects to prevent interference
	preview_env.glow_enabled = false
	preview_env.ssao_enabled = false
	preview_env.ssil_enabled = false
	preview_env.sdfgi_enabled = false
	preview_env.ssr_enabled = false
	preview_env.fog_enabled = false
	preview_env.volumetric_fog_enabled = false
	preview_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	
	model_preview_camera.environment = preview_env
	model_preview_viewport.add_child(model_preview_camera)
	
	# Add basic lighting to the isolated world
	var main_light = DirectionalLight3D.new()
	main_light.position = Vector3(2, 3, 2)
	main_light.look_at(Vector3(0, 0, 0), Vector3(0, 1, 0))
	main_light.light_energy = 0.8
	main_light.light_color = Color(1.0, 0.98, 0.95)
	main_light.shadow_enabled = false
	model_preview_viewport.add_child(main_light)
	
	# Soft fill light
	var fill_light = DirectionalLight3D.new()
	fill_light.position = Vector3(-1, 2, 1)
	fill_light.look_at(Vector3(0, 0, 0), Vector3(0, 1, 0))
	fill_light.light_energy = 0.3
	fill_light.light_color = Color(0.8, 0.9, 1.0)
	fill_light.shadow_enabled = false
	model_preview_viewport.add_child(fill_light)
	
	viewport_container.add_child(model_preview_viewport)
	preview_container_panel.add_child(viewport_container)
	right_vbox.add_child(preview_container_panel)
	
	# Preview info
	var preview_info = RichTextLabel.new()
	preview_info.custom_minimum_size = Vector2(240, 400)
	preview_info.bbcode_enabled = true
	preview_info.text = "[color=yellow]Hover over a boat to preview[/color]"
	right_vbox.add_child(preview_info)
	
	main_hbox.add_child(right_vbox)
	
	dialog.add_child(main_hbox)
	get_parent().add_child(dialog)
	dialog.popup_centered()
	
	# Show preview of current boat initially
	show_model_preview(GameManager.current_boat, preview_info)

func create_boat_panel(boat_name: String, is_owned: bool, dialog: AcceptDialog) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(650, 200)
	
	# Make panel hoverable for preview
	panel.mouse_entered.connect(func(): 
		if model_preview_viewport:
			var info = panel.get_parent().get_parent().get_parent().get_parent().get_child(0).get_child(1).get_child(2)
			show_model_preview(boat_name, info)
	)
	
	var boat_vbox = VBoxContainer.new()
	boat_vbox.add_theme_constant_override("separation", 5)
	
	# Boat name and status
	var name_hbox = HBoxContainer.new()
	var name_label = Label.new()
	name_label.text = boat_name
	name_label.add_theme_font_size_override("font_size", 16)
	
	if boat_name == GameManager.current_boat:
		name_label.modulate = Color.GREEN
		name_label.text += " (CURRENT)"
	elif GameManager.is_boat_rented(boat_name):
		name_label.modulate = Color.YELLOW
		var rental = GameManager.boat_rentals[boat_name]
		name_label.text += " (RENTED - %d days left, $%.0f/day)" % [rental.days_left, rental.income_per_day]
	
	name_hbox.add_child(name_label)
	boat_vbox.add_child(name_hbox)
	
	# Boat specifications
	var spec = GameManager.boat_specs[boat_name]
	var spec_grid = GridContainer.new()
	spec_grid.columns = 3
	
	var weight_label = Label.new()
	weight_label.text = "⚖ Weight: %.1f tons" % spec.weight_tons
	spec_grid.add_child(weight_label)
	
	var pax_label = Label.new()
	pax_label.text = "👥 Passengers: %d" % spec.passengers
	spec_grid.add_child(pax_label)
	
	var length_label = Label.new()
	length_label.text = "📏 Dimensions: %.1f×%.1fm" % [spec.length_m, spec.width_m]
	spec_grid.add_child(length_label)
	
	boat_vbox.add_child(spec_grid)
	
	# Condition details
	if GameManager.boat_conditions.has(boat_name):
		var condition = GameManager.boat_conditions[boat_name]
		
		boat_vbox.add_child(HSeparator.new())
		
		var cond_grid = GridContainer.new()
		cond_grid.columns = 2
		
		var paint_label = Label.new()
		paint_label.text = "Paint (%s): %.0f%%" % [condition.paint_quality, condition.paint]
		paint_label.modulate = get_condition_color(condition.paint)
		cond_grid.add_child(paint_label)
		
		var leak_label = Label.new()
		leak_label.text = "Leaks (%s): %.0f%%" % [condition.leaks_quality, condition.leaks]
		leak_label.modulate = get_condition_color(condition.leaks)
		cond_grid.add_child(leak_label)
		
		boat_vbox.add_child(cond_grid)
		
		# Overall and income
		var overall_label = Label.new()
		var value_mod = condition.get("value_modifier", 1.0)
		overall_label.text = "Overall: %.0f%% | Income: $%.0f/cruise" % [
			condition.overall,
			spec.base_income * (1 + condition.overall / 100.0) * value_mod
		]
		overall_label.modulate = Color.YELLOW
		boat_vbox.add_child(overall_label)
	
	# Buttons
	var button_hbox = HBoxContainer.new()
	
	if boat_name != GameManager.current_boat and not GameManager.is_boat_rented(boat_name):
		var switch_btn = Button.new()
		switch_btn.text = "Switch to this boat"
		switch_btn.pressed.connect(func(): 
			GameManager.switch_boat(boat_name)
			dialog.queue_free()
			show_brokerage()
		)
		button_hbox.add_child(switch_btn)
	
	# Rental button
	if spec.can_rent and boat_name != GameManager.current_boat:
		if GameManager.is_boat_rented(boat_name):
			var end_rental_btn = Button.new()
			end_rental_btn.text = "End Rental Early"
			end_rental_btn.modulate = Color.ORANGE
			end_rental_btn.pressed.connect(func(): 
				GameManager.end_rental(boat_name)
				dialog.queue_free()
				show_brokerage()
			)
			button_hbox.add_child(end_rental_btn)
		else:
			var rent_btn = Button.new()
			rent_btn.text = "Rent Out (7 days)"
			rent_btn.pressed.connect(func(): 
				if GameManager.start_rental(boat_name, 7):
					dialog.queue_free()
					show_brokerage()
			)
			button_hbox.add_child(rent_btn)
	
	boat_vbox.add_child(button_hbox)
	panel.add_child(boat_vbox)
	
	return panel

func create_sale_boat_panel(boat_id: String, boat_info: Dictionary, dialog: AcceptDialog) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(650, 220)
	
	var boat_name = boat_info.name
	
	# Make panel hoverable for preview
	panel.mouse_entered.connect(func(): 
		if model_preview_viewport:
			var info = panel.get_parent().get_parent().get_parent().get_parent().get_child(0).get_child(1).get_child(2)
			show_model_preview(boat_name, info)
	)
	
	var boat_vbox = VBoxContainer.new()
	boat_vbox.add_theme_constant_override("separation", 5)
	
	# Name and price
	var name_hbox = HBoxContainer.new()
	var name_label = Label.new()
	name_label.text = boat_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_hbox.add_child(name_label)
	
	var price_label = Label.new()
	price_label.text = "  $%d" % boat_info.price
	price_label.add_theme_font_size_override("font_size", 16)
	price_label.modulate = Color.GREEN if GameManager.money >= boat_info.price else Color.RED
	name_hbox.add_child(price_label)
	
	boat_vbox.add_child(name_hbox)
	
	# Specifications
	var spec = GameManager.boat_specs[boat_name]
	var spec_grid = GridContainer.new()
	spec_grid.columns = 3
	
	var weight_label = Label.new()
	weight_label.text = "⚖ %.1f tons" % spec.weight_tons
	spec_grid.add_child(weight_label)
	
	var pax_label = Label.new()
	pax_label.text = "👥 %d pax" % spec.passengers
	spec_grid.add_child(pax_label)
	
	var size_label = Label.new()
	size_label.text = "📏 %.1f×%.1fm" % [spec.length_m, spec.width_m]
	spec_grid.add_child(size_label)
	
	boat_vbox.add_child(spec_grid)
	
	# Condition preview
	var condition = boat_info.condition
	var overall_label = Label.new()
	overall_label.text = "Condition: %.0f%% | Income: $%.0f/cruise" % [
		condition.overall,
		spec.base_income * (1 + condition.overall / 100.0)
	]
	overall_label.modulate = Color.CYAN
	boat_vbox.add_child(overall_label)
	
	# Buy button
	var buy_btn = Button.new()
	if GameManager.money >= boat_info.price:
		buy_btn.text = "Buy for $%d" % boat_info.price
		buy_btn.pressed.connect(func(): _buy_boat(boat_id, dialog))
	else:
		buy_btn.text = "Need $%d more" % (boat_info.price - GameManager.money)
		buy_btn.disabled = true
	boat_vbox.add_child(buy_btn)
	
	panel.add_child(boat_vbox)
	return panel

func show_model_preview(boat_name: String, info_label: RichTextLabel):
	# Clear only the boat models, keep camera and lights
	for child in model_preview_viewport.get_children():
		if child != model_preview_camera and not child is DirectionalLight3D:
			child.queue_free()
	
	current_preview_model = null
	await get_tree().process_frame  # Wait for cleanup
	
	# Load boat model in isolated viewport
	var model_path = boat_models.get(boat_name, "")
	var model_loaded = false
	
	if model_path != "" and ResourceLoader.exists(model_path):
		print("Loading model for preview: ", model_path)
		var model_resource = load(model_path)
		if model_resource:
			var model_instance = model_resource.instantiate()
			if model_instance:
				print("Model instantiated successfully")
				
				# Clean and prepare the model
				_clean_boat_model(model_instance)
				
				# Create container for the boat
				var model_container = Node3D.new()
				model_container.name = "BoatPreview"
				
				# Apply appropriate scaling
				var scale_factor = _get_preview_scale(boat_name)
				model_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)
				model_instance.position = Vector3(0, 0, 0)
				
				# Add to container
				model_container.add_child(model_instance)
				current_preview_model = model_container
				model_preview_viewport.add_child(model_container)
				
				# Start rotation animation
				model_container.rotation_degrees.y = 0
				var tween = get_tree().create_tween()
				tween.set_loops()
				tween.tween_property(model_container, "rotation_degrees:y", 360, 20.0)
				
				model_loaded = true
				print("Boat model loaded and animated")
			else:
				print("Failed to instantiate model")
		else:
			print("Failed to load model resource")
	else:
		print("Model path not found or doesn't exist: ", model_path)
	
	# If model didn't load, create a simple fallback boat
	if not model_loaded:
		print("Creating fallback boat shape for: ", boat_name)
		var fallback = Node3D.new()
		fallback.name = "FallbackBoat"
		
		# Create simple boat hull
		var hull = MeshInstance3D.new()
		var hull_mesh = BoxMesh.new()
		hull_mesh.size = Vector3(2.0, 0.6, 1.0)
		hull.mesh = hull_mesh
		
		# Boat-like material
		var hull_material = StandardMaterial3D.new()
		hull_material.albedo_color = Color(0.3, 0.5, 0.8)
		hull_material.roughness = 0.4
		hull_material.metallic = 0.1
		hull.set_surface_override_material(0, hull_material)
		hull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
		fallback.add_child(hull)
		
		# Add simple cabin for larger boats
		if not boat_name.contains("Rowboat"):
			var cabin = MeshInstance3D.new()
			var cabin_mesh = BoxMesh.new()
			cabin_mesh.size = Vector3(0.8, 0.5, 0.6)
			cabin.mesh = cabin_mesh
			cabin.position = Vector3(0, 0.55, 0)
			
			var cabin_material = StandardMaterial3D.new()
			cabin_material.albedo_color = Color(0.9, 0.9, 0.9)
			cabin_material.roughness = 0.3
			cabin.set_surface_override_material(0, cabin_material)
			cabin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			
			fallback.add_child(cabin)
		
		current_preview_model = fallback
		model_preview_viewport.add_child(fallback)
		
		# Animate fallback too
		fallback.rotation_degrees.y = 0
		var tween = get_tree().create_tween()
		tween.set_loops()
		tween.tween_property(fallback, "rotation_degrees:y", 360, 15.0)
	
	# Update info panel
	if info_label:
		var spec = GameManager.boat_specs.get(boat_name, {})
		info_label.text = "[b]%s[/b]\n\n" % boat_name
		info_label.text += "[color=cyan]Income:[/color] $%.0f/cruise\n" % spec.get("base_income", 0)
		info_label.text += "[color=yellow]Hull:[/color] %s\n" % spec.get("hull_type", "Unknown")
		info_label.text += "[color=green]Capacity:[/color] %d passengers\n" % spec.get("passengers", 0)
		info_label.text += "[color=aqua]Size:[/color] %.1fm × %.1fm\n" % [spec.get("length_m", 0), spec.get("width_m", 0)]

func _get_preview_scale(boat_name: String) -> float:
	if boat_name.contains("Rowboat"):
		return 0.8
	elif boat_name.contains("Sailboat"):
		return 0.5
	elif boat_name.contains("Speed") or boat_name.contains("Racing"):
		return 0.6
	elif boat_name.contains("Cruiser") or boat_name.contains("Motor"):
		return 0.4
	elif boat_name.contains("Yacht") and not boat_name.contains("Mega"):
		return 0.3
	elif boat_name.contains("Ship") or boat_name.contains("Liner") or boat_name.contains("Mega"):
		return 0.2
	elif boat_name.contains("Cargo") or boat_name.contains("Container"):
		return 0.25
	else:
		return 0.4

func _clean_boat_model(node: Node):
	# Remove any non-boat elements that might be in the model
	if node.name.to_lower().contains("water") or \
	   node.name.to_lower().contains("ocean") or \
	   node.name.to_lower().contains("sea") or \
	   node.name.to_lower().contains("pier") or \
	   node.name.to_lower().contains("dock") or \
	   node.name.to_lower().contains("house") or \
	   node.name.to_lower().contains("building") or \
	   node.name.to_lower().contains("environment") or \
	   node.name.to_lower().contains("scene"):
		node.queue_free()
		return
	
	# Process mesh instances
	if node is MeshInstance3D:
		var mesh_inst = node as MeshInstance3D
		
		# Disable shadows for preview
		mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
		# Check for obviously wrong elements by name
		var node_name = node.name.to_lower()
		if node_name.contains("arrow") or node_name.contains("axis") or \
		   node_name.contains("helper") or node_name.contains("gizmo") or \
		   node_name.contains("debug") or node_name.contains("collider") or \
		   node_name.contains("collision") or node_name.contains("trigger"):
			node.visible = false
			return
		
		# Check mesh bounds for weird objects
		if mesh_inst.mesh:
			var aabb = mesh_inst.mesh.get_aabb()
			var size = aabb.size
			
			# Hide extremely thin objects (like debug lines)
			var min_dim = min(size.x, min(size.y, size.z))
			var max_dim = max(size.x, max(size.y, size.z))
			
			if min_dim > 0 and max_dim / min_dim > 50:  # Very thin objects
				node.visible = false
				return
			
			# Hide tiny objects that might be markers
			if size.length() < 0.02:
				node.visible = false
				return
	
	# Clean children recursively
	for child in node.get_children():
		_clean_boat_model(child)

func _buy_boat(boat_id: String, dialog: AcceptDialog):
	var boat_name = GameManager.boats_for_sale[boat_id].name
	
	if GameManager.buy_boat_from_sale(boat_id):
		print("Purchased boat: ", boat_name)
		dialog.queue_free()
		
		var confirm = ConfirmationDialog.new()
		confirm.title = "New Boat Purchased!"
		confirm.dialog_text = "You bought a %s!\nSwitch to it now?" % boat_name
		confirm.confirmed.connect(func(): GameManager.switch_boat(boat_name))
		get_parent().add_child(confirm)
		confirm.popup_centered()
		
		if GameManager.owned_boats.size() == 2:
			var rental_dialog = AcceptDialog.new()
			rental_dialog.title = "💡 New Feature Unlocked!"
			rental_dialog.dialog_text = """You now own multiple boats!
			
You can rent out boats you're not using for passive income.
Visit the Ship Brokerage to rent out your spare boats!"""
			get_parent().add_child(rental_dialog)
			rental_dialog.popup_centered()
		
		show_brokerage()

func get_condition_color(value: float) -> Color:
	if value >= 80:
		return Color.GREEN
	elif value >= 50:
		return Color.YELLOW
	elif value >= 30:
		return Color.ORANGE
	else:
		return Color.RED

# GameManager.gd - FULLY FIXED VERSION WITH PROPER CLOCK, DIY WORK, AND BOAT SINKING
extends Node

signal money_changed(new_amount)
signal boat_condition_changed(new_condition)
signal boat_changed(boat_name)
signal day_passed
signal work_completed
signal upgrade_purchased(upgrade_name)
signal time_tick(hour, minute)
signal cruise_started
signal cruise_completed
signal rental_started(boat_name)
signal rental_ended(boat_name)
signal boat_sinking_warning(boat_name, leak_level)
signal boat_sank(boat_name)
signal game_over

var money: float = 100.0
var days_since_cruise: int = 0
var has_monthly_mooring: bool = false
var mooring_days_left: int = 0
var current_day: int = 1
var is_working: bool = false
var is_cruising: bool = false
var work_timer: float = 0.0
var cruise_timer: float = 0.0
var cruise_total_time: float = 0.0
var current_work_type: String = ""
var current_work_quality: String = "standard"
var current_cruise_route: Dictionary = {}

# Rental system
var boat_rentals: Dictionary = {}

# Mechanic system
var has_mechanic: bool = false
var mechanic_daily_cost: float = 100.0

# Time system - FIXED
var game_time: float = 0.0
var current_hour: int = 6
var current_minute: int = 0
var time_accumulator: float = 0.0  # Added to properly track time

# Boat system
var current_boat: String = "Old Rowboat"
var owned_boats: Array = ["Old Rowboat"]

# Work quality options - now includes DIY options
var work_qualities: Dictionary = {
	"cheap": {
		"cost_multiplier": 0.5,
		"time_multiplier": 0.7,
		"improvement_multiplier": 0.8,
		"durability_multiplier": 0.5,
		"value_increase": 0.02,
		"is_diy": false
	},
	"standard": {
		"cost_multiplier": 1.0,
		"time_multiplier": 1.0,
		"improvement_multiplier": 1.0,
		"durability_multiplier": 1.0,
		"value_increase": 0.05,
		"is_diy": false
	},
	"premium": {
		"cost_multiplier": 2.5,
		"time_multiplier": 1.5,
		"improvement_multiplier": 1.3,
		"durability_multiplier": 2.0,
		"value_increase": 0.10,
		"is_diy": false
	},
	"diy_basic": {
		"cost_multiplier": 0.33,
		"time_multiplier": 2.0,
		"improvement_multiplier": 0.6,
		"durability_multiplier": 0.4,
		"value_increase": 0.01,
		"is_diy": true
	},
	"diy_standard": {
		"cost_multiplier": 0.33,
		"time_multiplier": 2.2,
		"improvement_multiplier": 0.75,
		"durability_multiplier": 0.6,
		"value_increase": 0.015,
		"is_diy": true
	},
	"diy_advanced": {
		"cost_multiplier": 0.33,
		"time_multiplier": 2.5,
		"improvement_multiplier": 0.9,
		"durability_multiplier": 0.8,
		"value_increase": 0.02,
		"is_diy": true
	}
}

# Per-boat condition tracking
var boat_conditions: Dictionary = {}

# Cruise routes - now with boat-specific durations
var cruise_routes: Dictionary = {
	"Short Canal": {
		"base_duration": 2.0,
		"income_multiplier": 0.8,
		"condition_loss": 0.5,
		"description": "Quick cruise"
	},
	"Standard Route": {
		"base_duration": 3.0,
		"income_multiplier": 1.0,
		"condition_loss": 1.0,
		"description": "Normal cruise"
	},
	"Long Journey": {
		"base_duration": 5.0,
		"income_multiplier": 1.5,
		"condition_loss": 1.5,
		"description": "Extended cruise"
	},
	"Grand Tour": {
		"base_duration": 8.0,
		"income_multiplier": 2.5,
		"condition_loss": 2.5,
		"description": "Epic voyage"
	},
	"Ocean Expedition": {
		"base_duration": 12.0,
		"income_multiplier": 4.0,
		"condition_loss": 3.5,
		"description": "Ocean crossing (large boats only)",
		"min_boat_size": 3
	}
}

# Boat specifications
var boat_specs: Dictionary = {
	"Old Rowboat": {
		"base_income": 10.0,
		"base_price": 0,
		"rental_income": 15.0,
		"has_engine": false,
		"has_electricity": false,
		"hull_type": "wood",
		"weight_tons": 0.5,
		"passengers": 2,
		"length_m": 3.5,
		"width_m": 1.2,
		"work_difficulty": 1.0,
		"can_hire_mechanic": false,
		"can_rent": true,
		"cruise_duration_factor": 1.5,
		"boat_size": 1
	},
	"Basic Sailboat": {
		"base_income": 25.0,
		"base_price": 500,
		"rental_income": 50.0,
		"has_engine": true,
		"has_electricity": true,
		"hull_type": "fiberglass",
		"weight_tons": 2.0,
		"passengers": 6,
		"length_m": 8.0,
		"width_m": 2.5,
		"work_difficulty": 1.5,
		"can_hire_mechanic": false,
		"can_rent": true,
		"cruise_duration_factor": 1.2,
		"boat_size": 2
	},
	"Motor Cruiser": {
		"base_income": 50.0,
		"base_price": 2000,
		"rental_income": 120.0,
		"has_engine": true,
		"has_electricity": true,
		"hull_type": "aluminum",
		"weight_tons": 5.0,
		"passengers": 10,
		"length_m": 12.0,
		"width_m": 3.8,
		"work_difficulty": 2.0,
		"can_hire_mechanic": true,
		"can_rent": true,
		"cruise_duration_factor": 1.0,
		"boat_size": 3
	},
	"Luxury Yacht": {
		"base_income": 100.0,
		"base_price": 10000,
		"rental_income": 300.0,
		"has_engine": true,
		"has_electricity": true,
		"hull_type": "composite",
		"weight_tons": 15.0,
		"passengers": 20,
		"length_m": 20.0,
		"width_m": 5.5,
		"work_difficulty": 3.0,
		"can_hire_mechanic": true,
		"can_rent": true,
		"cruise_duration_factor": 0.8,
		"boat_size": 4
	},
	"Mega Yacht": {
		"base_income": 200.0,
		"base_price": 50000,
		"rental_income": 800.0,
		"has_engine": true,
		"has_electricity": true,
		"hull_type": "steel",
		"weight_tons": 50.0,
		"passengers": 50,
		"length_m": 35.0,
		"width_m": 8.0,
		"work_difficulty": 4.0,
		"can_hire_mechanic": true,
		"can_rent": true,
		"cruise_duration_factor": 0.6,
		"boat_size": 5
	}
}

var boats_for_sale: Dictionary = {}
var boat_upgrades: Array = []

const CRUISE_FINE: float = 50.0
const MONTHLY_MOORING_COST: float = 500.0
const BASE_WORK_DURATION: float = 5.0

func _ready():
	print("GameManager ready! Starting money: $", money)
	initialize_boat_conditions()
	generate_boats_for_sale()
	
		# Ensure we always have at least the starter boat
	if owned_boats.is_empty():
		owned_boats = ["Old Rowboat"]
		print("GameManager: Initialized with starter boat")
	set_process(true)

func get_available_work_qualities() -> Dictionary:
	# Returns both professional and DIY options
	return {
		"Professional": ["cheap", "standard", "premium"],
		"DIY": ["diy_basic", "diy_standard", "diy_advanced"]
	}

func get_work_quality_display_name(quality: String) -> String:
	match quality:
		"cheap":
			return "Cheap Professional"
		"standard":
			return "Standard Professional" 
		"premium":
			return "Premium Professional"
		"diy_basic":
			return "Basic DIY"
		"diy_standard":
			return "Standard DIY"
		"diy_advanced":
			return "Advanced DIY"
		_:
			return quality.capitalize()

func get_work_quality_description(quality: String) -> String:
	var data = work_qualities[quality]
	var time_desc = "%.1fx time" % data.time_multiplier
	var cost_desc = "%.0f%% cost" % (data.cost_multiplier * 100)
	var quality_desc = ""
	
	if data.is_diy:
		if quality == "diy_basic":
			quality_desc = "Basic tools, good effort"
		elif quality == "diy_standard": 
			quality_desc = "Decent tools, careful work"
		else:  # diy_advanced
			quality_desc = "Good tools, skilled work"
	else:
		if quality == "cheap":
			quality_desc = "Quick & basic"
		elif quality == "standard":
			quality_desc = "Professional standard"
		else:  # premium
			quality_desc = "High-end materials"
	
	return "%s | %s | %s" % [cost_desc, time_desc, quality_desc]

func check_boat_sinking(boat_name: String):
	if not boat_conditions.has(boat_name):
		return
	
	var condition = boat_conditions[boat_name]
	var leak_level = condition.leaks
	
	# Check for sinking (leaks at 1% or below)
	if leak_level <= 1.0:
		sink_boat(boat_name)
		return
	
	# Check for warnings
	if leak_level <= 10.0:
		boat_sinking_warning.emit(boat_name, leak_level)
	elif leak_level <= 20.0:
		boat_sinking_warning.emit(boat_name, leak_level)

func sink_boat(boat_name: String):
	print("BOAT SINKING: ", boat_name)
	boat_sank.emit(boat_name)
	
	# Remove boat from ownership
	if boat_name in owned_boats:
		owned_boats.erase(boat_name)
	
	# Remove from rentals if rented
	if boat_rentals.has(boat_name):
		boat_rentals.erase(boat_name)
	
	# Remove condition data
	if boat_conditions.has(boat_name):
		boat_conditions.erase(boat_name)
	
	# Check if this was the current boat
	if boat_name == current_boat:
		if owned_boats.is_empty():
			# Game over - no boats left
			game_over.emit()
		else:
			# Switch to another boat
			current_boat = owned_boats[0]
			boat_changed.emit(current_boat)
			var condition = get_current_boat_condition()
			boat_condition_changed.emit(condition.overall)

func get_sinking_warning_message(boat_name: String, leak_level: float) -> String:
	if leak_level <= 1.0:
		return "%s has sunk due to catastrophic leaks!" % boat_name
	elif leak_level <= 10.0:
		return "CRITICAL: %s leaks at %.1f%% - Boat will sink soon!" % [boat_name, leak_level]
	elif leak_level <= 20.0:
		return "WARNING: %s leaks at %.1f%% - Risk of sinking!" % [boat_name, leak_level]
	else:
		return ""

func is_game_over() -> bool:
	return owned_boats.is_empty()

func get_boat_status_tips() -> Array:
	var tips = []
	
	# General maintenance tip
	tips.append("Keep your boat's condition in top shape for maximum cruise revenues!")
	
	# Check all owned boats for issues
	for boat_name in owned_boats:
		if not boat_conditions.has(boat_name):
			continue
		
		var condition = boat_conditions[boat_name]
		
		# Leak warnings
		if condition.leaks <= 20.0:
			if condition.leaks <= 10.0:
				tips.append("CRITICAL: %s leaks at %.1f%% - Risk of sinking!" % [boat_name, condition.leaks])
			else:
				tips.append("WARNING: %s leaks at %.1f%% - Needs attention!" % [boat_name, condition.leaks])
		
		# Overall condition
		if condition.overall < 30.0:
			tips.append("%s in poor condition - Income severely reduced!" % boat_name)
	
	return tips

func initialize_boat_conditions():
	# Set up Old Rowboat with proper initial conditions
	var paint = 20.0
	var leaks = 40.0
	var electricity = 100.0  # No electrical system
	var engine = 100.0      # No engine
	
	boat_conditions["Old Rowboat"] = {
		"paint": paint,
		"paint_quality": "cheap",
		"leaks": leaks,
		"leaks_quality": "cheap",
		"electricity": electricity,
		"electricity_quality": "none",
		"engine": engine,
		"engine_quality": "none",
		"overall": calculate_overall_condition(paint, leaks, electricity, engine, "Old Rowboat"),
		"value_modifier": 1.0
	}

func _process(delta):
	# FIXED: Proper clock system
	# Game runs at 100x speed (1 real second = 100 game seconds)
	time_accumulator += delta * 100.0
	
	# Convert accumulated seconds to minutes
	while time_accumulator >= 60.0:
		time_accumulator -= 60.0
		current_minute += 1
		
		# Handle minute overflow
		if current_minute >= 60:
			current_minute = 0
			current_hour += 1
			
			# Handle hour overflow
			if current_hour >= 24:
				current_hour = 0
				advance_day()
	
	# Emit the current time
	time_tick.emit(current_hour, current_minute)
	
	# Handle work timer
	if is_working:
		work_timer -= delta
		if work_timer <= 0:
			complete_work()
	
	# Handle cruise timer
	if is_cruising:
		cruise_timer -= delta
		if cruise_timer <= 0:
			complete_cruise()

func get_time_of_day() -> String:
	if current_hour < 6:
		return "night"
	elif current_hour < 12:
		return "morning"
	elif current_hour < 18:
		return "afternoon"
	else:
		return "evening"

func get_cruise_progress() -> float:
	if not is_cruising or cruise_total_time <= 0:
		return 0.0
	return 1.0 - (cruise_timer / cruise_total_time)

func generate_boats_for_sale():
	for boat_name in boat_specs.keys():
		if boat_name == "Old Rowboat":
			continue
		
		for i in range(2):
			var condition_multiplier = randf_range(0.3, 1.0)
			var boat_id = boat_name + "_" + str(i)
			
			var paint = randf_range(20, 100) * condition_multiplier
			var leaks = randf_range(20, 100) * condition_multiplier
			
			var electricity = 100.0
			var engine = 100.0
			
			if boat_specs[boat_name].has_electricity:
				electricity = randf_range(20, 100) * condition_multiplier
			if boat_specs[boat_name].has_engine:
				engine = randf_range(20, 100) * condition_multiplier
			
			var overall = calculate_overall_condition(paint, leaks, electricity, engine, boat_name)
			var price = boat_specs[boat_name].base_price * (0.5 + overall / 200.0)
			
			boats_for_sale[boat_id] = {
				"name": boat_name,
				"price": int(price),
				"condition": {
					"paint": paint,
					"paint_quality": "cheap",
					"leaks": leaks,
					"leaks_quality": "cheap",
					"electricity": electricity,
					"electricity_quality": "cheap" if boat_specs[boat_name].has_electricity else "none",
					"engine": engine,
					"engine_quality": "cheap" if boat_specs[boat_name].has_engine else "none",
					"overall": overall,
					"value_modifier": 1.0
				}
			}

func calculate_overall_condition(paint: float, leaks: float, electricity: float, engine: float, boat_name: String) -> float:
	var spec = boat_specs[boat_name]
	var total = paint * 0.2 + leaks * 0.3
	
	if spec.has_electricity:
		total += electricity * 0.25
	else:
		total += 25
	
	if spec.has_engine:
		total += engine * 0.25
	else:
		total += 25
	
	return total

func get_current_boat_condition() -> Dictionary:
	if not boat_conditions.has(current_boat):
		print("Warning: Boat condition not found for ", current_boat, " - creating default")
		var spec = boat_specs[current_boat]
		var paint = 50.0
		var leaks = 50.0
		var electricity = 100.0 if not spec.has_electricity else 50.0
		var engine = 100.0 if not spec.has_engine else 50.0
		
		boat_conditions[current_boat] = {
			"paint": paint,
			"paint_quality": "standard",
			"leaks": leaks,
			"leaks_quality": "standard",
			"electricity": electricity,
			"electricity_quality": "none" if not spec.has_electricity else "standard",
			"engine": engine,
			"engine_quality": "none" if not spec.has_engine else "standard",
			"overall": calculate_overall_condition(paint, leaks, electricity, engine, current_boat),
			"value_modifier": 1.0
		}
	return boat_conditions[current_boat]

func get_boat_condition_value() -> float:
	return get_current_boat_condition().overall

func calculate_work_cost(work_type: String, quality: String) -> float:
	var base_cost = 20.0
	var spec = boat_specs[current_boat]
	var quality_mult = work_qualities[quality].cost_multiplier
	
	base_cost *= spec.work_difficulty
	
	if work_type in ["engine", "electricity"]:
		base_cost *= 1.5
	
	return base_cost * quality_mult

func calculate_work_improvement(work_type: String, quality: String) -> float:
	var spec = boat_specs[current_boat]
	var base_improvement = randf_range(15.0, 21.0)
	var quality_mult = work_qualities[quality].improvement_multiplier
	
	var improvement = (base_improvement / spec.work_difficulty) * quality_mult
	
	if has_mechanic and work_type == "engine" and spec.has_engine:
		improvement *= 1.5
	
	return improvement

func get_work_duration(quality: String) -> float:
	var base_duration = BASE_WORK_DURATION
	var quality_mult = work_qualities[quality].time_multiplier
	
	if has_mechanic and boat_specs[current_boat].can_hire_mechanic:
		base_duration /= 2.0
	
	return base_duration * quality_mult

func get_cruise_duration(route_name: String) -> float:
	var route = cruise_routes[route_name]
	var base_duration = route.base_duration
	var spec = boat_specs[current_boat]
	return base_duration * spec.cruise_duration_factor

func can_take_route(route_name: String) -> bool:
	var route = cruise_routes[route_name]
	if route.has("min_boat_size"):
		var spec = boat_specs[current_boat]
		return spec.boat_size >= route.min_boat_size
	return true

func start_rental(boat_name: String, days: int) -> bool:
	if boat_name == current_boat:
		return false
	
	if not boat_name in owned_boats:
		return false
	
	if boat_rentals.has(boat_name):
		return false
	
	var spec = boat_specs[boat_name]
	if not spec.can_rent:
		return false
	
	var condition = boat_conditions.get(boat_name, {"overall": 50.0})
	var daily_income = spec.rental_income * (0.5 + condition.overall / 200.0)
	
	boat_rentals[boat_name] = {
		"days_left": days,
		"income_per_day": daily_income
	}
	
	rental_started.emit(boat_name)
	return true

func end_rental(boat_name: String):
	if boat_rentals.has(boat_name):
		boat_rentals.erase(boat_name)
		rental_ended.emit(boat_name)

func is_boat_rented(boat_name: String) -> bool:
	return boat_rentals.has(boat_name)

func complete_cruise():
	is_cruising = false
	days_since_cruise = 0
	
	# Calculate income
	var income = calculate_cruise_income() * current_cruise_route.income_multiplier
	add_money(income)
	
	# Get condition and apply deterioration
	var condition = get_current_boat_condition()
	var loss = current_cruise_route.condition_loss
	
	# Apply deterioration
	var paint_durability = work_qualities[condition.paint_quality].durability_multiplier
	var leak_durability = work_qualities[condition.leaks_quality].durability_multiplier
	
	condition.paint = max(0, condition.paint - (loss * 0.5 / paint_durability))
	condition.leaks = max(0, condition.leaks - (loss / leak_durability))
	
	if boat_specs[current_boat].has_engine:
		var engine_durability = work_qualities[condition.engine_quality].durability_multiplier
		condition.engine = max(0, condition.engine - (loss * 0.7 / engine_durability))
	
	if boat_specs[current_boat].has_electricity:
		var elec_durability = work_qualities[condition.electricity_quality].durability_multiplier
		condition.electricity = max(0, condition.electricity - (loss * 0.5 / elec_durability))
	
	# Recalculate overall condition
	condition.overall = calculate_overall_condition(
		condition.paint, condition.leaks,
		condition.electricity, condition.engine,
		current_boat
	)
	
	# Ensure the condition is saved back
	boat_conditions[current_boat] = condition
	
	boat_condition_changed.emit(condition.overall)
	
	# Check for boat sinking after cruise damage
	check_boat_sinking(current_boat)
	
	cruise_completed.emit()
	
	return income

func calculate_cruise_income() -> float:
	var spec = boat_specs[current_boat]
	var base = spec.base_income
	var condition = get_current_boat_condition()
	var condition_multiplier = condition.overall / 100.0
	var value_multiplier = condition.value_modifier
	var upgrade_bonus = boat_upgrades.size() * 5.0
	return base * (1 + condition_multiplier) * value_multiplier + upgrade_bonus

func start_work(work_type: String, quality: String) -> bool:
	if is_working or is_cruising:
		return false
	
	var cost = calculate_work_cost(work_type, quality)
	if not spend_money(cost):
		return false
	
	is_working = true
	work_timer = get_work_duration(quality)
	current_work_type = work_type
	current_work_quality = quality
	return true

func complete_work():
	is_working = false
	var condition = get_current_boat_condition()
	var improvement = calculate_work_improvement(current_work_type, current_work_quality)
	
	# Apply improvement
	if current_work_type == "paint":
		condition.paint = min(100, condition.paint + improvement)
		condition.paint_quality = current_work_quality
	elif current_work_type == "leaks":
		condition.leaks = min(100, condition.leaks + improvement * 1.2)
		condition.leaks_quality = current_work_quality
	elif current_work_type == "electricity":
		if boat_specs[current_boat].has_electricity:
			condition.electricity = min(100, condition.electricity + improvement)
			condition.electricity_quality = current_work_quality
	elif current_work_type == "engine":
		if boat_specs[current_boat].has_engine:
			condition.engine = min(100, condition.engine + improvement)
			condition.engine_quality = current_work_quality
	
	# Update boat value
	var quality_data = work_qualities[current_work_quality]
	condition.value_modifier = min(2.0, condition.value_modifier + quality_data.value_increase)
	
	# Recalculate overall
	condition.overall = calculate_overall_condition(
		condition.paint, condition.leaks,
		condition.electricity, condition.engine,
		current_boat
	)
	
	boat_condition_changed.emit(condition.overall)
	
	# Check for boat sinking after work (though work should improve conditions)
	check_boat_sinking(current_boat)
	
	work_completed.emit()
	current_work_type = ""
	current_work_quality = "standard"

func advance_day():
	current_day += 1
	days_since_cruise += 1
	
	# Process rentals
	for boat_name in boat_rentals.keys():
		var rental = boat_rentals[boat_name]
		add_money(rental.income_per_day)
		rental.days_left -= 1
		if rental.days_left <= 0:
			end_rental(boat_name)
	
	# Pay mechanic
	if has_mechanic:
		if not spend_money(mechanic_daily_cost):
			has_mechanic = false
	
	# Deteriorate boat conditions
	for boat_name in boat_conditions.keys():
		var condition = boat_conditions[boat_name]
		
		var paint_durability = work_qualities[condition.paint_quality].durability_multiplier
		var leak_durability = work_qualities[condition.leaks_quality].durability_multiplier
		
		condition.paint = max(0, condition.paint - (1.0 / paint_durability))
		condition.leaks = max(0, condition.leaks - (2.0 / leak_durability))
		
		if boat_specs[boat_name].has_engine:
			if has_mechanic and boat_name == current_boat:
				condition.engine = min(100, condition.engine + 1)
			else:
				var engine_durability = work_qualities[condition.engine_quality].durability_multiplier
				condition.engine = max(0, condition.engine - (1.0 / engine_durability))
		
		if boat_specs[boat_name].has_electricity:
			var elec_durability = work_qualities[condition.electricity_quality].durability_multiplier
			condition.electricity = max(0, condition.electricity - (1.0 / elec_durability))
		
		condition.overall = calculate_overall_condition(
			condition.paint, condition.leaks,
			condition.electricity, condition.engine,
			boat_name
		)
		
		# Check for boat sinking after condition updates
		check_boat_sinking(boat_name)
	
	# Remove any sunk boats from the iteration (they were removed in check_boat_sinking)
	# The game over check is handled in sink_boat() function
	
	# Fine check
	if days_since_cruise > 3 and not has_monthly_mooring:
		add_money(-CRUISE_FINE)
	
	if has_monthly_mooring:
		mooring_days_left -= 1
		if mooring_days_left <= 0:
			has_monthly_mooring = false
	
	day_passed.emit()

func add_money(amount: float):
	money += amount
	money_changed.emit(money)

func spend_money(amount: float) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false

func start_cruise_with_route(route_name: String):
	if is_working or is_cruising:
		return 0.0
	
	if not cruise_routes.has(route_name):
		route_name = "Standard Route"
	
	current_cruise_route = cruise_routes[route_name]
	is_cruising = true
	cruise_timer = get_cruise_duration(route_name)
	cruise_total_time = cruise_timer
	cruise_started.emit()
	return 0.0

func hire_mechanic() -> bool:
	var spec = boat_specs[current_boat]
	if not spec.can_hire_mechanic:
		return false
	
	if spend_money(mechanic_daily_cost):
		has_mechanic = true
		return true
	return false

func fire_mechanic():
	has_mechanic = false

func buy_monthly_mooring() -> bool:
	if spend_money(MONTHLY_MOORING_COST):
		has_monthly_mooring = true
		mooring_days_left = 30
		return true
	return false

func buy_upgrade(upgrade_name: String, cost: float) -> bool:
	if upgrade_name in boat_upgrades:
		return false
	
	if spend_money(cost):
		boat_upgrades.append(upgrade_name)
		upgrade_purchased.emit(upgrade_name)
		return true
	return false

func buy_boat_from_sale(boat_id: String) -> bool:
	if not boats_for_sale.has(boat_id):
		return false
	
	var boat_info = boats_for_sale[boat_id]
	if spend_money(boat_info.price):
		var boat_name = boat_info.name
		if not boat_name in owned_boats:
			owned_boats.append(boat_name)
		
		boat_conditions[boat_name] = boat_info.condition.duplicate()
		boats_for_sale.erase(boat_id)
		
		if owned_boats.size() == 2:
			print("You can now rent out boats for passive income!")
		
		return true
	return false

func switch_boat(boat_name: String) -> bool:
	if boat_name in owned_boats and not is_boat_rented(boat_name):
		current_boat = boat_name
		boat_changed.emit(boat_name)
		var condition = get_current_boat_condition()
		boat_condition_changed.emit(condition.overall)
		return true
	return false

func get_hours_until_fine() -> float:
	if has_monthly_mooring:
		return 999
	var days_left = 3 - days_since_cruise
	if days_left <= 0:
		return 0
	return days_left * 24 + (24 - current_hour) - (current_minute / 60.0)


class_name BoatCatalog
extends Node

# A compact catalog of boats with price, income, and style for rendering.
# style drives BoatRenderer's procedural drawing.
static func list() -> Array:
	return [
		{
			"id": "starter_dinghy",
			"name": "Plastic Dinghy",
			"price": 0,
			"base_income": 20.0,
			"multiplier": 1.0,
			"style": {
				"hull_color": Color.hex(0x5aa9e6ff),
				"cabin_color": Color.hex(0xdfe7fdff),
				"hull_length": 80,
				"hull_height": 14,
				"has_cabin": false,
				"has_mast": false,
				"has_flag": false,
				"window_count": 0
			}
		},
		{
			"id": "canal_narrowboat",
			"name": "Canal Narrowboat",
			"price": 450,
			"base_income": 35.0,
			"multiplier": 1.1,
			"style": {
				"hull_color": Color.hex(0x125b50ff),
				"cabin_color": Color.hex(0xfdebd0ff),
				"hull_length": 120,
				"hull_height": 18,
				"has_cabin": true,
				"has_mast": false,
				"has_flag": true,
				"window_count": 3
			}
		},
		{
			"id": "weekender_cruiser",
			"name": "Weekender Cruiser",
			"price": 1200,
			"base_income": 55.0,
			"multiplier": 1.25,
			"style": {
				"hull_color": Color.hex(0x3c91e6ff),
				"cabin_color": Color.hex(0xfff6d5ff),
				"hull_length": 140,
				"hull_height": 20,
				"has_cabin": true,
				"has_mast": false,
				"has_flag": true,
				"window_count": 4
			}
		},
		{
			"id": "sloop_sailor",
			"name": "Sloop Sailboat",
			"price": 2500,
			"base_income": 75.0,
			"multiplier": 1.45,
			"style": {
				"hull_color": Color.hex(0x305f72ff),
				"cabin_color": Color.hex(0xf2f2f2ff),
				"hull_length": 150,
				"hull_height": 18,
				"has_cabin": true,
				"has_mast": true,
				"has_flag": true,
				"window_count": 2
			}
		},
		{
			"id": "motor_yacht",
			"name": "Motor Yacht",
			"price": 6200,
			"base_income": 120.0,
			"multiplier": 1.8,
			"style": {
				"hull_color": Color.hex(0x1f3b4dff),
				"cabin_color": Color.hex(0xffffffff),
				"hull_length": 170,
				"hull_height": 24,
				"has_cabin": true,
				"has_mast": false,
				"has_flag": true,
				"window_count": 5
			}
		},
		{
			"id": "super_yacht",
			"name": "Super Yacht",
			"price": 25000,
			"base_income": 300.0,
			"multiplier": 2.5,
			"style": {
				"hull_color": Color.hex(0x0e1726ff),
				"cabin_color": Color.hex(0xf5f7ffff),
				"hull_length": 210,
				"hull_height": 26,
				"has_cabin": true,
				"has_mast": False,
				"has_flag": true,
				"window_count": 8
			}
		}
	]

static func get(boat_id: String) -> Dictionary:
	for b in list():
		if b.id == boat_id:
			return b
	return {}

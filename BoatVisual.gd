extends Sprite2D  # Note: Sprite2D in Godot 4, not Sprite

@export var base_texture: Texture2D
@export var damaged_texture: Texture2D
@export var upgraded_texture: Texture2D

var current_condition: float = 50.0

func _ready():
	GameManager.boat_condition_changed.connect(_on_condition_changed)
	update_visual()

func _on_condition_changed(new_condition):
	current_condition = new_condition
	update_visual()

func update_visual():
	if current_condition < 30:
		texture = damaged_texture
		modulate = Color(1, 0.8, 0.8)
	elif current_condition < 70:
		texture = base_texture
		modulate = Color.WHITE
	else:
		texture = upgraded_texture if upgraded_texture else base_texture
		modulate = Color(1, 1, 0.9)
// PROTOTYPE - NOT FOR PRODUCTION
// Question: Does the farming core loop feel satisfying?
// Date: 2026-04-08

extends Node2D
class_name FarmPlot

signal plot_clicked(plot: FarmPlot)

# Plot states: wasteland -> tilled -> planted -> growing -> harvestable
var state: String = "wasteland"
var watered: bool = false
var growth_days: int = 0
var max_growth_days: int = 0
var crop_type: String = ""
var grid_pos: Vector2i

# Visual
@onready var sprite = $Sprite2D
@onready var crop_sprite = $CropSprite

# Placeholder colors for different states
const STATE_COLORS = {
	"wasteland": Color(0.4, 0.3, 0.2),
	"tilled": Color(0.5, 0.35, 0.25),
	"planted": Color(0.5, 0.35, 0.25),
	"growing": Color(0.3, 0.5, 0.3),
	"harvestable": Color(0.2, 0.7, 0.2)
}

func _ready():
	sprite.modulate = STATE_COLORS["wasteland"]
	crop_sprite.visible = false

func _draw():
	# Draw grid cell border
	var rect = Rect2(-32, -32, 64, 64)
	draw_rect(rect, Color(0.2, 0.15, 0.1), false, 2.0)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Check if click is within this cell
			var local_pos = get_local_mouse_position()
			if abs(local_pos.x) < 32 and abs(local_pos.y) < 32:
				plot_clicked.emit(self)

func set_state(new_state: String):
	state = new_state
	sprite.modulate = STATE_COLORS.get(state, Color.WHITE)

func plant(type: String, days_to_grow: int):
	crop_type = type
	max_growth_days = days_to_grow
	growth_days = 0
	watered = false
	set_state("planted")
	_update_crop_visual()

func water():
	watered = true
	_update_crop_visual()

func _update_crop_visual():
	if crop_type == "":
		crop_sprite.visible = false
		return

	crop_sprite.visible = true

	# Visual representation based on growth stage
	match state:
		"planted":
			crop_sprite.scale = Vector2(0.3, 0.3)
			crop_sprite.modulate = Color(0.8, 0.6, 0.4)
		"growing":
			var progress = float(growth_days) / max_growth_days
			crop_sprite.scale = Vector2(0.3 + progress * 0.7, 0.3 + progress * 0.7)
			crop_sprite.modulate = Color(0.4 + progress * 0.4, 0.6 + progress * 0.3, 0.4)
		"harvestable":
			crop_sprite.scale = Vector2(1.0, 1.0)
			crop_sprite.modulate = Color(1.0, 0.3, 0.2) if watered else Color(0.7, 0.7, 0.3)
			# Add glow effect for harvestable
			crop_sprite.modulate = Color(1.0, 0.8, 0.3)

func process_day():
	if state == "harvestable":
		return  # Already ready

	if state in ["planted", "growing"]:
		if watered:
			growth_days += 1
			watered = false
			if growth_days >= max_growth_days:
				set_state("harvestable")
				_create_harvest_effect()
			else:
				set_state("growing")
		else:
			# Missed a day - visual indicator
			pass

	_update_crop_visual()

func harvest() -> bool:
	if state != "harvestable":
		return false

	# Reset plot
	state = "tilled"
	crop_type = ""
	growth_days = 0
	max_growth_days = 0
	watered = false
	crop_sprite.visible = false
	sprite.modulate = STATE_COLORS["tilled"]
	return true

func reset():
	state = "wasteland"
	watered = false
	growth_days = 0
	max_growth_days = 0
	crop_type = ""
	crop_sprite.visible = false
	sprite.modulate = STATE_COLORS["wasteland"]

func _create_harvest_effect():
	# Simple particle effect placeholder
	var tween = create_tween()
	var original_modulate = crop_sprite.modulate
	crop_sprite.modulate = Color(1.0, 1.0, 0.5)
	tween.tween_property(crop_sprite, "modulate", original_modulate, 0.5)

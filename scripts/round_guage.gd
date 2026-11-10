class_name RoundGauge
extends Control

@export var fill_color: Color = Color(0.8, 0.1, 0.1)
@export var back_color: Color = Color(0.08, 0.02, 0.02, 0.85)
@export var ring_color: Color = Color(0.7, 0.7, 0.7)
@export var font_size: int = 32

var ratio: float = 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		queue_redraw()

var text: String = "":
	set(value):
		text = value
		queue_redraw()


func _draw() -> void:
	var center: Vector2 = size / 2.0
	var radius: float = minf(size.x, size.y) / 2.0 - 3.0
	draw_circle(center, radius, back_color)
	if ratio > 0.0:
		draw_arc(center, radius * 0.5, -PI / 2.0, -PI / 2.0 + TAU * ratio, 48, fill_color, radius)
	draw_arc(center, radius, 0.0, TAU, 48, ring_color, 3.0)
	if text != "":
		var font: Font = ThemeDB.fallback_font
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var baseline: float = center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
		draw_string(font, Vector2(center.x - text_size.x / 2.0, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

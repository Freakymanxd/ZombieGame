extends Node2D

@export var cursor_image: Texture2D
## Final cursor size in pixels (max 256 x 256)
@export var cursor_size: Vector2i = Vector2i(32, 32)


func _ready() -> void:
	if cursor_image == null:
		push_error("Cursor: assign an image in the Inspector.")
		return

	var img: Image = cursor_image.get_image()
	if img.is_compressed():
		img.decompress()

	img.resize(cursor_size.x, cursor_size.y, Image.INTERPOLATE_LANCZOS)
	var tex := ImageTexture.create_from_image(img)

	# Hotspot = centre of the cursor, right for a crosshair
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2(cursor_size) / 2.0)

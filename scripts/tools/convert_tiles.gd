@tool
extends EditorScript

# Converts the design team's 1080x1080 tile images into game-ready tiles.
# Put originals in res://assets/tiles_raw/ and run this script.
const RAW_DIR: String = "res://assets/tiles_raw/"
const OUT_DIR: String = "res://assets/tiles/"
const SOURCE_SIZE: Vector2i = Vector2i(1080, 1080)
const CROP: Rect2i = Rect2i(122, 424, 836, 470)
const OUT_SIZE: Vector2i = Vector2i(256, 144)
const EXTENSIONS: Array[String] = ["png", "webp", "jpg", "jpeg"]


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var dir: DirAccess = DirAccess.open(RAW_DIR)
	if dir == null:
		push_error("Folder not found: " + RAW_DIR)
		return
	var done: int = 0
	for file_name in dir.get_files():
		if not EXTENSIONS.has(file_name.get_extension().to_lower()):
			continue
		var img: Image = Image.load_from_file(RAW_DIR + file_name)
		if img == null:
			push_warning("Could not read " + file_name)
			continue
		if img.get_size() != SOURCE_SIZE:
			push_warning("%s is %s, expected %s. Skipped." % [file_name, img.get_size(), SOURCE_SIZE])
			continue
		img.convert(Image.FORMAT_RGBA8)
		var tile: Image = img.get_region(CROP)
		tile.resize(OUT_SIZE.x, OUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
		tile.save_png(OUT_DIR + file_name.get_basename() + ".png")
		done += 1
	print("Converted ", done, " tile(s) into ", OUT_DIR)
	EditorInterface.get_resource_filesystem().scan()

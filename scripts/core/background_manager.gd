class_name BackgroundManager

static var _texture_cache: Dictionary = {}

const PORTRAIT_BG: Dictionary = {
	"main_menu": "res://assets/images/ui/main/main_bg.jpg",
	"book_shelf": "res://assets/images/ui/bookshelf/bookshelf_bg.jpg",
	"album_detail": "res://assets/images/ui/album/album_bg.jpg",
	"nonogram": "res://assets/images/ui/nonogram/nonogram_bg.jpg",
}

const LANDSCAPE_BG: Dictionary = {
	"main_menu": "res://assets/images/ui/main/main_bg_landscape.jpg",
	"book_shelf": "res://assets/images/ui/bookshelf/bookshelf_bg_landscape.jpg",
	"album_detail": "res://assets/images/ui/album/album_bg_landscape.jpg",
	"nonogram": "res://assets/images/ui/nonogram/nonogram_bg_landscape.jpg",
}

static func get_bg_path(scene_key: String, orientation: int) -> String:
	var dict: Dictionary
	if orientation == 0:
		dict = PORTRAIT_BG
	else:
		dict = LANDSCAPE_BG
	var path = dict.get(scene_key, "")
	if path == "" or not ResourceLoader.exists(path):
		if orientation != 0:
			path = PORTRAIT_BG.get(scene_key, "")
	return path

static func _get_cached_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	var tex: Texture2D = load(path)
	if tex:
		_texture_cache[path] = tex
	return tex

static func apply_background(texture_rect: TextureRect, scene_key: String, orientation: int) -> void:
	if not texture_rect:
		return
	var path = get_bg_path(scene_key, orientation)
	var tex = _get_cached_texture(path)
	if tex:
		texture_rect.texture = tex

static func apply_background_with_transition(texture_rect: TextureRect, scene_key: String, orientation: int, tween_node: Node) -> void:
	if not texture_rect:
		return
	var path = get_bg_path(scene_key, orientation)
	var new_tex = _get_cached_texture(path)
	if not new_tex:
		return
	if not tween_node or not tween_node.is_inside_tree():
		texture_rect.texture = new_tex
		return
	var existing_tween = texture_rect.get_meta("_bg_tween", null) as Tween
	if existing_tween and existing_tween.is_valid():
		existing_tween.kill()
	var tween = tween_node.create_tween()
	texture_rect.set_meta("_bg_tween", tween)
	tween.tween_property(texture_rect, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): texture_rect.texture = new_tex)
	tween.tween_property(texture_rect, "modulate:a", 1.0, 0.2)

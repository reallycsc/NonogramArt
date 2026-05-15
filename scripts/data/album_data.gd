class_name AlbumData

var _albums_cache: Dictionary = {}
var _albums_cache_valid: bool = false
var _pictures_cache: Dictionary = {}
var _raw_json_cache: Dictionary = {}
var _raw_json_valid: bool = false
var _album_by_id_cache: Dictionary = {}
var _album_images_valid_cache: Dictionary = {}

static var _instance: AlbumData = null


static func _get_instance() -> AlbumData:
	if _instance == null:
		_instance = AlbumData.new()
	return _instance


static func invalidate_cache(album_id: String = "") -> void:
	var inst = _get_instance()
	if album_id == "":
		inst._albums_cache.clear()
		inst._albums_cache_valid = false
		inst._pictures_cache.clear()
		inst._raw_json_cache.clear()
		inst._raw_json_valid = false
		inst._album_by_id_cache.clear()
	else:
		inst._pictures_cache.erase(album_id)


static func _load_albums_json() -> Dictionary:
	var inst = _get_instance()
	if inst._raw_json_valid:
		return inst._raw_json_cache
	var path = "res://data/albums.json"
	if not FileAccess.file_exists(path):
		push_error("AlbumData: albums.json not found at " + path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("AlbumData: Failed to open " + path)
		return {}
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("AlbumData: JSON parse error in " + path + " - " + json.get_error_message())
		return {}
	var data = json.data
	if not data is Dictionary:
		push_error("AlbumData: Root data is not a Dictionary in " + path)
		return {}
	inst._raw_json_cache = data
	inst._raw_json_valid = true
	return data


static func load_albums(bookshelf_id: String = "") -> Array:
	var inst = _get_instance()
	if inst._albums_cache_valid and inst._albums_cache.has(bookshelf_id):
		return inst._albums_cache[bookshelf_id]
	var data = _load_albums_json()
	if data.is_empty():
		return []
	var albums_array = data.get("albums", [])
	if not albums_array is Array:
		push_error("AlbumData: 'albums' is not an Array in albums.json")
		return []
	var result: Array = []
	for album in albums_array:
		if not album is Dictionary:
			continue
		if not album.has("id"):
			push_warning("AlbumData: Album entry missing 'id' field, skipping")
			continue
		if bookshelf_id != "" and album.get("bookshelf_id", "") != bookshelf_id:
			continue
		if not _check_album_images(album.get("id", "")):
			continue
		result.append(album)
	result.sort_custom(func(a, b): return a.get("order", 0) < b.get("order", 0))
	inst._albums_cache[bookshelf_id] = result
	inst._albums_cache_valid = true
	return result


static func _check_album_images(album_id: String) -> bool:
	var inst = _get_instance()
	if inst._album_images_valid_cache.has(album_id):
		return inst._album_images_valid_cache[album_id]
	var pictures = load_pictures(album_id)
	if pictures.is_empty():
		inst._album_images_valid_cache[album_id] = false
		return false
	for picture in pictures:
		var img_path: String = picture.get("image", "")
		if img_path == "" or not ResourceLoader.exists(img_path):
			inst._album_images_valid_cache[album_id] = false
			return false
		var pixel_path: String = picture.get("pixel_image", "")
		if pixel_path == "" or not ResourceLoader.exists(pixel_path):
			inst._album_images_valid_cache[album_id] = false
			return false
	inst._album_images_valid_cache[album_id] = true
	return true


static func preload_album_images_check(album_ids: Array) -> void:
	var inst = _get_instance()
	for album_id in album_ids:
		if inst._album_images_valid_cache.has(album_id):
			continue
		_check_album_images(album_id)


static func get_album(album_id: String) -> Dictionary:
	var inst = _get_instance()
	if inst._album_by_id_cache.has(album_id):
		return inst._album_by_id_cache[album_id]
	var data = _load_albums_json()
	if data.is_empty():
		return {}
	var albums_array = data.get("albums", [])
	if not albums_array is Array:
		return {}
	for album in albums_array:
		if album is Dictionary and album.get("id", "") == album_id:
			inst._album_by_id_cache[album_id] = album
			return album
	inst._album_by_id_cache[album_id] = {}
	return {}


static func load_pictures(album_id: String) -> Array:
	var inst = _get_instance()
	if inst._pictures_cache.has(album_id):
		return inst._pictures_cache[album_id]
	var path = "res://data/pictures/" + album_id + ".json"
	if not FileAccess.file_exists(path):
		push_warning("AlbumData: Picture file not found at " + path)
		return []
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("AlbumData: Failed to open " + path)
		return []
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("AlbumData: JSON parse error in " + path + " - " + json.get_error_message())
		return []
	var data = json.data
	if not data is Dictionary:
		push_error("AlbumData: Root data is not a Dictionary in " + path)
		return []
	var pictures = data.get("pictures", [])
	if not pictures is Array:
		push_error("AlbumData: 'pictures' is not an Array in " + path)
		return []
	pictures.sort_custom(func(a, b): return a.get("order", 0) < b.get("order", 0))
	inst._pictures_cache[album_id] = pictures
	return pictures


static func get_picture(album_id: String, picture_id: String) -> Dictionary:
	var pictures = load_pictures(album_id)
	for picture in pictures:
		if picture.get("id", "") == picture_id:
			return picture
	return {}


static func get_all_album_ids() -> Array:
	var data = _load_albums_json()
	if data.is_empty():
		return []
	var albums_array = data.get("albums", [])
	var ids: Array = []
	for album in albums_array:
		if album is Dictionary and album.has("id"):
			ids.append(album["id"])
	return ids

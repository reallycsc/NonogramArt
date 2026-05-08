class_name BookshelfData

var _cache: Dictionary = {}
var _cache_valid: bool = false

static var _instance: BookshelfData = null


static func _get_instance() -> BookshelfData:
	if _instance == null:
		_instance = BookshelfData.new()
	return _instance


static func invalidate_cache() -> void:
	var inst = _get_instance()
	inst._cache.clear()
	inst._cache_valid = false


static func _load_albums_json() -> Dictionary:
	return AlbumData._load_albums_json()


static func load_bookshelves() -> Dictionary:
	var inst = _get_instance()
	if inst._cache_valid and not inst._cache.is_empty():
		return inst._cache
	var data = _load_albums_json()
	if data.is_empty():
		return {}
	var bookshelves_array = data.get("bookshelves", [])
	if not bookshelves_array is Array:
		push_error("BookshelfData: 'bookshelves' is not an Array in albums.json")
		return {}
	var result: Dictionary = {}
	for bookshelf in bookshelves_array:
		if not bookshelf is Dictionary:
			continue
		if not bookshelf.has("id"):
			push_warning("BookshelfData: Bookshelf entry missing 'id' field, skipping")
			continue
		result[bookshelf["id"]] = bookshelf
	inst._cache = result
	inst._cache_valid = true
	return result


static func get_bookshelf_list() -> Array:
	var bookshelves_dict = load_bookshelves()
	var bookshelf_array: Array = []
	for key in bookshelves_dict:
		bookshelf_array.append(bookshelves_dict[key])
	bookshelf_array.sort_custom(func(a, b): return a.get("order", 0) < b.get("order", 0))
	return bookshelf_array


static func get_bookshelf(bookshelf_id: String) -> Dictionary:
	var bookshelves = load_bookshelves()
	return bookshelves.get(bookshelf_id, {})

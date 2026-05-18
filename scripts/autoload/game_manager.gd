extends Node

signal bookshelf_unlocked(bookshelf_id: String)
signal puzzle_completed(puzzle_id: String)
signal picture_completed(picture_id: String)
signal album_completed(album_id: String)
signal progress_changed
signal language_changed(language: int)

signal nonogram_cell_updated(x: int, y: int, state: int)
signal nonogram_cell_finished(x: int, y: int)
signal nonogram_rowHint_is_only_one_pattern(index: int)
signal nonogram_rowHint_deducible(index: int, is_deducible: bool)
signal nonogram_rowHint_finished(index: int)
signal nonogram_rowHint_error(index: int, is_error: bool)
signal nonogram_colHint_is_only_one_pattern(index: int)
signal nonogram_colHint_deducible(index: int, is_deducible: bool)
signal nonogram_colHint_finished(index: int)
signal nonogram_colHint_error(index: int, is_error: bool)
signal nonogram_game_completed
signal nonogram_life_updated(life: int, x: int, y: int)
signal nonogram_game_over

enum Language { CHINESE, ENGLISH }
enum SourceScene { NONOGRAM, PICTURE, ALBUM }

const BookshelfDataScript = preload("res://scripts/data/bookshelf_data.gd")
const AlbumDataScript = preload("res://scripts/data/album_data.gd")

const UNLOCK_THRESHOLD := 0.5

var album_progress: Dictionary = {}
var completed_puzzles: Array = []
var completed_pictures: Array = []
var completed_albums: Array = []
var animation_shown_pictures: Array = []
var album_picture_index: Dictionary = {}
var settings: Dictionary = {
	"bgm_volume": 0.8,
	"sfx_volume": 1.0,
	"show_errors": true,
	"auto_mark": true,
	"auto_rotate": true,
}

var test_mode: bool = true

var pending_bookshelf_id: String = ""
var pending_album_id: String = ""
var pending_picture_id: String = ""
var pending_picture_index: int = -1
var pending_puzzle_id: String = ""

var current_language: int = Language.CHINESE
var current_level_id: int = 1

var _save_path: String = "user://save_game.json"
var _completion_cache_valid: bool = false
var _album_completion_cache: Dictionary = {}
var _picture_completion_cache: Dictionary = {}
var _bookshelf_completion_cache: Dictionary = {}
var _total_completion_cache: float = -1.0
var _puzzle_to_album_map: Dictionary = {}
var _puzzle_to_picture_map: Dictionary = {}
var _picture_to_album_map: Dictionary = {}
var _album_puzzle_counts: Dictionary = {}
var _album_done_counts: Dictionary = {}
var _picture_puzzle_counts: Dictionary = {}
var _picture_done_counts: Dictionary = {}

var _album_icon_cache: Dictionary = {}
var _album_icon_grey_cache: Dictionary = {}
var _album_unlock_cache: Dictionary = {}

var data_preloaded: bool = false
signal preload_progress(step: int, total: int, description: String)
signal preload_finished

var _scene_preload_requests: Dictionary = {}

func _ready() -> void:
	load_game()
	if OrientationManager:
		OrientationManager.set_auto_rotate(settings.get("auto_rotate", true))


func preload_all_data() -> void:
	if data_preloaded:
		preload_finished.emit()
		return

	preload_progress.emit(0, 100, "加载书架数据...")
	BookshelfDataScript.load_bookshelves()
	await get_tree().process_frame

	preload_progress.emit(5, 100, "加载相册数据...")
	var album_ids = AlbumDataScript.get_all_album_ids()
	var album_count = album_ids.size()
	for i in range(album_count):
		AlbumDataScript.load_pictures(album_ids[i])
		if i % 5 == 4 or i == album_count - 1:
			var pct = 5 + int(float(i + 1) / float(album_count) * 55.0)
			preload_progress.emit(pct, 100, "加载相册数据... %d%%" % int(float(i + 1) / float(album_count) * 100))
			await get_tree().process_frame

	preload_progress.emit(65, 100, "构建关卡索引...")
	PuzzleData.build_puzzle_index()
	await get_tree().process_frame

	preload_progress.emit(70, 100, "计算完成度...")
	await _build_completion_cache_async()
	await get_tree().process_frame

	preload_progress.emit(80, 100, "生成图标...")
	_preload_album_icons(album_ids)
	await get_tree().process_frame

	preload_progress.emit(90, 100, "检查解锁状态...")
	_preload_album_unlock_status(album_ids)
	await get_tree().process_frame

	preload_progress.emit(100, 100, "准备就绪")
	await get_tree().process_frame

	data_preloaded = true
	preload_finished.emit()
	preload_scene("res://scenes/book_shelf.tscn")


func preload_scene(scene_path: String) -> void:
	if _scene_preload_requests.has(scene_path):
		return
	if not ResourceLoader.exists(scene_path):
		return
	var err = ResourceLoader.load_threaded_request(scene_path)
	if err == OK:
		_scene_preload_requests[scene_path] = true


func is_scene_preloaded(scene_path: String) -> bool:
	if not _scene_preload_requests.has(scene_path):
		return false
	var status = ResourceLoader.load_threaded_get_status(scene_path)
	return status == ResourceLoader.THREAD_LOAD_LOADED


func _preload_album_icons(album_ids: Array) -> void:
	var album_colors = _get_album_color_map()
	for album_id in album_ids:
		if _album_icon_cache.has(album_id):
			continue
		var album = AlbumDataScript.get_album(album_id)
		var icon_path = album.get("icon", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			_album_icon_cache[album_id] = load(icon_path)
		else:
			_album_icon_cache[album_id] = _generate_album_icon(album_id, album_colors)


func _preload_album_unlock_status(album_ids: Array) -> void:
	for album_id in album_ids:
		if _album_unlock_cache.has(album_id):
			continue
		_album_unlock_cache[album_id] = is_album_unlocked(album_id)


func get_album_icon(album_id: String) -> Texture2D:
	if _album_icon_cache.has(album_id):
		return _album_icon_cache[album_id]
	var album = AlbumDataScript.get_album(album_id)
	var icon_path = album.get("icon", "")
	var tex: Texture2D = null
	if icon_path != "" and ResourceLoader.exists(icon_path):
		tex = load(icon_path)
	else:
		tex = _generate_album_icon(album_id, _get_album_color_map())
	_album_icon_cache[album_id] = tex
	return tex


func get_album_icon_grey(album_id: String) -> Texture2D:
	if _album_icon_grey_cache.has(album_id):
		return _album_icon_grey_cache[album_id]
	var album = AlbumDataScript.get_album(album_id)
	var icon_path = album.get("icon", "")
	var grey_path = icon_path.get_basename() + "_grey.png"
	var tex: Texture2D = null
	if grey_path != "" and ResourceLoader.exists(grey_path):
		tex = load(grey_path)
	else:
		tex = get_album_icon(album_id)
	_album_icon_grey_cache[album_id] = tex
	return tex


func get_album_unlock_status(album_id: String) -> Dictionary:
	if test_mode:
		return {"unlocked": true, "reason": "test_mode"}
	if _album_unlock_cache.has(album_id):
		return _album_unlock_cache[album_id]
	var result = is_album_unlocked(album_id)
	_album_unlock_cache[album_id] = result
	return result


func _get_album_color_map() -> Dictionary:
	return {
		"chinese_history": Color(0.76, 0.23, 0.13),
		"world_history": Color(0.6, 0.3, 0.2),
		"mammals": Color(0.6, 0.4, 0.2),
		"birds": Color(0.3, 0.6, 0.3),
		"reptiles": Color(0.4, 0.5, 0.2),
		"fish": Color(0.2, 0.5, 0.7),
		"insects": Color(0.5, 0.4, 0.2),
		"trees": Color(0.2, 0.5, 0.2),
		"flowers": Color(0.8, 0.3, 0.5),
		"crops": Color(0.6, 0.5, 0.2),
		"fungi": Color(0.5, 0.4, 0.3),
		"ecosystems": Color(0.2, 0.6, 0.4),
		"food": Color(0.8, 0.5, 0.2),
		"fashion": Color(0.7, 0.3, 0.5),
		"architecture": Color(0.5, 0.4, 0.3),
		"crafts": Color(0.6, 0.3, 0.4),
		"photography": Color(0.3, 0.3, 0.4),
		"sculpture": Color(0.5, 0.5, 0.5),
		"design": Color(0.4, 0.3, 0.6),
		"abstract": Color(0.6, 0.2, 0.6),
		"symbols": Color(0.4, 0.4, 0.6),
		"textures": Color(0.5, 0.5, 0.4),
		"miscellaneous": Color(0.5, 0.5, 0.5),
		"sports": Color(0.3, 0.5, 0.3),
		"health": Color(0.3, 0.6, 0.3),
		"astronomy": Color(0.2, 0.2, 0.5),
		"energy": Color(0.6, 0.4, 0.1),
		"education": Color(0.3, 0.4, 0.5),
		"entertainment": Color(0.6, 0.3, 0.5),
		"festivals": Color(0.7, 0.3, 0.2),
		"religion": Color(0.5, 0.4, 0.3),
		"family": Color(0.5, 0.4, 0.5),
		"workplace": Color(0.4, 0.4, 0.4),
		"housing": Color(0.5, 0.4, 0.3),
		"war_military": Color(0.4, 0.3, 0.3),
		"math_physics": Color(0.3, 0.3, 0.5),
		"geology": Color(0.5, 0.4, 0.3),
		"paleontology": Color(0.5, 0.4, 0.3),
		"rivers_lakes": Color(0.2, 0.4, 0.6),
		"plains_basins": Color(0.5, 0.5, 0.3),
		"deserts_gobi": Color(0.7, 0.5, 0.3),
		"atmosphere": Color(0.4, 0.5, 0.6),
	}


func _generate_album_icon(a_id: String, album_colors: Dictionary) -> ImageTexture:
	var color = album_colors.get(a_id, Color(0.5, 0.5, 0.5))
	var size = 56
	var radius = 22
	var icon = Image.create(size, size, false, Image.FORMAT_RGBA8)
	icon.fill(Color(0.96, 0.94, 0.91))
	var r2 = radius * radius
	var min_y = 28 - radius
	var max_y = 28 + radius
	for y in range(max(0, min_y), min(size, max_y + 1)):
		var dy = y - 28
		var dx_max = sqrt(r2 - dy * dy)
		var x_start = int(28 - dx_max)
		var x_end = int(28 + dx_max)
		x_start = max(0, x_start)
		x_end = min(size - 1, x_end)
		if x_start <= x_end:
			icon.fill_rect(Rect2i(x_start, y, x_end - x_start + 1, 1), color)
	return ImageTexture.create_from_image(icon)


func _build_completion_cache_async() -> void:
	if _completion_cache_valid:
		return
	_completion_cache_valid = true
	_puzzle_to_album_map.clear()
	_puzzle_to_picture_map.clear()
	_picture_to_album_map.clear()
	_album_puzzle_counts.clear()
	_album_done_counts.clear()
	_picture_puzzle_counts.clear()
	_picture_done_counts.clear()
	_album_completion_cache.clear()
	_picture_completion_cache.clear()
	_bookshelf_completion_cache.clear()
	_total_completion_cache = -1.0

	var bookshelves = BookshelfDataScript.get_bookshelf_list()
	var valid_album_ids: Array = []
	var batch_idx: int = 0

	for bookshelf in bookshelves:
		var bs_id: String = bookshelf["id"]
		var albums = AlbumDataScript.load_albums(bs_id)
		for album in albums:
			valid_album_ids.append(album["id"])

	for album_id in valid_album_ids:
		var album_total: int = 0
		var album_done: int = 0
		var pictures = AlbumDataScript.load_pictures(album_id)
		for picture in pictures:
			var pic_id = picture.get("id", "")
			_picture_to_album_map[pic_id] = album_id
			var puzzles = picture.get("puzzles", [])
			var pic_total: int = puzzles.size()
			var pic_done: int = 0
			for pid in puzzles:
				_puzzle_to_album_map[pid] = album_id
				_puzzle_to_picture_map[pid] = pic_id
				if pid in completed_puzzles:
					pic_done += 1
			_picture_puzzle_counts[pic_id] = pic_total
			_picture_done_counts[pic_id] = pic_done
			if pic_total > 0:
				_picture_completion_cache[pic_id] = float(pic_done) / float(pic_total)
			else:
				_picture_completion_cache[pic_id] = 0.0
			album_total += pic_total
			album_done += pic_done
		_album_puzzle_counts[album_id] = album_total
		_album_done_counts[album_id] = album_done
		if album_total > 0:
			_album_completion_cache[album_id] = float(album_done) / float(album_total)
		else:
			_album_completion_cache[album_id] = 0.0
		batch_idx += 1
		if batch_idx % 5 == 0:
			await get_tree().process_frame

	var grand_total: int = 0
	var grand_done: int = 0
	for bookshelf in bookshelves:
		var bs_id: String = bookshelf["id"]
		var bs_total: int = 0
		var bs_done: int = 0
		var albums = AlbumDataScript.load_albums(bs_id)
		for album in albums:
			var a_id: String = album["id"]
			bs_total += _album_puzzle_counts.get(a_id, 0)
			bs_done += _album_done_counts.get(a_id, 0)
		if bs_total > 0:
			_bookshelf_completion_cache[bs_id] = float(bs_done) / float(bs_total)
		else:
			_bookshelf_completion_cache[bs_id] = 0.0
		grand_total += bs_total
		grand_done += bs_done
	if grand_total > 0:
		_total_completion_cache = float(grand_done) / float(grand_total)
	else:
		_total_completion_cache = 0.0


func _build_completion_cache() -> void:
	if _completion_cache_valid:
		return
	_completion_cache_valid = true
	_puzzle_to_album_map.clear()
	_puzzle_to_picture_map.clear()
	_picture_to_album_map.clear()
	_album_puzzle_counts.clear()
	_album_done_counts.clear()
	_picture_puzzle_counts.clear()
	_picture_done_counts.clear()
	_album_completion_cache.clear()
	_picture_completion_cache.clear()
	_bookshelf_completion_cache.clear()
	_total_completion_cache = -1.0

	var bookshelves = BookshelfDataScript.get_bookshelf_list()
	var valid_album_ids: Array = []

	for bookshelf in bookshelves:
		var bs_id: String = bookshelf["id"]
		var albums = AlbumDataScript.load_albums(bs_id)
		for album in albums:
			valid_album_ids.append(album["id"])

	for album_id in valid_album_ids:
		var album_total: int = 0
		var album_done: int = 0
		var pictures = AlbumDataScript.load_pictures(album_id)
		for picture in pictures:
			var pic_id = picture.get("id", "")
			_picture_to_album_map[pic_id] = album_id
			var puzzles = picture.get("puzzles", [])
			var pic_total: int = puzzles.size()
			var pic_done: int = 0
			for pid in puzzles:
				_puzzle_to_album_map[pid] = album_id
				_puzzle_to_picture_map[pid] = pic_id
				if pid in completed_puzzles:
					pic_done += 1
			_picture_puzzle_counts[pic_id] = pic_total
			_picture_done_counts[pic_id] = pic_done
			if pic_total > 0:
				_picture_completion_cache[pic_id] = float(pic_done) / float(pic_total)
			else:
				_picture_completion_cache[pic_id] = 0.0
			album_total += pic_total
			album_done += pic_done
		_album_puzzle_counts[album_id] = album_total
		_album_done_counts[album_id] = album_done
		if album_total > 0:
			_album_completion_cache[album_id] = float(album_done) / float(album_total)
		else:
			_album_completion_cache[album_id] = 0.0

	var grand_total: int = 0
	var grand_done: int = 0
	for bookshelf in bookshelves:
		var bs_id = bookshelf["id"]
		var bs_total: int = 0
		var bs_done: int = 0
		var albums = AlbumDataScript.load_albums(bs_id)
		for album in albums:
			var a_id = album["id"]
			bs_total += _album_puzzle_counts.get(a_id, 0)
			bs_done += _album_done_counts.get(a_id, 0)
		if bs_total > 0:
			_bookshelf_completion_cache[bs_id] = float(bs_done) / float(bs_total)
		else:
			_bookshelf_completion_cache[bs_id] = 0.0
		grand_total += bs_total
		grand_done += bs_done
	if grand_total > 0:
		_total_completion_cache = float(grand_done) / float(grand_total)
	else:
		_total_completion_cache = 0.0


func invalidate_completion_cache() -> void:
	_completion_cache_valid = false
	_album_unlock_cache.clear()


func is_album_unlocked(album_id: String) -> Dictionary:
	var album = AlbumDataScript.get_album(album_id)
	if album.is_empty():
		return {"unlocked": false, "reason": "not_found"}
	var unlock_condition = album.get("unlock_condition", null)
	if unlock_condition == null:
		return {"unlocked": true, "reason": "no_condition"}
	if unlock_condition is String and unlock_condition.begins_with("complete_album:"):
		var required_album = unlock_condition.split(":")[1]
		if required_album in completed_albums:
			return {"unlocked": true, "reason": "condition_met"}
		return {"unlocked": false, "reason": "need_album", "required": required_album}
	return {"unlocked": true, "reason": "unknown_condition"}


func is_bookshelf_unlocked(bookshelf_id: String) -> bool:
	var albums = AlbumDataScript.load_albums(bookshelf_id)
	for album in albums:
		var result = is_album_unlocked(album["id"])
		if result.unlocked:
			return true
	return false


func complete_puzzle(puzzle_id: String) -> void:
	if puzzle_id in completed_puzzles:
		return
	completed_puzzles.append(puzzle_id)
	puzzle_completed.emit(puzzle_id)
	_increment_completion(puzzle_id)
	progress_changed.emit()
	_check_picture_completion(puzzle_id)
	_check_album_unlock()
	save_game()


func _increment_completion(puzzle_id: String) -> void:
	if not _completion_cache_valid:
		return
	var album_id = _puzzle_to_album_map.get(puzzle_id, "")
	var picture_id = _puzzle_to_picture_map.get(puzzle_id, "")
	if picture_id != "":
		var pic_done = _picture_done_counts.get(picture_id, 0) + 1
		var pic_total = _picture_puzzle_counts.get(picture_id, 1)
		_picture_done_counts[picture_id] = pic_done
		_picture_completion_cache[picture_id] = float(pic_done) / float(pic_total) if pic_total > 0 else 0.0
	if album_id != "":
		var alb_done = _album_done_counts.get(album_id, 0) + 1
		var alb_total = _album_puzzle_counts.get(album_id, 1)
		_album_done_counts[album_id] = alb_done
		_album_completion_cache[album_id] = float(alb_done) / float(alb_total) if alb_total > 0 else 0.0
	_total_completion_cache = -1.0
	_bookshelf_completion_cache.clear()
	_album_unlock_cache.erase(album_id)


func complete_picture(picture_id: String) -> void:
	if picture_id in completed_pictures:
		return
	completed_pictures.append(picture_id)
	picture_completed.emit(picture_id)
	progress_changed.emit()
	_check_album_completion(picture_id)
	save_game()


func complete_album(album_id: String) -> void:
	if album_id in completed_albums:
		return
	completed_albums.append(album_id)
	album_completed.emit(album_id)
	progress_changed.emit()
	_check_album_unlock()
	_album_unlock_cache.clear()
	save_game()


func is_puzzle_completed(puzzle_id: String) -> bool:
	return puzzle_id in completed_puzzles


func is_picture_completed(picture_id: String) -> bool:
	return picture_id in completed_pictures


func should_show_animation(picture_id: String) -> bool:
	return picture_id in completed_pictures and not picture_id in animation_shown_pictures


func mark_animation_shown(picture_id: String) -> void:
	if not picture_id in animation_shown_pictures:
		animation_shown_pictures.append(picture_id)
		save_game()


func save_picture_index(album_id: String, index: int) -> void:
	album_picture_index[album_id] = index
	save_game()


func get_saved_picture_index(album_id: String) -> int:
	return album_picture_index.get(album_id, -1)


func is_album_completed(album_id: String) -> bool:
	return album_id in completed_albums


func get_album_completion(album_id: String) -> float:
	_build_completion_cache()
	return _album_completion_cache.get(album_id, 0.0)


func get_picture_completion(picture_id: String) -> float:
	_build_completion_cache()
	return _picture_completion_cache.get(picture_id, 0.0)


func get_bookshelf_completion(bookshelf_id: String) -> float:
	_build_completion_cache()
	if _bookshelf_completion_cache.has(bookshelf_id):
		return _bookshelf_completion_cache[bookshelf_id]
	var albums = AlbumDataScript.load_albums(bookshelf_id)
	var total: int = 0
	var done: int = 0
	for album in albums:
		total += _album_puzzle_counts.get(album["id"], 0)
		done += _album_done_counts.get(album["id"], 0)
	var result = float(done) / float(total) if total > 0 else 0.0
	_bookshelf_completion_cache[bookshelf_id] = result
	return result


func get_total_completion() -> float:
	_build_completion_cache()
	if _total_completion_cache >= 0.0:
		return _total_completion_cache
	var grand_total: int = 0
	var grand_done: int = 0
	for album_id in _album_puzzle_counts:
		grand_total += _album_puzzle_counts[album_id]
		grand_done += _album_done_counts[album_id]
	_total_completion_cache = float(grand_done) / float(grand_total) if grand_total > 0 else 0.0
	return _total_completion_cache


func get_level_data_by_id(_level_id: int) -> Dictionary:
	if NonogramManager.current_puzzle:
		var puzzle = NonogramManager.current_puzzle
		return {
			"memory_name": puzzle.name,
			"memory_name_en": puzzle.name,
		}
	return {"memory_name": "", "memory_name_en": ""}


func _check_picture_completion(puzzle_id: String) -> void:
	_build_completion_cache()
	var picture_id = _puzzle_to_picture_map.get(puzzle_id, "")
	if picture_id == "" or picture_id in completed_pictures:
		return
	var all_done = true
	var puzzles = []
	var album_id = _puzzle_to_album_map.get(puzzle_id, "")
	if album_id != "":
		var pictures = AlbumDataScript.load_pictures(album_id)
		for picture in pictures:
			if picture.get("id", "") == picture_id:
				puzzles = picture.get("puzzles", [])
				break
	for pid in puzzles:
		if not pid in completed_puzzles:
			all_done = false
			break
	if all_done:
		complete_picture(picture_id)


func _check_album_completion(picture_id: String) -> void:
	_build_completion_cache()
	var album_id = _picture_to_album_map.get(picture_id, "")
	if album_id == "" or album_id in completed_albums:
		return
	var pictures = AlbumDataScript.load_pictures(album_id)
	var all_done = true
	for pic in pictures:
		if not pic.get("id", "") in completed_pictures:
			all_done = false
			break
	if all_done:
		complete_album(album_id)


func _check_album_unlock() -> void:
	var album_ids = AlbumDataScript.get_all_album_ids()
	for album_id in album_ids:
		if album_id in completed_albums:
			continue
		var result = is_album_unlocked(album_id)
		if not result.unlocked and result.get("reason", "") == "need_album":
			var required = result.get("required", "")
			if required in completed_albums:
				progress_changed.emit()


func save_game() -> void:
	var data = {
		"version": 5,
		"album_progress": album_progress,
		"completed_puzzles": completed_puzzles,
		"completed_pictures": completed_pictures,
		"completed_albums": completed_albums,
		"animation_shown_pictures": animation_shown_pictures,
		"album_picture_index": album_picture_index,
		"settings": settings,
	}
	var file = FileAccess.open(_save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_game() -> void:
	if not FileAccess.file_exists(_save_path):
		_ensure_default_progress()
		return
	var file = FileAccess.open(_save_path, FileAccess.READ)
	if not file:
		_ensure_default_progress()
		return
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("GameManager: Failed to parse save file, using defaults")
		_ensure_default_progress()
		return
	var data = json.data
	if not data is Dictionary:
		_ensure_default_progress()
		return
	var version = data.get("version", 1)
	completed_puzzles = _ensure_array(data.get("completed_puzzles", []))
	completed_pictures = _ensure_array(data.get("completed_pictures", []))
	completed_albums = _ensure_array(data.get("completed_albums", []))
	animation_shown_pictures = _ensure_array(data.get("animation_shown_pictures", []))
	album_picture_index = data.get("album_picture_index", {})
	if not album_picture_index is Dictionary:
		album_picture_index = {}
	album_progress = data.get("album_progress", {})
	var loaded_settings = data.get("settings", {})
	if loaded_settings is Dictionary:
		for key in settings:
			if loaded_settings.has(key):
				settings[key] = loaded_settings[key]
	if version < 3:
		_migrate_old_save(data)
	_ensure_default_progress()


func _ensure_array(value) -> Array:
	if value is Array:
		return value
	return []


func _migrate_old_save(data: Dictionary) -> void:
	if data.has("era_progress"):
		album_progress = data.get("era_progress", {})
	if data.has("completed_stories"):
		completed_pictures = _ensure_array(data.get("completed_stories", []))
	save_game()


func _ensure_default_progress() -> void:
	pass


func _get_first_album_id() -> String:
	var album_ids = AlbumDataScript.get_all_album_ids()
	for album_id in album_ids:
		var album = AlbumDataScript.get_album(album_id)
		if album.get("unlock_condition", null) == null:
			return album_id
	if not album_ids.is_empty():
		return album_ids[0]
	return ""


func get_album_id_for_puzzle(puzzle_id: String) -> String:
	_build_completion_cache()
	if _puzzle_to_album_map.has(puzzle_id):
		return _puzzle_to_album_map[puzzle_id]
	
	var album_ids = AlbumDataScript.get_all_album_ids()
	for album_id in album_ids:
		var pictures = AlbumDataScript.load_pictures(album_id)
		for picture in pictures:
			var puzzles = picture.get("puzzles", [])
			if puzzle_id in puzzles:
				_puzzle_to_album_map[puzzle_id] = album_id
				return album_id
	
	push_warning("GameManager: Puzzle '%s' not found in any album" % puzzle_id)
	return ""


func get_album_id_for_picture(picture_id: String) -> String:
	_build_completion_cache()
	if _picture_to_album_map.has(picture_id):
		return _picture_to_album_map[picture_id]
	var album_ids = AlbumDataScript.get_all_album_ids()
	for album_id in album_ids:
		var pictures = AlbumDataScript.load_pictures(album_id)
		for picture in pictures:
			if picture.get("id", "") == picture_id:
				_picture_to_album_map[picture_id] = album_id
				return album_id
	return ""


func get_picture_id_for_puzzle(puzzle_id: String) -> String:
	_build_completion_cache()
	if _puzzle_to_picture_map.has(puzzle_id):
		return _puzzle_to_picture_map[puzzle_id]
	var album_id = get_album_id_for_puzzle(puzzle_id)
	if album_id == "":
		return ""
	var pictures = AlbumDataScript.load_pictures(album_id)
	for picture in pictures:
		if puzzle_id in picture.get("puzzles", []):
			_puzzle_to_picture_map[puzzle_id] = picture.get("id", "")
			return picture.get("id", "")
	return ""

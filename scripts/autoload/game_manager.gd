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
var animation_shown_albums: Array = []
var album_picture_index: Dictionary = {}
var settings: Dictionary = {
	"bgm_volume": 0.8,
	"sfx_volume": 1.0,
	"show_errors": true,
	"auto_mark": true,
	"auto_rotate": true,
}

var test_mode: bool = true

var privacy_agreed: bool = false
var taptap_user_id: String = ""
var taptap_archive_id: String = ""

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
	_apply_language(current_language)
	if not taptap_archive_id.is_empty():
		TapTapManager._current_archive_id = taptap_archive_id


func preload_all_data() -> void:
	if data_preloaded:
		preload_finished.emit()
		return

	preload_progress.emit(0, 100, tr("加载书架数据..."))
	BookshelfDataScript.load_bookshelves()
	await get_tree().process_frame

	preload_progress.emit(5, 100, tr("加载相册数据..."))
	var album_ids = AlbumDataScript.get_all_album_ids()
	var album_count = album_ids.size()
	for i in range(album_count):
		AlbumDataScript.load_pictures(album_ids[i])
		if i % 5 == 4 or i == album_count - 1:
			var pct = 5 + int(float(i + 1) / float(album_count) * 55.0)
			preload_progress.emit(pct, 100, tr("加载相册数据... %d%%") % int(float(i + 1) / float(album_count) * 100))
			await get_tree().process_frame

	preload_progress.emit(65, 100, tr("构建关卡索引..."))
	PuzzleData.build_puzzle_index()
	await get_tree().process_frame

	preload_progress.emit(70, 100, tr("计算完成度..."))
	await _build_completion_cache_async()
	await get_tree().process_frame

	preload_progress.emit(80, 100, tr("生成图标..."))
	_preload_album_icons(album_ids)
	await get_tree().process_frame

	preload_progress.emit(90, 100, tr("检查资源..."))
	AlbumDataScript.preload_album_images_check(album_ids)
	_preload_album_unlock_status(album_ids)
	await get_tree().process_frame

	preload_progress.emit(100, 100, tr("准备就绪"))
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


func _get_icon_cache_key(album_id: String) -> String:
	if current_language == Language.ENGLISH:
		return album_id + "_en"
	return album_id


func _preload_album_icons(album_ids: Array) -> void:
	for album_id in album_ids:
		var cache_key = _get_icon_cache_key(album_id)
		if _album_icon_cache.has(cache_key):
			continue
		var album = AlbumDataScript.get_album(album_id)
		var icon_path = album.get("icon", "")
		var tex: Texture2D = null
		if current_language == Language.ENGLISH:
			var en_path = icon_path.get_base_dir() + "/en/" + icon_path.get_file().get_basename() + "_en.png"
			if en_path != "" and ResourceLoader.exists(en_path):
				tex = load(en_path)
		if tex == null and icon_path != "" and ResourceLoader.exists(icon_path):
			tex = load(icon_path)
		_album_icon_cache[cache_key] = tex
		if not _album_icon_grey_cache.has(cache_key):
			var grey_tex: Texture2D = null
			if current_language == Language.ENGLISH:
				var en_grey_path = icon_path.get_base_dir() + "/en/" + icon_path.get_file().get_basename() + "_en_grey.png"
				if en_grey_path != "" and ResourceLoader.exists(en_grey_path):
					grey_tex = load(en_grey_path)
			if grey_tex == null:
				var grey_path = icon_path.get_basename() + "_grey.png"
				if grey_path != "" and ResourceLoader.exists(grey_path):
					grey_tex = load(grey_path)
			_album_icon_grey_cache[cache_key] = grey_tex


func _preload_album_unlock_status(album_ids: Array) -> void:
	for album_id in album_ids:
		if _album_unlock_cache.has(album_id):
			continue
		_album_unlock_cache[album_id] = is_album_unlocked(album_id)


func get_album_icon(album_id: String) -> Texture2D:
	var cache_key = _get_icon_cache_key(album_id)
	if _album_icon_cache.has(cache_key):
		return _album_icon_cache[cache_key]
	var album = AlbumDataScript.get_album(album_id)
	var icon_path = album.get("icon", "")
	var tex: Texture2D = null
	if current_language == Language.ENGLISH:
		var en_path = icon_path.get_base_dir() + "/en/" + icon_path.get_file().get_basename() + "_en.png"
		if en_path != "" and ResourceLoader.exists(en_path):
			tex = load(en_path)
	if tex == null and icon_path != "" and ResourceLoader.exists(icon_path):
		tex = load(icon_path)
	_album_icon_cache[cache_key] = tex
	return tex


func get_album_icon_grey(album_id: String) -> Texture2D:
	var cache_key = _get_icon_cache_key(album_id)
	if _album_icon_grey_cache.has(cache_key):
		return _album_icon_grey_cache[cache_key]
	var album = AlbumDataScript.get_album(album_id)
	var icon_path = album.get("icon", "")
	var tex: Texture2D = null
	if current_language == Language.ENGLISH:
		var en_grey_path = icon_path.get_base_dir() + "/en/" + icon_path.get_file().get_basename() + "_en_grey.png"
		if en_grey_path != "" and ResourceLoader.exists(en_grey_path):
			tex = load(en_grey_path)
	if tex == null:
		var grey_path = icon_path.get_basename() + "_grey.png"
		if grey_path != "" and ResourceLoader.exists(grey_path):
			tex = load(grey_path)
	_album_icon_grey_cache[cache_key] = tex
	return tex


func invalidate_album_icon_cache(album_id: String) -> void:
	_album_icon_cache.erase(album_id)
	_album_icon_grey_cache.erase(album_id)


func invalidate_all_album_icon_caches() -> void:
	_album_icon_cache.clear()
	_album_icon_grey_cache.clear()


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
	_submit_leaderboard_score()


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


func should_show_album_animation(album_id: String) -> bool:
	return album_id in completed_albums and not album_id in animation_shown_albums


func mark_album_animation_shown(album_id: String) -> void:
	if not album_id in animation_shown_albums:
		animation_shown_albums.append(album_id)
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
		"version": 7,
		"save_time": Time.get_datetime_string_from_system(),
		"album_progress": album_progress,
		"completed_puzzles": completed_puzzles,
		"completed_pictures": completed_pictures,
		"completed_albums": completed_albums,
		"animation_shown_pictures": animation_shown_pictures,
		"animation_shown_albums": animation_shown_albums,
		"album_picture_index": album_picture_index,
		"settings": settings,
		"language": current_language,
		"privacy_agreed": privacy_agreed,
		"taptap_user_id": taptap_user_id,
		"taptap_archive_id": taptap_archive_id,
	}
	var file = FileAccess.open(_save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	_upload_cloud_save()


var _cloud_upload_timer: Timer = null
var _cloud_upload_pending: bool = false
var _last_uploaded_hash: int = 0

func _upload_cloud_save() -> void:
	if not TapTapManager.is_available() or not TapTapManager.is_logged_in():
		return
	if TapTapManager.is_mock_mode():
		return
	var file = FileAccess.open(_save_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var current_hash = content.hash()
		if current_hash == _last_uploaded_hash:
			return
	_cloud_upload_pending = true
	if _cloud_upload_timer == null:
		_cloud_upload_timer = Timer.new()
		_cloud_upload_timer.one_shot = true
		_cloud_upload_timer.timeout.connect(_do_cloud_upload)
		add_child(_cloud_upload_timer)
	_cloud_upload_timer.stop()
	_cloud_upload_timer.start(3.0)

func _do_cloud_upload() -> void:
	if not _cloud_upload_pending:
		return
	_cloud_upload_pending = false
	var file = FileAccess.open(_save_path, FileAccess.READ)
	if not file:
		return
	var save_data = file.get_as_text()
	file.close()
	if save_data.is_empty():
		return
	_last_uploaded_hash = save_data.hash()
	var completed_count = completed_puzzles.size()
	print("GameManager: uploading cloud save, puzzles=%d dataLen=%d" % [completed_count, save_data.length()])
	if not TapTapManager.cloud_save_result.is_connected(_on_cloud_save_result):
		TapTapManager.cloud_save_result.connect(_on_cloud_save_result)
	TapTapManager.save_to_cloud(save_data, "已完成 %d 个数织" % completed_count)


func _on_cloud_save_result(action: String, data: String) -> void:
	print("GameManager: cloud_save_result action=%s data=%s" % [action, data])
	match action:
		"created":
			print("云存档已保存")
		"updated":
			print("云存档已更新")
		"error":
			printerr("云存档保存失败: %s" % data)
			if "Unauthenticated" in data or "login required" in data:
				TapTapManager._is_logged_in = false
				print("GameManager: TapTap session expired, reset login state")
		"deleted":
			pass


func load_from_cloud_save(cloud_json: String) -> void:
	if cloud_json.is_empty():
		return
	var json = JSON.new()
	if json.parse(cloud_json) != OK:
		push_warning("GameManager: Failed to parse cloud save data")
		return
	var data = json.data
	if not data is Dictionary:
		return
	completed_puzzles = _ensure_array(data.get("completed_puzzles", []))
	completed_pictures = _ensure_array(data.get("completed_pictures", []))
	completed_albums = _ensure_array(data.get("completed_albums", []))
	animation_shown_pictures = _ensure_array(data.get("animation_shown_pictures", []))
	animation_shown_albums = _ensure_array(data.get("animation_shown_albums", []))
	album_picture_index = data.get("album_picture_index", {})
	if not album_picture_index is Dictionary:
		album_picture_index = {}
	album_progress = data.get("album_progress", {})
	if not album_progress is Dictionary:
		album_progress = {}
	var loaded_settings = data.get("settings", {})
	if loaded_settings is Dictionary:
		for key in settings:
			if loaded_settings.has(key):
				settings[key] = loaded_settings[key]
	if data.has("language"):
		current_language = int(data["language"])
	privacy_agreed = data.get("privacy_agreed", privacy_agreed)
	taptap_user_id = data.get("taptap_user_id", taptap_user_id)
	taptap_archive_id = data.get("taptap_archive_id", taptap_archive_id)
	invalidate_completion_cache()
	var file = FileAccess.open(_save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	print("GameManager: Cloud save restored (%d puzzles)" % completed_puzzles.size())
	_submit_leaderboard_score()


func compare_with_cloud_save(cloud_json: String) -> Dictionary:
	var result = {
		"conflict": false,
		"cloud_newer": false,
		"local_info": {"puzzle_count": completed_puzzles.size(), "save_time": _read_local_save_time()},
		"cloud_info": {"puzzle_count": 0, "save_time": ""},
	}
	if cloud_json.is_empty():
		return result
	var json = JSON.new()
	if json.parse(cloud_json) != OK:
		return result
	var data = json.data
	if not data is Dictionary:
		return result
	var cloud_puzzles = data.get("completed_puzzles", [])
	var cloud_count = 0
	if cloud_puzzles is Array:
		cloud_count = cloud_puzzles.size()
	result["cloud_info"]["puzzle_count"] = cloud_count
	result["cloud_info"]["save_time"] = data.get("save_time", "")
	var local_count = completed_puzzles.size()
	if cloud_count > local_count:
		result["cloud_newer"] = true
	elif _is_same_content(cloud_json):
		result["cloud_newer"] = false
		result["conflict"] = false
	elif local_count > 0 and cloud_count > 0:
		result["conflict"] = true
	return result


func _read_local_save_time() -> String:
	var file = FileAccess.open(_save_path, FileAccess.READ)
	if not file:
		return ""
	var content = file.get_as_text()
	file.close()
	if content.is_empty():
		return ""
	var json = JSON.new()
	if json.parse(content) != OK:
		return ""
	var data = json.data
	if data is Dictionary:
		return data.get("save_time", "")
	return ""


var _leaderboard_submit_pending: bool = false
var _leaderboard_submit_timer: Timer = null

func _submit_leaderboard_score() -> void:
	if not TapTapManager.is_available() or not TapTapManager.is_logged_in():
		return
	if TapTapManager.is_mock_mode():
		return
	_leaderboard_submit_pending = true
	if _leaderboard_submit_timer == null:
		_leaderboard_submit_timer = Timer.new()
		_leaderboard_submit_timer.one_shot = true
		_leaderboard_submit_timer.timeout.connect(_do_leaderboard_submit)
		add_child(_leaderboard_submit_timer)
	_leaderboard_submit_timer.stop()
	_leaderboard_submit_timer.start(5.0)

func _do_leaderboard_submit() -> void:
	if not _leaderboard_submit_pending:
		return
	_leaderboard_submit_pending = false
	var count = completed_puzzles.size()
	if count <= 0:
		return
	var leaderboard_id = "691qntuadkntr8vq1o"
	print("GameManager: submitting leaderboard score id=%s score=%d" % [leaderboard_id, count])
	TapTapManager.submit_leaderboard_score(leaderboard_id, count)


func _is_same_content(cloud_json: String) -> bool:
	var file = FileAccess.open(_save_path, FileAccess.READ)
	if not file:
		return false
	var local_json = file.get_as_text()
	file.close()
	if local_json.is_empty():
		return false
	var local_json_obj = JSON.new()
	var cloud_json_obj = JSON.new()
	if local_json_obj.parse(local_json) != OK or cloud_json_obj.parse(cloud_json) != OK:
		return false
	if not local_json_obj.data is Dictionary or not cloud_json_obj.data is Dictionary:
		return false
	var local_data = local_json_obj.data
	var cloud_data = cloud_json_obj.data
	var keys_to_compare = ["completed_puzzles", "completed_pictures", "completed_albums", "album_progress"]
	for key in keys_to_compare:
		var local_val = JSON.stringify(local_data.get(key, {}))
		var cloud_val = JSON.stringify(cloud_data.get(key, {}))
		if local_val != cloud_val:
			return false
	return true


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
	animation_shown_albums = _ensure_array(data.get("animation_shown_albums", []))
	album_picture_index = data.get("album_picture_index", {})
	if not album_picture_index is Dictionary:
		album_picture_index = {}
	album_progress = data.get("album_progress", {})
	var loaded_settings = data.get("settings", {})
	if loaded_settings is Dictionary:
		for key in settings:
			if loaded_settings.has(key):
				settings[key] = loaded_settings[key]
	if data.has("language"):
		current_language = int(data["language"])
	privacy_agreed = data.get("privacy_agreed", false)
	taptap_user_id = data.get("taptap_user_id", "")
	taptap_archive_id = data.get("taptap_archive_id", "")
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


func _apply_language(language: int) -> void:
	match language:
		Language.CHINESE:
			TranslationServer.set_locale("zh_CN")
		Language.ENGLISH:
			TranslationServer.set_locale("en")


func get_localized(data: Dictionary, key: String) -> Variant:
	if current_language == Language.ENGLISH:
		var en_key = key + "_en"
		if data.has(en_key):
			var val = data[en_key]
			if val != "" and val != null:
				return val
	if data.has(key):
		return data[key]
	return ""


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

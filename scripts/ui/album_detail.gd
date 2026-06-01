extends Control

const AlbumDataScript = preload("res://scripts/data/album_data.gd")
const PuzzleDataScript = preload("res://scripts/data/puzzle_data.gd")
const NONOGRAM_BTN_5 = preload("res://assets/images/ui/album/picture_nonogram_5.png")
const NONOGRAM_BTN_5_HOVER = preload("res://assets/images/ui/album/picture_nonogram_5_hover.png")
const NONOGRAM_BTN_5_PRESSED = preload("res://assets/images/ui/album/picture_nonogram_5_pressed.png")
const NONOGRAM_BTN_10 = preload("res://assets/images/ui/album/picture_nonogram_10.png")
const NONOGRAM_BTN_10_HOVER = preload("res://assets/images/ui/album/picture_nonogram_10_hover.png")
const NONOGRAM_BTN_10_PRESSED = preload("res://assets/images/ui/album/picture_nonogram_10_pressed.png")
const NONOGRAM_BTN_15 = preload("res://assets/images/ui/album/picture_nonogram_15.png")
const NONOGRAM_BTN_15_HOVER = preload("res://assets/images/ui/album/picture_nonogram_15_hover.png")
const NONOGRAM_BTN_15_PRESSED = preload("res://assets/images/ui/album/picture_nonogram_15_pressed.png")
const NONOGRAM_BTN_20 = preload("res://assets/images/ui/album/picture_nonogram_20.png")
const NONOGRAM_BTN_20_HOVER = preload("res://assets/images/ui/album/picture_nonogram_20_hover.png")
const NONOGRAM_BTN_20_PRESSED = preload("res://assets/images/ui/album/picture_nonogram_20_pressed.png")
const NONOGRAM_BTN_25 = preload("res://assets/images/ui/album/picture_nonogram_25.png")
const NONOGRAM_BTN_25_HOVER = preload("res://assets/images/ui/album/picture_nonogram_25_hover.png")
const NONOGRAM_BTN_25_PRESSED = preload("res://assets/images/ui/album/picture_nonogram_25_pressed.png")
const NONOGRAM_BTN_LOCKED = preload("res://assets/images/ui/album/picture_nonogram_locked.png")
const BadgeButtonScene = preload("res://scenes/badge_button.tscn")

@onready var portrait_ui: Control = $PortraitUI
@onready var landscape_ui: Control = $LandscapeUI

@onready var p_page: Control = $PortraitUI/PageContent
@onready var p_title: Label = $PortraitUI/PageContent/Title
@onready var p_illustration_area: Control = $PortraitUI/PageContent/VBoxContainer/IllustrationArea
@onready var p_album_text: Label = $PortraitUI/PageContent/VBoxContainer/AlbumText
@onready var p_page_num: Label = $PortraitUI/PageContent/PageNumLabel
@onready var p_left_button: TextureButton = $PortraitUI/LeftButton
@onready var p_right_button: TextureButton = $PortraitUI/RightButton
@onready var p_medals_container: HBoxContainer = $PortraitUI/Medals

@onready var l_page: Control = $LandscapeUI/PageContent
@onready var l_title: Label = $LandscapeUI/PageContent/Title
@onready var l_illustration_area: Control = $LandscapeUI/PageContent/VBoxContainer/IllustrationArea
@onready var l_album_text: Label = $LandscapeUI/PageContent/VBoxContainer/AlbumText
@onready var l_page_num: Label = $LandscapeUI/PageContent/PageNumLabel
@onready var l_left_button: TextureButton = $LandscapeUI/LeftButton
@onready var l_right_button: TextureButton = $LandscapeUI/RightButton

@onready var l_page2: Control = $LandscapeUI/PageContent2
@onready var l_title2: Label = $LandscapeUI/PageContent2/Title
@onready var l_illustration_area2: Control = $LandscapeUI/PageContent2/VBoxContainer/IllustrationArea
@onready var l_album_text2: Label = $LandscapeUI/PageContent2/VBoxContainer/AlbumText
@onready var l_page_num2: Label = $LandscapeUI/PageContent2/PageNumLabel
@onready var l_medals_container: HBoxContainer = $LandscapeUI/Medals

@onready var settings_popup: Control = $CanvasLayer/SettingsPopup



var current_album_id: String = ""
var current_picture_id: String = ""
var _pictures: Array = []
var _current_picture_index: int = 0
var _just_completed_puzzle_id: String = ""
var _pending_light_fly_picture_id: String = ""

var _puzzle_cache: Dictionary = {}
var _texture_cache: Dictionary = {}
var _texture_lru: Array = []
const MAX_CACHED_PICTURES: int = 12
var _region_tex_cache: Dictionary = {}

var _preload_pending: bool = false
var _loading_textures: Dictionary = {}
var _pending_display: bool = false

var _swipe_start_pos: Vector2 = Vector2.ZERO
var _swipe_min_distance: float = 50.0
var _viewer_close_msec: int = 0
var _orientation_switching: bool = false
var _orientation_generation: int = 0
var _orientation_updating: bool = false

const REGION_GAP: float = 0.0

var _fullscreen_viewer: CanvasLayer = null
var _viewer_area: Control = null

func _ready() -> void:
	p_illustration_area.resized.connect(_on_illustration_area_resized.bind(p_illustration_area))
	l_illustration_area.resized.connect(_on_illustration_area_resized.bind(l_illustration_area))
	l_illustration_area2.resized.connect(_on_illustration_area_resized.bind(l_illustration_area2))
	if GameManager.pending_puzzle_id != "":
		_just_completed_puzzle_id = GameManager.pending_puzzle_id
		GameManager.pending_puzzle_id = ""
	if GameManager.pending_album_id != "":
		current_album_id = GameManager.pending_album_id
		GameManager.pending_album_id = ""
		_load_pictures_list()
	AudioManager.play_bgm_for_album(current_album_id)
	OrientationManager.orientation_changed.connect(_on_orientation_changed)
	_apply_orientation(OrientationManager.current_orientation)
	GameManager.preload_scene("res://scenes/nonogram_scene.tscn")
	GameManager.language_changed.connect(_on_language_changed)
	_setup_chapter_badges()

func _exit_tree() -> void:
	if current_album_id != "" and _current_picture_index >= 0:
		GameManager.save_picture_index(current_album_id, _current_picture_index)
	if OrientationManager.orientation_changed.is_connected(_on_orientation_changed):
		OrientationManager.orientation_changed.disconnect(_on_orientation_changed)
	if GameManager.language_changed.is_connected(_on_language_changed):
		GameManager.language_changed.disconnect(_on_language_changed)
	if _fullscreen_viewer:
		_fullscreen_viewer.queue_free()
		_fullscreen_viewer = null
	AnimationManager.clear_queue()
	_puzzle_cache.clear()
	_texture_cache.clear()
	_texture_lru.clear()
	_region_tex_cache.clear()
	_loading_textures.clear()
	_pending_display = false

func _on_language_changed(_language: int) -> void:
	if _pictures.is_empty():
		return
	_refresh_page_texts()
	_setup_chapter_badges()

func _refresh_page_texts() -> void:
	var display_index = _get_display_index()
	var picture = _pictures[display_index]
	_refresh_picture_text(picture, p_title, p_illustration_area, p_album_text)
	if _is_landscape():
		_refresh_picture_text(picture, l_title, l_illustration_area, l_album_text)
		var second_index = display_index + 1
		if second_index < _pictures.size():
			var picture2 = _pictures[second_index]
			_refresh_picture_text(picture2, l_title2, l_illustration_area2, l_album_text2)

func _refresh_picture_text(picture: Dictionary, title: Label, area: Control, text_label: Label) -> void:
	var pic_id = picture.get("id", "")
	var title_text = GameManager.get_localized(picture, "title")
	var full_text = GameManager.get_localized(picture, "full_text")
	_stop_typewriter(area)
	if GameManager.is_picture_completed(pic_id):
		title.text = title_text
		text_label.text = full_text
	else:
		title.text = _generate_gibberish(title_text.length(), pic_id + "_title")
		text_label.text = _generate_gibberish(full_text.length(), pic_id)

func _is_landscape() -> bool:
	return landscape_ui.visible

func _get_active_illustration_area() -> Control:
	if _is_landscape():
		return l_illustration_area
	return p_illustration_area

func _get_active_illustration_areas() -> Array:
	if _is_landscape():
		var areas = [l_illustration_area]
		if l_page2.visible:
			areas.append(l_illustration_area2)
		return areas
	return [p_illustration_area]

func _get_step() -> int:
	return 2 if _is_landscape() else 1

func _load_pictures_list() -> void:
	_pictures = AlbumDataScript.load_pictures(current_album_id)
	if _pictures.is_empty():
		return

	if GameManager.pending_picture_index >= 0 and GameManager.pending_picture_index < _pictures.size():
		_current_picture_index = GameManager.pending_picture_index
		GameManager.pending_picture_index = -1
	else:
		var saved_index = GameManager.get_saved_picture_index(current_album_id)
		if saved_index >= 0 and saved_index < _pictures.size():
			_current_picture_index = saved_index
		else:
			_current_picture_index = 0

func _display_current_pages() -> void:
	var display_index = _get_display_index()
	var picture = _pictures[display_index]
	current_picture_id = picture.get("id", "")
	_load_picture(picture, p_title, p_illustration_area, p_album_text, p_page_num, display_index)

	if _is_landscape():
		_load_picture(picture, l_title, l_illustration_area, l_album_text, l_page_num, display_index)
		var second_index = display_index + 1
		if second_index < _pictures.size():
			l_page2.visible = true
			var picture2 = _pictures[second_index]
			_load_picture(picture2, l_title2, l_illustration_area2, l_album_text2, l_page_num2, second_index)
		else:
			l_page2.visible = false
			_clear_page(l_title2, l_illustration_area2, l_album_text2, l_page_num2)

	_update_page_navigation()
	_schedule_preload_adjacent()
	GameManager.album_picture_index[current_album_id] = _current_picture_index

func _get_display_index() -> int:
	var idx = _current_picture_index
	if _is_landscape() and idx % 2 == 1 and idx > 0:
		return idx - 1
	return idx

func _kill_area_tweens(area: Control) -> void:
	if not is_instance_valid(area):
		return
	if area.has_meta("reveal_tween"):
		var tween: Tween = area.get_meta("reveal_tween")
		if tween and tween.is_valid():
			tween.kill()
		area.remove_meta("reveal_tween")
	if area.has_meta("fade_tween"):
		var tween: Tween = area.get_meta("fade_tween")
		if tween and tween.is_valid():
			tween.kill()
		area.remove_meta("fade_tween")
	_stop_typewriter(area)

func _clear_page(title: Label, area: Control, text: Label, page_num: Label) -> void:
	title.text = ""
	text.text = ""
	page_num.text = ""
	_kill_area_tweens(area)
	if area.has_meta("illustration_ctx"):
		area.remove_meta("illustration_ctx")
	var children = area.get_children()
	for child in children:
		area.remove_child(child)
		child.queue_free()

func _load_picture(picture: Dictionary, title: Label, area: Control, text_label: Label, page_num: Label, picture_index: int) -> void:
	var pic_id = picture.get("id", "")
	var title_text = GameManager.get_localized(picture, "title")
	page_num.text = "%d/%d" % [picture_index + 1, _pictures.size()]

	var full_text = GameManager.get_localized(picture, "full_text")

	_stop_typewriter(area)

	if GameManager.is_picture_completed(pic_id):
		var should_animate = GameManager.should_show_animation(pic_id)
		if should_animate:
			var entries = [
				{
					"label": title,
					"full_text": title_text,
					"gibberish": _generate_gibberish(title_text.length(), pic_id + "_title")
				},
				{
					"label": text_label,
					"full_text": full_text,
					"gibberish": _generate_gibberish(full_text.length(), pic_id)
				}
			]
			title.text = entries[0].gibberish
			text_label.text = entries[1].gibberish
			_start_typewriter_animation(area, entries)
		else:
			title.text = title_text
			text_label.text = full_text
	else:
		title.text = _generate_gibberish(title_text.length(), pic_id + "_title")
		text_label.text = _generate_gibberish(full_text.length(), pic_id)

	_build_illustration(area, picture, picture_index)

func _generate_gibberish(length: int, seed_str: String) -> String:
	var chars = "■□▢▣▤▥▦▧▨▩▪▫▬▭▮▯▰▱▲△▴▵▶▷▸▹►▻▼▽▾▿◀◁◂◃◄◅◆◇◈◉◊○◌◍◎●◐◑◒◓◔◕◖◗◘◙◚◛◜◝◞◟◠◡◢◣◤◥◦◧◨◩◪◫◬◭◮◯◰◱◲◳◴◵◶◷◸◹◺◿!@#$%^&*∠∟⊿⊾⊽⊼⊻⊺⊹⊸⊷⊶⊵⊴⊳⊲⊱⊰⊯⊮⊭⊬⊫⊪⊩⊨⊧⊦⊥⊤⊣⊢⊡⊠⊟⊞⊝⊜⊛⊚⊙⊘⊗⊖⊕⊔⊓⊒⊑⊐⊏⊎⊍⊌⊋⊊⊉⊈⊇⊆⊅⊄⊃⊂⊁⊀∀∁∂∃∄∅∆∇∈∉∊∋∌∍∎∏∐∑−∓∔∕∖∗∘∙√∛∜∝∞∟∠∡∢∣∤∥∦∧∨∩∪∫∬∭∮∯∰∱∲∳∴∵∶∷∸∹∺∻∼∽∾∿≀≁≂≃≄≅≆≇≈≉≊≋≌≍≎≏≐≑≒≓≔≕≖≗≘≙≚≛≜≝≞≟≠≡≢≣≤≥≦≧≨≩≪≫≬≭≮≯≰≱≲≳≴≵≶≷≸≹≺≻≼≽≾≿"
	var result = ""
	var seed_val = _string_to_seed(seed_str)
	var state = seed_val
	for _i in range(length):
		state = (state * 1103515245 + 12345) & 0x7fffffff
		result += chars[state % chars.length()]
	return result

func _stop_typewriter(area: Control) -> void:
	if area.has_meta("typewriter_tween"):
		var old_tween: Tween = area.get_meta("typewriter_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
		area.remove_meta("typewriter_tween")
	area.remove_meta("typewriter_entries")

func _start_typewriter_animation(area: Control, entries: Array) -> void:
	if entries.is_empty():
		return

	var max_chars = 0
	for entry in entries:
		max_chars = max(max_chars, entry.full_text.length())
	if max_chars == 0:
		return

	var chars_per_step = max(1, ceili(float(max_chars) / 30.0))
	var step_count = ceili(float(max_chars) / float(chars_per_step))
	var step_duration = 0.06

	var tween = create_tween()
	for step in range(step_count):
		var end_idx = min(step * chars_per_step + chars_per_step, max_chars)
		tween.tween_callback(_typewriter_reveal_step.bind(area, end_idx))
		tween.tween_interval(step_duration)

	tween.tween_callback(_on_typewriter_finished.bind(area))

	area.set_meta("typewriter_tween", tween)
	area.set_meta("typewriter_entries", entries)

func _typewriter_reveal_step(area: Control, end_idx: int) -> void:
	if not area.has_meta("typewriter_entries"):
		return
	var entries: Array = area.get_meta("typewriter_entries")
	for entry in entries:
		var label = entry.label
		if not is_instance_valid(label):
			continue
		var full: String = entry.full_text
		var gib: String = entry.gibberish
		if full.length() == 0:
			continue
		var result = ""
		var chars_to_show = mini(end_idx, full.length())
		for i in range(full.length()):
			if i < chars_to_show:
				result += full[i]
			else:
				result += gib[i]
		label.text = result

func _on_typewriter_finished(area: Control) -> void:
	if not area.has_meta("typewriter_entries"):
		return
	var entries: Array = area.get_meta("typewriter_entries")
	for entry in entries:
		var label = entry.label
		if is_instance_valid(label):
			label.text = entry.full_text

func _string_to_seed(s: String) -> int:
	var hash_val = 0
	for i in range(s.length()):
		hash_val = hash_val * 31 + s.unicode_at(i)
	return abs(hash_val) & 0x7fffffff

func _build_illustration(area: Control, picture: Dictionary, picture_index: int) -> void:
	_kill_area_tweens(area)
	if area.has_meta("illustration_ctx"):
		area.remove_meta("illustration_ctx")

	var ctx: Dictionary = {}
	var pic_id = picture.get("id", "")
	ctx["picture_id"] = pic_id
	ctx["picture_index"] = picture_index
	ctx["region_buttons"] = {}

	_clear_area_children(area)

	ctx["puzzles"] = []
	var puzzle_ids = picture.get("puzzles", [])
	for pid in puzzle_ids:
		if _puzzle_cache.has(pid):
			ctx["puzzles"].append(_puzzle_cache[pid])
		else:
			var puzzle = PuzzleDataScript.load_puzzle(pid)
			if puzzle:
				_puzzle_cache[pid] = puzzle
				ctx["puzzles"].append(puzzle)

	_compute_grid_layout(ctx, picture)

	var img_path = picture.get("image", "")
	if _texture_cache.has(pic_id):
		var cached = _texture_cache[pic_id]
		ctx["illustration_texture"] = cached["illust_tex"]
		ctx["pixel_texture"] = cached["pixel_tex"]
		ctx["illustration_width"] = cached["img_w"]
		ctx["illustration_height"] = cached["img_h"]
		_texture_lru.erase(pic_id)
		_texture_lru.append(pic_id)
	else:
		if _loading_textures.has(pic_id):
			var loading = _loading_textures[pic_id]
			var illust_tex_cached: Texture2D = loading.get("illust_tex")
			if illust_tex_cached == null and loading.get("state", "") == "loading_illust":
				var l_img_path: String = loading["img_path"]
				illust_tex_cached = ResourceLoader.load_threaded_get(l_img_path) as Texture2D
				loading["illust_tex"] = illust_tex_cached
				var picture_data: Dictionary = loading.get("picture", {})
				var pixel_path = picture_data.get("pixel_image", "")
				if pixel_path == "":
					pixel_path = l_img_path.get_basename() + "_nonogram_pixel.jpg"
				if pixel_path != "" and ResourceLoader.exists(pixel_path):
					ResourceLoader.load_threaded_request(pixel_path, "", false)
					loading["state"] = "loading_pixel"
					loading["pixel_path"] = pixel_path
				else:
					loading["state"] = "done"
			if illust_tex_cached:
				var pixel_tex_cached: Texture2D = loading.get("pixel_tex")
				if pixel_tex_cached == null and loading.has("pixel_path"):
					var pixel_path: String = loading["pixel_path"]
					pixel_tex_cached = ResourceLoader.load_threaded_get(pixel_path) as Texture2D
				ctx["illustration_texture"] = illust_tex_cached
				ctx["pixel_texture"] = pixel_tex_cached
				ctx["illustration_width"] = illust_tex_cached.get_width()
				ctx["illustration_height"] = illust_tex_cached.get_height()
				_loading_textures.erase(pic_id)
				_texture_cache[pic_id] = {
					"illust_tex": illust_tex_cached,
					"pixel_tex": pixel_tex_cached,
					"img_w": illust_tex_cached.get_width(),
					"img_h": illust_tex_cached.get_height()
				}
				_texture_lru.append(pic_id)
				_evict_texture_cache()
			else:
				_loading_textures.erase(pic_id)
				_load_textures_sync(ctx, pic_id, img_path, picture)
		else:
			_load_textures_sync(ctx, pic_id, img_path, picture)

	area.set_meta("illustration_ctx", ctx)
	_create_illustration_display(area, ctx)

func _load_textures_sync(ctx: Dictionary, pic_id: String, img_path: String, picture: Dictionary) -> void:
	var illust_tex: Texture2D = null
	var pixel_tex: Texture2D = null
	var img_w: int = 0
	var img_h: int = 0

	if img_path != "" and ResourceLoader.exists(img_path):
		var tex = ResourceLoader.load(img_path, "", ResourceLoader.CACHE_MODE_REUSE)
		if tex is Texture2D:
			illust_tex = tex
			img_w = tex.get_width()
			img_h = tex.get_height()

	if illust_tex == null:
		var placeholder_img = _generate_placeholder_illustration(ctx)
		illust_tex = ImageTexture.create_from_image(placeholder_img)
		img_w = illust_tex.get_width()
		img_h = illust_tex.get_height()

	var pixel_path = picture.get("pixel_image", "")
	if pixel_path == "":
		pixel_path = img_path.get_basename() + "_nonogram_pixel.jpg"
	if pixel_path != "" and ResourceLoader.exists(pixel_path):
		var tex = ResourceLoader.load(pixel_path, "", ResourceLoader.CACHE_MODE_REUSE)
		if tex is Texture2D:
			pixel_tex = tex

	ctx["illustration_texture"] = illust_tex
	ctx["pixel_texture"] = pixel_tex
	ctx["illustration_width"] = img_w
	ctx["illustration_height"] = img_h

	_texture_cache[pic_id] = {
		"illust_tex": illust_tex,
		"pixel_tex": pixel_tex,
		"img_w": img_w,
		"img_h": img_h
	}
	_texture_lru.append(pic_id)
	_evict_texture_cache()

func _clear_area_children(area: Control) -> void:
	var children = area.get_children()
	if children.is_empty():
		return
	for child in children:
		area.remove_child(child)
		child.queue_free()

func _evict_texture_cache() -> void:
	while _texture_lru.size() > MAX_CACHED_PICTURES:
		var evict_id = _texture_lru.pop_front()
		_texture_cache.erase(evict_id)
		_region_tex_cache.erase(evict_id)

func _compute_grid_layout(ctx: Dictionary, picture: Dictionary) -> void:
	ctx["has_valid_source_rects"] = false

	var puzzles = ctx["puzzles"]
	if puzzles.is_empty():
		ctx["grid_x"] = 1
		ctx["grid_y"] = 1
		return

	var ig = _get_image_grid_from_picture(current_album_id, ctx["picture_id"])
	if ig.x > 0 and ig.y > 0:
		ctx["grid_x"] = ig.x
		ctx["grid_y"] = ig.y
		ctx["has_valid_source_rects"] = true
		return

	var rects: Array = []
	for puzzle in puzzles:
		var sr = puzzle.source_rect
		if not sr.has("x") or not sr.has("y") or not sr.has("w") or not sr.has("h"):
			_compute_grid_from_count(ctx)
			return
		rects.append(sr)

	if rects.size() <= 1:
		ctx["grid_x"] = 1
		ctx["grid_y"] = 1
		if rects.size() == 1 and (rects[0].x > 0 or rects[0].y > 0):
			ctx["has_valid_source_rects"] = true
		return

	var all_at_origin = true
	for sr in rects:
		if sr.x != 0 or sr.y != 0:
			all_at_origin = false
			break

	if all_at_origin:
		_compute_grid_from_count(ctx)
		return

	ctx["has_valid_source_rects"] = true
	var max_x = 0
	var max_y = 0
	var cell_w = rects[0].w
	var cell_h = rects[0].h
	for sr in rects:
		max_x = max(max_x, sr.x + sr.w)
		max_y = max(max_y, sr.y + sr.h)
		cell_w = min(cell_w, sr.w)
		cell_h = min(cell_h, sr.h)

	if cell_w > 0 and cell_h > 0:
		ctx["grid_x"] = int(max_x / cell_w)
		ctx["grid_y"] = int(max_y / cell_h)
	else:
		_compute_grid_from_count(ctx)

func _get_image_grid_from_picture(album_id: String, picture_id: String) -> Vector2i:
	var picture = AlbumDataScript.get_picture(album_id, picture_id)
	var ig = picture.get("image_grid", {})
	if ig is Dictionary and ig.has("x") and ig.has("y"):
		return Vector2i(int(ig.x), int(ig.y))
	return Vector2i(0, 0)

func _compute_grid_from_count(ctx: Dictionary) -> void:
	var n = ctx["puzzles"].size()
	match n:
		0, 1:
			ctx["grid_x"] = 1
			ctx["grid_y"] = 1
		2:
			ctx["grid_x"] = 2
			ctx["grid_y"] = 1
		3:
			ctx["grid_x"] = 3
			ctx["grid_y"] = 1
		4:
			ctx["grid_x"] = 2
			ctx["grid_y"] = 2
		5, 6:
			ctx["grid_x"] = 3
			ctx["grid_y"] = 2
		7, 8:
			ctx["grid_x"] = 4
			ctx["grid_y"] = 2
		_:
			ctx["grid_x"] = ceili(sqrt(n))
			ctx["grid_y"] = ceili(float(n) / float(ctx["grid_x"]))

func _create_illustration_display(area: Control, ctx: Dictionary) -> void:
	var picture_id: String = ctx["picture_id"]
	if GameManager.is_picture_completed(picture_id) and _just_completed_puzzle_id == "":
		_create_completed_display(area, ctx)
		return

	var puzzles = ctx["puzzles"]
	var is_locked = _is_picture_locked(ctx["picture_index"])
	var just_completed_idx = -1
	if _just_completed_puzzle_id != "":
		for i in range(puzzles.size()):
			if puzzles[i].id == _just_completed_puzzle_id:
				just_completed_idx = i
				break

	for i in range(puzzles.size()):
		var puzzle = puzzles[i]
		var completed = GameManager.is_puzzle_completed(puzzle.id)

		var btn = TextureButton.new()
		btn.name = "RegionBtn_" + str(i)
		btn.stretch_mode = TextureButton.STRETCH_SCALE

		if is_locked:
			btn.texture_normal = NONOGRAM_BTN_LOCKED
			btn.texture_hover = NONOGRAM_BTN_LOCKED
			btn.texture_pressed = NONOGRAM_BTN_LOCKED
			btn.set_meta("locked", true)
		elif not completed:
			_set_btn_tex_nonogram(btn, max(puzzle.rows, puzzle.cols))
		elif i == just_completed_idx:
			_set_btn_tex_nonogram(btn, max(puzzle.rows, puzzle.cols))
		else:
			var source_tex: Texture2D = ctx["pixel_texture"]
			if source_tex == null:
				source_tex = ctx["illustration_texture"]
			if source_tex:
				var cache_key = picture_id + "_" + puzzle.id
				if _region_tex_cache.has(cache_key):
					var small_tex = _region_tex_cache[cache_key]
					btn.texture_normal = small_tex
					btn.texture_hover = small_tex
					btn.texture_pressed = small_tex
				else:
					var region = _get_region_pixel_rect(i, source_tex.get_width(), source_tex.get_height(), ctx)
					var atlas = AtlasTexture.new()
					atlas.atlas = source_tex
					atlas.region = region
					var region_img = atlas.get_image()
					var target_size = 160
					region_img.resize(target_size, target_size, Image.INTERPOLATE_NEAREST)
					var small_tex = ImageTexture.create_from_image(region_img)
					_region_tex_cache[cache_key] = small_tex
					btn.texture_normal = small_tex
					btn.texture_hover = small_tex
					btn.texture_pressed = small_tex
				btn.mouse_entered.connect(_on_region_btn_hover.bind(btn, true))
				btn.mouse_exited.connect(_on_region_btn_hover.bind(btn, false))
				btn.button_down.connect(_on_region_btn_press.bind(btn, true))
				btn.button_up.connect(_on_region_btn_press.bind(btn, false))
			else:
				_set_btn_tex_nonogram(btn, 5)

		btn.pressed.connect(_on_region_clicked.bind(puzzle))
		area.add_child(btn)
		ctx["region_buttons"][puzzle.id] = btn

	_update_region_positions(area)

	if just_completed_idx >= 0:
		_play_puzzle_reveal_animation(area, ctx, just_completed_idx)
	elif GameManager.is_picture_completed(picture_id):
		_create_completed_display(area, ctx)

func _play_puzzle_reveal_animation(area: Control, ctx: Dictionary, puzzle_idx: int) -> void:
	var puzzles = ctx["puzzles"]
	var puzzle = puzzles[puzzle_idx]
	var picture_id: String = ctx["picture_id"]
	var btn = ctx["region_buttons"].get(puzzle.id) as TextureButton
	if not btn:
		return

	var source_tex: Texture2D = ctx["pixel_texture"]
	if source_tex == null:
		source_tex = ctx["illustration_texture"]
	if source_tex == null:
		return

	var cache_key = picture_id + "_" + puzzle.id
	var pixel_tex: Texture2D = null
	if _region_tex_cache.has(cache_key):
		pixel_tex = _region_tex_cache[cache_key]
	else:
		var region = _get_region_pixel_rect(puzzle_idx, source_tex.get_width(), source_tex.get_height(), ctx)
		var atlas = AtlasTexture.new()
		atlas.atlas = source_tex
		atlas.region = region
		var region_img = atlas.get_image()
		var target_size = 160
		region_img.resize(target_size, target_size, Image.INTERPOLATE_NEAREST)
		pixel_tex = ImageTexture.create_from_image(region_img)
		_region_tex_cache[cache_key] = pixel_tex

	var grid_x: int = ctx["grid_x"]
	var col = puzzle_idx % grid_x
	var row = int(float(puzzle_idx) / grid_x)
	var layout = _get_illustration_layout(area, ctx)

	if layout.display_w <= 0 or layout.display_h <= 0:
		await get_tree().process_frame
		if not is_inside_tree() or not is_instance_valid(area) or not area.has_meta("illustration_ctx"):
			_just_completed_puzzle_id = ""
			return
		layout = _get_illustration_layout(area, ctx)
		if layout.display_w <= 0 or layout.display_h <= 0:
			_just_completed_puzzle_id = ""
			return

	var overlay_pos = Vector2(
		layout.offset_x + col * (layout.cell_w + REGION_GAP),
		layout.offset_y + row * (layout.cell_h + REGION_GAP)
	)
	var overlay_size = Vector2(layout.cell_w, layout.cell_h)

	if not is_instance_valid(btn):
		_just_completed_puzzle_id = ""
		return

	btn.position = overlay_pos
	btn.size = overlay_size

	var overlay = TextureRect.new()
	overlay.name = "RevealOverlay"
	overlay.texture = pixel_tex
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.modulate.a = 0.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.position = overlay_pos
	overlay.size = overlay_size
	area.add_child(overlay)

	var tween = create_tween()
	AnimationManager.register_tween(tween)
	if area.has_meta("reveal_tween"):
		var old_tween: Tween = area.get_meta("reveal_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	area.set_meta("reveal_tween", tween)
	tween.parallel().tween_property(btn, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(overlay, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		_just_completed_puzzle_id = ""
		if not is_inside_tree() or not is_instance_valid(btn):
			if is_instance_valid(overlay):
				overlay.queue_free()
			return
		btn.texture_normal = pixel_tex
		btn.texture_hover = pixel_tex
		btn.texture_pressed = pixel_tex
		btn.modulate.a = 1.0
		btn.mouse_entered.connect(_on_region_btn_hover.bind(btn, true))
		btn.mouse_exited.connect(_on_region_btn_hover.bind(btn, false))
		btn.button_down.connect(_on_region_btn_press.bind(btn, true))
		btn.button_up.connect(_on_region_btn_press.bind(btn, false))
		if is_instance_valid(overlay):
			overlay.queue_free()
		var all_done = true
		for p in puzzles:
			if not GameManager.is_puzzle_completed(p.id):
				all_done = false
				break
		if all_done and is_instance_valid(area):
			_pending_light_fly_picture_id = ctx["picture_id"]
			_play_picture_complete_animation(area, ctx)
	)

func _play_picture_complete_animation(area: Control, ctx: Dictionary) -> void:
	var picture_id: String = ctx["picture_id"]
	var will_animate = GameManager.should_show_animation(picture_id)
	if not will_animate:
		GameManager.mark_animation_shown(picture_id)
	_clear_area_children(area)
	_create_completed_display(area, ctx)
	if not will_animate and _pending_light_fly_picture_id == picture_id and _is_area_in_active_orientation(area):
		_pending_light_fly_picture_id = ""
		_play_light_fly_to_badge(picture_id)

func _on_region_btn_hover(btn: TextureButton, entered: bool) -> void:
	if btn.button_pressed:
		return
	btn.modulate = Color(1.2, 1.2, 1.2) if entered else Color.WHITE

func _on_region_btn_press(btn: TextureButton, pressed: bool) -> void:
	btn.modulate = Color(0.8, 0.8, 0.8) if pressed else Color.WHITE

func _is_picture_locked(picture_index: int) -> bool:
	if GameManager.test_mode:
		return false
	if picture_index <= 0:
		return false

	var prev_picture = _pictures[picture_index - 1]
	var prev_picture_id = prev_picture.get("id", "")
	return not GameManager.is_picture_completed(prev_picture_id)

func _set_btn_tex_nonogram(btn: TextureButton, grid_num: int) -> void:
	match grid_num:
		5:
			btn.texture_normal = NONOGRAM_BTN_5
			btn.texture_hover = NONOGRAM_BTN_5_HOVER
			btn.texture_pressed = NONOGRAM_BTN_5_PRESSED
		10:
			btn.texture_normal = NONOGRAM_BTN_10
			btn.texture_hover = NONOGRAM_BTN_10_HOVER
			btn.texture_pressed = NONOGRAM_BTN_10_PRESSED
		15:
			btn.texture_normal = NONOGRAM_BTN_15
			btn.texture_hover = NONOGRAM_BTN_15_HOVER
			btn.texture_pressed = NONOGRAM_BTN_15_PRESSED
		20:
			btn.texture_normal = NONOGRAM_BTN_20
			btn.texture_hover = NONOGRAM_BTN_20_HOVER
			btn.texture_pressed = NONOGRAM_BTN_20_PRESSED
		25:
			btn.texture_normal = NONOGRAM_BTN_25
			btn.texture_hover = NONOGRAM_BTN_25_HOVER
			btn.texture_pressed = NONOGRAM_BTN_25_PRESSED
		_:
			btn.texture_normal = NONOGRAM_BTN_5
			btn.texture_hover = NONOGRAM_BTN_5_HOVER
			btn.texture_pressed = NONOGRAM_BTN_5_PRESSED

func _create_completed_display(area: Control, ctx: Dictionary) -> void:
	var picture_id: String = ctx["picture_id"]
	var should_animate = GameManager.should_show_animation(picture_id)
	var illust_tex: Texture2D = ctx["illustration_texture"]
	var pixel_tex: Texture2D = ctx["pixel_texture"]
	var is_touch = DisplayServer.is_touchscreen_available()

	if pixel_tex and illust_tex and should_animate:
		var pixel_rect = TextureRect.new()
		pixel_rect.name = "PixelArtRect"
		pixel_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pixel_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pixel_rect.texture = pixel_tex
		if is_touch:
			pixel_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		area.add_child(pixel_rect)
		_update_completed_illustration_layout(area)

		var hd_rect = TextureRect.new()
		hd_rect.name = "HDImageRect"
		hd_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		hd_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hd_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hd_rect.texture = illust_tex
		if is_touch:
			hd_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = preload("res://shaders/sweep_reveal.gdshader")
		shader_mat.set_shader_parameter("progress", 0.0)
		shader_mat.set_shader_parameter("sweep_width", 0.08)
		hd_rect.material = shader_mat
		area.add_child(hd_rect)

		if area.has_meta("fade_tween"):
			var old_tween: Tween = area.get_meta("fade_tween")
			if old_tween and old_tween.is_valid():
				old_tween.kill()
		var fade_tween = create_tween()
		area.set_meta("fade_tween", fade_tween)
		fade_tween.tween_method(_set_sweep_progress.bind(shader_mat), 0.0, 1.15, 1.5)
		fade_tween.tween_callback(_on_animation_finished.bind(picture_id, area))
		if not is_touch:
			fade_tween.tween_callback(_enable_hd_click.bind(area))
	elif illust_tex:
		var hd_rect = TextureRect.new()
		hd_rect.name = "HDImageRect"
		hd_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		hd_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hd_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hd_rect.texture = illust_tex
		if is_touch:
			hd_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			hd_rect.gui_input.connect(_on_hd_image_input.bind(area))
		area.add_child(hd_rect)
	elif pixel_tex:
		var pixel_rect = TextureRect.new()
		pixel_rect.name = "PixelArtRect"
		pixel_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pixel_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pixel_rect.texture = pixel_tex
		if is_touch:
			pixel_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		area.add_child(pixel_rect)
		_update_completed_illustration_layout(area)

func _update_completed_illustration_layout(area: Control) -> void:
	if not area.has_meta("illustration_ctx"):
		return
	var ctx: Dictionary = area.get_meta("illustration_ctx")
	var picture_id: String = ctx.get("picture_id", "")
	if not GameManager.is_picture_completed(picture_id):
		return
	var pixel_rect = area.get_node_or_null("PixelArtRect") as TextureRect
	if not pixel_rect:
		return
	var layout = _get_illustration_layout(area, ctx)
	if layout.display_w <= 0 or layout.display_h <= 0:
		return
	pixel_rect.position = Vector2(layout.offset_x, layout.offset_y)
	pixel_rect.size = Vector2(layout.display_w, layout.display_h)

func _update_illustration_layout(area: Control) -> void:
	_update_region_positions(area)
	_update_completed_illustration_layout(area)

func _on_animation_finished(pic_id: String, area: Control) -> void:
	if not is_inside_tree() or not is_instance_valid(area):
		return
	GameManager.mark_animation_shown(pic_id)
	if _pending_light_fly_picture_id == pic_id and _is_area_in_active_orientation(area):
		_pending_light_fly_picture_id = ""
		_play_light_fly_to_badge(pic_id)


func _is_area_in_active_orientation(area: Control) -> bool:
	if _is_landscape():
		return area == l_illustration_area or area == l_illustration_area2
	return area == p_illustration_area

func _enable_hd_click(area: Control) -> void:
	if not is_inside_tree() or not is_instance_valid(area):
		return
	var hd_rect = area.get_node_or_null("HDImageRect") as TextureRect
	if hd_rect:
		hd_rect.gui_input.connect(_on_hd_image_input.bind(area))

func _on_hd_image_input(event: InputEvent, area: Control) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_fullscreen_viewer(area)
	elif event is InputEventScreenTouch and event.pressed:
		_show_fullscreen_viewer(area)

func _show_fullscreen_viewer(area: Control) -> void:
	if _fullscreen_viewer:
		return
	if not area.has_meta("illustration_ctx"):
		return
	var ctx: Dictionary = area.get_meta("illustration_ctx")
	var illust_tex: Texture2D = ctx.get("illustration_texture")
	if not illust_tex:
		return

	_viewer_area = area
	var area_rect = area.get_global_rect()
	var area_center = area_rect.position + area_rect.size * 0.5
	var vp_size = get_viewport().get_visible_rect().size
	var screen_center = vp_size * 0.5

	var canvas = CanvasLayer.new()
	canvas.layer = 100

	var overlay = ColorRect.new()
	overlay.name = "DimBg"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_viewer_overlay_input)

	var img_rect = TextureRect.new()
	img_rect.name = "ViewerImage"
	img_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img_rect.texture = illust_tex

	canvas.add_child(overlay)
	canvas.add_child(img_rect)
	add_child(canvas)

	_fullscreen_viewer = canvas

	img_rect.pivot_offset = screen_center
	var start_scale = Vector2(area_rect.size.x / vp_size.x, area_rect.size.y / vp_size.y)
	img_rect.scale = start_scale
	img_rect.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.75, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(img_rect, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(img_rect, "modulate:a", 1.0, 0.2)

func _on_viewer_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_fullscreen_viewer()
	elif event is InputEventScreenTouch and event.pressed:
		_close_fullscreen_viewer()

func _close_fullscreen_viewer() -> void:
	if not _fullscreen_viewer:
		return
	var viewer = _fullscreen_viewer
	_fullscreen_viewer = null
	_viewer_close_msec = Time.get_ticks_msec()
	_swipe_start_pos = Vector2.ZERO

	var img_rect = viewer.get_node_or_null("ViewerImage") as TextureRect
	var dim_bg = viewer.get_node_or_null("DimBg") as ColorRect

	var target_scale = Vector2.ONE
	if _viewer_area and is_instance_valid(_viewer_area):
		var area_rect = _viewer_area.get_global_rect()
		var vp_size = get_viewport().get_visible_rect().size
		target_scale = Vector2(area_rect.size.x / vp_size.x, area_rect.size.y / vp_size.y)
	_viewer_area = null

	var tween = create_tween()
	if dim_bg:
		tween.tween_property(dim_bg, "color:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if img_rect:
		tween.parallel().tween_property(img_rect, "scale", target_scale, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(img_rect, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(viewer.queue_free)

func _set_sweep_progress(value: float, shader_mat: ShaderMaterial) -> void:
	shader_mat.set_shader_parameter("progress", value)

func _get_ref_dimensions(ctx: Dictionary) -> Vector2:
	var img_w: int = ctx.get("illustration_width", 0)
	var img_h: int = ctx.get("illustration_height", 0)
	if img_w > 0 and img_h > 0:
		return Vector2(img_w, img_h)
	var grid_x: int = ctx.get("grid_x", 1)
	var grid_y: int = ctx.get("grid_y", 1)
	return Vector2(grid_x * 160.0, grid_y * 160.0)

func _get_region_pixel_rect(index: int, img_w: int, img_h: int, ctx: Dictionary) -> Rect2:
	var puzzles = ctx["puzzles"]
	var grid_x: int = ctx["grid_x"]
	var grid_y: int = ctx["grid_y"]
	var has_valid: bool = ctx["has_valid_source_rects"]

	if has_valid:
		var sr = puzzles[index].source_rect
		if sr.has("x") and sr.has("y") and sr.has("w") and sr.has("h"):
			var scale_x = float(img_w) / _get_original_width(ctx)
			var scale_y = float(img_h) / _get_original_height(ctx)
			return Rect2(sr.x * scale_x, sr.y * scale_y, sr.w * scale_x, sr.h * scale_y)

	var col = index % grid_x
	var row = int(float(index) / grid_x)
	var cell_w = float(img_w) / grid_x
	var cell_h = float(img_h) / grid_y
	return Rect2(col * cell_w, row * cell_h, cell_w, cell_h)

func _get_original_width(ctx: Dictionary) -> float:
	var puzzles = ctx["puzzles"]
	var max_x = 0.0
	for puzzle in puzzles:
		var sr = puzzle.source_rect
		if sr.has("x") and sr.has("w"):
			max_x = max(max_x, float(sr.x) + float(sr.w))
	if max_x > 0:
		return max_x
	return float(ctx.get("illustration_width", 1))

func _get_original_height(ctx: Dictionary) -> float:
	var puzzles = ctx["puzzles"]
	var max_y = 0.0
	for puzzle in puzzles:
		var sr = puzzle.source_rect
		if sr.has("y") and sr.has("h"):
			max_y = max(max_y, float(sr.y) + float(sr.h))
	if max_y > 0:
		return max_y
	return float(ctx.get("illustration_height", 1))

func _get_illustration_layout(area: Control, ctx: Dictionary) -> Dictionary:
	var area_size = area.size
	var ref = _get_ref_dimensions(ctx)
	var ref_w = ref.x
	var ref_h = ref.y
	var grid_x: int = ctx.get("grid_x", 1)
	var grid_y: int = ctx.get("grid_y", 1)

	var total_gap_x = REGION_GAP * max(grid_x - 1, 0)
	var total_gap_y = REGION_GAP * max(grid_y - 1, 0)

	var img_aspect = ref_w / ref_h
	var area_aspect = (area_size.x - total_gap_x) / (area_size.y - total_gap_y)

	var result = {
		"offset_x": 0.0, "offset_y": 0.0,
		"display_w": 0.0, "display_h": 0.0,
		"cell_w": 0.0, "cell_h": 0.0
	}

	if area_size.x <= 0 or area_size.y <= 0:
		return result

	if img_aspect > area_aspect:
		result.display_w = area_size.x - total_gap_x
		result.display_h = result.display_w / img_aspect
		result.offset_y = (area_size.y - total_gap_y - result.display_h) / 2
	else:
		result.display_h = area_size.y - total_gap_y
		result.display_w = result.display_h * img_aspect
		result.offset_x = (area_size.x - total_gap_x - result.display_w) / 2

	if grid_x > 0:
		result.cell_w = result.display_w / grid_x
	if grid_y > 0:
		result.cell_h = result.display_h / grid_y

	return result

func _update_region_positions(area: Control = null) -> void:
	if area == null:
		area = _get_active_illustration_area()
	if not area.has_meta("illustration_ctx"):
		return

	var ctx: Dictionary = area.get_meta("illustration_ctx")
	var puzzles = ctx["puzzles"]
	if puzzles.is_empty():
		return

	var grid_x: int = ctx["grid_x"]
	var grid_y: int = ctx["grid_y"]
	var region_buttons: Dictionary = ctx["region_buttons"]

	var layout = _get_illustration_layout(area, ctx)
	if layout.display_w <= 0 or layout.display_h <= 0:
		return

	for i in range(puzzles.size()):
		var puzzle = puzzles[i]
		var btn = region_buttons.get(puzzle.id) as TextureButton
		if not btn or not is_instance_valid(btn):
			continue

		var col = i % grid_x
		var row = int(float(i) / grid_x)

		btn.position = Vector2(
			layout.offset_x + col * (layout.cell_w + REGION_GAP),
			layout.offset_y + row * (layout.cell_h + REGION_GAP)
		)
		btn.size = Vector2(layout.cell_w, layout.cell_h)

func _on_illustration_area_resized(area: Control) -> void:
	if _orientation_updating:
		return
	_update_illustration_layout(area)

func _on_region_clicked(puzzle: PuzzleData) -> void:
	var btn: TextureButton = null
	var target_picture_index: int = _current_picture_index

	for check_area in [p_illustration_area, l_illustration_area, l_illustration_area2]:
		if check_area.has_meta("illustration_ctx"):
			var ctx: Dictionary = check_area.get_meta("illustration_ctx")
			var region_buttons: Dictionary = ctx["region_buttons"]
			if region_buttons.has(puzzle.id):
				btn = region_buttons[puzzle.id]
				target_picture_index = ctx["picture_index"]
				break

	if btn and btn.has_meta("locked") and btn.get_meta("locked"):
		AudioManager.play_sfx("click")
		_show_toast(tr("完成前一张图片即可解锁"))
		return

	AudioManager.play_sfx("click")
	var target_picture_id = ""
	if target_picture_index >= 0 and target_picture_index < _pictures.size():
		target_picture_id = _pictures[target_picture_index].get("id", "")
	GameManager.pending_album_id = current_album_id
	GameManager.pending_picture_id = target_picture_id
	GameManager.pending_picture_index = target_picture_index
	GameManager.pending_puzzle_id = puzzle.id
	get_tree().change_scene_to_file("res://scenes/nonogram_scene.tscn")

func _generate_placeholder_illustration(ctx: Dictionary) -> Image:
	var base_w = 640
	var base_h = 360

	var grid_x: int = ctx.get("grid_x", 1)
	var grid_y: int = ctx.get("grid_y", 1)

	if grid_x > 0 and grid_y > 0:
		var aspect = float(grid_x) / float(grid_y)
		if aspect >= 1:
			base_w = 640
			base_h = int(640.0 / aspect)
		else:
			base_h = 480
			base_w = int(480.0 * aspect)

	var img = Image.create(base_w, base_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.94, 0.91))
	img.fill_rect(Rect2i(0, 0, base_w, int(base_h * 0.4)), Color(0.75, 0.85, 0.95, 0.4))
	img.fill_rect(Rect2i(0, int(base_h * 0.7), base_w, int(base_h * 0.3)), Color(0.6, 0.5, 0.35, 0.3))

	return img

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	GameManager.save_picture_index(current_album_id, _current_picture_index)
	GameManager.pending_album_id = current_album_id
	GameManager.pending_bookshelf_id = ""
	var album = AlbumDataScript.get_album(current_album_id)
	if not album.is_empty():
		GameManager.pending_bookshelf_id = album.get("bookshelf_id", "")
	get_tree().change_scene_to_file("res://scenes/book_shelf.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if _fullscreen_viewer:
			_close_fullscreen_viewer()
		else:
			_on_back_pressed()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _fullscreen_viewer:
			_close_fullscreen_viewer()
		else:
			_on_back_pressed()

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	settings_popup.show_settings()

func _on_left_button_pressed() -> void:
	var step = _get_step()
	if _current_picture_index > 0:
		#AudioManager.play_sfx("page_flip")
		_current_picture_index = max(0, _current_picture_index - step)
		_display_current_pages()

func _on_right_button_pressed() -> void:
	var step = _get_step()
	if _current_picture_index < _pictures.size() - 1:
		#AudioManager.play_sfx("page_flip")
		_current_picture_index = min(_pictures.size() - 1, _current_picture_index + step)
		_display_current_pages()

func _update_page_navigation() -> void:
	var display_index = _get_display_index()
	var can_go_left = display_index > 0
	var can_go_right = display_index < _pictures.size() - 1

	if portrait_ui.visible:
		p_page_num.text = "%d/%d" % [_current_picture_index + 1, _pictures.size()]
		p_left_button.visible = can_go_left
		p_right_button.visible = can_go_right
	else:
		l_page_num.text = "%d/%d" % [display_index + 1, _pictures.size()]
		l_left_button.visible = can_go_left
		l_right_button.visible = can_go_right

func _input(event: InputEvent) -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	if settings_popup.visible:
		return
	if _fullscreen_viewer:
		return
	if _has_badge_overlay():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_start_pos = event.position
		elif _swipe_start_pos != Vector2.ZERO:
			var delta = event.position - _swipe_start_pos
			if abs(delta.x) > _swipe_min_distance and abs(delta.x) > abs(delta.y):
				if delta.x > 0:
					_on_swipe_right()
				else:
					_on_swipe_left()
			else:
				_handle_illustration_tap(event.position)
			_swipe_start_pos = Vector2.ZERO

func _has_badge_overlay() -> bool:
	var badges = get_tree().get_nodes_in_group("badge_buttons")
	for badge in badges:
		if badge is TextureButton and badge._is_showing_overlay:
			return true
	return false

func _handle_illustration_tap(pos: Vector2) -> void:
	if Time.get_ticks_msec() - _viewer_close_msec < 300:
		return
	var canvas_pos = get_viewport().get_mouse_position()
	var areas = _get_active_illustration_areas()
	for area in areas:
		if not area:
			continue
		if not area.get_global_rect().has_point(canvas_pos):
			continue
		if not area.has_meta("illustration_ctx"):
			continue
		var ctx: Dictionary = area.get_meta("illustration_ctx")
		var picture_id: String = ctx.get("picture_id", "")
		if not GameManager.is_picture_completed(picture_id):
			continue
		_show_fullscreen_viewer(area)
		return

func _on_swipe_left() -> void:
	if _current_picture_index < _pictures.size() - 1:
		_on_right_button_pressed()

func _on_swipe_right() -> void:
	if _current_picture_index > 0:
		_on_left_button_pressed()

func _show_toast(message: String) -> void:
	ToastManager.show_toast(message)

func _on_orientation_changed(new_orientation: int) -> void:
	_apply_orientation(new_orientation)

func _apply_orientation(orientation: int) -> void:
	if not is_inside_tree():
		return
	if _orientation_switching:
		return
	_orientation_switching = true
	_orientation_generation += 1
	var gen = _orientation_generation
	_orientation_updating = true
	_loading_textures.clear()
	_pending_display = false
	_preload_pending = false
	_kill_area_tweens(p_illustration_area)
	_kill_area_tweens(l_illustration_area)
	_kill_area_tweens(l_illustration_area2)
	if p_illustration_area.has_meta("illustration_ctx"):
		p_illustration_area.remove_meta("illustration_ctx")
	if l_illustration_area.has_meta("illustration_ctx"):
		l_illustration_area.remove_meta("illustration_ctx")
	if l_illustration_area2.has_meta("illustration_ctx"):
		l_illustration_area2.remove_meta("illustration_ctx")
	_clear_area_children(p_illustration_area)
	_clear_area_children(l_illustration_area)
	_clear_area_children(l_illustration_area2)
	if orientation == OrientationManager.Orientation.PORTRAIT:
		portrait_ui.visible = true
		p_left_button.visible = true
		p_right_button.visible = true
		landscape_ui.visible = false
		l_left_button.visible = false
		l_right_button.visible = false
	else:
		portrait_ui.visible = false
		p_left_button.visible = false
		p_right_button.visible = false
		landscape_ui.visible = true
		l_left_button.visible = true
		l_right_button.visible = true
	_orientation_switching = false
	_rebuild_after_orientation.call_deferred(gen)

func _rebuild_after_orientation(gen: int) -> void:
	if not is_inside_tree():
		_orientation_updating = false
		return
	if gen != _orientation_generation:
		_orientation_updating = false
		return
	_orientation_updating = false
	_display_current_pages()

func _schedule_preload_adjacent() -> void:
	if _preload_pending:
		return
	_preload_pending = true
	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree():
		_preload_pending = false
		return
	_do_preload_adjacent()

func _do_preload_adjacent() -> void:
	_preload_pending = false
	var display_index = _get_display_index()
	var step = _get_step()
	var indices = []
	var next_idx = display_index + step
	if next_idx < _pictures.size():
		indices.append(next_idx)
	var prev_idx = display_index - step
	if prev_idx >= 0:
		indices.append(prev_idx)
	if _is_landscape():
		var next2 = display_index + step + 1
		if next2 < _pictures.size():
			indices.append(next2)
		if prev_idx >= 0 and prev_idx + 1 < _pictures.size():
			indices.append(prev_idx + 1)
	for idx in indices:
		var picture = _pictures[idx]
		var pic_id = picture.get("id", "")
		if _texture_cache.has(pic_id):
			continue
		_preload_picture_resources(picture)

func _preload_picture_resources(picture: Dictionary) -> void:
	var pic_id = picture.get("id", "")
	var puzzle_ids = picture.get("puzzles", [])
	for pid in puzzle_ids:
		if not _puzzle_cache.has(pid):
			var puzzle = PuzzleDataScript.load_puzzle(pid)
			if puzzle:
				_puzzle_cache[pid] = puzzle

	var img_path = picture.get("image", "")
	if _texture_cache.has(pic_id):
		return
	if _loading_textures.has(pic_id):
		return

	if img_path != "" and ResourceLoader.exists(img_path):
		ResourceLoader.load_threaded_request(img_path, "", false)
		_loading_textures[pic_id] = {
			"img_path": img_path,
			"picture": picture,
			"state": "loading_illust",
			"illust_tex": null,
			"pixel_tex": null,
			"ctx": {}
		}
		if not _pending_display:
			_pending_display = true
			_process_texture_loading.call_deferred()

func _process_texture_loading() -> void:
	if not is_inside_tree():
		_pending_display = false
		return
	_pending_display = false
	var keys = _loading_textures.keys()
	for pic_id in keys:
		if not _loading_textures.has(pic_id):
			continue
		var info = _loading_textures[pic_id]
		var state: String = info.get("state", "")

		if state == "loading_illust":
			var img_path: String = info["img_path"]
			var status = ResourceLoader.load_threaded_get_status(img_path)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				var illust_tex = ResourceLoader.load_threaded_get(img_path) as Texture2D
				if illust_tex:
					info["illust_tex"] = illust_tex
					var picture: Dictionary = info["picture"]
					var pixel_path = picture.get("pixel_image", "")
					if pixel_path == "":
						pixel_path = img_path.get_basename() + "_nonogram_pixel.jpg"
					if pixel_path != "" and ResourceLoader.exists(pixel_path):
						ResourceLoader.load_threaded_request(pixel_path, "", false)
						info["state"] = "loading_pixel"
						info["pixel_path"] = pixel_path
					else:
						info["state"] = "done"
				else:
					info["state"] = "done"
			elif status == ResourceLoader.THREAD_LOAD_FAILED:
				info["state"] = "done"
		elif state == "loading_pixel":
			var pixel_path: String = info.get("pixel_path", "")
			var status = ResourceLoader.load_threaded_get_status(pixel_path)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				var pixel_tex = ResourceLoader.load_threaded_get(pixel_path) as Texture2D
				info["pixel_tex"] = pixel_tex
				info["state"] = "done"
			elif status == ResourceLoader.THREAD_LOAD_FAILED:
				info["state"] = "done"

		if info.get("state", "") == "done":
			var illust_tex: Texture2D = info.get("illust_tex")
			if illust_tex:
				_texture_cache[pic_id] = {
					"illust_tex": illust_tex,
					"pixel_tex": info.get("pixel_tex"),
					"img_w": illust_tex.get_width(),
					"img_h": illust_tex.get_height()
				}
				_texture_lru.append(pic_id)
				_evict_texture_cache()
			_loading_textures.erase(pic_id)

	if not _loading_textures.is_empty():
		_pending_display = true
		await get_tree().process_frame
		if not is_inside_tree():
			_pending_display = false
			return
		_process_texture_loading()


func _get_active_medals_container() -> HBoxContainer:
	if _is_landscape():
		return l_medals_container
	return p_medals_container


func _setup_chapter_badges() -> void:
	_clear_medals_container(p_medals_container)
	_clear_medals_container(l_medals_container)

	if current_album_id == "":
		return

	var chapters = AlbumDataScript.get_chapters(current_album_id)
	if chapters.is_empty():
		return

	var just_completed_pic_id = _get_just_completed_picture_id()

	for chapter in chapters:
		var chapter_id: String = chapter.get("id", "")
		var chapter_name: String = GameManager.get_localized(chapter, "name")
		var picture_ids = chapter.get("picture_ids", [])

		var completed_count = 0
		for pid in picture_ids:
			if GameManager.is_picture_completed(pid):
				completed_count += 1

		if just_completed_pic_id != "" and just_completed_pic_id in picture_ids:
			completed_count -= 1

		var total_count = picture_ids.size()

		var badge_icon_path: String = chapter.get("badge_icon", "")
		var badge_tex: Texture2D = null
		if badge_icon_path != "" and ResourceLoader.exists(badge_icon_path):
			badge_tex = load(badge_icon_path) as Texture2D
		var badge_icon_grey_path = badge_icon_path.get_basename() + "_grey.png"
		var badge_grey_tex: Texture2D = null
		if badge_icon_grey_path != "" and ResourceLoader.exists(badge_icon_grey_path):
			badge_grey_tex = load(badge_icon_grey_path) as Texture2D

		if badge_tex:
			_add_badge_to_container(p_medals_container, chapter_id, chapter_name, badge_tex, badge_grey_tex, completed_count, total_count, badge_icon_path)
			_add_badge_to_container(l_medals_container, chapter_id, chapter_name, badge_tex, badge_grey_tex, completed_count, total_count, badge_icon_path)


func _clear_medals_container(container: HBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _add_badge_to_container(container: HBoxContainer, chapter_id: String, chapter_name: String, badge_tex: Texture2D, badge_grey_tex: Texture2D, completed_count: int, total_count: int, badge_icon_path: String = "") -> void:
	var badge = BadgeButtonScene.instantiate()
	badge.name = "Badge_" + chapter_id
	container.add_child(badge)
	badge.setup(chapter_id, chapter_name, badge_tex, badge_grey_tex, completed_count, total_count, badge_icon_path)


func _get_just_completed_picture_id() -> String:
	if _just_completed_puzzle_id == "":
		return ""
	var pictures = _pictures
	for picture in pictures:
		var puzzle_ids = picture.get("puzzles", [])
		if _just_completed_puzzle_id in puzzle_ids:
			return picture.get("id", "")
	return ""


func _update_chapter_badges() -> void:
	if current_album_id == "":
		return

	var chapters = AlbumDataScript.get_chapters(current_album_id)
	if chapters.is_empty():
		return

	for chapter in chapters:
		var chapter_id: String = chapter.get("id", "")
		var picture_ids = chapter.get("picture_ids", [])

		var completed_count = 0
		for pid in picture_ids:
			if GameManager.is_picture_completed(pid):
				completed_count += 1
		var total_count = picture_ids.size()

		for container in [p_medals_container, l_medals_container]:
			var badge = container.get_node_or_null("Badge_" + chapter_id)
			if badge and badge.has_method("update_progress"):
				badge.update_progress(completed_count, total_count)


func _find_chapter_for_picture(picture_id: String) -> Dictionary:
	if current_album_id == "":
		return {}
	var chapters = AlbumDataScript.get_chapters(current_album_id)
	for chapter in chapters:
		var picture_ids = chapter.get("picture_ids", [])
		if picture_id in picture_ids:
			return chapter
	return {}


func _find_illustration_area_for_picture(picture_id: String) -> Control:
	var areas = _get_active_illustration_areas()
	for area in areas:
		if not is_instance_valid(area):
			continue
		if not area.has_meta("illustration_ctx"):
			continue
		var ctx: Dictionary = area.get_meta("illustration_ctx")
		if ctx.get("picture_id", "") == picture_id:
			return area
	if not areas.is_empty():
		return areas[0]
	return null


func _play_light_fly_to_badge(picture_id: String) -> void:
	if not is_inside_tree():
		return
	var chapter = _find_chapter_for_picture(picture_id)
	if chapter.is_empty():
		_update_chapter_badges()
		return

	var chapter_id: String = chapter.get("id", "")
	var active_container = _get_active_medals_container()
	var badge = active_container.get_node_or_null("Badge_" + chapter_id)
	if not badge:
		_update_chapter_badges()
		return

	var area = _find_illustration_area_for_picture(picture_id)
	if not area:
		_update_chapter_badges()
		return

	var area_rect = area.get_global_rect()
	var start_pos = area_rect.position + area_rect.size * 0.5
	var end_pos = badge.get_global_center()

	var light = _create_light_particle()
	$CanvasLayer.add_child(light)
	light.global_position = start_pos - light.size * 0.5

	var distance = start_pos.distance_to(end_pos)
	var duration = clampf(distance / 800.0, 0.4, 1.0)
	var target_pos = end_pos - light.size * 0.5

	var tween = create_tween()
	AnimationManager.register_tween(tween)

	tween.tween_property(light, "global_position:x", target_pos.x, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(light, "global_position:y", target_pos.y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(light, "modulate:a", 0.8, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(light, "scale", Vector2(0.6, 0.6), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tween.tween_callback(func():
		if not is_inside_tree():
			if is_instance_valid(light):
				light.queue_free()
			return
		if is_instance_valid(light):
			light.queue_free()
		if is_instance_valid(badge) and badge.has_method("increment_count"):
			badge.increment_count()
			badge.play_receive_light_animation()
		var other_container = l_medals_container if active_container == p_medals_container else p_medals_container
		var other_badge = other_container.get_node_or_null("Badge_" + chapter_id)
		if other_badge and other_badge.has_method("increment_count"):
			other_badge.increment_count()
	)


func _create_light_particle() -> Control:
	var container = Control.new()
	container.name = "LightParticle"
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.z_index = 100
	container.size = Vector2(48, 48)

	var glow_outer = ColorRect.new()
	glow_outer.name = "GlowOuter"
	glow_outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	var outer_mat = ShaderMaterial.new()
	outer_mat.shader = preload("res://shaders/light_glow.gdshader")
	outer_mat.set_shader_parameter("color", Vector3(1.0, 1.0, 1.0))
	outer_mat.set_shader_parameter("intensity", 0.6)
	glow_outer.material = outer_mat
	glow_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(glow_outer)

	var glow_inner = ColorRect.new()
	glow_inner.name = "GlowInner"
	glow_inner.set_anchors_preset(Control.PRESET_CENTER)
	glow_inner.offset_left = -10.0
	glow_inner.offset_top = -10.0
	glow_inner.offset_right = 10.0
	glow_inner.offset_bottom = 10.0
	var inner_mat = ShaderMaterial.new()
	inner_mat.shader = preload("res://shaders/light_glow.gdshader")
	inner_mat.set_shader_parameter("color", Vector3(1.0, 1.0, 1.0))
	inner_mat.set_shader_parameter("intensity", 1.2)
	glow_inner.material = inner_mat
	glow_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(glow_inner)

	var core = ColorRect.new()
	core.name = "Core"
	core.set_anchors_preset(Control.PRESET_CENTER)
	core.offset_left = -4.0
	core.offset_top = -4.0
	core.offset_right = 4.0
	core.offset_bottom = 4.0
	core.color = Color(1.0, 1.0, 1.0, 1.0)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(core)

	container.pivot_offset = container.size * 0.5
	return container

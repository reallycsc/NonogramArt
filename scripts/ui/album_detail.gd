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

@onready var portrait_ui: Control = $PortraitUI
@onready var landscape_ui: Control = $LandscapeUI
@onready var portrait_canvas: CanvasLayer = $PortraitUI/CanvasLayer
@onready var landscape_canvas: CanvasLayer = $LandscapeUI/CanvasLayer

@onready var p_page: Control = $PortraitUI/PageContent
@onready var p_title: Label = $PortraitUI/PageContent/Title
@onready var p_illustration_area: Control = $PortraitUI/PageContent/VBoxContainer/IllustrationArea
@onready var p_album_text: Label = $PortraitUI/PageContent/VBoxContainer/AlbumText
@onready var p_page_num: Label = $PortraitUI/PageContent/PageNumLabel
@onready var p_settings_popup: Control = $PortraitUI/CanvasLayer/SettingsPopup
@onready var p_left_button: TextureButton = $PortraitUI/CanvasLayer/LeftButton
@onready var p_right_button: TextureButton = $PortraitUI/CanvasLayer/RightButton

@onready var l_page: Control = $LandscapeUI/PageContent
@onready var l_title: Label = $LandscapeUI/PageContent/Title
@onready var l_illustration_area: Control = $LandscapeUI/PageContent/VBoxContainer/IllustrationArea
@onready var l_album_text: Label = $LandscapeUI/PageContent/VBoxContainer/AlbumText
@onready var l_page_num: Label = $LandscapeUI/PageContent/PageNumLabel
@onready var l_settings_popup: Control = $LandscapeUI/CanvasLayer/SettingsPopup
@onready var l_left_button: TextureButton = $LandscapeUI/CanvasLayer/LeftButton
@onready var l_right_button: TextureButton = $LandscapeUI/CanvasLayer/RightButton

@onready var l_page2: Control = $LandscapeUI/PageContent2
@onready var l_title2: Label = $LandscapeUI/PageContent2/Title
@onready var l_illustration_area2: Control = $LandscapeUI/PageContent2/VBoxContainer/IllustrationArea
@onready var l_album_text2: Label = $LandscapeUI/PageContent2/VBoxContainer/AlbumText
@onready var l_page_num2: Label = $LandscapeUI/PageContent2/PageNumLabel

var current_album_id: String = ""
var current_picture_id: String = ""
var _pictures: Array = []
var _current_picture_index: int = 0
var _fade_tween: Tween = null

var _puzzle_cache: Dictionary = {}
var _texture_cache: Dictionary = {}
var _texture_lru: Array = []
const MAX_CACHED_PICTURES: int = 6

var _preload_pending: bool = false

var _swipe_start_pos: Vector2 = Vector2.ZERO
var _swipe_min_distance: float = 50.0

const REGION_GAP: float = 0.0

var _fullscreen_viewer: CanvasLayer = null

func _ready() -> void:
	p_illustration_area.resized.connect(_on_illustration_area_resized.bind(p_illustration_area))
	l_illustration_area.resized.connect(_on_illustration_area_resized.bind(l_illustration_area))
	l_illustration_area2.resized.connect(_on_illustration_area_resized.bind(l_illustration_area2))
	if GameManager.pending_album_id != "":
		current_album_id = GameManager.pending_album_id
		GameManager.pending_album_id = ""
		_load_pictures_list()
	AudioManager.play_bgm_for_album(current_album_id)
	OrientationManager.orientation_changed.connect(_on_orientation_changed)
	_apply_orientation(OrientationManager.current_orientation)

func _exit_tree() -> void:
	if OrientationManager.orientation_changed.is_connected(_on_orientation_changed):
		OrientationManager.orientation_changed.disconnect(_on_orientation_changed)
	if _fullscreen_viewer:
		_fullscreen_viewer.queue_free()
		_fullscreen_viewer = null
	_puzzle_cache.clear()
	_texture_cache.clear()
	_texture_lru.clear()

func _is_landscape() -> bool:
	return landscape_ui.visible

func _get_active_illustration_area() -> Control:
	if _is_landscape():
		return l_illustration_area
	return p_illustration_area

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

	if _is_landscape() and _current_picture_index % 2 == 1 and _current_picture_index > 0:
		_current_picture_index -= 1

	_display_current_pages()

func _display_current_pages() -> void:
	var picture = _pictures[_current_picture_index]
	current_picture_id = picture.get("id", "")
	_load_picture(picture, p_title, p_illustration_area, p_album_text, p_page_num, _current_picture_index)

	if _is_landscape():
		_load_picture(picture, l_title, l_illustration_area, l_album_text, l_page_num, _current_picture_index)
		var second_index = _current_picture_index + 1
		if second_index < _pictures.size():
			l_page2.visible = true
			var picture2 = _pictures[second_index]
			_load_picture(picture2, l_title2, l_illustration_area2, l_album_text2, l_page_num2, second_index)
		else:
			l_page2.visible = false
			_clear_page(l_title2, l_illustration_area2, l_album_text2, l_page_num2)

	_update_page_navigation()
	_schedule_preload_adjacent()

func _clear_page(title: Label, area: Control, text: Label, page_num: Label) -> void:
	title.text = ""
	text.text = ""
	page_num.text = ""
	_stop_typewriter(area)
	if area.has_meta("illustration_ctx"):
		area.remove_meta("illustration_ctx")
	var children = area.get_children()
	for child in children:
		area.remove_child(child)
		child.free()

func _load_picture(picture: Dictionary, title: Label, area: Control, text_label: Label, page_num: Label, picture_index: int) -> void:
	var pic_id = picture.get("id", "")
	var title_text = picture.get("title", "")
	page_num.text = "%d/%d" % [picture_index + 1, _pictures.size()]

	var full_text = picture.get("full_text", "")

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
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
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
	if area.has_meta("illustration_ctx"):
		area.remove_meta("illustration_ctx")

	var ctx: Dictionary = {}
	var pic_id = picture.get("id", "")
	ctx["picture_id"] = pic_id
	ctx["picture_index"] = picture_index
	ctx["region_buttons"] = {}

	var children = area.get_children()
	for child in children:
		area.remove_child(child)
		child.free()

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
		var illust_tex: Texture2D = null
		var pixel_tex: Texture2D = null
		var img_w: int = 0
		var img_h: int = 0

		if img_path != "" and ResourceLoader.exists(img_path):
			var tex = ResourceLoader.load(img_path, "", ResourceLoader.CACHE_MODE_IGNORE)
			if tex is Texture2D:
				illust_tex = tex
				img_w = tex.get_width()
				img_h = tex.get_height()

		if illust_tex == null:
			var placeholder_img = _generate_placeholder_illustration(ctx)
			illust_tex = ImageTexture.create_from_image(placeholder_img)
			img_w = illust_tex.get_width()
			img_h = illust_tex.get_height()

		var base_path = img_path.get_basename()
		var pixel_path = base_path + "_nonogram_pixel.jpg"
		if ResourceLoader.exists(pixel_path):
			var tex = ResourceLoader.load(pixel_path, "", ResourceLoader.CACHE_MODE_IGNORE)
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

		while _texture_lru.size() > MAX_CACHED_PICTURES:
			var evict_id = _texture_lru.pop_front()
			_texture_cache.erase(evict_id)

	area.set_meta("illustration_ctx", ctx)

	_create_illustration_display(area, ctx)

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
	if GameManager.is_picture_completed(picture_id):
		_create_completed_display(area, ctx)
		return

	var puzzles = ctx["puzzles"]
	var is_locked = _is_picture_locked(ctx["picture_index"])

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
		else:
			var source_tex: Texture2D = ctx["pixel_texture"]
			if source_tex == null:
				source_tex = ctx["illustration_texture"]
			if source_tex:
				var region = _get_region_pixel_rect(i, source_tex.get_width(), source_tex.get_height(), ctx)
				var atlas = AtlasTexture.new()
				atlas.atlas = source_tex
				atlas.region = region
				var region_img = atlas.get_image()
				var target_size = 160
				region_img.resize(target_size, target_size, Image.INTERPOLATE_NEAREST)
				var small_tex = ImageTexture.create_from_image(region_img)
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

	if pixel_tex and illust_tex and should_animate:
		var pixel_rect = TextureRect.new()
		pixel_rect.name = "PixelArtRect"
		pixel_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pixel_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pixel_rect.texture = pixel_tex
		area.add_child(pixel_rect)
		_update_completed_illustration_layout(area)

		var hd_rect = TextureRect.new()
		hd_rect.name = "HDImageRect"
		hd_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		hd_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hd_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hd_rect.texture = illust_tex
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = preload("res://shaders/sweep_reveal.gdshader")
		shader_mat.set_shader_parameter("progress", 0.0)
		shader_mat.set_shader_parameter("sweep_width", 0.08)
		hd_rect.material = shader_mat
		area.add_child(hd_rect)

		if _fade_tween:
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_method(_set_sweep_progress.bind(shader_mat), 0.0, 1.15, 1.5)
		_fade_tween.tween_callback(_on_animation_finished.bind(picture_id))
		_fade_tween.tween_callback(_enable_hd_click.bind(area))
	elif illust_tex:
		var hd_rect = TextureRect.new()
		hd_rect.name = "HDImageRect"
		hd_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		hd_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hd_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hd_rect.texture = illust_tex
		hd_rect.gui_input.connect(_on_hd_image_input.bind(area))
		area.add_child(hd_rect)
	elif pixel_tex:
		var pixel_rect = TextureRect.new()
		pixel_rect.name = "PixelArtRect"
		pixel_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pixel_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pixel_rect.texture = pixel_tex
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

func _on_animation_finished(pic_id: String) -> void:
	GameManager.mark_animation_shown(pic_id)

func _enable_hd_click(area: Control) -> void:
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

	var canvas = CanvasLayer.new()
	canvas.layer = 100

	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0)

	var img_rect = TextureRect.new()
	img_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img_rect.texture = illust_tex

	var back_btn = TextureButton.new()
	back_btn.offset_left = 20.0
	back_btn.offset_top = 20.0
	back_btn.offset_right = 122.0
	back_btn.offset_bottom = 124.0
	back_btn.texture_normal = preload("res://assets/images/ui/back_button.png")
	back_btn.texture_pressed = preload("res://assets/images/ui/back_button_pressed.png")
	back_btn.texture_hover = preload("res://assets/images/ui/back_button_hover.png")
	back_btn.z_index = 10

	canvas.add_child(img_rect)
	canvas.add_child(overlay)
	canvas.add_child(back_btn)
	add_child(canvas)

	back_btn.pressed.connect(_close_fullscreen_viewer)
	overlay.gui_input.connect(_on_viewer_overlay_input)

	_fullscreen_viewer = canvas
	img_rect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(img_rect, "modulate:a", 1.0, 0.3)

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
	var tween = create_tween()
	tween.tween_property(viewer, "modulate:a", 0.0, 0.2)
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
		_show_toast("完成前一张图片即可解锁")
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

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	if portrait_ui.visible:
		p_settings_popup.show_settings()
	else:
		l_settings_popup.show_settings()

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
	var can_go_left = _current_picture_index > 0
	var can_go_right = _current_picture_index < _pictures.size() - 1

	if portrait_ui.visible:
		p_page_num.text = "%d/%d" % [_current_picture_index + 1, _pictures.size()]
		p_left_button.visible = can_go_left
		p_right_button.visible = can_go_right
	else:
		l_page_num.text = "%d/%d" % [_current_picture_index + 1, _pictures.size()]
		l_left_button.visible = can_go_left
		l_right_button.visible = can_go_right

func _input(event: InputEvent) -> void:
	if not DisplayServer.is_touchscreen_available():
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
			_swipe_start_pos = Vector2.ZERO

func _on_swipe_left() -> void:
	if _current_picture_index < _pictures.size() - 1:
		_on_right_button_pressed()

func _on_swipe_right() -> void:
	if _current_picture_index > 0:
		_on_left_button_pressed()

func _show_toast(message: String) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 16.0
	style.content_margin_top = 8.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.modulate.a = 0.0
	add_child(panel)
	panel.offset_left = -panel.size.x / 2
	panel.offset_top = -panel.size.y / 2
	panel.offset_right = panel.size.x / 2
	panel.offset_bottom = panel.size.y / 2
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.label_settings = LabelSettings.new()
	label.label_settings.font_color = Color.WHITE
	label.label_settings.font_size = 24
	label.label_settings.outline_color = Color.BLACK
	label.label_settings.outline_size = 2
	panel.add_child(label)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "position:y", panel.position.y - 60, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.chain().tween_interval(1.0)
	tween.chain().tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(panel.queue_free)

func _on_orientation_changed(new_orientation: int) -> void:
	_apply_orientation(new_orientation)

func _apply_orientation(orientation: int) -> void:
	if not is_inside_tree():
		return
	if orientation == OrientationManager.Orientation.PORTRAIT:
		portrait_ui.visible = true
		portrait_canvas.visible = true
		landscape_ui.visible = false
		landscape_canvas.visible = false
	else:
		portrait_ui.visible = false
		portrait_canvas.visible = false
		landscape_ui.visible = true
		landscape_canvas.visible = true
	if _is_landscape() and _current_picture_index % 2 == 1 and _current_picture_index > 0:
		_current_picture_index -= 1
	_display_current_pages()

func _schedule_preload_adjacent() -> void:
	if _preload_pending:
		return
	_preload_pending = true
	await get_tree().create_timer(0.1).timeout
	_do_preload_adjacent()

func _do_preload_adjacent() -> void:
	_preload_pending = false
	var step = _get_step()
	var indices = []
	var next_idx = _current_picture_index + step
	if next_idx < _pictures.size():
		indices.append(next_idx)
	var prev_idx = _current_picture_index - step
	if prev_idx >= 0:
		indices.append(prev_idx)
	if _is_landscape():
		var next2 = _current_picture_index + step + 1
		if next2 < _pictures.size():
			indices.append(next2)
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

	var illust_tex: Texture2D = null
	var pixel_tex: Texture2D = null
	var img_w: int = 0
	var img_h: int = 0

	if img_path != "" and ResourceLoader.exists(img_path):
		var tex = ResourceLoader.load(img_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if tex is Texture2D:
			illust_tex = tex
			img_w = tex.get_width()
			img_h = tex.get_height()

	if illust_tex == null:
		return

	var base_path = img_path.get_basename()
	var pixel_path = base_path + "_nonogram_pixel.jpg"
	if ResourceLoader.exists(pixel_path):
		var tex = ResourceLoader.load(pixel_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if tex is Texture2D:
			pixel_tex = tex

	_texture_cache[pic_id] = {
		"illust_tex": illust_tex,
		"pixel_tex": pixel_tex,
		"img_w": img_w,
		"img_h": img_h
	}
	_texture_lru.append(pic_id)

	while _texture_lru.size() > MAX_CACHED_PICTURES:
		var evict_id = _texture_lru.pop_front()
		_texture_cache.erase(evict_id)

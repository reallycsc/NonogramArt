extends Control

const LeaderboardDataScript = preload("res://scripts/data/leaderboard_data.gd")
const RankRowScene = preload("res://scenes/rank_row.tscn")

const TAB_ACTIVE_FONT_COLOR := Color(1, 1, 1, 1)
const TAB_ACTIVE_OUTLINE_COLOR := Color(0.8039216, 0.4509804, 0.043137256, 1)
const TAB_ACTIVE_OUTLINE_SIZE := 10
const TAB_INACTIVE_FONT_COLOR := Color(0.31764707, 0.1882353, 0.078431375, 1)
const TAB_INACTIVE_OUTLINE_COLOR := Color(0, 0, 0, 0)
const TAB_INACTIVE_OUTLINE_SIZE := 0

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var panel: Panel = $PanelContainer
@onready var close_button: TextureButton = $PanelContainer/CloseButton
@onready var title_label: Label = $PanelContainer/TitleLabel
@onready var tab_global: TextureButton = $PanelContainer/TabBar/GlobalTab
@onready var tab_friends: TextureButton = $PanelContainer/TabBar/FriendsTab
@onready var tab_regional: TextureButton = $PanelContainer/TabBar/RegionalTab
@onready var region_dropdown: OptionButton = $PanelContainer/RegionButton
@onready var refresh_hint: Label = $PanelContainer/RefreshHint
@onready var scroll: ScrollContainer = $PanelContainer/ScrollContainer
@onready var list: VBoxContainer = $PanelContainer/ScrollContainer/ListContainer
@onready var my_rank_container: Control = $PanelContainer/MyRankContainer

var _data = null
var _current_tab: int = 0
var _refresh_timer: Timer = null
var _is_loading: bool = false
var _my_rank_row: Control = null
var _my_score: Dictionary = {}
var _waiting_for_scores: bool = false

const SCROLL_TOP := 280.0
const SCROLL_BOTTOM := -105.0


func _ready() -> void:
	visible = false
	_data = LeaderboardDataScript.new()
	_current_tab = _data.TabType.GLOBAL

	close_button.pressed.connect(_on_close_pressed)
	dim_overlay.gui_input.connect(_on_dim_overlay_input)

	tab_global.pressed.connect(_on_tab_pressed.bind(_data.TabType.GLOBAL))
	tab_friends.pressed.connect(_on_tab_pressed.bind(_data.TabType.FRIENDS))

	tab_regional.visible = false
	region_dropdown.visible = false

	_refresh_timer = Timer.new()
	_refresh_timer.one_shot = true
	add_child(_refresh_timer)

	_select_tab(_current_tab)

	if TapTapManager.is_available() and not TapTapManager.is_mock_mode():
		TapTapManager.leaderboard_scores.connect(_on_taptap_scores_updated)
		TapTapManager.leaderboard_user_score.connect(_on_taptap_user_score)
		TapTapManager.leaderboard_result.connect(_on_taptap_leaderboard_result)

	GameManager.progress_changed.connect(_on_local_progress_changed)
	OrientationManager.orientation_changed.connect(_on_orientation_changed)


func _exit_tree() -> void:
	if _refresh_timer and is_instance_valid(_refresh_timer):
		_refresh_timer.queue_free()
	if GameManager.progress_changed.is_connected(_on_local_progress_changed):
		GameManager.progress_changed.disconnect(_on_local_progress_changed)
	if OrientationManager.orientation_changed.is_connected(_on_orientation_changed):
		OrientationManager.orientation_changed.disconnect(_on_orientation_changed)


func show_leaderboard() -> void:
	if visible:
		return
	_apply_orientation_layout()
	_select_tab(_current_tab)
	_load_leaderboard()
	var target_scale = _get_panel_scale()
	visible = true
	panel.scale = target_scale * 0.8
	panel.modulate.a = 0.0
	dim_overlay.color = Color(0, 0, 0, 0.0)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.8), 0.3)
	tween.tween_property(panel, "scale", target_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func _get_panel_scale() -> Vector2:
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size.x > viewport_size.y:
		var scale_ratio = viewport_size.y / 1280.0
		return Vector2(scale_ratio, scale_ratio)
	return Vector2.ONE


func _on_orientation_changed(_orientation: int) -> void:
	if visible:
		_apply_orientation_layout()


func _apply_orientation_layout() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var is_wide = viewport_size.x > viewport_size.y
	var panel_h = panel.offset_bottom - panel.offset_top
	if is_wide:
		var scale_ratio = viewport_size.y / 1280.0
		panel.scale = Vector2(scale_ratio, scale_ratio)
		panel.pivot_offset = Vector2(panel.pivot_offset.x, panel_h / 2.0)
	else:
		panel.scale = Vector2.ONE
		panel.pivot_offset = Vector2(310, 350)
	panel.offset_top = -panel_h / 2.0
	panel.offset_bottom = panel_h / 2.0


func hide_leaderboard() -> void:
	AudioManager.play_sfx("click")
	if _refresh_timer and is_instance_valid(_refresh_timer):
		_refresh_timer.stop()
	var target_scale = _get_panel_scale() * 0.8
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", target_scale, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.0), 0.15)
	tween.chain().tween_callback(func():
		visible = false
	)


func _on_dim_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close_pressed()
	elif event is InputEventScreenTouch and event.pressed:
		_on_close_pressed()


func _select_tab(tab: int) -> void:
	_current_tab = tab

	tab_global.button_pressed = (tab == _data.TabType.GLOBAL)
	tab_friends.button_pressed = (tab == _data.TabType.FRIENDS)
	tab_regional.button_pressed = false

	_apply_tab_label_style(tab_global, tab == _data.TabType.GLOBAL)
	_apply_tab_label_style(tab_friends, tab == _data.TabType.FRIENDS)
	_apply_tab_label_style(tab_regional, false)

	scroll.offset_top = SCROLL_TOP

	var interval = _data.get_refresh_interval_seconds(tab)
	if interval >= 60:
		refresh_hint.text = tr("排行榜每%d分钟更新一次") % (interval / 60)
	else:
		refresh_hint.text = tr("排行榜每%d秒更新一次") % interval


func _apply_tab_label_style(btn: TextureButton, active: bool) -> void:
	var label = btn.get_node_or_null("Label")
	if label == null:
		return
	if active:
		label.add_theme_color_override("font_color", TAB_ACTIVE_FONT_COLOR)
		label.add_theme_color_override("font_outline_color", TAB_ACTIVE_OUTLINE_COLOR)
		label.add_theme_constant_override("outline_size", TAB_ACTIVE_OUTLINE_SIZE)
	else:
		label.add_theme_color_override("font_color", TAB_INACTIVE_FONT_COLOR)
		label.add_theme_color_override("font_outline_color", TAB_INACTIVE_OUTLINE_COLOR)
		label.add_theme_constant_override("outline_size", TAB_INACTIVE_OUTLINE_SIZE)


func _on_tab_pressed(tab: int) -> void:
	AudioManager.play_sfx("click")
	if tab == _current_tab:
		var btn = _get_tab_button(tab)
		if btn:
			btn.button_pressed = true
		return
	_select_tab(tab)
	_load_leaderboard()


func _get_tab_button(tab: int) -> TextureButton:
	match tab:
		_data.TabType.GLOBAL:
			return tab_global
		_data.TabType.FRIENDS:
			return tab_friends
	return null


func _load_leaderboard() -> void:
	if _is_loading:
		return
	_is_loading = true
	_waiting_for_scores = true

	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

	if _my_rank_row and is_instance_valid(_my_rank_row):
		_my_rank_row.queue_free()
		_my_rank_row = null

	var data = _data.get_leaderboard(_current_tab)

	if TapTapManager.is_available() and TapTapManager.is_logged_in() and not TapTapManager.is_mock_mode():
		var collection = "PUBLIC" if _current_tab == _data.TabType.GLOBAL else "FRIENDS"
		TapTapManager.load_current_user_score(LeaderboardDataScript.LEADERBOARD_ID, collection)

	if data.is_empty():
		var hint = Label.new()
		hint.name = "LoadingHint"
		hint.set_anchors_preset(Control.PRESET_CENTER, true)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint.text = tr("加载中...")
		hint.add_theme_font_size_override("font_size", 24)
		list.add_child(hint)
	else:
		_display_data(data)

	_is_loading = false
	_schedule_refresh()


func _display_data(data: Array) -> void:
	var me_entry: Dictionary = {}
	for entry in data:
		if entry.get("is_me", false):
			me_entry = entry
			break

	if me_entry.is_empty() and not _my_score.is_empty():
		me_entry = _my_score

	for entry in data:
		var row = RankRowScene.instantiate()
		list.add_child(row)
		row.setup(entry, false)

	if not me_entry.is_empty():
		_my_rank_row = RankRowScene.instantiate()
		my_rank_container.add_child(_my_rank_row)
		_my_rank_row.setup(me_entry, false, true)
		my_rank_container.visible = true
	else:
		my_rank_container.visible = false


func _schedule_refresh() -> void:
	var interval = _data.get_refresh_interval_seconds(_current_tab)
	if _refresh_timer and is_instance_valid(_refresh_timer):
		_refresh_timer.stop()
		if _refresh_timer.timeout.is_connected(_on_auto_refresh):
			_refresh_timer.timeout.disconnect(_on_auto_refresh)
		_refresh_timer.start(interval)
		_refresh_timer.timeout.connect(_on_auto_refresh)


func _on_auto_refresh() -> void:
	if not is_inside_tree() or not visible:
		return
	_data.invalidate_cache(_current_tab)
	_load_leaderboard()


func _on_local_progress_changed() -> void:
	LeaderboardDataScript.mark_dirty()
	if is_inside_tree() and visible:
		_data.invalidate_cache(_current_tab)
		_load_leaderboard()


func _on_close_pressed() -> void:
	hide_leaderboard()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_on_close_pressed()
		get_viewport().set_input_as_handled()


func _on_taptap_scores_updated(scores_json: String) -> void:
	if not is_inside_tree() or not visible:
		return
	var data = _data._parse_taptap_scores(scores_json)
	if not data.is_empty():
		data.sort_custom(func(a, b): return a.score > b.score)
		for i in range(data.size()):
			data[i]["rank"] = i + 1
		match _current_tab:
			_data.TabType.GLOBAL:
				LeaderboardDataScript._global_cache = data
				LeaderboardDataScript._cache_timestamp["global"] = Time.get_unix_time_from_system()
			_data.TabType.FRIENDS:
				LeaderboardDataScript._friends_cache = data
				LeaderboardDataScript._cache_timestamp["friends"] = Time.get_unix_time_from_system()
	else:
		data = _data.get_leaderboard(_current_tab)
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	if _my_rank_row and is_instance_valid(_my_rank_row):
		_my_rank_row.queue_free()
		_my_rank_row = null
	if not data.is_empty():
		_display_data(data)
	else:
		var hint = Label.new()
		hint.name = "EmptyHint"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if _current_tab == _data.TabType.FRIENDS:
			hint.text = tr("暂无好友排行数据\n好友在本游戏中提交分数后将显示在此")
		else:
			hint.text = tr("暂无排行数据")
		hint.add_theme_font_size_override("font_size", 20)
		list.add_child(hint)


func _on_taptap_user_score(score_json: String) -> void:
	if score_json.is_empty():
		return
	var json = JSON.new()
	if json.parse(score_json) != OK:
		return
	var data = json.data
	if not data is Dictionary:
		return
	var user = data.get("user", {})
	var raw_score_display: String = data.get("scoreDisplay", str(data.get("score", "0")))
	var numeric_display = raw_score_display
	var regex = RegEx.new()
	regex.compile("^\\d+")
	var result = regex.search(raw_score_display)
	if result:
		numeric_display = result.get_string()
	var avatar_url = ""
	var avatar_data = user.get("avatar", "")
	if avatar_data is Dictionary:
		avatar_url = avatar_data.get("url", "")
	elif avatar_data is String:
		avatar_url = avatar_data
	_my_score = {
		"user_id": user.get("openid", ""),
		"nickname": user.get("name", ""),
		"avatar_url": avatar_url,
		"score": float(data.get("score", "0")),
		"score_display": numeric_display,
		"rank": int(data.get("rank", "0")),
		"is_me": true,
	}
	if visible and is_inside_tree():
		if _my_rank_row and is_instance_valid(_my_rank_row):
			_my_rank_row.queue_free()
			_my_rank_row = null
		_my_rank_row = RankRowScene.instantiate()
		my_rank_container.add_child(_my_rank_row)
		_my_rank_row.setup(_my_score, false, true)
		my_rank_container.visible = true


func _on_taptap_leaderboard_result(code: String, message: String) -> void:
	if code != "0":
		print("[Leaderboard] result code=%s msg=%s" % [code, message])
		if code == "500101" and _current_tab == _data.TabType.FRIENDS:
			for child in list.get_children():
				list.remove_child(child)
				child.queue_free()
			var hint = Label.new()
			hint.name = "AuthHint"
			hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hint.text = tr("需要重新登录以授权好友权限\n请退出后重新登录TapTap")
			hint.add_theme_font_size_override("font_size", 20)
			list.add_child(hint)

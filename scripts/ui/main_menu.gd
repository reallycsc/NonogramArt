extends Control

@onready var portrait_ui: Control = $PortraitUI
@onready var landscape_ui: Control = $LandscapeUI
@onready var portrait_video_bg: VideoStreamPlayer = $PortraitUI/VideoStreamPlayer
@onready var landscape_video_bg: VideoStreamPlayer = $LandscapeUI/VideoStreamPlayer

@onready var progress_bar: ProgressBar = $LoadPanel/VBox/ProgressBar
@onready var load_label: Label = $LoadPanel/VBox/LoadLabel
@onready var load_panel: Control = $LoadPanel
@onready var settings_popup: Control = $SettingsPopup
@onready var exit_popup: Control = $ExitConfirmPopup
@onready var privacy_popup: Control = $PrivacyPopup
@onready var login_button: TextureButton = $LoginButton
@onready var cloud_conflict_popup: Control = $CloudSaveConflictPopup

var _exit_callback: Callable = func(): get_tree().quit()

var _cloud_sync_mask: CanvasLayer = null
var _cloud_sync_timeout: Timer = null
var _pending_enter_bookshelf: bool = false

class _CloudSyncSpinner extends Control:
	var _angle: float = 0.0

	func _ready():
		custom_minimum_size = Vector2(56, 56)

	func _process(delta):
		_angle = fmod(_angle + delta * 3.5, TAU)
		queue_redraw()

	func _draw():
		var center = size / 2.0
		var radius = min(size.x, size.y) * 0.4
		if radius <= 0:
			return
		var arc_length = PI * 1.3
		var segments = 30
		var line_width = 4.0
		for i in range(segments):
			var t1 = float(i) / float(segments)
			var t2 = float(i + 1) / float(segments)
			var alpha = 1.0 - t1
			var a1 = _angle + t1 * arc_length
			var a2 = _angle + t2 * arc_length
			var p1 = center + Vector2(cos(a1), sin(a1)) * radius
			var p2 = center + Vector2(cos(a2), sin(a2)) * radius
			draw_line(p1, p2, Color(1, 1, 1, alpha), line_width, true)

const TAPTAP_CLIENT_ID: String = "fictuviuwc34cqheew"
const TAPTAP_CLIENT_TOKEN: String = "N9tct6MZ6P0PmKSe7yrsC2D79Jm370eLnW7iO8pS"
const TAPTAP_SERVER_URL: String = ""

func _set_background_mouse_filter() -> void:
	for ui in [portrait_ui, landscape_ui]:
		for child in ui.get_children():
			if child is TextureRect or child is VideoStreamPlayer:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_set_background_mouse_filter()
	load_panel.visible = true
	progress_bar.value = 0
	GameManager.preload_progress.connect(_on_preload_progress)
	GameManager.preload_finished.connect(_on_preload_finished)
	GameManager.preload_all_data()
	AudioManager.play_bgm("main_menu")
	OrientationManager.orientation_changed.connect(_on_orientation_changed)
	_apply_orientation(OrientationManager.current_orientation)
	exit_popup.confirmed.connect(_on_exit_confirmed)
	exit_popup.cancelled.connect(_on_exit_cancelled)
	cloud_conflict_popup.use_local.connect(_on_cloud_conflict_use_local)
	cloud_conflict_popup.use_cloud.connect(_on_cloud_conflict_use_cloud)
	GameManager.language_changed.connect(_on_language_changed)
	_restart_video(portrait_video_bg, "res://assets/images/ui/main/main_bg.ogv")
	_restart_video(landscape_video_bg, "res://assets/images/ui/main/main_bg_landscape.ogv")
	_setup_taptap()

func _exit_tree() -> void:
	if OrientationManager.orientation_changed.is_connected(_on_orientation_changed):
		OrientationManager.orientation_changed.disconnect(_on_orientation_changed)
	if GameManager.language_changed.is_connected(_on_language_changed):
		GameManager.language_changed.disconnect(_on_language_changed)
	if GameManager.cloud_sync_completed.is_connected(_on_cloud_sync_completed):
		GameManager.cloud_sync_completed.disconnect(_on_cloud_sync_completed)
	if _cloud_sync_timeout != null:
		_cloud_sync_timeout.stop()
		_cloud_sync_timeout.queue_free()
		_cloud_sync_timeout = null

func _setup_taptap() -> void:
	if not TapTapManager.is_available():
		_update_buttons()
		return
	TapTapManager.login_success.connect(_on_taptap_login_success)
	TapTapManager.login_failed.connect(_on_taptap_login_failed)
	TapTapManager.anti_addiction_callback.connect(_on_anti_addiction_callback)
	if not GameManager.privacy_agreed:
		privacy_popup.agreed.connect(_on_privacy_agreed)
		privacy_popup.disagreed.connect(_on_privacy_disagreed)
		privacy_popup.show_popup()
	else:
		_init_taptap_sdk()
	_update_buttons()

func _init_taptap_sdk() -> void:
	if TAPTAP_CLIENT_ID == "" or TAPTAP_CLIENT_TOKEN == "":
		push_warning("MainMenu: TapSDK credentials not configured, please set TAPTAP_CLIENT_ID / TAPTAP_CLIENT_TOKEN")
		return
	TapTapManager.init_sdk(TAPTAP_CLIENT_ID, TAPTAP_CLIENT_TOKEN, TAPTAP_SERVER_URL)
	TapTapManager.init_anti_addiction(TAPTAP_CLIENT_ID)
	TapTapManager.init_update(TAPTAP_CLIENT_ID, TAPTAP_CLIENT_TOKEN)
	TapTapManager.init_cloud_save()
	TapTapManager.init_leaderboard()
	TapTapManager.init_friends()
	AdManager.init_ad()
	if TapTapManager.is_sdk_logged_in():
		_handle_cached_login()

func _handle_cached_login() -> void:
	var user_info = TapTapManager.get_current_user_info()
	if user_info.is_empty():
		return
	TapTapManager._is_logged_in = true
	TapTapManager._user_info = user_info
	TapTapManager._login_time = Time.get_ticks_msec() / 1000.0
	TapTapManager._sdk_api_ready = false
	if TapTapManager._api_ready_timer == null:
		TapTapManager._api_ready_timer = Timer.new()
		TapTapManager._api_ready_timer.one_shot = true
		TapTapManager._api_ready_timer.timeout.connect(TapTapManager._on_api_ready)
		TapTapManager.add_child(TapTapManager._api_ready_timer)
	TapTapManager._api_ready_timer.start(2.0)
	GameManager.taptap_user_id = user_info.get("user_id", "")
	TapTapManager.get_friends_list()
	_try_restore_cloud_save()
	if GameManager.data_preloaded:
		TapTapManager.check_anti_addiction()
	else:
		_enter_when_ready = true

func _on_privacy_agreed() -> void:
	GameManager.privacy_agreed = true
	GameManager.save_game()
	_init_taptap_sdk()

func _on_privacy_disagreed() -> void:
	get_tree().quit()

func _on_taptap_login_success(user_info: Dictionary) -> void:
	print("登录成功")
	TapTapManager.check_anti_addiction()
	TapTapManager.get_friends_list()

func _on_taptap_login_failed(error: String) -> void:
	ToastManager.show_toast(tr("登录失败: %s") % error)

func _on_anti_addiction_callback(code: String, message: String) -> void:
	match code:
		"500":
			_try_restore_cloud_save()
			_enter_bookshelf()
		"1000", "1001":
			ToastManager.show_toast(tr("请重新登录"))
		"1030":
			ToastManager.show_toast(tr("当前时间无法游戏"))
		"1050":
			ToastManager.show_toast(tr("今日游戏时长已用完"))
		"1100":
			ToastManager.show_toast(tr("年龄限制，无法进入游戏"))
		"1200":
			ToastManager.show_toast(tr("网络错误，请检查网络"))
		_:
			_try_restore_cloud_save()
			_enter_bookshelf()

var _pending_cloud_save_json: String = ""
var _cloud_save_restore_started: bool = false
var _enter_when_ready: bool = false

func _try_restore_cloud_save() -> void:
	if _cloud_save_restore_started:
		return
	if not TapTapManager.is_available() or not TapTapManager.is_logged_in() or TapTapManager.is_mock_mode():
		return
	_cloud_save_restore_started = true
	GameManager.cloud_sync_in_progress = true
	var _finish_sync = func():
		GameManager.cloud_sync_in_progress = false
		GameManager.cloud_sync_completed.emit()
	var do_load_list = func():
		TapTapManager.cloud_save_list.connect(func(archives_json):
			if archives_json.is_empty():
				_finish_sync.call()
				return
			var json = JSON.new()
			if json.parse(archives_json) != OK:
				_finish_sync.call()
				return
			var archives = json.data.get("archives", [])
			if archives.is_empty():
				_finish_sync.call()
				return
			var latest = archives[0]
			var archive_id = latest.get("archiveId", "")
			var file_id = latest.get("fileId", "")
			if archive_id.is_empty() or file_id.is_empty():
				_finish_sync.call()
				return
			TapTapManager.cloud_save_data.connect(func(save_json):
				if save_json.is_empty():
					_finish_sync.call()
					return
				var comparison = GameManager.compare_with_cloud_save(save_json)
				if comparison["cloud_newer"]:
					GameManager.load_from_cloud_save(save_json)
				_finish_sync.call()
			, CONNECT_ONE_SHOT)
			TapTapManager.load_cloud_save_data(archive_id, file_id)
		, CONNECT_ONE_SHOT)
		TapTapManager.load_cloud_save_list()
	if TapTapManager._sdk_api_ready:
		do_load_list.call()
	else:
		TapTapManager.sdk_api_ready.connect(do_load_list, CONNECT_ONE_SHOT)

func _on_cloud_conflict_use_local() -> void:
	pass

func _on_cloud_conflict_use_cloud() -> void:
	if not _pending_cloud_save_json.is_empty():
		GameManager.load_from_cloud_save(_pending_cloud_save_json)
	_pending_cloud_save_json = ""

func _update_buttons() -> void:
	if load_panel.visible:
		login_button.visible = false
		$StartButton.visible = false
		return
	if not TapTapManager.is_available():
		login_button.visible = false
		$StartButton.visible = true
		return
	if TapTapManager.is_pc_mode() and not TapTapManager._is_sdk_initialized:
		login_button.visible = false
		$StartButton.visible = true
		return
	if TapTapManager.is_logged_in():
		login_button.visible = false
		$StartButton.visible = true
	else:
		login_button.visible = true
		$StartButton.visible = false

func _on_login_pressed() -> void:
	AudioManager.play_sfx("click")
	TapTapManager.login()

func _on_language_changed(_language: int) -> void:
	_restart_video(portrait_video_bg, "res://assets/images/ui/main/main_bg.ogv")
	_restart_video(landscape_video_bg, "res://assets/images/ui/main/main_bg_landscape.ogv")
	_update_buttons()

func _restart_video(player: VideoStreamPlayer, path: String) -> void:
	player.stop()
	var stream = load(path)
	if stream:
		player.stream = stream
		player.play()

func _on_preload_progress(step: int, _total: int, description: String) -> void:
	progress_bar.value = step
	load_label.text = description

func _on_preload_finished() -> void:
	load_panel.visible = false
	_update_buttons()
	if _enter_when_ready:
		_enter_when_ready = false
		TapTapManager.check_anti_addiction()

func _on_start_pressed() -> void:
	AudioManager.play_sfx("click")
	_try_restore_cloud_save()
	_enter_bookshelf()

func _enter_bookshelf() -> void:
	if GameManager.cloud_sync_in_progress:
		_pending_enter_bookshelf = true
		_show_cloud_sync_mask()
		if not GameManager.cloud_sync_completed.is_connected(_on_cloud_sync_completed):
			GameManager.cloud_sync_completed.connect(_on_cloud_sync_completed, CONNECT_ONE_SHOT)
		if _cloud_sync_timeout == null:
			_cloud_sync_timeout = Timer.new()
			_cloud_sync_timeout.one_shot = true
			_cloud_sync_timeout.timeout.connect(_on_cloud_sync_timeout)
			add_child(_cloud_sync_timeout)
			_cloud_sync_timeout.start(15.0)
		return
	_do_enter_bookshelf()

func _do_enter_bookshelf() -> void:
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/book_shelf.tscn")

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	settings_popup.show_settings()

func _on_orientation_changed(new_orientation: int) -> void:
	_apply_orientation(new_orientation)

func _apply_orientation(orientation: int) -> void:
	if not is_inside_tree():
		return
	if orientation == OrientationManager.Orientation.PORTRAIT:
		portrait_ui.visible = true
		landscape_ui.visible = false
	else:
		portrait_ui.visible = false
		landscape_ui.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_show_exit_confirm()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_show_exit_confirm()

func _show_exit_confirm() -> void:
	exit_popup.show_popup()
	get_viewport().set_input_as_handled()

func _on_exit_confirmed() -> void:
	_exit_callback.call()

func _on_exit_cancelled() -> void:
	pass

func _show_cloud_sync_mask() -> void:
	if _cloud_sync_mask != null:
		_cloud_sync_mask.visible = true
		return
	_cloud_sync_mask = CanvasLayer.new()
	_cloud_sync_mask.layer = 10
	add_child(_cloud_sync_mask)
	var mask = Control.new()
	mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	_cloud_sync_mask.add_child(mask)
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.6)
	mask.add_child(bg)
	var center_box = VBoxContainer.new()
	center_box.set_anchors_preset(Control.PRESET_CENTER)
	center_box.offset_left = -60
	center_box.offset_top = -50
	center_box.offset_right = 60
	center_box.offset_bottom = 50
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	mask.add_child(center_box)
	var spinner = _CloudSyncSpinner.new()
	center_box.add_child(spinner)
	var label = Label.new()
	label.text = tr("正在同步云存档")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_font_size_override("font_size", 22)
	center_box.add_child(label)

func _hide_cloud_sync_mask() -> void:
	if _cloud_sync_mask != null:
		_cloud_sync_mask.queue_free()
		_cloud_sync_mask = null
	if _cloud_sync_timeout != null:
		_cloud_sync_timeout.stop()
		_cloud_sync_timeout.queue_free()
		_cloud_sync_timeout = null

func _on_cloud_sync_completed() -> void:
	_hide_cloud_sync_mask()
	if _pending_enter_bookshelf:
		_pending_enter_bookshelf = false
		_do_enter_bookshelf()

func _on_cloud_sync_timeout() -> void:
	print("MainMenu: Cloud sync timeout, entering bookshelf anyway")
	_hide_cloud_sync_mask()
	if _pending_enter_bookshelf:
		_pending_enter_bookshelf = false
		_do_enter_bookshelf()

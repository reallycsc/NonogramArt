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

func _on_privacy_agreed() -> void:
	GameManager.privacy_agreed = true
	GameManager.save_game()
	_init_taptap_sdk()

func _on_privacy_disagreed() -> void:
	get_tree().quit()

func _on_taptap_login_success(user_info: Dictionary) -> void:
	print("登录成功")
	TapTapManager.check_anti_addiction()

func _on_taptap_login_failed(error: String) -> void:
	ToastManager.show_toast(tr("登录失败: %s") % error)

func _on_anti_addiction_callback(code: String, message: String) -> void:
	match code:
		"500":
			_try_restore_cloud_save_then_enter()
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
			_enter_bookshelf.call_deferred()

var _pending_cloud_save_json: String = ""

func _try_restore_cloud_save_then_enter() -> void:
	if TapTapManager.is_available() and TapTapManager.is_logged_in() and not TapTapManager.is_mock_mode():
		if not TapTapManager._sdk_api_ready:
			TapTapManager.sdk_api_ready.connect(_on_sdk_api_ready_for_restore, CONNECT_ONE_SHOT)
			return
		TapTapManager.cloud_save_list.connect(_on_cloud_save_list_for_restore, CONNECT_ONE_SHOT)
		TapTapManager.load_cloud_save_list()
	else:
		_enter_bookshelf.call_deferred()

func _on_sdk_api_ready_for_restore() -> void:
	TapTapManager.cloud_save_list.connect(_on_cloud_save_list_for_restore, CONNECT_ONE_SHOT)
	TapTapManager.load_cloud_save_list()

func _on_cloud_save_list_for_restore(archives_json: String) -> void:
	if archives_json.is_empty():
		_enter_bookshelf.call_deferred()
		return
	var json = JSON.new()
	if json.parse(archives_json) != OK:
		_enter_bookshelf.call_deferred()
		return
	var archives = json.data.get("archives", [])
	if archives.is_empty():
		_enter_bookshelf.call_deferred()
		return
	var latest = archives[0]
	var archive_id = latest.get("archiveId", "")
	var file_id = latest.get("fileId", "")
	if archive_id.is_empty() or file_id.is_empty():
		_enter_bookshelf.call_deferred()
		return
	TapTapManager.cloud_save_data.connect(_on_cloud_save_data_for_restore, CONNECT_ONE_SHOT)
	TapTapManager.load_cloud_save_data(archive_id, file_id)

func _on_cloud_save_data_for_restore(save_json: String) -> void:
	if save_json.is_empty():
		_enter_bookshelf.call_deferred()
		return
	var comparison = GameManager.compare_with_cloud_save(save_json)
	if comparison["conflict"]:
		_pending_cloud_save_json = save_json
		cloud_conflict_popup.show_popup(comparison["local_info"], comparison["cloud_info"])
	else:
		if comparison["cloud_newer"]:
			GameManager.load_from_cloud_save(save_json)
		_enter_bookshelf.call_deferred()

func _on_cloud_conflict_use_local() -> void:
	_enter_bookshelf.call_deferred()

func _on_cloud_conflict_use_cloud() -> void:
	if not _pending_cloud_save_json.is_empty():
		GameManager.load_from_cloud_save(_pending_cloud_save_json)
	_pending_cloud_save_json = ""
	_enter_bookshelf.call_deferred()

func _update_buttons() -> void:
	if load_panel.visible:
		login_button.visible = false
		$StartButton.visible = false
		return
	if not TapTapManager.is_available():
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

func _on_start_pressed() -> void:
	AudioManager.play_sfx("click")
	_enter_bookshelf()

func _enter_bookshelf() -> void:
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

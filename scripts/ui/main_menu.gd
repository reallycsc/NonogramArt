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

var _exit_callback: Callable = func(): get_tree().quit()

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

func _exit_tree() -> void:
	if OrientationManager.orientation_changed.is_connected(_on_orientation_changed):
		OrientationManager.orientation_changed.disconnect(_on_orientation_changed)

func _on_preload_progress(step: int, _total: int, description: String) -> void:
	progress_bar.value = step
	load_label.text = description

func _on_preload_finished() -> void:
	load_panel.visible = false
	$StartButton.visible = true

func _on_start_pressed() -> void:
	AudioManager.play_sfx("click")
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

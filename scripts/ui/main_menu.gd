extends Control

@onready var portrait_ui: Control = $PortraitUI
@onready var landscape_ui: Control = $LandscapeUI
@onready var portrait_video_bg: VideoStreamPlayer = $PortraitUI/VideoStreamPlayer
@onready var landscape_video_bg: VideoStreamPlayer = $LandscapeUI/VideoStreamPlayer

@onready var p_start_button: TextureButton = $PortraitUI/StartButton
@onready var p_progress_bar: ProgressBar = $PortraitUI/LoadPanel/VBox/ProgressBar
@onready var p_load_label: Label = $PortraitUI/LoadPanel/VBox/LoadLabel
@onready var p_load_panel: Control = $PortraitUI/LoadPanel
@onready var p_settings_popup: Control = $PortraitUI/SettingsPopup

@onready var l_start_button: TextureButton = $LandscapeUI/StartButton
@onready var l_progress_bar: ProgressBar = $LandscapeUI/LoadPanel/VBox/ProgressBar
@onready var l_load_label: Label = $LandscapeUI/LoadPanel/VBox/LoadLabel
@onready var l_load_panel: Control = $LandscapeUI/LoadPanel
@onready var l_settings_popup: Control = $LandscapeUI/SettingsPopup

func _ready() -> void:
	p_load_panel.visible = true
	l_load_panel.visible = true
	p_progress_bar.value = 0
	l_progress_bar.value = 0
	GameManager.preload_progress.connect(_on_preload_progress)
	GameManager.preload_finished.connect(_on_preload_finished)
	GameManager.preload_all_data()
	AudioManager.play_bgm("main_menu")
	OrientationManager.orientation_changed.connect(_on_orientation_changed)
	_apply_orientation(OrientationManager.current_orientation)

func _exit_tree() -> void:
	if OrientationManager.orientation_changed.is_connected(_on_orientation_changed):
		OrientationManager.orientation_changed.disconnect(_on_orientation_changed)

func _on_preload_progress(step: int, _total: int, description: String) -> void:
	p_progress_bar.value = step
	l_progress_bar.value = step
	p_load_label.text = description
	l_load_label.text = description

func _on_preload_finished() -> void:
	p_load_panel.visible = false
	l_load_panel.visible = false
	portrait_video_bg.visible = true
	landscape_video_bg.visible = true
	p_start_button.visible = true
	l_start_button.visible = true

func _on_start_pressed() -> void:
	AudioManager.play_sfx("click")
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/book_shelf.tscn")

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	if portrait_ui.visible:
		p_settings_popup.show_settings()
	else:
		l_settings_popup.show_settings()

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
		get_tree().quit()

extends Control

@onready var start_button: TextureButton = $StartButton
@onready var progress_bar: ProgressBar = $LoadPanel/VBox/ProgressBar
@onready var load_label: Label = $LoadPanel/VBox/LoadLabel
@onready var load_panel: Control = $LoadPanel
@onready var settings_popup: Control = $SettingsPopup

func _ready() -> void:
	start_button.visible = false
	load_panel.visible = true
	progress_bar.value = 0
	GameManager.preload_progress.connect(_on_preload_progress)
	GameManager.preload_finished.connect(_on_preload_finished)
	GameManager.preload_all_data()
	AudioManager.play_bgm("main_menu")

func _on_preload_progress(step: int, _total: int, description: String) -> void:
	progress_bar.value = step
	load_label.text = description

func _on_preload_finished() -> void:
	load_panel.visible = false
	start_button.visible = true

func _on_start_pressed() -> void:
	AudioManager.play_sfx("click")
	var tree = get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/book_shelf.tscn")

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("click")
	settings_popup.show_settings()

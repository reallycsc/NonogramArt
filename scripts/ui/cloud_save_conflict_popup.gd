extends Control

signal use_local
signal use_cloud

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var panel: Panel = $PanelContainer

var _cloud_info: Dictionary = {}
var _local_info: Dictionary = {}

func _ready() -> void:
	visible = false

func show_popup(local_info: Dictionary, cloud_info: Dictionary) -> void:
	_local_info = local_info
	_cloud_info = cloud_info
	visible = true
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	dim_overlay.color = Color(0, 0, 0, 0.0)

	var local_label = $PanelContainer/LocalInfo
	var cloud_label = $PanelContainer/CloudInfo
	var local_time = local_info.get("save_time", "")
	var cloud_time = cloud_info.get("save_time", "")
	var local_text = tr("本地存档：已完成 %d 个数织") % local_info.get("puzzle_count", 0)
	var cloud_text = tr("云存档：已完成 %d 个数织") % cloud_info.get("puzzle_count", 0)
	if not local_time.is_empty():
		local_text += "\n" + local_time
	if not cloud_time.is_empty():
		cloud_text += "\n" + cloud_time
	local_label.text = local_text
	cloud_label.text = cloud_text

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.8), 0.3)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func _hide_with_callback(callback: Callable) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.0), 0.15)
	tween.chain().tween_callback(func():
		visible = false
		callback.call()
	)

func _on_local_pressed() -> void:
	AudioManager.play_sfx("click")
	_hide_with_callback(func(): use_local.emit())

func _on_cloud_pressed() -> void:
	AudioManager.play_sfx("click")
	_hide_with_callback(func(): use_cloud.emit())

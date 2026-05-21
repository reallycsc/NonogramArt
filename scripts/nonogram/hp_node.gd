extends HBoxContainer

@onready var hp1: TextureRect = $Hp1
@onready var hp2: TextureRect = $Hp2
@onready var hp3: TextureRect = $Hp3
@onready var life_change_audio_player: AudioStreamPlayer2D = $LifeChangeAudioPlayer
@onready var nonogram_scene: Control = $"../.."

var hp_full_texture: Texture2D = preload("res://assets/images/ui/nonogram/heart.png")
var hp_empty_texture: Texture2D = preload("res://assets/images/ui/nonogram/heart_empty.png")

var max_hp:int = 3
var current_hp:int = 3
var _game_over_emitted: bool = false

func hp_change(change: int) -> void:
	current_hp += change
	current_hp = clamp(current_hp, 0, max_hp)
	match current_hp:
		0:
			hp1.texture = hp_empty_texture
			hp2.texture = hp_empty_texture
			hp3.texture = hp_empty_texture
		1:
			hp1.texture = hp_full_texture
			hp2.texture = hp_empty_texture
			hp3.texture = hp_empty_texture
		2:
			hp1.texture = hp_full_texture
			hp2.texture = hp_full_texture
			hp3.texture = hp_empty_texture
		3:
			hp1.texture = hp_full_texture
			hp2.texture = hp_full_texture
			hp3.texture = hp_full_texture
	life_change_audio_player.play()
	if current_hp == 0 and not _game_over_emitted:
		_game_over_emitted = true
		nonogram_scene.is_locked = true
		life_change_audio_player.finished.connect(_on_life_audio_finished)

func _on_life_audio_finished() -> void:
	GameManager.nonogram_game_over.emit()
	

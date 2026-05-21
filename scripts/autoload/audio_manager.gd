extends Node

signal bgm_volume_changed(value: float)
signal sfx_volume_changed(value: float)

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _max_sfx_players: int = 8
var _sfx_index: int = 0

var _current_bgm_key: String = ""
var _bgm_fade_tween: Tween = null

var bgm_volume: float = 0.8:
	set(v):
		bgm_volume = clampf(v, 0.0, 1.0)
		if _bgm_player:
			_bgm_player.volume_db = linear_to_db(bgm_volume)
		bgm_volume_changed.emit(bgm_volume)

var sfx_volume: float = 1.0:
	set(v):
		sfx_volume = clampf(v, 0.0, 1.0)
		for player in _sfx_players:
			player.volume_db = linear_to_db(sfx_volume)
		sfx_volume_changed.emit(sfx_volume)

const BGM_DIR = "res://assets/audio/music/"

const BGM_CONFIG = {
	"main_menu": "res://assets/audio/music/main_menu.mp3",
}

const SFX_CONFIG = {
	"click": "res://assets/audio/sfx/click.wav",
	"nonogram_click": "res://assets/audio/sfx/nonogram_click.wav",
	"nonogram_click_cross": "res://assets/audio/sfx/nonogram_click_cross.wav",
	"congratulations": "res://assets/audio/sfx/congratulations_2.wav",
	"life_change": "res://assets/audio/sfx/life_change.wav",
	"game_over": "res://assets/audio/sfx/game_over.wav",
	"page_flip": "res://assets/audio/sfx/page_flip.wav",
	"get_star": "res://assets/audio/sfx/get_star.wav"
}

var _sfx_cache: Dictionary = {}
var _bgm_cache: Dictionary = {}

func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)

	for i in range(_max_sfx_players):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)

	bgm_volume = GameManager.settings.get("bgm_volume", 0.8)
	sfx_volume = GameManager.settings.get("sfx_volume", 1.0)

func play_bgm(key: String, fade_duration: float = 1.0) -> void:
	if key == _current_bgm_key and _bgm_player.playing:
		return

	var stream = _load_bgm(key)
	if stream == null:
		return

	_current_bgm_key = key

	if _bgm_player.playing and fade_duration > 0.0:
		if _bgm_fade_tween:
			_bgm_fade_tween.kill()
		_bgm_fade_tween = create_tween()
		_bgm_fade_tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
		_bgm_fade_tween.tween_callback(_start_bgm.bind(stream, fade_duration))
	else:
		_start_bgm(stream, 0.0)

func _start_bgm(stream: AudioStream, fade_in_duration: float) -> void:
	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(bgm_volume) if fade_in_duration <= 0 else -80.0
	_bgm_player.play()

	if fade_in_duration > 0:
		if _bgm_fade_tween:
			_bgm_fade_tween.kill()
		_bgm_fade_tween = create_tween()
		_bgm_fade_tween.tween_property(_bgm_player, "volume_db", linear_to_db(bgm_volume), fade_in_duration)

func stop_bgm(fade_duration: float = 1.0) -> void:
	_current_bgm_key = ""
	if not _bgm_player.playing:
		return
	if fade_duration > 0.0:
		if _bgm_fade_tween:
			_bgm_fade_tween.kill()
		_bgm_fade_tween = create_tween()
		_bgm_fade_tween.tween_property(_bgm_player, "volume_db", -80.0, fade_duration)
		_bgm_fade_tween.tween_callback(_bgm_player.stop)
	else:
		_bgm_player.stop()

func play_sfx(key: String) -> void:
	var stream = _load_sfx(key)
	if stream == null:
		return

	var player = _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _max_sfx_players

	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume)
	player.play()

func play_bgm_for_album(album_id: String) -> void:
	if album_id == "":
		play_bgm("main_menu")
		return
	var album = AlbumData.get_album(album_id)
	var bgm_path = album.get("bgm", "")
	if bgm_path != "":
		if bgm_path == _current_bgm_key and _bgm_player.playing:
			return
		var stream = _load_bgm_from_path(bgm_path)
		if stream == null:
			push_error("AudioManager: 背景音乐加载失败: " + bgm_path + "，维持当前播放")
			return
		_current_bgm_key = bgm_path
		if _bgm_player.playing:
			if _bgm_fade_tween:
				_bgm_fade_tween.kill()
			_bgm_fade_tween = create_tween()
			_bgm_fade_tween.tween_property(_bgm_player, "volume_db", -80.0, 1.0)
			_bgm_fade_tween.tween_callback(_start_bgm.bind(stream, 1.0))
		else:
			_start_bgm(stream, 0.0)
	else:
		play_bgm(album_id)

func play_bgm_for_scene(scene_path: String) -> void:
	match scene_path:
		"res://scenes/main_menu.tscn":
			play_bgm("main_menu")
		"res://scenes/book_shelf.tscn":
			if GameManager.pending_album_id != "":
				play_bgm_for_album(GameManager.pending_album_id)
			else:
				play_bgm("main_menu")
		"res://scenes/album_detail.tscn":
			if GameManager.pending_album_id != "":
				play_bgm_for_album(GameManager.pending_album_id)
			else:
				play_bgm("main_menu")
		"res://scenes/nonogram_scene.tscn":
			if GameManager.pending_album_id != "":
				play_bgm_for_album(GameManager.pending_album_id)
			else:
				play_bgm("main_menu")
		_:
			play_bgm("main_menu")

func _load_bgm(key: String) -> AudioStream:
	if _bgm_cache.has(key):
		return _bgm_cache[key]
	var path = BGM_CONFIG.get(key, "")
	if path == "":
		path = BGM_DIR + key + ".mp3"
	if not ResourceLoader.exists(path):
		return null
	var stream = load(path)
	if stream is AudioStream:
		_bgm_cache[key] = stream
		return stream
	return null

func _load_bgm_from_path(path: String) -> AudioStream:
	if _bgm_cache.has(path):
		return _bgm_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var stream = load(path)
	if stream is AudioStream:
		_bgm_cache[path] = stream
		return stream
	return null

func _load_sfx(key: String) -> AudioStream:
	if _sfx_cache.has(key):
		return _sfx_cache[key]
	var path = SFX_CONFIG.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var stream = load(path)
	if stream is AudioStream:
		_sfx_cache[key] = stream
		return stream
	return null

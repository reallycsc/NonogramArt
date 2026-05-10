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

const BGM_CONFIG = {
	"main_menu": "res://assets/audio/music/main_menu.mp3",
	"chinese_history": "res://assets/audio/music/chinese_history.mp3",
	"world_history": "res://assets/audio/music/world_history.mp3",
	"asian_civilization": "res://assets/audio/music/asian_civilization.mp3",
	"european_civilization": "res://assets/audio/music/european_civilization.mp3",
	"africa_america": "res://assets/audio/music/africa_america.mp3",
	"war_military": "res://assets/audio/music/war_military.mp3",
	"political_system": "res://assets/audio/music/political_system.mp3",
	"economic_trade": "res://assets/audio/music/economic_trade.mp3",
	"world_heritage": "res://assets/audio/music/world_heritage.mp3",
	"chinese_heritage": "res://assets/audio/music/chinese_heritage.mp3",
	"archaeology": "res://assets/audio/music/archaeology.mp3",
	"historical_mysteries": "res://assets/audio/music/historical_mysteries.mp3",
	"chinese_painting": "res://assets/audio/music/chinese_painting.mp3",
	"western_painting": "res://assets/audio/music/western_painting.mp3",
	"sculpture": "res://assets/audio/music/sculpture.mp3",
	"photography": "res://assets/audio/music/photography.mp3",
	"architecture": "res://assets/audio/music/architecture.mp3",
	"crafts": "res://assets/audio/music/crafts.mp3",
	"design": "res://assets/audio/music/design.mp3",
	"performing_arts": "res://assets/audio/music/performing_arts.mp3",
	"folk_art": "res://assets/audio/music/folk_art.mp3",
	"contemporary_media": "res://assets/audio/music/contemporary_media.mp3",
	"mountains": "res://assets/audio/music/mountains.mp3",
	"plains_basins": "res://assets/audio/music/plains_basins.mp3",
	"deserts_gobi": "res://assets/audio/music/deserts_gobi.mp3",
	"rivers_lakes": "res://assets/audio/music/rivers_lakes.mp3",
	"atmosphere": "res://assets/audio/music/atmosphere.mp3",
	"geology": "res://assets/audio/music/geology.mp3",
	"paleontology": "res://assets/audio/music/paleontology.mp3",
	"nature_reserve": "res://assets/audio/music/nature_reserve.mp3",
	"mammals": "res://assets/audio/music/mammals.mp3",
	"birds": "res://assets/audio/music/birds.mp3",
	"reptiles": "res://assets/audio/music/reptiles.mp3",
	"fish": "res://assets/audio/music/fish.mp3",
	"insects": "res://assets/audio/music/insects.mp3",
	"trees": "res://assets/audio/music/trees.mp3",
	"flowers": "res://assets/audio/music/flowers.mp3",
	"crops": "res://assets/audio/music/crops.mp3",
	"fungi": "res://assets/audio/music/fungi.mp3",
	"ecosystems": "res://assets/audio/music/ecosystems.mp3",
	"fashion": "res://assets/audio/music/fashion.mp3",
	"food": "res://assets/audio/music/food.mp3",
	"housing": "res://assets/audio/music/housing.mp3",
	"transportation": "res://assets/audio/music/transportation.mp3",
	"festivals": "res://assets/audio/music/festivals.mp3",
	"religion": "res://assets/audio/music/religion.mp3",
	"family": "res://assets/audio/music/family.mp3",
	"workplace": "res://assets/audio/music/workplace.mp3",
	"education": "res://assets/audio/music/education.mp3",
	"sports": "res://assets/audio/music/sports.mp3",
	"entertainment": "res://assets/audio/music/entertainment.mp3",
	"health": "res://assets/audio/music/health.mp3",
	"math_physics": "res://assets/audio/music/math_physics.mp3",
	"chemistry_biology": "res://assets/audio/music/chemistry_biology.mp3",
	"astronomy": "res://assets/audio/music/astronomy.mp3",
	"mechanical_electronic": "res://assets/audio/music/mechanical_electronic.mp3",
	"energy": "res://assets/audio/music/energy.mp3",
	"civil_engineering": "res://assets/audio/music/civil_engineering.mp3",
	"information_tech": "res://assets/audio/music/information_tech.mp3",
	"industry": "res://assets/audio/music/industry.mp3",
	"agriculture_food": "res://assets/audio/music/agriculture_food.mp3",
	"transport_industry": "res://assets/audio/music/transport_industry.mp3",
	"abstract": "res://assets/audio/music/abstract.mp3",
	"symbols": "res://assets/audio/music/symbols.mp3",
	"textures": "res://assets/audio/music/textures.mp3",
	"miscellaneous": "res://assets/audio/music/miscellaneous.mp3",
}

const ALBUM_TO_BGM = {
	"chinese_history": "chinese_history",
	"world_history": "world_history",
	"asian_civilization": "asian_civilization",
	"european_civilization": "european_civilization",
	"africa_america": "africa_america",
	"war_military": "war_military",
	"political_system": "political_system",
	"economic_trade": "economic_trade",
	"world_heritage": "world_heritage",
	"chinese_heritage": "chinese_heritage",
	"archaeology": "archaeology",
	"historical_mysteries": "historical_mysteries",
	"chinese_painting": "chinese_painting",
	"western_painting": "western_painting",
	"sculpture": "sculpture",
	"photography": "photography",
	"architecture": "architecture",
	"crafts": "crafts",
	"design": "design",
	"performing_arts": "performing_arts",
	"folk_art": "folk_art",
	"contemporary_media": "contemporary_media",
	"mountains": "mountains",
	"plains_basins": "plains_basins",
	"deserts_gobi": "deserts_gobi",
	"rivers_lakes": "rivers_lakes",
	"atmosphere": "atmosphere",
	"geology": "geology",
	"paleontology": "paleontology",
	"nature_reserve": "nature_reserve",
	"mammals": "mammals",
	"birds": "birds",
	"reptiles": "reptiles",
	"fish": "fish",
	"insects": "insects",
	"trees": "trees",
	"flowers": "flowers",
	"crops": "crops",
	"fungi": "fungi",
	"ecosystems": "ecosystems",
	"fashion": "fashion",
	"food": "food",
	"housing": "housing",
	"transportation": "transportation",
	"festivals": "festivals",
	"religion": "religion",
	"family": "family",
	"workplace": "workplace",
	"education": "education",
	"sports": "sports",
	"entertainment": "entertainment",
	"health": "health",
	"math_physics": "math_physics",
	"chemistry_biology": "chemistry_biology",
	"astronomy": "astronomy",
	"mechanical_electronic": "mechanical_electronic",
	"energy": "energy",
	"civil_engineering": "civil_engineering",
	"information_tech": "information_tech",
	"industry": "industry",
	"agriculture_food": "agriculture_food",
	"transport_industry": "transport_industry",
	"abstract": "abstract",
	"symbols": "symbols",
	"textures": "textures",
	"miscellaneous": "miscellaneous",
}

const SFX_CONFIG = {
	"click": "res://assets/audio/sfx/click.wav",
	"nonogram_click": "res://assets/audio/sfx/nonogram_click.wav",
	"nonogram_click_cross": "res://assets/audio/sfx/nonogram_click_cross.wav",
	"congratulations": "res://assets/audio/sfx/congratulations_2.wav",
	"life_change": "res://assets/audio/sfx/life_change.wav",
	"game_over": "res://assets/audio/sfx/game_over.wav"
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
	var bgm_key = ALBUM_TO_BGM.get(album_id, "")
	if bgm_key == "":
		play_bgm("main_menu")
		return
	play_bgm(bgm_key)

func play_bgm_for_scene(scene_path: String) -> void:
	match scene_path:
		"res://scenes/main_menu.tscn":
			play_bgm("main_menu")
		"res://scenes/book_shelf.tscn":
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
	if path == "" or not ResourceLoader.exists(path):
		return null
	var stream = load(path)
	if stream is AudioStream:
		_bgm_cache[key] = stream
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

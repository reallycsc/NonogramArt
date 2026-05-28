extends Control

const LeaderboardDataScript = preload("res://scripts/data/leaderboard_data.gd")

const BG_LIST_1 := preload("res://assets/images/ui/leaderboard/list_1.png")
const BG_LIST_2 := preload("res://assets/images/ui/leaderboard/list_2.png")
const BG_LIST_3 := preload("res://assets/images/ui/leaderboard/list_3.png")
const BG_LIST_NORMAL := preload("res://assets/images/ui/leaderboard/list_normal.png")
const BG_LIST_ME := preload("res://assets/images/ui/leaderboard/list_me.png")

var _data = null
var rank: int = 0
var is_me: bool = false
var is_regional: bool = false
var _use_me_bg: bool = false
var _http_request: HTTPRequest = null

@onready var _background: TextureRect = $Background
@onready var _rank_label: Label = $Background/RankLabel
@onready var _avatar: TextureRect = $Background/HBox/Avatar
@onready var _name_label: Label = $Background/HBox/Info/NameLabel
@onready var _sub_label: Label = $Background/HBox/Info/SubLabel
@onready var _score_value: Label = $Background/HBox/Score/ScoreValue

const AVATAR_SIZE := Vector2(56, 56)


func setup(data: Dictionary, p_is_regional: bool = false, p_use_me_bg: bool = false) -> void:
	rank = data.get("rank", 0)
	is_me = data.get("is_me", false)
	is_regional = p_is_regional
	_use_me_bg = p_use_me_bg

	var nickname: String = data.get("nickname", "")
	var score: float = data.get("score", 0.0)
	var score_display: String = data.get("score_display", "")

	if _data == null:
		_data = LeaderboardDataScript.new()
	_name_label.text = nickname
	if not score_display.is_empty():
		_score_value.text = score_display
	elif score > 0.0 and score < 100000.0 and fmod(score, 1.0) != 0.0:
		_score_value.text = _data.format_score(score)
	else:
		_score_value.text = str(int(score))

	_sub_label.text = ""

	_setup_background()
	_setup_rank_display()

	var avatar_url: String = data.get("avatar_url", "")
	if not avatar_url.is_empty():
		_load_avatar_from_url(avatar_url)
	else:
		_setup_fallback_avatar(data.get("avatar_index", 0))


func _setup_background() -> void:
	if _use_me_bg:
		_background.texture = BG_LIST_ME
	elif rank == 1:
		_background.texture = BG_LIST_1
	elif rank == 2:
		_background.texture = BG_LIST_2
	elif rank == 3:
		_background.texture = BG_LIST_3
	else:
		_background.texture = BG_LIST_NORMAL
	var tex = _background.texture
	if tex:
		var img_h = tex.get_height()
		custom_minimum_size.y = img_h


func _setup_rank_display() -> void:
	match rank:
		1:
			_rank_label.visible = false
		2:
			_rank_label.visible = false
		3:
			_rank_label.visible = false
		_:
			_rank_label.visible = true
			_rank_label.text = str(rank)


func _load_avatar_from_url(url: String) -> void:
	if _http_request == null:
		_http_request = HTTPRequest.new()
		_http_request.request_completed.connect(_on_avatar_loaded)
		add_child(_http_request)
	_setup_fallback_avatar(0)
	_http_request.request(url)


func _on_avatar_loaded(_result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if body.is_empty():
		return
	var img = Image.new()
	var err = img.load_png_from_buffer(body)
	if err != OK:
		err = img.load_jpg_from_buffer(body)
	if err != OK:
		err = img.load_webp_from_buffer(body)
	if err != OK:
		return
	img.convert(Image.FORMAT_RGBA8)
	img = _make_circular(img)
	var tex = ImageTexture.create_from_image(img)
	if _avatar and is_instance_valid(_avatar):
		_avatar.texture = tex


func _setup_fallback_avatar(avatar_index: int) -> void:
	var colors = [
		Color(0.85, 0.65, 0.5),
		Color(0.75, 0.85, 0.65),
		Color(0.95, 0.8, 0.55),
		Color(0.8, 0.8, 0.9),
		Color(0.55, 0.7, 0.9),
		Color(0.7, 0.7, 0.65),
		Color(0.95, 0.65, 0.55),
		Color(0.65, 0.75, 0.7),
		Color(0.85, 0.75, 0.6),
		Color(0.7, 0.65, 0.8),
		Color(0.8, 0.85, 0.7),
		Color(0.75, 0.7, 0.8),
	]
	var color = colors[avatar_index % colors.size()]
	var img = Image.create(AVATAR_SIZE.x, AVATAR_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	img = _make_circular(img)
	var tex = ImageTexture.create_from_image(img)
	_avatar.texture = tex


func _make_circular(img: Image) -> Image:
	var size = Vector2(img.get_width(), img.get_height())
	var target = Vector2(AVATAR_SIZE.x, AVATAR_SIZE.y)
	if size != target:
		img.resize(int(target.x), int(target.y), Image.INTERPOLATE_LANCZOS)
	var center = target * 0.5
	var radius = min(target.x, target.y) * 0.48
	for y in range(int(target.y)):
		for x in range(int(target.x)):
			if Vector2(x, y).distance_to(center) > radius:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return img


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _http_request and is_instance_valid(_http_request):
			_http_request.queue_free()

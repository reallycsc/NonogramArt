var _global_cache: Array = []
var _friends_cache: Array = []
var _cache_timestamp: Dictionary = {}
var _taptap_global_loading: bool = false
var _taptap_friends_loading: bool = false

const LEADERBOARD_ID: String = "691qntuadkntr8vq1o"

const REFRESH_INTERVAL_GLOBAL: int = 600
const REFRESH_INTERVAL_FRIENDS: int = 600

enum TabType { GLOBAL, FRIENDS }


func get_leaderboard(tab: int, _region: String = "") -> Array:
	match tab:
		TabType.GLOBAL:
			return _get_global()
		TabType.FRIENDS:
			return _get_friends()
	return []


func _get_global() -> Array:
	var now = Time.get_unix_time_from_system()
	if not _global_cache.is_empty() and _cache_timestamp.has("global"):
		if now - _cache_timestamp["global"] < REFRESH_INTERVAL_GLOBAL:
			return _global_cache
	if TapTapManager.is_available() and TapTapManager.is_logged_in():
		if not _taptap_global_loading:
			_taptap_global_loading = true
			if not TapTapManager.leaderboard_scores.is_connected(_on_taptap_global_scores):
				TapTapManager.leaderboard_scores.connect(_on_taptap_global_scores)
			TapTapManager.load_leaderboard_scores(LEADERBOARD_ID, "PUBLIC")
		if not _global_cache.is_empty():
			return _global_cache
	return _global_cache


func _get_friends() -> Array:
	var now = Time.get_unix_time_from_system()
	if not _friends_cache.is_empty() and _cache_timestamp.has("friends"):
		if now - _cache_timestamp["friends"] < REFRESH_INTERVAL_FRIENDS:
			return _friends_cache
	if TapTapManager.is_available() and TapTapManager.is_logged_in():
		if not _taptap_friends_loading:
			_taptap_friends_loading = true
			if not TapTapManager.leaderboard_scores.is_connected(_on_taptap_friends_scores):
				TapTapManager.leaderboard_scores.connect(_on_taptap_friends_scores)
			TapTapManager.load_leaderboard_scores(LEADERBOARD_ID, "FRIENDS")
		if not _friends_cache.is_empty():
			return _friends_cache
	return _friends_cache


func invalidate_cache(tab: int = -1) -> void:
	if tab == -1:
		_global_cache.clear()
		_friends_cache.clear()
		_cache_timestamp.clear()
		return
	match tab:
		TabType.GLOBAL:
			_global_cache.clear()
			_cache_timestamp.erase("global")
		TabType.FRIENDS:
			_friends_cache.clear()
			_cache_timestamp.erase("friends")


func get_refresh_interval_seconds(tab: int) -> int:
	match tab:
		TabType.GLOBAL:
			return REFRESH_INTERVAL_GLOBAL
		TabType.FRIENDS:
			return REFRESH_INTERVAL_FRIENDS
	return 600


func format_score(total_seconds: float) -> String:
	var minutes = int(total_seconds) / 60
	var seconds = int(total_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]


func _parse_taptap_scores(scores_json: String) -> Array:
	if scores_json.is_empty():
		return []
	var json = JSON.new()
	if json.parse(scores_json) != OK:
		return []
	var data = json.data
	if not data is Dictionary:
		return []
	var scores = data.get("scores", [])
	if not scores is Array:
		return []
	var current_openid = ""
	if TapTapManager.is_logged_in():
		current_openid = TapTapManager.get_user_id()
	var entries = []
	for i in range(scores.size()):
		var s = scores[i]
		var user = s.get("user", {})
		var openid = user.get("openid", "")
		var is_me = openid == current_openid and not openid.is_empty()
		var score_val = int(s.get("score", "0"))
		var avatar_url = ""
		var avatar_data = user.get("avatar", "")
		if avatar_data is Dictionary:
			avatar_url = avatar_data.get("url", "")
		elif avatar_data is String:
			avatar_url = avatar_data
		entries.append({
			"user_id": openid,
			"nickname": user.get("name", ""),
			"avatar_url": avatar_url,
			"avatar_index": i % 12,
			"score": float(score_val),
			"score_display": str(score_val),
			"is_me": is_me,
		})
	return entries


func _on_taptap_global_scores(scores_json: String) -> void:
	_taptap_global_loading = false
	var entries = _parse_taptap_scores(scores_json)
	if not entries.is_empty():
		entries.sort_custom(func(a, b): return a.score > b.score)
		for i in range(entries.size()):
			entries[i]["rank"] = i + 1
	_global_cache = entries
	_cache_timestamp["global"] = Time.get_unix_time_from_system()


func _on_taptap_friends_scores(scores_json: String) -> void:
	_taptap_friends_loading = false
	var entries = _parse_taptap_scores(scores_json)
	if not entries.is_empty():
		entries.sort_custom(func(a, b): return a.score > b.score)
		for i in range(entries.size()):
			entries[i]["rank"] = i + 1
	_friends_cache = entries
	_cache_timestamp["friends"] = Time.get_unix_time_from_system()

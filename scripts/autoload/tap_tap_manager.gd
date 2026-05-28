extends Node

signal login_success(user_info: Dictionary)
signal login_failed(error: String)
signal login_canceled
signal logout_finished
signal sdk_initialized
signal anti_addiction_callback(code: String, message: String)
signal update_check_result(has_update: bool, info: String)
signal update_available(info: Dictionary)
signal plugin_log(message: String)
signal cloud_save_result(action: String, data: String)
signal cloud_save_list(archives_json: String)
signal cloud_save_data(save_json: String)
signal leaderboard_result(code: String, message: String)
signal leaderboard_scores(scores_json: String)
signal leaderboard_user_score(score_json: String)
signal sdk_api_ready

var _plugin: Object = null
var _is_logged_in: bool = false
var _is_sdk_initialized: bool = false
var _user_info: Dictionary = {}
var _current_archive_id: String = ""
var _login_time: float = 0.0
var _sdk_api_ready: bool = true
var _api_ready_timer: Timer = null

const PLUGIN_NAME: String = "TapTapPlugin"

var _mock_mode: bool = false

func _ready() -> void:
	if OS.get_name() == "Android" and Engine.has_singleton(PLUGIN_NAME):
		_plugin = Engine.get_singleton(PLUGIN_NAME)
		_connect_plugin_signals()
	elif OS.get_name() != "Android":
		_mock_mode = true
		print("TapTapManager: Running in mock mode (non-Android platform)")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and _is_logged_in:
		check_login_state()

func _connect_plugin_signals() -> void:
	if not _plugin:
		return
	if _plugin.has_signal("on_login_success"):
		_plugin.on_login_success.connect(_on_login_success)
	if _plugin.has_signal("on_login_failed"):
		_plugin.on_login_failed.connect(_on_login_failed)
	if _plugin.has_signal("on_login_canceled"):
		_plugin.on_login_canceled.connect(_on_login_canceled)
	if _plugin.has_signal("on_logout_finished"):
		_plugin.on_logout_finished.connect(_on_logout_finished)
	if _plugin.has_signal("on_anti_addiction_callback"):
		_plugin.on_anti_addiction_callback.connect(_on_anti_addiction_callback)
	if _plugin.has_signal("on_update_available"):
		_plugin.on_update_available.connect(_on_update_available)
	if _plugin.has_signal("on_cloud_save_result"):
		_plugin.on_cloud_save_result.connect(_on_cloud_save_result)
	if _plugin.has_signal("on_cloud_save_list"):
		_plugin.on_cloud_save_list.connect(_on_cloud_save_list)
	if _plugin.has_signal("on_cloud_save_data"):
		_plugin.on_cloud_save_data.connect(_on_cloud_save_data)
	if _plugin.has_signal("on_leaderboard_result"):
		_plugin.on_leaderboard_result.connect(_on_leaderboard_result)
	if _plugin.has_signal("on_leaderboard_scores"):
		_plugin.on_leaderboard_scores.connect(_on_leaderboard_scores)
	if _plugin.has_signal("on_leaderboard_user_score"):
		_plugin.on_leaderboard_user_score.connect(_on_leaderboard_user_score)
	if _plugin.has_signal("on_log"):
		_plugin.on_log.connect(_on_plugin_log)

func is_available() -> bool:
	return _plugin != null or _mock_mode

func is_mock_mode() -> bool:
	return _mock_mode

func init_sdk(client_id: String, client_token: String, server_url: String) -> void:
	if _mock_mode:
		_is_sdk_initialized = true
		print("TapTapManager [MOCK]: SDK initialized with client_id=%s" % client_id)
		sdk_initialized.emit()
		return
	if not _plugin:
		push_warning("TapTapManager: Plugin not available on this platform")
		return
	_plugin.initSDK(client_id, client_token, server_url)
	_is_sdk_initialized = true
	sdk_initialized.emit()

func login() -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			login_failed.emit("TapTap SDK not initialized (mock)")
			return
		print("TapTapManager [MOCK]: Login triggered, simulating success in 1s...")
		get_tree().create_timer(1.0).timeout.connect(_mock_login_success)
		return
	if not _plugin:
		login_failed.emit("TapTap SDK not available on this platform")
		return
	if not _is_sdk_initialized:
		login_failed.emit("TapTap SDK not initialized")
		return
	_plugin.login()

func logout() -> void:
	if _mock_mode:
		_is_logged_in = false
		_user_info = {}
		GameManager.taptap_user_id = ""
		GameManager.save_game()
		print("TapTapManager [MOCK]: Logout")
		logout_finished.emit()
		return
	if not _plugin or not _is_logged_in:
		return
	_plugin.logout()

func is_logged_in() -> bool:
	return _is_logged_in

func check_login_state() -> bool:
	if _mock_mode:
		return _is_logged_in
	if not _plugin:
		_is_logged_in = false
		return false
	if not _is_logged_in:
		return false
	if _login_time > 0.0 and (Time.get_ticks_msec() / 1000.0 - _login_time) < 10.0:
		return true
	if _plugin.has_method("isUserLoggedIn"):
		var sdk_logged_in = _plugin.isUserLoggedIn()
		if not sdk_logged_in:
			print("TapTapManager: SDK session expired, updating login state")
			_is_logged_in = false
			_user_info = {}
			_login_time = 0.0
	else:
		var current_id = ""
		if _plugin.has_method("getCurrentUserId"):
			current_id = _plugin.getCurrentUserId()
		if current_id.is_empty():
			print("TapTapManager: SDK session expired (userId empty), updating login state")
			_is_logged_in = false
			_user_info = {}
			_login_time = 0.0
	return _is_logged_in

func get_user_info() -> Dictionary:
	return _user_info

func get_user_name() -> String:
	return _user_info.get("name", "")

func get_user_avatar() -> String:
	return _user_info.get("avatar", "")

func get_user_id() -> String:
	return _user_info.get("user_id", "")

func get_display_user_id() -> String:
	if _mock_mode:
		if _is_logged_in:
			return _user_info.get("openid", "mock_openid_001")
		return ""
	if not _plugin:
		return ""
	return _plugin.getDisplayUserId()

func init_anti_addiction(client_id: String) -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Anti-addiction initialized with client_id=%s" % client_id)
		return
	if not _plugin:
		push_warning("TapTapManager: Plugin not available for anti-addiction init")
		return
	_plugin.initAntiAddiction(client_id)

func check_anti_addiction() -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Anti-addiction check, simulating code=500 (LOGIN_SUCCESS) in 1s...")
		get_tree().create_timer(1.0).timeout.connect(_mock_anti_addiction_success)
		return
	if _plugin and _is_sdk_initialized:
		_plugin.checkAntiAddiction()

func exit_anti_addiction() -> void:
	if _mock_mode:
		print("TapTapManager [MOCK]: Anti-addiction exited")
		anti_addiction_callback.emit("1000", "EXITED")
		return
	if _plugin:
		_plugin.exitAntiAddiction()

func check_update() -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Update check, simulating no update in 1s...")
		get_tree().create_timer(1.0).timeout.connect(_mock_no_update)
		return
	if _plugin:
		_plugin.checkUpdate()

func init_update(client_id: String, client_token: String) -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Update module initialized with client_id=%s" % client_id)
		return
	if not _plugin:
		push_warning("TapTapManager: Plugin not available for update init")
		return
	_plugin.initUpdate(client_id, client_token)

func init_cloud_save() -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Cloud save initialized")
		return
	if not _plugin:
		push_warning("TapTapManager: Plugin not available for cloud save init")
		return
	_plugin.initCloudSave()
	if not _current_archive_id.is_empty() and _plugin.has_method("setCurrentArchiveId"):
		_plugin.setCurrentArchiveId(_current_archive_id)
		print("TapTapManager: Restored archiveId=%s" % _current_archive_id)

func save_to_cloud(save_data: String, summary: String) -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Cloud save, dataLen=%d summary=%s" % [save_data.length(), summary])
		get_tree().create_timer(1.0).timeout.connect(_mock_cloud_save_success)
		return
	if not _plugin:
		push_warning("TapTapManager: Plugin not available for cloud save")
		return
	if not _sdk_api_ready:
		print("TapTapManager: SDK API not ready, deferring cloud save")
		return
	_plugin.saveToCloud(save_data, summary)

func load_cloud_save_list() -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Loading cloud save list...")
		get_tree().create_timer(1.0).timeout.connect(_mock_cloud_save_list)
		return
	if not _plugin:
		return
	if not _sdk_api_ready:
		print("TapTapManager: SDK API not ready, deferring cloud save list load")
		return
	_plugin.loadCloudSaveList()

func load_cloud_save_data(archive_id: String, file_id: String) -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Loading cloud save data...")
		get_tree().create_timer(1.0).timeout.connect(_mock_cloud_save_data)
		return
	if not _plugin:
		return
	_plugin.loadCloudSaveData(archive_id, file_id)

func delete_cloud_save(archive_id: String) -> void:
	if _mock_mode:
		print("TapTapManager [MOCK]: Cloud save deleted")
		cloud_save_result.emit("deleted", archive_id)
		return
	if not _plugin:
		return
	_plugin.deleteCloudSave(archive_id)

func _mock_login_success() -> void:
	var mock_user = {
		"name": "MockPlayer",
		"avatar": "",
		"user_id": "mock_user_001",
		"openid": "mock_openid_001",
	}
	_user_info = mock_user
	_is_logged_in = true
	_login_time = Time.get_ticks_msec() / 1000.0
	GameManager.taptap_user_id = mock_user["user_id"]
	GameManager.save_game()
	print("TapTapManager [MOCK]: Login success - %s" % str(mock_user))
	login_success.emit(mock_user)

func _mock_anti_addiction_success() -> void:
	print("TapTapManager [MOCK]: Anti-addiction callback code=500 (LOGIN_SUCCESS)")
	anti_addiction_callback.emit("500", "LOGIN_SUCCESS")

func _mock_no_update() -> void:
	print("TapTapManager [MOCK]: No update available")
	update_check_result.emit(false, "")

func _mock_cloud_save_success() -> void:
	print("TapTapManager [MOCK]: Cloud save success")
	cloud_save_result.emit("created", "mock_archive_id")

func _mock_cloud_save_list() -> void:
	print("TapTapManager [MOCK]: Cloud save list empty")
	cloud_save_list.emit('{"archives":[]}')

func _mock_cloud_save_data() -> void:
	print("TapTapManager [MOCK]: Cloud save data (empty)")
	cloud_save_data.emit("")

func _on_login_success(user_json: String) -> void:
	var json = JSON.new()
	if json.parse(user_json) == OK and json.data is Dictionary:
		_user_info = json.data
	_is_logged_in = true
	_login_time = Time.get_ticks_msec() / 1000.0
	_sdk_api_ready = false
	if _api_ready_timer == null:
		_api_ready_timer = Timer.new()
		_api_ready_timer.one_shot = true
		_api_ready_timer.timeout.connect(_on_api_ready)
		add_child(_api_ready_timer)
	_api_ready_timer.start(3.0)
	GameManager.taptap_user_id = _user_info.get("user_id", "")
	login_success.emit(_user_info)

func _on_api_ready() -> void:
	_sdk_api_ready = true
	print("TapTapManager: SDK API ready, triggering pending cloud save")
	sdk_api_ready.emit()
	GameManager.save_game()

func _on_login_failed(error: String) -> void:
	login_failed.emit(error)

func _on_login_canceled() -> void:
	login_canceled.emit()

func _on_logout_finished() -> void:
	_is_logged_in = false
	_user_info = {}
	_login_time = 0.0
	GameManager.taptap_user_id = ""
	GameManager.save_game()
	logout_finished.emit()

func _on_anti_addiction_callback(code: String, message: String) -> void:
	anti_addiction_callback.emit(code, message)

func _on_update_available(info_json: String) -> void:
	var json = JSON.new()
	if json.parse(info_json) == OK and json.data is Dictionary:
		update_available.emit(json.data)

func _on_cloud_save_result(action: String, data: String) -> void:
	match action:
		"created", "updated":
			_current_archive_id = data
			GameManager.taptap_archive_id = data
			_write_archive_id_to_save(data)
		"deleted":
			if _current_archive_id == data:
				_current_archive_id = ""
				GameManager.taptap_archive_id = ""
				_write_archive_id_to_save("")
	cloud_save_result.emit(action, data)

func _write_archive_id_to_save(archive_id: String) -> void:
	var file = FileAccess.open(GameManager._save_path, FileAccess.READ)
	if not file:
		return
	var content = file.get_as_text()
	file.close()
	if content.is_empty():
		return
	var json = JSON.new()
	if json.parse(content) != OK:
		return
	var data = json.data
	if not data is Dictionary:
		return
	data["taptap_archive_id"] = archive_id
	var write_file = FileAccess.open(GameManager._save_path, FileAccess.WRITE)
	if write_file:
		write_file.store_string(JSON.stringify(data, "\t"))
		write_file.close()

func _on_cloud_save_list(archives_json: String) -> void:
	if not _current_archive_id.is_empty():
		pass
	elif not archives_json.is_empty():
		var json = JSON.new()
		if json.parse(archives_json) == OK and json.data is Dictionary:
			var archives = json.data.get("archives", [])
			if archives is Array and not archives.is_empty():
				_current_archive_id = archives[0].get("archiveId", "")
				if not _current_archive_id.is_empty():
					GameManager.taptap_archive_id = _current_archive_id
					_write_archive_id_to_save(_current_archive_id)
	cloud_save_list.emit(archives_json)

func _on_cloud_save_data(save_json: String) -> void:
	cloud_save_data.emit(save_json)

func _on_plugin_log(message: String) -> void:
	print("[TapTapPlugin] %s" % message)
	plugin_log.emit(message)

func init_leaderboard() -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Leaderboard initialized")
		return
	if not _plugin:
		push_warning("TapTapManager: Plugin not available for leaderboard init")
		return
	_plugin.initLeaderboard()

func submit_leaderboard_score(leaderboard_id: String, score: int) -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Leaderboard score submitted id=%s score=%d" % [leaderboard_id, score])
		get_tree().create_timer(0.5).timeout.connect(func():
			leaderboard_result.emit("0", "submit_success")
		)
		return
	if not _plugin:
		return
	if not _sdk_api_ready:
		return
	_plugin.submitLeaderboardScore(leaderboard_id, score)

func load_leaderboard_scores(leaderboard_id: String, collection: String = "PUBLIC", page: String = "") -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Loading leaderboard scores id=%s" % leaderboard_id)
		get_tree().create_timer(1.0).timeout.connect(func():
			leaderboard_scores.emit('{"leaderboard":{"id":"%s","name":"mock"},"scores":[],"nextPage":""}' % leaderboard_id)
		)
		return
	if not _plugin:
		return
	if not _sdk_api_ready:
		return
	_plugin.loadLeaderboardScores(leaderboard_id, collection, page)

func load_current_user_score(leaderboard_id: String, collection: String = "PUBLIC") -> void:
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Loading current user score id=%s" % leaderboard_id)
		get_tree().create_timer(1.0).timeout.connect(func():
			leaderboard_user_score.emit('{"rank":"0","rankDisplay":"","score":"0","scoreDisplay":"","user":{"name":"MockPlayer","openid":"mock","avatar":""}}')
		)
		return
	if not _plugin:
		return
	if not _sdk_api_ready:
		return
	_plugin.loadCurrentUserScore(leaderboard_id, collection)

func _on_leaderboard_result(code: String, message: String) -> void:
	leaderboard_result.emit(code, message)

func _on_leaderboard_scores(scores_json: String) -> void:
	leaderboard_scores.emit(scores_json)

func _on_leaderboard_user_score(score_json: String) -> void:
	leaderboard_user_score.emit(score_json)

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
signal friends_list(friends_json: String)
signal sdk_api_ready

var _plugin: Object = null
var _pc_plugin: Object = null
var _is_logged_in: bool = false
var _is_sdk_initialized: bool = false
var _user_info: Dictionary = {}
var _current_archive_id: String = ""
var _current_archive_file_id: String = ""
var _login_time: float = 0.0
var _sdk_api_ready: bool = true
var _api_ready_timer: Timer = null

const PLUGIN_NAME: String = "TapTapPlugin"
const PC_PLUGIN_NAME: String = "TapTapPC"

var _mock_mode: bool = false
var _pc_mode: bool = false

func _ready() -> void:
	if OS.get_name() == "Android" and Engine.has_singleton(PLUGIN_NAME):
		_plugin = Engine.get_singleton(PLUGIN_NAME)
		_connect_plugin_signals()
	elif OS.get_name() == "Windows" and Engine.has_singleton(PC_PLUGIN_NAME):
		_pc_plugin = Engine.get_singleton(PC_PLUGIN_NAME)
		_pc_mode = true
		_connect_pc_signals()
		print("TapTapManager: Running in PC mode (TapTapPC GDExtension)")
	else:
		_mock_mode = true
		print("TapTapManager: Running in mock mode (non-Android/PC platform)")

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
	if _plugin.has_signal("on_friends_list"):
		_plugin.on_friends_list.connect(_on_friends_list)
	if _plugin.has_signal("on_log"):
		_plugin.on_log.connect(_on_plugin_log)

func _connect_pc_signals() -> void:
	if not _pc_plugin:
		return
	if _pc_plugin.has_signal("on_login_success"):
		_pc_plugin.on_login_success.connect(_on_pc_login_success)
	if _pc_plugin.has_signal("on_login_failed"):
		_pc_plugin.on_login_failed.connect(_on_login_failed)
	if _pc_plugin.has_signal("on_login_canceled"):
		_pc_plugin.on_login_canceled.connect(_on_login_canceled)
	if _pc_plugin.has_signal("on_sdk_initialized"):
		_pc_plugin.on_sdk_initialized.connect(_on_pc_sdk_initialized)
	if _pc_plugin.has_signal("on_system_state_changed"):
		_pc_plugin.on_system_state_changed.connect(_on_pc_system_state_changed)
	if _pc_plugin.has_signal("on_game_playable_changed"):
		_pc_plugin.on_game_playable_changed.connect(_on_pc_game_playable_changed)
	if _pc_plugin.has_signal("on_dlc_playable_changed"):
		_pc_plugin.on_dlc_playable_changed.connect(_on_pc_dlc_playable_changed)
	if _pc_plugin.has_signal("on_cloud_save_list"):
		_pc_plugin.on_cloud_save_list.connect(_on_pc_cloud_save_list)
	if _pc_plugin.has_signal("on_cloud_save_created"):
		_pc_plugin.on_cloud_save_created.connect(_on_pc_cloud_save_created)
	if _pc_plugin.has_signal("on_cloud_save_updated"):
		_pc_plugin.on_cloud_save_updated.connect(_on_pc_cloud_save_updated)
	if _pc_plugin.has_signal("on_cloud_save_deleted"):
		_pc_plugin.on_cloud_save_deleted.connect(_on_pc_cloud_save_deleted)
	if _pc_plugin.has_signal("on_cloud_save_data"):
		_pc_plugin.on_cloud_save_data.connect(_on_pc_cloud_save_data)
	if _pc_plugin.has_signal("on_achievement_unlocked"):
		_pc_plugin.on_achievement_unlocked.connect(_on_pc_achievement_unlocked)
	if _pc_plugin.has_signal("on_achievement_incremented"):
		_pc_plugin.on_achievement_incremented.connect(_on_pc_achievement_incremented)
	if _pc_plugin.has_signal("on_real_name_result"):
		_pc_plugin.on_real_name_result.connect(_on_pc_real_name_result)
	if _pc_plugin.has_signal("on_compliance_actions"):
		_pc_plugin.on_compliance_actions.connect(_on_pc_compliance_actions)

func is_available() -> bool:
	return _plugin != null or _pc_plugin != null or _mock_mode

func is_mock_mode() -> bool:
	return _mock_mode

func is_pc_mode() -> bool:
	return _pc_mode

func init_sdk(client_id: String, client_token: String, server_url: String) -> void:
	if _pc_mode:
		_init_pc_sdk(client_id, client_token)
		return
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

func _init_pc_sdk(client_id: String, client_public_key: String) -> void:
	if not _pc_plugin:
		return
	if _pc_plugin.check_restart(client_id):
		if OS.is_debug_build():
			print("TapTapManager [PC]: Debug build - skipping restart requirement")
		else:
			print("TapTapManager [PC]: App needs restart via TapTap launcher, quitting")
			get_tree().quit()
			return
	var result = _pc_plugin.init_sdk(client_id, client_public_key)
	if result == 0:
		_is_sdk_initialized = true
		print("TapTapManager [PC]: SDK initialized successfully")
	else:
		print("TapTapManager [PC]: SDK init result=%d" % result)
		if result == 2:
			print("TapTapManager [PC]: TapTap platform not found, running in standalone mode")
		elif result == 3:
			print("TapTapManager [PC]: Not launched through TapTap, running in standalone mode")
		elif result == 4:
			print("TapTapManager [PC]: Platform version mismatch")
		if OS.is_debug_build():
			_is_sdk_initialized = false
			print("TapTapManager [PC]: Debug build - continuing without SDK, TapTap features disabled")
		else:
			_is_sdk_initialized = false
	sdk_initialized.emit()

func _on_pc_sdk_initialized(result_code: int) -> void:
	print("TapTapManager [PC]: SDK initialized callback, result=%d" % result_code)

func login() -> void:
	if _pc_mode:
		_pc_login()
		return
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

func _pc_login() -> void:
	if not _pc_plugin or not _is_sdk_initialized:
		login_failed.emit("TapTap PC SDK not initialized")
		return
	var result = _pc_plugin.login("public_profile")
	match result:
		1:
			print("TapTapManager [PC]: Login request sent")
		2:
			login_failed.emit("Login request failed")
		3:
			push_warning("TapTapManager [PC]: Login already in progress")
		0:
			login_failed.emit("Login unknown error, SDK may not be initialized")

func _on_pc_login_success(user_json: String) -> void:
	var json = JSON.new()
	if json.parse(user_json) == OK and json.data is Dictionary:
		var auth_data = json.data
		_user_info = {
			"name": "",
			"avatar": "",
			"user_id": "",
			"openid": _pc_plugin.get_open_id() if _pc_plugin else "",
			"token_type": auth_data.get("token_type", ""),
			"kid": auth_data.get("kid", ""),
			"mac_key": auth_data.get("mac_key", ""),
			"mac_algorithm": auth_data.get("mac_algorithm", ""),
			"scope": auth_data.get("scope", ""),
		}
	else:
		_user_info = {"openid": _pc_plugin.get_open_id() if _pc_plugin else ""}
	_is_logged_in = true
	_login_time = Time.get_ticks_msec() / 1000.0
	_sdk_api_ready = false
	if _api_ready_timer == null:
		_api_ready_timer = Timer.new()
		_api_ready_timer.one_shot = true
		_api_ready_timer.timeout.connect(_on_api_ready)
		add_child(_api_ready_timer)
	_api_ready_timer.start(1.0)
	GameManager.taptap_user_id = _user_info.get("openid", "")
	login_success.emit(_user_info)

func logout() -> void:
	if _pc_mode:
		_is_logged_in = false
		_user_info = {}
		GameManager.taptap_user_id = ""
		GameManager.save_game()
		print("TapTapManager [PC]: Logout")
		logout_finished.emit()
		return
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

func is_sdk_logged_in() -> bool:
	if _pc_mode:
		return _is_logged_in
	if _mock_mode:
		return _is_logged_in
	if not _plugin:
		return false
	return _plugin.isUserLoggedIn()

func check_login_state() -> bool:
	if _pc_mode:
		return _is_logged_in
	if _mock_mode:
		return _is_logged_in
	if not _plugin:
		_is_logged_in = false
		return false
	if not _is_logged_in:
		return false
	if _login_time > 0.0 and (Time.get_ticks_msec() / 1000.0 - _login_time) < 10.0:
		return true
	var sdk_logged_in = _plugin.isUserLoggedIn()
	if not sdk_logged_in:
		print("TapTapManager: SDK session expired, updating login state")
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
	if _pc_mode:
		if _pc_plugin:
			return _pc_plugin.get_open_id()
		return ""
	if _mock_mode:
		if _is_logged_in:
			return _user_info.get("openid", "mock_openid_001")
		return ""
	if not _plugin:
		return ""
	return _plugin.getDisplayUserId()

func get_current_user_info() -> Dictionary:
	if _pc_mode:
		if _pc_plugin:
			var openid = _pc_plugin.get_open_id()
			if not openid.is_empty():
				return {"openid": openid, "name": "", "avatar": "", "user_id": openid}
		return {}
	if _mock_mode:
		if _is_logged_in:
			return _user_info
		return {}
	if not _plugin:
		return {}
	if not _plugin.has_method("getCurrentUserInfo"):
		return {}
	var json_str = _plugin.getCurrentUserInfo()
	if json_str.is_empty():
		return {}
	var json = JSON.new()
	if json.parse(json_str) != OK:
		return {}
	if json.data is Dictionary:
		return json.data
	return {}

func init_anti_addiction(client_id: String) -> void:
	if _pc_mode:
		if not _is_sdk_initialized:
			return
		_pc_plugin.enable_anti_addiction()
		print("TapTapManager [PC]: Anti-addiction enabled")
		return
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
	if _pc_mode:
		if not _is_sdk_initialized:
			return
		_pc_plugin.ensure_real_name()
		print("TapTapManager [PC]: Real name verification requested")
		return
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Anti-addiction check, simulating code=500 (LOGIN_SUCCESS) in 1s...")
		get_tree().create_timer(1.0).timeout.connect(_mock_anti_addiction_success)
		return
	if _plugin and _is_sdk_initialized:
		_plugin.checkAntiAddiction()

func _on_pc_real_name_result(status: int, error: String) -> void:
	match status:
		1:
			anti_addiction_callback.emit("500", "LOGIN_SUCCESS")
		2:
			login_canceled.emit()
		3:
			anti_addiction_callback.emit("1100", "Real name verification failed: " + error)
		_:
			anti_addiction_callback.emit("500", "LOGIN_SUCCESS")

func _on_pc_compliance_actions(actions_json: String) -> void:
	var json = JSON.new()
	if json.parse(actions_json) == OK and json.data is Array:
		for action in json.data:
			var action_type = action.get("action_type", 0)
			var title = action.get("title", "")
			var description = action.get("description", "")
			match action_type:
				1:
					if not title.is_empty():
						ToastManager.show_toast(title)
				2:
					ToastManager.show_toast(tr("游戏时长提醒: %s") % description)
				3:
					ToastManager.show_toast(tr("游戏时间已到，请休息"))
					get_tree().create_timer(3.0).timeout.connect(func(): get_tree().quit())

func exit_anti_addiction() -> void:
	if _pc_mode:
		print("TapTapManager [PC]: Anti-addiction exited")
		anti_addiction_callback.emit("1000", "EXITED")
		return
	if _mock_mode:
		print("TapTapManager [MOCK]: Anti-addiction exited")
		anti_addiction_callback.emit("1000", "EXITED")
		return
	if _plugin:
		_plugin.exitAntiAddiction()

func check_update() -> void:
	if _pc_mode:
		update_check_result.emit(false, "")
		return
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Update check, simulating no update in 1s...")
		get_tree().create_timer(1.0).timeout.connect(_mock_no_update)
		return
	if _plugin:
		_plugin.checkUpdate()

func init_update(client_id: String, client_token: String) -> void:
	if _pc_mode:
		return
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
	if _pc_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [PC]: Cloud save ready (no separate init needed)")
		return
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
	if _pc_mode:
		_pc_save_to_cloud(save_data, summary)
		return
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

func _pc_save_to_cloud(save_data: String, summary: String) -> void:
	if not _pc_plugin or not _is_sdk_initialized:
		return
	var temp_path = OS.get_user_data_dir() + "/cloud_save_temp.dat"
	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	if not file:
		push_warning("TapTapManager [PC]: Failed to write temp cloud save file")
		return
	file.store_string(save_data)
	file.close()
	if _current_archive_id.is_empty():
		_pc_plugin.create_cloud_save("NonogramArt Save", summary, "", 0, temp_path, "")
	else:
		_pc_plugin.update_cloud_save(_current_archive_id, "NonogramArt Save", summary, "", 0, temp_path, "")

func load_cloud_save_list() -> void:
	if _pc_mode:
		if not _pc_plugin or not _is_sdk_initialized:
			return
		_pc_plugin.load_cloud_save_list()
		return
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
	if _pc_mode:
		if not _pc_plugin or not _is_sdk_initialized:
			return
		_pc_plugin.load_cloud_save_data(archive_id, file_id)
		return
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
	if _pc_mode:
		if not _pc_plugin or not _is_sdk_initialized:
			return
		_pc_plugin.delete_cloud_save(archive_id)
		return
	if _mock_mode:
		print("TapTapManager [MOCK]: Cloud save deleted")
		cloud_save_result.emit("deleted", archive_id)
		return
	if not _plugin:
		return
	_plugin.deleteCloudSave(archive_id)

func is_game_owned() -> bool:
	if _pc_mode and _pc_plugin:
		return _pc_plugin.is_game_owned()
	return true

func is_dlc_owned(dlc_id: String) -> bool:
	if _pc_mode and _pc_plugin:
		return _pc_plugin.is_dlc_owned(dlc_id)
	return false

func show_dlc_store(dlc_id: String) -> void:
	if _pc_mode and _pc_plugin:
		_pc_plugin.show_dlc_store(dlc_id)

func unlock_achievement(achievement_id: String) -> void:
	if _pc_mode and _pc_plugin and _is_sdk_initialized:
		_pc_plugin.unlock_achievement(achievement_id)

func increment_achievement(achievement_id: String, steps: int) -> void:
	if _pc_mode and _pc_plugin and _is_sdk_initialized:
		_pc_plugin.increment_achievement(achievement_id, steps)

func show_achievements() -> void:
	if _pc_mode and _pc_plugin and _is_sdk_initialized:
		_pc_plugin.show_achievements()

func _on_pc_system_state_changed(state: int) -> void:
	match state:
		1:
			print("TapTapManager [PC]: TapTap client online")
		2:
			print("TapTapManager [PC]: TapTap client offline, game ownership checks may be stale")
		3:
			print("TapTapManager [PC]: TapTap client shutdown, saving and exiting")
			GameManager.save_game()
			get_tree().quit()

func _on_pc_game_playable_changed(is_playable: bool) -> void:
	if not is_playable:
		ToastManager.show_toast(tr("游戏所有权状态变更，请确认您仍拥有该游戏"))

func _on_pc_dlc_playable_changed(dlc_id: String, is_playable: bool) -> void:
	print("TapTapManager [PC]: DLC %s playable: %s" % [dlc_id, str(is_playable)])

func _on_pc_cloud_save_list(archives_json: String) -> void:
	var json = JSON.new()
	if json.parse(archives_json) == OK and json.data is Array:
		var archives = []
		for save in json.data:
			archives.append({
				"archiveId": save.get("uuid", ""),
				"fileId": save.get("file_id", ""),
				"name": save.get("name", ""),
				"summary": save.get("summary", ""),
				"playtime": save.get("playtime", 0),
				"modified_time": save.get("modified_time", 0),
			})
		if not archives.is_empty() and _current_archive_id.is_empty():
			_current_archive_id = archives[0].get("archiveId", "")
			_current_archive_file_id = archives[0].get("fileId", "")
			if not _current_archive_id.is_empty():
				GameManager.taptap_archive_id = _current_archive_id
				_write_archive_id_to_save(_current_archive_id)
		var result_json = JSON.stringify({"archives": archives})
		cloud_save_list.emit(result_json)
	else:
		cloud_save_list.emit('{"archives":[]}')

func _on_pc_cloud_save_created(save_json: String) -> void:
	var json = JSON.new()
	if json.parse(save_json) == OK and json.data is Dictionary:
		_current_archive_id = json.data.get("uuid", "")
		_current_archive_file_id = json.data.get("file_id", "")
		GameManager.taptap_archive_id = _current_archive_id
		_write_archive_id_to_save(_current_archive_id)
	cloud_save_result.emit("created", _current_archive_id)

func _on_pc_cloud_save_updated(save_json: String) -> void:
	var json = JSON.new()
	if json.parse(save_json) == OK and json.data is Dictionary:
		_current_archive_id = json.data.get("uuid", "")
		_current_archive_file_id = json.data.get("file_id", "")
		GameManager.taptap_archive_id = _current_archive_id
		_write_archive_id_to_save(_current_archive_id)
	cloud_save_result.emit("updated", _current_archive_id)

func _on_pc_cloud_save_deleted(uuid: String) -> void:
	if _current_archive_id == uuid:
		_current_archive_id = ""
		_current_archive_file_id = ""
		GameManager.taptap_archive_id = ""
		_write_archive_id_to_save("")
	cloud_save_result.emit("deleted", uuid)

func _on_pc_cloud_save_data(data: String, _size: int) -> void:
	cloud_save_data.emit(data)

func _on_pc_achievement_unlocked(achievement_json: String) -> void:
	print("TapTapManager [PC]: Achievement unlocked: %s" % achievement_json)

func _on_pc_achievement_incremented(achievement_json: String) -> void:
	print("TapTapManager [PC]: Achievement incremented: %s" % achievement_json)

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
	_api_ready_timer.start(1.0)
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
	if _pc_mode:
		return
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
	if _pc_mode:
		return
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
	if _pc_mode:
		return
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
	if _pc_mode:
		return
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

func init_friends() -> void:
	if _pc_mode:
		return
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Friends module initialized")
		return
	if not _plugin:
		print("TapTapManager: Plugin not available for friends init")
		return
	_plugin.initFriends()

func get_friends_list(next_page_token: String = "") -> void:
	if _pc_mode:
		return
	if _mock_mode:
		if not _is_sdk_initialized:
			return
		print("TapTapManager [MOCK]: Getting friends list...")
		get_tree().create_timer(1.0).timeout.connect(func():
			friends_list.emit('{"friends":[{"openid":"mock_friend_001","name":"MockFriend1","avatar":""},{"openid":"mock_friend_002","name":"MockFriend2","avatar":""}],"nextPageToken":""}')
		)
		return
	if not _plugin:
		return
	_plugin.getFriendsList(next_page_token)

func _on_friends_list(friends_json: String) -> void:
	if not friends_json.is_empty():
		var json = JSON.new()
		if json.parse(friends_json) == OK and json.data is Dictionary:
			var friends = json.data.get("friends", [])
			var next_page = json.data.get("nextPageToken", "")
			print("TapTapManager: Friends list received - count=%d nextPage=%s" % [friends.size(), next_page])
			for friend in friends:
				print("  Friend: name=%s openid=%s avatar=%s" % [friend.get("name", ""), friend.get("openid", ""), friend.get("avatar", "")])
		else:
			print("TapTapManager: Friends list parse error")
	else:
		print("TapTapManager: Friends list empty or error")
	friends_list.emit(friends_json)

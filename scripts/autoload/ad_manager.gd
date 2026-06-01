extends Node

signal ad_initialized(success: bool)
signal rewarded_loaded
signal rewarded_load_failed(reason: String)
signal rewarded_show
signal rewarded_complete(reward_type: String)
signal rewarded_skipped
signal rewarded_close
signal rewarded_error(reason: String)
signal banner_loaded
signal banner_load_failed(reason: String)
signal banner_click
signal banner_error(reason: String)
signal splash_loaded
signal splash_load_failed(reason: String)
signal splash_show
signal splash_error(reason: String)

var _plugin: Object = null
var _initialized: bool = false
var _mock_mode: bool = false
var _auto_show: bool = false
var _rewarded_space_id: String = ""
var _banner_space_id: String = ""
var _splash_space_id: String = ""

const AD_MEDIA_ID: String = "1103083"
const AD_MEDIA_KEY: String = "42mxPgPi2X6xh8JyY0V5NwUOKigEJtQRvF1ALXCrYBDJNgz9SwkCGyrhPsrEafwp"
const AD_REWARDED_SPACE_ID: String = "1057204"
const AD_TAP_CLIENT_ID: String = "fictuviuwc34cqheew"
const AD_BANNER_SPACE_ID: String = ""
const AD_SPLASH_SPACE_ID: String = ""

const REWARD_TYPE_COIN: String = "coin"
const REWARD_TYPE_HINT: String = "hint"
const REWARD_TYPE_LIFE: String = "life"

func _get_plugin_name() -> String:
	return "AdPlugin"

func _ready() -> void:
	_plugin = Engine.get_singleton(_get_plugin_name())
	if _plugin == null:
		print("AdManager: Plugin not available, using mock mode")
		_mock_mode = true
	else:
		_connect_signals()

func _connect_signals() -> void:
	_plugin.on_ad_initialized.connect(_on_ad_initialized)
	_plugin.on_rewarded_loaded.connect(_on_rewarded_loaded)
	_plugin.on_rewarded_load_failed.connect(_on_rewarded_load_failed)
	_plugin.on_rewarded_show.connect(_on_rewarded_show)
	_plugin.on_rewarded_complete.connect(_on_rewarded_complete)
	_plugin.on_rewarded_skipped.connect(_on_rewarded_skipped)
	_plugin.on_rewarded_close.connect(_on_rewarded_close)
	_plugin.on_rewarded_error.connect(_on_rewarded_error)

func init_ad(media_id: String = AD_MEDIA_ID, media_key: String = AD_MEDIA_KEY) -> void:
	if media_id.is_empty() or media_key.is_empty():
		print("AdManager: Media ID or Key not configured")
		ad_initialized.emit(false)
		return
	if _mock_mode:
		print("AdManager [MOCK]: Ad initialized")
		_initialized = true
		ad_initialized.emit(true)
		return
	_plugin.initAd(media_id, media_key)

func request_permissions() -> void:
	if _mock_mode:
		print("AdManager [MOCK]: Permissions requested")
		return
	_plugin.requestAdPermissions()

func is_initialized() -> bool:
	return _initialized

func is_rewarded_loaded() -> bool:
	if _mock_mode:
		return true
	return _plugin.isRewardedVideoLoaded()

func load_rewarded_video(space_id: String = AD_REWARDED_SPACE_ID) -> void:
	_rewarded_space_id = space_id
	if space_id.is_empty():
		push_warning("AdManager: Rewarded video space ID not configured")
		rewarded_load_failed.emit("space_id_empty")
		return
	_auto_show = true
	if _mock_mode:
		print("AdManager [MOCK]: Loading rewarded video...")
		get_tree().create_timer(2.0).timeout.connect(func():
			rewarded_loaded.emit()
			show_rewarded_video()
		)
		return
	if not _initialized:
		print("AdManager: SDK not initialized, initializing first...")
		init_ad()
		await ad_initialized
		if not _initialized:
			rewarded_load_failed.emit("sdk_init_failed")
			return
	_plugin.loadRewardedVideo(space_id)

func show_rewarded_video(reward_type: String = REWARD_TYPE_LIFE) -> void:
	if _mock_mode:
		print("AdManager [MOCK]: Showing rewarded video...")
		get_tree().create_timer(0.5).timeout.connect(func():
			rewarded_show.emit()
			rewarded_complete.emit(reward_type)
		)
		return
	if not _plugin.isRewardedVideoLoaded():
		print("AdManager: Rewarded video not loaded")
		rewarded_error.emit("not_loaded")
		return
	_plugin.showRewardedVideo()

func is_banner_loaded() -> bool:
	if _mock_mode:
		return true
	return _plugin.isBannerLoaded()

func load_banner(space_id: String = AD_BANNER_SPACE_ID, width: int = 320, height: int = 50) -> void:
	_banner_space_id = space_id
	if space_id.is_empty():
		push_warning("AdManager: Banner space ID not configured")
		banner_load_failed.emit("space_id_empty")
		return
	if _mock_mode:
		print("AdManager [MOCK]: Banner loaded")
		banner_loaded.emit()
		return
	_plugin.loadBanner(space_id, width, height)

func show_banner() -> void:
	if _mock_mode:
		print("AdManager [MOCK]: Banner shown")
		return
	_plugin.showBanner()

func hide_banner() -> void:
	if _mock_mode:
		print("AdManager [MOCK]: Banner hidden")
		return
	_plugin.hideBanner()

func load_splash(space_id: String = AD_SPLASH_SPACE_ID, timeout_ms: int = 3000) -> void:
	_splash_space_id = space_id
	if space_id.is_empty():
		push_warning("AdManager: Splash space ID not configured")
		splash_load_failed.emit("space_id_empty")
		return
	if _mock_mode:
		print("AdManager [MOCK]: Splash loaded")
		splash_loaded.emit()
		return
	_plugin.loadSplashAd(space_id, timeout_ms)

func _on_ad_initialized(success: String) -> void:
	_initialized = success == "1"
	print("AdManager: SDK initialized=%s" % _initialized)
	ad_initialized.emit(_initialized)

func _on_rewarded_loaded() -> void:
	print("AdManager: Rewarded video loaded")
	rewarded_loaded.emit()
	if _auto_show:
		_auto_show = false
		show_rewarded_video()

func _on_rewarded_load_failed(reason: String) -> void:
	print("AdManager: Rewarded video load failed: %s" % reason)
	_auto_show = false
	rewarded_load_failed.emit(reason)

func _on_rewarded_show() -> void:
	print("AdManager: Rewarded video shown")
	rewarded_show.emit()

func _on_rewarded_complete(reward_info: String) -> void:
	print("AdManager: Rewarded video complete: %s" % reward_info)
	rewarded_complete.emit(reward_info)

func _on_rewarded_skipped() -> void:
	print("AdManager: Rewarded video skipped")
	rewarded_skipped.emit()

func _on_rewarded_close() -> void:
	print("AdManager: Rewarded video closed")
	rewarded_close.emit()

func _on_rewarded_error(reason: String) -> void:
	print("AdManager: Rewarded video error: %s" % reason)
	rewarded_error.emit(reason)

func _on_banner_loaded() -> void:
	print("AdManager: Banner loaded")
	banner_loaded.emit()

func _on_banner_load_failed(reason: String) -> void:
	print("AdManager: Banner load failed: %s" % reason)
	banner_load_failed.emit(reason)

func _on_banner_click() -> void:
	print("AdManager: Banner clicked")
	banner_click.emit()

func _on_banner_error(reason: String) -> void:
	print("AdManager: Banner error: %s" % reason)
	banner_error.emit(reason)

func _on_splash_loaded() -> void:
	print("AdManager: Splash loaded")
	splash_loaded.emit()

func _on_splash_load_failed(reason: String) -> void:
	print("AdManager: Splash load failed: %s" % reason)
	splash_load_failed.emit(reason)

func _on_splash_show() -> void:
	print("AdManager: Splash shown")
	splash_show.emit()

func _on_splash_error(reason: String) -> void:
	print("AdManager: Splash error: %s" % reason)
	splash_error.emit(reason)

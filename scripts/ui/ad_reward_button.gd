extends TextureButton

signal ad_reward_triggered(reward_type: String)

enum RewardType {
	COIN = "coin"
	HINT = "hint"
	LIFE = "life"
	UNLOCK_ALBUM = "unlock_album"
}

const REWARD_TYPE_COIN: String = "coin"
const REWARD_TYPE_HINT: String = "hint"
const REWARD_TYPE_LIFE: String = "life"
const REWARD_TYPE_UNLOCK: String = "unlock_album"

const HOVER_SCALE := Vector2(1.1, 1.1)
const NORMAL_SCALE := Vector2(1.0, 1.0)
const PRESS_SCALE := Vector2(0.9, 0.9)

var _reward_type: String = REWARD_TYPE_COIN
var _reward_amount: int = 10
var _hover_tween: Tween = null
var _state: int = State.IDLE
var _loading_dot_timer: Timer = null
var _loading_dots: int = 0
var _connected: bool = false

enum State {
	IDLE
	LOADING
	READY
	SHOWING
}

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	pressed.connect(_on_pressed)
	_connect_signals()
	_update_display()


func _connect_signals() -> void:
	if _connected:
		return
	_connected = true
	AdManager.rewarded_loaded.connect(_on_rewarded_loaded)
	AdManager.rewarded_show.connect(_on_rewarded_show)
	AdManager.rewarded_complete.connect(_on_rewarded_complete)
	AdManager.rewarded_skipped.connect(_on_rewarded_skipped)
	AdManager.rewarded_close.connect(_on_rewarded_close)
	AdManager.rewarded_load_failed.connect(_on_rewarded_load_failed)
	AdManager.rewarded_error.connect(_on_rewarded_error)


func setup(p_reward_type: String, p_reward_amount: int = 10) -> void:
	_reward_type = p_reward_type
	_reward_amount = p_reward_amount
	_update_display()


func _on_mouse_entered() -> void:
	if _state == State.SHOWING:
		return
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", HOVER_SCALE, 0.15).set_trans(Tween.TRANS_CUBIC)


func _on_mouse_exited() -> void:
	if _state == State.SHOWING:
		return
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", NORMAL_SCALE, 0.15).set_trans(Tween.TRANS_CUBIC)


func _on_button_down() -> void:
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", PRESS_SCALE, 0.08).set_trans(Tween.TRANS_CUBIC)


func _on_button_up() -> void:
	if _state != State.SHOWING:
		_hover_tween = create_tween()
		_hover_tween.set_parallel(true)
		_hover_tween.tween_property(self, "scale", NORMAL_SCALE, 0.08).set_trans(Tween.TRANS_CUBIC)


func _on_pressed() -> void:
	if _state == State.SHOWING or _state == State.LOADING:
		return
	_request_and_show_ad()


func _request_and_show_ad() -> void:
	_state = State.LOADING
	_update_display()
	_start_loading_animation()
	AdManager.load_rewarded_video()


func _start_loading_animation() -> void:
	if _loading_dot_timer == null:
		_loading_dot_timer = Timer.new()
		_loading_dot_timer.one_shot = false
		_loading_dot_timer.wait_time = 0.4
		add_child(_loading_dot_timer)
		_loading_dot_timer.timeout.connect(_update_loading_dots)
	_loading_dots = 0
	_loading_dot_timer.start()


func _update_loading_dots() -> void:
	_loading_dots = (_loading_dots + 1) % 4


func _stop_loading_animation() -> void:
	if _loading_dot_timer != null:
		_loading_dot_timer.stop()


func set_ready() -> void:
	_state = State.READY
	_stop_loading_animation()
	_update_display()


func set_showing() -> void:
	_state = State.SHOWING
	_stop_loading_animation()
	_update_display()


func reset() -> void:
	_state = State.IDLE
	_stop_loading_animation()
	_update_display()


func _update_display() -> void:
	match _state:
		State.IDLE:
			modulate = Color(0.6, 0.6, 0.6, 1.0)
		State.LOADING:
			modulate = Color(0.8, 0.8, 0.8, 1.0)
		State.READY:
			modulate = Color(1.0, 1.0, 1.0, 1.0)
		State.SHOWING:
			modulate = Color(0.5, 0.5, 0.5, 0.5)


func _get_reward_description() -> String:
	match _reward_type:
		REWARD_TYPE_COIN:
			return "+%d %s" % [_reward_amount, tr("金币")]
		REWARD_TYPE_HINT:
			return "+%d %s" % [_reward_amount, tr("提示")]
		REWARD_TYPE_LIFE:
			return "+%d %s" % [_reward_amount, tr("生命")]
		REWARD_TYPE_UNLOCK:
			return tr("解锁画册")
	return ""


func _on_rewarded_loaded() -> void:
	if _state == State.LOADING:
		set_ready()
		AdManager.show_rewarded_video()


func _on_rewarded_show() -> void:
	set_showing()


func _on_rewarded_complete(reward_info: String) -> void:
	print("AdRewardButton: Reward complete: %s" % reward_info)
	ad_reward_triggered.emit(_reward_type)
	reset()


func _on_rewarded_skipped() -> void:
	print("AdRewardButton: Reward skipped")
	reset()


func _on_rewarded_close() -> void:
	print("AdRewardButton: Reward closed")
	reset()


func _on_rewarded_load_failed(reason: String) -> void:
	print("AdRewardButton: Load failed: %s" % reason)
	reset()
	ToastManager.show(tr("广告加载失败，请稍后重试"))


func _on_rewarded_error(reason: String) -> void:
	print("AdRewardButton: Error: %s" % reason)
	reset()
	ToastManager.show(tr("广告播放出错，请稍后重试"))

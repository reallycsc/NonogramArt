extends Control

signal agreed
signal disagreed

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var panel: Panel = $PanelContainer
@onready var privacy_label: RichTextLabel = $PanelContainer/ScrollContainer/PrivacyLabel

const PRIVACY_TEXT: String = """《数织艺术》隐私政策

生效日期：2026年5月27日

欢迎您使用《数织艺术》！我们非常重视您的隐私保护和个人信息安全。请您在使用本应用前，仔细阅读本隐私政策。

一、信息收集与使用

1. 我们会收集您的设备信息（设备型号、操作系统版本）用于应用稳定性保障。
2. 当您使用 TapTap 登录功能时，我们会收集您的 TapTap 账号信息（昵称、头像、OpenID）用于身份识别和游戏进度同步。
3. 我们会收集您的游戏进度数据用于存档和成就系统。

二、第三方 SDK 信息

本应用集成了 TapTap 开发者服务（TapSDK），用于提供以下功能：
• TapTap 登录：实现一键登录
• 合规认证：防沉迷系统
• 更新唤起：版本更新提醒
• 成就系统：游戏成就展示

TapSDK 可能收集的设备信息包括：设备型号、操作系统版本、设备标识符、网络状态。详情请参阅TapTap 隐私政策：https://developer.taptap.cn/docs/sdk/start/agreement/

三、信息存储与安全

1. 您的游戏进度数据存储在本地设备中。
2. 如您使用 TapTap 登录，游戏进度可同步至云端服务器。
3. 我们采用行业标准的安全措施保护您的个人信息。

四、您的权利

1. 您有权拒绝授权 TapTap 登录，但将无法使用云存档等在线功能。
2. 您可以随时在设置中退出登录，退出后我们将停止收集您的信息。
3. 您有权删除您的账号和相关数据。

五、未成年人保护

我们严格遵守国家关于未成年人网络保护的相关法律法规，已接入防沉迷系统，对未成年人游戏时间进行限制。

六、隐私政策更新

我们可能会不时更新本隐私政策。更新后的政策将在应用内通知您。

七、联系我们

如您对本隐私政策有任何疑问，请通过以下方式联系我们：
邮箱：reallyc2@sina.com"""

func _ready() -> void:
	visible = false
	if privacy_label:
		privacy_label.text = PRIVACY_TEXT

func show_popup() -> void:
	if privacy_label:
		privacy_label.text = PRIVACY_TEXT
	visible = true
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	dim_overlay.color = Color(0, 0, 0, 0.0)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim_overlay, "color", Color(0, 0, 0, 0.8), 0.3)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func _on_agree_pressed() -> void:
	AudioManager.play_sfx("click")
	_hide_with_callback(func(): agreed.emit())

func _on_disagree_pressed() -> void:
	AudioManager.play_sfx("click")
	_hide_with_callback(func(): disagreed.emit())

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

# Godot 4.x 接入 TapTap — 完整流程文档

## 概述

本文档记录了在 Godot 4.6 项目（{{PROJECT_DISPLAY_NAME}}）中接入 TapTap 全功能（登录、防沉迷、更新、云存档、排行榜）的完整流程，包括方案规划、Android 插件开发、GDScript 封装、UI 集成、构建部署及踩坑记录。

## 技术选型

| 项目 | 选择 | 说明 |
| ---- | ---- | ---- |
| 引擎 | Godot 4.6.3 | 使用 Gradle 构建模式导出 Android |
| SDK | TapSDK v4.10.2 | TapTap 官方 Android SDK（v4 统一初始化架构） |
| 登录模式 | TapTapLogin.loginWithScopes | v4 统一登录 API，支持 scope 授权 |
| 防沉迷 | TapTapCompliance | v4 合规认证模块，替代 v3 的 AntiAddictionUIKit |
| 云存档 | TapTapCloudSave | v4 新增模块，支持创建/更新/下载/删除存档 |
| 排行榜 | TapTapLeaderboard | v4 排行榜模块，支持提交分数/获取排名/好友榜 |
| 更新唤起 | Intent 跳转 TapTap 客户端 | v4 不再提供 TapUpdate 模块，改用 Intent |
| 插件架构 | GodotPlugin + .gdap | Godot 4.x 标准 Android 插件方案 |
| 语言 | Kotlin 2.1.0 | 与 godot-lib 4.6.3 编译版本一致 |
| 依赖方式 | Maven 远程依赖 | v4 SDK 通过 Maven Central 分发，不再使用本地 AAR |

## 整体架构

```
┌──────────────────────────────────────────────────────┐
│                    GDScript 层                        │
│  {{PLUGIN_MANAGER_SCRIPT}} (Autoload)                │
│  ├── 检测平台 → Android 用原生插件 / PC 用模拟       │
│  ├── init_sdk() / login() / logout()                 │
│  ├── init_anti_addiction() / check_anti_addiction()  │
│  ├── init_cloud_save() / save_to_cloud()             │
│  ├── init_leaderboard() / submit_leaderboard_score() │
│  └── 信号: login_success / anti_addiction_callback / │
│          cloud_save_result / cloud_save_list / ...   │
├──────────────────────────────────────────────────────┤
│                  Kotlin 原生插件层                     │
│  {{PLUGIN_NAME}}.kt (extends GodotPlugin)            │
│  ├── @UsedByGodot 标注暴露给 GDScript 的方法         │
│  ├── initSDK() → TapTapSdk.init()                    │
│  ├── login() → TapTapLogin.loginWithScopes()         │
│  ├── checkAntiAddiction() → TapTapCompliance.startup()│
│  ├── saveToCloud() → TapTapCloudSave.createArchive() │
│  └── 通过 safeEmit() 回调 GDScript（线程安全）       │
├──────────────────────────────────────────────────────┤
│                    TapSDK v4 层                       │
│  com.taptap.sdk:tap-core:4.10.2                      │
│  com.taptap.sdk:tap-login:4.10.2                     │
│  com.taptap.sdk:tap-compliance:4.10.2                │
│  com.taptap.sdk:tap-cloudsave:4.10.2                 │
└──────────────────────────────────────────────────────┘
```

## 阶段规划

| 阶段 | 优先级 | 内容 | 状态 |
| ---- | ------ | ---- | ---- |
| P0 | 高 | TapTap 登录 + 隐私弹窗 + GDScript 封装 | ✅ 完成 |
| P1 | 高 | 防沉迷查询 + 版本更新检测 | ✅ 完成 |
| P2 | 高 | 云存档（上传/下载/冲突处理）+ 数据分析 | ✅ 完成 |
| P3 | 中 | 成就系统 + 排行榜 | 待实现 |
| P4 | 低 | 内嵌动态 + 好友 + 礼包 | 待实现 |

## 文件规划

```
项目根目录/
├── android/
│   ├── plugins/                    # Godot 4.x Android 插件目录
│   │   ├── {{PLUGIN_NAME}}.gdap   # 插件描述文件（声明 remote 依赖）
│   │   └── {{PLUGIN_AAR_FILENAME}} # 编译后的插件 AAR
│   └── build/                      # Godot Android 构建模板
├── android_plugin/                 # 插件源码项目（独立 Gradle 工程）
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── java/.../{{PLUGIN_NAME}}.kt
│   │   │   ├── AndroidManifest.xml
│   │   │   └── resources/META-INF/services/org.godotengine.godot.plugin.GodotPlugin
│   │   ├── libs/                   # 编译依赖（compileOnly）
│   │   │   └── godot-lib.4.6.3.stable.template_release.aar
│   │   └── build.gradle
│   └── ...
├── scripts/
│   ├── autoload/
│   │   └── {{PLUGIN_MANAGER_SCRIPT}} # Autoload 封装层
│   └── ui/
│       ├── main_menu.gd           # 主菜单（集成登录/防沉迷/云存档流程）
│       ├── privacy_popup.gd       # 隐私政策弹窗
│       └── cloud_save_conflict_popup.gd # 云存档冲突弹窗
└── scenes/
    ├── main_menu.tscn
    ├── privacy_popup.tscn
    └── cloud_save_conflict_popup.tscn
```

## 阶段一：Android 插件开发

### 1.1 创建 Gradle 工程

```groovy
// android_plugin/app/build.gradle
buildscript {
    repositories { google(); mavenCentral() }
    dependencies {
        classpath "com.android.tools.build:gradle:8.1.0"
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
    }
}
plugins { id 'com.android.library' }
apply plugin: 'org.jetbrains.kotlin.android'

android {
    namespace '{{PACKAGE_NAME}}'
    compileSdk 34
    buildToolsVersion "34.0.0"
    defaultConfig { minSdk 24; targetSdk 34 }
    kotlinOptions {
        jvmTarget = '17'
        freeCompilerArgs += ['-Xskip-metadata-version-check']
    }
}
dependencies {
    compileOnly files("libs/godot-lib.4.6.3.stable.template_release.aar")
    compileOnly 'com.taptap.sdk:tap-core:4.10.2'
    compileOnly 'com.taptap.sdk:tap-login:4.10.2'
    compileOnly 'com.taptap.sdk:tap-compliance:4.10.2'
    compileOnly 'com.taptap.sdk:tap-cloudsave:4.10.2'
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
}
```

**v4 关键变化：** SDK 不再使用本地 AAR，改为 Maven 远程依赖。`compileOnly` 声明，运行时由 Godot 构建系统通过 `.gdap` 的 `remote` 依赖下载打包。

### 1.2 编写 Kotlin 插件类

```kotlin
class {{PLUGIN_NAME}}(godot: Godot) : GodotPlugin(godot) {
    override fun getPluginName(): String = "{{PLUGIN_NAME}}"

    override fun getPluginSignals(): MutableSet<SignalInfo> {
        return mutableSetOf(
            SignalInfo("on_login_success", String::class.java),
            SignalInfo("on_login_failed", String::class.java),
            SignalInfo("on_login_canceled"),
            SignalInfo("on_logout_finished"),
            SignalInfo("on_anti_addiction_callback", String::class.java, String::class.java),
            SignalInfo("on_cloud_save_result", String::class.java, String::class.java),
            SignalInfo("on_cloud_save_list", String::class.java),
            SignalInfo("on_cloud_save_data", String::class.java),
        )
    }

    @UsedByGodot
    fun initSDK(clientId: String, clientToken: String, serverUrl: String) {
        val activity = activity ?: return
        val sdkOptions = TapTapSdkOptions(clientId, clientToken, TapTapRegion.CN, "", true)
        val complianceOptions = TapTapComplianceOptions(true, false)
        TapTapSdk.init(activity, sdkOptions, complianceOptions)
    }

    @UsedByGodot
    fun login() {
        val activity = activity ?: return
        val scopes = arrayOf(Scopes.SCOPE_PUBLIC_PROFILE)
        TapTapLogin.loginWithScopes(activity, scopes, object : TapTapCallback<TapTapAccount> {
            override fun onSuccess(account: TapTapAccount) {
                val json = JSONObject().apply {
                    put("name", account.name ?: "")
                    put("avatar", account.avatar ?: "")
                    put("user_id", account.openId ?: "")
                    put("openid", account.openId ?: "")
                    put("unionid", account.unionId ?: "")
                }
                safeEmit("on_login_success", json.toString())
            }
            override fun onCancel() { safeEmit("on_login_canceled") }
            override fun onFail(exception: TapTapException) {
                safeEmit("on_login_failed", exception.message ?: "Unknown error")
            }
        })
    }

    @UsedByGodot
    fun checkAntiAddiction() {
        val userId = TapTapLogin.getCurrentTapAccount()?.openId ?: ""
        TapTapCompliance.startup(activity, userId)
    }

    @UsedByGodot
    fun saveToCloud(saveData: String, summary: String) {
        val metadata = ArchiveMetadata.Builder()
            .setName("save").setSummary(summary).setExtra("").setPlaytime(0).build()
        val saveFile = File(activity.cacheDir, "cloud_save.json")
        saveFile.writeText(saveData)
        TapTapCloudSave.createArchive(metadata, saveFile.absolutePath, null, callback)
    }
}
```

**v4 关键变化：**
- 初始化：`TapTapSdk.init()` 统一初始化，不再需要各模块单独 init
- 登录：`TapTapLogin.loginWithScopes()` 直接回调，不再需要 `registerLoginCallback()`
- 账号信息：`TapTapAccount` 直接包含 `name`/`avatar`/`openId`/`unionId`，不再需要 `getCurrentProfile()`
- 防沉迷：`TapTapCompliance` 替代 `AntiAddictionUIKit`，回调 code 一致
- 云存档：`TapTapCloudSave` 是 v4 新增模块

### 1.3 线程安全：safeEmit 模式

**关键问题：** SDK 回调在后台线程执行，`emitSignal()` 必须在主线程调用，否则会崩溃。

```kotlin
private val mainHandler = Handler(Looper.getMainLooper())

private fun safeEmit(signalName: String, vararg args: Any) {
    if (Looper.myLooper() == Looper.getMainLooper()) {
        emitSignal(signalName, *args)
    } else {
        mainHandler.post { emitSignal(signalName, *args) }
    }
}
```

### 1.4 信号类型匹配

**关键问题：** Kotlin `Int` 在 vararg 中无法匹配 Godot 的 `Int::class.java`，会导致 `IllegalArgumentException`。

**解决方案：** 信号声明和 emitSignal 统一使用 `String` 类型传递数值参数：

```kotlin
SignalInfo("on_anti_addiction_callback", String::class.java, String::class.java)
// ...
safeEmit("on_anti_addiction_callback", code.toString(), msg)
```

GDScript 侧对应：
```gdscript
signal anti_addiction_callback(code: String, message: String)
func _on_anti_addiction_callback(code: String, message: String) -> void:
    match code:
        "500": _enter_bookshelf.call_deferred()
        "1000", "1001": ToastManager.show_toast(tr("请重新登录"))
```

### 1.5 配置 AndroidManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application>
        <meta-data
            android:name="org.godotengine.plugin.v2.{{PLUGIN_NAME}}"
            android:value="{{PACKAGE_NAME}}.{{PLUGIN_NAME}}"/>
    </application>
</manifest>
```

### 1.6 配置 ServiceLoader

创建文件 `src/main/resources/META-INF/services/org.godotengine.godot.plugin.GodotPlugin`：

```
{{PACKAGE_NAME}}.{{PLUGIN_NAME}}
```

### 1.7 构建与部署

```bash
$env:JAVA_HOME = "{{JAVA_HOME_PATH}}"
cd android_plugin
.\gradlew.bat assembleRelease
Copy-Item app\build\outputs\aar\app-release.aar ..\android\plugins\{{PLUGIN_AAR_FILENAME}}
```

### 1.8 创建 .gdap 描述文件

```ini
[config]
name="{{PLUGIN_NAME}}"
binary_type="local"
binary="res://android/plugins/{{PLUGIN_AAR_FILENAME}}"

[dependencies]
remote=["com.taptap.sdk:tap-core:4.10.2", "com.taptap.sdk:tap-login:4.10.2", "com.taptap.sdk:tap-compliance:4.10.2", "com.taptap.sdk:tap-cloudsave:4.10.2"]
```

**v4 关键变化：** 不再使用 `local=[]` 列出本地 AAR，改为 `remote=[]` 声明 Maven 依赖，Godot 构建时自动下载。

## 阶段二：GDScript 封装层

### 2.1 {{PLUGIN_MANAGER_NAME}} (Autoload)

```gdscript
extends Node

signal login_success(user_info: Dictionary)
signal login_failed(error: String)
signal login_canceled
signal logout_finished
signal sdk_initialized
signal anti_addiction_callback(code: String, message: String)
signal cloud_save_result(action: String, data: String)
signal cloud_save_list(archives_json: String)
signal cloud_save_data(save_json: String)

var _plugin: Object = null
var _is_logged_in: bool = false
var _is_sdk_initialized: bool = false
var _mock_mode: bool = false
const PLUGIN_NAME: String = "{{PLUGIN_NAME}}"

func _ready() -> void:
    if OS.get_name() == "Android" and Engine.has_singleton(PLUGIN_NAME):
        _plugin = Engine.get_singleton(PLUGIN_NAME)
        _connect_plugin_signals()
    elif OS.get_name() != "Android":
        _mock_mode = true

func is_available() -> bool:
    return _plugin != null or _mock_mode

func init_sdk(client_id, client_token, server_url) -> void:
    if _mock_mode: _is_sdk_initialized = true; sdk_initialized.emit(); return
    if not _plugin: return
    _plugin.initSDK(client_id, client_token, server_url)
    _is_sdk_initialized = true
    sdk_initialized.emit()

func init_anti_addiction(client_id) -> void:
    if _plugin: _plugin.initAntiAddiction(client_id)

func init_cloud_save() -> void:
    if _plugin: _plugin.initCloudSave()

func save_to_cloud(save_data: String, summary: String) -> void:
    if _plugin: _plugin.saveToCloud(save_data, summary)

func load_cloud_save_list() -> void:
    if _plugin: _plugin.loadCloudSaveList()

func load_cloud_save_data(archive_id: String, file_id: String) -> void:
    if _plugin: _plugin.loadCloudSaveData(archive_id, file_id)
```

### 2.2 注册为 Autoload

在 `project.godot` 中：

```ini
[autoload]
{{PLUGIN_MANAGER_NAME}}="*res://scripts/autoload/{{PLUGIN_MANAGER_SCRIPT}}"
```

## 阶段三：UI 集成

### 3.1 主菜单登录流程

```
启动 → 加载进度条（登录按钮和开始按钮都隐藏）
  ↓
加载完成 → 初始化 TapSDK（含防沉迷、云存档）
  ↓
┌─ TapTap 可用 + 未授权 → 显示 "TapTap 登录" 按钮
│     ↓ 点击登录
│   登录成功 → 防沉迷校验
│     ↓ code=500（通过）
│   查询云存档列表
│     ├─ 云端有更新存档 → 自动恢复 → 进入书架
│     ├─ 云端与本地冲突 → 弹窗让玩家选择 → 进入书架
│     └─ 无云存档 → 直接进入书架
├─ TapTap 可用 + 已授权 → 显示 "开始游戏" 按钮
│     ↓ 点击开始
│   防沉迷校验 → 进入书架（同上云存档恢复流程）
└─ TapTap 不可用 → 显示 "开始游戏" 按钮
```

### 3.2 云存档自动上传

在 `GameManager.save_game()` 末尾添加云存档上传（带 3 秒防抖）：

```gdscript
func save_game() -> void:
    var data = {
        "version": 7,
        "save_time": Time.get_datetime_string_from_system(),
        # ... 其他字段
    }
    # 本地保存
    var file = FileAccess.open(_save_path, FileAccess.WRITE)
    if file: file.store_string(JSON.stringify(data, "\t")); file.close()
    # 云存档上传（防抖 3 秒）
    _upload_cloud_save()
```

**防抖原因：** `save_game()` 可能被快速连续调用多次，TapSDK 不允许同一存档 UUID 并发上传（错误码 400007）。

### 3.3 云存档冲突弹窗

当本地存档和云存档内容不同时，弹出冲突弹窗让玩家选择：

```
┌──────────────────────────┐
│         存档冲突          │
│                          │
│ 检测到本地存档与云存档   │
│ 不一致，请选择：         │
│                          │
│ 本地存档：已完成 5 个数织│
│ 2026-05-27 14:30:00      │
│                          │
│ 云存档：已完成 3 个数织  │
│ 2026-05-27 10:00:00      │
│                          │
│ [使用本地存档] [使用云存档]│
└──────────────────────────┘
```

冲突判断逻辑：
- 内容完全相同 → 不弹窗，直接进入
- 云端进度更多 → 自动恢复云端存档
- 内容不同且两边都有进度 → 弹窗让玩家选择

### 3.4 设置弹窗显示用户 ID

TapTap 登录成功后，在设置弹窗底部居中显示灰色用户 ID。

## 排行榜接入

### 概述

接入 TapSDK v4 排行榜模块，将游戏内已有的排行榜系统与 TapTap 排行榜数据对接。排行榜 ID：`691qntuadkntr8vq1o`（全球排行）。

### 分数设计

- **分数类型**：已完成关卡数量（`completed_puzzles.size()`）
- **排序方式**：分数越高排名越前（DESC）
- **提交时机**：完成关卡后 5 秒防抖提交（避免连续完成多关时频繁提交）

### 依赖配置

**build.gradle** 新增：
```groovy
compileOnly 'com.taptap.sdk:tap-leaderboard-androidx:4.10.2'
```

**.gdap** 新增：
```ini
remote=[..., "com.taptap.sdk:tap-leaderboard-androidx:4.10.2"]
```

### Kotlin 插件层

新增方法：
- `initLeaderboard()` — 注册排行榜事件回调
- `submitLeaderboardScore(leaderboardId, score)` — 提交分数
- `loadLeaderboardScores(leaderboardId, collection, page)` — 获取排行榜数据
- `loadCurrentUserScore(leaderboardId, collection)` — 获取当前用户排名

新增信号：
- `on_leaderboard_result(String, String)` — 排行榜事件（code, message）
- `on_leaderboard_scores(String)` — 排行榜数据（JSON）
- `on_leaderboard_user_score(String)` — 当前用户排名（JSON）

关键 API（经 javap 确认）：
```kotlin
TapTapLeaderboard.registerLeaderboardCallback(callback)
TapTapLeaderboard.submitScores(List<ScoreItem>, callback)
TapTapLeaderboard.loadLeaderboardScores(id, collection, page, null, callback)
TapTapLeaderboard.loadCurrentPlayerLeaderboardScore(id, collection, null, callback)
```

### GDScript 封装层

`tap_tap_manager.gd` 新增：
```gdscript
signal leaderboard_result(code: String, message: String)
signal leaderboard_scores(scores_json: String)
signal leaderboard_user_score(score_json: String)

func init_leaderboard() -> void
func submit_leaderboard_score(leaderboard_id: String, score: int) -> void
func load_leaderboard_scores(leaderboard_id: String, collection: String, page: String) -> void
func load_current_user_score(leaderboard_id: String, collection: String) -> void
```

### 排行榜数据对接

`leaderboard_data.gd` 修改：
- 全球排行和好友排行优先从 TapTap 获取真实数据
- TapTap 数据不可用时回退到 mock 数据
- 数据格式转换：TapTap Score → 排行榜条目 Dictionary
- 分数显示：整数分数直接显示数量，小数分数按时间格式（mm:ss）

`rank_row.gd` 修改：
- 支持 `score_display` 字段（TapTap 返回的格式化分数）
- 整数分数（如已完成关卡数）直接显示，不再格式化为时间

`game_manager.gd` 修改：
- `complete_puzzle()` 末尾调用 `_submit_leaderboard_score()`
- 5 秒防抖 Timer，避免连续完成多关时频繁提交

### 注意事项

1. 排行榜模块不需要在 `TapTapSdk.init()` 中添加 Options，只需注册回调
2. `LeaderboardCollection.PUBLIC` = 全球榜，`LeaderboardCollection.FRIENDS` = 好友榜
3. 排行榜依赖 TapTap 登录，未登录时回调会收到 code=500102
4. 排行榜默认「仅白名单可见」，需在开发者中心添加测试用户
5. `ScoreItem(leaderboardId, score)` 的 score 是 Long 类型

## 踩坑记录

### 坑1：Kotlin 版本不匹配

**现象：** `incompatible version of Kotlin` 编译错误

**解决：** 升级 `kotlin-gradle-plugin` 到 2.1.0，添加 `freeCompilerArgs += ['-Xskip-metadata-version-check']`

### 坑2：SDK 回调在后台线程导致崩溃

**现象：** 登录成功后闪退，logcat 显示 `emitSignal` 在非主线程调用

**解决：** 使用 `Handler(Looper.getMainLooper()).post` 包裹 `emitSignal`，封装为 `safeEmit()`

### 坑3：emitSignal 类型不匹配

**现象：** `IllegalArgumentException: Invalid type for argument #0. Should be of type int`

**原因：** Kotlin `Int` 在 vararg 中无法匹配 Godot 的 `Int::class.java`

**解决：** 信号声明和 emitSignal 统一使用 `String` 类型，GDScript 侧也用 String 接收

### 坑4：SDK 回调参数为 null 导致 NPE

**现象：** `NullPointerException: Parameter specified as non-null is null: parameter extras`

**原因：** Kotlin 可空类型与 Java 接口不匹配，SDK 回调的 `extras` 参数可能为 null

**解决：** 将 `extras: MutableMap<String, Any>` 改为 `extras: MutableMap<String, Any>?`，访问时用 `extras?.get()`

### 坑5：AAR 缺少插件注册文件

**现象：** `Engine.has_singleton()` 返回 false

**解决：** 确保三重注册：`.gdap` + `AndroidManifest.xml <meta-data>` + `META-INF/services/` ServiceLoader

### 坑6：云存档并发上传被拒绝

**现象：** `code=400007 msg=更新存档失败: concurrent CloudSave upload operations for the same UUID disallowed`

**原因：** `save_game()` 被快速连续调用，触发多次并发上传

**解决：** 添加 3 秒防抖 Timer，多次保存只触发一次上传

### 坑7：v4 SDK API 与文档不完全一致

**现象：** 编译错误，如 `ArchiveMetadata` 构造函数是 internal 的

**解决：** 使用 `javap -public -cp xxx.jar ClassName` 反编译确认实际 API 签名，不要完全依赖文档

### 坑8：v3 → v4 迁移注意事项

| v3 API | v4 API | 变化 |
| ------ | ------ | ---- |
| `TapLoginHelper.init()` + `startTapLogin()` | `TapTapSdk.init()` + `TapTapLogin.loginWithScopes()` | 统一初始化，直接回调 |
| `TapLoginHelper.getCurrentProfile()` | `TapTapLogin.getCurrentTapAccount()` | 账号信息直接在 account 上 |
| `AntiAddictionUIKit.init()` + `startupWithTapTap()` | `TapTapCompliance.registerComplianceCallback()` + `startup()` | 模块名和 API 变更 |
| `TapUpdate.init()` + `updateGame()` | Intent 跳转 TapTap 客户端 | v4 不再提供 TapUpdate 模块 |
| 本地 AAR 依赖 | Maven 远程依赖 | `.gdap` 中 `local=[]` → `remote=[...]` |
| 无 | `TapTapCloudSave` | v4 新增云存档模块 |

## 签名 MD5 配置

在 TapTap 开发者中心需要配置应用签名 MD5：

| 签名类型 | MD5 |
| -------- | --- |
| Debug | {{DEBUG_SIGN_MD5}} |
| Release | {{RELEASE_SIGN_MD5}} |

提取命令：
```powershell
keytool -list -v -keystore xxx.keystore -alias xxx -storepass xxx
```

## 防沉迷回调码

| code | 常量 | 含义 |
| ---- | ---- | ---- |
| 500 | LOGIN_SUCCESS | 玩家未受限制，正常进入游戏 |
| 1000 | EXITED | 退出防沉迷认证，应返回登录页 |
| 1001 | SWITCH_ACCOUNT | 用户点击切换账号，应返回登录页 |
| 1030 | PERIOD_RESTRICT | 当前时间无法游戏 |
| 1050 | DURATION_LIMIT | 今日游戏时长已用完 |
| 1100 | AGE_LIMIT | 年龄限制无法进入 |
| 1200 | INVALID_CLIENT_OR_NETWORK_ERROR | 网络错误 |
| 9002 | REAL_NAME_STOP | 实名过程中关闭了窗口 |

## 待完成事项

- [x] 填写 TapSDK 凭证
- [x] 实现防沉迷功能
- [x] 实现版本更新检测
- [x] 实现云存档功能
- [x] 云存档冲突弹窗
- [x] 接入排行榜（P3）
- [ ] 在 TapTap 开发者中心配置 Release 签名 MD5
- [ ] 接入成就系统（P3）

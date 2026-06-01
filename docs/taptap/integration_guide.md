# Godot 4.x 接入 TapTap — 完整流程文档

## 概述

本文档记录了在 Godot 4.6 项目（数织艺术 / NonogramArt）中接入 TapTap 全功能（登录、防沉迷、更新、云存档、排行榜）的完整流程，包括方案规划、Android 插件开发、GDScript 封装、UI 集成、构建部署及踩坑记录。

## 技术选型

| 项目 | 选择 | 说明 |
| ---- | ---- | ---- |
| 引擎 | Godot 4.6.3 | 使用 Gradle 构建模式导出 Android |
| SDK | TapSDK v4.10.2 | TapTap 官方 Android SDK（v4 统一初始化架构） |
| 登录模式 | TapTapLogin.loginWithScopes | v4 统一登录 API，支持 scope 授权 |
| 防沉迷 | TapTapCompliance | v4 合规认证模块，替代 v3 的 AntiAddictionUIKit |
| 云存档 | TapTapCloudSave | v4 新增模块，支持创建/更新/下载/删除存档 |
| 排行榜 | TapTapLeaderboard | v4 排行榜模块（tap-leaderboard-androidx），支持提交分数/获取排名/好友榜 |
| 更新唤起 | Intent 跳转 TapTap 客户端 | v4 不再提供 TapUpdate 模块，改用 Intent |
| 插件架构 | GodotPlugin + .gdap | Godot 4.x 标准 Android 插件方案 |
| 语言 | Kotlin 2.1.0 | 与 godot-lib 4.6.3 编译版本一致 |
| 依赖方式 | Maven 远程依赖 | v4 SDK 通过 Maven Central 分发，不再使用本地 AAR |

## 整体架构

```
┌──────────────────────────────────────────────────────┐
│                    GDScript 层                        │
│  tap_tap_manager.gd (Autoload: TapTapManager)        │
│  ├── 检测平台 → Android 用原生插件 / PC 用模拟       │
│  ├── init_sdk() / login() / logout()                 │
│  ├── init_anti_addiction() / check_anti_addiction()  │
│  ├── init_cloud_save() / save_to_cloud()             │
│  ├── init_leaderboard() / submit_leaderboard_score() │
│  ├── check_login_state() / sdk_api_ready 信号        │
│  └── 信号: login_success / anti_addiction_callback / │
│          cloud_save_result / cloud_save_list / ...   │
├──────────────────────────────────────────────────────┤
│                  Kotlin 原生插件层                     │
│  TapTapPlugin.kt (extends GodotPlugin)               │
│  ├── @UsedByGodot 标注暴露给 GDScript 的方法         │
│  ├── initSDK() → TapTapSdk.init()                    │
│  ├── login() → TapTapLogin.loginWithScopes()         │
│  ├── checkAntiAddiction() → TapTapCompliance.startup()│
│  ├── saveToCloud() → TapTapCloudSave.createArchive() │
│  ├── submitLeaderboardScore() → TapTapLeaderboard    │
│  ├── 日志系统: logAndEmit / writeLogFile              │
│  ├── 崩溃捕获: setupCrashHandler / logcat            │
│  └── 通过 safeEmit() 回调 GDScript（线程安全）       │
├──────────────────────────────────────────────────────┤
│                    TapSDK v4 层                       │
│  com.taptap.sdk:tap-core:4.10.2                      │
│  com.taptap.sdk:tap-login:4.10.2                     │
│  com.taptap.sdk:tap-compliance:4.10.2                │
│  com.taptap.sdk:tap-cloudsave:4.10.2                 │
│  com.taptap.sdk:tap-leaderboard-androidx:4.10.2      │
└──────────────────────────────────────────────────────┘
```

## 阶段规划

| 阶段 | 优先级 | 内容 | 状态 |
| ---- | ------ | ---- | ---- |
| P0 | 高 | TapTap 登录 + 隐私弹窗 + GDScript 封装 | ✅ 完成 |
| P1 | 高 | 防沉迷查询 + 版本更新检测 | ✅ 完成 |
| P2 | 高 | 云存档（上传/下载/冲突处理）+ 数据分析 | ✅ 完成 |
| P3 | 中 | 排行榜 | ✅ 完成 |
| P3 | 中 | Dirichlet Ad SDK 激励视频广告 | ✅ 完成 |
| P3 | 中 | 成就系统 | 待实现 |
| P4 | 低 | 内嵌动态 + 好友 + 礼包 | 待实现 |

## 文件规划

```
项目根目录/
├── android/
│   ├── plugins/                          # Godot 4.x Android 插件目录
│   │   ├── TapTapPlugin.gdap            # 插件描述文件（声明 remote 依赖）
│   │   ├── taptap_plugin.aar            # 编译后的插件 AAR（含 TapTapPlugin + AdPlugin）
│   │   ├── AdPlugin.gdap               # 广告插件描述文件
│   │   └── dirichlet_ad_4.2.5.0.aar    # Dirichlet Ad SDK AAR
│   └── build/                            # Godot Android 构建模板
├── android_plugin/                       # 插件源码项目（独立 Gradle 工程）
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── java/com/reallycsc/nonogramart/taptap/TapTapPlugin.kt
│   │   │   ├── java/com/reallycsc/nonogramart/ad/AdPlugin.kt
│   │   │   ├── AndroidManifest.xml
│   │   │   └── resources/META-INF/services/org.godotengine.godot.plugin.GodotPlugin
│   │   ├── libs/                         # 编译依赖（compileOnly）
│   │   │   └── godot-lib.4.6.3.stable.template_release.aar
│   │   ├── proguard-rules.pro           # ProGuard 混淆规则
│   │   └── build.gradle
│   ├── build.gradle
│   ├── settings.gradle
│   └── gradle.properties
├── scripts/
│   ├── autoload/
│   │   ├── tap_tap_manager.gd           # Autoload 封装层（TapTapManager）
│   │   └── ad_manager.gd               # 广告封装层（AdManager）
│   └── ui/
│       ├── main_menu.gd                 # 主菜单（集成登录/防沉迷/云存档流程）
│       ├── privacy_popup.gd             # 隐私政策弹窗
│       └── cloud_save_conflict_popup.gd # 云存档冲突弹窗
└── scenes/
    ├── main_menu.tscn
    ├── privacy_popup.tscn
    └── cloud_save_conflict_popup.tscn
```

## 阶段一：Android 插件开发

### 1.1 创建 Gradle 工程

**根 build.gradle** (`android_plugin/build.gradle`)：

```groovy
buildscript {
    ext.kotlin_version = '2.1.0'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.1.0"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        flatDir {
            dirs 'libs'
        }
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
```

**app/build.gradle** (`android_plugin/app/build.gradle`)：

```groovy
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.1.0"
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
    }
}

plugins {
    id 'com.android.library'
}

apply plugin: 'org.jetbrains.kotlin.android'

android {
    namespace 'com.reallycsc.nonogramart.taptap'
    compileSdk 34
    buildToolsVersion "34.0.0"

    defaultConfig {
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
        freeCompilerArgs += ['-Xskip-metadata-version-check']
    }
}

configurations.all {
    resolutionStrategy {
        force 'org.jetbrains.kotlin:kotlin-stdlib:2.1.0'
        force 'org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.0'
    }
}

dependencies {
    compileOnly files("libs/godot-lib.4.6.3.stable.template_release.aar")
    compileOnly 'com.taptap.sdk:tap-core:4.10.2'
    compileOnly 'com.taptap.sdk:tap-login:4.10.2'
    compileOnly 'com.taptap.sdk:tap-compliance:4.10.2'
    compileOnly 'com.taptap.sdk:tap-cloudsave:4.10.2'
    compileOnly 'com.taptap.sdk:tap-leaderboard-androidx:4.10.2'
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
}
```

**settings.gradle** (`android_plugin/settings.gradle`)：

```groovy
rootProject.name = "TapTapPlugin"
include ':app'
```

**gradle.properties** (`android_plugin/gradle.properties`)：

```properties
android.useAndroidX=true
org.gradle.jvmargs=-Xmx2048m
```

**v4 关键变化：** SDK 不再使用本地 AAR，改为 Maven 远程依赖。`compileOnly` 声明，运行时由 Godot 构建系统通过 `.gdap` 的 `remote` 依赖下载打包。

> **注意：** `libs/` 目录中仍保留 v3 旧版 AAR 文件（TapUpdate_3.30.3.aar、AntiAddictionUI_3.30.3.aar 等），这些是迁移前的遗留文件，当前构建未使用，可安全删除。

### 1.2 编写 Kotlin 插件类

```kotlin
package com.reallycsc.nonogramart.taptap

import android.os.Handler
import android.os.Looper
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONObject
// ... 其他 import 省略，见实际源码

class TapTapPlugin(godot: Godot) : GodotPlugin(godot) {

    companion object {
        private const val TAG = "TapTapPlugin"
    }

    private var isInitialized = false
    private var complianceInitialized = false
    private val mainHandler = Handler(Looper.getMainLooper())
    private var currentArchiveId: String? = null

    override fun getPluginName(): String = "TapTapPlugin"

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
            SignalInfo("on_leaderboard_result", String::class.java, String::class.java),
            SignalInfo("on_leaderboard_scores", String::class.java),
            SignalInfo("on_leaderboard_user_score", String::class.java),
            SignalInfo("on_log", String::class.java),
        )
    }

    @UsedByGodot
    fun initSDK(clientId: String, clientToken: String, serverUrl: String) {
        val activity = activity ?: return
        setupCrashHandler()
        try {
            val sdkOptions = TapTapSdkOptions(clientId, clientToken, TapTapRegion.CN, "", true)
            val complianceOptions = TapTapComplianceOptions(true, false)
            TapTapSdk.init(activity, sdkOptions, complianceOptions)
            isInitialized = true
        } catch (e: Exception) {
            logAndEmit("TapSDK v4 init FAILED: ${e.message}")
        }
    }

    @UsedByGodot
    fun login() { /* TapTapLogin.loginWithScopes() */ }

    @UsedByGodot
    fun logout() { /* TapTapLogin.logout() */ }

    @UsedByGodot
    fun initAntiAddiction(clientId: String) { /* TapTapCompliance.registerComplianceCallback() */ }

    @UsedByGodot
    fun checkAntiAddiction() { /* TapTapCompliance.startup() */ }

    @UsedByGodot
    fun exitAntiAddiction() { /* TapTapCompliance.exit() */ }

    @UsedByGodot
    fun checkUpdate() { /* Intent 跳转 TapTap 客户端 */ }

    @UsedByGodot
    fun initCloudSave() { /* TapTapCloudSave.registerCloudSaveCallback() */ }

    @UsedByGodot
    fun setCurrentArchiveId(archiveId: String) { currentArchiveId = if (archiveId.isEmpty()) null else archiveId }

    @UsedByGodot
    fun saveToCloud(saveData: String, summary: String) { /* TapTapCloudSave.createArchive/updateArchive */ }

    @UsedByGodot
    fun loadCloudSaveList() { /* TapTapCloudSave.getArchiveList() */ }

    @UsedByGodot
    fun loadCloudSaveData(archiveId: String, fileId: String) { /* TapTapCloudSave.getArchiveData() */ }

    @UsedByGodot
    fun deleteCloudSave(archiveId: String) { /* TapTapCloudSave.deleteArchive() */ }

    @UsedByGodot
    fun getCurrentUserId(): String { /* TapTapLogin.getCurrentTapAccount()?.openId */ }

    @UsedByGodot
    fun isUserLoggedIn(): Boolean { /* TapTapLogin.getCurrentTapAccount() != null */ }

    @UsedByGodot
    fun getDisplayUserId(): String { /* 同 getCurrentUserId() */ }

    @UsedByGodot
    fun initLeaderboard() { /* TapTapLeaderboard.registerLeaderboardCallback() */ }

    @UsedByGodot
    fun submitLeaderboardScore(leaderboardId: String, score: Long) { /* TapTapLeaderboard.submitScores() */ }

    @UsedByGodot
    fun loadLeaderboardScores(leaderboardId: String, collection: String, page: String) { /* TapTapLeaderboard.loadLeaderboardScores() */ }

    @UsedByGodot
    fun loadCurrentUserScore(leaderboardId: String, collection: String) { /* TapTapLeaderboard.loadCurrentPlayerLeaderboardScore() */ }
}
```

**v4 关键变化：**
- 初始化：`TapTapSdk.init()` 统一初始化，不再需要各模块单独 init
- 登录：`TapTapLogin.loginWithScopes()` 直接回调，不再需要 `registerLoginCallback()`
- 账号信息：`TapTapAccount` 直接包含 `name`/`avatar`/`openId`/`unionId`，不再需要 `getCurrentProfile()`
- 防沉迷：`TapTapCompliance` 替代 `AntiAddictionUIKit`，回调 code 一致
- 云存档：`TapTapCloudSave` 是 v4 新增模块
- 排行榜：`TapTapLeaderboard`（`tap-leaderboard-androidx`）是 v4 排行榜模块

**实际插件额外功能（相比基础模板）：**
- **日志系统**：`logAndEmit()` 同时写 Logcat、本地文件和 GDScript 信号
- **崩溃捕获**：`setupCrashHandler()` 捕获未处理异常并写入文件，`startLogcatCapture()` 持续记录 logcat
- **archiveId 管理**：`currentArchiveId` 跟踪当前云存档 ID，避免重复创建
- **登录状态检查**：`isUserLoggedIn()` / `getCurrentUserId()` / `getDisplayUserId()`
- **防沉迷退出**：`exitAntiAddiction()` 调用 `TapTapCompliance.exit()`
- **云存档删除**：`deleteCloudSave()` 调用 `TapTapCloudSave.deleteArchive()`
- **云存档智能创建/更新**：`saveToCloud()` 先查询已有存档列表，有则更新，无则创建

### 1.3 线程安全：safeEmit 模式

**关键问题：** SDK 回调在后台线程执行，`emitSignal()` 必须在主线程调用，否则会崩溃。

```kotlin
private fun safeEmit(signalName: String, vararg args: Any) {
    try {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            try {
                emitSignal(signalName, *args)
            } catch (e: Exception) {
                Log.e(TAG, "emitSignal failed: $signalName", e)
            }
        } else {
            mainHandler.post {
                try {
                    emitSignal(signalName, *args)
                } catch (e: Exception) {
                    Log.e(TAG, "emitSignal failed: $signalName", e)
                }
            }
        }
    } catch (e: Exception) {
        Log.e(TAG, "safeEmit failed: $signalName", e)
    }
}
```

**注意：** 实际实现中 safeEmit 包含双层 try-catch，防止 emitSignal 本身抛出异常导致崩溃。

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
            android:name="org.godotengine.plugin.v2.TapTapPlugin"
            android:value="com.reallycsc.nonogramart.taptap.TapTapPlugin"/>
    </application>
</manifest>
```

### 1.6 配置 ServiceLoader

创建文件 `src/main/resources/META-INF/services/org.godotengine.godot.plugin.GodotPlugin`：

```
com.reallycsc.nonogramart.taptap.TapTapPlugin
```

### 1.7 配置 ProGuard 混淆规则

`app/proguard-rules.pro`：

```
-keep class com.tds.** { *; }
-keep class com.taptap.** { *; }
-keep class com.tapsdk.** { *; }
-keep class tds.androidx.** { *; }
```

**说明：** TapSDK 的类名混淆后会导致反射调用失败，必须 keep 住 `com.tds`、`com.taptap`、`com.tapsdk` 和 `tds.androidx` 包下的所有类。当前 `buildTypes.release` 中 `minifyEnabled` 设为 `false`，但保留 ProGuard 规则以备后续启用混淆时使用。

### 1.8 构建与部署

```powershell
$env:JAVA_HOME = "E:\Program Files\Android\Android Studio\jbr"  # JDK 17+
cd android_plugin
.\gradlew.bat assembleRelease
Copy-Item app\build\outputs\aar\app-release.aar ..\android\plugins\TapTapPlugin.aar
```

### 1.9 创建 .gdap 描述文件

在 `android/plugins/` 目录创建 `TapTapPlugin.gdap`：

```ini
[config]
name="TapTapPlugin"
binary_type="local"
binary="res://android/plugins/TapTapPlugin.aar"

[dependencies]
remote=["com.taptap.sdk:tap-core:4.10.2", "com.taptap.sdk:tap-login:4.10.2", "com.taptap.sdk:tap-compliance:4.10.2", "com.taptap.sdk:tap-cloudsave:4.10.2", "com.taptap.sdk:tap-leaderboard-androidx:4.10.2"]
```

**v4 关键变化：** 不再使用 `local=[]` 列出本地 AAR，改为 `remote=[]` 声明 Maven 依赖，Godot 构建时自动下载。

> **注意：** 排行榜模块的 Maven 依赖名是 `tap-leaderboard-androidx`（带 `-androidx` 后缀），不是 `tap-leaderboard`。

## 阶段二：GDScript 封装层

### 2.1 TapTapManager (Autoload)

```gdscript
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
var _mock_mode: bool = false

const PLUGIN_NAME: String = "TapTapPlugin"

func _ready() -> void:
    if OS.get_name() == "Android" and Engine.has_singleton(PLUGIN_NAME):
        _plugin = Engine.get_singleton(PLUGIN_NAME)
        _connect_plugin_signals()
    elif OS.get_name() != "Android":
        _mock_mode = true

func is_available() -> bool:
    return _plugin != null or _mock_mode

func is_mock_mode() -> bool:
    return _mock_mode

func init_sdk(client_id: String, client_token: String, server_url: String) -> void:
    if _mock_mode:
        _is_sdk_initialized = true
        sdk_initialized.emit()
        return
    if not _plugin: return
    _plugin.initSDK(client_id, client_token, server_url)
    _is_sdk_initialized = true
    sdk_initialized.emit()

func login() -> void:
    if _mock_mode:
        get_tree().create_timer(1.0).timeout.connect(_mock_login_success)
        return
    if not _plugin or not _is_sdk_initialized: return
    _plugin.login()

func logout() -> void:
    if _mock_mode:
        _is_logged_in = false
        _user_info = {}
        logout_finished.emit()
        return
    if not _plugin or not _is_logged_in: return
    _plugin.logout()

func check_login_state() -> bool:
    # 检查 SDK 登录状态是否过期
    # 使用 isUserLoggedIn() 或 getCurrentUserId() 判断
    # 10 秒内刚登录的跳过检查
    ...

func init_anti_addiction(client_id: String) -> void:
    if _plugin: _plugin.initAntiAddiction(client_id)

func check_anti_addiction() -> void:
    if _plugin and _is_sdk_initialized: _plugin.checkAntiAddiction()

func init_cloud_save() -> void:
    if not _plugin: return
    _plugin.initCloudSave()
    if not _current_archive_id.is_empty() and _plugin.has_method("setCurrentArchiveId"):
        _plugin.setCurrentArchiveId(_current_archive_id)

func save_to_cloud(save_data: String, summary: String) -> void:
    if not _plugin or not _sdk_api_ready: return
    _plugin.saveToCloud(save_data, summary)

func load_cloud_save_list() -> void:
    if not _plugin or not _sdk_api_ready: return
    _plugin.loadCloudSaveList()

func load_cloud_save_data(archive_id: String, file_id: String) -> void:
    if _plugin: _plugin.loadCloudSaveData(archive_id, file_id)

func delete_cloud_save(archive_id: String) -> void:
    if _plugin: _plugin.deleteCloudSave(archive_id)

func init_leaderboard() -> void:
    if _plugin: _plugin.initLeaderboard()

func submit_leaderboard_score(leaderboard_id: String, score: int) -> void:
    if not _plugin or not _sdk_api_ready: return
    _plugin.submitLeaderboardScore(leaderboard_id, score)

func load_leaderboard_scores(leaderboard_id: String, collection: String = "PUBLIC", page: String = "") -> void:
    if not _plugin or not _sdk_api_ready: return
    _plugin.loadLeaderboardScores(leaderboard_id, collection, page)

func load_current_user_score(leaderboard_id: String, collection: String = "PUBLIC") -> void:
    if not _plugin or not _sdk_api_ready: return
    _plugin.loadCurrentUserScore(leaderboard_id, collection)
```

**实际封装层额外功能（相比基础模板）：**
- **sdk_api_ready 机制**：登录成功后 1 秒内 SDK API 可能未就绪，通过 Timer 延迟标记 ready
- **login state 检查**：`check_login_state()` 在应用恢复前台时验证 SDK 登录状态是否过期
- **archiveId 持久化**：云存档 ID 自动写入本地存档文件，下次启动时恢复
- **mock 模式**：所有方法在非 Android 平台都有模拟实现，方便 PC 编辑器测试
- **has_method 安全检查**：调用插件方法前检查方法是否存在，兼容不同版本插件

### 2.2 注册为 Autoload

在 `project.godot` 中：

```ini
[autoload]
TapTapManager="*res://scripts/autoload/tap_tap_manager.gd"
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
        "taptap_archive_id": taptap_archive_id,
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
- `submitLeaderboardScore(leaderboardId, score: Long)` — 提交分数
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
6. Maven 依赖名是 `tap-leaderboard-androidx`（注意 `-androidx` 后缀），不是 `tap-leaderboard`

## 打包导出配置

### export_presets.cfg 关键配置

```ini
[preset.0]
name="Android"
platform="Android"
runnable=true

[preset.0.options]
# Gradle 构建（必须开启，否则插件不会被打包）
gradle_build/use_gradle_build=true
gradle_build/gradle_build_directory=""
gradle_build/compress_native_libraries=false
gradle_build/export_format=0

# 启用 TapTapPlugin
plugins/TapTapPlugin=true

# 架构（仅 arm64-v8a）
architectures/armeabi-v7a=false
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=false

# 包名和签名
version/code=1
version/name="1.0"
package/unique_name="com.reallycsc.nonogramartdebug"
package/name="数织艺术"
package/signed=true

# 权限
permissions/internet=true

# 导出路径
export_path="export/NonogramArt.apk"
```

**关键配置说明：**
- `gradle_build/use_gradle_build=true`：必须开启 Gradle 构建，否则 `.gdap` 声明的远程依赖不会被下载打包
- `plugins/TapTapPlugin=true`：必须在导出预设中勾选插件，否则插件不会被包含在 APK 中
- `package/unique_name`：Debug 包名带 `debug` 后缀，Release 包名不带
- `architectures/arm64-v8a=true`：仅打包 64 位架构

## Dirichlet Ad SDK 接入（激励视频广告）

### 概述

接入 Dirichlet Ad SDK 4.2.5.0（TapADN SDK），实现激励视频广告功能。用户在游戏结束后观看广告可恢复 3 点生命值继续游戏。

### 技术选型

| 项目 | 选择 | 说明 |
| ---- | ---- | ---- |
| SDK | Dirichlet Ad SDK 4.2.5.0 | 上海艾得蒽数字科技有限公司广告平台 |
| 广告类型 | 激励视频（Reward Video Ad） | 用户观看完整视频后获得奖励 |
| 媒体 ID | 1103083 | 在 Dirichlet Ad 平台申请 |
| 广告位 ID | 1057204 | 激励视频广告位 |
| 依赖方式 | 本地 AAR | `dirichlet_ad_4.2.5.0.aar` 放在 `android/plugins/` |
| 插件类 | AdPlugin | 独立的 GodotPlugin，与 TapTapPlugin 共存于同一 AAR |

### 架构设计

```
┌──────────────────────────────────────────────────────┐
│                    GDScript 层                        │
│  ad_manager.gd (Autoload: AdManager)                 │
│  ├── init_ad() → 初始化 SDK                          │
│  ├── load_rewarded_video() → 加载激励视频             │
│  ├── show_rewarded_video() → 展示激励视频             │
│  ├── _auto_show 标志 → 加载后自动展示                 │
│  └── 信号: ad_initialized / rewarded_loaded / ...    │
├──────────────────────────────────────────────────────┤
│                  Kotlin 原生插件层                     │
│  AdPlugin.kt (extends GodotPlugin)                   │
│  ├── initAd() → TapAdManager.get().init()            │
│  ├── loadRewardedVideo() → TapAdNative.loadRewardVideo│
│  ├── showRewardedVideo() → TapRewardVideoAd.show()   │
│  ├── initTapCacheManager() → 反射初始化缓存           │
│  ├── fixSdkInternalContext() → 反射修复 Context       │
│  └── safeEmit() → 线程安全信号发送                    │
├──────────────────────────────────────────────────────┤
│                Dirichlet Ad SDK 层                    │
│  com.tapsdk.tapad.TapAdManager                       │
│  com.tapsdk.tapad.TapAdNative                        │
│  com.tapsdk.tapad.TapRewardVideoAd                   │
│  com.tapsdk.tapad.TapAdConfig                        │
└──────────────────────────────────────────────────────┘
```

### 依赖配置

**android_plugin/app/build.gradle** 新增：
```groovy
compileOnly files("libs/dirichlet_ad_4.2.5.0.aar")
compileOnly 'com.squareup.okhttp3:okhttp:3.12.1'
compileOnly "com.github.bumptech.glide:glide:4.9.0"
```

**android/plugins/AdPlugin.gdap**：
```ini
[config]
name="AdPlugin"
binary_type="local"
binary="res://android/plugins/taptap_plugin.aar"

[dependencies]
local=["res://android/plugins/dirichlet_ad_4.2.5.0.aar"]
```

**说明：**
- AdPlugin 与 TapTapPlugin 共存于同一个 `taptap_plugin.aar`（两个 gdap 指向同一个 binary）
- `dirichlet_ad_4.2.5.0.aar` 是本地 AAR，放在 `android/plugins/` 目录
- Ad SDK 的远程依赖（okhttp、glide 等）已在 TapTapPlugin.gdap 的 remote 中声明

**android/plugins/TapTapPlugin.gdap** 新增依赖：
```ini
[dependencies]
local=["res://android/plugins/dirichlet_ad_4.2.5.0.aar"]
remote=["com.taptap.sdk:tap-core:4.10.2", "com.taptap.sdk:tap-login:4.10.2", ...]
```

**android/build/build.gradle** 硬编码依赖（用于 CLI 构建）：
```groovy
implementation files('H:/Work/MyProject/NonogramArt/android/plugins/taptap_plugin.aar')
implementation files('H:/Work/MyProject/NonogramArt/android/plugins/dirichlet_ad_4.2.5.0.aar')
implementation "com.squareup.okhttp3:okhttp:3.12.1"
implementation "com.github.bumptech.glide:glide:4.9.0"
```

### Kotlin 插件层

#### AdPlugin 类

```kotlin
package com.reallycsc.nonogramart.ad

class AdPlugin(godot: Godot) : GodotPlugin(godot) {
    override fun getPluginName(): String = "AdPlugin"

    override fun getPluginSignals(): MutableSet<SignalInfo> {
        return mutableSetOf(
            SignalInfo("on_ad_initialized", String::class.java),
            SignalInfo("on_rewarded_loaded"),
            SignalInfo("on_rewarded_cached"),
            SignalInfo("on_rewarded_load_failed", String::class.java),
            SignalInfo("on_rewarded_show"),
            SignalInfo("on_rewarded_complete", String::class.java),
            SignalInfo("on_rewarded_skipped"),
            SignalInfo("on_rewarded_close"),
            SignalInfo("on_rewarded_error", String::class.java)
        )
    }

    @UsedByGodot fun initAd(mediaId: String, mediaKey: String)
    @UsedByGodot fun isAdInitialized(): Boolean
    @UsedByGodot fun requestAdPermissions()
    @UsedByGodot fun loadRewardedVideo(spaceId: String)
    @UsedByGodot fun isRewardedVideoLoaded(): Boolean
    @UsedByGodot fun showRewardedVideo()
}
```

#### 初始化流程

```
main_menu.gd: TapTapManager.init_sdk()
  ↓ (TapTapSdk.init() 完成)
main_menu.gd: AdManager.init_ad()
  ↓
AdPlugin.initAd(mediaId, mediaKey)
  ↓ (主线程)
initAdInternal()
  ├── fixSdkInternalContext()  ← 反射修复 SDK 内部 Context
  ├── initTapCacheManager()    ← 反射初始化 TapCacheManager
  ├── TapAdConfig.Builder()
  │   .withMediaId(1103083)
  │   .withMediaName("数织艺术")
  │   .withMediaKey(mediaKey)
  │   .withTapClientId("fictuviuwc34cqheew")
  │   .withCustomController(...)  ← 隐私控制
  │   .build()
  └── TapAdManager.get().init(context, config)
```

**关键：** Ad SDK 初始化必须在 TapTapSdk.init() 之后，因为 `TapCacheManager` 依赖 TapSDK Core 先初始化。

#### 反射修复：initTapCacheManager()

**问题：** `TapAdManager.init()` 内部调用 `TapCacheManager.a()` 检查 `d` 字段是否为 true。如果 `TapCacheManager` 未初始化（`d=false`），抛出 `TapCacheManager not initialized` 异常。

**修复：** 通过反射调用混淆类 `com.tapsdk.tapad.ll` 的 `a()` 获取单例，再调用 `b()` 初始化，将 `d` 设为 true。

```kotlin
private fun initTapCacheManager() {
    try {
        val clazz = Class.forName("com.tapsdk.tapad.ll")
        val getInstance = clazz.getDeclaredMethod("a")
        val instance = getInstance.invoke(null)
        val initMethod = clazz.getDeclaredMethod("b")
        initMethod.invoke(instance)
    } catch (e: Exception) {
        log("initTapCacheManager: failed - ${e.message}")
    }
}
```

#### 反射修复：fixSdkInternalContext()

**问题：** SDK 内部类 `com.tapsdk.tapad.i1` 保存了 `context.getApplicationContext()` 的静态字段 `a`。如果 `getApplicationContext()` 返回 null，后续调用 `context.getCacheDir()` 时 NPE。

**修复：** 通过反射设置 `i1.a` 为有效的 Application Context。

```kotlin
private fun fixSdkInternalContext(context: Context) {
    try {
        val clazz = Class.forName("com.tapsdk.tapad.i1")
        val field = clazz.getDeclaredField("a")
        field.isAccessible = true
        if (field.get(null) == null) {
            field.set(null, context.applicationContext ?: context)
        }
    } catch (e: Exception) {
        log("fixSdkInternalContext: failed - ${e.message}")
    }
}
```

#### 激励视频广告流程

```
游戏结束 → 用户点击广告按钮
  ↓
AdManager.load_rewarded_video()
  ↓ _auto_show = true
AdPlugin.loadRewardedVideo(spaceId)
  ↓ TapAdNative.loadRewardVideoAd()
  ↓ onRewardVideoAdLoad → rewardedAd = ad
  ↓ _auto_show → showRewardVideoAd()
  ↓
AdPlugin.showRewardedVideo()
  ↓ ad.setRewardAdInteractionListener()
  ↓ ad.showRewardVideoAd(activity)
  ↓
onRewardVerify(verifyResult=true)
  ↓ safeEmit("on_rewarded_complete", reward)
  ↓
GDScript: NonogramManager.add_life(3)
          hp_node.reset_game_over()
          game_over_popup.continue_after_ad()
```

### GDScript 封装层

**ad_manager.gd (Autoload: AdManager)**：

```gdscript
const AD_MEDIA_ID: String = "1103083"
const AD_MEDIA_KEY: String = "42mxPgPi2X6xh8JyY0V5NwUOKigEJtQRvF1ALXCrYBDJNgz9SwkCGyrhPsrEafwp"
const AD_REWARDED_SPACE_ID: String = "1057204"

func init_ad(media_id, media_key) -> void:
    _plugin.initAd(media_id, media_key)

func load_rewarded_video(space_id) -> void:
    _auto_show = true
    _plugin.loadRewardedVideo(space_id)

func show_rewarded_video() -> void:
    _plugin.showRewardedVideo()
```

**关键设计：**
- `_auto_show` 标志：加载成功后自动展示，简化调用方逻辑
- `_ready()` 中不自动初始化，等待 TapTapManager 先初始化
- `main_menu.gd` 中在 `TapTapManager.init_friends()` 之后调用 `AdManager.init_ad()`

### 游戏结束广告恢复流程

**nonogram_scene.gd**：
```gdscript
func _on_ad_reward_requested() -> void:
    _ad_reward_handled = false
    AdManager.load_rewarded_video()

func _on_ad_reward_complete(reward_info: String) -> void:
    _ad_reward_handled = true
    NonogramManager.add_life(3)
    hp_node.reset_game_over()
    game_over_popup.continue_after_ad()

func _on_ad_reward_close() -> void:
    if _ad_reward_handled: return
    game_over_popup.show_game_over()
```

**hp_node.gd**：
```gdscript
func reset_game_over() -> void:
    _game_over_emitted = false
    if life_change_audio_player.finished.is_connected(_on_life_audio_finished):
        life_change_audio_player.finished.disconnect(_on_life_audio_finished)
```

### export_presets.cfg 新增

```ini
plugins/AdPlugin=true
```

### 构建流程

**完整构建（GDScript 有变更时）：**
1. Godot 编辑器导出 → 更新 PCK（包含 GDScript 和插件注册信息）
2. `gradlew.bat assembleStandardDebug` → 重新打包 APK（包含最新 Kotlin 代码）

**仅 Kotlin 变更时：**
1. `android_plugin/gradlew.bat assembleRelease` → 编译 AAR
2. 复制 AAR 到 `android/plugins/`
3. `gradlew.bat assembleStandardDebug` → 重新打包 APK

**构建命令模板：**
```powershell
# 1. 构建 AAR
$env:JAVA_HOME = "E:\Program Files\Android\Android Studio\jbr"
& "H:\Work\MyProject\NonogramArt\android_plugin\gradlew.bat" -p "H:\Work\MyProject\NonogramArt\android_plugin" assembleRelease --no-daemon

# 2. 复制 AAR
Copy-Item "H:\Work\MyProject\NonogramArt\android_plugin\app\build\outputs\aar\app-release.aar" "H:\Work\MyProject\NonogramArt\android\plugins\taptap_plugin.aar" -Force

# 3. 构建 APK
$env:ANDROID_HOME = "C:\Users\Administrator\AppData\Local\Android\Sdk"
& "H:\Work\MyProject\NonogramArt\android\build\gradlew.bat" -p "H:\Work\MyProject\NonogramArt\android\build" assembleStandardDebug `
    "-Pexport_package_name=com.reallycsc.nonogramartdebug" `
    "-Pexport_path=H:\Work\MyProject\NonogramArt\export" `
    "-Pexport_filename=NonogramArt.apk" `
    "-Pperform_signing=true" "-PdoNotStrip=true" `
    "-Pcompress_native_libraries=true" `
    "-Pexport_enabled_abis=arm64-v8a" `
    "-Pdebug_keystore_file=C:/Users/Administrator/.android/debug.keystore" `
    "-Pdebug_keystore_password=android" `
    "-Pdebug_keystore_alias=androiddebugkey"

# 4. 安装
Copy-Item "H:\Work\MyProject\NonogramArt\android\build\build\outputs\apk\standard\debug\android_debug.apk" "H:\Work\MyProject\NonogramArt\export\NonogramArt.apk" -Force
& "C:\Users\Administrator\AppData\Local\Android\Sdk\platform-tools\adb.exe" uninstall com.reallycsc.nonogramartdebug
& "C:\Users\Administrator\AppData\Local\Android\Sdk\platform-tools\adb.exe" install -t "H:\Work\MyProject\NonogramArt\export\NonogramArt.apk"
```

### Ad SDK 踩坑记录

#### 坑1：TapCacheManager not initialized

**现象：** `TapAdManager.init()` 抛出 `TapCacheManager not initialized. Call initialize() first.`

**原因：** Dirichlet Ad SDK 的 `TapCacheManager`（混淆类名 `com.tapsdk.tapad.ll`）需要在 `TapAdManager.init()` 之前初始化。`TapCacheManager` 正常由 `TapTapSdk.init()` 初始化，但时序可能不对。

**解决：** 在 `TapAdManager.init()` 之前通过反射调用 `com.tapsdk.tapad.ll.a().b()` 初始化 TapCacheManager。

#### 坑2：SDK 内部 Context 为 null 导致 NPE

**现象：** `Attempt to invoke virtual method 'java.io.File android.content.Context.getCacheDir()' on a null object reference`

**原因：** SDK 内部类 `com.tapsdk.tapad.i1` 的静态字段 `a` 保存了 `context.getApplicationContext()` 的结果。如果 `getApplicationContext()` 返回 null，后续调用 NPE。

**解决：** 通过反射设置 `com.tapsdk.tapad.i1.a` 为有效的 Application Context。

#### 坑3：TapSDK Client ID 不存在

**现象：** 初始化时提示 `TapSDK: Client ID不存在`

**原因：** AdPlugin 中 `ensureTapSdkInitialized()` 硬编码了错误的 TapTap Client ID（`FdGZcLfbQWb1S0nEoOaMjsvwwJq5K1VbQhR2n5q7Y5B`），与项目实际的 Client ID（`fictuviuwc34cqheew`）不一致。

**解决：** 移除 `ensureTapSdkInitialized()`，改为在 `TapAdConfig.Builder()` 中使用 `.withTapClientId("fictuviuwc34cqheew")` 传入正确的 Client ID。Ad SDK 初始化必须在 TapTapPlugin 的 `TapTapSdk.init()` 之后。

#### 坑4：@UsedByGodot 方法不支持 Kotlin 默认参数

**现象：** `SCRIPT ERROR: Invalid call to function 'initAd' in base 'JNISingleton'. Expected 3 argument(s).`

**原因：** Kotlin 的 `@UsedByGodot` 注解不支持默认参数值。`fun initAd(mediaId: String, mediaKey: String, tapClientId: String = "")` 在 Godot 运行时被注册为需要 3 个参数的方法，GDScript 只传 2 个参数导致调用失败。

**解决：** 所有 `@UsedByGodot` 方法的参数数量必须与 GDScript 调用完全一致，不使用默认参数。`tapClientId` 改为在 Kotlin 中硬编码。

#### 坑5：Gradle 直接构建不更新 PCK 中的 GDScript

**现象：** 修改了 `ad_manager.gd` 但 APK 中运行的仍是旧版本 GDScript。

**原因：** Gradle 直接构建只更新 Kotlin 代码（AAR），不会更新 PCK 中的 GDScript。PCK 由 Godot 编辑器导出时生成。

**解决：** GDScript 有变更时必须用 Godot 编辑器导出一次（更新 PCK），然后再用 Gradle 重新构建 APK（更新 Kotlin 代码）。

#### 坑6：广告素材不存在（code=100001）

**现象：** `Reward video ad load failed: code=100001 msg=广告素材不存在`

**原因：** 广告位 `1057204` 在 Dirichlet Ad 平台还没有配置广告素材，或未审核通过，或测试设备不在投放范围内。

**解决：** 在 Dirichlet Ad 开发者后台确认广告位配置和素材状态。

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
| 无 | `TapTapLeaderboard` | v4 排行榜模块（tap-leaderboard-androidx） |
| `TapBootstrap.initActivity()` | `TapTapSdk.init()` | 统一初始化替代各模块单独 init |

## 签名 MD5 配置

在 TapTap 开发者中心需要配置应用签名 MD5：

| 签名类型 | MD5 |
| -------- | --- |
| Debug | （需从 debug keystore 提取） |
| Release | （需从 release keystore 提取） |

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
- [x] 接入 Dirichlet Ad SDK 激励视频广告（P3）
- [ ] 在 Dirichlet Ad 后台配置广告位 1057204 的广告素材
- [ ] 在 TapTap 开发者中心配置 Release 签名 MD5
- [ ] 接入成就系统（P3）
- [ ] 清理 libs/ 目录中 v3 旧版 AAR 文件

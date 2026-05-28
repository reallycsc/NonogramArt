# Godot 4.x Android 原生插件开发 Skill

## 概述

为 Godot 4.x 游戏引擎开发 Android 原生插件，将第三方 Android SDK 封装为 Godot 可用的 GDScript 接口。适用于需要在 Godot 游戏中集成 Android 平台特有功能（如第三方登录、支付、推送、广告等）的场景。

## 核心原理

Godot 4.x Android 插件通过 **三重注册机制** 被引擎发现和加载：

1. **`.gdap` 描述文件** — 告诉 Godot 编辑器插件的存在和二进制位置
2. **`AndroidManifest.xml` 的 `<meta-data>`** — 告诉 Godot 运行时插件名称和初始化类
3. **Java ServiceLoader** — 告诉 JVM 如何加载插件类

**三者缺一不可**，缺少任何一个都会导致 `Engine.has_singleton()` 返回 `false`。

## 插件开发标准流程

### Step 1：创建 Android Library 项目

```
android_plugin/
├── app/
│   ├── src/main/
│   │   ├── java/com/example/plugin/MyPlugin.kt
│   │   ├── AndroidManifest.xml
│   │   └── resources/META-INF/services/org.godotengine.godot.plugin.GodotPlugin
│   ├── libs/
│   │   └── godot-lib.X.X.X.stable.template_release.aar
│   └── build.gradle
├── build.gradle
├── settings.gradle
└── gradle.properties
```

### Step 2：编写 build.gradle

```groovy
buildscript {
    repositories { google(); mavenCentral() }
    dependencies {
        classpath "com.android.tools.build:gradle:8.1.0"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0"  // 必须与 godot-lib 编译版本一致
    }
}
plugins { id 'com.android.library' }
apply plugin: 'org.jetbrains.kotlin.android'

android {
    namespace 'com.example.plugin'
    compileSdk 34
    buildToolsVersion "34.0.0"    // 必须与已安装的 SDK 版本一致
    defaultConfig { minSdk 24; targetSdk 34 }
    kotlinOptions {
        jvmTarget = '17'
        freeCompilerArgs += ['-Xskip-metadata-version-check']  // 关键：跳过 Kotlin 元数据版本检查
    }
}
dependencies {
    compileOnly files("libs/godot-lib.X.X.X.stable.template_release.aar")  // compileOnly，不打包进 AAR
    // 第三方 SDK 也用 compileOnly，通过 .gdap 的 [dependencies] 声明
    // Maven 远程依赖示例：
    // compileOnly 'com.taptap.sdk:tap-core:4.10.2'
    // compileOnly 'com.taptap.sdk:tap-login:4.10.2'
}
```

**关键配置：**
- `kotlin-gradle-plugin` 版本必须与 `godot-lib` 编译时使用的 Kotlin 版本一致
- `-Xskip-metadata-version-check` 避免 Kotlin 元数据版本不匹配的 daemon 连接失败
- `godot-lib` 使用 `compileOnly`，运行时由 Godot 引擎提供
- 第三方 SDK AAR 也使用 `compileOnly`，通过 `.gdap` 的 `[dependencies]` 声明让 Godot 构建系统打包

### Step 3：编写 Kotlin 插件类

```kotlin
package com.example.plugin

import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class MyPlugin(godot: Godot) : GodotPlugin(godot) {
    override fun getPluginName(): String = "MyPlugin"  // 必须与 .gdap 和 meta-data 中的名称一致

    override fun getPluginSignals(): MutableSet<SignalInfo> {
        return mutableSetOf(
            SignalInfo("on_success", String::class.java),
            SignalInfo("on_error", String::class.java),
        )
    }

    @UsedByGodot  // 必须标注，否则 GDScript 无法调用
    fun doSomething(param: String) {
        val activity = activity ?: return
        activity.runOnUiThread {
            // UI 操作必须在主线程
            try {
                // 调用第三方 SDK
                emitSignal("on_success", "result")
            } catch (e: Exception) {
                emitSignal("on_error", e.message ?: "Unknown error")
            }
        }
    }
}
```

**规则：**
- `getPluginName()` 返回值 = `.gdap` 中 `name` = `AndroidManifest` 中 `org.godotengine.plugin.v2.` 后的名称
- 暴露给 GDScript 的方法必须标注 `@UsedByGodot`
- 需要在 GDScript 中接收的回调必须通过 `getPluginSignals()` 声明信号
- UI 操作必须在 `activity.runOnUiThread` 中执行
- 通过 `emitSignal()` 向 GDScript 发送事件
- **SDK 回调中必须使用 `safeEmit()`** 而非直接 `emitSignal()`，因为回调在后台线程执行
- **信号参数统一使用 `String` 类型**，避免 Kotlin Int 与 Godot Int::class.java 不匹配

### Step 4：配置 AndroidManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <meta-data
            android:name="org.godotengine.plugin.v2.MyPlugin"
            android:value="com.example.plugin.MyPlugin"/>
    </application>
</manifest>
```

**格式：**
- `android:name` = `org.godotengine.plugin.v2.` + 插件名
- `android:value` = 插件类的全限定名

### Step 5：配置 ServiceLoader

创建文件 `src/main/resources/META-INF/services/org.godotengine.godot.plugin.GodotPlugin`：

```
com.example.plugin.MyPlugin
```

内容为插件类的全限定名，每行一个（多插件时）。

### Step 6：构建 AAR

```bash
$env:JAVA_HOME = "E:\Program Files\Android\Android Studio\jbr"  # 或其他 JDK 17+
cd android_plugin
.\gradlew.bat assembleRelease
```

输出：`app/build/outputs/aar/app-release.aar`

### Step 7：部署到 Godot 项目

将以下文件放入 `android/plugins/` 目录：

```
android/plugins/
├── MyPlugin.gdap              # 插件描述文件
├── my_plugin.aar              # 编译后的插件 AAR
├── third_party_sdk.aar        # 第三方 SDK 依赖（如有）
└── ...
```

### Step 8：创建 .gdap 描述文件

```ini
[config]
name="MyPlugin"
binary_type="local"
binary="res://android/plugins/my_plugin.aar"

[dependencies]
local=["res://android/plugins/third_party_sdk.aar"]
remote=[]
```

- `name` 必须与 Kotlin `getPluginName()` 一致
- `binary_type="local"` 表示使用本地 AAR 文件
- `local` 列出第三方 SDK 的 AAR 路径
- `remote` 列出 Maven 仓库依赖（如 `"com.taptap.sdk:tap-core:4.10.2"`），Godot 构建时自动下载
- 使用 Maven 远程依赖时，`local` 可为空，SDK 不需要手动下载 AAR

### Step 9：GDScript 封装层

```gdscript
extends Node

signal success(result: String)
signal error(msg: String)

var _plugin: Object = null
var _mock_mode: bool = false

const PLUGIN_NAME: String = "MyPlugin"

func _ready() -> void:
    if OS.get_name() == "Android" and Engine.has_singleton(PLUGIN_NAME):
        _plugin = Engine.get_singleton(PLUGIN_NAME)
        _plugin.on_success.connect(_on_success)
        _plugin.on_error.connect(_on_error)
    elif OS.get_name() != "Android":
        _mock_mode = true

func is_available() -> bool:
    return _plugin != null or _mock_mode

func do_something(param: String) -> void:
    if _mock_mode:
        success.emit("mock_result")
        return
    if _plugin:
        _plugin.doSomething(param)

func _on_success(result: String) -> void:
    success.emit(result)

func _on_error(msg: String) -> void:
    error.emit(msg)
```

**设计模式：**
- Autoload 单例，全局可访问
- `_mock_mode` 在非 Android 平台启用，方便 PC 编辑器测试
- 信号转发：将原生插件信号转为 GDScript 信号，上层不直接依赖原生接口
- `is_available()` 统一判断可用性

### Step 10：导出配置

在 Godot 编辑器中：
1. 项目 → 导出 → Android 预设 → 勾选 **Use Gradle Build**
2. 在 **Plugins** 标签中勾选插件
3. 导出 APK

对应的 `export_presets.cfg`：
```ini
gradle_build/use_gradle_build=true
gradle_build/gradle_build_directory=""
plugins/MyPlugin=true
```

## 验证清单

构建 AAR 后，用 ZIP 工具检查 AAR 内容：

```
AAR 根目录/
├── AndroidManifest.xml          ← 必须包含 meta-data
├── classes.jar                  ← 必须包含：
│   ├── com/example/plugin/MyPlugin.class
│   └── META-INF/services/org.godotengine.godot.plugin.GodotPlugin
└── ...
```

**验证命令（PowerShell）：**
```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead("path/to/plugin.aar")
$zip.Entries | ForEach-Object { $_.FullName }
$zip.Dispose()
```

**必须确认：**
- [ ] `AndroidManifest.xml` 包含 `org.godotengine.plugin.v2.XXX` 的 meta-data
- [ ] `classes.jar` 内包含 `META-INF/services/org.godotengine.godot.plugin.GodotPlugin`
- [ ] `classes.jar` 内包含插件类的 `.class` 文件
- [ ] `.gdap` 文件中 `name` 与 `getPluginName()` 一致
- [ ] `android/plugins/` 目录包含 `.gdap`、插件 AAR 和所有依赖 AAR

## 常见问题速查

| 现象 | 原因 | 解决 |
| ---- | ---- | ---- |
| `Engine.has_singleton()` 返回 false | 缺少 meta-data 或 ServiceLoader | 检查 AndroidManifest 和 META-INF/services |
| `incompatible version of Kotlin` | Kotlin 版本与 godot-lib 不一致 | 升级 kotlin-gradle-plugin，添加 -Xskip-metadata-version-check |
| `This class does not have a constructor` | 接口当类实例化 | object : Interface { 不带括号 |
| 导出报 'android_build' 不是命令 | gradle_build_directory 配置错误 | 设为空字符串使用默认路径 |
| AAR 中没有 ServiceLoader 文件 | resources 目录未被打包 | 确认路径：src/main/resources/META-INF/services/ |
| AAR 中没有 meta-data | AndroidManifest 未包含 application 块 | 添加 `<application><meta-data .../></application>` |
| 插件方法在 GDScript 中不可见 | 忘记 @UsedByGodot 标注 | 给暴露的方法添加 @UsedByGodot |
| 信号在 GDScript 中连接失败 | 忘记在 getPluginSignals() 中声明 | 添加 SignalInfo 声明 |
| SDK 回调后闪退 | emitSignal 在后台线程调用 | 使用 safeEmit() 切换到主线程 |
| `IllegalArgumentException: Invalid type for argument` | Kotlin Int 无法匹配 Godot Int::class.java | 信号统一使用 String 类型传递数值 |
| `NullPointerException` on SDK 回调参数 | Kotlin 可空类型与 Java 接口不匹配 | 参数加 `?` 可空修饰符 |
| 云存档并发上传被拒绝 (400007) | 同一 UUID 并发上传 | 添加防抖 Timer（3 秒） |
| SDK API 编译错误但文档说可以 | v4 SDK 文档与实际 API 不一致 | 用 javap 反编译确认实际签名 |
| 排行榜回调收到 500102 | 用户未登录 | 引导用户先登录 TapTap |
| `tap-leaderboard` 找不到 | Maven 依赖名不对 | 使用 `tap-leaderboard-androidx`（带 -androidx 后缀） |

## 第三方 SDK 集成模式

### compileOnly vs implementation

| 依赖类型 | build.gradle 中 | .gdap 中 | 说明 |
| -------- | --------------- | -------- | ---- |
| godot-lib | compileOnly | 不需要 | 运行时由引擎提供 |
| 第三方 SDK AAR | compileOnly | local=[...] | 通过 .gdap 声明，Godot 构建时打包 |
| Maven 远程依赖 | compileOnly | remote=[...] | Godot 构建时从 Maven 下载并打包 |
| AndroidX 等 | implementation | 不需要 | 自动合并到 AAR 的 classes.jar |

**Maven 远程依赖详解（以 TapSDK v4 为例）：**

当第三方 SDK 通过 Maven Central 分发时，不再需要下载本地 AAR 文件：

1. `build.gradle` 中用 `compileOnly` 声明（编译时需要，不打包进插件 AAR）：
```groovy
dependencies {
    compileOnly 'com.taptap.sdk:tap-core:4.10.2'
    compileOnly 'com.taptap.sdk:tap-login:4.10.2'
}
```

2. `.gdap` 中用 `remote` 声明（Godot 构建时自动下载并打包到 APK）：
```ini
[dependencies]
remote=["com.taptap.sdk:tap-core:4.10.2", "com.taptap.sdk:tap-login:4.10.2"]
```

3. 不再需要在 `android/plugins/` 目录放置 SDK 的 AAR 文件

**优势：** SDK 版本升级只需修改版本号，无需手动下载替换 AAR 文件。

### 检查 AAR 内部类名

```powershell
# 解压 AAR 中的 classes.jar 并列出内容
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead("xxx.aar")
$classesEntry = $zip.GetEntry("classes.jar")
$tempJar = [System.IO.Path]::GetTempFileName()
$stream = $classesEntry.Open()
$fs = [System.IO.File]::Create($tempJar)
$stream.CopyTo($fs); $fs.Close(); $stream.Close(); $zip.Dispose()
$jarZip = [System.IO.Compression.ZipFile]::OpenRead($tempJar)
$jarZip.Entries | ForEach-Object { $_.FullName }
$jarZip.Dispose(); Remove-Item $tempJar -Force
```

## TapTap SDK v4 集成专项

本节记录在 Godot 4.x Android 插件中集成 TapSDK v4 的关键模式和踩坑经验。

### v4 统一初始化架构

v4 不再需要各模块单独初始化，而是通过 `TapTapSdk.init()` 一次性初始化所有模块：

```kotlin
val sdkOptions = TapTapSdkOptions(clientId, clientToken, TapTapRegion.CN, "", true)
val complianceOptions = TapTapComplianceOptions(true, false)
TapTapSdk.init(activity, sdkOptions, complianceOptions)
```

**要点：**
- `TapTapSdkOptions` 构造函数参数顺序需用 javap 确认，文档可能不准确
- 各模块的 Options 作为 `vararg options` 传入，按需添加
- 初始化一次即可，登录、防沉迷、云存档等模块自动就绪

### 登录 API

```kotlin
TapTapLogin.loginWithScopes(activity, scopes, object : TapTapCallback<TapTapAccount> {
    override fun onSuccess(account: TapTapAccount) {
        // v4: 账号信息直接在 account 上，不再需要 getCurrentProfile()
        val name = account.name       // 可能为 null
        val avatar = account.avatar   // 可能为 null
        val openId = account.openId   // 可能为 null
        val unionId = account.unionId // 可能为 null
    }
    override fun onCancel() { /* 用户取消 */ }
    override fun onFail(exception: TapTapException) { /* 失败 */ }
})
```

**v3 → v4 变化：**
- `TapLoginHelper.startTapLogin()` → `TapTapLogin.loginWithScopes()`
- 不再需要 `registerLoginCallback()`，直接在调用时传入回调
- `TapLoginHelper.getCurrentProfile()` → `TapTapLogin.getCurrentTapAccount()`
- 账号信息从 `profile.name` → `account.name`（无中间 profile 对象）

### 防沉迷 API

```kotlin
// 注册回调（只需一次）
TapTapCompliance.registerComplianceCallback(object : TapTapComplianceCallback {
    override fun onResult(code: Int, extras: MutableMap<String, Any>?) {
        // 注意：extras 可能为 null，必须加 ?
        safeEmit("on_anti_addiction_callback", code.toString(), extras?.get("msg")?.toString() ?: "")
    }
})

// 启动防沉迷检查
val userId = TapTapLogin.getCurrentTapAccount()?.openId ?: ""
TapTapCompliance.startup(activity, userId)
```

**v3 → v4 变化：**
- `AntiAddictionUIKit` → `TapTapCompliance`
- `startupWithTapTap()` → `startup(activity, userId)`
- 回调码不变：500(通过)/1000(退出)/1001(切换)/1030/1050/1100/1200/9002

### 云存档 API

v4 新增模块，支持创建/更新/下载/删除存档：

```kotlin
// 创建存档
val metadata = ArchiveMetadata.Builder()
    .setName("save")
    .setSummary(summary)
    .setExtra("")
    .setPlaytime(0)
    .build()
TapTapCloudSave.createArchive(metadata, filePath, null, requestCallback)

// 更新存档（需要 archiveId）
TapTapCloudSave.updateArchive(archiveId, metadata, filePath, null, requestCallback)

// 获取存档列表
TapTapCloudSave.getArchiveList(requestCallback)

// 下载存档数据
TapTapCloudSave.getArchiveData(archiveId, fileId, requestCallback)

// 删除存档
TapTapCloudSave.deleteArchive(archiveId, requestCallback)
```

**关键注意：**
- `ArchiveMetadata` 构造函数是 `internal` 的，必须使用 `Builder` 模式
- `TapCloudSaveRequestCallback` 需实现所有方法（onRequestError/onArchiveCreated/onArchiveUpdated/onArchiveDeleted/onArchiveListResult/onArchiveDataResult/onArchiveCoverResult）
- `onArchiveListResult` 参数类型是 `List<ArchiveData>`（不是 `MutableList`）
- 首次创建后保存 `archiveId`，后续更新使用 `updateArchive` 而非 `createArchive`
- 同一 UUID 不允许并发上传（错误码 400007），需防抖

### safeEmit 线程安全模式

**问题：** SDK 回调在后台线程执行，`emitSignal()` 必须在主线程调用，否则崩溃。

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

**使用方式：** 所有 SDK 回调中的 `emitSignal` 都替换为 `safeEmit`。

### 信号类型匹配

**问题：** Kotlin `Int` 在 vararg 中无法匹配 Godot 的 `Int::class.java`，导致 `IllegalArgumentException`。

**解决：** 信号声明和 emitSignal 统一使用 `String` 类型：

```kotlin
// Kotlin 侧
SignalInfo("on_anti_addiction_callback", String::class.java, String::class.java)
safeEmit("on_anti_addiction_callback", code.toString(), msg)

// GDScript 侧
signal anti_addiction_callback(code: String, message: String)
func _on_anti_addiction_callback(code: String, message: String) -> void:
    match code:
        "500": _enter_bookshelf.call_deferred()
        "1000", "1001": ToastManager.show_toast(tr("请重新登录"))
```

### javap 反编译确认 API

v4 SDK 文档与实际 API 可能不一致，遇到编译错误时用 javap 确认：

```powershell
# 1. 找到 Maven 缓存中的 SDK JAR
$jarPath = "$env:USERPROFILE\.gradle\caches\modules-2\files-2.1\com.taptap.sdk\tap-cloudsave\4.10.2\*\*.jar"

# 2. 列出类的 public 方法
javap -public -cp $jarPath com.taptap.cloudsave.api.ArchiveMetadata
javap -public -cp $jarPath com.taptap.cloudsave.TapTapCloudSave
javap -public -cp $jarPath com.taptap.sdk.core.options.TapTapSdkOptions
```

**典型发现：**
- `ArchiveMetadata` 构造函数是 `internal` 的 → 必须用 `Builder`
- `TapTapSdkOptions` 构造函数参数顺序与文档不同
- `TapTapAccount` 直接包含 `name`/`avatar`，不是嵌套在 `userInfo` 中

### 云存档防抖模式

**问题：** `save_game()` 可能被快速连续调用，触发并发上传（错误码 400007）。

```gdscript
var _cloud_save_timer: Timer = null

func _upload_cloud_save() -> void:
    if not TapTapManager.is_available(): return
    if not TapTapManager._is_logged_in: return
    if _cloud_save_timer == null:
        _cloud_save_timer = Timer.new()
        _cloud_save_timer.one_shot = true
        _cloud_save_timer.timeout.connect(_do_cloud_upload)
        add_child(_cloud_save_timer)
    _cloud_save_timer.start(3.0)

func _do_cloud_upload() -> void:
    var file = FileAccess.open(_save_path, FileAccess.READ)
    if not file: return
    var save_data = file.get_as_text()
    file.close()
    TapTapManager.save_to_cloud(save_data, "auto save")
```

### 排行榜 API

v4 排行榜模块（`tap-leaderboard-androidx`），支持提交分数、获取排行数据：

```kotlin
// 注册事件回调（初始化时调用一次）
TapTapLeaderboard.registerLeaderboardCallback(object : TapTapLeaderboardCallback {
    override fun onLeaderboardResult(code: Int, message: String) {
        // code=500102: 用户未登录
    }
})

// 提交分数
val scoreItem = SubmitScoresRequest.ScoreItem(leaderboardId, score)
TapTapLeaderboard.submitScores(listOf(scoreItem), object : ITapTapLeaderboardResponseCallback<SubmitScoresResponse> {
    override fun onSuccess(result: SubmitScoresResponse) { /* 成功 */ }
    override fun onFailure(code: Int, message: String) { /* 失败 */ }
})

// 获取排行榜数据
TapTapLeaderboard.loadLeaderboardScores(
    leaderboardId,
    LeaderboardCollection.PUBLIC,  // 或 FRIENDS
    page,  // 翻页 token，首次传 ""
    null,  // 内部参数，传 null
    object : ITapTapLeaderboardResponseCallback<LeaderboardScoresResponse> {
        override fun onSuccess(result: LeaderboardScoresResponse) {
            // result.leaderboard: Leaderboard (id, name)
            // result.scores: List<Score> (rank, score, scoreDisplay, user)
            // result.nextPage: String (翻页 token)
        }
        override fun onFailure(code: Int, message: String) { /* 失败 */ }
    }
)

// 获取当前用户排名
TapTapLeaderboard.loadCurrentPlayerLeaderboardScore(
    leaderboardId,
    LeaderboardCollection.PUBLIC,
    null,
    object : ITapTapLeaderboardResponseCallback<UserScoreResponse> {
        override fun onSuccess(result: UserScoreResponse) {
            // result.currentUserScore: Score?
        }
        override fun onFailure(code: Int, message: String) { /* 失败 */ }
    }
)
```

**关键注意：**
- 排行榜模块不需要在 `TapTapSdk.init()` 中添加 Options
- Maven 依赖是 `tap-leaderboard-androidx`（注意 `-androidx` 后缀），不是 `tap-leaderboard`
- `ScoreItem` 是 `SubmitScoresRequest` 的内部类：`SubmitScoresRequest.ScoreItem(leaderboardId, score)`
- `submitScores` 第一个参数是 `List<ScoreItem>`，不是 `SubmitScoresRequest`
- `Score.user` 类型是 `Score.User`（内部类），有 `name`/`openid`/`avatar`（`avatar` 是 `Image` 类型，用 `url` 获取 URL）
- `LeaderboardScoresResponse.leaderboard` 可能为 null

### 云存档冲突检测

**原则：** 只在实际内容不同时才弹冲突弹窗，内容相同时静默通过。

```gdscript
func compare_with_cloud_save(cloud_json: String) -> Dictionary:
    if _is_same_content(cloud_json):
        return {"conflict": false}
    var cloud_data = JSON.parse_string(cloud_json)
    var cloud_time = str(cloud_data.get("save_time", ""))
    var local_time = _read_local_save_time()
    return {
        "conflict": true,
        "cloud_newer": cloud_time > local_time,
        "local_info": {"puzzle_count": _count_local_puzzles(), "save_time": local_time},
        "cloud_info": {"puzzle_count": _count_cloud_puzzles(cloud_data), "save_time": cloud_time},
    }

func _is_same_content(cloud_json: String) -> bool:
    var local_file = FileAccess.open(_save_path, FileAccess.READ)
    if not local_file: return false
    var local_data = JSON.parse_string(local_file.get_as_text())
    local_file.close()
    var cloud_data = JSON.parse_string(cloud_json)
    for key in ["completed_puzzles", "completed_pictures", "completed_albums", "album_progress"]:
        if JSON.stringify(local_data.get(key, {})) != JSON.stringify(cloud_data.get(key, {})):
            return false
    return true
```

### v3 → v4 迁移速查

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

## PC 模拟测试模式

在 GDScript 封装层实现 `_mock_mode`，使 UI 流程可以在 PC 编辑器中完整测试：

```gdscript
func _ready() -> void:
    if OS.get_name() == "Android" and Engine.has_singleton(PLUGIN_NAME):
        _plugin = Engine.get_singleton(PLUGIN_NAME)
    elif OS.get_name() != "Android":
        _mock_mode = true

func is_available() -> bool:
    return _plugin != null or _mock_mode

func some_method() -> void:
    if _mock_mode:
        get_tree().create_timer(1.0).timeout.connect(func():
            success.emit("mock_result")
        )
        return
    if _plugin:
        _plugin.someMethod()
```

**云存档 mock 模式示例：**

```gdscript
func save_to_cloud(save_data: String, summary: String) -> void:
    if _mock_mode:
        get_tree().create_timer(0.5).timeout.connect(func():
            cloud_save_result.emit("created", "mock_archive_id")
        )
        return
    if _plugin: _plugin.saveToCloud(save_data, summary)

func load_cloud_save_list() -> void:
    if _mock_mode:
        get_tree().create_timer(0.5).timeout.connect(func():
            cloud_save_list.emit("[]")
        )
        return
    if _plugin: _plugin.loadCloudSaveList()
```

**好处：**
- 在 PC 编辑器中按 F5 即可测试完整 UI 流程
- 不需要每次都打包 APK
- 模拟模式下按钮显示 `[MOCK]` 标记，方便区分
- 云存档 mock 返回空列表，不会干扰本地存档

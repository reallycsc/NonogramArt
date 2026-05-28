package com.reallycsc.nonogramart.taptap

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.os.Handler
import android.os.Looper
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONObject
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

import com.taptap.sdk.core.TapTapSdk
import com.taptap.sdk.core.TapTapSdkOptions
import com.taptap.sdk.core.TapTapRegion
import com.taptap.sdk.login.TapTapLogin
import com.taptap.sdk.login.TapTapAccount
import com.taptap.sdk.login.Scopes
import com.taptap.sdk.kit.internal.callback.TapTapCallback
import com.taptap.sdk.kit.internal.exception.TapTapException
import com.taptap.sdk.compliance.TapTapCompliance
import com.taptap.sdk.compliance.TapTapComplianceCallback
import com.taptap.sdk.compliance.constants.ComplianceMessage
import com.taptap.sdk.compliance.option.TapTapComplianceOptions
import com.taptap.sdk.cloudsave.TapTapCloudSave
import com.taptap.sdk.cloudsave.internal.TapCloudSaveRequestCallback
import com.taptap.sdk.cloudsave.internal.TapCloudSaveCallback
import com.taptap.sdk.cloudsave.ArchiveMetadata
import com.taptap.sdk.cloudsave.ArchiveData

import com.taptap.sdk.leaderboard.androidx.TapTapLeaderboard
import com.taptap.sdk.leaderboard.callback.TapTapLeaderboardCallback
import com.taptap.sdk.leaderboard.callback.ITapTapLeaderboardResponseCallback
import com.taptap.sdk.leaderboard.data.request.LeaderboardCollection
import com.taptap.sdk.leaderboard.data.request.SubmitScoresRequest
import com.taptap.sdk.leaderboard.data.response.LeaderboardScoresResponse
import com.taptap.sdk.leaderboard.data.response.UserScoreResponse
import com.taptap.sdk.leaderboard.data.response.SubmitScoresResponse
import com.taptap.sdk.leaderboard.data.response.common.Score

class TapTapPlugin(godot: Godot) : GodotPlugin(godot) {

    companion object {
        private const val TAG = "TapTapPlugin"
    }

    private var isInitialized = false
    private var complianceInitialized = false
    private val mainHandler = Handler(Looper.getMainLooper())
    private var defaultExceptionHandler: Thread.UncaughtExceptionHandler? = null
    private var logcatProcess: Process? = null
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

    private fun logAndEmit(message: String) {
        Log.i(TAG, message)
        writeLogFile(message)
        safeEmit("on_log", message)
    }

    private fun getLogDir(): File? {
        val act = activity ?: return null
        val base = act.getExternalFilesDir(null) ?: return null
        val dir = File(base, "taptap_logs")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    private fun writeLogFile(message: String) {
        try {
            val dir = getLogDir() ?: return
            val file = File(dir, "debug.log")
            val timestamp = SimpleDateFormat("HH:mm:ss.SSS", Locale.US).format(Date())
            file.appendText("$timestamp $message\n")
        } catch (_: Exception) {}
    }

    private fun setupCrashHandler() {
        checkPreviousCrashLog()
        startLogcatCapture()
        defaultExceptionHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            val sw = StringWriter()
            sw.append("=== CRASH ===\n")
            sw.append("Thread: ${thread.name}\n")
            sw.append("Exception: ${throwable.javaClass.name}\n")
            sw.append("Message: ${throwable.message}\n")
            sw.append("Stack:\n")
            throwable.printStackTrace(PrintWriter(sw))
            var cause = throwable.cause
            while (cause != null) {
                sw.append("Caused by: ${cause.javaClass.name}: ${cause.message}\n")
                cause.printStackTrace(PrintWriter(sw))
                cause = cause.cause
            }
            val crashInfo = sw.toString()
            Log.e(TAG, crashInfo)
            try {
                val dir = getLogDir()
                if (dir != null) {
                    val ts = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
                    File(dir, "crash_$ts.log").writeText(crashInfo)
                }
            } catch (_: Exception) {}
            stopLogcatCapture()
            defaultExceptionHandler?.uncaughtException(thread, throwable)
        }
    }

    private fun startLogcatCapture() {
        try {
            val dir = getLogDir() ?: return
            val logFile = File(dir, "logcat.txt")
            if (logFile.exists()) logFile.delete()
            logcatProcess = Runtime.getRuntime().exec(
                arrayOf("logcat", "-v", "time", "*:V")
            )
            Thread {
                try {
                    val reader = BufferedReader(InputStreamReader(logcatProcess?.inputStream))
                    val writer = logFile.bufferedWriter()
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        writer.write(line)
                        writer.newLine()
                        writer.flush()
                    }
                    writer.close()
                } catch (_: Exception) {}
            }.start()
            logAndEmit("Logcat capture started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start logcat capture", e)
        }
    }

    private fun stopLogcatCapture() {
        try {
            logcatProcess?.destroy()
            logcatProcess = null
        } catch (_: Exception) {}
    }

    private fun checkPreviousCrashLog() {
        try {
            val dir = getLogDir() ?: return
            val crashFiles = dir.listFiles { f -> f.name.startsWith("crash_") }
            if (crashFiles != null && crashFiles.isNotEmpty()) {
                for (f in crashFiles) {
                    logAndEmit("PREVIOUS CRASH FOUND: ${f.name}")
                    val content = f.readText().take(2000)
                    logAndEmit("Crash content: $content")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check previous crash log", e)
        }
    }

    @UsedByGodot
    fun initSDK(clientId: String, clientToken: String, serverUrl: String) {
        val activity = activity ?: run {
            Log.e(TAG, "initSDK: Activity is null")
            return
        }
        setupCrashHandler()
        logAndEmit("initSDK called (v4), setting up TapSDK...")
        try {
            val sdkOptions = TapTapSdkOptions(
                clientId,
                clientToken,
                TapTapRegion.CN,
                "",
                true,
            )
            val complianceOptions = TapTapComplianceOptions(
                true,
                false,
            )
            TapTapSdk.init(activity, sdkOptions, complianceOptions)
            isInitialized = true
            logAndEmit("TapSDK v4 initialized OK")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize TapSDK v4", e)
            logAndEmit("TapSDK v4 init FAILED: ${e.javaClass.simpleName}: ${e.message}")
        }
    }

    @UsedByGodot
    fun initAntiAddiction(clientId: String) {
        logAndEmit("initAntiAddiction called (v4 compliance)")
        try {
            TapTapCompliance.registerComplianceCallback(
                object : TapTapComplianceCallback {
                    override fun onComplianceResult(code: Int, extra: Map<String, Any>?) {
                        val msg = extra?.entries?.joinToString("; ") { "${it.key}=${it.value}" } ?: ""
                        logAndEmit("Compliance callback: code=$code msg=$msg")
                        safeEmit("on_anti_addiction_callback", code.toString(), msg)
                    }
                }
            )
            complianceInitialized = true
            logAndEmit("TapTapCompliance registered OK")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register compliance callback", e)
            logAndEmit("Compliance register FAILED: ${e.javaClass.simpleName}: ${e.message}")
            safeEmit("on_anti_addiction_callback", "500", "compliance_init_failed")
        }
    }

    @UsedByGodot
    fun initUpdate(clientId: String, clientToken: String) {
        logAndEmit("initUpdate called (v4, using intent-based update)")
    }

    @UsedByGodot
    fun login() {
        if (!ensureInitialized("login")) return
        val activity = activity ?: return
        logAndEmit("login called, starting TapTap login...")
        try {
            val scopes = arrayOf(Scopes.SCOPE_PUBLIC_PROFILE)
            TapTapLogin.loginWithScopes(
                activity,
                scopes,
                object : TapTapCallback<TapTapAccount> {
                    override fun onSuccess(account: TapTapAccount) {
                        try {
                            logAndEmit("Login success callback received")
                            val json = JSONObject().apply {
                                put("name", account.name ?: "")
                                put("avatar", account.avatar ?: "")
                                put("user_id", account.openId ?: "")
                                put("openid", account.openId ?: "")
                                put("unionid", account.unionId ?: "")
                            }
                            logAndEmit("Login data prepared, emitting on_login_success")
                            safeEmit("on_login_success", json.toString())
                        } catch (e: Exception) {
                            Log.e(TAG, "Error processing login result", e)
                            safeEmit("on_login_failed", "Parse error: ${e.message}")
                        }
                    }

                    override fun onCancel() {
                        logAndEmit("Login canceled")
                        safeEmit("on_login_canceled")
                    }

                    override fun onFail(exception: TapTapException) {
                        Log.e(TAG, "Login error: ${exception.message}")
                        safeEmit("on_login_failed", exception.message ?: "Unknown error")
                    }
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Login exception", e)
            safeEmit("on_login_failed", "Exception: ${e.message}")
        }
    }

    @UsedByGodot
    fun logout() {
        try {
            TapTapLogin.logout()
            currentArchiveId = null
            safeEmit("on_logout_finished")
            logAndEmit("Logout OK")
        } catch (e: Exception) {
            Log.e(TAG, "Logout error", e)
        }
    }

    @UsedByGodot
    fun checkAntiAddiction() {
        logAndEmit("checkAntiAddiction called, sdkInit=$isInitialized, complianceInit=$complianceInitialized")
        if (!isInitialized) {
            logAndEmit("TapSDK not initialized, emitting code=500")
            safeEmit("on_anti_addiction_callback", "500", "sdk_not_init")
            return
        }
        if (!complianceInitialized) {
            logAndEmit("Compliance not initialized, emitting code=500")
            safeEmit("on_anti_addiction_callback", "500", "compliance_not_init")
            return
        }
        val activity = this.activity
        if (activity == null) {
            logAndEmit("Activity is null, emitting code=500")
            safeEmit("on_anti_addiction_callback", "500", "no_activity")
            return
        }
        val userId = try {
            val account = TapTapLogin.getCurrentTapAccount()
            account?.openId ?: ""
        } catch (e: Exception) {
            Log.e(TAG, "Error getting current account", e)
            ""
        }
        if (userId.isEmpty()) {
            logAndEmit("userId is empty, emitting code=500")
            safeEmit("on_anti_addiction_callback", "500", "no_userid")
            return
        }
        logAndEmit("Starting compliance check for userId=$userId")
        try {
            TapTapCompliance.startup(activity, userId)
            logAndEmit("TapTapCompliance.startup called OK")
        } catch (e: Exception) {
            Log.e(TAG, "TapTapCompliance.startup exception", e)
            logAndEmit("Compliance check FAILED: ${e.javaClass.simpleName}: ${e.message}")
            safeEmit("on_anti_addiction_callback", "500", "check_failed")
        }
    }

    @UsedByGodot
    fun exitAntiAddiction() {
        if (!complianceInitialized) return
        try {
            TapTapCompliance.exit()
            logAndEmit("TapTapCompliance.exit called OK")
        } catch (e: Exception) {
            Log.e(TAG, "TapTapCompliance.exit exception", e)
        }
    }

    @UsedByGodot
    fun checkUpdate() {
        logAndEmit("checkUpdate called (intent-based)")
        val activity = this.activity ?: return
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("taptap://taptap.cn/app?source=outer|update"))
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            activity.startActivity(intent)
            logAndEmit("Update: opened TapTap app")
        } catch (e: Exception) {
            Log.e(TAG, "Update: failed to open TapTap", e)
            try {
                val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.taptap.cn/"))
                webIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                activity.startActivity(webIntent)
                logAndEmit("Update: opened TapTap web")
            } catch (e2: Exception) {
                logAndEmit("Update: failed to open TapTap web: ${e2.message}")
            }
        }
    }

    @UsedByGodot
    fun initCloudSave() {
        logAndEmit("initCloudSave called")
        try {
            TapTapCloudSave.registerCloudSaveCallback(
                object : TapCloudSaveCallback {
                    override fun onResult(resultCode: Int) {
                        logAndEmit("CloudSave status: code=$resultCode")
                        when (resultCode) {
                            300001 -> safeEmit("on_cloud_save_result", "error", "need_login")
                            300002 -> safeEmit("on_cloud_save_result", "error", "init_failed")
                        }
                    }
                }
            )
            logAndEmit("CloudSave callback registered OK")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register CloudSave callback", e)
            logAndEmit("CloudSave register FAILED: ${e.javaClass.simpleName}: ${e.message}")
        }
    }

    @UsedByGodot
    fun setCurrentArchiveId(archiveId: String) {
        currentArchiveId = if (archiveId.isEmpty()) null else archiveId
        logAndEmit("setCurrentArchiveId: $currentArchiveId")
    }

    @UsedByGodot
    fun saveToCloud(saveData: String, summary: String) {
        logAndEmit("saveToCloud called, dataLen=${saveData.length}")
        val activity = this.activity ?: run {
            safeEmit("on_cloud_save_result", "error", "no_activity")
            return
        }
        try {
            val saveFile = File(activity.cacheDir, "cloud_save.json")
            saveFile.writeText(saveData)

            val metadata = ArchiveMetadata.Builder()
                .setName("nonogramart_save")
                .setSummary(summary)
                .setExtra("")
                .setPlaytime(0)
                .build()

            val callback = object : TapCloudSaveRequestCallback {
                override fun onRequestError(errorCode: Int, errorMessage: String) {
                    logAndEmit("CloudSave error: code=$errorCode msg=$errorMessage")
                    safeEmit("on_cloud_save_result", "error", "code=$errorCode msg=$errorMessage")
                }

                override fun onArchiveCreated(archive: ArchiveData) {
                    currentArchiveId = archive.uuid
                    logAndEmit("CloudSave created: id=${archive.uuid}")
                    safeEmit("on_cloud_save_result", "created", archive.uuid)
                }

                override fun onArchiveUpdated(archive: ArchiveData) {
                    currentArchiveId = archive.uuid
                    logAndEmit("CloudSave updated: id=${archive.uuid}")
                    safeEmit("on_cloud_save_result", "updated", archive.uuid)
                }

                override fun onArchiveDeleted(archive: ArchiveData) {
                    if (currentArchiveId == archive.uuid) {
                        currentArchiveId = null
                    }
                    logAndEmit("CloudSave deleted: id=${archive.uuid}")
                    safeEmit("on_cloud_save_result", "deleted", archive.uuid)
                }

                override fun onArchiveListResult(archiveList: List<ArchiveData>) {
                    logAndEmit("CloudSave list: count=${archiveList.size}")
                }

                override fun onArchiveDataResult(archiveData: ByteArray) {
                    logAndEmit("CloudSave data received: size=${archiveData.size}")
                }

                override fun onArchiveCoverResult(coverData: ByteArray) {
                    logAndEmit("CloudSave cover received: size=${coverData.size}")
                }
            }

            if (currentArchiveId != null) {
                TapTapCloudSave.updateArchive(currentArchiveId!!, metadata, saveFile.absolutePath, null, callback)
                logAndEmit("CloudSave updating existing archive: $currentArchiveId")
            } else {
                logAndEmit("CloudSave archiveId is null, querying archive list first...")
                TapTapCloudSave.getArchiveList(object : TapCloudSaveRequestCallback {
                    override fun onRequestError(errorCode: Int, errorMessage: String) {
                        logAndEmit("CloudSave pre-query list error: code=$errorCode msg=$errorMessage, creating new archive")
                        TapTapCloudSave.createArchive(metadata, saveFile.absolutePath, null, callback)
                    }
                    override fun onArchiveCreated(archive: ArchiveData) {}
                    override fun onArchiveUpdated(archive: ArchiveData) {}
                    override fun onArchiveDeleted(archive: ArchiveData) {}
                    override fun onArchiveDataResult(archiveData: ByteArray) {}
                    override fun onArchiveCoverResult(coverData: ByteArray) {}
                    override fun onArchiveListResult(archiveList: List<ArchiveData>) {
                        if (archiveList.isNotEmpty()) {
                            currentArchiveId = archiveList[0].uuid
                            logAndEmit("CloudSave found existing archive: $currentArchiveId, updating instead of creating")
                            TapTapCloudSave.updateArchive(currentArchiveId!!, metadata, saveFile.absolutePath, null, callback)
                        } else {
                            logAndEmit("CloudSave no existing archive, creating new one")
                            TapTapCloudSave.createArchive(metadata, saveFile.absolutePath, null, callback)
                        }
                    }
                })
            }
        } catch (e: Exception) {
            Log.e(TAG, "saveToCloud exception", e)
            logAndEmit("saveToCloud FAILED: ${e.javaClass.simpleName}: ${e.message}")
            safeEmit("on_cloud_save_result", "error", e.message ?: "unknown")
        }
    }

    @UsedByGodot
    fun loadCloudSaveList() {
        logAndEmit("loadCloudSaveList called")
        try {
            TapTapCloudSave.getArchiveList(object : TapCloudSaveRequestCallback {
                override fun onRequestError(errorCode: Int, errorMessage: String) {
                    logAndEmit("CloudSave list error: code=$errorCode msg=$errorMessage")
                    safeEmit("on_cloud_save_list", "")
                }

                override fun onArchiveCreated(archive: ArchiveData) {}
                override fun onArchiveUpdated(archive: ArchiveData) {}
                override fun onArchiveDeleted(archive: ArchiveData) {}
                override fun onArchiveDataResult(archiveData: ByteArray) {}
                override fun onArchiveCoverResult(coverData: ByteArray) {}

                override fun onArchiveListResult(archiveList: List<ArchiveData>) {
                    logAndEmit("CloudSave list: count=${archiveList.size}")
                    if (archiveList.isNotEmpty()) {
                        currentArchiveId = archiveList[0].uuid
                    }
                    val json = JSONObject()
                    val arr = org.json.JSONArray()
                    for (archive in archiveList) {
                        val obj = JSONObject().apply {
                            put("archiveId", archive.uuid)
                            put("name", archive.name ?: "")
                            put("summary", archive.summary ?: "")
                            put("fileId", archive.fileId ?: "")
                            put("modifiedTime", archive.modifiedTime)
                        }
                        arr.put(obj)
                    }
                    json.put("archives", arr)
                    safeEmit("on_cloud_save_list", json.toString())
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "loadCloudSaveList exception", e)
            logAndEmit("loadCloudSaveList FAILED: ${e.javaClass.simpleName}: ${e.message}")
            safeEmit("on_cloud_save_list", "")
        }
    }

    @UsedByGodot
    fun loadCloudSaveData(archiveId: String, fileId: String) {
        logAndEmit("loadCloudSaveData called: archiveId=$archiveId fileId=$fileId")
        try {
            TapTapCloudSave.getArchiveData(archiveId, fileId, object : TapCloudSaveRequestCallback {
                override fun onRequestError(errorCode: Int, errorMessage: String) {
                    logAndEmit("CloudSave data error: code=$errorCode msg=$errorMessage")
                    safeEmit("on_cloud_save_data", "")
                }

                override fun onArchiveCreated(archive: ArchiveData) {}
                override fun onArchiveUpdated(archive: ArchiveData) {}
                override fun onArchiveDeleted(archive: ArchiveData) {}
                override fun onArchiveListResult(archiveList: List<ArchiveData>) {}
                override fun onArchiveCoverResult(coverData: ByteArray) {}

                override fun onArchiveDataResult(archiveData: ByteArray) {
                    logAndEmit("CloudSave data received: size=${archiveData.size}")
                    val dataStr = String(archiveData, Charsets.UTF_8)
                    safeEmit("on_cloud_save_data", dataStr)
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "loadCloudSaveData exception", e)
            logAndEmit("loadCloudSaveData FAILED: ${e.javaClass.simpleName}: ${e.message}")
            safeEmit("on_cloud_save_data", "")
        }
    }

    @UsedByGodot
    fun deleteCloudSave(archiveId: String) {
        logAndEmit("deleteCloudSave called: archiveId=$archiveId")
        try {
            TapTapCloudSave.deleteArchive(archiveId, object : TapCloudSaveRequestCallback {
                override fun onRequestError(errorCode: Int, errorMessage: String) {
                    logAndEmit("CloudSave delete error: code=$errorCode msg=$errorMessage")
                    safeEmit("on_cloud_save_result", "delete_error", "code=$errorCode msg=$errorMessage")
                }

                override fun onArchiveCreated(archive: ArchiveData) {}
                override fun onArchiveUpdated(archive: ArchiveData) {}
                override fun onArchiveListResult(archiveList: List<ArchiveData>) {}
                override fun onArchiveDataResult(archiveData: ByteArray) {}
                override fun onArchiveCoverResult(coverData: ByteArray) {}

                override fun onArchiveDeleted(archive: ArchiveData) {
                    if (currentArchiveId == archive.uuid) {
                        currentArchiveId = null
                    }
                    logAndEmit("CloudSave deleted: ${archive.uuid}")
                    safeEmit("on_cloud_save_result", "deleted", archive.uuid)
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "deleteCloudSave exception", e)
            safeEmit("on_cloud_save_result", "delete_error", e.message ?: "unknown")
        }
    }

    @UsedByGodot
    fun getCurrentUserId(): String {
        return try {
            TapTapLogin.getCurrentTapAccount()?.openId ?: ""
        } catch (e: Exception) {
            ""
        }
    }

    @UsedByGodot
    fun isUserLoggedIn(): Boolean {
        return try {
            TapTapLogin.getCurrentTapAccount() != null
        } catch (e: Exception) {
            false
        }
    }

    @UsedByGodot
    fun getDisplayUserId(): String {
        return try {
            TapTapLogin.getCurrentTapAccount()?.openId ?: ""
        } catch (e: Exception) {
            ""
        }
    }

    @UsedByGodot
    fun initLeaderboard() {
        logAndEmit("initLeaderboard called")
        try {
            TapTapLeaderboard.registerLeaderboardCallback(
                object : TapTapLeaderboardCallback {
                    override fun onLeaderboardResult(code: Int, message: String) {
                        logAndEmit("Leaderboard event: code=$code msg=$message")
                        safeEmit("on_leaderboard_result", code.toString(), message)
                    }
                }
            )
            logAndEmit("Leaderboard callback registered OK")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register leaderboard callback", e)
            logAndEmit("Leaderboard register FAILED: ${e.javaClass.simpleName}: ${e.message}")
        }
    }

    @UsedByGodot
    fun submitLeaderboardScore(leaderboardId: String, score: Long) {
        logAndEmit("submitLeaderboardScore called: id=$leaderboardId score=$score")
        try {
            val scoreItem = SubmitScoresRequest.ScoreItem(leaderboardId, score)
            val request = SubmitScoresRequest(listOf(scoreItem))
            TapTapLeaderboard.submitScores(
                request.scores,
                object : ITapTapLeaderboardResponseCallback<SubmitScoresResponse> {
                    override fun onSuccess(result: SubmitScoresResponse) {
                        logAndEmit("Leaderboard score submitted OK")
                        safeEmit("on_leaderboard_result", "0", "submit_success")
                    }
                    override fun onFailure(code: Int, message: String) {
                        logAndEmit("Leaderboard submit failed: code=$code msg=$message")
                        safeEmit("on_leaderboard_result", code.toString(), message)
                    }
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "submitLeaderboardScore exception", e)
            logAndEmit("submitLeaderboardScore FAILED: ${e.javaClass.simpleName}: ${e.message}")
            safeEmit("on_leaderboard_result", "-1", e.message ?: "unknown")
        }
    }

    @UsedByGodot
    fun loadLeaderboardScores(leaderboardId: String, collection: String, page: String) {
        logAndEmit("loadLeaderboardScores called: id=$leaderboardId collection=$collection page=$page")
        try {
            val col = if (collection == "FRIENDS") LeaderboardCollection.FRIENDS else LeaderboardCollection.PUBLIC
            TapTapLeaderboard.loadLeaderboardScores(
                leaderboardId,
                col,
                page,
                null,
                object : ITapTapLeaderboardResponseCallback<LeaderboardScoresResponse> {
                    override fun onSuccess(result: LeaderboardScoresResponse) {
                        try {
                            val json = JSONObject()
                            val lb = result.leaderboard
                            val lbObj = JSONObject().apply {
                                put("id", lb?.id ?: "")
                                put("name", lb?.name ?: "")
                            }
                            json.put("leaderboard", lbObj)
                            val arr = org.json.JSONArray()
                            for (score in result.scores) {
                                arr.put(scoreToJson(score))
                            }
                            json.put("scores", arr)
                            json.put("nextPage", result.nextPage ?: "")
                            logAndEmit("Leaderboard scores loaded: count=${result.scores.size}")
                            safeEmit("on_leaderboard_scores", json.toString())
                        } catch (e: Exception) {
                            Log.e(TAG, "Error parsing leaderboard scores", e)
                            safeEmit("on_leaderboard_scores", "")
                        }
                    }
                    override fun onFailure(code: Int, message: String) {
                        logAndEmit("Leaderboard load failed: code=$code msg=$message")
                        safeEmit("on_leaderboard_scores", "")
                    }
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "loadLeaderboardScores exception", e)
            logAndEmit("loadLeaderboardScores FAILED: ${e.javaClass.simpleName}: ${e.message}")
            safeEmit("on_leaderboard_scores", "")
        }
    }

    @UsedByGodot
    fun loadCurrentUserScore(leaderboardId: String, collection: String) {
        logAndEmit("loadCurrentUserScore called: id=$leaderboardId collection=$collection")
        try {
            val col = if (collection == "FRIENDS") LeaderboardCollection.FRIENDS else LeaderboardCollection.PUBLIC
            TapTapLeaderboard.loadCurrentPlayerLeaderboardScore(
                leaderboardId,
                col,
                null,
                object : ITapTapLeaderboardResponseCallback<UserScoreResponse> {
                    override fun onSuccess(result: UserScoreResponse) {
                        try {
                            val json = scoreToJson(result.currentUserScore ?: return)
                            logAndEmit("Leaderboard user score: rank=${result.currentUserScore?.rank} score=${result.currentUserScore?.score}")
                            safeEmit("on_leaderboard_user_score", json.toString())
                        } catch (e: Exception) {
                            Log.e(TAG, "Error parsing user score", e)
                            safeEmit("on_leaderboard_user_score", "")
                        }
                    }
                    override fun onFailure(code: Int, message: String) {
                        logAndEmit("Leaderboard user score failed: code=$code msg=$message")
                        safeEmit("on_leaderboard_user_score", "")
                    }
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "loadCurrentUserScore exception", e)
            logAndEmit("loadCurrentUserScore FAILED: ${e.javaClass.simpleName}: ${e.message}")
            safeEmit("on_leaderboard_user_score", "")
        }
    }

    private fun scoreToJson(score: Score): JSONObject {
        val userObj = JSONObject().apply {
            val u = score.user
            put("name", u?.name ?: "")
            put("openid", u?.openid ?: "")
            put("avatar", u?.avatar?.url ?: "")
        }
        return JSONObject().apply {
            put("rank", score.rank?.toString() ?: "0")
            put("rankDisplay", score.rankDisplay ?: "")
            put("score", score.score?.toString() ?: "0")
            put("scoreDisplay", score.scoreDisplay ?: "")
            put("user", userObj)
        }
    }

    private fun ensureInitialized(method: String): Boolean {
        if (!isInitialized) {
            Log.w(TAG, "$method: TapSDK not initialized")
            return false
        }
        return true
    }
}

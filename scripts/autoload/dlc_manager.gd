extends Node

signal album_pack_loaded(album_id: String)
signal album_pack_download_progress(album_id: String, downloaded: int, total: int)
signal album_pack_download_failed(album_id: String, error: String)

var _loaded_packs: Dictionary = {}
var _pack_dir: String = "user://dlc/"
var _base_url: String = ""
var _version: String = "1.0"
var _downloading: bool = false
var _downloading_album_id: String = ""
var _http: HTTPRequest = null

func _ready():
	set_base_url("https://github.com/reallycsc/NonogramArt_DLC/releases/download/")
	DirAccess.make_dir_recursive_absolute(_pack_dir)
	_scan_existing_packs()

func _scan_existing_packs() -> void:
	var dir = DirAccess.open(_pack_dir)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("album_") and file_name.ends_with(".pck"):
			var pck_path = _pack_dir + file_name
			if ProjectSettings.load_resource_pack(pck_path, false):
				var album_id = file_name.substr(6, file_name.length() - 10)
				_loaded_packs[album_id] = true
		file_name = dir.get_next()
	dir.list_dir_end()

func is_album_available(album_id: String) -> bool:
	if _loaded_packs.has(album_id):
		return true
	return _is_album_in_main_pack(album_id)

func _is_album_in_main_pack(album_id: String) -> bool:
	var test_path = "res://assets/images/illustrations/" + album_id + "/"
	return DirAccess.dir_exists_absolute(test_path)

func load_album_pack(album_id: String) -> bool:
	if _loaded_packs.has(album_id):
		return true
	if _is_album_in_main_pack(album_id):
		_loaded_packs[album_id] = true
		return true
	var pck_path = _pack_dir + "album_" + album_id + ".pck"
	if not FileAccess.file_exists(pck_path):
		return false
	if ProjectSettings.load_resource_pack(pck_path, false):
		_loaded_packs[album_id] = true
		AlbumData.invalidate_cache(album_id)
		album_pack_loaded.emit(album_id)
		return true
	return false

func download_album(album_id: String) -> void:
	if _downloading:
		return
	if is_album_available(album_id):
		load_album_pack(album_id)
		return
	var pck_path = _pack_dir + "album_" + album_id + ".pck"
	if FileAccess.file_exists(pck_path):
		if load_album_pack(album_id):
			return
	_downloading = true
	_downloading_album_id = album_id
	var file_name = "album_" + album_id + ".pck"
	var url = _base_url + file_name + "/" + file_name
	_http = HTTPRequest.new()
	add_child(_http)
	_http.download_file = pck_path + ".tmp"
	_http.download_progress.connect(_on_download_progress)
	var err = _http.request(url)
	if err != OK:
		_cleanup_http()
		album_pack_download_failed.emit(album_id, "Request failed: " + str(err))
		return
	var result = await _http.request_completed
	_cleanup_http()
	if result == null or result.size() < 4 or result[0] != HTTPRequest.RESULT_SUCCESS:
		if FileAccess.file_exists(pck_path + ".tmp"):
			DirAccess.remove_absolute(pck_path + ".tmp")
		album_pack_download_failed.emit(album_id, "Download failed")
		return
	var file = FileAccess.open(pck_path + ".tmp", FileAccess.READ)
	if not file:
		album_pack_download_failed.emit(album_id, "Temp file not found")
		return
	file.close()
	DirAccess.rename_absolute(pck_path + ".tmp", pck_path)
	if not load_album_pack(album_id):
		album_pack_download_failed.emit(album_id, "PCK load failed")

func _on_download_progress(downloaded: int, total: int) -> void:
	if _downloading_album_id != "":
		album_pack_download_progress.emit(_downloading_album_id, downloaded, total)

func _cleanup_http() -> void:
	if _http:
		if _http.download_progress.is_connected(_on_download_progress):
			_http.download_progress.disconnect(_on_download_progress)
		_http.queue_free()
		_http = null
	_downloading = false
	_downloading_album_id = ""

func is_downloading() -> bool:
	return _downloading

func get_downloading_album_id() -> String:
	return _downloading_album_id

func get_pack_size_mb(album_id: String) -> float:
	var pck_path = _pack_dir + "album_" + album_id + ".pck"
	if FileAccess.file_exists(pck_path):
		var size = FileAccess.get_file_as_bytes(pck_path).size()
		return float(size) / 1048576.0
	return 0.0

func set_base_url(url: String) -> void:
	_base_url = url.rstrip("/") + "/"

func set_version(ver: String) -> void:
	_version = ver

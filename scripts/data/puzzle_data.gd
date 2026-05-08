class_name PuzzleData

var id: String = ""
var name: String = ""
var picture_id: String = ""
var rows: int = 0
var cols: int = 0
var row_clues: Array = []
var col_clues: Array = []
var solution: Array = []
var hint_cells: Array = []
var difficulty: String = "easy"
var source_rect: Dictionary = {}

var _cache: Dictionary = {}


static var _instance: PuzzleData = null


static func _get_instance() -> PuzzleData:
	if _instance == null:
		_instance = PuzzleData.new()
	return _instance


static func invalidate_cache(puzzle_id: String = "") -> void:
	var inst = _get_instance()
	if puzzle_id == "":
		inst._cache.clear()
	else:
		inst._cache.erase(puzzle_id)


static func from_json(data: Dictionary) -> PuzzleData:
	var p = PuzzleData.new()
	p.id = data.get("id", "")
	p.name = data.get("name", "")
	p.picture_id = data.get("picture_id", "")
	var size = data.get("size", {})
	p.rows = size.get("rows", 0)
	p.cols = size.get("cols", 0)
	p.row_clues = data.get("row_clues", [])
	p.col_clues = data.get("col_clues", [])
	p.solution = data.get("solution", [])
	p.hint_cells = []
	for cell in data.get("hint_cells", []):
		if cell is Array and cell.size() >= 2:
			p.hint_cells.append(Vector2i(cell[0], cell[1]))
	p.difficulty = data.get("difficulty", "easy")
	var sr = data.get("source_rect", {})
	if sr.has("x"):
		p.source_rect = sr
	return p


static func load_puzzle(puzzle_id: String) -> PuzzleData:
	var inst = _get_instance()
	if inst._cache.has(puzzle_id):
		return inst._cache[puzzle_id]
	var album_ids = AlbumData.get_all_album_ids()
	for album_id in album_ids:
		var pictures = AlbumData.load_pictures(album_id)
		for picture in pictures:
			if puzzle_id in picture.get("puzzles", []):
				var path = "res://data/puzzles/" + album_id + "/" + puzzle_id + ".json"
				var p = _load_puzzle_file(path)
				if p:
					inst._cache[puzzle_id] = p
				return p
	push_warning("PuzzleData: Puzzle '%s' not found in any album" % puzzle_id)
	return null


static func load_puzzles_for_picture(album_id: String, picture_id: String) -> Array:
	var picture = AlbumData.get_picture(album_id, picture_id)
	var result: Array = []
	for pid in picture.get("puzzles", []):
		var p = load_puzzle(pid)
		if p:
			result.append(p)
	return result


static func _load_puzzle_file(path: String) -> PuzzleData:
	if not FileAccess.file_exists(path):
		push_warning("PuzzleData: Puzzle file not found at " + path)
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("PuzzleData: Failed to open " + path)
		return null
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("PuzzleData: JSON parse error in " + path + " - " + json.get_error_message())
		return null
	if not json.data is Dictionary:
		push_error("PuzzleData: Root data is not a Dictionary in " + path)
		return null
	return from_json(json.data)


func to_json() -> Dictionary:
	var h = []
	for cell in hint_cells:
		h.append([cell.x, cell.y])
	return {
		"id": id,
		"name": name,
		"picture_id": picture_id,
		"size": {"rows": rows, "cols": cols},
		"row_clues": row_clues,
		"col_clues": col_clues,
		"difficulty": difficulty,
		"hint_cells": h,
		"source_rect": source_rect,
	}

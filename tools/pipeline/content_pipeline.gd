@tool
extends EditorScript

const NonogramSolverScript = preload("res://scripts/nonogram/nonogram_solver.gd")
const GeneratePuzzleScript = preload("res://tools/puzzle_generator/generate_puzzle.gd")

func _run() -> void:
	print("=== 内容生产流水线 ===")
	print("此工具执行完整的内容生产流程：")
	print("  1. 从配图提取物体区域")
	print("  2. 生成数织关卡")
	print("  3. 验证可推理求解性")
	print("  4. 保存关卡数据")
	print("")
	print("请调用 run_full_pipeline() 执行完整流水线")


func run_full_pipeline() -> void:
	print("\n" + "=" * 50)
	print("开始执行完整内容生产流水线")
	print("=" * 50)

	var all_puzzle_configs = _get_all_puzzle_solutions()
	var generator = GeneratePuzzleScript.new()

	var total = all_puzzle_configs.size()
	var success = 0
	var fail = 0

	for i in range(total):
		var config = all_puzzle_configs[i]
		print("\n[%d/%d] 生成: %s (%s)" % [i + 1, total, config.id, config.name])

		var puzzle_data = generator.generate_from_solution(
			config.id, config.name, config.story_id,
			config.solution, config.difficulty, config.source_rect
		)

		generator.save_puzzle(puzzle_data, "res://data/puzzles/" + config.era_id)

		if NonogramSolverScript.is_logically_solvable(puzzle_data.row_clues, puzzle_data.col_clues):
			success += 1
		else:
			fail += 1

	print("\n" + "=" * 50)
	print("流水线执行完成")
	print("成功: %d, 需手动调整: %d, 总计: %d" % [success, fail, total])
	print("=" * 50)

	_verify_final_results()


func _verify_final_results() -> void:
	print("\n=== 最终验证 ===")
	var eras = ["mythology", "xia_shang_zhou", "spring_autumn", "qin_han",
				"three_kingdoms", "sui_tang", "song_yuan", "ming_qing",
				"modern", "contemporary"]

	var total = 0
	var solvable = 0

	for era_id in eras:
		var puzzle_dir = "res://data/puzzles/" + era_id
		if not DirAccess.dir_exists_absolute(puzzle_dir):
			continue

		var dir = DirAccess.open(puzzle_dir)
		if not dir:
			continue

		var files: Array = []
		dir.list_dir_begin()
		var fn = dir.get_next()
		while fn != "":
			if fn.ends_with(".json"):
				files.append(fn)
			fn = dir.get_next()
		dir.list_dir_end()

		var era_solvable = 0
		for file_name in files:
			var path = puzzle_dir + "/" + file_name
			var file = FileAccess.open(path, FileAccess.READ)
			if not file:
				continue
			var json = JSON.new()
			json.parse(file.get_as_text())
			file.close()
			if json.data and NonogramSolverScript.is_logically_solvable(json.data.row_clues, json.data.col_clues):
				era_solvable += 1
			total += 1

		print("  %s: %d/%d 可推理" % [era_id, era_solvable, files.size()])
		solvable += era_solvable

	print("\n总计: %d/%d 关卡可推理求解" % [solvable, total])


func _get_all_puzzle_solutions() -> Array:
	var puzzles: Array = []

	puzzles.append_array(_get_mythology_puzzles())
	puzzles.append_array(_get_xia_shang_zhou_puzzles())
	puzzles.append_array(_get_spring_autumn_puzzles())
	puzzles.append_array(_get_qin_han_puzzles())
	puzzles.append_array(_get_three_kingdoms_puzzles())
	puzzles.append_array(_get_sui_tang_puzzles())
	puzzles.append_array(_get_song_yuan_puzzles())
	puzzles.append_array(_get_ming_qing_puzzles())
	puzzles.append_array(_get_modern_puzzles())
	puzzles.append_array(_get_contemporary_puzzles())

	return puzzles


func _get_mythology_puzzles() -> Array:
	return [
		{
			"era_id": "mythology", "id": "pangu_sun", "name": "太阳", "story_id": "pangu",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,0,1,0,0],
				[0,1,1,1,0],
				[1,1,1,1,1],
				[0,1,1,1,0],
				[0,0,1,0,0]
			]
		},
		{
			"era_id": "mythology", "id": "pangu_axe", "name": "盘古斧", "story_id": "pangu",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0]
			]
		},
		{
			"era_id": "mythology", "id": "pangu_mountain", "name": "山", "story_id": "pangu",
			"difficulty": "medium",
			"source_rect": {"x": 192, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[0,0,0,0,0,0,0,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1]
			]
		},
		{
			"era_id": "mythology", "id": "nuwa_stone", "name": "五色石", "story_id": "nuwa",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,1,1,1,0],
				[1,1,1,1,1],
				[1,1,1,1,1],
				[1,1,1,1,1],
				[0,1,1,1,0]
			]
		},
		{
			"era_id": "mythology", "id": "nuwa_turtle", "name": "巨龟", "story_id": "nuwa",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[0,1,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,0,0,0,0,0,0]
			]
		},
		{
			"era_id": "mythology", "id": "houyi_bow", "name": "神弓", "story_id": "houyi",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[1,0,0,0,0,0,0,0,0,0],
				[1,1,0,0,0,0,0,0,0,0],
				[1,0,1,0,0,0,0,0,0,0],
				[1,0,0,1,0,0,0,0,0,0],
				[1,0,0,0,1,0,0,0,0,0],
				[1,0,0,0,0,1,0,0,0,0],
				[1,0,0,0,0,0,1,0,0,0],
				[1,0,0,0,0,0,0,1,0,0],
				[1,1,0,0,0,0,0,0,1,0],
				[1,0,0,0,0,0,0,0,0,1]
			]
		},
		{
			"era_id": "mythology", "id": "houyi_sun", "name": "烈日", "story_id": "houyi",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,0,1,0,1],
				[0,1,1,1,0],
				[1,1,1,1,1],
				[0,1,1,1,0],
				[1,0,1,0,1]
			]
		},
	]


func _get_xia_shang_zhou_puzzles() -> Array:
	return [
		{
			"era_id": "xia_shang_zhou", "id": "dayu_ding", "name": "青铜鼎", "story_id": "dayu",
			"difficulty": "medium",
			"source_rect": {"x": 0, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,0,0,0,0,0,0,1,0],
				[0,1,0,0,0,0,0,0,1,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,0,0,0,0,0,0,1,0],
				[1,1,0,0,0,0,0,0,1,1],
				[1,1,0,0,0,0,0,0,1,1],
				[1,1,1,1,1,1,1,1,1,1]
			]
		},
		{
			"era_id": "xia_shang_zhou", "id": "dayu_water", "name": "洪水", "story_id": "dayu",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,0,0,0,0],
				[0,1,0,1,0],
				[1,1,1,1,1],
				[1,1,1,1,1],
				[1,1,1,1,1]
			]
		},
		{
			"era_id": "xia_shang_zhou", "id": "taigong_hook", "name": "鱼钩", "story_id": "taigong",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,0,0,0,0,0,1],
				[0,0,0,0,0,0,0,0,1,0],
				[0,0,0,0,0,0,0,1,0,0],
				[0,0,0,0,0,0,1,0,0,0],
				[0,0,0,0,0,1,0,0,0,0],
				[0,0,0,0,1,0,0,0,0,0],
				[0,0,0,1,0,0,0,0,0,0],
				[0,0,1,1,0,0,0,0,0,0],
				[0,1,1,0,0,0,0,0,0,0],
				[1,1,0,0,0,0,0,0,0,0]
			]
		},
		{
			"era_id": "xia_shang_zhou", "id": "taigong_rod", "name": "钓竿", "story_id": "taigong",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,0,0,0,0],
				[0,1,0,0,0],
				[0,1,0,0,0],
				[0,1,0,0,0],
				[0,1,1,1,0]
			]
		},
		{
			"era_id": "xia_shang_zhou", "id": "fenghuo_fire", "name": "烽火", "story_id": "fenghuo",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,0,1,0,0],
				[0,1,1,1,0],
				[0,1,1,1,0],
				[1,1,1,1,1],
				[0,1,1,1,0]
			]
		},
		{
			"era_id": "xia_shang_zhou", "id": "fenghuo_drum", "name": "战鼓", "story_id": "fenghuo",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,0,0,0,0,0,0,1,1],
				[1,1,0,0,0,0,0,0,1,1],
				[1,1,0,0,0,0,0,0,1,1],
				[1,1,0,0,0,0,0,0,1,1],
				[1,1,0,0,0,0,0,0,1,1],
				[1,1,0,0,0,0,0,0,1,1],
				[0,1,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,1,0,0]
			]
		},
	]


func _get_spring_autumn_puzzles() -> Array:
	return [
		{
			"era_id": "spring_autumn", "id": "wanbi_jade", "name": "玉璧", "story_id": "wanbi",
			"difficulty": "medium",
			"source_rect": {"x": 0, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,0,0,0,0,0,0,1,0],
				[1,0,0,1,1,1,1,0,0,1],
				[1,0,1,1,1,1,1,1,0,1],
				[1,0,1,1,1,1,1,1,0,1],
				[1,0,1,1,1,1,1,1,0,1],
				[1,0,1,1,1,1,1,1,0,1],
				[1,0,0,1,1,1,1,0,0,1],
				[0,1,0,0,0,0,0,0,1,0],
				[0,0,1,1,1,1,1,1,0,0]
			]
		},
		{
			"era_id": "spring_autumn", "id": "wanbi_map", "name": "城图", "story_id": "wanbi",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,1,1,1,1],
				[1,0,0,0,1],
				[1,0,1,0,1],
				[1,0,0,0,1],
				[1,1,1,1,1]
			]
		},
		{
			"era_id": "spring_autumn", "id": "goujian_sword", "name": "越王剑", "story_id": "goujian",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0]
			]
		},
		{
			"era_id": "spring_autumn", "id": "goujian_gall", "name": "苦胆", "story_id": "goujian",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,1,1,0,0],
				[1,1,1,1,0],
				[1,1,1,1,1],
				[0,1,1,1,0],
				[0,0,1,0,0]
			]
		},
		{
			"era_id": "spring_autumn", "id": "jingke_dagger", "name": "匕首", "story_id": "jingke",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,0,0,0,0,0,1],
				[0,0,0,0,0,0,0,0,1,1],
				[0,0,0,0,0,0,0,1,1,0],
				[0,0,0,0,0,0,1,1,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,0,1,1,1,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,0,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,0,0,0,0,0,0]
			]
		},
		{
			"era_id": "spring_autumn", "id": "jingke_scroll", "name": "地图", "story_id": "jingke",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,1,1,1,0],
				[1,0,0,1,0],
				[1,0,1,1,0],
				[1,1,1,1,0],
				[0,0,0,0,0]
			]
		},
	]


func _get_qin_han_puzzles() -> Array:
	return [
		{
			"era_id": "qin_han", "id": "qinshi_wall", "name": "长城", "story_id": "qinshi",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,1,1,1,1],
				[1,0,1,0,1],
				[1,1,1,1,1],
				[0,1,1,1,0],
				[0,1,1,1,0]
			]
		},
		{
			"era_id": "qin_han", "id": "qinshi_seal", "name": "传国玉玺", "story_id": "qinshi",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,0,0,0,0,0,0,1,1],
				[1,1,0,1,1,1,1,0,1,1],
				[1,1,0,1,0,0,1,0,1,1],
				[1,1,0,1,0,0,1,0,1,1],
				[1,1,0,1,1,1,1,0,1,1],
				[1,1,0,0,0,0,0,0,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1]
			]
		},
		{
			"era_id": "qin_han", "id": "qinshi_sword", "name": "秦剑", "story_id": "qinshi",
			"difficulty": "medium",
			"source_rect": {"x": 192, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,0,0,0,0,0,1],
				[0,0,0,0,0,0,0,0,1,0],
				[0,0,0,0,0,0,0,1,0,0],
				[0,0,0,0,0,0,1,0,0,0],
				[0,0,0,0,0,1,0,0,0,0],
				[0,0,0,1,1,1,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0]
			]
		},
		{
			"era_id": "qin_han", "id": "zhangqian_camel", "name": "骆驼", "story_id": "zhangqian",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,1,1,1,1,0,0,0,0],
				[0,0,1,1,1,1,0,0,0,0],
				[0,1,1,1,1,1,1,0,0,0],
				[0,1,1,1,1,1,1,1,0,0],
				[0,0,1,1,1,1,1,0,0,0],
				[0,0,0,1,1,1,0,0,0,0],
				[0,0,1,1,0,1,1,0,0,0],
				[0,1,1,0,0,0,1,1,0,0]
			]
		},
		{
			"era_id": "qin_han", "id": "zhangqian_silk", "name": "丝绸", "story_id": "zhangqian",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,1,1,1,1],
				[1,0,1,0,1],
				[1,1,1,1,1],
				[1,0,1,0,1],
				[1,1,1,1,1]
			]
		},
		{
			"era_id": "qin_han", "id": "zhaojun_lute", "name": "琵琶", "story_id": "zhaojun",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,0,0,1,1,0,0,0,0]
			]
		},
		{
			"era_id": "qin_han", "id": "zhaojun_goose", "name": "大雁", "story_id": "zhaojun",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,0,1,0,0],
				[0,1,1,1,0],
				[1,1,1,1,1],
				[0,0,1,0,0],
				[0,1,0,1,0]
			]
		},
	]


func _get_three_kingdoms_puzzles() -> Array:
	return [
		{
			"era_id": "three_kingdoms", "id": "caochuan_arrow", "name": "箭", "story_id": "caochuan",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,0,1,0,0],
				[0,0,1,0,0],
				[1,1,1,1,1],
				[0,0,1,0,0],
				[0,0,1,0,0]
			]
		},
		{
			"era_id": "three_kingdoms", "id": "caochuan_boat", "name": "草船", "story_id": "caochuan",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,0,0,0,0,0,0],
				[0,0,0,0,0,0,0,0,0,0],
				[0,0,0,0,0,0,0,0,0,0],
				[0,0,0,0,0,0,0,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[0,1,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,0,1,1,1,1,0,0,0]
			]
		},
		{
			"era_id": "three_kingdoms", "id": "taoyuan_peach", "name": "桃", "story_id": "taoyuan",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,1,1,0,0],
				[1,1,1,1,0],
				[1,1,1,1,1],
				[0,1,1,1,0],
				[0,0,1,0,0]
			]
		},
		{
			"era_id": "three_kingdoms", "id": "taoyuan_wine", "name": "酒坛", "story_id": "taoyuan",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,1,1,1,1,1,1,0,0]
			]
		},
		{
			"era_id": "three_kingdoms", "id": "wenji_rooster", "name": "公鸡", "story_id": "wenji",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,1,1,1,0,0,0,0,0],
				[0,1,1,1,1,1,0,0,0,0],
				[0,0,1,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,0,0,0],
				[0,0,0,1,1,1,0,0,0,0],
				[0,0,0,1,1,1,0,0,0,0],
				[0,0,0,1,1,1,0,0,0,0],
				[0,0,1,1,0,1,1,0,0,0],
				[0,0,1,1,0,1,1,0,0,0]
			]
		},
		{
			"era_id": "three_kingdoms", "id": "wenji_sword", "name": "宝剑", "story_id": "wenji",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,0,0,0,1],
				[0,0,0,1,0],
				[0,1,1,1,0],
				[0,1,0,0,0],
				[0,1,0,0,0]
			]
		},
	]


func _get_sui_tang_puzzles() -> Array:
	return [
		{
			"era_id": "sui_tang", "id": "xuanzang_stupa", "name": "佛塔", "story_id": "xuanzang",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,0,0,0,1,1,0,0,0,0],
				[1,1,1,1,1,1,1,1,1,1],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0]
			]
		},
		{
			"era_id": "sui_tang", "id": "xuanzang_sutra", "name": "经卷", "story_id": "xuanzang",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,1,1,1,1],
				[1,0,0,0,1],
				[1,0,0,0,1],
				[1,0,0,0,1],
				[1,1,1,1,1]
			]
		},
		{
			"era_id": "sui_tang", "id": "xuanzang_staff", "name": "禅杖", "story_id": "xuanzang",
			"difficulty": "medium",
			"source_rect": {"x": 192, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,1,1,1,1,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0]
			]
		},
		{
			"era_id": "sui_tang", "id": "libai_cup", "name": "酒杯", "story_id": "libai",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,1,1,1,1],
				[0,1,1,1,0],
				[0,0,1,0,0],
				[0,0,1,0,0],
				[0,1,1,1,0]
			]
		},
		{
			"era_id": "sui_tang", "id": "libai_moon", "name": "明月", "story_id": "libai",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,1,1,1,1,1,0,0,0],
				[0,1,1,1,1,1,1,1,0,0],
				[1,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,0],
				[0,1,1,1,1,1,1,1,0,0],
				[0,0,1,1,1,1,1,0,0,0],
				[0,0,0,1,1,1,0,0,0,0]
			]
		},
		{
			"era_id": "sui_tang", "id": "wencheng_buddha", "name": "佛像", "story_id": "wencheng",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,1,0,1,1,0,1,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0]
			]
		},
		{
			"era_id": "sui_tang", "id": "wencheng_temple", "name": "寺庙", "story_id": "wencheng",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,0,1,0,0],
				[0,1,1,1,0],
				[1,1,1,1,1],
				[0,1,0,1,0],
				[0,1,1,1,0]
			]
		},
	]


func _get_song_yuan_puzzles() -> Array:
	return [
		{
			"era_id": "song_yuan", "id": "yuefei_spear", "name": "长枪", "story_id": "yuefei",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,0,0,0,0,0,1],
				[0,0,0,0,0,0,0,0,1,0],
				[0,0,0,1,1,1,0,1,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0]
			]
		},
		{
			"era_id": "song_yuan", "id": "yuefei_shield", "name": "盾牌", "story_id": "yuefei",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,1,1,1,1],
				[1,1,1,1,1],
				[0,1,1,1,0],
				[0,0,1,0,0],
				[0,0,0,0,0]
			]
		},
		{
			"era_id": "song_yuan", "id": "huozi_type", "name": "活字", "story_id": "huozi",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,1,1,1,1],
				[1,0,0,0,1],
				[1,0,0,0,1],
				[1,0,0,0,1],
				[1,1,1,1,1]
			]
		},
		{
			"era_id": "song_yuan", "id": "huozi_book", "name": "书卷", "story_id": "huozi",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,0,0,0,0,0,0],
				[1,1,1,1,1,1,1,1,1,1],
				[1,0,0,0,0,0,0,0,0,1],
				[1,0,0,0,0,0,0,0,0,1],
				[1,0,0,0,0,0,0,0,0,1],
				[1,0,0,0,0,0,0,0,0,1],
				[1,0,0,0,0,0,0,0,0,1],
				[1,0,0,0,0,0,0,0,0,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1]
			]
		},
		{
			"era_id": "song_yuan", "id": "marco_ship", "name": "帆船", "story_id": "marco",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,1,0,0,0,0,0],
				[0,0,0,0,1,0,0,0,0,0],
				[0,0,0,1,1,1,0,0,0,0],
				[0,0,1,1,1,1,1,0,0,0],
				[0,1,1,1,1,1,1,1,0,0],
				[1,1,1,1,1,1,1,1,1,0],
				[0,0,0,0,1,0,0,0,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[0,1,1,1,1,1,1,1,1,0]
			]
		},
		{
			"era_id": "song_yuan", "id": "marco_compass", "name": "指南针", "story_id": "marco",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,0,1,0,0],
				[0,1,1,1,0],
				[1,1,1,1,1],
				[0,1,1,1,0],
				[0,0,1,0,0]
			]
		},
	]


func _get_ming_qing_puzzles() -> Array:
	return [
		{
			"era_id": "ming_qing", "id": "zhenghe_ship", "name": "宝船", "story_id": "zhenghe",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,1,0,0,0,0,0],
				[0,0,0,1,1,1,0,0,0,0],
				[0,0,0,0,1,0,0,0,0,0],
				[0,0,0,0,1,0,0,0,0,0],
				[0,0,1,1,1,1,1,0,0,0],
				[0,1,1,1,1,1,1,1,0,0],
				[1,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[0,1,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,1,0,0]
			]
		},
		{
			"era_id": "ming_qing", "id": "zhenghe_compass", "name": "罗盘", "story_id": "zhenghe",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,1,0,1,0],
				[1,1,1,1,1],
				[0,1,1,1,0],
				[1,1,1,1,1],
				[0,1,0,1,0]
			]
		},
		{
			"era_id": "ming_qing", "id": "kangqian_robe", "name": "龙袍", "story_id": "kangqian",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,0,0,1,1,0,0,1,0],
				[0,1,1,0,1,1,0,1,1,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,0,1,1,1,1,0,1,0],
				[0,1,1,0,1,1,0,1,1,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,1,0,0]
			]
		},
		{
			"era_id": "ming_qing", "id": "kangqian_seal", "name": "玉玺", "story_id": "kangqian",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,1,1,1,1],
				[1,1,1,1,1],
				[1,1,0,1,1],
				[1,1,1,1,1],
				[1,1,1,1,1]
			]
		},
		{
			"era_id": "ming_qing", "id": "linzexu_pipe", "name": "烟管", "story_id": "linzexu",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,0,0,0,0,0,1],
				[0,0,0,0,0,0,0,0,1,0],
				[0,0,0,0,0,0,0,1,0,0],
				[0,0,0,0,0,0,1,0,0,0],
				[0,0,0,0,0,1,0,0,0,0],
				[0,0,0,0,1,0,0,0,0,0],
				[0,0,0,1,0,0,0,0,0,0],
				[0,0,1,0,0,0,0,0,0,0],
				[0,1,1,0,0,0,0,0,0,0],
				[1,1,1,0,0,0,0,0,0,0]
			]
		},
		{
			"era_id": "ming_qing", "id": "linzexu_fire", "name": "烈火", "story_id": "linzexu",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,0,1,0,0],
				[0,1,1,1,0],
				[1,1,1,1,1],
				[0,1,1,1,0],
				[1,1,1,1,1]
			]
		},
	]


func _get_modern_puzzles() -> Array:
	return [
		{
			"era_id": "modern", "id": "xinhai_flag", "name": "旗帜", "story_id": "xinhai",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,0,0,0,0],
				[1,1,0,0,0],
				[1,1,1,0,0],
				[1,1,1,1,0],
				[1,1,1,1,1]
			]
		},
		{
			"era_id": "modern", "id": "xinhai_rifle", "name": "步枪", "story_id": "xinhai",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,0,0,0,0,0,1],
				[0,0,0,0,0,0,0,0,1,1],
				[0,0,0,0,0,0,0,1,1,0],
				[0,0,0,0,0,0,1,1,0,0],
				[0,0,0,0,0,1,1,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,1,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0],
				[0,0,0,1,1,0,0,0,0,0]
			]
		},
		{
			"era_id": "modern", "id": "wusi_book", "name": "新青年", "story_id": "wusi",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[1,1,1,1,0],
				[1,0,0,1,0],
				[1,0,0,1,0],
				[1,0,0,1,0],
				[1,1,1,1,0]
			]
		},
		{
			"era_id": "modern", "id": "wusi_torch", "name": "火炬", "story_id": "wusi",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,0,1,1,0,0,0,0]
			]
		},
		{
			"era_id": "modern", "id": "changzheng_star", "name": "五角星", "story_id": "changzheng",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,0,1,0,0],
				[1,1,1,1,1],
				[0,1,1,1,0],
				[0,1,0,1,0],
				[1,0,0,0,1]
			]
		},
		{
			"era_id": "modern", "id": "changzheng_mountain", "name": "雪山", "story_id": "changzheng",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1]
			]
		},
	]


func _get_contemporary_puzzles() -> Array:
	return [
		{
			"era_id": "contemporary", "id": "liangdan_rocket", "name": "火箭", "story_id": "liangdan",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,0,1,1,1,1,0,1,0]
			]
		},
		{
			"era_id": "contemporary", "id": "liangdan_star", "name": "红星", "story_id": "liangdan",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,0,1,0,0],
				[1,1,1,1,1],
				[0,1,1,1,0],
				[0,1,0,1,0],
				[1,0,0,0,1]
			]
		},
		{
			"era_id": "contemporary", "id": "gaige_building", "name": "高楼", "story_id": "gaige",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,1,0,1,0,1,0,0,0],
				[0,0,1,0,1,0,1,0,0,0],
				[0,0,1,0,1,0,1,0,0,0],
				[0,0,1,0,1,0,1,0,0,0],
				[0,0,1,0,1,0,1,0,0,0],
				[0,0,1,0,1,0,1,0,0,0],
				[0,0,1,0,1,0,1,0,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[0,1,1,1,1,1,1,1,1,0]
			]
		},
		{
			"era_id": "contemporary", "id": "gaige_wheat", "name": "麦穗", "story_id": "gaige",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,0,1,0,0],
				[0,1,1,1,0],
				[0,0,1,0,0],
				[0,1,1,1,0],
				[0,0,1,0,0]
			]
		},
		{
			"era_id": "contemporary", "id": "hangtian_capsule", "name": "飞船", "story_id": "hangtian",
			"difficulty": "medium",
			"source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
			"solution": [
				[0,0,0,0,1,1,0,0,0,0],
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[0,1,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,0,0,1,1,1,1,0,0,0]
			]
		},
		{
			"era_id": "contemporary", "id": "hangtian_moon", "name": "月球", "story_id": "hangtian",
			"difficulty": "easy",
			"source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
			"solution": [
				[0,1,1,1,0],
				[1,1,1,1,1],
				[1,1,0,1,1],
				[1,1,1,1,1],
				[0,1,1,1,0]
			]
		},
	]

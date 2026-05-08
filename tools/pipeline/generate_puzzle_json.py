import json
import os
import sys

def compute_clues(solution):
    rows = len(solution)
    cols = len(solution[0]) if rows > 0 else 0
    
    row_clues = []
    for r in range(rows):
        segments = []
        count = 0
        for c in range(cols):
            if solution[r][c] == 1:
                count += 1
            else:
                if count > 0:
                    segments.append(count)
                count = 0
        if count > 0:
            segments.append(count)
        if not segments:
            segments = [0]
        row_clues.append(segments)
    
    col_clues = []
    for c in range(cols):
        segments = []
        count = 0
        for r in range(rows):
            if solution[r][c] == 1:
                count += 1
            else:
                if count > 0:
                    segments.append(count)
                count = 0
        if count > 0:
            segments.append(count)
        if not segments:
            segments = [0]
        col_clues.append(segments)
    
    return row_clues, col_clues


def generate_puzzle_json(puzzle_id, name, story_id, solution, difficulty, source_rect):
    rows = len(solution)
    cols = len(solution[0]) if rows > 0 else 0
    row_clues, col_clues = compute_clues(solution)
    
    return {
        "id": puzzle_id,
        "name": name,
        "story_id": story_id,
        "size": {"rows": rows, "cols": cols},
        "difficulty": difficulty,
        "row_clues": row_clues,
        "col_clues": col_clues,
        "solution": solution,
        "hint_cells": [],
        "source_rect": source_rect
    }


PUZZLES = {
    "xia_shang_zhou": [
        {
            "id": "dayu_ding", "name": "青铜鼎", "story_id": "dayu", "difficulty": "medium",
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
            "id": "dayu_water", "name": "洪水", "story_id": "dayu", "difficulty": "easy",
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
            "id": "taigong_hook", "name": "鱼钩", "story_id": "taigong", "difficulty": "medium",
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
            "id": "taigong_rod", "name": "钓竿", "story_id": "taigong", "difficulty": "easy",
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
            "id": "fenghuo_fire", "name": "烽火", "story_id": "fenghuo", "difficulty": "easy",
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
            "id": "fenghuo_drum", "name": "战鼓", "story_id": "fenghuo", "difficulty": "medium",
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
    ],
    "spring_autumn": [
        {
            "id": "wanbi_jade", "name": "玉璧", "story_id": "wanbi", "difficulty": "medium",
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
            "id": "wanbi_map", "name": "城图", "story_id": "wanbi", "difficulty": "easy",
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
            "id": "goujian_sword", "name": "越王剑", "story_id": "goujian", "difficulty": "medium",
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
            "id": "goujian_gall", "name": "苦胆", "story_id": "goujian", "difficulty": "easy",
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
            "id": "jingke_dagger", "name": "匕首", "story_id": "jingke", "difficulty": "medium",
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
            "id": "jingke_scroll", "name": "地图", "story_id": "jingke", "difficulty": "easy",
            "source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
            "solution": [
                [1,1,1,1,0],
                [1,0,0,1,0],
                [1,0,1,1,0],
                [1,1,1,1,0],
                [0,0,0,0,0]
            ]
        },
    ],
    "three_kingdoms": [
        {
            "id": "caochuan_arrow", "name": "箭", "story_id": "caochuan", "difficulty": "easy",
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
            "id": "caochuan_boat", "name": "草船", "story_id": "caochuan", "difficulty": "medium",
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
            "id": "taoyuan_peach", "name": "桃", "story_id": "taoyuan", "difficulty": "easy",
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
            "id": "taoyuan_wine", "name": "酒坛", "story_id": "taoyuan", "difficulty": "medium",
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
            "id": "wenji_rooster", "name": "公鸡", "story_id": "wenji", "difficulty": "medium",
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
            "id": "wenji_sword", "name": "宝剑", "story_id": "wenji", "difficulty": "easy",
            "source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
            "solution": [
                [0,0,0,0,1],
                [0,0,0,1,0],
                [0,1,1,1,0],
                [0,1,0,0,0],
                [0,1,0,0,0]
            ]
        },
    ],
    "song_yuan": [
        {
            "id": "yuefei_spear", "name": "长枪", "story_id": "yuefei", "difficulty": "medium",
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
            "id": "yuefei_shield", "name": "盾牌", "story_id": "yuefei", "difficulty": "easy",
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
            "id": "huozi_type", "name": "活字", "story_id": "huozi", "difficulty": "easy",
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
            "id": "huozi_book", "name": "书卷", "story_id": "huozi", "difficulty": "medium",
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
            "id": "marco_ship", "name": "帆船", "story_id": "marco", "difficulty": "medium",
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
            "id": "marco_compass", "name": "指南针", "story_id": "marco", "difficulty": "easy",
            "source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
            "solution": [
                [0,0,1,0,0],
                [0,1,1,1,0],
                [1,1,1,1,1],
                [0,1,1,1,0],
                [0,0,1,0,0]
            ]
        },
    ],
    "ming_qing": [
        {
            "id": "zhenghe_ship", "name": "宝船", "story_id": "zhenghe", "difficulty": "medium",
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
            "id": "zhenghe_compass", "name": "罗盘", "story_id": "zhenghe", "difficulty": "easy",
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
            "id": "kangqian_robe", "name": "龙袍", "story_id": "kangqian", "difficulty": "medium",
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
            "id": "kangqian_seal", "name": "玉玺", "story_id": "kangqian", "difficulty": "easy",
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
            "id": "linzexu_pipe", "name": "烟管", "story_id": "linzexu", "difficulty": "medium",
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
            "id": "linzexu_fire", "name": "烈火", "story_id": "linzexu", "difficulty": "easy",
            "source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
            "solution": [
                [0,0,1,0,0],
                [0,1,1,1,0],
                [1,1,1,1,1],
                [0,1,1,1,0],
                [1,1,1,1,1]
            ]
        },
    ],
    "modern": [
        {
            "id": "xinhai_flag", "name": "旗帜", "story_id": "xinhai", "difficulty": "easy",
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
            "id": "xinhai_rifle", "name": "步枪", "story_id": "xinhai", "difficulty": "medium",
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
            "id": "wusi_book", "name": "新青年", "story_id": "wusi", "difficulty": "easy",
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
            "id": "wusi_torch", "name": "火炬", "story_id": "wusi", "difficulty": "medium",
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
            "id": "changzheng_star", "name": "五角星", "story_id": "changzheng", "difficulty": "easy",
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
            "id": "changzheng_mountain", "name": "雪山", "story_id": "changzheng", "difficulty": "medium",
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
    ],
    "contemporary": [
        {
            "id": "liangdan_rocket", "name": "火箭", "story_id": "liangdan", "difficulty": "medium",
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
            "id": "liangdan_star", "name": "红星", "story_id": "liangdan", "difficulty": "easy",
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
            "id": "gaige_building", "name": "高楼", "story_id": "gaige", "difficulty": "medium",
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
            "id": "gaige_wheat", "name": "麦穗", "story_id": "gaige", "difficulty": "easy",
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
            "id": "hangtian_capsule", "name": "飞船", "story_id": "hangtian", "difficulty": "medium",
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
            "id": "hangtian_moon", "name": "月球", "story_id": "hangtian", "difficulty": "easy",
            "source_rect": {"x": 0, "y": 0, "w": 64, "h": 64},
            "solution": [
                [0,1,1,1,0],
                [1,1,1,1,1],
                [1,1,0,1,1],
                [1,1,1,1,1],
                [0,1,1,1,0]
            ]
        },
    ],
}


def main():
    base_dir = r"H:\Work\MyProject\ChineseMemory"
    data_dir = os.path.join(base_dir, "data", "puzzles")
    
    for era_id, puzzles in PUZZLES.items():
        era_dir = os.path.join(data_dir, era_id)
        os.makedirs(era_dir, exist_ok=True)
        
        for puzzle in puzzles:
            puzzle_data = generate_puzzle_json(
                puzzle["id"], puzzle["name"], puzzle["story_id"],
                puzzle["solution"], puzzle["difficulty"], puzzle["source_rect"]
            )
            
            file_path = os.path.join(era_dir, puzzle["id"] + ".json")
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(puzzle_data, f, ensure_ascii=False, indent="\t")
            
            print(f"  生成: {era_id}/{puzzle['id']}.json ({puzzle_data['size']['rows']}x{puzzle_data['size']['cols']})")
    
    print("\n所有谜题文件生成完成！")


if __name__ == "__main__":
    main()

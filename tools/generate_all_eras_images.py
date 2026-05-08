import os
import sys
import json
import requests
from PIL import Image
from io import BytesIO

API_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3/images/generations"
API_KEY = "ark-769a3f8a-9ceb-4556-ae95-d882f7966850-2be63"
MODEL = "doubao-seedream-4-5-251128"

ASPECT_RATIO_SIZES = {
    "1:1": "2048x2048",
    "4:3": "2304x1728",
    "3:4": "1728x2304",
    "16:9": "2848x1600",
    "9:16": "1600x2848",
    "3:2": "2496x1664",
    "2:3": "1664x2496",
    "21:9": "3136x1344",
}

DIFFICULTY_GRID_SIZE = {
    "mythology": 5,
    "xia_shang_zhou": 5,
    "spring_autumn": 10,
    "qin_han": 10,
    "three_kingdoms": 10,
    "sui_tang": 10,
    "song_yuan": 15,
    "ming_qing": 15,
    "modern": 15,
    "contemporary": 15,
}


def get_size_for_grid(x_cells, y_cells):
    from math import gcd
    g = gcd(x_cells, y_cells)
    ratio_w = x_cells // g
    ratio_h = y_cells // g
    ratio_key = f"{ratio_w}:{ratio_h}"
    if ratio_key in ASPECT_RATIO_SIZES:
        return ASPECT_RATIO_SIZES[ratio_key]
    return "2K"


def generate_jimeng_image(prompt, size="2K"):
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": MODEL,
        "prompt": prompt,
        "sequential_image_generation": "disabled",
        "response_format": "url",
        "size": size,
        "stream": False,
        "watermark": False
    }

    try:
        print(f"正在调用API生成图片 (size={size})...")
        response = requests.post(API_BASE_URL, headers=headers, json=payload, timeout=120)
        response.raise_for_status()
        result = response.json()

        if result.get("data") and isinstance(result["data"], list) and len(result["data"]) > 0:
            if result["data"][0].get("url"):
                return result["data"][0]["url"]

        print(f"API调用失败: {result.get('error', {}).get('message', '未知错误')}")
        return None
    except requests.exceptions.RequestException as e:
        print(f"请求异常: {str(e)}")
        return None


def download_image(url, save_path):
    try:
        response = requests.get(url)
        response.raise_for_status()
        img = Image.open(BytesIO(response.content))
        img.save(save_path)
        print(f"图片已保存: {save_path} ({img.size[0]}x{img.size[1]})")
        return True
    except Exception as e:
        print(f"下载图片失败: {str(e)}")
        return False


def main():
    all_stories = {
        "xia_shang_zhou": {
            "era_name": "夏商周",
            "stories": {
                "dayu": {
                    "name": "大禹治水",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["青铜鼎", "洪水"],
                    "prompt": (
                        "大禹治水，中国传统山水画风格，一幅完整的故事场景画。"
                        "画面中央大禹手持耒耜站在水边，周围是汹涌的洪水，远处有青铜鼎，"
                        "天空阴云密布，展现人与自然搏斗的壮丽场景。"
                        "浓墨重彩，传统中国画技法，完整构图，高分辨率"
                    )
                },
                "taigong": {
                    "name": "姜太公钓鱼",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["鱼钩", "钓竿"],
                    "prompt": (
                        "姜太公钓鱼，中国传统工笔画风格，一幅完整的故事场景画。"
                        "画面中央姜太公坐在渭水边，手持直钩鱼竿垂钓，鱼钩悬在水面三尺之上，"
                        "旁边放着斗笠，远处是青山绿水，意境悠远。"
                        "细腻笔触，传统东方美学，完整构图，高分辨率"
                    )
                },
                "fenghuo": {
                    "name": "烽火戏诸侯",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["烽火", "战鼓"],
                    "prompt": (
                        "烽火戏诸侯，中国传统壁画风格，一幅完整的故事场景画。"
                        "画面中央烽火台燃起熊熊烈火，周幽王和褒姒在城楼上观看，"
                        "远处诸侯军队赶来，城下有战鼓，戏剧性场景。"
                        "粗犷线条，历史感强，完整构图，高分辨率"
                    )
                }
            }
        },
        "spring_autumn": {
            "era_name": "春秋战国",
            "stories": {
                "wanbi": {
                    "name": "完璧归赵",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["玉璧", "地图"],
                    "prompt": (
                        "完璧归赵，中国传统水墨画风格，一幅完整的故事场景画。"
                        "画面中央蔺相如手持和氏璧站在秦王面前，怒发冲冠，"
                        "旁边有秦国宫殿和地图卷轴，展现智勇双全的场景。"
                        "浓墨重彩，传统中国画技法，完整构图，高分辨率"
                    )
                },
                "goujian": {
                    "name": "卧薪尝胆",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["宝剑", "苦胆"],
                    "prompt": (
                        "卧薪尝胆，中国传统工笔画风格，一幅完整的故事场景画。"
                        "画面中央越王勾践坐在柴草上，面前悬挂着苦胆，旁边放着宝剑，"
                        "背景是简陋的居室，展现隐忍图强的精神。"
                        "细腻笔触，传统东方美学，完整构图，高分辨率"
                    )
                },
                "jingke": {
                    "name": "荆轲刺秦",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["匕首", "地图"],
                    "prompt": (
                        "荆轲刺秦王，中国传统壁画风格，一幅完整的故事场景画。"
                        "画面中央荆轲手持匕首刺向秦王，秦王惊慌躲避，"
                        "旁边有展开的地图，展现惊心动魄的瞬间。"
                        "粗犷线条，敦煌壁画风格，完整构图，高分辨率"
                    )
                }
            }
        },
        "qin_han": {
            "era_name": "秦汉",
            "stories": {
                "qinshi": {
                    "name": "秦始皇统一",
                    "x_cells": 3,
                    "y_cells": 1,
                    "objects": ["长城", "玉玺", "秦剑"],
                    "prompt": (
                        "秦始皇统一中国，中国传统壁画风格，一幅完整的故事场景画。"
                        "画面中央秦始皇身披龙袍站在宫殿前，身后是万里长城，"
                        "手中持有传国玉玺，旁边有青铜剑，展现帝王威严。"
                        "浓墨重彩，历史感强，完整构图，高分辨率"
                    )
                },
                "zhangqian": {
                    "name": "张骞出使",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["骆驼", "丝绸"],
                    "prompt": (
                        "张骞出使西域，中国传统工笔画风格，一幅完整的故事场景画。"
                        "画面中央张骞骑着骆驼走在丝绸之路上，手中持有丝绸，"
                        "背景是沙漠和商队，展现开拓精神。"
                        "细腻笔触，传统东方美学，完整构图，高分辨率"
                    )
                },
                "zhaojun": {
                    "name": "昭君出塞",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["琵琶", "大雁"],
                    "prompt": (
                        "昭君出塞，中国传统工笔画风格，一幅完整的故事场景画。"
                        "画面中央王昭君怀抱琵琶骑在马上，天空中有大雁飞过，"
                        "背景是塞外风光，展现美人远嫁的凄美场景。"
                        "细腻笔触，传统东方美学，完整构图，高分辨率"
                    )
                }
            }
        },
        "three_kingdoms": {
            "era_name": "三国两晋南北朝",
            "stories": {
                "caochuan": {
                    "name": "草船借箭",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["箭", "草船"],
                    "prompt": (
                        "草船借箭，中国传统水墨画风格，一幅完整的故事场景画。"
                        "画面中央诸葛亮站在草船上，船的两边扎满草人，"
                        "万箭齐发射向草船，江面大雾弥漫，展现智谋。"
                        "浓墨重彩，传统中国画技法，完整构图，高分辨率"
                    )
                },
                "taoyuan": {
                    "name": "桃园结义",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["桃树", "酒坛"],
                    "prompt": (
                        "桃园三结义，中国传统工笔画风格，一幅完整的故事场景画。"
                        "画面中央刘备、关羽、张飞在桃园中结拜，焚香跪拜，"
                        "旁边有盛开的桃花和酒坛，展现兄弟情义。"
                        "细腻笔触，传统东方美学，完整构图，高分辨率"
                    )
                },
                "wenji": {
                    "name": "闻鸡起舞",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["公鸡", "宝剑"],
                    "prompt": (
                        "闻鸡起舞，中国传统水墨画风格，一幅完整的故事场景画。"
                        "画面中央祖逖和刘琨在晨光中舞剑，旁边有公鸡啼鸣，"
                        "展现励志图强的精神，背景是简朴的庭院。"
                        "浓墨重彩，传统中国画技法，完整构图，高分辨率"
                    )
                }
            }
        },
        "sui_tang": {
            "era_name": "隋唐",
            "stories": {
                "xuanzang": {
                    "name": "玄奘西行",
                    "x_cells": 3,
                    "y_cells": 1,
                    "objects": ["佛塔", "经卷", "禅杖"],
                    "prompt": (
                        "玄奘西行取经，中国传统工笔画风格，一幅完整的故事场景画。"
                        "画面中央玄奘法师背着经卷行走在沙漠中，手持禅杖，"
                        "远处有佛塔，展现求法的艰辛与坚定。"
                        "细腻笔触，佛教艺术风格，完整构图，高分辨率"
                    )
                },
                "libai": {
                    "name": "李白醉酒",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["酒杯", "明月"],
                    "prompt": (
                        "李白醉酒，中国传统水墨画风格，一幅完整的故事场景画。"
                        "画面中央李白举杯邀明月，醉卧在花间，"
                        "月光洒落，展现诗仙豪放飘逸的气质。"
                        "水墨淋漓，意境悠远，完整构图，高分辨率"
                    )
                },
                "wencheng": {
                    "name": "文成公主入藏",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["佛像", "寺庙"],
                    "prompt": (
                        "文成公主入藏，中国传统工笔画风格，一幅完整的故事场景画。"
                        "画面中央文成公主坐在马车中，手持佛像，"
                        "背景是布达拉宫和雪山，展现汉藏和亲的场景。"
                        "细腻笔触，藏汉融合风格，完整构图，高分辨率"
                    )
                }
            }
        },
        "song_yuan": {
            "era_name": "宋元",
            "stories": {
                "yuefei": {
                    "name": "岳飞抗金",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["长枪", "盾牌"],
                    "prompt": (
                        "岳飞抗金，中国传统水墨画风格，一幅完整的故事场景画。"
                        "画面中央岳飞手持长枪指挥作战，身后是岳家军，"
                        "军旗飘扬，展现精忠报国的英雄气概。"
                        "浓墨重彩，传统中国画技法，完整构图，高分辨率"
                    )
                },
                "huozi": {
                    "name": "活字印刷",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["活字", "书卷"],
                    "prompt": (
                        "毕昇发明活字印刷术，中国传统工笔画风格，一幅完整的故事场景画。"
                        "画面中央毕昇正在排版活字，旁边有印刷好的书卷，"
                        "展现古代科技发明的场景。"
                        "细腻笔触，传统东方美学，完整构图，高分辨率"
                    )
                },
                "marco": {
                    "name": "马可波罗来华",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["帆船", "指南针"],
                    "prompt": (
                        "马可波罗来华，中国传统工笔画风格，一幅完整的故事场景画。"
                        "画面中央马可波罗站在帆船上，手持指南针，"
                        "背景是元代港口和船队，展现东西方交流的场景。"
                        "细腻笔触，传统东方美学，完整构图，高分辨率"
                    )
                }
            }
        },
        "ming_qing": {
            "era_name": "明清",
            "stories": {
                "zhenghe": {
                    "name": "郑和下西洋",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["宝船", "罗盘"],
                    "prompt": (
                        "郑和下西洋，中国传统工笔画风格，一幅完整的故事场景画。"
                        "画面中央巨大的宝船航行在海上，郑和站在船头，"
                        "手持罗盘，船队浩浩荡荡，展现大明国威。"
                        "细腻笔触，传统东方美学，完整构图，高分辨率"
                    )
                },
                "kangqian": {
                    "name": "康乾盛世",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["龙袍", "玉玺"],
                    "prompt": (
                        "康乾盛世，中国传统工笔画风格，一幅完整的故事场景画。"
                        "画面中央康熙皇帝身穿龙袍坐在龙椅上，手持玉玺，"
                        "背景是宏伟的宫殿，展现盛世景象。"
                        "细腻笔触，宫廷画风格，完整构图，高分辨率"
                    )
                },
                "linzexu": {
                    "name": "林则徐销烟",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["烟管", "烈火"],
                    "prompt": (
                        "虎门销烟，中国传统水墨画风格，一幅完整的故事场景画。"
                        "画面中央林则徐指挥销毁鸦片，浓烟滚滚，"
                        "百姓围观欢呼，展现民族气节。"
                        "浓墨重彩，历史感强，完整构图，高分辨率"
                    )
                }
            }
        },
        "modern": {
            "era_name": "近现代",
            "stories": {
                "xinhai": {
                    "name": "辛亥革命",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["旗帜", "步枪"],
                    "prompt": (
                        "辛亥革命，写实风格插画，一幅完整的故事场景画。"
                        "画面中央革命军举着旗帜冲锋，手持步枪，"
                        "武昌城背景，展现推翻帝制的壮举。"
                        "写实风格，历史感强，完整构图，高分辨率"
                    )
                },
                "wusi": {
                    "name": "五四运动",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["书籍", "火炬"],
                    "prompt": (
                        "五四运动，写实风格插画，一幅完整的故事场景画。"
                        "画面中央青年学生举着标语和火炬游行，"
                        "背景是天安门，展现爱国热情。"
                        "写实风格，历史感强，完整构图，高分辨率"
                    )
                },
                "changzheng": {
                    "name": "长征",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["红星", "雪山"],
                    "prompt": (
                        "红军长征，写实风格插画，一幅完整的故事场景画。"
                        "画面中央红军战士攀登雪山，红旗飘扬，"
                        "展现坚韧不拔的精神。"
                        "写实风格，历史感强，完整构图，高分辨率"
                    )
                }
            }
        },
        "contemporary": {
            "era_name": "当代",
            "stories": {
                "liangdan": {
                    "name": "两弹一星",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["火箭", "红星"],
                    "prompt": (
                        "两弹一星，写实风格插画，一幅完整的故事场景画。"
                        "画面中央火箭发射升空，蘑菇云升起，"
                        "展现中国核工业和航天事业的成就。"
                        "写实风格，科技感强，完整构图，高分辨率"
                    )
                },
                "gaige": {
                    "name": "改革开放",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["高楼", "麦穗"],
                    "prompt": (
                        "改革开放，写实风格插画，一幅完整的故事场景画。"
                        "画面中央现代化的城市高楼林立，旁边是丰收的麦田，"
                        "展现经济腾飞和农业发展。"
                        "写实风格，现代感强，完整构图，高分辨率"
                    )
                },
                "hangtian": {
                    "name": "航天工程",
                    "x_cells": 2,
                    "y_cells": 1,
                    "objects": ["飞船", "月球"],
                    "prompt": (
                        "中国航天工程，写实风格插画，一幅完整的故事场景画。"
                        "画面中央神舟飞船飞向月球，背景是浩瀚星空，"
                        "展现中国探索太空的成就。"
                        "写实风格，科技感强，完整构图，高分辨率"
                    )
                }
            }
        }
    }

    total_stories = 0
    success_count = 0
    failed_stories = []

    for era_id, era_info in all_stories.items():
        output_dir = f"h:/Work/MyProject/ChineseMemory/assets/images/illustrations/{era_id}"
        os.makedirs(output_dir, exist_ok=True)

        print("\n" + "=" * 80)
        print(f"正在生成【{era_info['era_name']}】时代插图")
        print(f"难度阶段: {DIFFICULTY_GRID_SIZE[era_id]}x{DIFFICULTY_GRID_SIZE[era_id]}")
        print("=" * 80)

        for story_id, story_info in era_info["stories"].items():
            total_stories += 1
            x = story_info['x_cells']
            y = story_info['y_cells']
            api_size = get_size_for_grid(x, y)

            print(f"\n{'='*60}")
            print(f"故事: {story_info['name']} ({story_id})")
            print(f"布局: {x}x{y} 个 {DIFFICULTY_GRID_SIZE[era_id]}x{DIFFICULTY_GRID_SIZE[era_id]} 网格区域")
            print(f"API尺寸参数: {api_size} (宽高比 {x}:{y})")
            print(f"核心物体: {', '.join(story_info['objects'])}")
            print(f"提示词: {story_info['prompt']}")
            print(f"{'='*60}")

            image_url = generate_jimeng_image(story_info['prompt'], size=api_size)
            if image_url:
                print(f"生成成功: {image_url}")
                save_path = os.path.join(output_dir, f"{story_id}.png")
                if download_image(image_url, save_path):
                    success_count += 1
                else:
                    failed_stories.append(f"{era_info['era_name']} - {story_info['name']}")
            else:
                print(f"生成失败: {story_id}")
                failed_stories.append(f"{era_info['era_name']} - {story_info['name']}")

    print("\n" + "=" * 80)
    print("所有时代插图生成完成！")
    print("=" * 80)
    print(f"\n生成结果摘要:")
    print(f"  时代数量: {len(all_stories)}个")
    print(f"  故事插图总数: {total_stories}张")
    print(f"  成功: {success_count}张")
    print(f"  失败: {len(failed_stories)}张")
    if failed_stories:
        print(f"  失败列表:")
        for failed in failed_stories:
            print(f"    - {failed}")


if __name__ == "__main__":
    main()
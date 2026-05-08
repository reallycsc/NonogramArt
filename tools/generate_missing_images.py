import os
import requests
from PIL import Image
from io import BytesIO

API_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3/images/generations"
API_KEY = "ark-769a3f8a-9ceb-4556-ae95-d882f7966850-2be63"
MODEL = "doubao-seedream-4-5-251128"


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
    missing_stories = {
        "ming_qing": {
            "era_name": "明清",
            "stories": {
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

    for era_id, era_info in missing_stories.items():
        output_dir = f"h:/Work/MyProject/ChineseMemory/assets/images/illustrations/{era_id}"
        os.makedirs(output_dir, exist_ok=True)

        print("\n" + "=" * 80)
        print(f"正在生成【{era_info['era_name']}】时代插图")
        print("=" * 80)

        for story_id, story_info in era_info["stories"].items():
            total_stories += 1
            x = story_info['x_cells']
            y = story_info['y_cells']

            print(f"\n{'='*60}")
            print(f"故事: {story_info['name']} ({story_id})")
            print(f"布局: {x}x{y} 网格区域")
            print(f"核心物体: {', '.join(story_info['objects'])}")
            print(f"{'='*60}")

            image_url = generate_jimeng_image(story_info['prompt'], size="2K")
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
    print("缺失插图生成完成！")
    print("=" * 80)
    print(f"\n生成结果摘要:")
    print(f"  时代数量: {len(missing_stories)}个")
    print(f"  故事插图总数: {total_stories}张")
    print(f"  成功: {success_count}张")
    print(f"  失败: {len(failed_stories)}张")
    if failed_stories:
        print(f"  失败列表:")
        for failed in failed_stories:
            print(f"    - {failed}")


if __name__ == "__main__":
    main()
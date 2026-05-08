import os
import requests
from PIL import Image
from io import BytesIO

API_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3/images/generations"
API_KEY = "ark-769a3f8a-9ceb-4556-ae95-d882f7966850-2be63"
MODEL = "doubao-seedream-4-5-251128"

OUTPUT_DIR = "h:/Work/MyProject/ChineseMemory/assets/images/icons"


def generate_jimeng_image(prompt, size="2048x2048"):
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


def generate_humanities_history_album_icons():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    COLORS = "朱砂红和鎏金配色"
    BACKGROUND = "纯色背景（#F5F0E8宣纸白）"

    albums = [
        {
            "id": "chinese_history",
            "name": "中国通史",
            "icon": "album_chinese_history.png",
            "prompt": f"长城和兵马俑组合图案，中国风卡通风格，{BACKGROUND}，{COLORS}，简洁图标设计，方形构图，无文字，高清分辨率"
        },
        {
            "id": "world_history",
            "name": "世界通史",
            "icon": "album_world_history.png",
            "prompt": f"地球仪和世界地图组合图案，中国风卡通风格，{BACKGROUND}，{COLORS}，简洁图标设计，方形构图，无文字，高清分辨率"
        },
        {
            "id": "asian_civilization",
            "name": "亚洲文明史",
            "icon": "album_asian_civilization.png",
            "prompt": f"泰姬陵和宝塔组合图案，中国风卡通风格，{BACKGROUND}，{COLORS}，简洁图标设计，方形构图，无文字，高清分辨率"
        },
        {
            "id": "european_civilization",
            "name": "欧洲文明史",
            "icon": "album_european_civilization.png",
            "prompt": f"罗马斗兽场和城堡组合图案，中国风卡通风格，{BACKGROUND}，{COLORS}，简洁图标设计，方形构图，无文字，高清分辨率"
        },
        {
            "id": "africa_america_civilization",
            "name": "非洲与美洲文明史",
            "icon": "album_africa_america.png",
            "prompt": f"金字塔和玛雅遗迹组合图案，中国风卡通风格，{BACKGROUND}，{COLORS}，简洁图标设计，方形构图，无文字，高清分辨率"
        },
        {
            "id": "war_military",
            "name": "战争与军事史",
            "icon": "album_war_military.png",
            "prompt": f"古代兵器和盾牌组合图案，中国风卡通风格，{BACKGROUND}，{COLORS}，简洁图标设计，方形构图，无文字，高清分辨率"
        },
        {
            "id": "political_system",
            "name": "政治与制度史",
            "icon": "album_political_system.png",
            "prompt": f"印章和法典组合图案，中国风卡通风格，{BACKGROUND}，{COLORS}，简洁图标设计，方形构图，无文字，高清分辨率"
        },
        {
            "id": "economic_trade",
            "name": "经济与贸易史",
            "icon": "album_economic_trade.png",
            "prompt": f"古钱币和商船组合图案，中国风卡通风格，{BACKGROUND}，{COLORS}，简洁图标设计，方形构图，无文字，高清分辨率"
        },
        {
            "id": "world_heritage",
            "name": "世界文化遗产",
            "icon": "album_world_heritage.png",
            "prompt": f"世界遗产标志和古建筑组合图案，中国风卡通风格，{BACKGROUND}，{COLORS}，简洁图标设计，方形构图，无文字，高清分辨率"
        },
        {
            "id": "chinese_heritage",
            "name": "中国文化遗产",
            "icon": "album_chinese_heritage.png",
            "prompt": f"故宫和青花瓷组合图案，中国风卡通风格，{BACKGROUND}，{COLORS}，简洁图标设计，方形构图，无文字，高清分辨率"
        },
        {
            "id": "archaeology",
            "name": "考古发现与发掘",
            "icon": "album_archaeology.png",
            "prompt": f"考古铲和出土文物组合图案，中国风卡通风格，{BACKGROUND}，{COLORS}，简洁图标设计，方形构图，无文字，高清分辨率"
        },
        {
            "id": "historical_mysteries",
            "name": "历史未解之谜",
            "icon": "album_historical_mysteries.png",
            "prompt": f"神秘符号和古老手稿组合图案，中国风卡通风格，{BACKGROUND}，{COLORS}，简洁图标设计，方形构图，无文字，高清分辨率"
        }
    ]

    print("=" * 80)
    print("人文历史书架 - 书籍图标生成（纯图案模式）")
    print("=" * 80)

    success_count = 0
    fail_count = 0

    for album in albums:
        print(f"\n{'='*60}")
        print(f"书籍: {album['name']} ({album['id']})")
        print(f"图标文件: {album['icon']}")
        print(f"提示词: {album['prompt']}")
        print(f"{'='*60}")

        image_url = generate_jimeng_image(album['prompt'], size="2048x2048")
        if image_url:
            print(f"生成成功: {image_url}")
            save_path = os.path.join(OUTPUT_DIR, album['icon'])
            if download_image(image_url, save_path):
                success_count += 1
            else:
                fail_count += 1
        else:
            print(f"生成失败: {album['id']}")
            fail_count += 1

    print("\n" + "=" * 80)
    print("人文历史书架 - 书籍图标生成完成！")
    print("=" * 80)
    print(f"\n生成结果摘要:")
    print(f"  书籍总数: {len(albums)}")
    print(f"  成功: {success_count}")
    print(f"  失败: {fail_count}")
    print(f"  输出目录: {OUTPUT_DIR}")
    print(f"  配色方案: {COLORS}")
    print(f"  背景色: {BACKGROUND}")


if __name__ == "__main__":
    generate_humanities_history_album_icons()
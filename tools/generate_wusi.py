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
    output_dir = "h:/Work/MyProject/ChineseMemory/assets/images/illustrations/modern"
    os.makedirs(output_dir, exist_ok=True)

    story_info = {
        "name": "五四运动",
        "story_id": "wusi",
        "prompt": (
            "五四运动，写实风格插画，一幅完整的故事场景画。"
            "画面中央青年学生举着标语和火炬游行，"
            "背景是天安门，展现爱国热情。"
            "写实风格，历史感强，完整构图，高分辨率"
        )
    }

    print(f"生成故事: {story_info['name']} ({story_info['story_id']})")
    image_url = generate_jimeng_image(story_info['prompt'], size="2K")
    
    if image_url:
        print(f"生成成功: {image_url}")
        save_path = os.path.join(output_dir, f"{story_info['story_id']}.png")
        if download_image(image_url, save_path):
            print("生成完成！")
        else:
            print("下载失败")
    else:
        print("生成失败")


if __name__ == "__main__":
    main()
import os
import sys
import json
import requests
from PIL import Image
from io import BytesIO

API_BASE_URL = 'https://ark.cn-beijing.volces.com/api/v3/images/generations'
API_KEY = 'ark-769a3f8a-9ceb-4556-ae95-d882f7966850-2be63'
MODEL = 'doubao-seedream-4-5-251128'

STYLE_PREFIX = '中国风卡通插画风格，一幅完整的故事场景画。'
STYLE_SUFFIX = '色彩明快温暖，线条圆润，卡通造型可爱，完整构图，高分辨率'

def generate_jimeng_image(prompt, size='2K'):
    headers = {
        'Authorization': f'Bearer {API_KEY}',
        'Content-Type': 'application/json'
    }
    full_prompt = STYLE_PREFIX + prompt + STYLE_SUFFIX
    payload = {
        'model': MODEL,
        'prompt': full_prompt,
        'sequential_image_generation': 'disabled',
        'response_format': 'url',
        'size': size,
        'stream': False,
        'watermark': False
    }
    try:
        print(f'  调用API生成图片 (size={size})...')
        response = requests.post(API_BASE_URL, headers=headers, json=payload, timeout=180)
        response.raise_for_status()
        result = response.json()
        if result.get('data') and isinstance(result['data'], list) and len(result['data']) > 0:
            if result['data'][0].get('url'):
                return result['data'][0]['url']
        print(f'  API调用失败: {result.get("error", {}).get("message", "未知错误")}')
        return None
    except requests.exceptions.RequestException as e:
        print(f'  请求异常: {str(e)}')
        return None

def download_image(url, save_path):
    try:
        response = requests.get(url, timeout=60)
        response.raise_for_status()
        img = Image.open(BytesIO(response.content))
        img.save(save_path)
        print(f'  图片已保存: {save_path} ({img.size[0]}x{img.size[1]})')
        return True
    except Exception as e:
        print(f'  下载图片失败: {str(e)}')
        return False

def main():
    output_dir = 'h:/Work/MyProject/ChineseMemory/assets/images/illustrations/yuangu'
    os.makedirs(output_dir, exist_ok=True)
    
    story = {
        'id': 'huangdi',
        'title': '黄帝部落联盟',
        'objects': ['龙旗', '战鼓', '部落'],
        'prompt': (
            '炎黄二帝站在高台上，手持龙旗和熊旗，'
            '身后是联合的部落族人，战鼓声声，旗帜飘扬，'
            '展现华夏文明起源的壮丽场景。'
        )
    }
    
    print(f'生成图片: {story["title"]}')
    print(f'核心物体: {", ".join(story["objects"])}')
    
    save_path = os.path.join(output_dir, f'{story["id"]}.png')
    
    if os.path.exists(save_path):
        os.remove(save_path)
        print('  删除已存在的文件')
    
    image_url = generate_jimeng_image(story['prompt'], size='2496x1664')
    if image_url:
        print(f'  生成成功: {image_url}')
        if download_image(image_url, save_path):
            print('  图片下载成功')
        else:
            print('  图片下载失败')
    else:
        print('  生成失败')

if __name__ == '__main__':
    main()

import base64
import os
from PIL import Image
import io

images = [
    'chapter1_01_yuanmou.png',
    'chapter2_18_kongzi.png',
    'chapter3_24_qinshihuang.png',
    'chapter3_26_bingmayong.png',
    'chapter4_41_chibi.png',
    'chapter5_54_taizong.png',
    'chapter5_60_libai.png',
    'chapter6_77_qingmingtu.png',
    'chapter7_79_hubilie.png',
    'chapter8_88_zijincheng.png',
    'chapter9_96_qianlong.png',
]

for img in images:
    if os.path.exists(img):
        with Image.open(img) as im:
            w, h = im.size
            new_w, new_h = 300, int(300 * h / w)
            im.thumbnail((new_w, new_h), Image.Resampling.LANCZOS)

            buf = io.BytesIO()
            im.convert('RGB').save(buf, 'JPEG', quality=75)
            b64 = base64.b64encode(buf.getvalue()).decode()

            print(f'**{img}**')
            print(f'![{img}](data:image/jpeg;base64,{b64})')
            print()

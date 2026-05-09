import os
import sys
from suno_music import SunoMusicGenerator

def generate_chinese_history_bgm():
    output_path = "assets/music"
    os.makedirs(output_path, exist_ok=True)
    
    try:
        generator = SunoMusicGenerator()
        
        print("🎵 正在为《中国通史》生成背景音乐...")
        print("=" * 60)
        print("音乐风格：中国传统古典风格，庄重典雅")
        print("乐器：古筝、笛子、二胡、编钟")
        print("意境：历史悠久、文明传承、庄重肃穆")
        print("=" * 60)
        
        prompt = """
        Epic Chinese traditional instrumental music, ancient China historical theme, 
        featuring guzheng (Chinese zither), dizi (bamboo flute), erhu (fiddle), and bianzhong (bronze bells).
        The music should evoke a sense of grand history, ancient civilizations, and cultural heritage.
        Majestic and solemn mood, with gentle flowing melodies representing the long river of history.
        Suitable as background music for documentary about Chinese history, educational content.
        No vocals, pure instrumental.
        """
        
        title = "Chinese_History_Epic"
        
        result = generator.create_song(
            prompt=prompt,
            title=title,
            genre="traditional chinese",
            mood="epic",
            instrumental=True,
            duration=180,
            save_path=output_path
        )
        
        print("\n🎉 背景音乐生成完成！")
        print(f"📁 文件位置: {output_path}/{title}.mp3")
        print(f"📊 时长: {result.get('duration', 'N/A')} 秒")
        
        return result
        
    except Exception as e:
        print(f"❌ 生成失败: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    generate_chinese_history_bgm()
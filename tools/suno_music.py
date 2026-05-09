import requests
import time
import os
import json
from dotenv import load_dotenv
from typing import Optional, Dict, Any, List, Union

load_dotenv()

class SunoClient:
    def __init__(self, api_key: Optional[str] = None, cookie: Optional[str] = None):
        self.api_key = api_key or os.getenv("SUNO_API_KEY")
        self.cookie = cookie or os.getenv("SUNO_COOKIE")
        
        if self.api_key and self.api_key.strip().lower() in ["your_suno_api_key_here", ""]:
            self.api_key = None
        if self.cookie and self.cookie.strip().lower() in ["your_suno_session_cookie_here", ""]:
            self.cookie = None
        
        self.auth_type = None
        if self.cookie:
            self.auth_type = "cookie"
            self.base_url = "http://localhost:3000"
            self.headers = {
                "Content-Type": "application/json"
            }
        elif self.api_key:
            self.auth_type = "api_key"
            self.base_url = os.getenv("SUNO_API_BASE_URL", "https://api.sunoapi.org/api/v1")
            self.headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
        else:
            raise ValueError("Either api_key or cookie must be provided.")
        
        self.default_model = os.getenv("SUNO_DEFAULT_MODEL", "chirp-v4")
        self.default_duration = int(os.getenv("SUNO_DEFAULT_DURATION", 120))

    def _request(self, method: str, endpoint: str, **kwargs) -> Dict[str, Any]:
        url = f"{self.base_url}{endpoint}"
        
        try:
            response = requests.request(method, url, headers=self.headers, timeout=30, **kwargs)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            try:
                error_data = response.json() if response else {}
                error_msg = error_data.get("detail", error_data.get("msg", str(e)))
            except:
                error_msg = str(e)
            raise Exception(f"API request failed: {error_msg}")

    def generate_music(
        self,
        prompt: str,
        title: Optional[str] = None,
        genre: Optional[str] = None,
        instrumental: bool = False,
        model: Optional[str] = None,
        duration: Optional[int] = None,
        tags: Optional[str] = None
    ) -> Dict[str, Any]:
        if self.auth_type == "api_key":
            payload = {
                "prompt": prompt,
                "instrumental": instrumental,
                "model": model or self.default_model,
                "duration": duration or self.default_duration
            }
            if title:
                payload["title"] = title
            if genre:
                payload["genre"] = genre
            
            return self._request("POST", "/generate", json=payload)
        
        else:
            payload = {
                "prompt": prompt,
                "make_instrumental": instrumental,
                "mv": model or self.default_model,
                "duration": duration or self.default_duration
            }
            if title:
                payload["title"] = title
            if tags:
                payload["tags"] = tags
            
            return self._request("POST", "/api/generate/v2", json=payload)

    def generate_music_custom(
        self,
        prompt: str,
        title: str,
        lyrics: Optional[str] = None,
        **kwargs
    ) -> Dict[str, Any]:
        if lyrics:
            kwargs["prompt"] = lyrics
        
        result = self.generate_music(
            prompt=prompt,
            title=title,
            **kwargs
        )
        return result

    def generate_lyrics(self, prompt: str) -> Dict[str, Any]:
        if self.auth_type == "api_key":
            return self._request("POST", "/generate/lyrics", json={"prompt": prompt})
        else:
            return self._request("POST", "/api/lyrics", json={"prompt": prompt})

    def get_generation_details(self, task_id: str) -> Dict[str, Any]:
        if self.auth_type == "api_key":
            return self._request("GET", f"/generate/{task_id}")
        else:
            return self._request("GET", f"/api/feed/{task_id}")

    def poll_result(
        self,
        task_id: str,
        timeout: int = 300,
        poll_interval: int = 5
    ) -> Dict[str, Any]:
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            result = self.get_generation_details(task_id)
            
            if self.auth_type == "api_key":
                if result.get("code") == 200:
                    data = result.get("data", {})
                    status = data.get("status", "").lower()
                    
                    if status == "completed":
                        return result
                    elif status == "failed":
                        raise Exception(f"Generation failed: {data.get('error', 'Unknown error')}")
                    elif status == "running":
                        print(f"Generation in progress... ({data.get('progress', 0)}%)")
            else:
                if isinstance(result, dict):
                    status = result.get("status", "").lower()
                    
                    if status == "complete":
                        return result
                    elif status == "failed":
                        raise Exception(f"Generation failed: {result.get('error', 'Unknown error')}")
                    elif status in ["pending", "generating"]:
                        print(f"Generation in progress...")
            
            time.sleep(poll_interval)
        
        raise TimeoutError(f"Generation timed out after {timeout} seconds")

    def download_audio(
        self,
        audio_url: str,
        save_path: str,
        filename: Optional[str] = None
    ) -> str:
        if not filename:
            filename = os.path.basename(audio_url)
            if not filename or not filename.endswith(('.mp3', '.wav')):
                filename = f"audio_{int(time.time())}.mp3"
        
        full_path = os.path.join(save_path, filename)
        os.makedirs(save_path, exist_ok=True)
        
        response = requests.get(audio_url, stream=True, timeout=60)
        response.raise_for_status()
        
        with open(full_path, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        return full_path

    def get_remaining_credits(self) -> int:
        if self.auth_type == "api_key":
            result = self._request("GET", "/generate/credit")
            return result.get("data", 0)
        else:
            result = self._request("GET", "/user/info")
            return result.get("credits", {}).get("available", 0)


class SunoMusicGenerator:
    def __init__(self, api_key: Optional[str] = None, cookie: Optional[str] = None):
        self.client = SunoClient(api_key, cookie)
    
    def create_song(
        self,
        prompt: str,
        title: str,
        lyrics: Optional[str] = None,
        genre: Optional[str] = None,
        mood: Optional[str] = None,
        instrumental: bool = False,
        duration: int = 120,
        vocal_gender: Optional[str] = None,
        save_path: str = "./output"
    ) -> Dict[str, Any]:
        print(f"🎵 Creating song: {title}")
        print(f"📝 Prompt: {prompt}")
        
        if lyrics:
            result = self.client.generate_music_custom(
                prompt=prompt,
                title=title,
                lyrics=lyrics,
                genre=genre,
                instrumental=instrumental,
                duration=duration
            )
        else:
            tags = []
            if genre:
                tags.append(genre)
            if mood:
                tags.append(mood)
            
            result = self.client.generate_music(
                prompt=prompt,
                title=title,
                genre=genre,
                instrumental=instrumental,
                duration=duration,
                tags=",".join(tags) if tags else None
            )
        
        if self.client.auth_type == "api_key":
            if result.get("code") == 200:
                task_id = result["data"]["taskId"]
                print(f"✅ Task created: {task_id}")
        else:
            if "id" in result:
                task_id = result["id"]
                print(f"✅ Task created: {task_id}")
            elif isinstance(result, list) and len(result) > 0:
                task_id = result[0]["id"]
                print(f"✅ Task created: {task_id}")
            else:
                raise Exception("Failed to get task ID from response")
        
        print("⏳ Waiting for generation...")
        final_result = self.client.poll_result(task_id)
        
        data = final_result.get("data", final_result)
        
        if isinstance(data, list):
            data = data[0]
        
        audio_url = None
        if self.client.auth_type == "api_key":
            audio_url = data.get("audioUrl")
        else:
            audio_url = data.get("audio_url")
        
        if audio_url:
            audio_path = self.client.download_audio(
                audio_url,
                save_path,
                f"{title.replace(' ', '_')}.mp3"
            )
            print(f"🎶 Audio saved to: {audio_path}")
            data["local_path"] = audio_path
        
        return data
    
    def create_background_music(
        self,
        mood: str = "relaxing",
        duration: int = 60,
        genre: str = "ambient",
        save_path: str = "./output"
    ) -> Dict[str, Any]:
        prompts = {
            "relaxing": f"A calming {genre} background music track, soothing and peaceful, perfect for meditation or study",
            "upbeat": f"An energetic {genre} background track, positive and motivating, ideal for workout or productivity",
            "cinematic": f"A dramatic cinematic {genre} score, epic and emotional, suitable for film trailers",
            "chill": f"A laid-back {genre} chill track, smooth and groovy, great for casual listening",
            "focus": f"A minimal {genre} focus music, clean and non-distracting, perfect for work or coding"
        }
        
        prompt = prompts.get(mood, prompts["relaxing"])
        title = f"{mood}_{genre}_background_{int(time.time())}"
        
        return self.create_song(
            prompt=prompt,
            title=title,
            genre=genre,
            instrumental=True,
            duration=duration,
            save_path=save_path
        )

    def check_balance(self) -> int:
        credits = self.client.get_remaining_credits()
        print(f"💰 Available credits: {credits}")
        return credits


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Suno AI Music Generator")
    parser.add_argument("--prompt", type=str, required=True, help="Music description prompt")
    parser.add_argument("--title", type=str, help="Song title")
    parser.add_argument("--lyrics", type=str, help="Custom lyrics")
    parser.add_argument("--genre", type=str, help="Music genre")
    parser.add_argument("--mood", type=str, help="Music mood")
    parser.add_argument("--instrumental", action="store_true", help="Generate instrumental only")
    parser.add_argument("--duration", type=int, default=120, help="Duration in seconds")
    parser.add_argument("--save-path", type=str, default="./output", help="Output directory")
    parser.add_argument("--check-balance", action="store_true", help="Check remaining credits")
    
    args = parser.parse_args()
    
    try:
        generator = SunoMusicGenerator()
        
        if args.check_balance:
            generator.check_balance()
            return
        
        result = generator.create_song(
            prompt=args.prompt,
            title=args.title or f"song_{int(time.time())}",
            lyrics=args.lyrics,
            genre=args.genre,
            mood=args.mood,
            instrumental=args.instrumental,
            duration=args.duration,
            save_path=args.save_path
        )
        
        print("\n📊 Generation Complete!")
        print(f"Title: {result.get('title', result.get('name', 'Unknown'))}")
        print(f"Audio URL: {result.get('audioUrl', result.get('audio_url', 'N/A'))}")
        print(f"Local Path: {result.get('local_path', 'N/A')}")
        print(f"Duration: {result.get('duration', 'N/A')} seconds")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
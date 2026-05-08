import os
import base64
from pathlib import Path
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

class GPTImageGenerator:
    def __init__(self):
        self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        self.default_params = {
            "model": os.getenv("DEFAULT_MODEL", "gpt-image-2"),
            "size": os.getenv("DEFAULT_SIZE", "1024x1024"),
            "quality": os.getenv("DEFAULT_QUALITY", "standard"),
            "n": int(os.getenv("DEFAULT_N", "1"))
        }

    def generate(self, prompt, **kwargs):
        params = {**self.default_params, **kwargs}
        params["prompt"] = prompt
        
        if "response_format" not in params:
            params["response_format"] = "url"
        
        response = self.client.images.generate(**params)
        return response

    def generate_and_save(self, prompt, output_dir="output", **kwargs):
        response = self.generate(prompt, **kwargs)
        
        out_path = Path(output_dir)
        out_path.mkdir(exist_ok=True, parents=True)
        
        results = []
        for i, image in enumerate(response.data):
            if response_format := kwargs.get("response_format", "url"):
                if response_format == "b64_json":
                    img_bytes = base64.b64decode(image.b64_json)
                    filename = out_path / f"image_{i}.png"
                    filename.write_bytes(img_bytes)
                    results.append({"type": "file", "path": str(filename)})
                else:
                    results.append({"type": "url", "url": image.url})
        
        return results

    def generate_batch(self, prompts, **kwargs):
        results = []
        for i, prompt in enumerate(prompts):
            try:
                response = self.generate(prompt, **kwargs)
                results.append({
                    "prompt": prompt,
                    "success": True,
                    "data": [img.url for img in response.data]
                })
            except Exception as e:
                results.append({
                    "prompt": prompt,
                    "success": False,
                    "error": str(e)
                })
        return results

if __name__ == "__main__":
    generator = GPTImageGenerator()
    
    example_prompt = "A beautiful sunset over a mountain lake, photorealistic, vibrant colors"
    
    print("Generating image...")
    try:
        results = generator.generate_and_save(
            example_prompt,
            n=2,
            size="1536x1024",
            quality="high",
            response_format="url"
        )
        print("Image generation successful!")
        for result in results:
            print(result)
    except Exception as e:
        print(f"Error: {e}")
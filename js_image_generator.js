require('dotenv').config();
const OpenAI = require('openai');
const fs = require('fs');
const path = require('path');
const https = require('https');
const { createWriteStream } = require('fs');

class GPTImageGenerator {
    constructor() {
        this.client = new OpenAI({
            apiKey: process.env.OPENAI_API_KEY
        });
        
        this.defaultParams = {
            model: process.env.DEFAULT_MODEL || 'gpt-image-2',
            size: process.env.DEFAULT_SIZE || '1024x1024',
            quality: process.env.DEFAULT_QUALITY || 'standard',
            n: parseInt(process.env.DEFAULT_N) || 1
        };
    }

    async generate(prompt, options = {}) {
        const params = { ...this.defaultParams, ...options, prompt };
        
        if (!params.response_format) {
            params.response_format = 'url';
        }
        
        const response = await this.client.images.generate(params);
        return response;
    }

    async downloadImage(url, outputPath) {
        return new Promise((resolve, reject) => {
            const file = createWriteStream(outputPath);
            https.get(url, (response) => {
                response.pipe(file);
                file.on('finish', () => {
                    file.close(() => resolve(outputPath));
                });
            }).on('error', (err) => {
                fs.unlink(outputPath, () => reject(err));
            });
        });
    }

    async generateAndSave(prompt, outputDir = 'output', options = {}) {
        const response = await this.generate(prompt, options);
        
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }
        
        const results = [];
        for (let i = 0; i < response.data.length; i++) {
            const image = response.data[i];
            
            if (options.response_format === 'b64_json') {
                const base64Data = image.b64_json;
                const buffer = Buffer.from(base64Data, 'base64');
                const filePath = path.join(outputDir, `image_${i}.png`);
                fs.writeFileSync(filePath, buffer);
                results.push({ type: 'file', path: filePath });
            } else {
                const filePath = path.join(outputDir, `image_${i}.png`);
                await this.downloadImage(image.url, filePath);
                results.push({ type: 'file', path: filePath });
            }
        }
        
        return results;
    }

    async generateBatch(prompts, options = {}) {
        const results = [];
        
        for (let i = 0; i < prompts.length; i++) {
            try {
                const response = await this.generate(prompts[i], options);
                results.push({
                    prompt: prompts[i],
                    success: true,
                    data: response.data.map(img => img.url)
                });
            } catch (error) {
                results.push({
                    prompt: prompts[i],
                    success: false,
                    error: error.message
                });
            }
        }
        
        return results;
    }
}

async function main() {
    const generator = new GPTImageGenerator();
    
    const examplePrompt = "A beautiful sunset over a mountain lake, photorealistic, vibrant colors";
    
    console.log("Generating image...");
    try {
        const results = await generator.generateAndSave(examplePrompt, 'output', {
            n: 2,
            size: '1536x1024',
            quality: 'high'
        });
        console.log("Image generation successful!");
        console.log(results);
    } catch (error) {
        console.error("Error:", error.message);
    }
}

if (require.main === module) {
    main();
}

module.exports = GPTImageGenerator;
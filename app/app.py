import os
import secrets
from flask import Flask, request, jsonify, redirect, render_template_string
from urllib.parse import urlparse
import boto3

app = Flask(__name__)

TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME', 'urls')
dynamodb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION', 'eu-west-2'))
table = dynamodb.Table(TABLE_NAME)

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>URL Shortener</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 2rem;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            max-width: 500px;
            width: 100%;
            text-align: center;
        }
        h1 {
            color: #333;
            margin-bottom: 1.5rem;
            font-size: 2rem;
        }
        .url-form {
            margin-bottom: 2rem;
        }
        input[type="url"] {
            width: 100%;
            padding: 1rem;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 1rem;
            margin-bottom: 1rem;
            transition: border-color 0.3s;
        }
        input[type="url"]:focus {
            outline: none;
            border-color: #667eea;
        }
        button {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 1rem 2rem;
            border-radius: 10px;
            font-size: 1rem;
            cursor: pointer;
            transition: transform 0.2s;
            width: 100%;
        }
        button:hover {
            transform: translateY(-2px);
        }
        .result {
            margin-top: 2rem;
            padding: 1rem;
            background: #f8f9fa;
            border-radius: 10px;
            display: none;
        }
        .short-url {
            color: #667eea;
            font-weight: bold;
            word-break: break-all;
        }
        .error {
            color: #e74c3c;
            margin-top: 1rem;
        }
        .copy-btn {
            background: #28a745;
            margin-top: 0.5rem;
            padding: 0.5rem 1rem;
            font-size: 0.9rem;
        }
        .footer {
            margin-top: 2rem;
            color: #666;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔗 URL Shortener</h1>
        <div class="url-form">
            <input type="url" id="urlInput" placeholder="Enter your long URL here..." required>
            <button onclick="shortenUrl()">Shorten It!</button>
        </div>
        
        <div id="result" class="result">
            <p>Your shortened URL:</p>
            <div id="shortUrl" class="short-url"></div>
            <button class="copy-btn" onclick="copyUrl()">📋 Copy URL</button>
        </div>
        
        <div id="error" class="error"></div>
        
        <div class="footer">
            <p>Built with Flask & AWS</p>
        </div>
    </div>

    <script>
        async function shortenUrl() {
            const url = document.getElementById('urlInput').value;
            const errorDiv = document.getElementById('error');
            const resultDiv = document.getElementById('result');
            
            errorDiv.textContent = '';
            resultDiv.style.display = 'none';
            
            if (!url) {
                errorDiv.textContent = 'Please enter a URL';
                return;
            }
            
            try {
                const response = await fetch('/shorten', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({url: url})
                });
                
                const data = await response.json();
                
                if (response.ok) {
                    document.getElementById('shortUrl').textContent = data.short_url;
                    resultDiv.style.display = 'block';
                } else {
                    errorDiv.textContent = data.error || 'Something went wrong';
                }
            } catch (error) {
                errorDiv.textContent = 'Network error. Please try again.';
            }
        }
        
        function copyUrl() {
            const shortUrl = document.getElementById('shortUrl').textContent;
            navigator.clipboard.writeText(shortUrl).then(() => {
                const btn = document.querySelector('.copy-btn');
                const originalText = btn.textContent;
                btn.textContent = '✅ Copied!';
                setTimeout(() => {
                    btn.textContent = originalText;
                }, 2000);
            });
        }
        
        document.getElementById('urlInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                shortenUrl();
            }
        });
    </script>
</body>
</html>
'''

def generate_short_code():
    return secrets.token_urlsafe(8)[:8]

def is_valid_url(url):
    try:
        result = urlparse(url)
        return all([result.scheme, result.netloc]) and result.scheme in ['http', 'https']
    except:
        return False

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/healthz')
def health_check():
    return jsonify({"status": "ok"})

@app.route('/shorten', methods=['POST'])
def shorten_url():
    try:
        data = request.get_json()
        if not data or 'url' not in data:
            return jsonify({"error": "URL is required"}), 400
        
        original_url = data['url'].strip()
        
        if not is_valid_url(original_url):
            return jsonify({"error": "Invalid URL format"}), 400
        
        short_code = generate_short_code()
        
        table.put_item(
            Item={
                'short_code': short_code,
                'original_url': original_url,
                'created_at': str(int(os.times().elapsed * 1000))
            }
        )
        
        base_url = request.host_url.rstrip('/')
        short_url = f"{base_url}/{short_code}"
        
        return jsonify({"short_url": short_url})
    
    except Exception as e:
        print(f"Error shortening URL: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/<short_code>')
def redirect_url(short_code):
    try:
        response = table.get_item(Key={'short_code': short_code})
        
        if 'Item' not in response:
            return render_template_string('''
                <h1>URL Not Found</h1>
                <p>The shortened URL you're looking for doesn't exist.</p>
                <a href="/">Create a new short URL</a>
            '''), 404
        
        original_url = response['Item']['original_url']
        return redirect(original_url, code=302)
    
    except Exception as e:
        print(f"Error redirecting: {str(e)}")
        return render_template_string('''
            <h1>Error</h1>
            <p>Something went wrong. Please try again.</p>
            <a href="/">Go back home</a>
        '''), 500

if __name__ == '__main__':
    debug_mode = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    port = int(os.environ.get('PORT', 8080))
    app.run(debug=debug_mode, host='0.0.0.0', port=port)

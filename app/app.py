import os
import secrets
from flask import Flask, request, jsonify, redirect, render_template_string
from urllib.parse import urlparse
import boto3

app = Flask(__name__)

TABLE_NAME = os.environ.get('TABLE_NAME', 'urls')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLE_NAME)

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>URL Shortener</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px; 
            margin: 50px auto; 
            padding: 20px;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            min-height: 100vh;
            color: white;
        }
        .container {
            background: rgba(255,255,255,0.05);
            backdrop-filter: blur(15px);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 25px;
            padding: 40px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }
        h1 { 
            text-align: center; 
            margin-bottom: 40px;
            font-size: 2.5em;
            background: linear-gradient(45deg, #00d4ff, #5b86e5);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #b8c6db;
        }
        input[type="url"] {
            width: 100%;
            padding: 15px;
            border: 2px solid rgba(255,255,255,0.1);
            border-radius: 12px;
            font-size: 16px;
            background: rgba(255,255,255,0.05);
            color: white;
            transition: border-color 0.3s;
        }
        input[type="url"]:focus {
            outline: none;
            border-color: #00d4ff;
        }
        input[type="url"]::placeholder {
            color: rgba(255,255,255,0.5);
        }
        button {
            background: linear-gradient(45deg, #00d4ff, #5b86e5);
            color: white;
            padding: 15px 30px;
            border: none;
            border-radius: 12px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 600;
            width: 100%;
            margin-top: 10px;
            transition: transform 0.2s;
        }
        button:hover { 
            transform: translateY(-2px);
        }
        .result {
            margin-top: 30px;
            padding: 25px;
            background: rgba(0, 212, 255, 0.1);
            border: 1px solid rgba(0, 212, 255, 0.3);
            border-radius: 15px;
            word-break: break-all;
        }
        .short-url {
            font-weight: bold;
            font-size: 1.2em;
            color: #00d4ff;
        }
        .error {
            margin-top: 20px;
            padding: 15px;
            background: rgba(255, 82, 82, 0.1);
            border: 1px solid rgba(255, 82, 82, 0.3);
            border-radius: 10px;
            color: #ff5252;
        }
        .stats {
            margin-top: 40px;
            text-align: center;
            font-size: 0.9em;
            color: #b8c6db;
        }
        a {
            color: #00d4ff;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔗 URL Shortener</h1>
        <p style="text-align: center; margin-bottom: 30px; color: #b8c6db;">Powered by AWS ECS, DynamoDB, and DevOps automation</p>
        
        <form method="POST" action="/shorten">
            <div class="form-group">
                <label for="url">Enter your long URL:</label>
                <input type="url" id="url" name="url" placeholder="https://example.com/my/very/long/path" required>
            </div>
            <button type="submit">Shorten URL</button>
        </form>

        {% if short_url %}
        <div class="result">
            <p><strong>Original URL:</strong><br>{{ original_url }}</p>
            <p><strong>Short URL:</strong><br>
            <span class="short-url">{{ short_url }}</span></p>
            <p><a href="{{ short_url }}" target="_blank">Test the redirect</a></p>
        </div>
        {% endif %}

        {% if error %}
        <div class="error">
            <strong>Error:</strong> {{ error }}
        </div>
        {% endif %}

        <div class="stats">
            <p><strong>Infrastructure:</strong> ECS Fargate • ALB • DynamoDB • VPC</p>
            <p><strong>DevOps:</strong> GitHub Actions • CodeDeploy • Terraform</p>
        </div>
    </div>
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

@app.route('/healthz')
def health_check():
    return jsonify({"status": "ok"})

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/shorten', methods=['POST'])
def shorten_url():
    if request.is_json:
        data = request.get_json()
        url = data.get('url')
    else:
        url = request.form.get('url')
    
    if not url:
        error_msg = "URL is required"
        if request.is_json:
            return jsonify({"error": error_msg}), 400
        return render_template_string(HTML_TEMPLATE, error=error_msg)
    
    if not is_valid_url(url):
        error_msg = "Please enter a valid URL"
        if request.is_json:
            return jsonify({"error": error_msg}), 400
        return render_template_string(HTML_TEMPLATE, error=error_msg)
    
    short_code = generate_short_code()
    
    try:
        table.put_item(
            Item={
                'short_code': short_code,
                'url': url
            }
        )
    except Exception as e:
        error_msg = "Failed to create short URL"
        if request.is_json:
            return jsonify({"error": error_msg}), 500
        return render_template_string(HTML_TEMPLATE, error=error_msg)
    
    host = request.headers.get('Host', 'localhost:8080')
    scheme = 'https' if request.headers.get('X-Forwarded-Proto') == 'https' else 'http'
    short_url = f"{scheme}://{host}/{short_code}"
    
    if request.is_json:
        return jsonify({
            "short_code": short_code,
            "short_url": short_url,
            "original_url": url
        })
    else:
        return render_template_string(HTML_TEMPLATE, 
                                     short_url=short_url, 
                                     original_url=url)

@app.route('/<short_code>')
def redirect_url(short_code):
    try:
        response = table.get_item(
            Key={'short_code': short_code}
        )
        
        if 'Item' in response:
            return redirect(response['Item']['url'], code=302)
        else:
            return jsonify({"error": "Short URL not found"}), 404
            
    except Exception as e:
        return jsonify({"error": "Failed to retrieve URL"}), 500

if __name__ == '__main__':
    debug_mode = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    app.run(debug=debug_mode, host='0.0.0.0', port=8080)
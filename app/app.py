import os
import json
import hashlib
import secrets
from flask import Flask, request, jsonify, redirect, render_template_string
import boto3
from botocore.exceptions import ClientError

app = Flask(__name__)

TABLE_NAME = os.environ.get('TABLE_NAME', 'urls')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLE_NAME)

# HTML template for the web interface
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
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: white;
        }
        .container {
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        h1 { 
            text-align: center; 
            margin-bottom: 40px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
        }
        input[type="url"] {
            width: 100%;
            padding: 15px;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            background: rgba(255,255,255,0.9);
            color: #333;
        }
        button {
            background: #4CAF50;
            color: white;
            padding: 15px 30px;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 600;
            width: 100%;
            margin-top: 10px;
            transition: background 0.3s;
        }
        button:hover { background: #45a049; }
        .result {
            margin-top: 30px;
            padding: 20px;
            background: rgba(255,255,255,0.2);
            border-radius: 10px;
            word-break: break-all;
        }
        .short-url {
            font-weight: bold;
            font-size: 1.2em;
            color: #FFE4E1;
        }
        .stats {
            margin-top: 40px;
            text-align: center;
            font-size: 0.9em;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔗 URL Shortener</h1>
        <p style="text-align: center; margin-bottom: 30px;">Powered by AWS ECS, DynamoDB, and lots of DevOps magic! ✨</p>
        
        <form method="POST" action="/shorten">
            <div class="form-group">
                <label for="url">Enter your long URL:</label>
                <input type="url" id="url" name="url" placeholder="https://example.com/my/very/long/path" required>
            </div>
            <button type="submit">✨ Shorten It!</button>
        </form>

        {% if short_url %}
        <div class="result">
            <p><strong>Original URL:</strong><br>{{ original_url }}</p>
            <p><strong>Short URL:</strong><br>
            <span class="short-url">{{ short_url }}</span></p>
            <p><a href="{{ short_url }}" target="_blank" style="color: #FFE4E1;">🚀 Test the redirect</a></p>
        </div>
        {% endif %}

        <div class="stats">
            <p>🏗️ <strong>Infrastructure:</strong> ECS Fargate • ALB • DynamoDB • VPC Endpoints • WAF</p>
            <p>🚀 <strong>DevOps:</strong> GitHub Actions • CodeDeploy Blue/Green • Terraform • OIDC</p>
            <p>🔒 <strong>Security:</strong> Private Subnets • IAM Least Privilege • No NAT Gateways</p>
        </div>
    </div>
</body>
</html>
'''

def generate_short_code():
    return secrets.token_urlsafe(8)[:11]

@app.route('/healthz')
def health_check():
    return jsonify({"status": "ok"})

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/shorten', methods=['POST'])
def shorten_url():
    # Handle both form data and JSON
    if request.is_json:
        data = request.get_json()
        url = data.get('url')
    else:
        url = request.form.get('url')
    
    if not url:
        if request.is_json:
            return jsonify({"error": "URL is required"}), 400
        return render_template_string(HTML_TEMPLATE, error="URL is required")
    
    # Generate short code
    short_code = generate_short_code()
    
    # Store in DynamoDB
    try:
        table.put_item(
            Item={
                'short_code': short_code,
                'url': url
            }
        )
    except Exception as e:
        if request.is_json:
            return jsonify({"error": "Failed to store URL"}), 500
        return render_template_string(HTML_TEMPLATE, error="Failed to store URL")
    
    # Build short URL
    host = request.headers.get('Host', 'localhost:8080')
    short_url = f"http://{host}/{short_code}"
    
    if request.is_json:
        return jsonify({
            "short": short_code,
            "url": url
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
    app.run(debug=True, host='0.0.0.0', port=8080)
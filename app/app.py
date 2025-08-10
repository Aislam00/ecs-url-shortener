import os
import json
import hashlib
import secrets
from flask import Flask, request, jsonify, redirect
import boto3
from botocore.exceptions import ClientError

app = Flask(__name__)

TABLE_NAME = os.environ.get('TABLE_NAME', 'urls')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLE_NAME)

def generate_short_code():
    return secrets.token_urlsafe(8)

@app.route('/healthz')
def health_check():
    return jsonify({'status': 'ok'}), 200

@app.route('/shorten', methods=['POST'])
def shorten_url():
    try:
        data = request.get_json()
        if not data or 'url' not in data:
            return jsonify({'error': 'URL is required'}), 400
        
        original_url = data['url']
        if not original_url.startswith(('http://', 'https://')):
            return jsonify({'error': 'Invalid URL format'}), 400
        
        short_code = generate_short_code()
        
        table.put_item(
            Item={
                'short_code': short_code,
                'original_url': original_url
            }
        )
        
        return jsonify({
            'short': short_code,
            'url': original_url
        }), 201
        
    except Exception as e:
        app.logger.error(f"Error shortening URL: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/<short_code>')
def redirect_url(short_code):
    try:
        response = table.get_item(
            Key={'short_code': short_code}
        )
        
        if 'Item' not in response:
            return jsonify({'error': 'Short URL not found'}), 404
        
        original_url = response['Item']['original_url']
        return redirect(original_url, code=302)
        
    except Exception as e:
        app.logger.error(f"Error redirecting URL: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
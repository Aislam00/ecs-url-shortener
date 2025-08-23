import os
import secrets
import ssl
from flask import Flask, request, jsonify, redirect, render_template_string
from urllib.parse import urlparse
import boto3

app = Flask(__name__)

TABLE_NAME = os.environ.get('TABLE_NAME', 'urls')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLE_NAME)

# [Keep all your existing HTML_TEMPLATE and functions exactly the same]
HTML_TEMPLATE = '''[Your existing HTML template]'''

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

# [Keep all your existing routes exactly the same]

if __name__ == '__main__':
    # Generate self-signed certificate for HTTPS
    context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
    context.load_cert_chain('cert.pem', 'key.pem')
    
    debug_mode = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    app.run(debug=debug_mode, host='0.0.0.0', port=8080, ssl_context=context)

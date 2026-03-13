import json, re, os

config_path = 'C:/OpenClaw/.openclaw/openclaw.json'
with open(config_path) as f:
    data = f.read()

# Search for any API keys
for match in re.finditer(r'(sk-[a-zA-Z0-9_-]{20,}|gsk_[a-zA-Z0-9_-]{20,})', data):
    key = match.group()
    if key.startswith('sk-'):
        print('OpenAI key found: ' + key[:10] + '...')
    elif key.startswith('gsk_'):
        print('Groq key found: ' + key[:10] + '...')

# Check env
for var in ['OPENAI_API_KEY', 'GROQ_API_KEY', 'OPENROUTER_API_KEY']:
    val = os.environ.get(var)
    if val:
        print(f'{var}: {val[:10]}...')

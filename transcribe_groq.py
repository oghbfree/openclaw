import json, http.client, sys, os, re

config_path = 'C:/OpenClaw/.openclaw/openclaw.json'
with open(config_path) as f:
    data = f.read()

groq_key = None
for match in re.finditer(r'gsk_[a-zA-Z0-9_-]{20,}', data):
    groq_key = match.group()
    break

if not groq_key:
    print('No Groq key found')
    sys.exit(1)

audio_path = sys.argv[1] if len(sys.argv) > 1 else None
if not audio_path:
    print('Usage: python transcribe_groq.py <audio_file>')
    sys.exit(1)

print(f'Transcribing: {audio_path}')
print(f'File size: {os.path.getsize(audio_path)} bytes')

# Read the audio file
with open(audio_path, 'rb') as f:
    audio_data = f.read()

# Build multipart form data manually
boundary = '----FormBoundary7MA4YWxkTrZu0gW'
parts = []

# model field
parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="model"\r\n\r\nwhisper-large-v3-turbo\r\n'.encode())

# language field
parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="language"\r\n\r\nen\r\n'.encode())

# file field
filename = os.path.basename(audio_path)
file_header = f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{filename}"\r\nContent-Type: audio/ogg\r\n\r\n'.encode()
file_footer = b'\r\n'
parts.append(file_header + audio_data + file_footer)

# ending boundary
parts.append(f'--{boundary}--\r\n'.encode())

body = b''.join(parts)

conn = http.client.HTTPSConnection('api.groq.com', timeout=30)
conn.request('POST', '/openai/v1/audio/transcriptions', body=body, headers={
    'Authorization': f'Bearer {groq_key}',
    'Content-Type': f'multipart/form-data; boundary={boundary}'
})

resp = conn.getresponse()
result = resp.read().decode()
print(f'Status: {resp.status}')

if resp.status == 200:
    data = json.loads(result)
    print('TRANSCRIPT:')
    print(data.get('text', ''))
else:
    print(result)

conn.close()

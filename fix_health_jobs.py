import json

with open('C:/OpenClaw/.openclaw/cron/jobs.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

health_job_ids = [
    '603e6750-d18b-4c1b-8574-2308b3b20b83',
    'ee1110a6-ec4e-45e9-bc47-b2781fb8162d',
    '6c16d299-05e2-452e-aff7-a18ce0c61f2e'
]

for job in data['jobs']:
    if job['id'] in health_job_ids:
        old_channel = job.get('delivery', {}).get('channel', 'N/A')
        job['delivery']['channel'] = 'telegram'
        print(f'Fixed: {job["name"]} ({job["id"][:8]}...) channel: {old_channel} -> telegram')

with open('C:/OpenClaw/.openclaw/cron/jobs.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2)

print('Done!')

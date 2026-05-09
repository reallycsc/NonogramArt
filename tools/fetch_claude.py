import urllib.request
import sys

try:
    print('Fetching content...')
    response = urllib.request.urlopen('https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md', timeout=30)
    content = response.read().decode('utf-8')
    print(f'Fetched {len(content)} characters')
    
    with open('CLAUDE.md', 'a', encoding='utf-8') as f:
        f.write('\n' + content)
    print('Content appended successfully')
    
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
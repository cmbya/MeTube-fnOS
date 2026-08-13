#!/usr/bin/env python3
import json, os, re, urllib.request
API='https://api.github.com/repos/alexta69/metube/tags?per_page=100'
TOKEN=os.environ.get('GITHUB_TOKEN','').strip()
PAT=re.compile(r'^(\d{4})\.(\d{2})\.(\d{2})$')
headers={'Accept':'application/vnd.github+json','User-Agent':'MeTube-fnOS-builder','X-GitHub-Api-Version':'2022-11-28'}
if TOKEN: headers['Authorization']=f'Bearer {TOKEN}'
req=urllib.request.Request(API,headers=headers)
with urllib.request.urlopen(req,timeout=60) as r: tags=json.load(r)
found=[]
for item in tags:
    name=str(item.get('name','')).strip(); m=PAT.match(name)
    if m: found.append((tuple(map(int,m.groups())),name))
if not found: raise SystemExit('没有找到 YYYY.MM.DD 格式的 MeTube 上游标签')
found.sort(reverse=True); print(found[0][1])

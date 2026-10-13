from bs4 import BeautifulSoup
import json
from pathlib import Path
s=BeautifulSoup(Path('presentazione/index.html').read_text(),'html.parser')
data=[]
for section in s.select('section'):
 b=section.select_one('.body')
 d={'label':section['data-label'],'title':b.select_one('h1,h2').get_text('\n',strip=True),'eyebrow':b.select_one('.eyebrow').get_text(),'caption':[x.get_text('\n',strip=True) for x in b.select(':scope > .caption')]}
 for cls in ('agenda','process','metrics','three'):
  container=b.select_one('.'+cls)
  if container:
   d['layout']=cls; d['items']=[{'title':x.select_one('h3').get_text(),'body':x.select_one('p').get_text('\n',strip=True),'value':x.select_one('.value').get_text() if x.select_one('.value') else ''} for x in container.find_all('div',recursive=False)]
 if b.select_one('pre'): d.update(layout='code',code=b.select_one('pre').get_text(),items=[{'title':b.select_one('.code-layout h3').get_text(),'body':b.select_one('.code-layout p').get_text('\n',strip=True),'caption':b.select_one('.code-layout .caption').get_text('\n',strip=True)}])
 if 'cover' in section.get('class',[]): d.update(layout='cover',subtitle=b.select_one('.subtitle').get_text('\n',strip=True),byline=b.select_one('.byline').get_text())
 if 'closing' in section.get('class',[]): d.update(layout='closing',subtitle=b.select_one(':scope > p:not(.eyebrow)').get_text('\n',strip=True),contact=b.select_one('.contact').get_text())
 data.append(d)
Path('presentazione/.build/content.json').write_text(json.dumps(data,ensure_ascii=False))
print('Estratti',len(data),'contenuti')

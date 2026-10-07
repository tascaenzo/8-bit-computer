"""Write purchase dimensions and package requirements alongside connectivity BOM."""
import csv

def requirement(c):
    r=c['ref'];v=c['value']
    if c.get('kind'):
        special={'151':'CD74HCT151E','283':'CD74HCT283E','157':'SN74HCT157N','138':'SN74HCT138N','244':'SN74HCT244N'}
        part=special.get(c['kind'],v+' compatible pinout')
        return part,f'5V HCT; PDIP-{c["n"]}; rows 7.62mm; optional socket'
    if r.startswith('SW'):
        return f'SDA{c["positions"]:02d}H0BD',f'C&K; through-hole SPST; pitch 2.54mm; rows 7.62mm; {c["positions"]} contacts'
    if r.startswith('RN'):return 'Bussed 8x10k SIP-9','Common pin 1; pitch 2.54mm; isolated networks incompatible'
    if r.startswith('R'):return v+' 1/4W 5%','Axial; pitch 7.62mm; body max 6.3x2.5mm'
    if r.startswith('D'):return v+' high efficiency LED','Through-hole 3mm; pitch 2.54mm; pad 1 cathode; pad 2 anode'
    if r.startswith('C'):
        if '10u' in v:return '10uF 16V electrolytic','Pitch 2.50mm; diameter max 5mm; pad 1 positive'
        return '100nF 25V ceramic','Pitch 2.50mm; body max 4x3mm; nonpolarized'
    if r.startswith('J'):return '2-row male pin header',f'Pitch 2.54mm; {c["n"]//2}x2 contacts; unshrouded'
    raise ValueError(r)

def write_bom(path,components):
    with path.open('w') as f:
        w=csv.writer(f);w.writerow(['Reference','Value','Footprint','Purpose','Part_or_requirement','Mounting_specification'])
        for c in components:w.writerow([c['ref'],c['value'],c['footprint'],c['purpose'],*requirement(c)])

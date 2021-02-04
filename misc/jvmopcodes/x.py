import re

with open('opcodes.txt') as f:
    s = f.read()


td = re.compile('<td[^>]*>')

rows = [
    [column.replace('</td>', '').strip()
        for column in td.split(row.replace('</tr>', '').strip())][1:]
    for row in s.split('<tr>')
]
rows = sorted(rows, key=lambda row: row[1])

# for row in rows:
#     print('================================')
#     print(row)

## Print all zero argument opcodes
# for row in rows:
#     if not row[3]:
#         print(f"  0x{row[1]}: \"{row[0]}\",")


## Print all one 16-bit branch argument opcodes
# for row in rows:
#     if row[3] in ['2: branchbyte1, branchbyte2']:
#         print(f"  0x{row[1]}: \"{row[0]}\",")

## Print all one 16-bit index argument opcodes
# for row in rows:
#     if row[3] in ['2: indexbyte1, indexbyte2']:
#         print(f"  0x{row[1]}: \"{row[0]}\",")

## Print all one 8-bit index argument opcodes
for row in rows:
    if row[3] in ['1: index']:
        print(f"  0x{row[1]}: \"{row[0]}\",")

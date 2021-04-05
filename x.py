import sys
import os

for path in sys.argv[1:]:
    filename = os.path.basename(path)
    basename, extension = os.path.splitext(filename)
    assert extension == '.java', extension

    out = []
    with open(path) as f:
        abstract = False
        for line in f:
            if 'abstract ' in line:
                abstract = True
            if line.strip().startswith(basename + '('):
                modifier = 'protected ' if abstract else 'public '
                line = line.replace(basename + '(', modifier + basename + '(')
            out.append(line)

    with open(path, 'w') as f:
        f.write(''.join(out))

import os
import subprocess
import sys

scriptdir = os.path.dirname(os.path.realpath(__file__))
jarpath = os.path.join(
    scriptdir, 'target', 'java2cj-1.0-SNAPSHOT-jar-with-dependencies.jar')
classespath = os.path.join(scriptdir, 'target', 'classes')
jdtpath = os.path.join(
    os.environ.get('HOME') or os.environ.get('userprofile'),
    os.path.join(
        '.m2',
        'repository',
        'org',
        'eclipse',
        'jdt',
        'org.eclipse.jdt.core',
        '3.22.0',
        'org.eclipse.jdt.core-3.22.0.jar'))


def list_java_files(top):
    files = []
    for root, dirnames, filenames in os.walk(top):
        for filename in filenames:
            if filename.endswith('.java'):
                files.append(os.path.join(root, filename))
    return files

args = sys.argv[1:]
if not args:
    args = [os.path.join('src', 'main', 'java', 'crossj', 'cj')]

cpsep = ';' if os.name == 'nt' else ':'

java_files = [f for arg in args for f in list_java_files(arg)]
subprocess.run([
    'java',
    '-cp',
    f'{classespath}{cpsep}{jarpath}',
    'com.github.math4tots.java2cj.Main'] + java_files)

@echo off

REM TODO: make this directory independent

java -cp target/classes crossj.cj.main.CJMain -t -o target/out.js && node --enable-source-maps target/out.js

@echo off

REM TODO: make this directory independent

java -cp target/classes crossj.cj.main.JSMain -t -o target/out.js && node --enable-source-maps target/out.js

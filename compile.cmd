@echo off
set JX_HOME=c:\SoftwareTree\Gilhari-0.8.0b-SDK
if not exist .\bin mkdir .\bin
dir /s /B src\*.java > sources.txt
javac -d .\bin -cp .;%JX_HOME%\libs\jxclasses.jar;%JX_HOME%\external_libs\json-20240303.jar @sources.txt
echo Compilation finished.

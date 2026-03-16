@echo off
echo Starting Atomicas ChemTools API...
cd /d "%~dp0"

:: Activate conda environment
call conda activate cadd

uvicorn server:app --host 0.0.0.0 --port 8000 --reload
pause

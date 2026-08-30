# Start Python middleware (required). PHP BFF optional on 8081.
Set-Location $PSScriptRoot\..\middleware
python -m uvicorn app.main:app --host 127.0.0.1 --port 8080

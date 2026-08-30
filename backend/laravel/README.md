# SaHayak Laravel / PHP

PHP 8.4 is at `G:\tools\php\php.exe`.

BFF proxy (Python middleware must be on 8080):

```
$env:SAHAYAK_PYTHON='http://127.0.0.1:8080'
G:\tools\php\php.exe -S 127.0.0.1:8081 G:\Sahayak\backend\laravel\public\index.php
```

Matching and saga step names live in `app/Domain`. Writes and orchestration at runtime stay on the Python `/v1` service so Flutter never talks to two contracts.

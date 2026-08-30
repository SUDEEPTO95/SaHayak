# Flutter citizen app — SaHayak. Talks only to `/v1`.

SDK on this PC: `G:\tools\flutter\bin\flutter.bat`

```
cd G:\Sahayak\frontend\mobile
G:\tools\flutter\bin\flutter.bat pub get
G:\tools\flutter\bin\flutter.bat run --dart-define=SAHAYAK_API_BASE=http://127.0.0.1:8080
```

Home is only **Need blood** and **I can donate**. Under the name: **blood help nearby**.

Play package: `app.sahayak.india`. Release signing: `android/upload-keystore.jks` + `android/key.properties` (not in git). No SMS or call permissions.

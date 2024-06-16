# Cashflow APP

Requirements:
   - Java 8/11

Create a bundle:
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storetype JKS

```bash
flutter build appbundle --release --no-sound-null-safety
```
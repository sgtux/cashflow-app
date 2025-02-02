# Cashflow APP

Requirements:
   - Java 8/11

Create a bundle:
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storetype JKS

Configure keystore.jks in local.properties:
```sh
storeFile=/path/keystore.jks
storePassword=foo
keyAlias=alias
keyPassword=foo
```

```bash
flutter build appbundle --release
```
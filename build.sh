echo "Atualizar versionCode no arquivo pubspec.yaml"
grep version: pubspec.yaml 
flutter build appbundle --release 
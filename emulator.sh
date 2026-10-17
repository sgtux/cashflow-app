#!/usr/bin/env bash
# Inicia o emulador com limite de memória e CPU para não travar o PC.
# Se passar do limite, só o emulador é encerrado.
AVD=${1:-pixel}
SDK=${ANDROID_HOME:-$HOME/Android/Sdk}

systemd-run --user --scope --unit="android-emulator-$AVD" \
  -p MemoryHigh=4500M -p MemoryMax=5G -p MemorySwapMax=1G \
  -p CPUQuota=200% \
  nice -n 10 "$SDK/emulator/emulator" -avd "$AVD" "${@:2}"

#!/data/data/com.termux/files/usr/bin/bash

# 1. 아키텍처 감지
ARCH=$(uname -m)
case $ARCH in
  aarch64) ARCH=arm64;;
  arm*) ARCH=armhf;;
  x86_64) ARCH=amd64;;
  i*86) ARCH=i386;;
  *) echo "[!] Unsupported architecture: $ARCH"; exit 1;;
esac
echo "[+] Detected architecture: $ARCH"

# 2. 사용자에게 Variant 선택
echo "[*] Select Kali variant:"
echo "1) Full (모든 도구 포함)"
echo "2) Minimal (기본 CLI 도구)"
echo "3) Nano (초경량 껍데기)"
read -p "Enter choice [1-3]: " choice

case $choice in
  1) VARIANT="full";;
  2) VARIANT="minimal";;
  3) VARIANT="nano";;
  *) echo "[!] Invalid choice"; exit 1;;
esac

# 3. 이미지 다운로드
IMG="kali-nethunter-rootfs-${VARIANT}-${ARCH}.tar.xz"
URL="https://kali.download/nethunter-images/current/rootfs/$IMG"
echo "[*] Downloading $IMG ..."
curl -LO "$URL" || { echo "[!] Download failed."; exit 1; }

# 4. 기존 디렉토리 정리
rm -rf kali kali-*

# 5. 압축 해제 (dev 제외)
mkdir kali
cd kali
echo "[*] Extracting rootfs (excluding /dev)..."
proot --link2symlink tar --wildcards --exclude='./dev/*' -xf ../$IMG || {
  echo "[!] Extraction failed"; exit 1;
}
cd ..

# 6. 실행 스크립트 생성
echo "[*] Creating launch script..."
cat > kali <<EOF
#!/bin/bash
cd \$(dirname \$0)/kali
unset LD_PRELOAD
proot --link2symlink -0 -r . \\
  -b /dev/ -b /proc/ -b /sys/ \\
  -b \$HOME:/root -w /root \\
  /usr/bin/env -i \\
  HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \\
  TERM=\$TERM LANG=C.UTF-8 \\
  /bin/bash --login
EOF

chmod +x kali
echo "[+] Done! Run Kali with: ./kali"

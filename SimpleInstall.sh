#!/data/data/com.termux/files/usr/bin/bash

BASE_URL="https://kali.download/nethunter-images/current/rootfs"
IMAGE_NAME=""
IMAGE_FILE=""
SHA_NAME=""
SHA_URL=""
KEEP_IMAGE=""
IMAGE_URL=""

function select_arch() {
    echo "[*] Detecting architecture..."
    ARCH=$(uname -m)
    case $ARCH in
        aarch64) ARCH="arm64";;
        arm*) ARCH="armhf";;
        x86_64) ARCH="amd64";;
        i*86) ARCH="i386";;
        *) echo "[!] Unknown architecture: $ARCH"; exit 1;;
    esac
    echo "[+] Detected architecture: $ARCH"
}

function select_variant() {
    echo "[*] Select Kali variant to install:"
    echo "1) Full (all tools, large size)"
    echo "2) Minimal (basic CLI tools)"
    echo "3) Nano (ultralight, almost empty)"
    read -p "Enter choice [1-3]: " choice
    case $choice in
        1) VARIANT="full";;
        2) VARIANT="minimal";;
        3) VARIANT="nano";;
        *) echo "[!] Invalid choice"; exit 1;;
    esac
    IMAGE_NAME="kali-nethunter-rootfs-${VARIANT}-${ARCH}.tar.xz"
    IMAGE_FILE="${IMAGE_NAME}"
    SHA_NAME="${IMAGE_NAME}.sha512sum"
    SHA_URL="${BASE_URL}/${SHA_NAME}"
    IMAGE_URL="${BASE_URL}/${IMAGE_NAME}"
}

function get_url() {
    echo "[*] Downloading rootfs image..."
    wget --continue "${IMAGE_URL}"
}

function get_sha() {
    if [ -z $KEEP_IMAGE ]; then
        get_url
        if curl --silent --fail --head "${SHA_URL}"; then
            echo "[+] SHA file found. Verifying..."
            wget --continue "${SHA_URL}"
            verify_sha
        else
            echo "[!] SHA file not found. Skipping verification."
        fi
    fi
}

function verify_sha() {
    echo "[*] Verifying image..."
    sha512sum -c "${SHA_NAME}" || {
        echo "[!] SHA verification failed!"
        exit 1
    }
    echo "[+] Verified."
}

function extract_image() {
    echo "[*] Extracting image..."
    proot --link2symlink tar -xf "${IMAGE_FILE}" || {
        echo "[!] Extraction failed!"
        exit 1
    }
    echo "[+] Extraction complete."
}

function setup_kali() {
    echo "[*] Setting up Kali NetHunter..."
    mv kali-* kali
    cd kali
    echo "[*] Creating launch script..."
    cat > ../kali <<EOF
#!/bin/bash
cd \$(dirname \$0)/kali
unset LD_PRELOAD
command="proot --link2symlink -0 -r . -b /dev/ -b /proc/ -b /sys/ -b \$HOME:/root -w /root /usr/bin/env -i HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TERM=\$TERM LANG=C.UTF-8 /bin/bash --login"
eval \$command
EOF
    chmod +x ../kali
    echo "[+] Kali NetHunter Rootless installed!"
}

# 실행 흐름
select_arch
select_variant
get_sha
extract_image
setup_kali

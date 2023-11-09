
# content form https://github.com/audacioustux/devcontainers/blob/main/src/operator-sdk/install.sh

## 安装 operator-sdk --开始
function  install_operator_sdk() {
set -eax

export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')

sdk_path=""
if [ "$OS" = "linux" ] && [ "$ARCH" = "amd64" ]; then
    echo "use local: .devcontainer/config/operator-sdk_linux_amd64"
    sdk_path="/workspaces/codespace_kubernets/.devcontainer/config/"
else
    echo "use remote"
    export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/latest/download
    curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}
    gpg --keyserver keyserver.ubuntu.com --recv-keys 052996E2A20B5C7E

    curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt
    curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt.asc
    gpg -u "Operator SDK (release) <cncf-operator-sdk@cncf.io>" --verify checksums.txt.asc

    grep operator-sdk_${OS}_${ARCH} checksums.txt | sha256sum -c -
fi 



install -o root -g root -m 0755 ${sdk_path}operator-sdk_${OS}_${ARCH} /usr/local/bin/operator-sdk
}


# 主要函数

install_operator_sdk
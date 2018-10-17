# Adapted from https://github.com/japaric/cross
set -ex

main() {
    local SHLIB_VERSION_NUMBER=1.0.2 
    local version=${SHLIB_VERSION_NUMBER}m
    local SHLIB_MAJOR=1
    local SHLIB_MINOR=0.2
    local os=$1 \
    local triple=$2
    local sysroot=$3

    local dependencies=(
        ca-certificates
        curl
        m4
        make
        perl
    )

    # NOTE cross toolchain must be already installed
    local purge_list=()
    for dep in ${dependencies[@]}; do
        if ! yum list -q installed $dep; then
            yum install -y $dep
            purge_list+=( $dep )
        fi
    done

    td=$(mktemp -d)

    pushd $td
    curl https://www.openssl.org/source/openssl-$version.tar.gz | \
        tar --strip-components=1 -xz
    AR=${triple}ar CC=${triple}gcc ./Configure \
      --prefix=${sysroot}/usr \
      --openssldir=${sysroot}/usr \
      no-asm \
      shared \
      $os \
      -fPIC \
      ${@:4}
    make SHLIB_VERSION_NUMBER=${SHLIB_VERSION_NUMBER} SHLIB_MAJOR=${SHLIB_MAJOR} SHLIB_MINOR=${SHLIB_MINOR} -j$(nproc)
    make SHLIB_VERSION_NUMBER=${SHLIB_VERSION_NUMBER} SHLIB_MAJOR=${SHLIB_MAJOR} SHLIB_MINOR=${SHLIB_MINOR} install_sw
    
    # clean up

    popd

    if [ ${#purge_list[@]} -ne 0 ]; then
        yum remove -y ${purge_list[@]}
    fi

    rm -rf $td
    rm $0
}

main "${@}"

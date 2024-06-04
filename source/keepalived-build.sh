#!/bin/bash
# Clone Repository
cd ${DATA_DIR}
git clone https://github.com/acassen/keepalived

# Change directory, execute autogen.sh and configure keepalived source
cd ${DATA_DIR}/keepalived
git checkout v${LAT_V}
./autogen.sh
./configure   \
  --prefix=/usr \
  --sysconfdir=/etc \
  --mandir=/usr/man \
  --docdir=/usr/doc/keepalived-${LAT_V} \
  --build=x86_64-slackware-linux

# Compile keepalived and install it to temporary directory
make -j$CPU_COUNT
DESTDIR=${DATA_DIR}/v$LAT_V make install -j$CPU_COUNT

# Create necessary directory and ccopy over slack-desc
mkdir -p ${DATA_DIR}/$LAT_V
cd ${DATA_DIR}/v$LAT_V
mkdir -p ${DATA_DIR}/v$LAT_V/install
cp ${DATA_DIR}/slack-desc ${DATA_DIR}/v$LAT_V/install/

# Move sample keepalived.conf to samples directory
mv ${DATA_DIR}/v$LAT_V/etc/keepalived/keepalived.conf.sample ${DATA_DIR}/v$LAT_V/etc/keepalived/samples/keepalived.conf.sample

# Create Slackware package
makepkg -l n -c n ${DATA_DIR}/$LAT_V/${APP_NAME}-${LAT_V}-x86_64-1.txz
cd ${DATA_DIR}/$LAT_V
md5sum ${APP_NAME}-${LAT_V}-x86_64-1.txz | awk '{print $1}' > ${APP_NAME}-${LAT_V}-x86_64-1.txz.md5

## Cleanup
rm -R ${DATA_DIR}/keepalived ${DATA_DIR}/v$LAT_V*

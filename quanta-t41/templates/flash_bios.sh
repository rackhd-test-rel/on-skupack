#!/bin/bash
set -xe
DOWNLOAD_DIR=/opt/downloads
CMD="<%= sku.biosFirmware.command %>"
CMD=${CMD##*/}
CMD="/opt/ami/${CMD}"

#
# Retrieve the update script and run it
mkdir -p /opt/ami
curl --retry 3 <%=api.server%>/<%= sku.biosFirmware.command %> -o ${CMD}
chmod 777 ${CMD}

#
# Download the sku specific file if it exists
filename=<%= sku.biosFirmware.filename %>
curl --retry 3 <%=api.server%>/${filename} -o ${DOWNLOAD_DIR}/${filename##*/}
md5=($(md5sum ${DOWNLOAD_DIR}/${filename##*/}))
md5Expected="<%= sku.biosFirmware.md5sum %>"

#
# convert string to lower case with ,,
test ${md5,,} = ${md5Expected,,}
FLASH_FILE=${DOWNLOAD_DIR}/${filename##*/}

#
# Download the user uploaded file if specified to override default
<% if (typeof file !== 'undefined' && file) { %>
  fileMd5Uri="<%=api.files%>/<%=file%>/md5"
  fileUri="<%=api.files%>/<%=file%>"
  outputPath="${DOWNLOAD_DIR}/<%= file %>"
  curl --retry 3 ${fileUri} -o ${outputPath}
  md5=($(md5sum ${outputPath}))
  md5Expected=`curl ${fileMd5Uri}`
  test ${md5Expected,,} = ${md5,,}
  FLASH_FILE=${outputPath}
<% } %>

pushd ${DOWNLOAD_DIR}

#Snapshot the current image
VERSION=`${CMD} /S | grep 'ROM ID' | awk -F= '{print $2}' | tr -d ' '`
${CMD} backup.bin /O
curl -T ./${BACKUP_FILE} <%= api.files %>/<%= nodeId %>-${VERSION}

# Flash new image
${CMD} <%= sku.biosFirmware.args %>

# Wait some time for the internal process to finish
# otherwise catalog ami task after flashing will hang the node in some fw verion
sleep 30

#!/bin/sh
set -ex
endpoints=$(echo $KB_MEMBER_ADDRESSES | tr ',' '\n')
leaverEndpoint=$(echo "$endpoints" | grep $KB_LEAVE_MEMBER_POD_NAME)

ETCDID=$(execEtcdctl $leaverEndpoint endpoint status | awk -F', ' '{print $2}')
execEtcdctl $leaverEndpoint member remove $ETCDID
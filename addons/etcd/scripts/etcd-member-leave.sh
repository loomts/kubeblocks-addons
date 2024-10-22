#!/bin/bash

# This is magic for shellspec ut framework. "test" is a `test [expression]` well known as a shell command.
# Normally test without [expression] returns false. It means that __() { :; }
# function is defined if this script runs directly.
#
# shellspec overrides the test command and returns true *once*. It means that
# __() function defined internally by shellspec is called.
#
# In other words. If not in test mode, __ is just a comment. If test mode, __
# is a interception point.
# you should set ut_mode="true" when you want to run the script in shellspec file.
ut_mode="false"
test || __() {
  # when running in non-unit test mode, set the options "set -ex".
  set -ex;
}

load_common_library() {
  # the kb-common.sh and common.sh scripts are defined in the scripts-template configmap
  # and are mounted to the same path which defined in the cmpd.spec.scripts
  kblib_common_library_file="/scripts/kb-common.sh"
  etcd_common_library_file="/scripts/common.sh"
  # shellcheck source=/scripts/kb-common.sh
  . "${kblib_common_library_file}"
  # shellcheck source=/scripts/common.sh
  . "${etcd_common_library_file}"
}

get_leaver_endpoint() {
  endpoints=$(echo "$KB_MEMBER_ADDRESSES" | tr ',' '\n')
  echo "$endpoints" | grep "$KB_LEAVE_MEMBER_POD_NAME"
}

get_etcd_id() {
  endpoint="$1"
  exec_etcdctl "$endpoint" endpoint status | awk -F', ' '{print $2}'
}

remove_member() {
  etcd_id="$1"
  exec_etcdctl "$KB_MEMBER_ADDRESSES" member remove "$etcd_id"
}

member_leave() {
  leaver_endpoint=$(get_leaver_endpoint)

  if [ -z "$leaver_endpoint" ]; then
    echo "ERROR: leave member pod name not found in member addresses" >&2
    retuen 1
  fi

  etcd_id=$(get_etcd_id "$leaver_endpoint")
  remove_member "$etcd_id"
  return 0
}

# This is magic for shellspec ut framework.
# Sometime, functions are defined in a single shell script.
# You will want to test it. but you do not want to run the script.
# When included from shellspec, __SOURCED__ variable defined and script
# end here. The script path is assigned to the __SOURCED__ variable.
${__SOURCED__:+false} : || return 0

# main
load_common_library
if member_leave; then
  echo "Member leave successfully"
else
  echo "Failed to leave member" >&2
  exit 1
fi
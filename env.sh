# enable/disable sets of tests
export JASMINE_SERVER_UNIT=0
export JASMINE_SERVER_INTEGRATION=1
export JASMINE_CLIENT_UNIT=1
export JASMINE_CLIENT_INTEGRATION=1

if [[ "$@" != '' ]]; then
    exec "$@"
fi

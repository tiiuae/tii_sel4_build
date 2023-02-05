#! /bin/sh

. `pwd`/.config

export SEL4CP_SDK=/workspace/sel4cp/sel4cp/release/sel4cp-sdk-1.2.6

cd ${SEL4CP_SDK}/board/${PLATFORM}/example/$1

exec make BUILD_DIR=/workspace/${PLATFORM}_sel4cp_$1 SEL4CP_SDK=${SEL4CP_SDK} SEL4CP_BOARD=${PLATFORM} SEL4CP_CONFIG=debug

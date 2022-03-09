#
# Copyright 2022, Technology Innovation Institute
#
# SPDX-License-Identifier: BSD-2-Clause
#

set(TII_VM_IMAGES_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE STRING "")
mark_as_advanced(TII_VM_IMAGES_DIR)

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(tii-vm-images DEFAULT_MSG TII_VM_IMAGES_DIR)


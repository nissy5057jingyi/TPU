// Copyright (c) 2011-2024 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef _MEMORY_COPIER_RTL_H_
#define _MEMORY_COPIER_RTL_H_

#ifdef __KERNEL__
    #include <linux/ioctl.h>
    #include <linux/types.h>
#else
    #include <sys/ioctl.h>
    #include <stdint.h>
    #ifndef __user
        #define __user
    #endif
#endif /* __KERNEL__ */

#include <esp.h>
#include <esp_accelerator.h>

struct memory_copier_rtl_access {
    struct esp_access esp;
    /* <<--regs-->> */
	unsigned data_in;
	unsigned enable;
	unsigned data_out;
    unsigned src_offset;
    unsigned dst_offset;
};

#define MEMORY_COPIER_RTL_IOC_ACCESS _IOW('S', 0, struct memory_copier_rtl_access)

#endif /* _MEMORY_COPIER_RTL_H_ */

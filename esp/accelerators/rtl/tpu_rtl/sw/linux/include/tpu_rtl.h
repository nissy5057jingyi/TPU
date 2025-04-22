// Copyright (c) 2011-2024 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef _TPU_RTL_H_
#define _TPU_RTL_H_

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

struct tpu_rtl_access {
    struct esp_access esp;
    /* <<--regs-->> */
	unsigned reg8;
	unsigned reg9;
	unsigned reg4;
	unsigned reg5;
	unsigned reg6;
	unsigned reg7;
	unsigned reg0;
	unsigned reg1;
	unsigned reg2;
	unsigned reg3;
	unsigned reg10;
    unsigned src_offset;
    unsigned dst_offset;
};

#define TPU_RTL_IOC_ACCESS _IOW('S', 0, struct tpu_rtl_access)

#endif /* _TPU_RTL_H_ */

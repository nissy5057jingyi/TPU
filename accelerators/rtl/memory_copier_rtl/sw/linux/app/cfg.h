// Copyright (c) 2011-2024 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "memory_copier_rtl.h"

typedef int32_t token_t;

/* <<--params-def-->> */
#define DATA_IN 32
#define ENABLE 1
#define DATA_OUT 33

/* <<--params-->> */
const int32_t data_in = DATA_IN;
const int32_t enable = ENABLE;
const int32_t data_out = DATA_OUT;

#define NACC 1

struct memory_copier_rtl_access memory_copier_cfg_000[] = {{
    /* <<--descriptor-->> */
		.data_in = DATA_IN,
		.enable = ENABLE,
		.data_out = DATA_OUT,
    .src_offset    = 0,
    .dst_offset    = 0,
    .esp.coherence = ACC_COH_NONE,
    .esp.p2p_store = 0,
    .esp.p2p_nsrcs = 0,
    .esp.p2p_srcs  = {"", "", "", ""},
}};

esp_thread_info_t cfg_000[] = {{
    .run       = true,
    .devname   = "memory_copier_rtl.0",
    .ioctl_req = MEMORY_COPIER_RTL_IOC_ACCESS,
    .esp_desc  = &(memory_copier_cfg_000[0].esp),
}};

#endif /* __ESP_CFG_000_H__ */

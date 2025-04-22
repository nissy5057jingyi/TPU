// Copyright (c) 2011-2024 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "tpu_rtl.h"

typedef int8_t token_t;

/* <<--params-def-->> */
#define REG8 1
#define REG9 1
#define REG4 1
#define REG5 1
#define REG6 1
#define REG7 1
#define REG0 1
#define REG1 1
#define REG2 1
#define REG3 1
#define REG10 1

/* <<--params-->> */
const int32_t reg8 = REG8;
const int32_t reg9 = REG9;
const int32_t reg4 = REG4;
const int32_t reg5 = REG5;
const int32_t reg6 = REG6;
const int32_t reg7 = REG7;
const int32_t reg0 = REG0;
const int32_t reg1 = REG1;
const int32_t reg2 = REG2;
const int32_t reg3 = REG3;
const int32_t reg10 = REG10;

#define NACC 1

struct tpu_rtl_access tpu_cfg_000[] = {{
    /* <<--descriptor-->> */
		.reg8 = REG8,
		.reg9 = REG9,
		.reg4 = REG4,
		.reg5 = REG5,
		.reg6 = REG6,
		.reg7 = REG7,
		.reg0 = REG0,
		.reg1 = REG1,
		.reg2 = REG2,
		.reg3 = REG3,
		.reg10 = REG10,
    .src_offset    = 0,
    .dst_offset    = 0,
    .esp.coherence = ACC_COH_NONE,
    .esp.p2p_store = 0,
    .esp.p2p_nsrcs = 0,
    .esp.p2p_srcs  = {"", "", "", ""},
}};

esp_thread_info_t cfg_000[] = {{
    .run       = true,
    .devname   = "tpu_rtl.0",
    .ioctl_req = TPU_RTL_IOC_ACCESS,
    .esp_desc  = &(tpu_cfg_000[0].esp),
}};

#endif /* __ESP_CFG_000_H__ */

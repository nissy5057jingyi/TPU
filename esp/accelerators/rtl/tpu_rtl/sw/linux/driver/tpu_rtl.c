// Copyright (c) 2011-2024 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "tpu_rtl.h"

#define DRV_NAME "tpu_rtl"

/* <<--regs-->> */
#define TPU_REG8_REG 0x68
#define TPU_REG9_REG 0x64
#define TPU_REG4_REG 0x60
#define TPU_REG5_REG 0x5c
#define TPU_REG6_REG 0x58
#define TPU_REG7_REG 0x54
#define TPU_REG0_REG 0x50
#define TPU_REG1_REG 0x4c
#define TPU_REG2_REG 0x48
#define TPU_REG3_REG 0x44
#define TPU_REG10_REG 0x40

struct tpu_rtl_device {
    struct esp_device esp;
};

static struct esp_driver tpu_driver;

static struct of_device_id tpu_device_ids[] = {
    {
        .name = "SLD_TPU_RTL",
    },
    {
        .name = "eb_04a",
    },
    {
        .compatible = "sld,tpu_rtl",
    },
    {},
};

static int tpu_devs;

static inline struct tpu_rtl_device *to_tpu(struct esp_device *esp)
{
    return container_of(esp, struct tpu_rtl_device, esp);
}

static void tpu_prep_xfer(struct esp_device *esp, void *arg)
{
    struct tpu_rtl_access *a = arg;

    /* <<--regs-config-->> */
	iowrite32be(a->reg8, esp->iomem + TPU_REG8_REG);
	iowrite32be(a->reg9, esp->iomem + TPU_REG9_REG);
	iowrite32be(a->reg4, esp->iomem + TPU_REG4_REG);
	iowrite32be(a->reg5, esp->iomem + TPU_REG5_REG);
	iowrite32be(a->reg6, esp->iomem + TPU_REG6_REG);
	iowrite32be(a->reg7, esp->iomem + TPU_REG7_REG);
	iowrite32be(a->reg0, esp->iomem + TPU_REG0_REG);
	iowrite32be(a->reg1, esp->iomem + TPU_REG1_REG);
	iowrite32be(a->reg2, esp->iomem + TPU_REG2_REG);
	iowrite32be(a->reg3, esp->iomem + TPU_REG3_REG);
	iowrite32be(a->reg10, esp->iomem + TPU_REG10_REG);
    iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
    iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);
}

static bool tpu_xfer_input_ok(struct esp_device *esp, void *arg)
{
    /* struct tpu_rtl_device *tpu = to_tpu(esp); */
    /* struct tpu_rtl_access *a = arg; */

    return true;
}

static int tpu_probe(struct platform_device *pdev)
{
    struct tpu_rtl_device *tpu;
    struct esp_device *esp;
    int rc;

    tpu = kzalloc(sizeof(*tpu), GFP_KERNEL);
    if (tpu == NULL) return -ENOMEM;
    esp         = &tpu->esp;
    esp->module = THIS_MODULE;
    esp->number = tpu_devs;
    esp->driver = &tpu_driver;
    rc          = esp_device_register(esp, pdev);
    if (rc) goto err;

    tpu_devs++;
    return 0;
err:
    kfree(tpu);
    return rc;
}

static int __exit tpu_remove(struct platform_device *pdev)
{
    struct esp_device *esp                        = platform_get_drvdata(pdev);
    struct tpu_rtl_device *tpu = to_tpu(esp);

    esp_device_unregister(esp);
    kfree(tpu);
    return 0;
}

static struct esp_driver tpu_driver = {
    .plat =
        {
            .probe  = tpu_probe,
            .remove = tpu_remove,
            .driver =
                {
                    .name           = DRV_NAME,
                    .owner          = THIS_MODULE,
                    .of_match_table = tpu_device_ids,
                },
        },
    .xfer_input_ok = tpu_xfer_input_ok,
    .prep_xfer     = tpu_prep_xfer,
    .ioctl_cm      = TPU_RTL_IOC_ACCESS,
    .arg_size      = sizeof(struct tpu_rtl_access),
};

static int __init tpu_init(void)
{
    return esp_driver_register(&tpu_driver);
}

static void __exit tpu_exit(void) { esp_driver_unregister(&tpu_driver); }

module_init(tpu_init) module_exit(tpu_exit)

    MODULE_DEVICE_TABLE(of, tpu_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("tpu_rtl driver");

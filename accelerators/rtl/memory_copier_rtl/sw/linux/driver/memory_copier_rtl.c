// Copyright (c) 2011-2024 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "memory_copier_rtl.h"

#define DRV_NAME "memory_copier_rtl"

/* <<--regs-->> */
#define MEMORY_COPIER_DATA_IN_REG 0x48
#define MEMORY_COPIER_ENABLE_REG 0x44
#define MEMORY_COPIER_DATA_OUT_REG 0x40

struct memory_copier_rtl_device {
    struct esp_device esp;
};

static struct esp_driver memory_copier_driver;

static struct of_device_id memory_copier_device_ids[] = {
    {
        .name = "SLD_MEMORY_COPIER_RTL",
    },
    {
        .name = "eb_075",
    },
    {
        .compatible = "sld,memory_copier_rtl",
    },
    {},
};

static int memory_copier_devs;

static inline struct memory_copier_rtl_device *to_memory_copier(struct esp_device *esp)
{
    return container_of(esp, struct memory_copier_rtl_device, esp);
}

static void memory_copier_prep_xfer(struct esp_device *esp, void *arg)
{
    struct memory_copier_rtl_access *a = arg;

    /* <<--regs-config-->> */
	iowrite32be(a->data_in, esp->iomem + MEMORY_COPIER_DATA_IN_REG);
	iowrite32be(a->enable, esp->iomem + MEMORY_COPIER_ENABLE_REG);
	iowrite32be(a->data_out, esp->iomem + MEMORY_COPIER_DATA_OUT_REG);
    iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
    iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);
}

static bool memory_copier_xfer_input_ok(struct esp_device *esp, void *arg)
{
    /* struct memory_copier_rtl_device *memory_copier = to_memory_copier(esp); */
    /* struct memory_copier_rtl_access *a = arg; */

    return true;
}

static int memory_copier_probe(struct platform_device *pdev)
{
    struct memory_copier_rtl_device *memory_copier;
    struct esp_device *esp;
    int rc;

    memory_copier = kzalloc(sizeof(*memory_copier), GFP_KERNEL);
    if (memory_copier == NULL) return -ENOMEM;
    esp         = &memory_copier->esp;
    esp->module = THIS_MODULE;
    esp->number = memory_copier_devs;
    esp->driver = &memory_copier_driver;
    rc          = esp_device_register(esp, pdev);
    if (rc) goto err;

    memory_copier_devs++;
    return 0;
err:
    kfree(memory_copier);
    return rc;
}

static int __exit memory_copier_remove(struct platform_device *pdev)
{
    struct esp_device *esp                        = platform_get_drvdata(pdev);
    struct memory_copier_rtl_device *memory_copier = to_memory_copier(esp);

    esp_device_unregister(esp);
    kfree(memory_copier);
    return 0;
}

static struct esp_driver memory_copier_driver = {
    .plat =
        {
            .probe  = memory_copier_probe,
            .remove = memory_copier_remove,
            .driver =
                {
                    .name           = DRV_NAME,
                    .owner          = THIS_MODULE,
                    .of_match_table = memory_copier_device_ids,
                },
        },
    .xfer_input_ok = memory_copier_xfer_input_ok,
    .prep_xfer     = memory_copier_prep_xfer,
    .ioctl_cm      = MEMORY_COPIER_RTL_IOC_ACCESS,
    .arg_size      = sizeof(struct memory_copier_rtl_access),
};

static int __init memory_copier_init(void)
{
    return esp_driver_register(&memory_copier_driver);
}

static void __exit memory_copier_exit(void) { esp_driver_unregister(&memory_copier_driver); }

module_init(memory_copier_init) module_exit(memory_copier_exit)

    MODULE_DEVICE_TABLE(of, memory_copier_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("memory_copier_rtl driver");

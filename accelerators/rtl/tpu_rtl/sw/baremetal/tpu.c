/* Copyright (c) 2011-2024 Columbia University, System Level Design Group */
/* SPDX-License-Identifier: Apache-2.0 */

#include <stdio.h>
#ifndef __riscv
    #include <stdlib.h>
#endif

#include <esp_accelerator.h>
#include <esp_probe.h>
#include <fixed_point.h>

typedef int8_t token_t;

static unsigned DMA_WORD_PER_BEAT(unsigned _st) { return (sizeof(void *) / _st); }

#define SLD_TPU 0x04a
#define DEV_NAME "sld,tpu_rtl"

/* TPU Configuration Registers */
/* These values need to be properly set based on the hardware configuration */
/* Based on the Verilog file, we need to configure multiple registers */
const int32_t reg0 = 0x0F; /* Enable matmul, norm, pool, activation */
const int32_t reg1 = 0x10; /* Matrix A starting address */
const int32_t reg2 = 0x20; /* Matrix B starting address */
const int32_t reg3 = 0x30; /* Matrix C starting address */
const int32_t reg4 = 0x01; /* Mean value for normalization */
const int32_t reg5 = 0x01; /* Inverse variance for normalization */
const int32_t reg6 = 0x02; /* Pooling window size */
const int32_t reg7 = 0x01; /* Activation type (ReLU=0, TanH=1) */
const int32_t reg8 = 0x10; /* Matrix A stride */
const int32_t reg9 = 0x10; /* Matrix B stride */
const int32_t reg10 = 0x10; /* Matrix C stride and matrix size */

/* Matrix dimensions and TPU configuration */
#define MATRIX_SIZE reg10
#define MATRIX_INPUTS (2*MATRIX_SIZE*MATRIX_SIZE) /* A and B matrices */
#define MATRIX_OUTPUTS (MATRIX_SIZE*MATRIX_SIZE) /* C matrix */

static unsigned in_words_adj;
static unsigned out_words_adj;
static unsigned in_len;
static unsigned out_len;
static unsigned in_size;
static unsigned out_size;
static unsigned out_offset;
static unsigned mem_size;

/* Size of the contiguous chunks for scatter/gather */
#define CHUNK_SHIFT 20
#define CHUNK_SIZE  BIT(CHUNK_SHIFT)
#define NCHUNK(_sz) ((_sz % CHUNK_SIZE == 0) ? (_sz / CHUNK_SIZE) : (_sz / CHUNK_SIZE) + 1)

/* User defined registers */
#define TPU_REG8_REG 0x68  /* Matrix A stride */
#define TPU_REG9_REG 0x64  /* Matrix B stride */
#define TPU_REG4_REG 0x60  /* Mean value */
#define TPU_REG5_REG 0x5c  /* Inverse variance */
#define TPU_REG6_REG 0x58  /* Pooling window size */
#define TPU_REG7_REG 0x54  /* Activation type */
#define TPU_REG0_REG 0x50  /* Enable flags */
#define TPU_REG1_REG 0x4c  /* Matrix A address */
#define TPU_REG2_REG 0x48  /* Matrix B address */
#define TPU_REG3_REG 0x44  /* Matrix C address */
#define TPU_REG10_REG 0x40 /* Matrix C stride / Matrix size */

/* Configuration register for start/done */
#define TPU_START_REG 0x70  /* Start TPU execution */

/* Function to initialize input matrices and expected output */
static void init_buf(token_t *in, token_t *gold)
{
    int i, j, k;
    token_t *matA, *matB;
    
    /* Initialize matrix A and B with some pattern */
    matA = in;
    matB = in + MATRIX_SIZE * MATRIX_SIZE;
    
    /* Initialize matrices with pattern */
    for (i = 0; i < MATRIX_SIZE; i++) {
        for (j = 0; j < MATRIX_SIZE; j++) {
            matA[i * MATRIX_SIZE + j] = (token_t)(i + j);  /* Matrix A */
            matB[i * MATRIX_SIZE + j] = (token_t)(i * j);  /* Matrix B */
        }
    }
    
    /* Calculate expected output (matrix multiplication) */
    for (i = 0; i < MATRIX_SIZE; i++) {
        for (j = 0; j < MATRIX_SIZE; j++) {
            token_t sum = 0;
            for (k = 0; k < MATRIX_SIZE; k++) {
                sum += matA[i * MATRIX_SIZE + k] * matB[k * MATRIX_SIZE + j];
            }
            /* Apply normalization, pooling and activation if enabled */
            /* For simplicity, just storing matrix multiply result */
            gold[i * MATRIX_SIZE + j] = sum;
        }
    }
}

/* Function to validate the output against expected results */
static int validate_buf(token_t *out, token_t *gold)
{
    int i, j;
    unsigned errors = 0;
    
    /* Check results */
    for (i = 0; i < MATRIX_SIZE; i++) {
        for (j = 0; j < MATRIX_SIZE; j++) {
            if (gold[i * MATRIX_SIZE + j] != out[i * MATRIX_SIZE + j]) {
                errors++;
                printf("Mismatch at [%d,%d]: expected %d, got %d\n", 
                       i, j, gold[i * MATRIX_SIZE + j], out[i * MATRIX_SIZE + j]);
                /* Limit error reporting */
                if (errors > 10) return errors;
            }
        }
    }
    
    return errors;
}

int main(int argc, char *argv[])
{
    int i;
    int n;
    int ndev;
    struct esp_device *espdevs;
    struct esp_device *dev;
    unsigned done;
    unsigned **ptable;
    token_t *mem;
    token_t *gold;
    unsigned errors = 0;
    unsigned coherence;

    /* Calculate adjusted sizes for DMA transfers */
    if (DMA_WORD_PER_BEAT(sizeof(token_t)) == 0) {
        in_words_adj = MATRIX_INPUTS;
        out_words_adj = MATRIX_OUTPUTS;
    } else {
        in_words_adj = round_up(MATRIX_INPUTS, DMA_WORD_PER_BEAT(sizeof(token_t)));
        out_words_adj = round_up(MATRIX_OUTPUTS, DMA_WORD_PER_BEAT(sizeof(token_t)));
    }
    
    in_len = in_words_adj;
    out_len = out_words_adj;
    in_size = in_len * sizeof(token_t);
    out_size = out_len * sizeof(token_t);
    out_offset = in_len;
    mem_size = (out_offset * sizeof(token_t)) + out_size;

    /* Search for the TPU device */
    printf("Scanning device tree...\n");
    ndev = probe(&espdevs, VENDOR_SLD, SLD_TPU, DEV_NAME);
    if (ndev == 0) {
        printf("TPU device not found\n");
        return 0;
    }

    for (n = 0; n < ndev; n++) {
        printf("**************** %s.%d ****************\n", DEV_NAME, n);
        dev = &espdevs[n];

        /* Check DMA capabilities */
        if (ioread32(dev, PT_NCHUNK_MAX_REG) == 0) {
            printf("  -> scatter-gather DMA is disabled. Abort.\n");
            return 0;
        }

        if (ioread32(dev, PT_NCHUNK_MAX_REG) < NCHUNK(mem_size)) {
            printf("  -> Not enough TLB entries available. Abort.\n");
            return 0;
        }

        /* Allocate memory */
        gold = aligned_malloc(out_size);
        mem = aligned_malloc(mem_size);
        printf("  memory buffer base-address = %p\n", mem);

        /* Allocate and populate page table */
        ptable = aligned_malloc(NCHUNK(mem_size) * sizeof(unsigned *));
        for (i = 0; i < NCHUNK(mem_size); i++)
            ptable[i] = (unsigned *)&mem[i * (CHUNK_SIZE / sizeof(token_t))];

        printf("  ptable = %p\n", ptable);
        printf("  nchunk = %lu\n", NCHUNK(mem_size));

        for (coherence = ACC_COH_NONE; coherence <= ACC_COH_RECALL; coherence++) {
            printf("  --------------------\n");
            printf("  Testing coherence mode: %d\n", coherence);
            printf("  Generate input matrices...\n");
            init_buf(mem, gold);

            /* Pass common configuration parameters */
            iowrite32(dev, COHERENCE_REG, coherence);

#ifndef __sparc
            iowrite32(dev, PT_ADDRESS_REG, (unsigned long long)ptable);
#else
            iowrite32(dev, PT_ADDRESS_REG, (unsigned)ptable);
#endif
            iowrite32(dev, PT_NCHUNK_REG, NCHUNK(mem_size));
            iowrite32(dev, PT_SHIFT_REG, CHUNK_SHIFT);

            /* Set up DMA source and destination offsets */
            iowrite32(dev, SRC_OFFSET_REG, 0x0);
            iowrite32(dev, DST_OFFSET_REG, out_offset * sizeof(token_t));

            /* Configure TPU registers based on Verilog definitions */
            iowrite32(dev, TPU_REG0_REG, reg0);     /* Enable flags */
            iowrite32(dev, TPU_REG1_REG, reg1);     /* Matrix A address */
            iowrite32(dev, TPU_REG2_REG, reg2);     /* Matrix B address */
            iowrite32(dev, TPU_REG3_REG, reg3);     /* Matrix C address */
            iowrite32(dev, TPU_REG4_REG, reg4);     /* Mean value */
            iowrite32(dev, TPU_REG5_REG, reg5);     /* Inverse variance */
            iowrite32(dev, TPU_REG6_REG, reg6);     /* Pooling window size */
            iowrite32(dev, TPU_REG7_REG, reg7);     /* Activation type */
            iowrite32(dev, TPU_REG8_REG, reg8);     /* Matrix A stride */
            iowrite32(dev, TPU_REG9_REG, reg9);     /* Matrix B stride */
            iowrite32(dev, TPU_REG10_REG, reg10);   /* Matrix size/C stride */

            /* Flush cache for coherence */
            esp_flush(coherence);

            /* Start the TPU */
            printf("  Starting TPU operation...\n");
            iowrite32(dev, CMD_REG, CMD_MASK_START);

            /* Wait for completion */
            done = 0;
            while (!done) {
                done = ioread32(dev, STATUS_REG);
                done &= STATUS_MASK_DONE;
            }
            iowrite32(dev, CMD_REG, 0x0);

            printf("  TPU operation completed\n");
            printf("  Validating results...\n");

            /* Validate the output */
            errors = validate_buf(&mem[out_offset], gold);
            if (errors)
                printf("  ... FAIL (%d errors)\n", errors);
            else
                printf("  ... PASS\n");
        }
        
        /* Free allocated memory */
        aligned_free(ptable);
        aligned_free(mem);
        aligned_free(gold);
    }

    return 0;
}
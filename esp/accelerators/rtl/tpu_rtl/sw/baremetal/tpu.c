/* Copyright (c) 2011-2024 Columbia University, System Level Design Group */
/* SPDX-License-Identifier: Apache-2.0 */

#include <stdio.h>
#ifndef __riscv
    #include <stdlib.h>
#endif

#include <esp_accelerator.h>
#include <esp_probe.h>
#include <fixed_point.h>

typedef int32_t token_t;  // TPU uses 32-bit data

static unsigned DMA_WORD_PER_BEAT(unsigned _st) { return (sizeof(void *) / _st); }

#define SLD_TPU_BASIC_DMA32 0x04b  // Unique device ID for TPU
#define DEV_NAME            "sld,tpu_rtl_basic_dma32"

/* Configuration parameters for the TPU */
const int32_t data_in_size = 128;   // Number of input elements
const int32_t data_out_size = 128;  // Number of output elements
const int32_t activation_type = 1;  // 0: None, 1: ReLU, 2: TanH
const int32_t pooling_size = 2;     // 1: 1x1 (no pooling), 2: 2x2, 4: 4x4
const int32_t norm_enable = 1;      // 0: Disabled, 1: Enabled

/* Matrix dimensions for test */
#define MATRIX_DIM 8 // 8x8 matrix (64 elements)

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

/* User defined registers - match the wrapper RTL module */
#define TPU_DATA_IN_REG         0x40
#define TPU_DATA_OUT_REG        0x44
#define TPU_ACTIVATION_REG      0x48
#define TPU_POOLING_REG         0x4C
#define TPU_NORM_REG            0x50
#define TPU_CONF_DONE_REG       0x34

/* Simple matrix multiplication to generate gold output */
static void matrix_multiply(token_t *a, token_t *b, token_t *c, int dim) {
    for (int i = 0; i < dim; i++) {
        for (int j = 0; j < dim; j++) {
            c[i * dim + j] = 0;
            for (int k = 0; k < dim; k++) {
                c[i * dim + j] += a[i * dim + k] * b[k * dim + j];
            }
            
            // Apply ReLU activation if enabled
            if (activation_type == 1 && c[i * dim + j] < 0) {
                c[i * dim + j] = 0;
            }
            // Apply TanH activation if enabled (simplified tanh approximation)
            else if (activation_type == 2) {
                if (c[i * dim + j] > 127) c[i * dim + j] = 127;
                else if (c[i * dim + j] < -127) c[i * dim + j] = -127;
            }
        }
    }
    
    // Apply pooling if enabled (simple 2x2 max pooling)
    if (pooling_size > 1) {
        int pool_dim = dim / pooling_size;
        token_t *temp = (token_t *) malloc(dim * dim * sizeof(token_t));
        memcpy(temp, c, dim * dim * sizeof(token_t));
        
        for (int i = 0; i < pool_dim; i++) {
            for (int j = 0; j < pool_dim; j++) {
                token_t max_val = temp[i * 2 * dim + j * 2];
                for (int pi = 0; pi < pooling_size; pi++) {
                    for (int pj = 0; pj < pooling_size; pj++) {
                        token_t val = temp[(i * 2 + pi) * dim + (j * 2 + pj)];
                        if (val > max_val) max_val = val;
                    }
                }
                c[i * pool_dim + j] = max_val;
            }
        }
        free(temp);
    }
}

static int validate_buf(token_t *out, token_t *gold) {
    int errors = 0;
    int output_size = data_out_size;
    
    // If pooling is enabled, the output size is reduced
    if (pooling_size > 1) {
        output_size = data_out_size / (pooling_size * pooling_size);
    }
    
    for (int i = 0; i < output_size; i++) {
        if (gold[i] != out[i]) {
            printf("Error at index %d: expected %d, got %d\n", i, gold[i], out[i]);
            errors++;
            // Limit error reporting to avoid flood
            if (errors > 10) {
                printf("Too many errors, stopping validation...\n");
                break;
            }
        }
    }

    return errors;
}

static void init_buf(token_t *in, token_t *gold) {
    // Split input buffer into matrix A and matrix B
    token_t *matrix_a = in;
    token_t *matrix_b = in + MATRIX_DIM * MATRIX_DIM;
    
    // Initialize matrix A with incrementing values
    for (int i = 0; i < MATRIX_DIM; i++) {
        for (int j = 0; j < MATRIX_DIM; j++) {
            matrix_a[i * MATRIX_DIM + j] = i + j;
        }
    }
    
    // Initialize matrix B with some pattern
    for (int i = 0; i < MATRIX_DIM; i++) {
        for (int j = 0; j < MATRIX_DIM; j++) {
            matrix_b[i * MATRIX_DIM + j] = (i == j) ? 2 : 1; // Simple identity matrix with offset
        }
    }
    
    // Calculate expected output for validation
    matrix_multiply(matrix_a, matrix_b, gold, MATRIX_DIM);
    
    // Print sample of input and expected output
    printf("Sample input matrix A:\n");
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            printf("%4d ", matrix_a[i * MATRIX_DIM + j]);
        }
        printf("\n");
    }
    
    printf("Sample input matrix B:\n");
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            printf("%4d ", matrix_b[i * MATRIX_DIM + j]);
        }
        printf("\n");
    }
    
    printf("Sample expected output:\n");
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            printf("%4d ", gold[i * MATRIX_DIM + j]);
        }
        printf("\n");
    }
}

int main(int argc, char *argv[]) {
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

    // Calculate DMA word adjustments
    if (DMA_WORD_PER_BEAT(sizeof(token_t)) == 0) {
        in_words_adj  = data_in_size;
        out_words_adj = data_out_size;
    } else {
        in_words_adj  = round_up(data_in_size, DMA_WORD_PER_BEAT(sizeof(token_t)));
        out_words_adj = round_up(data_out_size, DMA_WORD_PER_BEAT(sizeof(token_t)));
    }
    
    in_len     = in_words_adj;
    out_len    = out_words_adj;
    in_size    = in_len * sizeof(token_t);
    out_size   = out_len * sizeof(token_t);
    out_offset = in_len;
    mem_size   = (out_offset * sizeof(token_t)) + out_size;

    // Search for the device
    printf("Scanning device tree for %s...\n", DEV_NAME);

    ndev = probe(&espdevs, VENDOR_SLD, SLD_TPU_BASIC_DMA32, DEV_NAME);
    if (ndev == 0) {
        printf("TPU accelerator not found\n");
        return 0;
    }

    for (n = 0; n < ndev; n++) {
        printf("**************** %s.%d ****************\n", DEV_NAME, n);

        dev = &espdevs[n];

        // Check DMA capabilities
        if (ioread32(dev, PT_NCHUNK_MAX_REG) == 0) {
            printf("  -> scatter-gather DMA is disabled. Abort.\n");
            return 0;
        }

        if (ioread32(dev, PT_NCHUNK_MAX_REG) < NCHUNK(mem_size)) {
            printf("  -> Not enough TLB entries available. Abort.\n");
            return 0;
        }

        // Allocate memory
        gold = aligned_malloc(out_size);
        mem  = aligned_malloc(mem_size);
        printf("  memory buffer base-address = %p\n", mem);

        // Allocate and populate page table
        ptable = aligned_malloc(NCHUNK(mem_size) * sizeof(unsigned *));
        for (i = 0; i < NCHUNK(mem_size); i++)
            ptable[i] = (unsigned *)&mem[i * (CHUNK_SIZE / sizeof(token_t))];

        printf("  ptable = %p\n", ptable);
        printf("  nchunk = %lu\n", NCHUNK(mem_size));

        // Test different coherence models
        for (coherence = ACC_COH_NONE; coherence <= ACC_COH_RECALL; coherence++) {
            printf("  --------------------\n");
            printf("  Testing coherence mode: %d\n", coherence);
            printf("  Generate input data...\n");
            init_buf(mem, gold);

            // Pass common configuration parameters
            iowrite32(dev, COHERENCE_REG, coherence);

#ifndef __sparc
            iowrite32(dev, PT_ADDRESS_REG, (unsigned long long)ptable);
#else
            iowrite32(dev, PT_ADDRESS_REG, (unsigned)ptable);
#endif
            iowrite32(dev, PT_NCHUNK_REG, NCHUNK(mem_size));
            iowrite32(dev, PT_SHIFT_REG, CHUNK_SHIFT);

            // Use the following if input and output data are not allocated at the default offsets
            iowrite32(dev, SRC_OFFSET_REG, 0x0);
            iowrite32(dev, DST_OFFSET_REG, out_offset * sizeof(token_t));

            // Pass TPU-specific configuration parameters
            iowrite32(dev, TPU_DATA_IN_REG, data_in_size);
            iowrite32(dev, TPU_DATA_OUT_REG, data_out_size);
            iowrite32(dev, TPU_ACTIVATION_REG, activation_type);
            iowrite32(dev, TPU_POOLING_REG, pooling_size);
            iowrite32(dev, TPU_NORM_REG, norm_enable);

            // Flush (customize coherence model here)
            esp_flush(coherence);
            
            // Kick off accelerator
            printf("  Setting configuration done...\n");
            iowrite32(dev, TPU_CONF_DONE_REG, 1);
            
            // Start accelerator
            printf("  Starting TPU accelerator...\n");
            iowrite32(dev, CMD_REG, CMD_MASK_START);

            // Wait for completion
            done = 0;
            while (!done) {
                done = ioread32(dev, STATUS_REG);
                done &= STATUS_MASK_DONE;
            }
            
            // Reset control signals
            iowrite32(dev, CMD_REG, 0x0);
            iowrite32(dev, TPU_CONF_DONE_REG, 0);

            printf("  TPU execution completed\n");
            printf("  Validating results...\n");

            /* Validation */
            errors = validate_buf(&mem[out_offset], gold);
            if (errors) printf("  ... FAIL (%d errors)\n", errors);
            else printf("  ... PASS\n");
        }
        
        // Free memory
        aligned_free(ptable);
        aligned_free(mem);
        aligned_free(gold);
    }

    return 0;
}
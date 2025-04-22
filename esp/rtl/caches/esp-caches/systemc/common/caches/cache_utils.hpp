// Copyright (c) 2011-2024 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0

#ifndef __CACHE_UTILS_HPP__
#define __CACHE_UTILS_HPP__

#include "cache_consts.hpp"
#include "cache_types.hpp"
#include "utils/esp_systemc.hpp"
#include "utils/esp_utils.hpp"
#include <iostream>
#include <utility>

#define CACHE_REPORT_INFO(text) \
    cerr << "Info:  " << sc_object::basename() << ".\t " << text << endl;

#define CACHE_REPORT_ERROR(text, var) \
    cerr << hex << "ERROR: " << sc_object::basename() << ".\t " << text << " : " << var << endl;

#define CACHE_REPORT_TIME(time, text) \
    cerr << "Info:  " << sc_object::basename() << ".\t @" << time << " : " << text << endl;

#define CACHE_REPORT_VAR(time, text, var)                                                          \
    cerr << "Info:  " << sc_object::basename() << ".\t @" << time << " : " << text << " : " << var \
         << endl;

#define CACHE_REPORT_DEBUG(time, text, var)                                                  \
    cerr << "Debug:  " << sc_object::basename() << ".\t @" << time << " : " << text << " : " \
         << var << endl;

#define __str(s)  #s
#define __xstr(s) __str(s)

#define IMP_MEM_NAME(A, B, C, D) A##_##B##_##C##sets_##D##ways

#define IMP_MEM_NAME_STRING(a, b, c, d) __xstr(IMP_MEM_NAME(a, b, c, d))

#define EXP_MEM_TYPE(A, B, C, D) A##_##B##_##C##sets_##D##ways_t

#define EXP_MEM_TYPE_STRING(a, b, c, d) EXP_MEM_TYPE(a, b, c, d)

#define EXP_MEM_INCLUDE(A, B, C, D) A##_##B##_##C##sets_##D##ways.hpp

#define EXP_MEM_INCLUDE_STRING(a, b, c, d) __xstr(EXP_MEM_INCLUDE(a, b, c, d))

inline void write_word(line_t &line, word_t word, word_offset_t w_off, byte_offset_t b_off,
                       hsize_t hsize)
{
    uint32_t b_off_tmp = 0;

#ifdef ENDIAN_BIG_ENDIAN

    switch (hsize) {
        case BYTE: b_off_tmp = BYTES_PER_WORD - 1 - b_off; break;
        case HALFWORD: b_off_tmp = BYTES_PER_WORD - BYTES_PER_WORD / 2 - b_off; break;
    #if (BYTES_PER_WORD == 4)
        default: b_off_tmp = 0; break;
    #else
        case WORD_32: b_off_tmp = BYTES_PER_WORD - BYTES_PER_WORD / 4 - b_off; break;
        default: b_off_tmp = 0; break;
    #endif
    }

#else // ENDIAN_LITTLE_ENDIAN

    b_off_tmp = b_off;

#endif

    uint32_t w_off_bits = BITS_PER_WORD * w_off;
    uint32_t b_off_bits = 8 * b_off_tmp;
    uint32_t off_bits   = w_off_bits + b_off_bits;

    // uint32_t word_range_hi = b_off_bits + size - 1;
    // uint32_t line_range_hi = off_bits + size - 1;

    // cerr << "line_range_hi: " << line_range_hi << ", word_range_hi: " << word_range_hi << endl;
    // cerr << "off_bits: " << off_bits << ", b_off_bits: " << b_off_bits << endl;
    if (hsize == BYTE) line.range(off_bits + 7, off_bits) = word.range(b_off_bits + 7, b_off_bits);
    else if (hsize == HALFWORD)
        line.range(off_bits + 15, off_bits) = word.range(b_off_bits + 15, b_off_bits);
    else if (hsize == WORD_32)
        line.range(off_bits + 31, off_bits) = word.range(b_off_bits + 31, b_off_bits);
    else if (BYTE_BITS != 2)
        line.range(off_bits + 63, off_bits) = word.range(b_off_bits + 63, b_off_bits);
}

inline word_t read_word(line_t line, word_offset_t w_off)
{
    word_t word;
    word = (sc_uint<BITS_PER_WORD>)line.range(BITS_PER_WORD * w_off + BITS_PER_WORD - 1,
                                              BITS_PER_WORD * w_off);

    return word;
}

inline void rand_wait()
{
    int waits = rand() % 5;

    for (int i = 0; i < waits; i++)
        wait();
}

inline addr_breakdown_t rand_addr()
{
    addr_t addr                    = (rand() % (1 << ADDR_BITS - 1)); // MSB always set to 0
    addr.range(OFFSET_BITS - 1, 0) = 0;
    addr_breakdown_t addr_br;
    addr_br.breakdown(addr);
    return addr_br;
}

inline addr_breakdown_llc_t rand_addr_llc()
{
    addr_t addr                    = (rand() % (1 << ADDR_BITS - 1)); // MSB always set to 0
    addr.range(OFFSET_BITS - 1, 0) = 0;
    addr_breakdown_llc_t addr_br;
    addr_br.breakdown(addr);
    return addr_br;
}

inline word_t rand_word()
{
    word_t word;

#if (BITS_PER_WORD == 64)
    word = (((word_t)(rand() % (1 << 31))) << 32) + (rand() % (1 << 31));
#else
    word      = (rand() % (1 << BITS_PER_WORD - 1));
#endif

    return word;
}

inline line_t line_of_addr(addr_t addr)
{
    line_t line;

    for (int i = 0; i < WORDS_PER_LINE; ++i) {
#if (BITS_PER_WORD == 64)
        addr_t tmp_addr = addr + (i * WORD_OFFSET);
        write_word(line, (tmp_addr << 32) + tmp_addr, i, 0, WORD);
#else
        write_word(line, addr + (i * WORD_OFFSET), i, 0, WORD);
#endif
    }

    return line;
}

inline word_t word_of_addr(addr_t addr)
{
    word_t word;

#if (BITS_PER_WORD == 64)
    word = ((word_t)addr << 32) + addr;
#else
    word = addr;
#endif

    return word;
}

#endif /* __CACHE_UTILS_HPP__ */

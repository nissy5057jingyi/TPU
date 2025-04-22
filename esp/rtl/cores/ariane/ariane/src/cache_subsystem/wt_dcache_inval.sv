// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Paolo Mantovani <paolo.mantovani@columbia.edu>, Columbia University, New York NY
// Description: invalidation request unit
//
// This module receives an invalidation request from the bus in the form of a valid bit and
// the physical address for the request.
// Invalidation occurs then in two steps. First, a cache read is performed to look check if
// the target TAG is present in the L1 cache. If the look up returns a hit, an invalidation
// request for the vorresponding way is sent to the miss unit which executes the invalidation.
//

import ariane_pkg::*;
import wt_cache_pkg::*;

module wt_dcache_inval #(
  parameter ariane_pkg::ariane_cfg_t         ArianeCfg = ariane_pkg::ArianeDefaultConfig
) (
  input  logic                               clk_i,             // Clock
  input  logic                               rst_ni,            // Asynchronous reset active low
  // request port from bus
  input  logic                               mem_inv_req_i,     // invalidate request
  input  logic [riscv::PLEN-1:0]             mem_inv_paddr_i,   // physical address to invalidate
  output logic                               mem_inv_ack_o,     // invalidate request ack
  // cache read interface
  output logic [DCACHE_TAG_WIDTH-1:0]        rd_tag_o,          // tag computed from paddr
  output logic [DCACHE_CL_IDX_WIDTH-1:0]     rd_idx_o,          // index computed from the paddr
  output logic [DCACHE_OFFSET_WIDTH-1:0]     rd_off_o,          // byte offset unused for invalidation
  output logic                               rd_req_o,          // read request for all ways and index rd_idx_o
  output logic                               rd_tag_only_o,     // set to 1 here as we do not have to read the data arrays
  input  logic                               rd_ack_i,
  input  logic  [63:0]                       rd_data_i,         // unused
  input  logic  [DCACHE_SET_ASSOC-1:0]       rd_vld_bits_i,     // valid ways at index rd_idx_o
  input  logic  [DCACHE_SET_ASSOC-1:0]       rd_hit_oh_i,       // onehot hit array indicating if a way matches rd_tag_o
  // to missunit
  output cache_inval_t                       inv_req_o,         // invalidation request for line inv_req_o.idx, inv_req_o.way
  input  logic                               inv_ack_i
);

  enum logic [1:0] { IDLE, INV_REQ, WAIT_INV } state_d, state_q;

  logic [DCACHE_INDEX_WIDTH-1:0] inv_idx_d, inv_idx_q;
  logic [DCACHE_SET_ASSOC-1:0]       inv_way_d, inv_way_q;

  logic rd_req, save_idx, save_way, save_tag, hit, inv_req;

  logic [DCACHE_TAG_WIDTH-1:0] cmp_tag_d, cmp_tag_q;

  // cache read
  assign cmp_tag_d     = (save_tag) ? mem_inv_paddr_i[ariane_pkg::DCACHE_TAG_WIDTH     +
                                                      ariane_pkg::DCACHE_INDEX_WIDTH-1 :
                                                      ariane_pkg::DCACHE_INDEX_WIDTH]    :
                                      cmp_tag_q;
  assign rd_tag_o      = cmp_tag_d;
  assign rd_idx_o      = mem_inv_paddr_i[ariane_pkg::DCACHE_INDEX_WIDTH-1:DCACHE_OFFSET_WIDTH];
  assign rd_off_o      = '0;
  assign rd_tag_only_o = 1'b1;
  assign rd_req_o      = rd_req;

    // save invalidate request
  assign inv_way_d = (save_way) ? (rd_vld_bits_i & rd_hit_oh_i)                       : inv_way_q;
  assign inv_idx_d = (save_idx) ? mem_inv_paddr_i[ariane_pkg::DCACHE_INDEX_WIDTH-1:0] : inv_idx_q;
  assign hit       = |(rd_vld_bits_i & rd_hit_oh_i);

  // invalidate request
  assign inv_req_o.vld = inv_req;
  assign inv_req_o.all = 1'b0; // only invalidate target way
  assign inv_req_o.idx = inv_idx_q;

  always_comb begin : way_oh2bin
     integer i;
     inv_req_o.way = '0;
     for (i = 0; i < DCACHE_SET_ASSOC; i = i + 1) begin
         if (inv_way_d[i] == 1'b1) begin
            inv_req_o.way = i;
         end
     end
  end

  // ---------------------
  // Invalidate Control
  // --------------------
  always_comb begin : invalidate_control
     state_d       = state_q;

     save_idx      = 1'b0;
     save_way      = 1'b0;
     save_tag      = 1'b0;

     inv_req       = 1'b0;
     rd_req        = 1'b0;

     mem_inv_ack_o = 1'b0;

     case (state_q)
       //////////////////////////////////
       // wait for an incoming request
       IDLE : begin
          if (mem_inv_req_i) begin
             rd_req   = 1'b1;
             save_tag = 1'b1;
             if (rd_ack_i) begin
                state_d       = INV_REQ;
                save_idx      = 1'b1;
                mem_inv_ack_o = 1'b1;
             end
          end
       end

       //////////////////////////////////
       // send invalidate req to missunit
       // if the lookup returns a hit
       INV_REQ : begin
          save_way = 1'b1;
          inv_req  = hit;
          if (hit & ~inv_ack_i)
            state_d = WAIT_INV;
          else
            state_d = IDLE;
       end

       //////////////////////////////////
       // wait invalidate ack
       WAIT_INV : begin
          inv_req = 1'b1;
          if (inv_ack_i)
            state_d = IDLE;
       end

       default : begin
          state_d = IDLE;
       end

     endcase
  end


  always_ff @(posedge clk_i or negedge rst_ni) begin : p_regs
     if (~rst_ni) begin
        state_q   <= IDLE;
        inv_idx_q <= '0;
        inv_way_q <= '0;
        cmp_tag_q <= '0;
     end else begin
        state_q   <= state_d;
        inv_idx_q <= inv_idx_d;
        inv_way_q <= inv_way_d;
        cmp_tag_q <= cmp_tag_d;
     end
  end

endmodule

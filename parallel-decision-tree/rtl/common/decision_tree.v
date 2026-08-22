`timescale 1ns/1ps

// One decision-tree processing unit (UN).
// A-Memory and C-Memory are intentionally local to each instance, matching
// the three-UN architecture. AD-Memory is supplied by the shared ad_ro block.
module decision_tree #(
    parameter ATTR_NUM         = 4,
    parameter ATTR_NUM_ENC     = 2,
    parameter WORD_LEN         = 8,
    parameter ND_NUM_ENC       = 5,
    parameter CLASS_ENC        = 2,
    parameter MAX_ND           = 32,
    parameter ADDER_TREE_DEPTH = 2,
    parameter FRAC_BITS        = 4
)(
    input  wire [(ATTR_NUM*WORD_LEN)-1:0] attr_bus,
    input  wire [ND_NUM_ENC-1:0]          node_num,
    input  wire [ND_NUM_ENC-1:0]          ad_left,
    input  wire [ND_NUM_ENC-1:0]          ad_right,
    output reg                             direction,
    output reg  [CLASS_ENC-1:0]           class_out,
    output reg  [ND_NUM_ENC-1:0]          next_node,
    output reg signed [(2*WORD_LEN)+ATTR_NUM_ENC:0] score_dbg
);

    localparam [CLASS_ENC-1:0]  INVALID_CLASS = {CLASS_ENC{1'b1}};
    localparam [ND_NUM_ENC-1:0] INVALID_NODE  = {ND_NUM_ENC{1'b1}};

    // Flattened A-Memory: coefficient(node, attribute).
    reg signed [WORD_LEN-1:0] a_memory [0:(MAX_ND*ATTR_NUM)-1];
    reg signed [(2*WORD_LEN)+ATTR_NUM_ENC:0] threshold_memory [0:MAX_ND-1];
    reg [CLASS_ENC-1:0] c_memory [0:MAX_ND-1];

    integer init_i;
    integer attr_i;
    integer dot_acc;

    initial begin
        for (init_i = 0; init_i < (MAX_ND*ATTR_NUM); init_i = init_i + 1)
            a_memory[init_i] = 0;

        for (init_i = 0; init_i < MAX_ND; init_i = init_i + 1) begin
            threshold_memory[init_i] = 0;
            c_memory[init_i] = INVALID_CLASS;
        end

        // One-hot Q4.4 coefficients. Every internal node compares one feature
        // with zero while retaining the recovered M2 dot-product data path.
        a_memory[(0*ATTR_NUM)+0]  = 16;
        a_memory[(1*ATTR_NUM)+1]  = 16;
        a_memory[(2*ATTR_NUM)+1]  = 16;
        a_memory[(3*ATTR_NUM)+2]  = 16;
        a_memory[(5*ATTR_NUM)+2]  = 16;
        a_memory[(6*ATTR_NUM)+2]  = 16;
        a_memory[(7*ATTR_NUM)+3]  = 16;
        a_memory[(12*ATTR_NUM)+3] = 16;

        // Reconstructed leaf-class map. 2'b11 is reserved as INVALID_CLASS,
        // so the regression tree uses class IDs 0, 1 and 2.
        c_memory[4]  = 2'd0;
        c_memory[8]  = 2'd1;
        c_memory[9]  = 2'd2;
        c_memory[10] = 2'd1;
        c_memory[11] = 2'd0;
        c_memory[13] = 2'd1;
        c_memory[14] = 2'd2;
        c_memory[15] = 2'd2;
        c_memory[16] = 2'd0;
    end

    always @(*) begin
        dot_acc  = 0;
        direction = 1'b0;
        class_out = INVALID_CLASS;
        next_node = INVALID_NODE;
        score_dbg = 0;

        if (node_num < MAX_ND) begin
            for (attr_i = 0; attr_i < ATTR_NUM; attr_i = attr_i + 1) begin
                dot_acc = dot_acc
                        + $signed(attr_bus[(attr_i*WORD_LEN) +: WORD_LEN])
                        * $signed(a_memory[(node_num*ATTR_NUM)+attr_i]);
            end

            score_dbg = dot_acc;
            class_out = c_memory[node_num];

            if (c_memory[node_num] == INVALID_CLASS) begin
                direction = (dot_acc >= threshold_memory[node_num]);
                next_node = direction ? ad_right : ad_left;
            end
        end
    end

endmodule

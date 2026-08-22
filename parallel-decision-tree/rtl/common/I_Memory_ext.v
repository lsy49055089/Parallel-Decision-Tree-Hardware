`timescale 1ns/1ps

// External input-vector memory shared by UN1, UN2 and UN3.
//
// Recovery note:
// The original project used 37 vectors with four signed Q4.4 attributes.
// The original initialization values were not present in the recoverable chat
// fragments, so this version uses a deterministic nine-path regression set.
module I_Memory_ext #(
    parameter ATTR_NUM   = 4,
    parameter WORD_LEN   = 8,
    parameter IN_NUM_ENC = 6,
    parameter IN_NUM     = 37
)(
    input  wire [IN_NUM_ENC-1:0]             vec_id,
    output wire [(ATTR_NUM*WORD_LEN)-1:0]     attr_bus
);

    reg [(ATTR_NUM*WORD_LEN)-1:0] memory [0:IN_NUM-1];
    integer i;

    function [(ATTR_NUM*WORD_LEN)-1:0] vector_for_index;
        input integer index;
        reg signed [WORD_LEN-1:0] x0;
        reg signed [WORD_LEN-1:0] x1;
        reg signed [WORD_LEN-1:0] x2;
        reg signed [WORD_LEN-1:0] x3;
        begin
            // +/-1.0 in signed Q4.4.
            x0 =  16;
            x1 =  16;
            x2 =  16;
            x3 =  16;

            // Each pattern reaches one terminal leaf in the recovered tree.
            case (index % 9)
                0: begin x0 = -16; x1 =  16; x2 =  16; x3 =  16; end // leaf 4
                1: begin x0 = -16; x1 = -16; x2 =  16; x3 =  16; end // leaf 8
                2: begin x0 = -16; x1 = -16; x2 = -16; x3 = -16; end // leaf 13
                3: begin x0 = -16; x1 = -16; x2 = -16; x3 =  16; end // leaf 14
                4: begin x0 =  16; x1 = -16; x2 = -16; x3 =  16; end // leaf 9
                5: begin x0 =  16; x1 = -16; x2 =  16; x3 =  16; end // leaf 10
                6: begin x0 =  16; x1 =  16; x2 = -16; x3 =  16; end // leaf 11
                7: begin x0 =  16; x1 =  16; x2 =  16; x3 = -16; end // leaf 15
                8: begin x0 =  16; x1 =  16; x2 =  16; x3 =  16; end // leaf 16
                default: begin x0 = 16; x1 = 16; x2 = 16; x3 = 16; end
            endcase

            // Attribute 0 occupies the least-significant byte.
            vector_for_index = {x3, x2, x1, x0};
        end
    endfunction

    initial begin
        for (i = 0; i < IN_NUM; i = i + 1)
            memory[i] = vector_for_index(i);
    end

    assign attr_bus = (vec_id < IN_NUM) ? memory[vec_id] : {(ATTR_NUM*WORD_LEN){1'b0}};

endmodule

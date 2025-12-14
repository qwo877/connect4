module win_judge (
    input clk,
    input rst_n,

    input [41:0] occupied,
    input [41:0] whos,

    output reg  op_ready,
    input       op_valid,

    input       re_ready,
    output reg  re_valid,
    output reg  re_is_finished
);

localparam S_IDLE = 0,
           S_DETECT_V = 1,
           S_DETECT_H = 2,
           S_DETECT_RISE = 3,
           S_DETECT_FALL = 4,
           S_RE = 5;

reg op_ready_nxt;
reg re_valid_nxt;
reg re_is_finished_nxt;

reg [3:0] S, S_nxt;

reg [2:0] rlim, rlim_nxt;
reg [2:0] llim, llim_nxt;
reg [2:0] tlim, tlim_nxt;
reg [2:0] blim, blim_nxt;

reg [2:0] c, c_nxt;
reg [2:0] r, r_nxt;

reg op_fire, re_fire;

reg occupied_all;
reg whos_all;
reg [2:0] c0, c1, c2, c3, r0, r1, r2, r3;

always @(*) begin
    op_fire = op_ready & op_valid;
    re_fire = re_ready & re_valid;
    occupied_all = 0;
    whos_all = 0;
    c0 = 0; c1 = 0; c2 = 0; c3 = 0;
    r0 = 0; r1 = 0; r2 = 0; r3 = 0;

    op_ready_nxt = op_ready;
    re_valid_nxt = re_valid;
    re_is_finished_nxt = re_is_finished;

    S_nxt = S;

    rlim_nxt = rlim;
    llim_nxt = llim;
    tlim_nxt = tlim;
    blim_nxt = blim;

    c_nxt = c;
    r_nxt = r;

    case (S)
        S_IDLE: begin
            if (op_fire) begin
                op_ready_nxt = 0;

                rlim_nxt = 0;
                llim_nxt = 6;
                tlim_nxt = 0;
                blim_nxt = 2;

                c_nxt = rlim_nxt;
                r_nxt = tlim_nxt;

                S_nxt = S_DETECT_V;
            end
        end
        S_DETECT_V: begin
            c0 = c; r0 = r    ;
            c1 = c; r1 = r + 1;
            c2 = c; r2 = r + 2;
            c3 = c; r3 = r + 3;
            occupied_all = ( & {occupied[r0 * 7 + c0], occupied[r1 * 7 + c1], occupied[r2 * 7 + c2], occupied[r3 * 7 + c3]});
            whos_all     = ( & {whos    [r0 * 7 + c0], whos    [r1 * 7 + c1], whos    [r2 * 7 + c2], whos    [r3 * 7 + c3]}) |
                           (~| {whos    [r0 * 7 + c0], whos    [r1 * 7 + c1], whos    [r2 * 7 + c2], whos    [r3 * 7 + c3]});

            c_nxt = (c == llim) ? rlim : c + 1;
            r_nxt = (c == llim) ? r + 1 : r;

            if (occupied_all && whos_all) begin
                re_valid_nxt = 1;
                re_is_finished_nxt = 1;
                S_nxt = S_RE;
            end
            else begin
                if (c == llim && r == blim) begin
                    rlim_nxt = 0;
                    llim_nxt = 3;
                    tlim_nxt = 0;
                    blim_nxt = 5;

                    c_nxt = rlim_nxt;
                    r_nxt = tlim_nxt;

                    S_nxt = S_DETECT_H;
                end
            end
        end
        S_DETECT_H: begin
            c0 = c    ; r0 = r;
            c1 = c + 1; r1 = r;
            c2 = c + 2; r2 = r;
            c3 = c + 3; r3 = r;
            occupied_all = ( & {occupied[r0 * 7 + c0], occupied[r1 * 7 + c1], occupied[r2 * 7 + c2], occupied[r3 * 7 + c3]});
            whos_all     = ( & {whos    [r0 * 7 + c0], whos    [r1 * 7 + c1], whos    [r2 * 7 + c2], whos    [r3 * 7 + c3]}) |
                           (~| {whos    [r0 * 7 + c0], whos    [r1 * 7 + c1], whos    [r2 * 7 + c2], whos    [r3 * 7 + c3]});

            c_nxt = (c == llim) ? rlim : c + 1;
            r_nxt = (c == llim) ? r + 1 : r;

            if (occupied_all && whos_all) begin
                re_valid_nxt = 1;
                re_is_finished_nxt = 1;
                S_nxt = S_RE;
            end
            else begin
                if (c == llim && r == blim) begin
                    rlim_nxt = 0;
                    llim_nxt = 3;
                    tlim_nxt = 3;
                    blim_nxt = 5;

                    c_nxt = rlim_nxt;
                    r_nxt = tlim_nxt;

                    S_nxt = S_DETECT_RISE;
                end
            end
        end
        S_DETECT_RISE: begin
            c0 = c    ; r0 = r    ;
            c1 = c + 1; r1 = r - 1; 
            c2 = c + 2; r2 = r - 2;
            c3 = c + 3; r3 = r - 3; 
            occupied_all = ( & {occupied[r0 * 7 + c0], occupied[r1 * 7 + c1], occupied[r2 * 7 + c2], occupied[r3 * 7 + c3]});
            whos_all     = ( & {whos    [r0 * 7 + c0], whos    [r1 * 7 + c1], whos    [r2 * 7 + c2], whos    [r3 * 7 + c3]}) |
                           (~| {whos    [r0 * 7 + c0], whos    [r1 * 7 + c1], whos    [r2 * 7 + c2], whos    [r3 * 7 + c3]});

            c_nxt = (c == llim) ? rlim : c + 1;
            r_nxt = (c == llim) ? r + 1 : r;

            if (occupied_all && whos_all) begin
                re_valid_nxt = 1;
                re_is_finished_nxt = 1;
                S_nxt = S_RE;
            end
            else begin
                if (c == llim && r == blim) begin
                    rlim_nxt = 0;
                    llim_nxt = 3;
                    tlim_nxt = 0;
                    blim_nxt = 2;

                    c_nxt = rlim_nxt;
                    r_nxt = tlim_nxt;

                    S_nxt = S_DETECT_FALL;
                end
            end
        end
        S_DETECT_FALL: begin
            c0 = c    ; r0 = r    ;
            c1 = c + 1; r1 = r + 1;
            c2 = c + 2; r2 = r + 2;
            c3 = c + 3; r3 = r + 3;
            occupied_all = ( & {occupied[r0 * 7 + c0], occupied[r1 * 7 + c1], occupied[r2 * 7 + c2], occupied[r3 * 7 + c3]});
            whos_all     = ( & {whos    [r0 * 7 + c0], whos    [r1 * 7 + c1], whos    [r2 * 7 + c2], whos    [r3 * 7 + c3]}) |
                           (~| {whos    [r0 * 7 + c0], whos    [r1 * 7 + c1], whos    [r2 * 7 + c2], whos    [r3 * 7 + c3]});

            c_nxt = (c == llim) ? rlim : c + 1;
            r_nxt = (c == llim) ? r + 1 : r;

            if (occupied_all && whos_all) begin
                re_valid_nxt = 1;
                re_is_finished_nxt = 1;
                S_nxt = S_RE;
            end
            else begin
                if (c == llim && r == blim) begin
                    re_valid_nxt = 1;
                    re_is_finished_nxt = 0;
                    S_nxt = S_RE;
                end
            end
        end
        S_RE: begin
            if (re_fire) begin
                re_valid_nxt = 0;
                re_is_finished_nxt = 0;
                op_ready_nxt = 1;
                S_nxt = S_IDLE;
            end
        end
        default: begin
        end
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        op_ready <= 1;
        re_valid <= 0;
        re_is_finished <= 0;

        S <= S_IDLE;
        rlim <= 0;
        llim <= 0;
        tlim <= 0;
        blim <= 0;
        c    <= 0;
        r    <= 0;
    end
    else begin
        op_ready <= op_ready_nxt;
        re_valid <= re_valid_nxt;
        re_is_finished <= re_is_finished_nxt;

        S <= S_nxt;

        rlim <= rlim_nxt;
        llim <= llim_nxt;
        tlim <= tlim_nxt;
        blim <= blim_nxt;
        c <= c_nxt;
        r <= r_nxt;
    end
end

endmodule

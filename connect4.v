module connect4 (
    input clk, //系統時脈，所有邏輯皆在其上升沿觸發運行。
    input rst_n,//非同步低態重置信號，初始化模組狀態與棋盤內容

    output reg  op_ready,//是否可以接受新操作。1表示模組處於空閒可接收玩家指令狀態。
    input       op_valid,//操作輸入是否有效，為1時代表 op_player_id 和 op_col_id 為一筆有效落子。
    input       op_player_id,//本次操作的玩家編號，0 表示玩家 0，1 表示玩家 1。
    input [2:0] op_col_id,//玩家指定落子的行編號（0~6），若該列已滿將視為錯誤操作。

    input       re_ready,//外部是否準備接收回應訊號。當為1且 re_valid 為1時，表示可成功送出一筆回應。
    output reg  re_valid,//回應是否有效。1表示此次操作處理已完成，有一筆結果可以讀取。
    output reg  re_err,//是否為錯誤操作（如選擇滿列）。1表示操作無效
    output reg  re_is_finished,//若 re_is_finished 為1，且有玩家勝出，則為勝方 ID（0 或 1）；若平手則為 0。
    output reg  re_winner,//若 re_is_finished 為1，且有玩家勝出，則為勝方 ID（0 或 1）；若平手則為 0。
    output reg  re_tie//若為1表示遊戲為平手狀態，棋盤已滿且無勝方。
);

localparam S_WAIT_OP  = 0,
           S_DROP     = 1,
           S_GO_JUDGE = 2,
           S_JUDGE    = 3,
           S_RE       = 4;



reg  op_ready_nxt; 
reg  re_valid_nxt;
reg  re_err_nxt;
reg  re_is_finished_nxt;
reg  re_winner_nxt;
reg  re_tie_nxt;


reg [3:0] S, S_nxt;

reg [41:0] occupied;
reg [41:0] whos;
reg [41:0] occupied_nxt;
reg [41:0] whos_nxt;
reg player_id, player_id_nxt;
reg [2:0] col_id, col_id_nxt;
reg [2:0] row_id, row_id_nxt;

wire wj_op_ready;
reg wj_op_valid, wj_op_valid_nxt;

reg wj_re_ready, wj_re_ready_nxt;
wire wj_re_valid;
wire wj_re_is_finished;

win_judge wj (
    .clk(clk),
    .rst_n(rst_n),

    .occupied(occupied),
    .whos(whos),

    .op_ready(wj_op_ready),
    .op_valid(wj_op_valid),

    .re_ready(wj_re_ready),
    .re_valid(wj_re_valid),
    .re_is_finished(wj_re_is_finished)
);

reg op_fire, re_fire, wj_op_fire, wj_re_fire;
reg [6:0] col_full;

integer i;

always @(*) begin
    op_fire = op_ready & op_valid;
    re_fire = re_ready & re_valid;
    wj_op_fire = wj_op_ready & wj_op_valid;
    wj_re_fire = wj_re_ready & wj_re_valid;

    col_full = occupied[6:0];

    op_ready_nxt = op_ready;
    re_valid_nxt = re_valid;
    re_err_nxt = re_err;
    re_is_finished_nxt = re_is_finished;
    re_winner_nxt = re_winner;
    re_tie_nxt = re_tie;

    S_nxt = S;

    occupied_nxt = occupied;
    whos_nxt = whos;
    player_id_nxt = player_id;
    col_id_nxt = col_id;
    row_id_nxt = row_id;

    wj_op_valid_nxt = wj_op_valid;

    wj_re_ready_nxt = wj_re_ready;

    case (S)
        S_WAIT_OP: begin
            if (op_fire) begin
                op_ready_nxt = 0;

                player_id_nxt = op_player_id;
                col_id_nxt = op_col_id;
                if (col_full[op_col_id]) begin
                    re_valid_nxt = 1;
                    re_err_nxt = 1;
                    re_is_finished_nxt = 0;
                    re_winner_nxt = 0;
                    re_tie_nxt = 0;
                    S_nxt = S_RE;
                end
                else begin
                    {occupied_nxt[op_col_id], whos_nxt[op_col_id]} = {1'b1, op_player_id};
                    row_id_nxt = 0;
                    S_nxt = S_DROP;
                end
            end
        end
        S_DROP: begin
            if (row_id == 5 || occupied[(row_id+1) * 7 + col_id]) begin
                wj_op_valid_nxt = 1;
                S_nxt = S_GO_JUDGE;
            end
            else begin
                {occupied_nxt[ row_id    * 7 + col_id], whos_nxt[ row_id    * 7 + col_id]} = {1'b0, 1'b0};

                {occupied_nxt[(row_id+1) * 7 + col_id], whos_nxt[(row_id+1) * 7 + col_id]} = {1'b1, player_id};
                row_id_nxt = row_id + 1;
                S_nxt = S_DROP;
            end
        end
        S_GO_JUDGE: begin
            if (wj_op_fire) begin
                wj_re_ready_nxt = 1;

                wj_op_valid_nxt = 0;

                S_nxt = S_JUDGE;
            end
        end
        S_JUDGE: begin
            if (wj_re_fire) begin
                wj_re_ready_nxt = 0;

                re_valid_nxt = 1;
                re_err_nxt = 0;
                re_is_finished_nxt = wj_re_is_finished | (&col_full);
                re_tie_nxt = (&col_full) & ~wj_re_is_finished;
                re_winner_nxt = wj_re_is_finished ? player_id : 0;

                S_nxt = S_RE;
            end
        end
        S_RE: begin
            if (re_fire) begin
                op_ready_nxt = 1;

                re_valid_nxt = 0;
                re_err_nxt = 0;
                re_is_finished_nxt = 0;
                re_winner_nxt = 0;
                re_tie_nxt = 0;

                if (re_is_finished) begin
                    occupied_nxt = 42'b0;
                    whos_nxt = 42'b0;
                    player_id_nxt = 0;
                    col_id_nxt = 0;
                    row_id_nxt = 0;
                end

                S_nxt = S_WAIT_OP;
            end
        end
        default: begin
        end
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        S <= S_WAIT_OP;

        op_ready <= 1;
        re_valid <= 0;
        re_err <= 0;
        re_is_finished <= 0;
        re_winner <= 0;
        re_tie <= 0;

        occupied <= 42'b0;
        whos <= 42'b0;
        player_id <= 0;
        col_id <= 0;
        row_id <= 0;

        wj_op_valid <= 0;

        wj_re_ready <= 0;
    end
    else begin
        S <= S_nxt;

        op_ready <= op_ready_nxt;
        re_valid <= re_valid_nxt;
        re_err <= re_err_nxt;
        re_is_finished <= re_is_finished_nxt;
        re_winner <= re_winner_nxt;
        re_tie <= re_tie_nxt;

        occupied <= occupied_nxt;
        whos <= whos_nxt;
        player_id <= player_id_nxt;
        col_id <= col_id_nxt;
        row_id <= row_id_nxt;

        wj_op_valid <= wj_op_valid_nxt;

        wj_re_ready <= wj_re_ready_nxt;
    end
end

endmodule

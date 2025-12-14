# Connect4 Verilog 專案

四連棋 (Connect4) 遊戲的 Verilog 硬體實現。

## 檔案結構

```
connect4_project/
├── connect4.v      # 主控制模組 - 處理遊戲流程與落子邏輯
├── win_judge.v     # 勝負判斷模組 - 檢測垂直/水平/斜向連線
├── connect4_tb.v   # 測試平台
├── filelist.f      # 編譯用檔案清單
└── README.md       # 本說明檔
```

## 模組說明

### connect4 (主模組)
- 管理遊戲狀態機 (等待操作 → 落子 → 判斷 → 回應)
- 處理棋子下落動畫邏輯
- 檢測列滿錯誤
- 調用 win_judge 進行勝負判斷

### win_judge (勝負判斷模組)
- 檢測四種連線方向：
  - 垂直 (S_DETECT_V)
  - 水平 (S_DETECT_H)
  - 右上斜向 (S_DETECT_RISE)
  - 右下斜向 (S_DETECT_FALL)

## 編譯方式

使用 Icarus Verilog:
```bash
# 方法一：直接指定檔案
iverilog -o connect4_tb win_judge.v connect4.v connect4_tb.v

# 方法二：使用 filelist
iverilog -f filelist.f connect4_tb.v -o connect4_tb

# 執行模擬
vvp connect4_tb
```

使用其他工具 (如 Vivado, Quartus):
- 將 `connect4.v` 和 `win_judge.v` 加入專案
- `connect4` 為頂層模組

## 介面說明

### 輸入
| 信號 | 寬度 | 說明 |
|------|------|------|
| clk | 1 | 系統時脈 |
| rst_n | 1 | 非同步低態重置 |
| op_valid | 1 | 操作有效信號 |
| op_player_id | 1 | 玩家編號 (0/1) |
| op_col_id | 3 | 落子行號 (0~6) |
| re_ready | 1 | 外部準備接收回應 |

### 輸出
| 信號 | 寬度 | 說明 |
|------|------|------|
| op_ready | 1 | 可接受新操作 |
| re_valid | 1 | 回應有效 |
| re_err | 1 | 錯誤操作 (列已滿) |
| re_is_finished | 1 | 遊戲結束 |
| re_winner | 1 | 勝方 ID |
| re_tie | 1 | 平手 |

## 棋盤配置

6x7 棋盤，使用 42-bit 暫存器儲存：
- `occupied[41:0]`: 該格是否有棋子
- `whos[41:0]`: 棋子所屬玩家

索引計算: `index = row * 7 + col`
<img width="1138" height="1048" alt="螢幕擷取畫面 2025-12-14 154622" src="https://github.com/user-attachments/assets/88c8af24-a672-4367-9e30-013ab2b25ce0" />





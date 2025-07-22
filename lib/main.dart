import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MineSweeperApp());

//  这是一个完整的 Flutter 扫雷游戏实现，包括以下内容：
// 	•	生成 10x10 的雷区；
// 	•	随机布置 15 个地雷；
// 	•	点击展开，空白区域递归展开；
// 	•	长按插旗；
// 	•	游戏成功、失败弹窗提醒；
// 	•	支持通过坐标编号开启。
class MineSweeperApp extends StatelessWidget {
  const MineSweeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MineSweeperPage(),
    );
  }
}

class Cell {
  bool hasMine = false;
  bool revealed = false;
  bool flagged = false;
  int nearbyMines = 0;
  String rc = "";

  Cell(this.rc);
}

class MineSweeperPage extends StatefulWidget {
  const MineSweeperPage({super.key});

  @override
  State<MineSweeperPage> createState() => _MineSweeperPageState();
}

class _MineSweeperPageState extends State<MineSweeperPage> {
  static const int rows = 10;
  static const int cols = 10;
  static const int mineCount = 15;
  static const int cells = rows * cols;
  int revealedCells = cells - mineCount;
  late List<List<Cell>> board;
  bool gameOver = false;
  int revealedCount = 0;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 初始化网格数据
  void _initializeBoard() {
    board = List.generate(
        rows,
        (int rIndex) =>
            List.generate(cols, (int cIndex) => Cell("$rIndex$cIndex")));
    _placeMines();
    _calculateNumbers();
  }

  // 随机出地雷
  void _placeMines() {
    final rng = Random();
    int placed = 0;
    while (placed < mineCount) {
      int r = rng.nextInt(rows);
      int c = rng.nextInt(cols);
      if (!board[r][c].hasMine) {
        board[r][c].hasMine = true;
        placed++;
      }
    }
  }

  // 计算出附近9宫格内的地雷数
  void _calculateNumbers() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c].hasMine) continue;
        int count = 0;
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            int nr = r + dr;
            int nc = c + dc;
            if (nr >= 0 &&
                nr < rows &&
                nc >= 0 &&
                nc < cols &&
                board[nr][nc].hasMine) {
              count++;
            }
          }
        }
        board[r][c].nearbyMines = count;
      }
    }
  }

  // 扩散展开算法（递归）
  void _reveal(int r, int c) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return;
    Cell cell = board[r][c];
    if (cell.revealed || cell.flagged) return;

    setState(() {
      cell.revealed = true;
      revealedCount++;

      if (revealedCount >= revealedCells) {
        gameOver = true;
        _showGameOver(true);
        return;
      }
      if (cell.hasMine) {
        gameOver = true;
        _showGameOver(false);
        return;
      }

      if (cell.nearbyMines == 0) {
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            if (dr != 0 || dc != 0) _reveal(r + dr, c + dc);
          }
        }
      }
    });
  }

  // 插旗
  void _toggleFlag(int r, int c) {
    setState(() {
      if (!board[r][c].revealed) {
        board[r][c].flagged = !board[r][c].flagged;
      }
    });
  }

  // 游戏结束
  void _showGameOver(bool isWin) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isWin ? "Congratulations!You Win!" : "Game Over"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                gameOver = false;
                _initializeBoard();
              });
            },
            child: const Text("Restart"),
          ),
        ],
      ),
    );
  }

  // 回车键
  void _inputNumber(String text) {
    _openCell();
  }

  // 手动揭开一个
  void _openCell() {
    var text = _controller.text;
    if (!gameOver && text.isNotEmpty) {
      int index = int.parse(text) - 1;
      int r = index ~/ cols;
      int c = index % cols;
      _reveal(r, c);
    }
  }

  // 构建一个
  Widget _buildCell(int r, int c) {
    final cell = board[r][c];
    return Stack(
      children: [
        GestureDetector(
          onTap: gameOver ? null : () => _reveal(r, c),
          onLongPress: gameOver ? null : () => _toggleFlag(r, c),
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: cell.revealed ? Colors.grey[300] : Colors.blue[600],
              border: Border.all(color: Colors.black),
            ),
            child: Center(
              child: cell.revealed
                  ? cell.hasMine
                      ? const Icon(Icons.bug_report, color: Colors.red)
                      : Text(
                          cell.nearbyMines > 0 ? '${cell.nearbyMines}' : '',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        )
                  : cell.flagged
                      ? const Icon(Icons.flag, color: Colors.orange)
                      : null,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 2, top: 2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
          ),
          child: Text(
            (int.parse(cell.rc) + 1).toString().padLeft(2, '0'),
            style: const TextStyle(
                fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double paddingWidth = 20;
    if (kIsWeb) {
      paddingWidth = MediaQuery.of(context).size.width / 4;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter MineSweeper"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                gameOver = false;
                revealedCount = 0;
                _initializeBoard();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(
            left: paddingWidth, top: 0, right: paddingWidth, bottom: 20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 40,
                    child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(3), // 限制长度
                          FilteringTextInputFormatter.digitsOnly, // 只允许数字
                          MaxValueInputFormatter(cells) // 最大值限制
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Please enter a number...',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.green, width: 2.0), // 默认未选中状态的线
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey, width: 2.0), // 选中状态线
                          ),
                        ),
                        onSubmitted: _inputNumber),
                  ),
                  TextButton(
                      onPressed: _openCell,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4)),
                        ),
                        child: const Text(
                          "open",
                          style: TextStyle(color: Colors.white),
                        ),
                      ))
                ],
              ),
            ),
            Expanded(
                child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: 1, // 宽高比 = 1，正方形
              ),
              itemCount: rows * cols,
              itemBuilder: (context, index) {
                int r = index ~/ cols;
                int c = index % cols;
                return _buildCell(r, c);
              },
            ))
          ],
        ),
      ),
    );
  }
}

// 最大数字限制
class MaxValueInputFormatter extends TextInputFormatter {
  final int max;

  MaxValueInputFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // 允许空字符串（可用于清空输入）
    if (text.isEmpty) return newValue;

    // 尝试转换为 int
    final value = int.tryParse(text);
    if (value == null) return oldValue;

    // 超过最大值，拦截
    if (value > max) return oldValue;

    return newValue;
  }
}

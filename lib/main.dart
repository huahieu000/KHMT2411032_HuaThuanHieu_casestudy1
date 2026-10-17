import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý thu chi',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // # MỚI: Hàm hỗ trợ định dạng số tiền (VD: 10000.0 -> "10.000")
  String _formatCurrency(double amount) {
    final int value = amount.round();
    final String str = value.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  // # MỚI: Hàm hiển thị Modal hỗ trợ cả THÊM VÀ SỬA giao dịch
  void _showTransactionModal({Map<String, dynamic>? transaction}) {
    // # MỚI: Kiểm tra xem đang ở chế độ Sửa (truyền transaction) hay Thêm mới
    final isEditing = transaction != null;
    final titleController = TextEditingController(
      text: isEditing ? transaction['title'] : '',
    );
    final amountController = TextEditingController(
      text: isEditing ? (transaction['amount'] as double).toStringAsFixed(0) : '',
    );
    String type = isEditing ? transaction['type'] : 'expense';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // # MỚI: Dùng StatefulBuilder để cập nhật giao diện nút bấm trong modal
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // # MỚI: Đổi tiêu đề modal tùy thuộc Thêm hay Sửa
                    isEditing ? 'Sửa giao dịch' : 'Thêm giao dịch mới',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // # MỚI: Thanh chọn Loại giao dịch (Chi tiêu / Thu nhập)
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Chi tiêu')),
                          selected: type == 'expense',
                          selectedColor: Colors.red.shade100,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => type = 'expense');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Thu nhập')),
                          selected: type == 'income',
                          selectedColor: Colors.green.shade100,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => type = 'income');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tên giao dịch (VD: Ăn sáng)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền (VNĐ)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final amount = double.tryParse(amountController.text) ?? 0.0;

                        if (title.isNotEmpty && amount > 0) {
                          if (isEditing) {
                            // # MỚI: Gọi hàm Cập nhật (Sửa) trong SQLite
                            await DatabaseHelper.instance.updateTransaction({
                              'id': transaction['id'],
                              'title': title,
                              'amount': amount,
                              'date': transaction['date'],
                              'type': type,
                              'category_id': transaction['category_id'] ?? 1,
                            });
                          } else {
                            // # MỚI: Gọi hàm Thêm mới trong SQLite
                            await DatabaseHelper.instance.insertTransaction({
                              'title': title,
                              'amount': amount,
                              'date': '17/10/2026',
                              'type': type,
                              'category_id': 1,
                            });
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            setState(() {});
                          }
                        }
                      },
                      child: Text(isEditing ? 'Cập nhật' : 'Lưu giao dịch'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // # MỚI: Hàm hiển thị hộp thoại xác nhận Xóa giao dịch
  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa giao dịch này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              // # MỚI: Thực hiện xóa giao dịch trong SQLite
              await DatabaseHelper.instance.deleteTransaction(id);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        title: const Text(
          'Quản lý thu chi',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87, size: 28),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final listTx = snapshot.data ?? [];

          // # MỚI: Lặp qua danh sách từ SQLite để tính ĐỘNG: Tổng thu, Tổng chi và Số dư
          double totalIncome = 0;
          double totalExpense = 0;

          for (var tx in listTx) {
            final double amt = (tx['amount'] as num).toDouble();
            if (tx['type'] == 'income') {
              totalIncome += amt;
            } else {
              totalExpense += amt;
            }
          }

          final double balance = totalIncome - totalExpense;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thẻ Số dư hiện tại
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'SỐ DƯ HIỆN TẠI',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 16),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // # MỚI: Hiển thị Số dư tự động tính toán kèm định dạng tiền
                          Text(
                            '${_formatCurrency(balance)} đ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 14,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white54,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Positioned(
                        right: 0,
                        top: 0,
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Colors.amber,
                          size: 45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Thẻ Tổng thu / Tổng chi
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'TỔNG THU NHẬP',
                        // # MỚI: Hiển thị Tổng thu nhập động
                        amount: '${_formatCurrency(totalIncome)} đ',
                        amountColor: Colors.green.shade600,
                        icon: Icons.arrow_downward,
                        iconBgColor: Colors.green.shade100,
                        iconColor: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'TỔNG CHI TIÊU',
                        // # MỚI: Hiển thị Tổng chi tiêu động
                        amount: '${_formatCurrency(totalExpense)} đ',
                        amountColor: Colors.red.shade600,
                        icon: Icons.arrow_upward,
                        iconBgColor: Colors.red.shade100,
                        iconColor: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tiêu đề phần giao dịch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Giao dịch gần đây (Từ SQLite)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Xem tất cả',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Danh sách Giao dịch
                if (listTx.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'Chưa có giao dịch nào.\nBấm nút + bên dưới để thêm mới!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listTx.length,
                    itemBuilder: (context, index) {
                      final tx = listTx[index];
                      final bool isExpense = tx['type'] == 'expense';
                      final double amt = (tx['amount'] as num).toDouble();

                      // # MỚI: Bọc InkWell để bắt sự kiện Bấm (Sửa) và Nhấn giữ (Xóa)
                      return InkWell(
                        onTap: () => _showTransactionModal(transaction: tx), // # MỚI: Bấm để SỬA
                        onLongPress: () => _confirmDelete(tx['id']),          // # MỚI: Giữ lâu để XÓA
                        child: _buildTransactionItem(
                          title: tx['title'],
                          category: isExpense ? 'Chi tiêu' : 'Thu nhập',
                          date: tx['date'],
                          // # MỚI: Định dạng lại chuỗi hiển thị số tiền
                          amount: '${isExpense ? "-" : "+"}${_formatCurrency(amt)} đ',
                          isExpense: isExpense,
                          icon: isExpense ? Icons.shopping_bag : Icons.savings,
                          iconBgColor: isExpense ? const Color(0xFFFFECE5) : const Color(0xFFDCFCE7),
                          iconColor: isExpense ? const Color(0xFFFF6B00) : const Color(0xFF16A34A),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        // # MỚI: Mở modal ở chế độ Thêm mới khi bấm nút +
        onPressed: () => _showTransactionModal(),
        backgroundColor: const Color(0xFF2563EB),
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey.shade500,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subtitles_outlined),
            label: 'Giao dịch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            label: 'Thống kê',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required Color amountColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String category,
    required String date,
    required String amount,
    required bool isExpense,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isExpense ? Colors.red.shade600 : Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
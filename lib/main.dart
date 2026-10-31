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
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedStatFilter = 'month';
  String _selectedCategoryFilter = 'Tất cả danh mục';
  String _selectedTimeRange = 'Tháng này';

  String _formatCurrency(double amount) {
    final int value = amount.round();
    final String str = value.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

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
    final List<Widget> pages = [
      _buildHomeTab(),
      _buildTransactionTab(),
      _buildStatisticsTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        title: Text(
          _selectedIndex == 0
              ? 'Quản lý thu chi'
              : (_selectedIndex == 1
                    ? 'Giao dịch'
                    : (_selectedIndex == 2 ? 'Thống kê' : 'Cá nhân')),
          style: const TextStyle(
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
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black87,
                  size: 28,
                ),
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
      body: pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
          if (result == true) {
            setState(() {});
          }
        },
        backgroundColor: const Color(0xFF2563EB),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey.shade500,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final listTx = snapshot.data ?? [];
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
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
                            Icon(
                              Icons.remove_red_eye_outlined,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'TỔNG THU NHẬP',
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
                    onPressed: () => setState(() => _selectedIndex = 1),
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
                  itemCount: listTx.length > 5 ? 5 : listTx.length,
                  itemBuilder: (context, index) {
                    final tx = listTx[index];
                    final bool isExpense = tx['type'] == 'expense';
                    final double amt = (tx['amount'] as num).toDouble();

                    return InkWell(
                      onTap: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddTransactionScreen(transaction: tx),
                          ),
                        );
                        if (res == true) setState(() {});
                      },
                      onLongPress: () => _confirmDelete(tx['id']),
                      child: _buildTransactionItem(
                        title: tx['title'],
                        category: isExpense ? 'Chi tiêu' : 'Thu nhập',
                        date: tx['date'],
                        amount:
                            '${isExpense ? "-" : "+"}${_formatCurrency(amt)} đ',
                        isExpense: isExpense,
                        icon: isExpense
                            ? Icons.restaurant
                            : Icons.account_balance_wallet,
                        iconBgColor: isExpense
                            ? const Color(0xFFFFECE5)
                            : const Color(0xFFDCFCE7),
                        iconColor: isExpense
                            ? const Color(0xFFFF6B00)
                            : const Color(0xFF16A34A),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var listTx = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          listTx = listTx
              .where(
                (tx) => tx['title'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
        }

        if (_selectedFilter != 'all') {
          listTx = listTx.where((tx) => tx['type'] == _selectedFilter).toList();
        }

        if (_selectedCategoryFilter != 'Tất cả danh mục') {
          listTx = listTx
              .where((tx) => tx['title'] == _selectedCategoryFilter)
              .toList();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm giao dịch...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune, color: Color(0xFF2563EB)),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FilterScreen(
                              initialType: _selectedFilter,
                              initialCategory: _selectedCategoryFilter,
                              initialTimeRange: _selectedTimeRange,
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _selectedFilter = result['type'];
                            _selectedCategoryFilter = result['category'];
                            _selectedTimeRange = result['timeRange'];
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterTab('Tất cả', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Thu nhập', 'income'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Chi tiêu', 'expense'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${listTx.length} giao dịch',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: listTx.isEmpty
                    ? const Center(
                        child: Text(
                          'Không tìm thấy giao dịch nào.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: listTx.length,
                        itemBuilder: (context, index) {
                          final tx = listTx[index];
                          final bool isExpense = tx['type'] == 'expense';
                          final double amt = (tx['amount'] as num).toDouble();

                          return InkWell(
                            onTap: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddTransactionScreen(transaction: tx),
                                ),
                              );
                              if (res == true) setState(() {});
                            },
                            onLongPress: () => _confirmDelete(tx['id']),
                            child: _buildTransactionTabItem(
                              title: tx['title'],
                              category: isExpense ? 'Ăn uống' : 'Thu nhập',
                              date: tx['date'],
                              amount:
                                  '${isExpense ? "-" : "+"}${_formatCurrency(amt)} đ',
                              isExpense: isExpense,
                              icon: isExpense
                                  ? Icons.restaurant
                                  : Icons.account_balance_wallet,
                              iconBgColor: isExpense
                                  ? const Color(0xFFFFECE5)
                                  : const Color(0xFFDCFCE7),
                              iconColor: isExpense
                                  ? const Color(0xFFFF5252)
                                  : const Color(0xFF16A34A),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final listTx = snapshot.data ?? [];
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatFilterButton('Tháng này', 'month'),
                  const SizedBox(width: 8),
                  _buildStatFilterButton('Tháng trước', 'last_month'),
                  const SizedBox(width: 8),
                  _buildStatFilterButton('Năm nay', 'year'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Phân bổ chi tiêu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      width: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 16,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red.shade100,
                            ),
                          ),
                          CircularProgressIndicator(
                            value: totalExpense > 0 ? 1.0 : 0.0,
                            strokeWidth: 16,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF5252),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Tổng chi tiêu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatCurrency(totalExpense)} đ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatCategoryItem(
                      'Ăn uống',
                      '2.000.000 đ',
                      '40%',
                      const Color(0xFFFF5252),
                    ),
                    const SizedBox(height: 12),
                    _buildStatCategoryItem(
                      'Mua sắm',
                      '1.500.000 đ',
                      '30%',
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildStatCategoryItem(
                      'Đi lại',
                      '700.000 đ',
                      '14%',
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildStatCategoryItem(
                      'Học tập',
                      '500.000 đ',
                      '10%',
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildStatCategoryItem(
                      'Khác',
                      '200.000 đ',
                      '6%',
                      Colors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(
                    Icons.person,
                    size: 36,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Nguyễn Văn A',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'nguyenvana@example.com',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                _buildProfileMenuItem(
                  Icons.person_outline,
                  'Thông tin cá nhân',
                  Colors.black87,
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildProfileMenuItem(
                  Icons.settings_outlined,
                  'Cài đặt ngân sách',
                  Colors.black87,
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildProfileMenuItem(
                  Icons.list_alt_rounded,
                  'Danh mục chi tiêu',
                  Colors.black87,
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildProfileMenuItem(
                  Icons.cloud_upload_outlined,
                  'Sao lưu dữ liệu',
                  Colors.black87,
                ),
                Divider(height: 1, color: Colors.grey.shade100),
                Divider(height: 1, color: Colors.grey.shade100),
                _buildProfileMenuItem(
                  Icons.logout,
                  'Đăng xuất',
                  Colors.redAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String title, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: color,
        ),
      ),
      trailing: color == Colors.redAccent
          ? null
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }

  Widget _buildStatCategoryItem(
    String title,
    String amount,
    String percent,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              child: Text(
                percent,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final bool isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade200,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatFilterButton(String label, String value) {
    final bool isSelected = _selectedStatFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade200,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
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

  Widget _buildTransactionTabItem({
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
              borderRadius: BorderRadius.circular(12),
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
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$category • $date',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isExpense
                      ? const Color(0xFFFF5252)
                      : const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.more_horiz, color: Colors.grey, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class FilterScreen extends StatefulWidget {
  final String initialType;
  final String initialCategory;
  final String initialTimeRange;

  const FilterScreen({
    super.key,
    required this.initialType,
    required this.initialCategory,
    required this.initialTimeRange,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late String _selectedType;
  late String _selectedCategory;
  late String _selectedTimeRange;

  final List<String> _categories = [
    'Tất cả danh mục',
    'Ăn uống',
    'Mua sắm',
    'Lương',
    'Đi lại',
    'Học tập',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedCategory = widget.initialCategory;
    _selectedTimeRange = widget.initialTimeRange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bộ lọc',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loại giao dịch',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildCheckboxOption('Tất cả', 'all'),
            _buildCheckboxOption('Thu nhập', 'income'),
            _buildCheckboxOption('Chi tiêu', 'expense'),
            const SizedBox(height: 24),
            const Text(
              'Danh mục',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _categories.map((String cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Khoảng thời gian',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildRadioOption('Hôm nay'),
            _buildRadioOption('7 ngày qua'),
            _buildRadioOption('Tháng này'),
            _buildRadioOption('Tùy chỉnh'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'type': _selectedType,
                    'category': _selectedCategory,
                    'timeRange': _selectedTimeRange,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Áp dụng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxOption(String label, String value) {
    final bool isChecked = _selectedType == value;
    return InkWell(
      onTap: () => setState(() => _selectedType = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isChecked,
                activeColor: const Color(0xFF3B4874),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (val) {
                  if (val == true) setState(() => _selectedType = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label) {
    final bool isSelected = _selectedTimeRange == label;
    return InkWell(
      onTap: () => setState(() => _selectedTimeRange = label),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Radio<String>(
              value: label,
              groupValue: _selectedTimeRange,
              activeColor: const Color(0xFF2563EB),
              onChanged: (val) {
                if (val != null) setState(() => _selectedTimeRange = val);
              },
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late String type;
  late TextEditingController amountController;
  late TextEditingController dateController;
  late TextEditingController noteController;
  String selectedCategory = 'Ăn uống';

  final List<String> expenseCategories = [
    'Ăn uống',
    'Mua sắm',
    'Đi lại',
    'Học tập',
    'Giải trí',
    'Sức khỏe',
    'Khác',
  ];

  final List<String> incomeCategories = [
    'Lương',
    'Thưởng',
    'Kinh doanh',
    'Đầu tư',
    'Khác',
  ];
  void _showCategoryPicker() {
    final categories = type == 'expense' ? expenseCategories : incomeCategories;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Chọn danh mục',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...categories.map((category) {
                return ListTile(
                  title: Text(category),
                  trailing: selectedCategory == category
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                    Navigator.pop(sheetContext);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final isEditing = widget.transaction != null;
    type = isEditing ? widget.transaction!['type'] : 'expense';
    selectedCategory = isEditing
        ? widget.transaction!['title'].toString()
        : (type == 'expense' ? 'Ăn uống' : 'Lương');
    amountController = TextEditingController(
      text: isEditing
          ? (widget.transaction!['amount'] as double).toStringAsFixed(0)
          : '',
    );
    dateController = TextEditingController(
      text: isEditing ? widget.transaction!['date'] : '10/10/2026',
    );
    noteController = TextEditingController(text: '');
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Sửa giao dịch' : 'Thêm giao dịch',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => type = 'expense'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: type == 'expense'
                            ? const Color(0xFFFF5252)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: type == 'expense'
                              ? Colors.transparent
                              : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Chi tiêu',
                        style: TextStyle(
                          color: type == 'expense'
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => type = 'income'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: type == 'income'
                            ? const Color(0xFF2563EB)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: type == 'income'
                              ? Colors.transparent
                              : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Thu nhập',
                        style: TextStyle(
                          color: type == 'income'
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Danh mục',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showCategoryPicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag,
                      color: Color(0xFFFF6B00),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedCategory,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Số tiền',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nhập số tiền',
                suffixText: 'đ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ngày giao dịch',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                suffixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ghi chú',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú (tùy chọn)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  if (amount > 0) {
                    if (isEditing) {
                      await DatabaseHelper.instance.updateTransaction({
                        'id': widget.transaction!['id'],
                        'title': selectedCategory,
                        'amount': amount,
                        'date': dateController.text,
                        'type': type,
                        'category_id': 1,
                      });
                    } else {
                      await DatabaseHelper.instance.insertTransaction({
                        'title': selectedCategory,
                        'amount': amount,
                        'date': dateController.text,
                        'type': type,
                        'category_id': 1,
                      });
                    }
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                },
                child: const Text(
                  'Lưu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

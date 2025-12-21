import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../l10n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BookProvider>().loadStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.statistics_title),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.book), text: loc.statistics_tab_reading),
            Tab(
                icon: const Icon(Icons.attach_money),
                text: loc.statistics_tab_finance),
          ],
        ),
      ),
      body: Consumer<BookProvider>(
        builder: (context, provider, child) {
          final stats = provider.statistics;
          final totalBooks = (stats['totalBooks'] ?? 0) as int;
          final readBooks = (stats['readBooks'] ?? 0) as int;
          final readingBooks = (stats['readingBooks'] ?? 0) as int;
          final unreadBooks = (stats['unreadBooks'] ?? 0) as int;
          final totalSpent = (stats['totalSpent'] ?? 0.0) as double;
          final totalEarned = (stats['totalEarned'] ?? 0.0) as double;
          final totalProfit = totalEarned - totalSpent;

          return TabBarView(
            controller: _tabController,
            children: [
              // 閱讀統計 Tab
              _buildReadingTab(
                  context, totalBooks, readBooks, readingBooks, unreadBooks),
              // 金額統計 Tab
              _buildFinanceTab(context, totalSpent, totalEarned, totalProfit),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReadingTab(
    BuildContext context,
    int totalBooks,
    int readBooks,
    int readingBooks,
    int unreadBooks,
  ) {
    final loc = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 閱讀概覽卡片
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    loc.stat_overview_title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                        title: loc.stat_total_books,
                        value: totalBooks.toString(),
                        icon: Icons.library_books,
                        color: Colors.blue,
                      ),
                      _StatCard(
                        title: loc.stat_read,
                        value: readBooks.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      _StatCard(
                        title: loc.stat_reading,
                        value: readingBooks.toString(),
                        icon: Icons.menu_book,
                        color: Colors.orange,
                      ),
                      _StatCard(
                        title: loc.stat_unread,
                        value: unreadBooks.toString(),
                        icon: Icons.circle_outlined,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 閱讀進度條
          if (totalBooks > 0)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.stat_completion_title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${((readBooks / (totalBooks == 0 ? 1 : totalBooks)) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 12,
                        child: Row(
                          children: [
                            Expanded(
                              flex: readBooks,
                              child: Container(color: Colors.green),
                            ),
                            Expanded(
                              flex: readingBooks,
                              child: Container(color: Colors.orange),
                            ),
                            Expanded(
                              flex: unreadBooks,
                              child: Container(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${loc.stat_read}: $readBooks',
                          style: const TextStyle(color: Colors.green),
                        ),
                        Text(loc.stats_reading_label(readingBooks),
                          style: const TextStyle(color: Colors.orange)),
                        Text(loc.stats_unread_label(unreadBooks),
                          style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinanceTab(
    BuildContext context,
    double totalSpent,
    double totalEarned,
    double totalProfit,
  ) {
    final loc = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 金額統計卡片
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.finance_title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  _StatRow(
                    label: loc.finance_total_spent,
                    amount: totalSpent,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    label: loc.finance_total_earned,
                    amount: totalEarned,
                    color: Colors.green,
                  ),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: totalProfit >= 0
                          ? Colors.green.withAlpha((0.1 * 255).round())
                          : Colors.red.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.finance_total_profit,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '\$${totalProfit.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: totalProfit >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _StatRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

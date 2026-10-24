import 'package:flutter/material.dart';
import 'features/safe_route/views/safe_route_page.dart';
import 'features/evidence_vault/views/evidence_vault_page.dart';
void main() {
  runApp(const ShieldApp());
}

class ShieldApp extends StatelessWidget {
  const ShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SHIELD',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F2FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C3FC5),
          primary: const Color(0xFF6C3FC5),
          secondary: const Color(0xFF14B8A6),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F2FF),
          foregroundColor: Color(0xFF2A1B4D),
          elevation: 0,
        ),
      ),
      home: const ShieldHomePage(),
    );
  }
}

class ShieldHomePage extends StatelessWidget {
  const ShieldHomePage({super.key});

  static const violet = Color(0xFF6C3FC5);
  static const coral = Color(0xFFFF4D6A);
  static const teal = Color(0xFF14B8A6);
  static const ink = Color(0xFF2A1B4D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SHIELD', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Your safety, your control',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Hi, welcome back 👋',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your personal safety companion',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [violet, Color(0xFF3B1F7A)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Need help?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 142,
                    height: 142,
                    child: ElevatedButton(
                      onPressed: () => _showSosDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: coral,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 0,
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sos_rounded, size: 48),
                          Text(
                            'SOS',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text('Emergency', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Demo interface · No real emergency alert is sent',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your safety tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: 
_toolCard(
  context,
  Icons.route_rounded,
  'SafeRoute',
  'Compare routes',
  teal,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SafeRoutePage(),
      ),
    );
  },
),

                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _toolCard(
                    context,
                    Icons.lock_rounded,
                    'Evidence vault',
                    'Secure incidents',
                    violet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _toolCard(
                    context,
                    Icons.people_alt_rounded,
                    'Trusted circle',
                    'Your contacts',
                    teal,
                  ),
                ),
                const SizedBox(width: 12),
                
Expanded(
  child: _toolCard(
    context,
    Icons.lock_rounded,
    'Evidence vault',
    'Secure incidents',
    violet,
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EvidenceVaultPage(),
        ),
      );
    },
  ),
),

              ],
            ),
            const SizedBox(height: 18),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE6DEF7)),
              ),
              child: const ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0x1414B8A6),
                  child: Icon(Icons.timer_outlined, color: teal),
                ),
                title: Text('Safety check-in'),
                subtitle: Text('Set a timer for your journey'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            label: 'Route',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_outline_rounded),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            label: 'Circle',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            label: 'Shield',
          ),
        ],
      ),
    );
  }


Widget _toolCard(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
  Color color, {
  VoidCallback? onTap,
}) {
  return Card(
    color: Colors.white,
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE6DEF7)),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  void _showSosDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'This is a prototype. No contacts or emergency services will '
          'be notified yet. Real SOS requires location permissions and '
          'a configured backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
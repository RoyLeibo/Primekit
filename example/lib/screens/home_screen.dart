import 'package:flutter/material.dart';
import 'package:primekit/primekit.dart';

/// Home screen showcasing all Primekit modules interactively.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<_DemoSection> _sections = const [
    _DemoSection('📋 Forms', 'Zod-like schema validation', FormsDemo()),
    _DemoSection('🎨 UI', 'Toasts, overlays, skeletons', UiDemo()),
    _DemoSection('🌐 Network', 'ApiResponse<T>, offline queue', NetworkDemo()),
    _DemoSection('💾 Storage', 'Secure prefs, TTL cache', StorageDemo()),
    _DemoSection('👑 Membership', 'TierGate, UpgradePrompt', MembershipDemo()),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('🚀 Primekit Demo'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final section = _sections[i];
            return Card(
              child: ListTile(
                title: Text(
                  section.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(section.subtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => _DemoPage(
                      title: section.title,
                      child: section.demo,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _DemoSection {
  const _DemoSection(this.title, this.subtitle, this.demo);
  final String title;
  final String subtitle;
  final Widget demo;
}

class _DemoPage extends StatelessWidget {
  const _DemoPage({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: child,
      );
}

// ────────────────────────────────────────────────────────────────────────────
// Forms Demo
// ────────────────────────────────────────────────────────────────────────────

class FormsDemo extends StatefulWidget {
  const FormsDemo({super.key});

  @override
  State<FormsDemo> createState() => _FormsDemoState();
}

class _FormsDemoState extends State<FormsDemo> {
  final _schema = PkSchema.object({
    'email': PkSchema.string().email().required(),
    'password': PkSchema.string().minLength(8).required(),
    'age': PkSchema.number().min(0).max(150).integer().required(),
  });

  Map<String, dynamic> _values = {};
  Map<String, String> _errors = {};

  void _validate() {
    final result = _schema.validate(_values);
    setState(() => _errors = result.errors);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PkSchema validation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _errors['email'],
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => _values = {..._values, 'email': v},
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Password (min 8 chars)',
                errorText: _errors['password'],
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (v) => _values = {..._values, 'password': v},
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Age (0-150)',
                errorText: _errors['age'],
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  _values = {..._values, 'age': int.tryParse(v) ?? v},
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validate,
                child: const Text('Validate Schema'),
              ),
            ),
            if (_errors.isEmpty && _values.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('All fields valid!',
                        style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}

// ────────────────────────────────────────────────────────────────────────────
// UI Demo
// ────────────────────────────────────────────────────────────────────────────

class UiDemo extends StatelessWidget {
  const UiDemo({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              label: const Text('Success Toast'),
              onPressed: () =>
                  ToastService.success(context, 'Operation successful!'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.error, color: Colors.red),
              label: const Text('Error Toast'),
              onPressed: () =>
                  ToastService.error(context, 'Something went wrong!'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.warning, color: Colors.orange),
              label: const Text('Warning Toast'),
              onPressed: () => ToastService.warning(context, 'Low disk space!'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.info, color: Colors.blue),
              label: const Text('Loading Overlay (2s)'),
              onPressed: () async {
                LoadingOverlay.show(context, message: 'Processing...');
                await Future<void>.delayed(const Duration(seconds: 2));
                if (context.mounted) LoadingOverlay.hide(context);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Confirm Dialog'),
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Delete Item?',
                  message: 'This action cannot be undone.',
                  isDestructive: true,
                );
                if (context.mounted) {
                  ToastService.info(
                    context,
                    confirmed ? 'Confirmed!' : 'Cancelled.',
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Skeleton Loader:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SkeletonLoader.listItem(hasAvatar: true, textLines: 2),
            const SizedBox(height: 8),
            SkeletonLoader.listItem(hasAvatar: true, textLines: 2),
          ],
        ),
      );
}

// ────────────────────────────────────────────────────────────────────────────
// Network Demo
// ────────────────────────────────────────────────────────────────────────────

class NetworkDemo extends StatefulWidget {
  const NetworkDemo({super.key});

  @override
  State<NetworkDemo> createState() => _NetworkDemoState();
}

class _NetworkDemoState extends State<NetworkDemo> {
  ApiResponse<Map<String, dynamic>> _state =
      const ApiResponse.loading();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    ConnectivityMonitor.instance.isConnected.listen(
      (connected) => setState(() => _isConnected = connected),
    );
  }

  Future<void> _fetchData() async {
    setState(() => _state = const ApiResponse.loading());
    await Future<void>.delayed(const Duration(milliseconds: 800));
    setState(() => _state = const ApiResponse.success({'id': 1, 'name': 'John Doe', 'email': 'john@example.com'}));
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(_isConnected ? 'Online' : 'Offline'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Fetch Data (ApiResponse<T>)'),
            ),
            const SizedBox(height: 16),
            _state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              success: (data) => Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✅ ApiResponse.success',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('id: ${data['id']}'),
                      Text('name: ${data['name']}'),
                      Text('email: ${data['email']}'),
                    ],
                  ),
                ),
              ),
              failure: (error) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('❌ ${error.userMessage}'),
                ),
              ),
            ),
          ],
        ),
      );
}

// ────────────────────────────────────────────────────────────────────────────
// Storage Demo
// ────────────────────────────────────────────────────────────────────────────

class StorageDemo extends StatefulWidget {
  const StorageDemo({super.key});

  @override
  State<StorageDemo> createState() => _StorageDemoState();
}

class _StorageDemoState extends State<StorageDemo> {
  String? _cachedValue;
  String? _secureValue;

  Future<void> _saveToCache() async {
    await JsonCache.instance.set(
      'demo_key',
      {'message': 'Hello from Primekit cache!', 'timestamp': DateTime.now().toIso8601String()},
      ttl: const Duration(minutes: 5),
    );
    final data = await JsonCache.instance.get('demo_key');
    setState(() => _cachedValue = data?['message']?.toString());
  }

  Future<void> _saveSecure() async {
    await SecurePrefs.instance.setString('demo_secret', 'my-secret-value');
    final val = await SecurePrefs.instance.getString('demo_secret');
    setState(() => _secureValue = val);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _saveToCache,
              child: const Text('Save to TTL Cache (5 min)'),
            ),
            if (_cachedValue != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Cached: $_cachedValue'),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveSecure,
              child: const Text('Save to Secure Storage'),
            ),
            if (_secureValue != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Secure: ${_secureValue!.masked(visibleStart: 2)}'),
              ),
            ],
          ],
        ),
      );
}

// ────────────────────────────────────────────────────────────────────────────
// Membership Demo
// ────────────────────────────────────────────────────────────────────────────

class MembershipDemo extends StatefulWidget {
  const MembershipDemo({super.key});

  @override
  State<MembershipDemo> createState() => _MembershipDemoState();
}

class _MembershipDemoState extends State<MembershipDemo> {
  MembershipTier _currentTier = MembershipTier.free;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current tier:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final tier in [
                  MembershipTier.free,
                  MembershipTier.pro,
                  MembershipTier.enterprise,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tier.name),
                      selected: _currentTier == tier,
                      onSelected: (_) => setState(() => _currentTier = tier),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            MemberBadge(tier: _currentTier),
            const SizedBox(height: 24),
            const Text('TierGate Demo:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TierGate(
              requires: MembershipTier.pro,
              currentTier: _currentTier,
              fallback: UpgradePrompt(
                targetTier: MembershipTier.pro,
                featureName: 'Cloud Export',
                style: UpgradePromptStyle.inline,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_upload, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Cloud Export — Pro feature unlocked!'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

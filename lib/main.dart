import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ivzloxwkokirozungdxj.supabase.co',
    publishableKey: 'sb_publishable_zQQYp0_h_n3Tlc2FwanFuA_ApGTqc8X',
  );

  runApp(const CrochetApp());
}

final supabase = Supabase.instance.client;

class CrochetApp extends StatelessWidget {
  const CrochetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Háčkování Objednávky',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink.shade300),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('cs', 'CZ'),
        Locale('en', 'US'),
      ],
      locale: const Locale('cs', 'CZ'),
      home: const OrdersScreen(),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final Stream<List<Map<String, dynamic>>> _ordersStream = 
      supabase.from('objednavky').stream(primaryKey: ['id']).order('created_at', ascending: false);

  // Text controllers
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _detailsController = TextEditingController();
  final _statusController = TextEditingController(); // Flexible status instead of rigid dropdown

  bool _showInlineInput = false;
  dynamic _editingOrderId; // Keeps track of which order we are updating (null = new order)

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _productController.dispose();
    _priceController.dispose();
    _detailsController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  // Handles both creating a new order and updating an existing one
  Future<void> _saveOrder() async {
    if (_nameController.text.isEmpty || _productController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jméno a produkt musí být vyplněny!')),
      );
      return;
    }

    final data = {
      'jmeno_zakaznika': _nameController.text,
      'kontakt': _contactController.text,
      'typ_produktu': _productController.text,
      'cena': double.tryParse(_priceController.text) ?? 0.0,
      'detaily': _detailsController.text,
      'stav': _statusController.text.isEmpty ? 'Nová' : _statusController.text,
    };

    try {
      if (_editingOrderId == null) {
        // Insert new
        await supabase.from('objednavky').insert(data);
      } else {
        // Update existing
        await supabase.from('objednavky').update(data).eq('id', _editingOrderId);
      }

      _clearInputForm();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při ukládání: $error')),
        );
      }
    }
  }

  // Deletes an order from Supabase
  Future<void> _deleteOrder(dynamic id) async {
    try {
      await supabase.from('objednavky').delete().eq('id', id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při mazání: $error')),
        );
      }
    }
  }

  // Populates the input form with existing data for editing
  void _startEditing(Map<String, dynamic> order) {
    setState(() {
      _editingOrderId = order['id'];
      _nameController.text = order['jmeno_zakaznika'] ?? '';
      _contactController.text = order['kontakt'] ?? '';
      _productController.text = order['typ_produktu'] ?? '';
      _priceController.text = order['cena']?.toString() ?? '';
      _detailsController.text = order['detaily'] ?? '';
      _statusController.text = order['stav'] ?? '';
      _showInlineInput = true; // Open the input panel
    });
  }

  void _clearInputForm() {
    _nameController.clear();
    _contactController.clear();
    _productController.clear();
    _priceController.clear();
    _detailsController.clear();
    _statusController.clear();
    setState(() {
      _editingOrderId = null;
      _showInlineInput = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Háčkované Objednávky 🧶'),
        backgroundColor: Colors.pink.shade100,
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              if (_showInlineInput) {
                _clearInputForm();
              } else {
                setState(() {
                  _showInlineInput = true;
                });
              }
            },
            icon: Icon(_showInlineInput ? Icons.close : Icons.add, color: Colors.black),
            label: Text(
              _showInlineInput ? 'Zavřít' : 'Nový',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Inline Editor Panel
          if (_showInlineInput)
            Container(
              color: Colors.pink.shade100.withOpacity(0.3),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    _editingOrderId == null ? '➕ Nová Objednávka' : '✏️ Upravit Objednávku',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink.shade700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController, 
                          decoration: const InputDecoration(labelText: 'Jméno', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _productController, 
                          decoration: const InputDecoration(labelText: 'Produkt', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _priceController, 
                          decoration: const InputDecoration(labelText: 'Cena Kč', isDense: true),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _contactController, 
                          decoration: const InputDecoration(labelText: 'Kontakt', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _detailsController, 
                          decoration: const InputDecoration(labelText: 'Detaily', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _statusController, 
                          decoration: const InputDecoration(labelText: 'Stav (např. Hotovo)', isDense: true),
                        ),
                      ),
                      IconButton(
                        onPressed: _saveOrder, 
                        icon: const Icon(Icons.check_box, color: Colors.green, size: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // Main dynamic stream display list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Chyba stahování dat: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final orders = snapshot.data ?? [];
                
                if (orders.isEmpty) {
                  return const Center(child: Text('Žádné objednávky. Klepněte na "Nový" nahoře pro přidání.'));
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final String currentStatus = order['stav'] ?? 'Nová';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: Colors.pink.shade50,
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${order['jmeno_zakaznika']} — ${order['typ_produktu']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Simple text status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                currentStatus,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Kontakt: ${order['kontakt']}\nDetaily: ${order['detaily']}\nCena: ${order['cena']} Kč',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // EDIT BUTTON
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _startEditing(order),
                            ),
                            // DELETE BUTTON
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // Simple quick-delete alert
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Smazat objednávku?'),
                                    content: const Text('Opravdu chcete tuto objednávku odstranit?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Zrušit'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteOrder(order['id']);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('Smazat', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

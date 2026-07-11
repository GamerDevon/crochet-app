import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Replace these strings with your absolute, real Supabase project credentials!
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
      supabase.from('orders').stream(primaryKey: ['id']).order('created_at', ascending: false);

  // Text inputs for the inline row
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _detailsController = TextEditingController();

  bool _showInlineInput = false;

  Future<void> _addOrder() async {
    if (_nameController.text.isEmpty || _productController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jméno a produkt musí být vyplněny!')),
      );
      return;
    }

    try {
      await supabase.from('orders').insert({
        'jmeno_zakaznika': _nameController.text,
        'kontakt': _contactController.text,
        'typ_produktu': _productController.text,
        'cena': double.tryParse(_priceController.text) ?? 0.0,
        'detaily': _detailsController.text,
        'stav': 'Nová',
      });

      _nameController.clear();
      _contactController.clear();
      _productController.clear();
      _priceController.clear();
      _detailsController.clear();
      
      setState(() {
        _showInlineInput = false; // Collapse row after saving
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při ukládání: $error')),
        );
      }
    }
  }

  Future<void> _updateStatus(dynamic id, String newStatus) async {
    try {
      await supabase.from('orders').update({'stav': newStatus}).eq('id', id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při aktualizaci stavu: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Háčkované Objednávky 🧶'),
        backgroundColor: Colors.pink.shade100,
        centerTitle: true,
        actions: [
          // Clicking this button reveals or hides the next row editor instantly
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showInlineInput = !_showInlineInput;
              });
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
          // Inline layout container that generates a new editable row
          if (_showInlineInput)
            Container(
              color: Colors.pink.shade100.withOpacity(0.3),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _contactController, 
                          decoration: const InputDecoration(labelText: 'Kontakt (IG, FB...)', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _detailsController, 
                          decoration: const InputDecoration(labelText: 'Detaily / Barvy', isDense: true),
                        ),
                      ),
                      IconButton(
                        onPressed: _addOrder, 
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
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: Colors.pink.shade50,
                      child: ListTile(
                        title: Text(
                          '${order['jmeno_zakaznika']} — ${order['typ_produktu']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Kontakt: ${order['kontakt']}\nDetaily: ${order['detaily']}\nCena: ${order['cena']} Kč',
                        ),
                        trailing: DropdownButton<String>(
                          value: order['stav'],
                          items: <String>['Nová', 'Rozpracovaná', 'Dokončená'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newStatus) {
                            if (newStatus != null) {
                              _updateStatus(order['id'], newStatus);
                            }
                          },
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

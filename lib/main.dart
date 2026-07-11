import 'package:flutter/material.dart';

void main() {
  runApp(const CrochetApp());
}

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
  // Local list to store orders immediately
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 1,
      'jmeno_zakaznika': 'Anna Nováková',
      'kontakt': 'IG: @mamma_crochet',
      'typ_produktu': 'Růžový Medvídek',
      'detaily': 'Výška 25cm, bezpečnostní očka',
      'cena': 450,
      'stav': 'Rozpracovaná'
    },
    {
      'id': 2,
      'jmeno_zakaznika': 'Jan Horák',
      'kontakt': '+420 777 123 456',
      'typ_produktu': 'Zimní kulich',
      'detaily': 'Tmavě modrý, s bambulí',
      'cena': 300,
      'stav': 'Nová'
    }
  ];

  // Text inputs
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _detailsController = TextEditingController();

  void _addOrder() {
    if (_nameController.text.isEmpty || _productController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jméno a produkt musí být vyplněny!')),
      );
      return;
    }

    setState(() {
      _orders.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch,
        'jmeno_zakaznika': _nameController.text,
        'kontakt': _contactController.text,
        'typ_produktu': _productController.text,
        'cena': double.tryParse(_priceController.text) ?? 0.0,
        'detaily': _detailsController.text,
        'stav': 'Nová',
      });
    });

    _nameController.clear();
    _contactController.clear();
    _productController.clear();
    _priceController.clear();
    _detailsController.clear();
    
    Navigator.pop(context);
  }

  void _openAddOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nová Objednávka'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Jméno zákazníka')),
              TextField(controller: _contactController, decoration: const InputDecoration(labelText: 'Kontakt (FB, IG, Telefon)')),
              TextField(controller: _productController, decoration: const InputDecoration(labelText: 'Typ produktu (např. Medvídek)')),
              TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Cena (Kč)'), keyboardType: TextInputType.number),
              TextField(controller: _detailsController, decoration: const InputDecoration(labelText: 'Detaily / Barvy')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zrušit')),
          ElevatedButton(onPressed: _addOrder, child: const Text('Uložit')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Háčkované Objednávky 🧶'),
        backgroundColor: Colors.pink.shade100,
        centerTitle: true,
      ),
      body: _orders.isEmpty
          ? const Center(child: Text('Žádné objednávky. Klepněte na + pro přidání.'))
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
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
                          setState(() {
                            order['stav'] = newStatus;
                          });
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddOrderDialog,
        backgroundColor: Colors.pink.shade300,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ivzloxwkokirozungdxj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml2emxveHdrb2tpcm96dW5nZHhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3NjI2NTIsImV4cCI6MjA5OTMzODY1Mn0.m2RM1NANkqCAafNzpLfy8syKNMxm4J_x3VY9nnVCvts',
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
  late final Stream<List<Map<String, dynamic>>> _ordersStream;

  // Textové kontrolery
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _vsController = TextEditingController();
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _shippingController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _statusController = TextEditingController();

  // Boolean stav pro přepínač platby
  bool _isPaid = false;

  bool _showInlineInput = false;
  dynamic _editingOrderId; 

  @override
  void initState() {
    super.initState();
    _ordersStream = supabase
        .from('objednavky')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _vsController.dispose();
    _productController.dispose();
    _priceController.dispose();
    _shippingController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _saveOrder() async {
    if (_nameController.text.isEmpty || _productController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jméno a zboží musí být vyplněny!')),
      );
      return;
    }

    final data = {
      'jmeno_zakaznika': _nameController.text,
      'adresa': _addressController.text,
      'mesto': _cityController.text,
      'psc': _zipController.text,
      'variabilni_symbol': _vsController.text,
      'prijata_platba': _isPaid, // Posíláme čisté True/False
      'zbozi': _productController.text,
      'cena': double.tryParse(_priceController.text) ?? 0.0,
      'doprava': _shippingController.text,
      'telefon': _phoneController.text,
      'email': _emailController.text,
      'stav': _statusController.text.isEmpty ? 'Nová' : _statusController.text,
    };

    try {
      if (_editingOrderId == null) {
        await supabase.from('objednavky').insert(data);
      } else {
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

  void _startEditing(Map<String, dynamic> order) {
    setState(() {
      _editingOrderId = order['id'];
      _nameController.text = order['jmeno_zakaznika'] ?? '';
      _addressController.text = order['adresa'] ?? '';
      _cityController.text = order['mesto'] ?? '';
      _zipController.text = order['psc'] ?? '';
      _vsController.text = order['variabilni_symbol'] ?? '';
      _isPaid = order['prijata_platba'] == true; // Načtení booleanu z DB
      _productController.text = order['zbozi'] ?? order['typ_produktu'] ?? '';
      _priceController.text = order['cena']?.toString() ?? '';
      _shippingController.text = order['doprava'] ?? '';
      _phoneController.text = order['telefon'] ?? '';
      _emailController.text = order['email'] ?? '';
      _statusController.text = order['stav'] ?? '';
      _showInlineInput = true;
    });
  }

  void _clearInputForm() {
    _nameController.clear();
    _addressController.clear();
    _cityController.clear();
    _zipController.clear();
    _vsController.clear();
    _productController.clear();
    _priceController.clear();
    _shippingController.clear();
    _phoneController.clear();
    _emailController.clear();
    _statusController.clear();
    setState(() {
      _isPaid = false;
      _editingOrderId = null;
      _showInlineInput = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Háčkované Objednávky — Desktop Manager 🧶'),
        backgroundColor: Colors.pink.shade100,
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              if (_showInlineInput) {
                _clearInputForm();
              } else {
                setState(() => _showInlineInput = true);
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
          if (_showInlineInput)
            Container(
              color: Colors.pink.shade100.withOpacity(0.3),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _editingOrderId == null ? '➕ Nová Objednávka' : '✏️ Upravit Objednávku',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink.shade700, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Jméno (Zákazník)', isDense: true))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Telefon', isDense: true))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(flex: 2, child: TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Adresa', isDense: true))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'Město', isDense: true))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _zipController, 
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'PSČ (pouze čísla)', isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(flex: 2, child: TextField(controller: _productController, decoration: const InputDecoration(labelText: 'Zboží', isDense: true))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _shippingController, decoration: const InputDecoration(labelText: 'Doprava', isDense: true))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _statusController, decoration: const InputDecoration(labelText: 'Stav objednávky', isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _vsController, 
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Variabilní Symbol (VS)', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _priceController, 
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*'))],
                          decoration: const InputDecoration(labelText: 'Cena (Kč)', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // KLIKACÍ PŘEPÍNAČ BOOLEAN
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Zaplaceno:', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Switch(
                            value: _isPaid,
                            activeColor: Colors.green,
                            onChanged: (bool value) {
                              setState(() {
                                _isPaid = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _saveOrder,
                        icon: const Icon(Icons.save),
                        label: const Text('Uložit'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade200, foregroundColor: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Chyba stahování dat: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) return const Center(child: Text('Žádné objednávky.'));

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final String currentStatus = order['stav'] ?? 'Nová';
                    final bool paidStatus = order['prijata_platba'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: Colors.pink.shade50,
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${order['jmeno_zakaznika']} — ${order['zbozi'] ?? order['typ_produktu'] ?? ''}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.pink.shade100, borderRadius: BorderRadius.circular(12)),
                              child: Text(currentStatus, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '📞 ${order['telefon'] ?? '-'}  |  ✉️ ${order['email'] ?? '-'}\n'
                                  '📍 ${order['adresa'] ?? ''}, ${order['mesto'] ?? ''} ${order['psc'] ?? ''}\n'
                                  '📦 Doprava: ${order['doprava'] ?? '-'}',
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '🔢 VS: ${order['variabilni_symbol'] ?? '-'}\n'
                                  '💰 Cena Celkem: ${order['cena'] ?? 0} Kč\n'
                                  '💳 Platba: ${paidStatus ? "ZAPLACENO ✅" : "NEZAPLACENO ❌"}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    color: paidStatus ? Colors.green.shade800 : Colors.red.shade800
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _startEditing(order)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Smazat objednávku?'),
                                    content: const Text('Opravdu chcete tuto objednávku odstranit?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zrušit')),
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

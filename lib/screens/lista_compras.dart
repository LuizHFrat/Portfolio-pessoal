import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _auth = FirebaseAuth.instance;
  final _itemController = TextEditingController();
  String _selectedCategory = 'Outros';
  String _sortOption = 'timestamp';
  bool _descending = false;

  Map<String, dynamic>? _recentlyDeletedItem;

  Future<void> _addItem() async {
    if (_itemController.text.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final newItem = {
      'name': _itemController.text.trim(),
      'category': _selectedCategory,
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('shopping_list')
        .doc(user.uid)
        .collection('items')
        .add(newItem);

    _itemController.clear();
  }

  Future<void> _deleteItem(String itemId, Map<String, dynamic> itemData) async {
    setState(
      () {
        _recentlyDeletedItem = {'id': itemId, ...itemData};
      },
    );

    final user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('shopping_list')
          .doc(user.uid)
          .collection('items')
          .doc(itemId)
          .delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item excluído.'),
        action: SnackBarAction(
          label: 'Desfazer',
          textColor: Colors.white,
          onPressed: _undoDelete,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _undoDelete() async {
    if (_recentlyDeletedItem == null) return;

    final user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('shopping_list')
          .doc(user.uid)
          .collection('items')
          .add(
        {
          'name': _recentlyDeletedItem!['name'],
          'category': _recentlyDeletedItem!['category'],
          'timestamp': _recentlyDeletedItem!['timestamp'],
        },
      );

      setState(
        () {
          _recentlyDeletedItem = null;
        },
      );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Laticínios':
        return Colors.blueAccent;
      case 'Carnes':
        return Colors.redAccent;
      case 'Verduras':
        return Colors.greenAccent;
      case 'Limpeza':
        return Colors.purpleAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  void _openSortOptions() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 0, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'timestamp',
          child: Text('Ordenar por Data de Adição'),
        ),
        const PopupMenuItem(
          value: 'category',
          child: Text('Ordenar por Categoria'),
        ),
        const PopupMenuItem(
          value: 'name',
          child: Text('Ordenar por Ordem Alfabética'),
        ),
      ],
    ).then(
      (value) {
        if (value != null) {
          setState(
            () {
              _sortOption = value;
              _descending = value == 'timestamp' ? true : false;
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sua Lista de Compras'),
        backgroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            color: theme.colorScheme.onPrimary,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _openSortOptions,
            color: theme.colorScheme.onPrimary,
            tooltip: 'Ordenar',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(
                      labelText: 'Adicione um item',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: const [
                    DropdownMenuItem(
                      value: 'Laticínios',
                      child: Text('Laticínios'),
                    ),
                    DropdownMenuItem(
                      value: 'Carnes',
                      child: Text('Carnes'),
                    ),
                    DropdownMenuItem(
                      value: 'Verduras',
                      child: Text('Verduras'),
                    ),
                    DropdownMenuItem(
                      value: 'Limpeza',
                      child: Text('Limpeza'),
                    ),
                    DropdownMenuItem(
                      value: 'Outros',
                      child: Text('Outros'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(
                      () {
                        _selectedCategory = value!;
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addItem,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('shopping_list')
                  .doc(_auth.currentUser!.uid)
                  .collection('items')
                  .orderBy(_sortOption, descending: _descending)
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final items = snapshot.data!.docs;

                if (items.isEmpty) {
                  return const Center(
                    child: Text('Nenhum item adicionado ainda.'),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, index) {
                    final itemData = items[index].data();
                    final itemId = items[index].id;

                    return Dismissible(
                      key: ValueKey(itemId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: theme.colorScheme.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        _deleteItem(itemId, itemData);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: ListTile(
                          title: Text(
                            itemData['name'],
                          ),
                          subtitle: Text(
                            itemData['category'],
                          ),
                          leading: Container(
                            width: 10,
                            color: _getCategoryColor(
                              itemData['category'],
                            ),
                          ),
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

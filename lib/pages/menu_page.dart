import 'package:flutter/material.dart';
import '../services/menu_service.dart'; // Pastikan file ini sudah dibuat
import '../models/menu.dart';
import '../services/cart_service.dart';
import 'cart_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<Menu> cart = [];
  List<Menu> menuList = []; // Data dari Firestore
  bool isLoading = true;
  String? errorMessage;
  final MenuService _menuService = MenuService(); // Service Firestore

  @override
  void initState() {
    super.initState();
    _loadCart();
    _loadMenusFromFirestore(); // Load dari Firestore
  }

  // Load keranjang dari local storage
  Future<void> _loadCart() async { // UBAH: return Future<void>
    final savedCart = await CartService.loadCart();
    setState(() {
      cart = savedCart;
    });
  }

  // Load menu dari Firestore
  Future<void> _loadMenusFromFirestore() async { // UBAH: return Future<void>
    try {
      final menus = await _menuService.getMenus();
      setState(() {
        menuList = menus;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat menu: $e';
        isLoading = false;
      });
    }
  }

  // Refresh data (pull-to-refresh)
  Future<void> _refreshData() async {
    await _loadMenusFromFirestore();
    await _loadCart();
  }

  // Group menu by category dan sort by order
  Map<String, List<Menu>> get groupedMenu {
    if (menuList.isEmpty) return {};

    final sortedMenu = List<Menu>.from(menuList)
      ..sort((a, b) => a.order.compareTo(b.order));
    
    Map<String, List<Menu>> grouped = {};
    for (var menu in sortedMenu) {
      grouped.putIfAbsent(menu.category, () => []);
      grouped[menu.category]!.add(menu);
    }
    return grouped;
  }

  // Tambah ke keranjang dengan pencegahan duplikasi
  void addToCart(Menu item) async {
    bool isAlreadyInCart = cart.any((cartItem) => cartItem.name == item.name);
    
    if (!isAlreadyInCart) {
      setState(() {
        cart.add(item);
      });
      
      await CartService.saveCart(cart);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} ditambahkan ke keranjang'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} sudah ada di keranjang'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat menu...'),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pemesanan Makanan')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMenusFromFirestore,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final categories = groupedMenu.keys.toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemesanan Makanan'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(cart: cart),
                    ),
                  ).then((_) {
                    _loadCart();
                  });
                },
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      cart.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, categoryIndex) {
            final category = categories[categoryIndex];
            final menusInCategory = groupedMenu[category]!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Kategori
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          '${menusInCategory.length} item',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.green.shade100,
                      ),
                    ],
                  ),
                ),
                
                // List Menu dalam Kategori
                ...menusInCategory.map((item) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Gambar Menu
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              item.image,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('ERROR loading image ${item.image}: $error');
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.fastfood, size: 30),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.name.split(' ').first,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Info Menu
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Rp ${item.price}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '#${item.order}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.category == 'Makanan'
                                            ? Colors.blue.shade50
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: item.category == 'Makanan'
                                              ? Colors.blue.shade700
                                              : Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Tombol Tambah
                          ElevatedButton(
                            onPressed: () => addToCart(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Tambah'),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}
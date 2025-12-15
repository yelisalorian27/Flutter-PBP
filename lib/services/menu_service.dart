import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Menu>> getMenus() async {
    try {
      print('🚀 ======= DEBUG START =======');
      print('🔍 1. Testing Firebase connection...');
      
      // Test koneksi dengan query sederhana
      try {
        await _firestore.collection('test_connection').doc('test').set({
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('✅ Firebase connection OK');
      } catch (e) {
        print('❌ Firebase connection FAILED: $e');
      }
      
      print('🔍 2. Querying collection: MenuPemesanan');
      QuerySnapshot snapshot;
      
      try {
        // Coba query MenuPemesanan
        snapshot = await _firestore
            .collection('MenuPemesanan')
            .get();
            
        print('📊 Documents found in MenuPemesanan: ${snapshot.docs.length}');
        
        // Jika kosong, coba collection lain
        if (snapshot.docs.isEmpty) {
          print('⚠️ MenuPemesanan is empty, trying alternative names...');
          
          final possibleCollections = ['menus', 'menu', 'Menu', 'MENU', 'MenuPemesanan'];
          for (var collectionName in possibleCollections) {
            if (collectionName == 'MenuPemesanan') continue;
            
            try {
              var altSnapshot = await _firestore.collection(collectionName).limit(1).get();
              if (altSnapshot.docs.isNotEmpty) {
                print('✅ Found collection: $collectionName');
                snapshot = await _firestore.collection(collectionName).get();
                break;
              }
            } catch (e) {
              // Ignore error
            }
          }
        }
        
      } catch (e) {
        print('❌ ERROR querying MenuPemesanan: $e');
        print('📋 Full error: ${e.toString()}');
        return [];
      }
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ WARNING: No documents found in any collection!');
        print('ℹ️ Please check Firebase Console');
        return [];
      }
      
      // Print semua data DETAIL
      print('📋 === DETAILED DATA FROM FIRESTORE ===');
      print('Collection: ${snapshot.docs.first.reference.parent.id}');
      
      for (var i = 0; i < snapshot.docs.length; i++) {
        var doc = snapshot.docs[i];
        var data = doc.data() as Map<String, dynamic>;
        
        print('\n📄 Document $i (ID: ${doc.id}):');
        print('   ├─ name:     ${data['name'] ?? "NULL"}');
        print('   ├─ image:    ${data['image'] ?? "NULL"}');
        print('   ├─ price:    ${data['price'] ?? "NULL"} (${data['price']?.runtimeType})');
        print('   ├─ category: ${data['category'] ?? "NULL"}');
        print('   └─ order:    ${data['order'] ?? "NULL"} (${data['order']?.runtimeType})');
        
        // Warning jika ada field null
        List<String> missingFields = [];
        if (data['name'] == null) missingFields.add('name');
        if (data['image'] == null) missingFields.add('image');
        if (data['price'] == null) missingFields.add('price');
        if (data['category'] == null) missingFields.add('category');
        if (data['order'] == null) missingFields.add('order');
        
        if (missingFields.isNotEmpty) {
          print('   ⚠️  MISSING: ${missingFields.join(", ")}');
        }
      }
      print('\n📋 ====================================');
      
      // Convert to Menu objects dengan FIX untuk huruf besar/kecil
      List<Menu> menus = [];
      int successCount = 0;
      int errorCount = 0;
      
      for (var doc in snapshot.docs) {
        try {
          var data = doc.data() as Map<String, dynamic>;
          
          // FIX: Handle both lowercase and uppercase field names
          String name = data['name']?.toString() ?? 
                        data['Name']?.toString() ?? 
                        'Unknown Menu';
          
          String image = data['image']?.toString() ?? 
                         data['Image']?.toString() ?? 
                         'assets/images/placeholder.png';
          
          // Try both 'price' and 'Price'
          dynamic priceData = data['price'] ?? data['Price'];
          int price = _parsePrice(priceData);
          
          String category = data['category']?.toString() ?? 
                            data['Category']?.toString() ?? 
                            'Unknown';
          
          // Try both 'order' and 'Order'
          dynamic orderData = data['order'] ?? data['Order'];
          int order = _parseOrder(orderData);
          
          // Validasi data penting
          if (name == 'Unknown Menu' || price == 0) {
            print('⚠️  Skipping invalid menu: $name (price: $price)');
            errorCount++;
            continue;
          }
          
          menus.add(Menu(
            name: name,
            image: image,
            price: price,
            category: category,
            order: order,
          ));
          
          successCount++;
          print('✅ Parsed: $name (Rp $price)');
          
        } catch (e) {
          print('❌ Failed to parse document ${doc.id}: $e');
          errorCount++;
        }
      }
      
      print('\n🎯 RESULT SUMMARY:');
      print('   ✅ Successfully parsed: $successCount menus');
      print('   ❌ Failed to parse: $errorCount menus');
      print('   📦 Total in collection: ${snapshot.docs.length} documents');
      print('🚀 ======= DEBUG END =======\n');
      
      return menus;
      
    } catch (e) {
      print('💥 FATAL ERROR in MenuService.getMenus(): $e');
      print('📋 Error type: ${e.runtimeType}');
      print('📋 Full error: ${e.toString()}');
      return [];
    }
  }
  
  // Helper function untuk parse price
  int _parsePrice(dynamic price) {
    if (price == null) return 0;
    
    try {
      if (price is int) return price;
      if (price is double) return price.toInt();
      if (price is String) {
        // Remove currency symbols and formatting
        String cleaned = price
            .replaceAll('Rp', '')
            .replaceAll('IDR', '')
            .replaceAll('.', '')
            .replaceAll(',', '')
            .replaceAll(' ', '')
            .trim();
        return int.tryParse(cleaned) ?? 0;
      }
      if (price is num) return price.toInt();
    } catch (e) {
      print('⚠️  Error parsing price "$price": $e');
    }
    
    return 0;
  }
  
  // Helper function untuk parse order
  int _parseOrder(dynamic order) {
    if (order == null) return 0;
    
    try {
      if (order is int) return order;
      if (order is double) return order.toInt();
      if (order is String) return int.tryParse(order) ?? 0;
      if (order is num) return order.toInt();
    } catch (e) {
      print('⚠️  Error parsing order "$order": $e');
    }
    
    return 0;
  }
}
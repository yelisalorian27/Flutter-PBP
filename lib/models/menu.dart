class Menu {
  final String name;
  final String image;
  final int price;
  final String category;
  final int order;

  Menu({
    required this.name,
    required this.image,
    required this.price,
    required this.category,
    required this.order,
  });

  // Untuk penyimpanan ke SharedPreferences
  Map<String, dynamic> toJson() => {
    'name': name,
    'image': image,
    'price': price,
    'category': category,
    'order': order,
  };

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      name: json['name'],
      image: json['image'],
      price: json['price'],
      category: json['category'],
      order: json['order'],
    );
  }

  // Untuk pencegahan duplikasi (berdasarkan nama)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Menu && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
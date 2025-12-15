class MenuItem {
  final String name;
  final String image;
  final int price;
  final String category;
  final int order;

  MenuItem({
    required this.name,
    required this.image,
    required this.price,
    required this.category,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'image': image,
        'price': price,
        'category': category,
        'order': order,
      };

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      name: json['name'],
      image: json['image'],
      price: json['price'],
      category: json['category'],
      order: json['order'],
    );
  }
}

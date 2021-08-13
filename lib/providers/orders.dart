import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  List<OrderItem> get orders {
    return [..._orders];
  }

  final String authToken;
  Orders(this.authToken, this._orders);

  Future<void> fetchOrders() async {
    final url = Uri.parse(
        'https://flutter-shop-app-6565c-default-rtdb.asia-southeast1.firebasedatabase.app/orders.json?auth=$authToken');
    final response = await http.get(url);
    print(json.decode(response.body).runtimeType);
    final extractedData = json.decode(response.body) as Map<String, dynamic>;
    final List<OrderItem> loadedOrders = [];
    if (extractedData == null) {
      _orders = [];
      return;
    }
    extractedData.forEach((orderKey, orderData) {
      loadedOrders.add(
        OrderItem(
          id: orderKey,
          amount: orderData['amount'],
          // Converting that ISO6601 string back to a DateTime Object
          dateTime: DateTime.parse(orderData['dateTime']),
          products: (orderData['products'] as List<dynamic>)
              .map(
                (item) => CartItem(
                  id: item['id'],
                  title: item['title'],
                  quantity: item['quantity'],
                  price: item['price'],
                ),
              )
              .toList(),
        ),
      );
    });
    _orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url = Uri.parse(
        'https://flutter-shop-app-6565c-default-rtdb.asia-southeast1.firebasedatabase.app/orders.json?auth=$authToken');
    final DateTime timestamp = DateTime.now();
    final response = await http.post(url,
        body: json.encode({
          'amount': total,
          'dateTime': timestamp
              .toIso8601String(), //This string conversion is easily convertable back to a DateTime Object
          'products': cartProducts
              .map((cp) => {
                    'id': cp.id,
                    'title': cp.title,
                    'quantity': cp.quantity,
                    'price': cp.price,
                  })
              .toList(),
        }));
    final addedOrder = OrderItem(
      // Giving it the id randomly generated by firebase
      id: json.decode(response.body)['name'],
      amount: total,
      dateTime: timestamp,
      products: cartProducts,
    );
    _orders.insert(0, addedOrder);
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:tacoprime/models/restaurant.dart';

class Cart extends ChangeNotifier{

// list of items for sale
List<Restaurant> restaurantShop = [
  Restaurant(
    name: 'Taco Bell', 
    imagePath: 'lib/images/taco_bell.jpg', 
    description: 'Taco Bell is an American-based chain of fast food restaurants by founder Glen Bell.',
    ),
  Restaurant(
    name: 'Chipotle', 
    imagePath: 'lib/images/chipotle.jpg', 
    description: 'Chipotle Mexican Grill, Inc. is an American chain of fast casual restaurants in the United States, United Kingdom, Canada, Germany, and France.',
    ),
  Restaurant(
    name: 'Taco Cabana', 
    imagePath: 'lib/images/taco_cabana.jpg', 
    description: 'Taco Cabana is an American fast casual restaurant chain specializing in Mexican cuisine.',
    ),
  Restaurant(
    name: 'Torchys Tacos', 
    imagePath: 'lib/images/torchys_tacos.jpg', 
    description: 'Torchy\'s Tacos is an American fast casual street taco restaurant chain based in Austin, Texas.',
    ),
];

// list of items in the cart
List<Restaurant> userCart = [];

// get list of items for sale
List<Restaurant> getRestaurantList() {
  return restaurantShop;
}

// get cart
List<Restaurant> getCart() {
  return userCart;
}

// add item to cart
void addToCart(Restaurant restaurant) {
  userCart.add(restaurant);
  notifyListeners();
}

// remove item from cart
void removeFromCart(Restaurant restaurant) {
  userCart.remove(restaurant);
  notifyListeners();
  }

}
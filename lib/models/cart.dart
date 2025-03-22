import 'package:flutter/material.dart';
import 'package:tacoprime/models/restaurant.dart';

class Cart extends ChangeNotifier{

// list of items for sale
List<Restaurant> restaurantShop = [

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
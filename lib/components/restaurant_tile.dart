import 'package:flutter/material.dart';
import 'package:tacoprime/models/restaurant.dart';

class RestaurantTile extends StatelessWidget {
  final Restaurant restaurant;
  final void Function()? onTap;
  RestaurantTile({super.key, required this.restaurant, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        // Restaurant Image
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(restaurant.imagePath)),


        
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              
              // Text Column for Restaurant Name and Description
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant Name
                      Text(
                        restaurant.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Restaurant Description
                      Text(
                        restaurant.description,
                        style: TextStyle(color: Colors.grey[600]),
                        // If you want to limit lines:
                        // maxLines: 2,
                        // overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

          
                // Button
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    margin: EdgeInsets.only(left: 8),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                        ),
                      ),
                ),
                  ],
                ),
        ),


      ],),
    );
  }
}
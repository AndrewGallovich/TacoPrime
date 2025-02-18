import 'package:flutter/material.dart';
import 'package:tacoprime/models/restaurant.dart';

class RestaurantTile extends StatelessWidget {
  final Restaurant restaurant;
  RestaurantTile({super.key, required this.restaurant});

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
          child: Image.asset(restaurant.imagePath)),


        
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              
              // Text Column for Restaurant Name and Description
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Restaurant Name
                  Text(
                    restaurant.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),


                  // Restaurant Description
                  Text(
                    restaurant.description,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),

          
                // Plus Button
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),


      ],),
    );
  }
}
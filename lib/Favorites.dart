import 'package:flutter/material.dart';

import 'databaseHelper.dart';

class FavoritesScreen extends StatefulWidget {
  final List<String> favorites;
  final bool dark;

  FavoritesScreen({Key? key, required this.favorites, required this.dark}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: widget.dark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, // Set the color of the icon to white
          ),
          backgroundColor: Color(0xFF490F0E),
          title: Text(
            'پسندیدہ',
            style: TextStyle(fontFamily: "علوی نستعلیق", fontSize: 30, color: Colors.white),
          ),
          centerTitle: true,
          leading: IconButton( // Add leading IconButton for back navigation
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop(); // Navigate back
            },
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: widget.dark? Color(0xEC0F0F10) : null,
          ),
          child: ListView.builder(
            itemCount: widget.favorites.length,
            itemBuilder: (context, index) {
              String favorite = widget.favorites[index];
              bool isFavorite = widget.favorites.contains(favorite);

              return Column(
                children: [
                  ListTile(
                    title: Center(child: Text(favorite,style: TextStyle(fontSize: 15),)),
                    trailing: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Color(0xFF890F1E) : null,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isFavorite) {
                            // Remove from favorites
                            DatabaseHelper().removeFavorite(favorite);
                            widget.favorites.remove(favorite);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: Duration(milliseconds:500 ),
                                content: Text('پسندیدہ سے ہٹا دیا گیا'), backgroundColor: widget.dark? Colors.black : Color(0xFF490F0E),),
                            );
                          } else {
                            // Add to favorites
                            DatabaseHelper().insertFavorite(favorite);
                            widget.favorites.add(favorite);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(                                              duration: Duration(milliseconds:500 ),
                                  content: Text('پسندیدہ میں شامل کیا گیا')),
                            );
                          }
                        });
                      },
                    ),
                  ),
                  Divider( // Add a divider after each list item
                    height: 0, // You can adjust the height as needed
                    color: Colors.grey[400], // Set the color of the divider
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

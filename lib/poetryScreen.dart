import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:xml/xml.dart' as xml;
import 'Favorites.dart';
import 'databaseHelper.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

class PoetryScreen extends StatefulWidget {
  @override
  _PoetryScreenState createState() => _PoetryScreenState();
}

class Poetry {
  final String content;

  Poetry(this.content);
}

class _PoetryScreenState extends State<PoetryScreen> {
  List<Poetry> poetryList = [];
  String poetryIndex = '';
  List<String> poetryIndex1 = [];
  List<dynamic> poetryIndex12 = [];
  Set<int> favorites = Set<int>();
  Color _backgroundColor = Colors.white;
  AssetImage _backgroundImage =
      AssetImage('assets/korakaghaz1.jpg'); // Default image
  final TextEditingController _pageController = TextEditingController();
  final PageController _pageControllerPageView = PageController();
  bool isDarkMode = false;
  List<String> filteredPoetryList = [];
  DatabaseHelper databaseHelper = DatabaseHelper();
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  InterstitialAd? _interstitialAd;
  bool _interstitialAdShown = false;

  List<String> indexStrings = [
    "متفرق اشعار\nصفحہ نمبر 1 تا 72",
    "غزل: اجڑ اجڑ کے سنورتی ہے تیرے ہجر کی شام\nصفحہ نمبر 73",
    "غزل: آنکھوں کے کشکول شکستہ ہو جائیں گے شام کو\nصفحہ نمبر 74",
    "غزل: کہاں سے آ گیا کہاں یہ شام بھی کہاں ہوئی\nصفحہ نمبر 75",
    "غزل: کتنی مشکل سے بہلا تھا یہ کیا کر گئی شام\nصفحہ نمبر 76",
    "غزل: دھانی سرمئی سبز گلابی جیسے ماں کا آنچل شام\nصفحہ نمبر 77",
    "غزل: کہتے ہیں لوگ یہ کہ بڑی دل نشیں ہے شام\nصفحہ نمبر 78",
    "غزل: تا حشر ضد میں صبح کی آتی رہے گی شام\nصفحہ نمبر 79",
    "غزل: دے اٹھی لو جو ترے ساتھ گزاری ہوئی شام\nصفحہ نمبر 80",
    "غزل: حیات سوختہ ساماں اک استعارۂ شام\nصفحہ نمبر 81",
    "غزل: البیلی کامنی کہ نشیلی گھڑی ہے شام\nصفحہ نمبر 82",
  ];
  bool isLoading = true;

  void fetchData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference<Map<String, dynamic>> indexStringsCollection = firestore.collection('Index');
    bool isLoading = true;

    try {
      // Fetch all documents from the collection
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
      await indexStringsCollection.get();

      List<String> textArray = [];

      // Extract and display each string
      querySnapshot.docs.forEach((DocumentSnapshot doc) {
        // Extract text array from each document and add to the list
        List<String> text = List<String>.from(doc['text']);
        textArray.addAll(text);
      });

      // Update the state with the text array
      setState(() {
        poetryIndex12.addAll(textArray);
      });

      // Print the fetched strings
      print('Strings: $poetryIndex12');
    } catch (e) {
      print('Error fetching data: $e');
    }
  }



  @override
  void initState() {
    super.initState();
    loadPoetryData();
    loadFavorites();
    fetchData();
    loadinstertialAd();
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }
  @override
  void dispose() {
    _bannerAd!.dispose();
    _fontSizeController.dispose();
    _interstitialAd!.dispose();
    super.dispose();
  }

  loadinstertialAd() {
    InterstitialAd.load(
        adUnitId: adInsUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {},
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  loadinstertialAd();
                },
                // Called when a click is recorded for an ad.
                onAdClicked: (ad) {});

            debugPrint('$ad loaded.');
            // Keep a reference to the ad so you can show it later.
            setState(() {
              _interstitialAd = ad;
            });
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }
  final adUnitId = 'ca-app-pub-3940256099942544/2934735716';
  // final adInsUnitId ='';
  // final adInsUnitId ='ca-app-pub-6941566226636802/8666232544';
  final adInsUnitId ='ca-app-pub-3940256099942544/4411468910';
  // : 'ca-app-pub-3940256099942544/4411468910';

  void loadFavorites() async {
    List<String> favoriteList = await databaseHelper.getFavoriteList();
    setState(() {
      favorites = Set<int>.from(favoriteList.map((content) =>
          poetryIndex1.indexWhere((poetry) => poetry.contains(content))));
    });
  }
  //
  // void loadPoetryData() async {
  //   // Load poetry data from XML file
  //   String xmlData = await DefaultAssetBundle.of(context)
  //       .loadString('assets/strings-edited.xml');
  //   var parsedXml = xml.XmlDocument.parse(xmlData);
  //
  //   var indexElement = parsedXml
  //       .findAllElements('string')
  //       .firstWhere((element) => element.getAttribute('name') == 'index');
  //   // var indexElement1 = parsedXml.findAllElements('string').firstWhere((element) => element.getAttribute('name') == 'xx1');
  //   var xxElements = parsedXml.findAllElements('string').where((element) {
  //     var nameAttribute = element.getAttribute('name');
  //     return nameAttribute != null && nameAttribute.contains('xx');
  //   });
  //
  //   // Increment and add xxStrings
  //   int index = 1;
  //   var totalPages = xxElements.length;
  //   xxElements.forEach((element) {
  //     setState(() {
  //       poetryIndex1.add('\n $index / $totalPages\n\n${element.text}');
  //       index++;
  //     });
  //   });
  //   setState(() {
  //     poetryIndex = indexElement.text;
  //   });
  //   filteredPoetryList = List.from(poetryIndex1);
  //
  //   // setState(() {
  //   //   poetryIndex1 = indexElement1.text;
  //   // });
  // }
  void loadPoetryData() async {
    // Load poetry data from Firebase Storage XML file
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('xml/strings-edited.xml');

    try {
      // Download XML file as a byte buffer
      final xmlDataBytes = await ref.getData();

      // Convert byte buffer to string with UTF-8 encoding
      String xmlData = utf8.decode(xmlDataBytes!);

      // Parse XML data
      var parsedXml = xml.XmlDocument.parse(xmlData);

      var indexElement = parsedXml
          .findAllElements('string')
          .firstWhere((element) => element.getAttribute('name') == 'index');

      var xxElements = parsedXml.findAllElements('string').where((element) {
        var nameAttribute = element.getAttribute('name');
        return nameAttribute != null && nameAttribute.contains('xx');
      });

      // Increment and add xxStrings
      int index = 1;
      var totalPages = xxElements.length;
      xxElements.forEach((element) {
        setState(() {
          poetryIndex1.add('\n $index / $totalPages\n\n${element.text}');
          index++;
        });
      });
      setState(() {
        poetryIndex = indexElement.text;
        filteredPoetryList = List.from(poetryIndex1);
        isLoading = false; // Set loading state to false when data is loaded
      });
    } catch (e) {
      print('Error loading poetry data: $e');
      setState(() {
        isLoading = false; // Set loading state to false if an error occurs
      });
    }
  }

  bool showPoetryIndex = false;
  String selectedFont = 'علوی نستعلیق'; // Default font
  int currentIndex = 0;
  Function(int)? onTabTapped;
  double _fontSize = 20.0; // Initial font size
  TextEditingController _fontSizeController = TextEditingController();



  @override
  Widget build(BuildContext context) {
    DateTime? currentBackPressTime;

    return  WillPopScope(
      onWillPop: () async {
        DateTime now = DateTime.now();
        if (currentBackPressTime == null ||
            now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
          currentBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              backgroundColor: isDarkMode? Colors.black : Color(0xFF490F0E),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, // Set the color of the icon to white
          ),
          title: Center(
            child: const Text(
               "شامِ  اُداس",
              style: TextStyle(
                  color: Colors.white, fontFamily: "علوی نستعلیق", fontSize: 25),
            ),
          ),
          backgroundColor: isDarkMode ? Color(0xFF490F0E) : Color(0xFF490F0E),
          actions: [

            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  isDarkMode = !isDarkMode;
                });
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor:  isDarkMode
          ? Colors.black
          : Colors
          .white,
          selectedItemColor: isDarkMode
              ? Colors.white
              : Colors
              .black,
          unselectedItemColor: isDarkMode
              ? Colors.white
              : Colors
              .black,
          // Set favorite icon color for dark mode
          currentIndex: currentIndex,
          onTap: onTabTapped,
          type: BottomNavigationBarType
              .fixed, // Use fixed type to evenly space items
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
        icon: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Color(0xFF890F1E), width: 3.0),
        ),
        child: IconButton(
                icon: Icon(
                  Icons.home,
                 color: isDarkMode
                ? Colors.white
                    : Colors
                    .black, // Set favorite icon color for dark mode
                ),
                onPressed: () {
                  _goToPage(1);
                },
              )),
              label: 'شروع سے',

            ),
            BottomNavigationBarItem(
            icon: Container(
            decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFF890F1E), width: 3.0),
            ),
            child: IconButton(
                icon: Icon(Icons.list, color: isDarkMode
                    ? Colors.white
                    : Colors
                    .black, // Set favorite icon color for dark mode
                ),
                onPressed: () {
                  _openIndexDialog(context);
                },
              )),
              label: 'فہرست',
            ),
            BottomNavigationBarItem(
            icon: Container(
            decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFF890F1E), width: 3.0),
            ),
            child: IconButton(
                icon: Icon(Icons.search, color: isDarkMode
                    ? Colors.white
                    : Colors
                    .black, // Set favorite icon color for dark mode
                ),
                onPressed: () {
                  _openSearchDialog(context);
                },
              )),
              label: 'تلاش کریں',
            ),
            BottomNavigationBarItem(
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFF890F1E), width: 3.0),
                ),
                child: IconButton(
                icon: Icon(Icons.favorite, color: isDarkMode
                    ? Colors.white
                    : Colors
                    .black, // Set favorite icon color for dark mode
                ),
                onPressed: () {
                  _navigateToFavoritesScreen();
                },
              ),

            ),  label: 'پسندیدہ',),
            BottomNavigationBarItem(
            icon: Container(
            decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFF890F1E), width: 3.0),
            ),
            child: IconButton(
                icon: Icon(Icons.settings, color: isDarkMode
                    ? Colors.white
                    : Colors
                    .black, // Set favorite icon color for dark mode
                ),
                onPressed: () {
                  _openSettingsDialog(context);
                },
              )),
              label: 'ترتیبات',
            ),
          ],
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black, // You can adjust the color of the border here
              width: 2.0, // You can adjust the width of the border here
            ),
          ),
          child: Column(
            children: [
              Container(
                // alignment: Alignment.center,
                child: AdWidget(ad: _bannerAd!),
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
              ),
              Expanded(
                child: Container(
                  // color: isDarkMode ? Colors.black : null, // Set background color for dark mode
                  decoration: isDarkMode
                      ? BoxDecoration(
                          color: isDarkMode ? Color(0xEC0F0F10) : null,
                        )
                      : BoxDecoration(
                          image: DecorationImage(
                            image: _backgroundImage,
                            fit: BoxFit.cover,
                          ),
                        ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(right: 50,),
                    child: Container(
                      decoration: BoxDecoration(color: isDarkMode
                          ? Colors.black26
                          : Colors
                          .white,),
                      width: MediaQuery.of(context).size.width,
                      child: isLoading
                          ? Center(
                        child: CircularProgressIndicator(), // Show circular progress indicator while loading
                      )
                          : PageView.builder(
                        controller: _pageControllerPageView,
                        itemCount: filteredPoetryList.length,
                        reverse: true,
                        itemBuilder: (context, pageIndex) {
                          if ((pageIndex + 1) % 14 == 0) {
                            // Ensure the ad is loaded before showing it
                            if (_interstitialAd != null && !_interstitialAdShown) {
                              _interstitialAd!.show();
                              _interstitialAdShown = true; // Mark ad as shown on this page
                            } else if (_interstitialAd == null) {
                              // Load the ad if it's not already loaded
                              loadinstertialAd();
                            }
                          } else if ((pageIndex + 1) % 8 != 0) {
                            // Reset the flag after every 8 pages
                            _interstitialAdShown = false;
                          }
                          return StreamBuilder<bool>(
                            stream: databaseHelper
                                .isFavoriteInDatabaseStream(poetryIndex1[pageIndex]),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(
                                    child:
                                        CircularProgressIndicator()); // or some loading indicator
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                bool isFavorite = snapshot.data ?? false;

                                return SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        filteredPoetryList[pageIndex],
                                        style: TextStyle(
                                          fontSize: _fontSize,
                                          fontFamily: selectedFont,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors
                                                  .black, // Set text color for dark mode
                                        ),
                                        textAlign:
                                            TextAlign.center, // Align text to center
                                      ),
                                      SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFavorite
                                                  ? Color(0xFF890F1E)
                                                  : (isDarkMode
                                                      ? Colors.white
                                                      : Colors
                                                          .black), // Set favorite icon color for dark mode
                                            ),
                                            onPressed: () async {
                                              setState(() {
                                                if (isFavorite) {
                                                  favorites.remove(pageIndex);
                                                  databaseHelper.removeFavorite(
                                                      filteredPoetryList[pageIndex]);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      duration: Duration(milliseconds:500 ),

                                                      content: Text(
                                                            'پسندیدہ سے ہٹا دیا گیا'),backgroundColor: isDarkMode? Colors.black : Color(0xFF490F0E),),
                                                  );
                                                } else {
                                                  favorites.add(pageIndex);
                                                  databaseHelper.insertFavorite(
                                                      filteredPoetryList[pageIndex]);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      duration: Duration(milliseconds:500 ),
                                                        content: Text(
                                                            'پسندیدہ میں شامل کیا گیا'),backgroundColor: isDarkMode? Colors.black : Color(0xFF490F0E),),
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                          SizedBox(width: 20),
                                          IconButton(
                                            icon: Icon(
                                              Icons.share,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors
                                                      .black, // Set favorite icon color for dark mode
                                            ),
                                            onPressed: () {
                                              Share.share(poetryIndex1[pageIndex]);
                                            },
                                          ),
                                          SizedBox(width: 20),
                                          IconButton(
                                            icon: Icon(
                                              Icons.copy,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors
                                                      .black, // Set favorite icon color for dark mode
                                            ),
                                            onPressed: () {
                                              FlutterClipboard.copy(
                                                      poetryIndex1[pageIndex])
                                                  .then((value) =>
                                                      ScaffoldMessenger.of(context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'کلپ بورڈ پر کاپی کیا گیا ہے'),
                                                        ),
                                                      ));
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  void _openImageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode
              ? Colors.black87
              : Colors
              .white,
          title: Center(
            child: Text(
              'صفحہ کا ڈیزائن تبدیل کریں',
              style: TextStyle(
                fontFamily: "علوی نستعلیق",
                color: isDarkMode
                    ? Colors.white
                    : Colors
                    .black87,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImageOption('assets/chamraykakhat.jpg'),
                _buildImageOption('assets/gata.jpg'),
                _buildImageOption('assets/kalachamra.jpg'),
                _buildImageOption('assets/korakaghaz1.jpg'),
                _buildImageOption('assets/lakrikatakhta.jpg'),
                _buildImageOption('assets/newbook1.jpg'),
                _buildImageOption('assets/newdiary.jpg'),
                _buildImageOption('assets/p13.jpg'),
                _buildImageOption('assets/puranidiary.jpg'),
                _buildImageOption('assets/puranikitaab.jpg'),
                // Add more image options as needed
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOption(String imagePath) {
    return InkWell(
      onTap: () {
        setState(() {
          _backgroundImage = AssetImage(imagePath);
        });
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
      child: Image.asset(
        imagePath,
        width: 100,
        height: 100,
        fit: BoxFit.cover,

      ),
    );
  }

  void _goToPage(int pageNumber) {
    // int pageNumber = int.tryParse(_pageController.text) ?? 0;
    if (pageNumber > 0 && pageNumber <= poetryIndex1.length) {
      // Scroll to the desired page
      _pageControllerPageView.animateToPage(
        pageNumber - 1,
        duration: Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    } else {
      // Show error message if the page number is out of bounds
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid page number'),
        ),
      );
    }
  }

  void _openSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode
              ? Colors.black
              : Colors
              .white,
          title: Center(
            child: Text(
              'ترتیبات',
              style: TextStyle(
                fontFamily: "علوی نستعلیق",
                color: isDarkMode
                    ? Colors.white
                    : Colors
                    .black,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('فونٹ تبدیل کریں',
                    style: TextStyle(
                      fontFamily: "علوی نستعلیق",
                      color: isDarkMode
                          ? Colors.white
                          : Colors
                          .black,
                    )),
                onTap: () {
                  // Open dialog to change font
                  _openFontSelectionDialog(context);
                },
              ),
              ListTile(
                title: Text('صفحہ کا ڈیزائن تبدیل کریں',
                    style: TextStyle(
                      fontFamily: "علوی نستعلیق",
                      color: isDarkMode
                          ? Colors.white
                          : Colors
                          .black,
                    )),
                onTap: () {
                  // Open dialog to change background image
                  _openImageSelectionDialog(context);
                },
              ),
              ListTile(
                title: Text(
                  'فونٹ سائز تبدیل کریں',
                  style: TextStyle(
                    fontFamily: "علوی نستعلیق",
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () {
                  // Open dialog to change font size
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: isDarkMode
                            ? Colors.black
                            : Colors
                            .white,
                        title: Text(
                          ' فونٹ سائز تبدیل کریں',

                          style: TextStyle(
                            fontFamily: "علوی نستعلیق",
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        content: TextField(
                          controller: _fontSizeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'فونٹ سائز',
                            labelStyle:TextStyle(color: isDarkMode
                                ? Colors.white
                                : Colors
                                .black,),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                              _interstitialAd!.show();
                            },
                            child: Text(
                              'منسوخ کریں',
                              style: TextStyle(
                                fontFamily: "علوی نستعلیق",
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Apply the font size entered by the user
                              setState(() {
                                double? fontSize =
                                double.tryParse(_fontSizeController.text);
                                if (fontSize != null) {
                                  // Update the font size
                                  _fontSize = fontSize;
                                }
                              });
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'لاگو کریں',
                              style: TextStyle(
                                fontFamily: "علوی نستعلیق",
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFontSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode
              ? Colors.black
              : Colors
              .white,
          title: Center(
            child: Text('فونٹ منتخب کریں',
                style: TextStyle(
                  fontFamily: "علوی نستعلیق",
                  color: isDarkMode
                      ? Colors.white
                      : Colors
                      .black,
                )),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFontOption('جمیل نوری نستعلیق'),
                _buildFontOption('علوی نستعلیق'),
                _buildFontOption('پاک نستعلیق'),
                _buildFontOption('ادوبی عربی بولڈ'),
                _buildFontOption('AA سمیر بسام'),
                _buildFontOption('AA سمیر ذکرن'),
                _buildFontOption('القلم نقش'),
                _buildFontOption('القلم ٹیلینو'),
                _buildFontOption('صدف یونیکوڈ'),
                _buildFontOption('تراد عربی بولڈ یونیکوڈ'),
                _buildFontOption('اردو عماد نستعلیق'),
                // Add more font options as needed
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFontOption(String font) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedFont = font;
        });
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
      child: ListTile(
        title: Center(
          child: Text(font,style: TextStyle(fontFamily:"علوی نستعلیق",color: isDarkMode
              ? Colors.white
              : Colors
              .black,),),
        ),
      ),
    );
  }

  void _openSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String pageNumber = '';

        return AlertDialog(
          backgroundColor:  isDarkMode
              ? Colors.black
              : Colors
              .white,
          title: Center(
            child: Text('تلاش کریں',
                style: TextStyle(
                  fontFamily: "علوی نستعلیق",color:  isDarkMode
                    ? Colors.white
                    : Colors
                    .black,
                )),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  pageNumber = value;
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '...صفحہ نمبر',
                  hintStyle: TextStyle(
                    fontFamily: "علوی نستعلیق",
                    color:  isDarkMode
                        ? Colors.white
                        : Colors
                        .black,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
        style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            // Return the color when the button is disabled
            return Colors.grey;
          }
          // Return the color based on isDarkMode flag
          return isDarkMode ? Colors.white : Colors.black;
        },
        )),
              onPressed: () {
                if (pageNumber.isNotEmpty) {
                  int? parsedPageNumber = int.tryParse(pageNumber);
                  if (parsedPageNumber != null) {
                    if (parsedPageNumber > 0 && parsedPageNumber <= 295) {
                      _goToPage(parsedPageNumber);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a valid page number'),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Invalid page number'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a page number'),
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Center(
                child: Text('تلاش کریں',
                    style: TextStyle(
                      fontFamily: "علوی نستعلیق",
                      color:  isDarkMode
                          ? Colors.black
                          : Colors
                          .white,

                    )),
              ),
            ),
          ],
        );
      },
    );
  }
  void _navigateToFavoritesScreen() async {
    List<String> favorites = await databaseHelper.getFavoriteList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FavoritesScreen(favorites: favorites, dark: isDarkMode),
      ),
    );
  }

  void _openIndexDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor:  isDarkMode
                ? Colors.black
                : Colors
                .white,
              title: Center(
                child: Text('فہرست',
                    style: TextStyle(
                      fontFamily: "علوی نستعلیق",
                      color:  isDarkMode
                          ? Colors.white
                          : Colors
                          .black,
                    )),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: poetryIndex12.map((poetryIndex) {
                    return ListTile(
                      // tileColor: Color(0xFF490F0E), // Change the background color of the ListTile
                      title: Center(
                        child: Text(
                          poetryIndex,
                          style: TextStyle(
                            fontFamily: "علوی نستعلیق",
                            fontSize: 16,
                            color:  isDarkMode
                                ? Colors.white
                                : Colors
                                .black,
                          ),
                        ),
                      ),
                      onTap: () {
                        String tappedIndex = poetryIndex;
                        // You can now use the tappedIndex variable to access the title of the index string
                        print("Tapped Index: $tappedIndex");
                        RegExp regExp = RegExp(r'\d+');
                        Iterable<Match> matches =
                            regExp.allMatches(tappedIndex);

                        List<int> numbers = [];
                        for (Match match in matches) {
                          numbers.add(int.parse(match.group(0)!));
                        }

                        print(numbers);
                        if (tappedIndex.contains("167")) {
                          // _search("", "${numbers[0]}");
                          _goToPage(numbers[0]);
                          Navigator.pop(context);
                        } else if (tappedIndex.contains("168")) {
                          // _search("", "${numbers[1]}");
                          _goToPage(numbers[1]);
                          Navigator.pop(context);
                        } else {
                          // _search("", "${numbers[0]}");
                          _goToPage(numbers[0]);
                          Navigator.pop(context);
                        }
                      },
                    );
                  }).toList(),
                ),
              ) // Add more font options as neede
              );
        });
  }
}

import 'dart:io' show Platform;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:yura_trophy/trophy_list.dart';
import 'main.dart';
import 'package:flutter/material.dart';

class Backlog extends StatefulWidget {
  final String website;

  Backlog(this.website) {
    assert(website != null);
  }
  @override
  _BacklogState createState() => _BacklogState(website);
}

class _BacklogState extends State<Backlog> {
  //? Initializes the data set
  final String website;
  _BacklogState(this.website);
  //? The Debouncer (class created in the main file) is now instantiated here so the search is delayed until the user stops typing.
  Debouncer debounce = Debouncer(milliseconds: 1000);
  //? Another debouncer to close the menus after 20 seconds
  Debouncer menuCloser = Debouncer(milliseconds: 15000);

  List searchQuery = [];

  //? These are the overall backlog settings.
  Map backlogSettings = settings.get('backlogSettings') ??
      {
        'psv': true,
        'ps3': true,
        'ps4': true,
        'ps5': true,
        'sorting': "alphabeticalAscending",
        'gamerCard': "grid",
      };

  Map openMenus = {
    //? Options menu
    'search': false,
    'togglePlatforms': false,
    'sort': false,
    'display': false
  };

  //? These integers will store how many games were filtered and how many are being displayed currently.
  int _displayedGames = 0;

  @override
  Widget build(BuildContext context) {
    Map profile = settings.get('${website}Dump');
    List gamesList = settings
        .get('${website}Games')
        .where((i) => i['gamePercentage'] == 0)
        .toList();
    Map backlogger = settings.get('backlog') ??
        {
          'psnProfiles': {},
          'psnTrophyLeaders': {},
          'exophase': {},
          'trueTrophies': {},
          'psn100': {}
        };
    backlogger[website].forEach((k, v) {
      gamesList.add(v);
    });

    Widget fetchExophaseGames() {
      List<Widget> cardAndGames = [];

      //? Resets the integers to store the updated numbers
      _displayedGames = 0;

      //? Alphabetical sorting in ascending manner (A games before Z games).
      if (backlogSettings['sorting'] == "alphabeticalAscending") {
        gamesList.sort((a, b) => (a['gameName'] ?? "")
            .toLowerCase()
            .compareTo((b['gameName'] ?? "").toLowerCase()));
      }
      //? Alphabetical sorting in descending manner (Z games before A games).
      else if (backlogSettings['sorting'] == "alphabeticalDescending") {
        gamesList.sort((a, b) => (b['gameName'] ?? "")
            .toLowerCase()
            .compareTo((a['gameName'] ?? "").toLowerCase()));
      }
      //? EXP sorting in ascending manner (low EXP games before high EXP games).
      else if (backlogSettings['sorting'] == "expAscending") {
        gamesList
            .sort((a, b) => (a['gameEXP'] ?? 0) > (b['gameEXP'] ?? 0) ? 1 : -1);
      }
      //? EXP sorting in descending manner (high EXP games before low EXP games).
      else if (backlogSettings['sorting'] == "expDescending") {
        gamesList
            .sort((a, b) => (a['gameEXP'] ?? 0) < (b['gameEXP'] ?? 0) ? 1 : -1);
      }

      //? Block display with vertically ordered name, image, platform, last trophy date, exp/trophy ratio/time tracked, trophy distribution
      if (backlogSettings['gamerCard'] == "block") {
        for (var i = 0; i < gamesList.length; i++) {
          //? This will filter out games based on meeting the search criteria
          if (searchQuery.length > 0) {
            int o = 0;
            searchQuery.forEach((searchWord) {
              if (gamesList[i]['gameName'].toLowerCase().contains(searchWord)) {
                o++;
              }
            });
            if (o != searchQuery.length) {
              continue;
            }
          }

          int shouldDisplay = 0;
          if (backlogSettings['ps4'] == true &&
              gamesList[i]['gamePS4'] == true) {
            shouldDisplay++;
          }
          if (backlogSettings['ps3'] == true &&
              gamesList[i]['gamePS3'] == true) {
            shouldDisplay++;
          }
          if (backlogSettings['ps5'] == true &&
              gamesList[i]['gamePS5'] == true) {
            shouldDisplay++;
          }
          if (backlogSettings['psv'] == true &&
              gamesList[i]['gameVita'] == true) {
            shouldDisplay++;
          }
          if (shouldDisplay == 0) {
            continue;
          } else {
            _displayedGames++;
            cardAndGames.add(Container(
                //? Defines how wide each block will be. For mobile users, expect 2 blocks per line.
                //? Desktop users can have as many blocks per line as wide their monitors are.
                //? Desktop blocks will measure 290 (+ 2x5 margin = 300) each.
                width: Platform.isWindows ? 240 : 200,
                decoration: BoxDecoration(
                    color: themeSelector["primary"][settings.get("theme")]
                        .withOpacity(0.85),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    border: Border.all(
                        color: Colors.white,
                        width: Platform.isWindows ? 4 : 2.5),
                    boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)]),
                margin: EdgeInsets.all(Platform.isWindows ? 5 : 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //? Game name and image
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return TrophyList(trophyListData: gamesList[i]);
                        }),
                      ),
                      child: Column(
                        children: [
                          //? Game name
                          Padding(
                            padding: EdgeInsets.all(Platform.isWindows ? 5 : 2),
                            child: Text(gamesList[i]['gameName'],
                                style: textSelection(theme: "textLightBold"),
                                textAlign: TextAlign.center),
                          ),
                          //? Game image
                          Container(
                            width: Platform.isWindows ? 260 : 200,
                            child: CachedNetworkImage(
                              placeholder: (context, url) => loadingSelector(),
                              imageUrl: gamesList[i]['gameImage'],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                    //? Platforms
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (gamesList[i]['gameVita'] == true)
                          Image.asset(
                            img['psv'],
                            width: 40,
                          ),
                        if (gamesList[i]['gamePS3'] == true)
                          Image.asset(
                            img['ps3'],
                            width: 40,
                          ),
                        if (gamesList[i]['gamePS4'] == true)
                          Image.asset(
                            img['ps4'],
                            width: 40,
                          ),
                        if (gamesList[i]['gamePS5'] == true)
                          Image.asset(
                            img['ps5'],
                            width: 40,
                          ),
                      ],
                    ),
                    //? Row with Exophase EXP, trophy earned ratio and tracked gameplay time
                    if (gamesList[i]['gameEXP'] != null &&
                        gamesList[i]['gameEXP'] > 0)
                      Padding(
                        padding: EdgeInsets.all(Platform.isWindows ? 5 : 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //? Exophase EXP system
                            Tooltip(
                              message: "EXP",
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  //? Exophase's favicon used as EXP icon since the EXP icon is
                                  //? way too transparent to be used consistently
                                  CachedNetworkImage(
                                      imageUrl:
                                          "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                      height: 15),
                                  SizedBox(width: Platform.isWindows ? 5 : 3),
                                  //? EXP earned from this game
                                  Text(
                                    gamesList[i]['gameEXP'].toString(),
                                    style: textSelection(),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    //? Backlog removal button
                    if (backlogger[website][gamesList[i]['gameLink']] != null)
                      InkWell(
                          onTap: () {
                            setState(() {
                              backlogger[website].removeWhere(
                                  (k, v) => k == gamesList[i]['gameLink']);
                            });
                            settings.put('backlog', backlogger);
                          },
                          child: Container(
                            padding: EdgeInsets.all(5),
                            margin: EdgeInsets.only(bottom: 5),
                            // decoration: boxDeco(),
                            child: Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                          ))
                  ],
                )));
          }
        }
        return Expanded(
          child: StaggeredGridView.countBuilder(
            crossAxisCount: Platform.isWindows
                ? (MediaQuery.of(context).size.width / 250).floor()
                : (MediaQuery.of(context).size.width / 150).floor(),
            staggeredTileBuilder: (index) => StaggeredTile.fit(1),
            itemCount: cardAndGames.length,
            itemBuilder: (context, index) => cardAndGames[index],
          ),
        );
      }
      //? List display with horizontally ordered image, name, platform/exp, last trophy date, trophy ratio, time tracked, trophy distribution
      else if (backlogSettings['gamerCard'] == "list") {
        for (var i = 0; i < gamesList.length; i++) {
          //? This will filter out games based on meeting the search criteria
          if (searchQuery.length > 0) {
            int o = 0;
            searchQuery.forEach((searchWord) {
              if (gamesList[i]['gameName'].toLowerCase().contains(searchWord)) {
                o++;
              }
            });
            if (o != searchQuery.length) {
              continue;
            }
          }

          int shouldDisplay = 0;
          if (backlogSettings['ps4'] == true &&
              gamesList[i]['gamePS4'] == true) {
            shouldDisplay++;
          }
          if (backlogSettings['ps3'] == true &&
              gamesList[i]['gamePS3'] == true) {
            shouldDisplay++;
          }
          if (backlogSettings['ps5'] == true &&
              gamesList[i]['gamePS5'] == true) {
            shouldDisplay++;
          }
          if (backlogSettings['psv'] == true &&
              gamesList[i]['gameVita'] == true) {
            shouldDisplay++;
          }
          if (shouldDisplay == 0) {
            continue;
          } else {
            _displayedGames++;
            cardAndGames.add(InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return TrophyList(trophyListData: gamesList[i]);
                }),
              ),
              child: Container(
                height: Platform.isWindows
                    ? 95
                    : 58, //gamesList[i]['gamePS5'] == true ? 150 : 95
                //! Already prepared the code for the other websites with larger images.
                decoration: BoxDecoration(
                    color: themeSelector["primary"][settings.get("theme")]
                        .withOpacity(0.85),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    border: Border.all(
                        color: Colors.white,
                        width: Platform.isWindows ? 4 : 2.5),
                    boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)]),
                margin: EdgeInsets.symmetric(
                    vertical: Platform.isWindows ? 5 : 2, horizontal: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //? Image with the left side corners cut to avoid overflowing through the box
                    ClipRRect(
                      borderRadius:
                          BorderRadius.horizontal(left: Radius.circular(7)),
                      child: Container(
                        width: Platform.isWindows ? 160 : 100,
                        child: CachedNetworkImage(
                          placeholder: (context, url) => loadingSelector(),
                          imageUrl: gamesList[i]['gameImage'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    //? Spacing to separate the text/platforms/points from the image
                    SizedBox(width: Platform.isWindows ? 10 : 5),
                    //? Column with the game name, game platforms and game EXP
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //? Game name
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(gamesList[i]['gameName'],
                                  style: textSelection()),
                            ),
                            //? Game platforms and Exophase EXP
                            SizedBox(height: 1),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (gamesList[i]['gameVita'] == true)
                                    Image.asset(
                                      img['psv'],
                                      width: Platform.isWindows ? 40 : 25,
                                    ),
                                  if (gamesList[i]['gamePS3'] == true)
                                    Image.asset(
                                      img['ps3'],
                                      width: Platform.isWindows ? 40 : 25,
                                    ),
                                  if (gamesList[i]['gamePS4'] == true)
                                    Image.asset(
                                      img['ps4'],
                                      width: Platform.isWindows ? 40 : 25,
                                    ),
                                  if (gamesList[i]['gamePS5'] == true)
                                    Image.asset(
                                      img['ps5'],
                                      width: Platform.isWindows ? 40 : 25,
                                    ), //? Game points earned through Exophase's scoring
                                  SizedBox(width: Platform.isWindows ? 5 : 3),

                                  if (gamesList[i]['gameEXP'] != null &&
                                      gamesList[i]['gameEXP'] > 0)
                                    Tooltip(
                                      message: "EXP",
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          //? Exophase's favicon used as EXP icon since the EXP icon is
                                          //? way too transparent to be used consistently
                                          CachedNetworkImage(
                                              placeholder: (context, url) =>
                                                  loadingSelector(),
                                              imageUrl:
                                                  "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                              height:
                                                  Platform.isWindows ? 15 : 10),
                                          SizedBox(
                                              width:
                                                  Platform.isWindows ? 5 : 3),
                                          //? EXP earned from this game
                                          Text(
                                            gamesList[i]['gameEXP'].toString(),
                                            style: textSelection(),
                                          )
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ), //? Backlog removal button
                    if (backlogger[website][gamesList[i]['gameLink']] != null)
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: InkWell(
                            onTap: () {
                              setState(() {
                                backlogger[website].removeWhere(
                                    (k, v) => k == gamesList[i]['gameLink']);
                              });
                              settings.put('backlog', backlogger);
                            },
                            child: Container(
                              padding: EdgeInsets.all(5),
                              margin: EdgeInsets.only(bottom: 5),
                              // decoration: boxDeco(),
                              child: Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                            )),
                      )
                  ],
                ),
              ),
            ));
          }
        }
        return Expanded(
          child: ListView.builder(
            itemCount: cardAndGames.length,
            itemBuilder: (context, index) => cardAndGames[index],
          ),
        );
      }
      //? Grid display
      for (var i = 0; i < gamesList.length; i++) {
        //? This will filter out games based on meeting the search criteria
        if (searchQuery.length > 0) {
          int o = 0;
          searchQuery.forEach((searchWord) {
            if (gamesList[i]['gameName'].toLowerCase().contains(searchWord)) {
              o++;
            }
          });
          if (o != searchQuery.length) {
            continue;
          }
        }

        int shouldDisplay = 0;
        if (backlogSettings['ps4'] == true && gamesList[i]['gamePS4'] == true) {
          shouldDisplay++;
        }
        if (backlogSettings['ps3'] == true && gamesList[i]['gamePS3'] == true) {
          shouldDisplay++;
        }
        if (backlogSettings['ps5'] == true && gamesList[i]['gamePS5'] == true) {
          shouldDisplay++;
        }
        if (backlogSettings['psv'] == true &&
            gamesList[i]['gameVita'] == true) {
          shouldDisplay++;
        }
        if (shouldDisplay == 0) {
          continue;
        } else {
          _displayedGames++;
          cardAndGames.add(InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return TrophyList(trophyListData: gamesList[i]);
              }),
            ),
            child: Container(
              decoration: BoxDecoration(
                  color: themeSelector["primary"][settings.get("theme")]
                      .withOpacity(0.85),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  border: Border.all(
                      color: Colors.white,
                      width: Platform.isWindows ? 4.0 : 3.0),
                  boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)]),
              margin: EdgeInsets.all(Platform.isWindows ? 5.0 : 3.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Tooltip(
                    message: gamesList[i]['gameName'],
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(7)),
                      child: Container(
                        width: Platform.isWindows
                            ? 260
                            : (MediaQuery.of(context).size.width - 20) / 2,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: CachedNetworkImage(
                            filterQuality: FilterQuality.high,
                            placeholder: (context, url) => loadingSelector(),
                            imageUrl: gamesList[i]['gameImage'],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (gamesList[i]['gameVita'] == true)
                        Image.asset(
                          img['psv'],
                          width: Platform.isWindows ? 35 : 25,
                        ),
                      if (gamesList[i]['gamePS3'] == true)
                        Image.asset(
                          img['ps3'],
                          width: Platform.isWindows ? 35 : 25,
                        ),
                      if (gamesList[i]['gamePS4'] == true)
                        Image.asset(
                          img['ps4'],
                          width: Platform.isWindows ? 35 : 25,
                        ),
                      if (gamesList[i]['gamePS5'] == true)
                        Image.asset(
                          img['ps5'],
                          width: Platform.isWindows ? 35 : 25,
                        )
                    ],
                  ),
                ],
              ),
            ),
          ));
        }
      }
      return Expanded(
        child: Container(
          child: StaggeredGridView.countBuilder(
            crossAxisCount: Platform.isWindows
                ? (MediaQuery.of(context).size.width / 150).floor()
                : (MediaQuery.of(context).size.width / 100).floor(),
            staggeredTileBuilder: (index) => StaggeredTile.fit(1),
            itemCount: cardAndGames.length,
            itemBuilder: (context, index) => cardAndGames[index],
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: backgroundDecoration(),
          child: Column(
            children: [
              fetchExophaseGames(),
              //? This Column contains the bottom bar buttons to change settings and display options.
              Container(
                width: MediaQuery.of(context).size.width,
                color: themeSelector["primary"][settings.get("theme")],
                child: Column(
                  children: [
                    //? This Row lets you search for specific games.
                    if (openMenus['search'] == true)
                      Container(
                        padding: EdgeInsets.all(5),
                        height: Platform.isWindows ? 45 : 25,
                        width: MediaQuery.of(context).size.width / 2.5,
                        child: Center(
                          child: Container(
                            height: 20,
                            child: TextFormField(
                                decoration: InputDecoration(
                                    hintText: regionalText['games']
                                        ['searchText'],
                                    hintStyle: textSelection(),
                                    icon: Icon(Icons.search,
                                        color: themeSelector["secondary"]
                                            [settings.get("theme")],
                                        size: Platform.isWindows ? 25 : 15)),
                                textAlign: TextAlign.center,
                                autocorrect: false,
                                autofocus: Platform.isWindows ? true : false,
                                onChanged: (text) {
                                  debounce.run(() {
                                    setState(() {
                                      searchQuery = text
                                          .toLowerCase()
                                          .replaceAll(":", "")
                                          .split(" ");
                                    });
                                  });
                                }),
                          ),
                        ),
                      ),
                    //? This Row lets you filter in and out specific consoles.
                    if (openMenus['togglePlatforms'] == true)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: Platform.isWindows ? 45 : 25),
                          Text(
                            regionalText['games']['togglePlatforms'],
                            style: textSelection(),
                            textAlign: TextAlign.center,
                          ),
                          //? Filter out PS Vita games
                          Tooltip(
                            message: regionalText['games']['psv'],
                            child: InkWell(
                                child: Container(
                                    height: Platform.isWindows ? 40 : 25,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: backlogSettings['psv'] != true
                                              ? Colors.red
                                              : Colors.green,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Image.asset(img['psv'],
                                        width: Platform.isWindows ? 40 : 20)),
                                onTap: () {
                                  setState(() {
                                    if (backlogSettings['psv'] != true) {
                                      backlogSettings['psv'] = true;
                                    } else {
                                      backlogSettings['psv'] = false;
                                    }
                                    settings.put(
                                        'backlogSettings', backlogSettings);
                                  });
                                }),
                          ),
                          //? Filter out PS3 games
                          Tooltip(
                            message: regionalText['games']['ps3'],
                            child: InkWell(
                                child: Container(
                                    height: Platform.isWindows ? 40 : 25,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: backlogSettings['ps3'] != true
                                              ? Colors.red
                                              : Colors.green,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Image.asset(img['ps3'],
                                        width: Platform.isWindows ? 40 : 20)),
                                onTap: () {
                                  setState(() {
                                    if (backlogSettings['ps3'] != true) {
                                      backlogSettings['ps3'] = true;
                                    } else {
                                      backlogSettings['ps3'] = false;
                                    }
                                    settings.put(
                                        'backlogSettings', backlogSettings);
                                  });
                                }),
                          ),
                          //? Filter out PS4 games
                          Tooltip(
                            message: regionalText['games']['ps4'],
                            child: InkWell(
                                child: Container(
                                    height: Platform.isWindows ? 40 : 25,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: backlogSettings['ps4'] != true
                                              ? Colors.red
                                              : Colors.green,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Image.asset(img['ps4'],
                                        width: Platform.isWindows ? 40 : 20)),
                                onTap: () {
                                  setState(() {
                                    if (backlogSettings['ps4'] != true) {
                                      backlogSettings['ps4'] = true;
                                    } else {
                                      backlogSettings['ps4'] = false;
                                    }
                                    settings.put(
                                        'backlogSettings', backlogSettings);
                                  });
                                }),
                          ),
                          //? Filter out PS5 games
                          Tooltip(
                            message: regionalText['games']['ps5'],
                            child: InkWell(
                                child: Container(
                                    height: Platform.isWindows ? 40 : 25,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: backlogSettings['ps5'] != true
                                              ? Colors.red
                                              : Colors.green,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Image.asset(img['ps5'],
                                        width: Platform.isWindows ? 40 : 20)),
                                onTap: () {
                                  setState(() {
                                    if (backlogSettings['ps5'] != true) {
                                      backlogSettings['ps5'] = true;
                                    } else {
                                      backlogSettings['ps5'] = false;
                                    }
                                    settings.put(
                                        'backlogSettings', backlogSettings);
                                  });
                                }),
                          ),
                        ],
                      ),
                    //? This Row lets you sort games in different orders.
                    if (openMenus['sort'] == true)
                      Container(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: Platform.isWindows ? 45 : 25),
                              Center(
                                child: Text(
                                  regionalText['games']['sort'],
                                  style: textSelection(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 3),
                                  //? Sort games by Alphabetical (A to Z or Z to A)
                                  Tooltip(
                                    message: backlogSettings['sorting'] ==
                                            "alphabeticalDescending"
                                        ? regionalText['games']
                                            ['alphabeticalDescending']
                                        : regionalText['games']
                                            ['alphabeticalAscending'],
                                    child: InkWell(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: backlogSettings['sorting']
                                                      .contains('alphabetical')
                                                  ? Colors.green
                                                  : Colors.transparent,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Text(
                                          backlogSettings['sorting'] ==
                                                  "alphabeticalDescending"
                                              ? "ZYX"
                                              : "ABC",
                                          style: textSelection(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (backlogSettings['sorting'] !=
                                              "alphabeticalAscending") {
                                            backlogSettings['sorting'] =
                                                "alphabeticalAscending";
                                          } else {
                                            backlogSettings['sorting'] =
                                                "alphabeticalDescending";
                                          }
                                        });
                                        settings.put(
                                            'backlogSettings', backlogSettings);
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  //? Sort games by EXP
                                  Tooltip(
                                    message: backlogSettings['sorting'] ==
                                            "expAscending"
                                        ? regionalText['games']['expAscending']
                                        : regionalText['games']
                                            ['expDescending'],
                                    child: InkWell(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: backlogSettings['sorting']
                                                      .contains('exp')
                                                  ? Colors.green
                                                  : Colors.transparent,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Text(
                                          "EXP" +
                                              (backlogSettings['sorting'] ==
                                                      "expAscending"
                                                  ? "⬆️"
                                                  : "⬇️"),
                                          style: textSelection(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (backlogSettings['sorting'] !=
                                              "expDescending") {
                                            backlogSettings['sorting'] =
                                                "expDescending";
                                          } else {
                                            backlogSettings['sorting'] =
                                                "expAscending";
                                          }
                                        });
                                        settings.put(
                                            'backlogSettings', backlogSettings);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    //? This Row lets you change the view style for the trophy lists
                    if (openMenus['display'] == true)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: Platform.isWindows ? 45 : 25),
                          SizedBox(width: 10),
                          Text(
                            regionalText['games']['display'],
                            style: textSelection(),
                            textAlign: TextAlign.center,
                          ),
                          if (backlogSettings['gamerCard'] != "list")
                            Tooltip(
                              message: regionalText['games']['list'],
                              child: InkWell(
                                  child: Icon(Icons.list,
                                      color: themeSelector["secondary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 35 : 17),
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onTap: () {
                                    setState(() {
                                      backlogSettings['gamerCard'] = "list";
                                    });
                                    settings.put(
                                        'backlogSettings', backlogSettings);
                                  }),
                            ),
                          //? Option to use view trophy lists as a block
                          if (backlogSettings['gamerCard'] != "block")
                            Tooltip(
                              message: regionalText['games']['block'],
                              child: InkWell(
                                  child: Icon(
                                    Icons.auto_awesome_mosaic,
                                    color: themeSelector["secondary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 25 : 15,
                                  ),
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onTap: () {
                                    setState(() {
                                      backlogSettings['gamerCard'] = "block";
                                    });
                                    settings.put(
                                        'backlogSettings', backlogSettings);
                                  }),
                            ),
                          //? Option to use view trophy lists as a grid
                          if (backlogSettings['gamerCard'] != "grid")
                            Tooltip(
                              message: regionalText['games']['grid'],
                              child: InkWell(
                                  child: Icon(Icons.view_comfy,
                                      color: themeSelector["secondary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 30 : 15),
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onTap: () {
                                    setState(() {
                                      backlogSettings['gamerCard'] = "grid";
                                    });
                                    settings.put(
                                        'backlogSettings', backlogSettings);
                                  }),
                            ),
                        ],
                      ),
                    //? This row contains the toggles to display the other option rows above.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: Platform.isWindows ? 45 : 25),
                        Text(
                          regionalText['games']['options'],
                          style: textSelection(),
                          textAlign: TextAlign.center,
                        ),
                        //? Search
                        Tooltip(
                          message: regionalText['games']['search'],
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color: openMenus['search'] != true
                                          ? Colors.transparent
                                          : Colors.green,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Icon(Icons.search,
                                    color: themeSelector["secondary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 30 : 17),
                              ),
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () {
                                setState(() {
                                  if (openMenus['search'] != true) {
                                    openMenus['search'] = true;
                                  } else {
                                    openMenus['search'] = false;
                                    searchQuery = [];
                                  }
                                });
                              }),
                        ),
                        //? Toggle consoles
                        Tooltip(
                          message: regionalText['games']['togglePlatforms'],
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color:
                                          openMenus['togglePlatforms'] != true
                                              ? Colors.transparent
                                              : Colors.green,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Icon(Icons.sports_esports,
                                    color: themeSelector["secondary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 30 : 17),
                              ),
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () {
                                setState(() {
                                  if (openMenus['togglePlatforms'] != true) {
                                    openMenus['togglePlatforms'] = true;
                                    openMenus['sort'] = false;
                                    openMenus['display'] = false;
                                  } else {
                                    openMenus['togglePlatforms'] = false;
                                  }
                                });
                                menuCloser.run(() {
                                  if (mounted &&
                                      openMenus['togglePlatforms'] == true) {
                                    setState(() {
                                      openMenus['togglePlatforms'] = false;
                                    });
                                  }
                                });
                              }),
                        ),
                        //? Sorting
                        Tooltip(
                          message: regionalText['games']['sort'],
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color: openMenus['sort'] != true
                                          ? Colors.transparent
                                          : Colors.green,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Icon(Icons.sort_by_alpha,
                                    color: themeSelector["secondary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 30 : 17),
                              ),
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () {
                                setState(() {
                                  if (openMenus['sort'] != true) {
                                    openMenus['togglePlatforms'] = false;
                                    openMenus['sort'] = true;
                                    openMenus['display'] = false;
                                  } else {
                                    openMenus['sort'] = false;
                                  }
                                });
                                menuCloser.run(() {
                                  if (mounted && openMenus['sort'] == true) {
                                    setState(() {
                                      openMenus['sort'] = false;
                                    });
                                  }
                                });
                              }),
                        ),
                        //? Display
                        Tooltip(
                          message: regionalText['games']['display'],
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color: openMenus['display'] != true
                                          ? Colors.transparent
                                          : Colors.green,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Icon(
                                    openMenus['gamerCard'] == "list"
                                        ? Icons.list
                                        : openMenus['gamerCard'] == "block"
                                            ? Icons.auto_awesome_mosaic
                                            : Icons.view_comfy,
                                    color: themeSelector["secondary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 30 : 17),
                              ),
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () {
                                setState(() {
                                  if (openMenus['display'] != true) {
                                    openMenus['togglePlatforms'] = false;
                                    openMenus['sort'] = false;
                                    openMenus['display'] = true;
                                  } else {
                                    openMenus['display'] = false;
                                  }
                                });
                                menuCloser.run(() {
                                  if (mounted && openMenus['display'] == true) {
                                    setState(() {
                                      openMenus['display'] = false;
                                    });
                                  }
                                });
                              }),
                        ),
                        SizedBox(width: 5),
                        //? Reset settings button
                        Tooltip(
                          message: regionalText['home']['undo'],
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                backlogSettings = {
                                  'psv': true,
                                  'ps3': true,
                                  'ps4': true,
                                  'ps5': true,
                                  'sorting': "alphabeticalAscending",
                                  'gamerCard': backlogSettings['gamerCard'],
                                };
                                openMenus = {
                                  'search': false,
                                  'togglePlatforms': false,
                                  'sort': false,
                                  'display': false
                                };
                                searchQuery = [];
                              });
                              settings.put('backlogSettings', backlogSettings);
                            },
                            child: Container(
                              child: Icon(Icons.undo,
                                  color: themeSelector["secondary"]
                                      [settings.get("theme")],
                                  size: Platform.isWindows ? 30 : 17),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        appBar: AppBar(
          titleSpacing: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 40,
          centerTitle: true,
          backgroundColor: themeSelector["primary"][settings.get("theme")],
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                //? PSN Avatar
                CachedNetworkImage(
                  imageUrl: profile['avatar'] ??
                      "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                  height: 35,
                ),
                //? PSN ID
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    regionalText['backlog']['title']
                            .replaceAll("PSNID", settings.get('psnID')) +
                        " (",
                    style: textSelection(theme: "textLightBold"),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: regionalText["games"]["filteredGames"],
                      child: Row(
                        children: [
                          Icon(Icons.sports_esports,
                              color: themeSelector["secondary"]
                                  [settings.get("theme")],
                              size: Platform.isWindows ? 25 : 15),
                          Text(
                            " ${_displayedGames.toString()} )",
                            style: textSelection(theme: 'textLightBold'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          leading:
              //? Back arrow to return to main menu
              InkWell(
            enableFeedback: false,
            child: Icon(
              Icons.arrow_back,
              color: themeSelector["secondary"][settings.get("theme")],
            ),
            onTap: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}

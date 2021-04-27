import 'dart:convert';
import 'dart:io' show Platform;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yura_trophy/trophy_list.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class GameSearch extends StatefulWidget {
  final String website;

  GameSearch(this.website) {
    assert(website != null);
  }
  @override
  _GameSearchState createState() => _GameSearchState(website);
}

class _GameSearchState extends State<GameSearch> {
  //? This bool will store the status of the update and disable the FloatingActionButton from rendering
  bool isUpdating = true;

  //? Initializes the data set
  final String website;
  _GameSearchState(this.website);

  //? The Debouncer (class created in the main file) is now instantiated here so the search is delayed until the user stops typing.
  Debouncer debounce = Debouncer(milliseconds: 1000);
  //? Another debouncer to close the menus after 20 seconds
  Debouncer menuCloser = Debouncer(milliseconds: 15000);

  List searchQuery = [];

  //? These are the overall profile settings. They will become overall settings now (as of January 20th, 2021)
  //? doing basic work to port it over to a general location to be used on every other website later.
  Map gameSearchSettings = settings.get('gameSearchSettings') ??
      {
        'psv': true,
        'ps3': true,
        'ps4': true,
        'ps5': true,
        'notPSN': false,
        'sorting': "alphabeticalAscending",
        'gamerCard': "block",
      };
  Map openMenus = {'togglePlatforms': false, 'sort': false, 'display': false};

  //? Backlog Map
  Map backlogger = (settings.get('backlog') ??
      {
        'psnProfiles': {},
        'psnTrophyLeaders': {},
        'exophase': {},
        'trueTrophies': {},
        'psn100': {}
      });

  //? Counter for games being displayed on screen
  int _displayedGames = 0;
  //? Content collector for data
  Map<String, dynamic> gameSearchData = {};

  //? Load a webpage, parse it as a string and then computes the result and returns a map
  Future<Map<String, dynamic>> requestWebsite(List<String> query) async {
    isUpdating = true;
    //? Initializes the String variable
    // String parsedHTML;

    //? Checks if the requested page is from Exophase
    if (website == 'exophase') {
      //? Loads the english/default webpage
      await ws.loadFullURL(
          "https://api.exophase.com/public/archive/games?q=${query.join(" ").replaceAll(" ", "+")}&sort=added");

      List request = json.decode(ws.getPageContent())['games']['list'];
      Map<String, dynamic> finalData = {};
      request.forEach((element) {
        finalData.addAll({
          element['endpoint_awards']: {
            'gameLink': element['endpoint_awards'],
            'gamePercentage': 0,
            'gameImage': element['images']['o'],
            'gameEXP': element['total_exp'],
            'gameID': element['master_id'],
            'gameName': element['title'],
            'gameOwners': element['global_players'],
            'gameRatio': element['total_awards'],
            'gamePoints': element['total_points']
          }
        });
        if (element['environment_slug'] == 'psn') {
          finalData[element['endpoint_awards']]['psn'] = true;
          if (element['platforms'] is List) {
            finalData[element['endpoint_awards']][
                    'game${element['platforms'][0]['name'].replaceAll("PS ", "")}'] =
                true;
          } else {
            element['platforms'].forEach((k, v) {
              finalData[element['endpoint_awards']]
                  ['game${v['name'].replaceAll("PS ", "")}'] = true;
            });
          }
        } else {
          finalData[element['endpoint_awards']]['gameSystem'] = [];
          if (element['platforms'] is List) {
            finalData[element['endpoint_awards']]
                ['gameSystem'] = [element['platforms'][0]['name']];
          } else {
            element['platforms'].forEach((k, v) {
              finalData[element['endpoint_awards']]['gameSystem']
                  .add(v['name']);
            });
          }
        }
      });
      setState(() {
        gameSearchData = finalData;

        isUpdating = false;
      });

      return finalData;
    } else {
      throw Error;
    }
  }

  //? Parses trophy list data and returns the trophy list in the proper display mode.
  Widget gameSearchDisplay() {
    //? Returns the properly formatted list/grid of items to be displayed
    Widget listDisplay;

    //? Stores and organizes all trophies to be displayed inside listDisplay
    List gamesArray = [];

    //? Transforms the Map into a List for the sort functions.
    gameSearchData.forEach((k, v) {
      gamesArray.add(v);
    });

    //? Stores how many trophies are currently being displayed using the filters applied
    _displayedGames = 0;

    //? Stores all the trophy widgets, being them in a List or Grid.
    List<Widget> gamesWidgets = [];

    //? Alphabetical sorting in ascending manner (A games before Z games).
    if (gameSearchSettings['sorting'] == "alphabeticalAscending") {
      gamesArray.sort((a, b) => (a['gameName'] ?? "")
          .toLowerCase()
          .compareTo((b['gameName'] ?? "").toLowerCase()));
    }
    //? Alphabetical sorting in descending manner (Z trophies before A games).
    else if (gameSearchSettings['sorting'] == "alphabeticalDescending") {
      gamesArray.sort((a, b) => (b['gameName'] ?? "")
          .toLowerCase()
          .compareTo((a['gameName'] ?? "").toLowerCase()));
    }
    //? EXP sorting in ascending manner (low EXP games before high EXP games).
    else if (gameSearchSettings['sorting'] == "expAscending") {
      gamesArray
          .sort((a, b) => (a['gameEXP'] ?? 0) > (b['gameEXP'] ?? 0) ? 1 : -1);
    }
    //? EXP sorting in descending manner (high EXP games before low EXP games).
    else if (gameSearchSettings['sorting'] == "expDescending") {
      gamesArray
          .sort((a, b) => (a['gameEXP'] ?? 0) < (b['gameEXP'] ?? 0) ? 1 : -1);
    }
    //? Ratio sorting in ascending manner (low ratio games before high ratio games).
    else if (gameSearchSettings['sorting'] == "ratioAscending") {
      gamesArray.sort(
          (a, b) => (a['gameRatio'] ?? 0) > (b['gameRatio'] ?? 0) ? 1 : -1);
    }
    //? Ratio sorting in descending manner (high ratio games before low ratio games).
    else if (gameSearchSettings['sorting'] == "ratioDescending") {
      gamesArray.sort(
          (a, b) => (a['gameRatio'] ?? 0) < (b['gameRatio'] ?? 0) ? 1 : -1);
    }
    //? Player count sorting in ascending manner (low player count games before high player count games).
    else if (gameSearchSettings['sorting'] == "playerAscending") {
      gamesArray.sort(
          (a, b) => (a['gameOwners'] ?? 0) > (b['gameOwners'] ?? 0) ? 1 : -1);
    }
    //? Player count sorting in descending manner (high player count games before low player count games).
    else if (gameSearchSettings['sorting'] == "playerDescending") {
      gamesArray.sort(
          (a, b) => (a['gameOwners'] ?? 0) < (b['gameOwners'] ?? 0) ? 1 : -1);
    }
    //? Points total sorting in ascending manner (low points games before high points games).
    else if (gameSearchSettings['sorting'] == "pointsAscending") {
      gamesArray.sort(
          (a, b) => (a['gamePoints'] ?? 0) > (b['gamePoints'] ?? 0) ? 1 : -1);
    }
    //? Points total sorting in descending manner (high points games before low points games).
    else if (gameSearchSettings['sorting'] == "pointsDescending") {
      gamesArray.sort(
          (a, b) => (a['gamePoints'] ?? 0) < (b['gamePoints'] ?? 0) ? 1 : -1);
    }

    for (var i = 0; i < gamesArray.length; i++) {
      int shouldDisplay = 0;
      if (gameSearchSettings['ps4'] == true &&
          gamesArray[i]['gamePS4'] == true) {
        shouldDisplay++;
      }
      if (gameSearchSettings['ps3'] == true &&
          gamesArray[i]['gamePS3'] == true) {
        shouldDisplay++;
      }
      if (gameSearchSettings['ps5'] == true &&
          gamesArray[i]['gamePS5'] == true) {
        shouldDisplay++;
      }
      if (gameSearchSettings['psv'] == true &&
          gamesArray[i]['gameVita'] == true) {
        shouldDisplay++;
      }
      if (gameSearchSettings['notPSN'] != false &&
          gamesArray[i]['gameSystem'] != null) {
        shouldDisplay++;
      }
      if (shouldDisplay == 0) {
        continue;
      }

      _displayedGames++;
      InkWell gameDisplay;

      //? Block display with vertically ordered name, image, platform, last trophy date, exp/trophy ratio/time tracked, trophy distribution
      if (gameSearchSettings['gamerCard'] == "block") {
        gameDisplay = InkWell(
          onTap: () async {
            if (gamesArray[i]['gameSystem'] == null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return TrophyList(trophyListData: gamesArray[i]);
                }),
              );
            } else {
              if (await canLaunch(gamesArray[i]['gameLink'])) {
                launch(gamesArray[i]['gameLink']);
              }
            }
          },
          child: Container(
            //? Defines how wide each block will be. For mobile users, expect 2 blocks per line.
            //? Desktop users can have as many blocks per line as wide their monitors are.
            //? Desktop blocks will measure 290 (+ 2x5 margin = 300) each.
            width: Platform.isWindows ? 240 : 200,
            decoration: BoxDecoration(
                color: themeSelector["primary"][settings.get("theme")]
                    .withOpacity(0.85),
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border.all(
                    color:
                        backlogger[website][gamesArray[i]['gameLink']] == null
                            ? Colors.white
                            : themeSelector["primary"][settings.get("theme")],
                    width: Platform.isWindows ? 4 : 2.5),
                boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)]),
            margin: EdgeInsets.symmetric(
                vertical: Platform.isWindows ? 5 : 2,
                horizontal: Platform.isWindows ? 5 : 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //? Game name
                Padding(
                  padding: EdgeInsets.all(Platform.isWindows ? 5 : 2),
                  child: Text(gamesArray[i]['gameName'],
                      style: textSelection(theme: "textLightBold"),
                      textAlign: TextAlign.center),
                ),
                //? Game image
                Container(
                  width: Platform.isWindows ? 260 : 200,
                  child: CachedNetworkImage(
                    placeholder: (context, url) => loadingSelector(),
                    imageUrl: gamesArray[i]['gameImage'],
                    fit: BoxFit.cover,
                  ),
                ),
                //? Spacing to separate the text/platforms/points from the image
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (gamesArray[i]['gameVita'] == true)
                      Image.asset(
                        img['psv'],
                        width: 40,
                      ),
                    if (gamesArray[i]['gamePS3'] == true)
                      Image.asset(
                        img['ps3'],
                        width: 40,
                      ),
                    if (gamesArray[i]['gamePS4'] == true)
                      Image.asset(
                        img['ps4'],
                        width: 40,
                      ),
                    if (gamesArray[i]['gamePS5'] == true)
                      Image.asset(
                        img['ps5'],
                        width: 40,
                      ),
                    if (gamesArray[i]['gameSystem'] != null)
                      Padding(
                        padding: const EdgeInsets.all(3),
                        child: Text(
                          gamesArray[i]['gameSystem'][0],
                          style: textSelection(theme: "textLight"),
                        ),
                      )
                  ],
                ),
                Divider(
                  color: themeSelector['secondary'][settings.get('theme')],
                  thickness: 3,
                  height: 10,
                ),
                //? General information for this game
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    children: [
                      //? Player count and points
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          //? Players tracked for this game
                          Tooltip(
                            message: regionalText['gameSearch']['players'],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.group_sharp,
                                    color: themeSelector["secondary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 25 : 15),
                                SizedBox(width: 3),
                                Text(
                                  gamesArray[i]['gameOwners'].toString() ?? "0",
                                  style: textSelection(theme: "textLight"),
                                ),
                              ],
                            ),
                          ),
                          //? Points for this game
                          Tooltip(
                            message: regionalText['gameSearch']['points'],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bar_chart,
                                    color: themeSelector["secondary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 25 : 15),
                                SizedBox(width: 3),
                                Text(
                                  gamesArray[i]['gamePoints'].toString() ?? "0",
                                  style: textSelection(theme: "textLight"),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      //? Number of unlockables and EXP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          //? Achievements for this game
                          Tooltip(
                            message: regionalText['gameSearch'][
                                gamesArray[i]['gameSystem'] == null
                                    ? 'trophies'
                                    : 'achievements'],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (gamesArray[i]['gameSystem'] != null)
                                  Icon(Icons.military_tech,
                                      color: themeSelector["secondary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 25 : 15),
                                if (gamesArray[i]['gameSystem'] == null)
                                  trophyType('total', tooltip: false),
                                SizedBox(width: 3),
                                Text(
                                  gamesArray[i]['gameRatio'].toString(),
                                  style: textSelection(theme: "textLight"),
                                ),
                              ],
                            ),
                          ),
                          //? EXP for this game
                          if (website == 'exophase')
                            Tooltip(
                              message: "EXP",
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CachedNetworkImage(
                                      imageUrl:
                                          "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                      height: 15),
                                  SizedBox(width: 3),
                                  Text(
                                    gamesArray[i]['gameEXP'].toString() ?? "0",
                                    style: textSelection(theme: "textLight"),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                //? Backlog button
                InkWell(
                    onTap: () {
                      if (backlogger[website][gamesArray[i]['gameLink']] ==
                          null) {
                        setState(() {
                          backlogger[website][gamesArray[i]['gameLink']] =
                              gamesArray[i];
                        });
                      } else {
                        setState(() {
                          backlogger[website].removeWhere(
                              (k, v) => k == gamesArray[i]['gameLink']);
                        });
                      }
                      settings.put('backlog', backlogger);
                    },
                    child: Container(
                      padding: EdgeInsets.all(5),
                      margin: EdgeInsets.only(bottom: 5),
                      decoration: boxDeco(),
                      child: Text(
                        regionalText['games']['backlog'] + "?",
                        style: textSelection(),
                      ),
                    ))
              ],
            ),
          ),
        );
      }
      //? List display with horizontally ordered image, name, platform/exp, last trophy date, trophy ratio, time tracked, trophy distribution
      else if (gameSearchSettings['gamerCard'] == "list") {
        gameDisplay = InkWell(
          onTap: () async {
            if (gamesArray[i]['gameSystem'] == null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return TrophyList(trophyListData: gamesArray[i]);
                }),
              );
            } else {
              if (await canLaunch(gamesArray[i]['gameLink'])) {
                launch(gamesArray[i]['gameLink']);
              }
            }
          },
          child: Container(
            height: Platform.isWindows ? 95 : 58,
            decoration: BoxDecoration(
                color: themeSelector["primary"][settings.get("theme")]
                    .withOpacity(0.85),
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border.all(
                    color:
                        backlogger[website][gamesArray[i]['gameLink']] == null
                            ? Colors.white
                            : themeSelector["primary"][settings.get("theme")],
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
                      imageUrl: gamesArray[i]['gameImage'],
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
                          child: Text(gamesArray[i]['gameName'],
                              style: textSelection()),
                        ),
                        //? Game platforms and Exophase EXP
                        SizedBox(height: 1),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //? Platforms, EXP and number of unlockables
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                //? Platform icons
                                if (gamesArray[i]['gameVita'] == true)
                                  Image.asset(
                                    img['psv'],
                                    width: Platform.isWindows ? 40 : 25,
                                  ),
                                if (gamesArray[i]['gamePS3'] == true)
                                  Image.asset(
                                    img['ps3'],
                                    width: Platform.isWindows ? 40 : 25,
                                  ),
                                if (gamesArray[i]['gamePS4'] == true)
                                  Image.asset(
                                    img['ps4'],
                                    width: Platform.isWindows ? 40 : 25,
                                  ),
                                if (gamesArray[i]['gamePS5'] == true)
                                  Image.asset(
                                    img['ps5'],
                                    width: Platform.isWindows ? 40 : 25,
                                  ),
                                if (gamesArray[i]['gameSystem'] != null)
                                  Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Text(gamesArray[i]['gameSystem'][0],
                                        style:
                                            textSelection(theme: "textLight"),
                                        textAlign: TextAlign.center),
                                  ),

                                SizedBox(width: 10),
                                //? EXP for this game
                                if (website == 'exophase')
                                  Tooltip(
                                    message: "EXP",
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CachedNetworkImage(
                                            imageUrl:
                                                "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                            height: 15),
                                        SizedBox(width: 3),
                                        Text(
                                          gamesArray[i]['gameEXP'].toString() ??
                                              "0",
                                          style:
                                              textSelection(theme: "textLight"),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(width: 10),
                                //? Achievements for this game
                                Tooltip(
                                  message: regionalText['gameSearch'][
                                      gamesArray[i]['gameSystem'] == null
                                          ? 'trophies'
                                          : 'achievements'],
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (gamesArray[i]['gameSystem'] != null)
                                        Icon(Icons.military_tech,
                                            color: themeSelector["secondary"]
                                                [settings.get("theme")],
                                            size: Platform.isWindows ? 25 : 15),
                                      if (gamesArray[i]['gameSystem'] == null)
                                        trophyType('total', tooltip: false),
                                      SizedBox(width: 3),
                                      Text(
                                        gamesArray[i]['gameRatio'].toString(),
                                        style:
                                            textSelection(theme: "textLight"),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            //? Player count and points
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                //? Players tracked for this game
                                Tooltip(
                                  message: regionalText['gameSearch']
                                      ['players'],
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.group_sharp,
                                          color: themeSelector["secondary"]
                                              [settings.get("theme")],
                                          size: Platform.isWindows ? 25 : 15),
                                      SizedBox(width: 3),
                                      Text(
                                        gamesArray[i]['gameOwners']
                                                .toString() ??
                                            "0",
                                        style:
                                            textSelection(theme: "textLight"),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10),
                                //? Points for this game
                                Tooltip(
                                  message: regionalText['gameSearch']['points'],
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bar_chart,
                                          color: themeSelector["secondary"]
                                              [settings.get("theme")],
                                          size: Platform.isWindows ? 25 : 15),
                                      SizedBox(width: 3),
                                      Text(
                                        gamesArray[i]['gamePoints']
                                                .toString() ??
                                            "0",
                                        style:
                                            textSelection(theme: "textLight"),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                //? Backlog button
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: InkWell(
                      onTap: () {
                        if (backlogger[website][gamesArray[i]['gameLink']] ==
                            null) {
                          setState(() {
                            backlogger[website][gamesArray[i]['gameLink']] =
                                gamesArray[i];
                          });
                        } else {
                          setState(() {
                            backlogger[website].removeWhere(
                                (k, v) => k == gamesArray[i]['gameLink']);
                          });
                        }
                        settings.put('backlog', backlogger);
                      },
                      child: Container(
                        padding: EdgeInsets.all(5),
                        margin: EdgeInsets.only(bottom: 5),
                        decoration: boxDeco(),
                        child: Text(
                          regionalText['games']['backlog'] + "?",
                          style: textSelection(),
                        ),
                      )),
                )
              ],
            ),
          ),
        );
      }
      //? Grid display with vertically ordered image, platform and trophy distribution
      else {
        //? Grid display
        gameDisplay = InkWell(
          onTap: () async {
            if (gamesArray[i]['gameSystem'] == null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return TrophyList(trophyListData: gamesArray[i]);
                }),
              );
            } else {
              if (await canLaunch(gamesArray[i]['gameLink'])) {
                launch(gamesArray[i]['gameLink']);
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
                color: themeSelector["primary"][settings.get("theme")]
                    .withOpacity(0.85),
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border.all(
                    color:
                        backlogger[website][gamesArray[i]['gameLink']] == null
                            ? Colors.white
                            : themeSelector["primary"][settings.get("theme")],
                    width: Platform.isWindows ? 4.0 : 3.0),
                boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)]),
            margin: EdgeInsets.all(Platform.isWindows ? 5.0 : 3.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Tooltip(
                  message: gamesArray[i]['gameName'],
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
                          imageUrl: gamesArray[i]['gameImage'],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (gamesArray[i]['gameVita'] == true)
                      Image.asset(
                        img['psv'],
                        width: Platform.isWindows ? 35 : 25,
                      ),
                    if (gamesArray[i]['gamePS3'] == true)
                      Image.asset(
                        img['ps3'],
                        width: Platform.isWindows ? 35 : 25,
                      ),
                    if (gamesArray[i]['gamePS4'] == true)
                      Image.asset(
                        img['ps4'],
                        width: Platform.isWindows ? 35 : 25,
                      ),
                    if (gamesArray[i]['gamePS5'] == true)
                      Image.asset(
                        img['ps5'],
                        width: Platform.isWindows ? 35 : 25,
                      ),
                    if (gamesArray[i]['gameSystem'] != null)
                      Padding(
                        padding: const EdgeInsets.all(3),
                        child: Text(gamesArray[i]['gameSystem'][0],
                            style: textSelection(theme: "textLight"),
                            textAlign: TextAlign.center),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
      gamesWidgets.add(gameDisplay);
    }

    listDisplay = Column(children: gamesWidgets);

    if (gamesWidgets.length == 0) {
    }
    //? This expanded renders the trophy data in grid-like manner, if the user opted for that
    else if (gameSearchSettings['gamerCard'] == "grid") {
      listDisplay = Container(
        child: StaggeredGridView.countBuilder(
          crossAxisCount: Platform.isWindows
              ? (MediaQuery.of(context).size.width / 150).floor()
              : (MediaQuery.of(context).size.width / 100).floor(),
          staggeredTileBuilder: (index) => StaggeredTile.fit(1),
          itemCount: gamesWidgets.length,
          itemBuilder: (context, index) => gamesWidgets[index],
        ),
      );
    }
    //? This expanded renders the trophy data like a comprehensible list, if the user opted for that
    else if (gameSearchSettings['gamerCard'] == "list") {
      listDisplay = ListView.builder(
        itemCount: gamesWidgets.length,
        itemBuilder: (context, index) => gamesWidgets[index],
      );
    }
    //? This expanded renders the trophy data in a staggered gridview, if the user opted for that
    else if (gameSearchSettings['gamerCard'] == "block") {
      listDisplay = StaggeredGridView.countBuilder(
        crossAxisCount: Platform.isWindows
            ? (MediaQuery.of(context).size.width / 250).floor()
            : (MediaQuery.of(context).size.width / 150).floor(),
        staggeredTileBuilder: (index) => StaggeredTile.fit(1),
        itemCount: gamesWidgets.length,
        itemBuilder: (context, index) => gamesWidgets[index],
      );
    }
    return listDisplay;
  }

  //? This boolean stores if the update has started or not.
  bool updateStart = false;

  //? This Map holds the trophy list data to be used to populate the page
  Map<String, dynamic> gameSearchMap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: backgroundDecoration(),
          child: Column(
            children: [
              //? This contains all trophy data, including the top banner and the trophy list.
              Container(
                child: Expanded(
                    child: //isUpdating //&&
                        gameSearchData.isEmpty
                            ? Container()
                            : gameSearchDisplay()),
              ),
              //? This Column contains the bottom bar buttons to change settings and display options.
              Container(
                width: MediaQuery.of(context).size.width,
                color: themeSelector["primary"][settings.get("theme")],
                child: Column(
                  children: [
                    //? This Row lets you search for specific games.
                    Container(
                      padding: EdgeInsets.all(5),
                      height: 35,
                      width: MediaQuery.of(context).size.width / 3,
                      child: Container(
                        child: TextFormField(
                            style: textSelection(),
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: regionalText['games']['searchText'],
                                hintStyle: textSelection(),
                                icon: Icon(Icons.search,
                                    color: themeSelector["secondary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 25 : 15)),
                            textAlign: TextAlign.center,
                            autofocus: Platform.isWindows ? true : false,
                            onChanged: (text) {
                              debounce.run(() {
                                if (text.length > 0) {
                                  searchQuery = text
                                      .toLowerCase()
                                      .replaceAll(":", "")
                                      .split(" ");
                                  requestWebsite(searchQuery);
                                }
                              });
                            }),
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
                                          color:
                                              gameSearchSettings['psv'] != true
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
                                    if (gameSearchSettings['psv'] != true) {
                                      gameSearchSettings['psv'] = true;
                                    } else {
                                      gameSearchSettings['psv'] = false;
                                    }
                                    settings.put('gameSearchSettings',
                                        gameSearchSettings);
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
                                          color:
                                              gameSearchSettings['ps3'] != true
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
                                    if (gameSearchSettings['ps3'] != true) {
                                      gameSearchSettings['ps3'] = true;
                                    } else {
                                      gameSearchSettings['ps3'] = false;
                                    }
                                    settings.put('gameSearchSettings',
                                        gameSearchSettings);
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
                                          color:
                                              gameSearchSettings['ps4'] != true
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
                                    if (gameSearchSettings['ps4'] != true) {
                                      gameSearchSettings['ps4'] = true;
                                    } else {
                                      gameSearchSettings['ps4'] = false;
                                    }
                                    settings.put('gameSearchSettings',
                                        gameSearchSettings);
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
                                          color:
                                              gameSearchSettings['ps5'] != true
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
                                    if (gameSearchSettings['ps5'] != true) {
                                      gameSearchSettings['ps5'] = true;
                                    } else {
                                      gameSearchSettings['ps5'] = false;
                                    }
                                    settings.put('gameSearchSettings',
                                        gameSearchSettings);
                                  });
                                }),
                          ),
                          //? Filter out non-Playstation games
                          if (website == 'exophase')
                            Tooltip(
                              message: regionalText['gameSearch']['notPSN'],
                              child: InkWell(
                                  child: Container(
                                    height: Platform.isWindows ? 40 : 25,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: gameSearchSettings['notPSN'] !=
                                                  true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      child:
                                          trophyType('total', tooltip: false),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (gameSearchSettings['notPSN'] !=
                                          true) {
                                        gameSearchSettings['notPSN'] = true;
                                      } else {
                                        gameSearchSettings['notPSN'] = false;
                                      }
                                      settings.put('gameSearchSettings',
                                          gameSearchSettings);
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
                              Text(
                                regionalText['games']['sort'],
                                style: textSelection(),
                                textAlign: TextAlign.center,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 3),
                                  //? Sort games by Alphabetical
                                  Tooltip(
                                    message: gameSearchSettings['sorting'] ==
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
                                              color:
                                                  gameSearchSettings['sorting']
                                                          .contains(
                                                              'alphabetical')
                                                      ? Colors.green
                                                      : Colors.transparent,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Text(
                                          gameSearchSettings['sorting'] ==
                                                  "alphabeticalDescending"
                                              ? "ZYX"
                                              : "ABC",
                                          style: textSelection(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (gameSearchSettings['sorting'] !=
                                              "alphabeticalAscending") {
                                            gameSearchSettings['sorting'] =
                                                "alphabeticalAscending";
                                          } else {
                                            gameSearchSettings['sorting'] =
                                                "alphabeticalDescending";
                                          }
                                        });
                                        settings.put('gameSearchSettings',
                                            gameSearchSettings);
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  //? Sort games by EXP
                                  Tooltip(
                                    message: gameSearchSettings['sorting'] ==
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
                                              color:
                                                  gameSearchSettings['sorting']
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
                                              (gameSearchSettings['sorting'] ==
                                                      "expAscending"
                                                  ? "⬆️"
                                                  : "⬇️"),
                                          style: textSelection(),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (gameSearchSettings['sorting'] !=
                                              "expDescending") {
                                            gameSearchSettings['sorting'] =
                                                "expDescending";
                                          } else {
                                            gameSearchSettings['sorting'] =
                                                "expAscending";
                                          }
                                        });
                                        settings.put('gameSearchSettings',
                                            gameSearchSettings);
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  //? Sort games by Player Count
                                  Tooltip(
                                    message: regionalText['gameSearch']
                                        ['sortPlayer'],
                                    child: InkWell(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color:
                                                  gameSearchSettings['sorting']
                                                          .contains('player')
                                                      ? Colors.green
                                                      : Colors.transparent,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.group,
                                                color:
                                                    themeSelector["secondary"]
                                                        [settings.get("theme")],
                                                size: Platform.isWindows
                                                    ? 22
                                                    : 17),
                                            Text(
                                              gameSearchSettings['sorting'] ==
                                                      "playerAscending"
                                                  ? "⬆️"
                                                  : "⬇️",
                                              style: textSelection(),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (gameSearchSettings['sorting'] !=
                                              "playerDescending") {
                                            gameSearchSettings['sorting'] =
                                                "playerDescending";
                                          } else {
                                            gameSearchSettings['sorting'] =
                                                "playerAscending";
                                          }
                                        });
                                        settings.put('gameSearchSettings',
                                            gameSearchSettings);
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  //? Sort games by total Unlockables
                                  Tooltip(
                                    message: regionalText['gameSearch']
                                        ['sortRatio'],
                                    child: InkWell(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color:
                                                  gameSearchSettings['sorting']
                                                          .contains('ratio')
                                                      ? Colors.green
                                                      : Colors.transparent,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Row(
                                          children: [
                                            trophyType('total', size: 'small'),
                                            Text(
                                              gameSearchSettings['sorting'] ==
                                                      "ratioAscending"
                                                  ? "⬆️"
                                                  : "⬇️",
                                              style: textSelection(),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (gameSearchSettings['sorting'] !=
                                              "ratioDescending") {
                                            gameSearchSettings['sorting'] =
                                                "ratioDescending";
                                          } else {
                                            gameSearchSettings['sorting'] =
                                                "ratioAscending";
                                          }
                                        });
                                        settings.put('gameSearchSettings',
                                            gameSearchSettings);
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  //? Sort games by Points
                                  Tooltip(
                                    message: regionalText['gameSearch']
                                        ['sortPoints'],
                                    child: InkWell(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color:
                                                  gameSearchSettings['sorting']
                                                          .contains('point')
                                                      ? Colors.green
                                                      : Colors.transparent,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.bar_chart,
                                                color:
                                                    themeSelector["secondary"]
                                                        [settings.get("theme")],
                                                size: Platform.isWindows
                                                    ? 22
                                                    : 17),
                                            Text(
                                              gameSearchSettings['sorting'] ==
                                                      "pointsAscending"
                                                  ? "⬆️"
                                                  : "⬇️",
                                              style: textSelection(),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (gameSearchSettings['sorting'] !=
                                              "pointsDescending") {
                                            gameSearchSettings['sorting'] =
                                                "pointsDescending";
                                          } else {
                                            gameSearchSettings['sorting'] =
                                                "pointsAscending";
                                          }
                                        });
                                        settings.put('gameSearchSettings',
                                            gameSearchSettings);
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
                          if (gameSearchSettings['gamerCard'] != "list")
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
                                      gameSearchSettings['gamerCard'] = "list";
                                    });
                                    settings.put('gameSearchSettings',
                                        gameSearchSettings);
                                  }),
                            ),
                          //? Option to use view trophy lists as a block
                          if (gameSearchSettings['gamerCard'] != "block")
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
                                      gameSearchSettings['gamerCard'] = "block";
                                    });
                                    settings.put('gameSearchSettings',
                                        gameSearchSettings);
                                  }),
                            ),
                          //? Option to use view trophy lists as a grid
                          if (gameSearchSettings['gamerCard'] != "grid")
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
                                      gameSearchSettings['gamerCard'] = "grid";
                                    });
                                    settings.put('gameSearchSettings',
                                        gameSearchSettings);
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
                                gameSearchSettings = {
                                  'psv': true,
                                  'ps3': true,
                                  'ps4': true,
                                  'ps5': true,
                                  'notPSN': false,
                                  'sorting': "lastPlayed",
                                  'gamerCard': gameSearchSettings['gamerCard'],
                                };
                                openMenus = {
                                  'togglePlatforms': false,
                                  'sort': false,
                                  'display': false
                                };
                                searchQuery = [];
                              });
                              settings.put(
                                  'gameSearchSettings', gameSearchSettings);
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
          leading: InkWell(
            enableFeedback: false,
            child: Icon(
              Icons.arrow_back,
              color: themeSelector["secondary"][settings.get("theme")],
            ),
            onTap: () => Navigator.pop(context),
          ),
          title: Text(
            "${regionalText['gameSearch']['appBar']}" +
                (searchQuery.isNotEmpty ? ': "${searchQuery.join(" ")}"' : "") +
                (_displayedGames == 0
                    ? ""
                    : " (${_displayedGames.toString()})"),
            style: textSelection(theme: "textLightBold"),
          ),
        ),
      ),
    );
  }
}

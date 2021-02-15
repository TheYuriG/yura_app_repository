import 'dart:io' show Platform;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:yura_trophy/trophy_list.dart';
import 'trophy_log.dart';
import 'multicolorcircle.dart';
import 'main.dart';
import 'package:flutter/material.dart';

class ExophaseProfile extends StatefulWidget {
  ExophaseProfile({Key key}) : super(key: key);
  @override
  _ExophaseProfileState createState() => _ExophaseProfileState();
}

class _ExophaseProfileState extends State<ExophaseProfile> {
  //? The Debouncer (class created in the main file) is now instantiated here so the search is delayed until the user stops typing.
  Debouncer debounce = Debouncer(milliseconds: 1000);

  List searchQuery = [];

  //? These are the overall profile settings. They will become overall settings now (as of January 20th, 2021)
  //? doing basic work to port it over to a general location to be used on every other website later.
  Map gameSettings = settings.get('exophaseSettings') ??
      settings.get('gameSettings') ??
      {
        'psv': true,
        'ps3': true,
        'ps4': true,
        'ps5': true,
        'incomplete': true,
        'complete': true,
        'zero': true,
        'timed': false,
        'mustPlatinum': false,
        'mustNotPlatinum': false,
        'sorting': "lastPlayed",
        'gamerCard': "grid",
        'search': false,
        'filter': false,
        'togglePlatforms': false,
        'sort': false,
        'display': false
      };

  @override
  Widget build(BuildContext context) {
    Map exophaseDump = settings.get('exophaseDump');
    List exophaseGamesList = settings.get('exophaseGames');

    //? These integers will store how many games were filtered and how many are being displayed currently.
    int _displayedGames = 0;
    int _filteredGames = 0;

    List<Widget> fetchExophaseGames() {
      List<Widget> cardAndGames = [];

      //? Resets the integers to store the updated numbers
      _displayedGames = 0;
      _filteredGames = 0;

      //? Last played sorting in reverse manner (older games before newer games).
      if (gameSettings['sorting'] == "lastPlayed") {
        exophaseGamesList.sort((a, b) => (a['gameLastPlayedTimestamp'] ?? 0) >
                (b['gameLastPlayedTimestamp'] ?? 0)
            ? -1
            : 1);
      }

      //? Last played sorting in reverse manner (older games before newer games).
      else if (gameSettings['sorting'] == "firstPlayed") {
        exophaseGamesList.sort((a, b) => (a['gameLastPlayedTimestamp'] ?? 0) >
                (b['gameLastPlayedTimestamp'] ?? 0)
            ? 1
            : -1);
      }

      //? Alphabetical sorting in ascending manner (A games before Z games).
      else if (gameSettings['sorting'] == "alphabeticalAscending") {
        exophaseGamesList.sort((a, b) => (a['gameName'] ?? "")
            .toLowerCase()
            .compareTo((b['gameName'] ?? "").toLowerCase()));
      }

      //? Alphabetical sorting in descending manner (Z games before A games).
      else if (gameSettings['sorting'] == "alphabeticalDescending") {
        exophaseGamesList.sort((a, b) => (b['gameName'] ?? "")
            .toLowerCase()
            .compareTo((a['gameName'] ?? "").toLowerCase()));
      }

      //? Progression sorting in ascending manner (low percentage games before high percentage games).
      else if (gameSettings['sorting'] == "completionAscending") {
        exophaseGamesList.sort((a, b) =>
            (a['gamePercentage'] ?? 0) == (b['gamePercentage'] ?? 0)
                ? (a['gameLastPlayedTimestamp'] ?? 0) >
                        (b['gameLastPlayedTimestamp'] ?? 0)
                    ? -1
                    : 1
                : (a['gamePercentage'] ?? 0) > (b['gamePercentage'] ?? 0)
                    ? 1
                    : -1);
      }

      //? Progression sorting in descending manner (high percentage games before low percentage games).
      else if (gameSettings['sorting'] == "completionDescending") {
        exophaseGamesList.sort((a, b) =>
            (a['gamePercentage'] ?? 0) == (b['gamePercentage'] ?? 0)
                ? (a['gameLastPlayedTimestamp'] ?? 0) >
                        (b['gameLastPlayedTimestamp'] ?? 0)
                    ? -1
                    : 1
                : (a['gamePercentage'] ?? 0) < (b['gamePercentage'] ?? 0)
                    ? 1
                    : -1);
      }

      //? EXP sorting in ascending manner (low EXP games before high EXP games).
      else if (gameSettings['sorting'] == "expAscending") {
        exophaseGamesList
            .sort((a, b) => (a['gameEXP'] ?? 0) > (b['gameEXP'] ?? 0) ? 1 : -1);
      }

      //? EXP sorting in descending manner (high EXP games before low EXP games).
      else if (gameSettings['sorting'] == "expDescending") {
        exophaseGamesList
            .sort((a, b) => (a['gameEXP'] ?? 0) < (b['gameEXP'] ?? 0) ? 1 : -1);
      }

      //? Tracked playtime sorting in ascending manner (low tracked playtime games before high tracked playtime games).
      else if (gameSettings['sorting'] == "timeAscending") {
        exophaseGamesList.sort((a, b) =>
            double.parse((a['gameTime'] ?? "0.0h").replaceAll('h', '')) >
                    double.parse((b['gameTime'] ?? "0.0h").replaceAll('h', ''))
                ? 1
                : -1);
      }

      //? Tracked playtime sorting in descending manner (high tracked playtime games before low tracked playtime games).
      else if (gameSettings['sorting'] == "timeDescending") {
        exophaseGamesList.sort((a, b) =>
            double.parse((a['gameTime'] ?? "0.0h").replaceAll('h', '')) <
                    double.parse((b['gameTime'] ?? "0.0h").replaceAll('h', ''))
                ? 1
                : -1);
      }

      for (var i = 0; i < exophaseGamesList.length; i++) {
        //? This will filter out games based on meeting the search criteria
        if (searchQuery.length > 0) {
          int o = 0;
          searchQuery.forEach((searchWord) {
            if (exophaseGamesList[i]['gameName']
                .toLowerCase()
                .contains(searchWord)) {
              o++;
            }
          });
          if (o != searchQuery.length) {
            _filteredGames++;
            continue;
          }
        }

        int shouldDisplay = 0;
        if (gameSettings['ps4'] == true &&
            exophaseGamesList[i]['gamePS4'] == true) {
          shouldDisplay++;
        }
        if (gameSettings['ps3'] == true &&
            exophaseGamesList[i]['gamePS3'] == true) {
          shouldDisplay++;
        }
        if (gameSettings['ps5'] == true &&
            exophaseGamesList[i]['gamePS5'] == true) {
          shouldDisplay++;
        }
        if (gameSettings['psv'] == true &&
            exophaseGamesList[i]['gameVita'] == true) {
          shouldDisplay++;
        }
        if (shouldDisplay == 0) {
          _filteredGames++;
          continue;
        } else if (gameSettings['zero'] == false &&
            exophaseGamesList[i]['gamePercentage'] == 0) {
          _filteredGames++;
          continue;
        } else if (gameSettings['incomplete'] == false &&
            exophaseGamesList[i]['gamePercentage'] < 100) {
          _filteredGames++;
          continue;
        } else if (gameSettings['complete'] == false &&
            exophaseGamesList[i]['gamePercentage'] == 100) {
          _filteredGames++;
          continue;
        } else if (gameSettings['timed'] == true &&
            exophaseGamesList[i]['gameTime'] == null) {
          _filteredGames++;
          continue;
        } else if (gameSettings['mustPlatinum'] == true &&
            exophaseGamesList[i]['gamePlatinum'] == null) {
          _filteredGames++;
          continue;
        } else if (gameSettings['mustNotPlatinum'] == true &&
            exophaseGamesList[i]['gamePlatinum'] != null) {
          _filteredGames++;
          continue;
        } else {
          _displayedGames++;
          InkWell gameDisplay;
          //? Block display with vertically ordered name, image, platform, last trophy date, exp/trophy ratio/time tracked, trophy distribution
          if (gameSettings['gamerCard'] == "block") {
            gameDisplay = InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return TrophyList(trophyListData: exophaseGamesList[i]);
                }),
              ),
              child: Container(
                  //? Defines how wide each block will be. For mobile users, expect 2 blocks per line.
                  //? Desktop users can have as many blocks per line as wide their monitors are.
                  //? Desktop blocks will measure 290 (+ 2x5 margin = 300) each.
                  width: Platform.isWindows
                      ? 240
                      : (MediaQuery.of(context).size.width - 20) / 2,
                  decoration: BoxDecoration(
                      color: themeSelector["primary"][settings.get("theme")]
                          .withOpacity(0.85),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      border: Border.all(
                          color: exophaseGamesList[i]['gamePercentage'] < 30
                              ? Colors.red
                              : exophaseGamesList[i]['gamePercentage'] == 100
                                  ? Colors.green
                                  : Colors.yellow[600],
                          width: Platform.isWindows ? 4 : 2.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black, blurRadius: 5)
                      ]),
                  margin: EdgeInsets.symmetric(
                      vertical: Platform.isWindows ? 5 : 2,
                      horizontal: Platform.isWindows ? 5 : 2),
                  padding: EdgeInsets.only(
                      top: 2,
                      bottom:
                          exophaseGamesList[i]['gamePercentage'] > 0 ? 10 : 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      //? Game name
                      Padding(
                        padding: EdgeInsets.all(Platform.isWindows ? 5 : 2),
                        child: Text(exophaseGamesList[i]['gameName'],
                            style: textSelection(theme: "textLightBold"),
                            textAlign: TextAlign.center),
                      ),
                      //? Spacing to separate the text/platforms/points from the image
                      //? Game image
                      Container(
                        width: Platform.isWindows
                            ? 260
                            : (MediaQuery.of(context).size.width - 20) / 2,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: CachedNetworkImage(
                            filterQuality: FilterQuality.high,
                            placeholder: (context, url) => loadingSelector(),
                            imageUrl: exophaseGamesList[i]['gameImage'],
                          ),
                        ),
                      ),
                      //? Spacing to separate the text/platforms/points from the image
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (exophaseGamesList[i]['gameVita'] == true)
                            Image.asset(
                              img['psv'],
                              width: 40,
                            ),
                          if (exophaseGamesList[i]['gamePS3'] == true)
                            Image.asset(
                              img['ps3'],
                              width: 40,
                            ),
                          if (exophaseGamesList[i]['gamePS4'] == true)
                            Image.asset(
                              img['ps4'],
                              width: 40,
                            ),
                          if (exophaseGamesList[i]['gamePS5'] == true)
                            Image.asset(
                              img['ps5'],
                              width: 40,
                            ),
                        ],
                      ),
                      //? Last played tracked date
                      Text(exophaseGamesList[i]['gameLastPlayed'],
                          style: textSelection()),
                      //? Row with Exophase EXP, trophy earned ratio and tracked gameplay time
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
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
                                        placeholder: (context, url) =>
                                            loadingSelector(),
                                        imageUrl:
                                            "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                        height: 20),
                                    SizedBox(width: Platform.isWindows ? 5 : 3),
                                    //? EXP earned from this game
                                    Text(
                                      exophaseGamesList[i]['gameEXP']
                                          .toString(),
                                      style: textSelection(),
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(width: Platform.isWindows ? 5 : 3),
                              //? Game trophy earned ratio
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  trophyType("total"),
                                  SizedBox(width: Platform.isWindows ? 5 : 2),
                                  Text(exophaseGamesList[i]['gameRatio'],
                                      style: textSelection()),
                                ],
                              ),
                              if (exophaseGamesList[i]['gameTime'] != null)
                                SizedBox(height: Platform.isWindows ? 3 : 2),
                              if (exophaseGamesList[i]['gameTime'] != null)
                                //? Exophase game played time tracker
                                Row(
                                  children: [
                                    Icon(
                                      Icons.hourglass_bottom,
                                      color: themeSelector["secondary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 30 : 14,
                                    ),
                                    Text(
                                      exophaseGamesList[i]['gameTime'],
                                      style: textSelection(),
                                    )
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (exophaseGamesList[i]['gamePercentage'] > 0)
                        Divider(
                            color: themeSelector['secondary']
                                [settings.get('theme')],
                            thickness: 2,
                            indent: 5,
                            endIndent: 5,
                            height: 5),
                      if (exophaseGamesList[i]['gamePercentage'] > 0)
                        SizedBox(height: 7),
                      //? Row with the trophy distribution and the multicolored circle
                      if (exophaseGamesList[i]['gamePercentage'] > 0)
                        Container(
                          height: Platform.isWindows ? 70 : 50,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              //? This contains bronze, silver, gold, platinum
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  //? First column displays platinum and silver trophies, if available
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (exophaseGamesList[i]
                                              ['gamePlatinum'] !=
                                          null)
                                        trophyType("platinum",
                                            quantity: exophaseGamesList[i]
                                                ['gamePlatinum']),
                                      SizedBox(height: 5),
                                      if (exophaseGamesList[i]['gameSilver'] !=
                                          null)
                                        trophyType("silver",
                                            quantity: exophaseGamesList[i]
                                                ['gameSilver'])
                                    ],
                                  ),
                                  //? This sized box has height to make the Columns before and after
                                  //? align their trophy icons at the bottom
                                  SizedBox(width: Platform.isWindows ? 5 : 3),
                                  //? Second column displays gold and bronze trophies, if available
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (exophaseGamesList[i]['gameGold'] !=
                                          null)
                                        trophyType("gold",
                                            quantity: exophaseGamesList[i]
                                                ['gameGold']),
                                      SizedBox(height: 5),
                                      if (exophaseGamesList[i]['gameBronze'] !=
                                          null)
                                        trophyType("bronze",
                                            quantity: exophaseGamesList[i]
                                                ['gameBronze']),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(width: 15),
                              //? This is the created MultiColorCircle class
                              MultiColorCircle(
                                //? This needs to have an unique key otherwise the filtering function
                                //? will glitch the rebuild and not display the correct percentage at the correct location.
                                key: UniqueKey(),
                                diameter: Platform.isWindows ? 55 : 40,
                                width: Platform.isWindows ? 10 : 7,
                                colors: [
                                  Colors.blue[400],
                                  Colors.yellow[600],
                                  Colors.grey[400],
                                  Colors.brown
                                ],
                                unfilled: Colors.grey.withOpacity(0.4),
                                //? This takes an array of doubles that is returned by the function below.
                                percentages: trophyPointsDistribution(
                                    exophaseGamesList[i]['gamePlatinum'] ?? 0,
                                    exophaseGamesList[i]['gameGold'] ?? 0,
                                    exophaseGamesList[i]['gameSilver'] ?? 0,
                                    exophaseGamesList[i]['gameBronze'] ?? 0,
                                    exophaseGamesList[i]['gamePercentage']),
                                centerText: Text(
                                  exophaseGamesList[i]['gamePercentage']
                                          .toString() +
                                      "%",
                                  style: textSelection(),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )),
            );
          }
          //? List display with horizontally ordered image, name, platform/exp, last trophy date, trophy ratio, time tracked, trophy distribution
          else if (gameSettings['gamerCard'] == "list") {
            gameDisplay = InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return TrophyList(trophyListData: exophaseGamesList[i]);
                }),
              ),
              child: Container(
                height: Platform.isWindows
                    ? 95
                    : 58, //exophaseGamesList[i]['gamePS5'] == true ? 150 : 95
                //! Already prepared the code for the other websites with larger images.
                decoration: BoxDecoration(
                    color: themeSelector["primary"][settings.get("theme")]
                        .withOpacity(0.85),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    border: Border.all(
                        color: exophaseGamesList[i]['gamePercentage'] < 30
                            ? Colors.red
                            : exophaseGamesList[i]['gamePercentage'] == 100
                                ? Colors.green
                                : Colors.yellow[600],
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
                        height: Platform.isWindows ? 95 : 58,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: CachedNetworkImage(
                            filterQuality: FilterQuality.high,
                            placeholder: (context, url) => loadingSelector(),
                            imageUrl: exophaseGamesList[i]['gameImage'],
                          ),
                        ),
                      ),
                    ),
                    //? Spacing to separate the text/platforms/points from the image
                    SizedBox(width: Platform.isWindows ? 10 : 5),
                    //? Column with the game name, game platforms and game EXP
                    ConstrainedBox(
                      //? This 410 is the pixel size of the items around the text
                      //? This allows the text box to expand as much as possible and then become
                      //? a single child scroll view for whatever else overflows
                      //? will work on all device sizes
                      constraints: BoxConstraints(
                        maxWidth: Platform.isWindows
                            ? MediaQuery.of(context).size.width - 410.0
                            : MediaQuery.of(context).size.width - 261.0,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: Platform.isWindows ? 8.0 : 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //? Game name
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(exophaseGamesList[i]['gameName'],
                                  style: textSelection()),
                            ),
                            //? Game platforms and Exophase EXP
                            SizedBox(height: 1),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (exophaseGamesList[i]['gameVita'] == true)
                                    Image.asset(
                                      img['psv'],
                                      width: Platform.isWindows ? 40 : 25,
                                    ),
                                  if (exophaseGamesList[i]['gamePS3'] == true)
                                    Image.asset(
                                      img['ps3'],
                                      width: Platform.isWindows ? 40 : 25,
                                    ),
                                  if (exophaseGamesList[i]['gamePS4'] == true)
                                    Image.asset(
                                      img['ps4'],
                                      width: Platform.isWindows ? 40 : 25,
                                    ),
                                  if (exophaseGamesList[i]['gamePS5'] == true)
                                    Image.asset(
                                      img['ps5'],
                                      width: Platform.isWindows ? 40 : 25,
                                    ), //? Game points earned through Exophase's scoring
                                  SizedBox(width: Platform.isWindows ? 5 : 3),
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
                                            width: Platform.isWindows ? 5 : 3),
                                        //? EXP earned from this game
                                        Text(
                                          exophaseGamesList[i]['gameEXP']
                                              .toString(),
                                          style: textSelection(),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            //? Game last played date
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                  exophaseGamesList[i]['gameLastPlayed'],
                                  style: textSelection()),
                            ),
                            // SizedBox(height: 3),
                          ],
                        ),
                      ),
                    ),
                    //? This will push every other item to the edges of the list Container
                    Expanded(child: SizedBox()),
                    //? This contains all the remaining information. Time played, trophy earned ratio
                    //? bronze, silver, gold, platinum, percentage progress
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: Platform.isWindows ? 5.0 : 3.0,
                          vertical: Platform.isWindows ? 8.0 : 5.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //? This row will align all the top information without the bottom progress bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              //? This first column organizes tracked gameplay time (if available) and trophy earned ratio
                              Container(
                                width: Platform.isWindows ? 95 : 60,
                                height: Platform.isWindows ? 60 : 37,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          trophyType("total"),
                                          SizedBox(
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          Text(
                                              exophaseGamesList[i]['gameRatio'],
                                              style: textSelection()),
                                        ],
                                      ),
                                    ),
                                    if (exophaseGamesList[i]['gameTime'] !=
                                        null)
                                      SizedBox(
                                          height: Platform.isWindows ? 3 : 2),
                                    if (exophaseGamesList[i]['gameTime'] !=
                                        null)
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.hourglass_bottom,
                                              color: themeSelector["secondary"]
                                                  [settings.get("theme")],
                                              size:
                                                  Platform.isWindows ? 30 : 14,
                                            ),
                                            Text(
                                              exophaseGamesList[i]['gameTime'],
                                              style: textSelection(),
                                            )
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(width: Platform.isWindows ? 5 : 2),
                              //? Second column displays platinum and silver trophies, if available
                              Container(
                                width: Platform.isWindows ? 56 : 35,
                                height: Platform.isWindows ? 48 : 35,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (exophaseGamesList[i]['gamePlatinum'] !=
                                        null)
                                      trophyType("platinum",
                                          quantity: exophaseGamesList[i]
                                              ['gamePlatinum'],
                                          size: "small"),
                                    SizedBox(
                                        height: Platform.isWindows ? 5 : 2),
                                    if (exophaseGamesList[i]['gameSilver'] !=
                                        null)
                                      trophyType("silver",
                                          quantity: exophaseGamesList[i]
                                              ['gameSilver'],
                                          size: "small")
                                  ],
                                ),
                              ),
                              //? Third column displays gold and bronze trophies, if available
                              Container(
                                width: Platform.isWindows ? 55 : 40,
                                height: Platform.isWindows ? 48 : 35,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (exophaseGamesList[i]['gameGold'] !=
                                        null)
                                      trophyType("gold",
                                          quantity: exophaseGamesList[i]
                                              ['gameGold'],
                                          size: "small"),
                                    SizedBox(
                                        height: Platform.isWindows ? 5 : 2),
                                    if (exophaseGamesList[i]['gameBronze'] !=
                                        null)
                                      trophyType("bronze",
                                          quantity: exophaseGamesList[i]
                                              ['gameBronze'],
                                          size: "small")
                                  ],
                                ),
                              )
                            ],
                          ),
                          // ? This row just creates a progress bar based on (gamePercentage * 2) + x = 200px
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                              child: Tooltip(
                                message: exophaseGamesList[i]['gamePercentage']
                                        .toString() +
                                    "%",
                                child: Row(
                                  children: [
                                    //? Platinum points distribution
                                    if (exophaseGamesList[i]['gamePlatinum'] !=
                                        null)
                                      Container(
                                        color: Colors.blue[400],
                                        height: Platform.isWindows ? 10 : 5,
                                        width: (Platform.isWindows ? 2 : 1.2) *
                                            trophyPointsDistribution(
                                                exophaseGamesList[i]
                                                        ['gamePlatinum'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                        ['gameGold'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                        ['gameSilver'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                        ['gameBronze'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                    ['gamePercentage'])[0],
                                      ),
                                    //? Gold points distribution
                                    if (exophaseGamesList[i]['gameGold'] !=
                                        null)
                                      Container(
                                        color: Colors.yellow[600],
                                        height: Platform.isWindows ? 10 : 5,
                                        width: (Platform.isWindows ? 2 : 1.2) *
                                            trophyPointsDistribution(
                                                exophaseGamesList[i]
                                                        ['gamePlatinum'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                        ['gameGold'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                        ['gameSilver'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                        ['gameBronze'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                    ['gamePercentage'])[1],
                                      ),
                                    //? Silver points distribution
                                    if (exophaseGamesList[i]['gameSilver'] !=
                                        null)
                                      Container(
                                        color: Colors.grey[400],
                                        height: Platform.isWindows ? 10 : 5,
                                        width: (Platform.isWindows ? 2 : 1.2) *
                                            trophyPointsDistribution(
                                                exophaseGamesList[i]
                                                        ['gamePlatinum'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                        ['gameGold'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                        ['gameSilver'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                        ['gameBronze'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                    ['gamePercentage'])[2],
                                      ),
                                    //? Bronze points distribution
                                    if (exophaseGamesList[i]['gameBronze'] !=
                                        null)
                                      Container(
                                        color: Colors.brown,
                                        height: Platform.isWindows ? 10 : 5,
                                        width: (Platform.isWindows ? 2 : 1.2) *
                                            trophyPointsDistribution(
                                                exophaseGamesList[i]
                                                        ['gamePlatinum'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                        ['gameGold'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                        ['gameSilver'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                        ['gameBronze'] ??
                                                    0,
                                                exophaseGamesList[i]
                                                    ['gamePercentage'])[3],
                                      ),
                                    Container(
                                      height: Platform.isWindows ? 10 : 5,
                                      width: (Platform.isWindows ? 2 : 1.2) *
                                          (100 -
                                                  exophaseGamesList[i]
                                                      ['gamePercentage'])
                                              .toDouble(),
                                      color: Colors.grey.withOpacity(0.7),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          //? Grid display with vertically ordered image, platform and trophy distribution
          else {
            //? Grid display
            gameDisplay = InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return TrophyList(trophyListData: exophaseGamesList[i]);
                }),
              ),
              child: Container(
                decoration: BoxDecoration(
                    color: themeSelector["primary"][settings.get("theme")]
                        .withOpacity(0.85),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    border: Border.all(
                        color: exophaseGamesList[i]['gamePercentage'] < 30
                            ? Colors.red
                            : exophaseGamesList[i]['gamePercentage'] == 100
                                ? Colors.green
                                : Colors.yellow[600],
                        width: Platform.isWindows ? 4.0 : 3.0),
                    boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)]),
                margin: EdgeInsets.all(Platform.isWindows ? 5.0 : 3.0),
                child: Tooltip(
                  message: exophaseGamesList[i]['gameName'],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ClipRRect(
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
                              imageUrl: exophaseGamesList[i]['gameImage'],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (exophaseGamesList[i]['gameVita'] == true)
                            Image.asset(
                              img['psv'],
                              width: 35,
                            ),
                          if (exophaseGamesList[i]['gamePS3'] == true)
                            Image.asset(
                              img['ps3'],
                              width: 35,
                            ),
                          if (exophaseGamesList[i]['gamePS4'] == true)
                            Image.asset(
                              img['ps4'],
                              width: 35,
                            ),
                          if (exophaseGamesList[i]['gamePS5'] == true)
                            Image.asset(
                              img['ps5'],
                              width: 35,
                            )
                        ],
                      ),
                      SizedBox(height: Platform.isWindows ? 5 : 2),
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        child: Tooltip(
                          message: exophaseGamesList[i]['gamePercentage']
                                  .toString() +
                              "%",
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              //? Platinum points distribution
                              if (exophaseGamesList[i]['gamePlatinum'] != null)
                                Container(
                                  color: Colors.blue[400],
                                  height: Platform.isWindows ? 10 : 7,
                                  width: trophyPointsDistribution(
                                      exophaseGamesList[i]['gamePlatinum'] ?? 0,
                                      exophaseGamesList[i]['gameGold'] ?? 0,
                                      exophaseGamesList[i]['gameSilver'] ?? 0,
                                      exophaseGamesList[i]['gameBronze'] ?? 0,
                                      exophaseGamesList[i]
                                          ['gamePercentage'])[0],
                                ),
                              //? Gold points distribution
                              if (exophaseGamesList[i]['gameGold'] != null)
                                Container(
                                  color: Colors.yellow[600],
                                  height: Platform.isWindows ? 10 : 7,
                                  width: trophyPointsDistribution(
                                      exophaseGamesList[i]['gamePlatinum'] ?? 0,
                                      exophaseGamesList[i]['gameGold'] ?? 0,
                                      exophaseGamesList[i]['gameSilver'] ?? 0,
                                      exophaseGamesList[i]['gameBronze'] ?? 0,
                                      exophaseGamesList[i]
                                          ['gamePercentage'])[1],
                                ),
                              //? Silver points distribution
                              if (exophaseGamesList[i]['gameSilver'] != null)
                                Container(
                                  color: Colors.grey[400],
                                  height: Platform.isWindows ? 10 : 7,
                                  width: trophyPointsDistribution(
                                      exophaseGamesList[i]['gamePlatinum'] ?? 0,
                                      exophaseGamesList[i]['gameGold'] ?? 0,
                                      exophaseGamesList[i]['gameSilver'] ?? 0,
                                      exophaseGamesList[i]['gameBronze'] ?? 0,
                                      exophaseGamesList[i]
                                          ['gamePercentage'])[2],
                                ),
                              //? Bronze points distribution
                              if (exophaseGamesList[i]['gameBronze'] != null)
                                Container(
                                  color: Colors.brown,
                                  height: Platform.isWindows ? 10 : 7,
                                  width: trophyPointsDistribution(
                                      exophaseGamesList[i]['gamePlatinum'] ?? 0,
                                      exophaseGamesList[i]['gameGold'] ?? 0,
                                      exophaseGamesList[i]['gameSilver'] ?? 0,
                                      exophaseGamesList[i]['gameBronze'] ?? 0,
                                      exophaseGamesList[i]
                                          ['gamePercentage'])[3],
                                ),
                              Container(
                                height: Platform.isWindows ? 10 : 7,
                                width: (100 -
                                        exophaseGamesList[i]['gamePercentage'])
                                    .toDouble(),
                                color: Colors.grey.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 2),
                    ],
                  ),
                ),
              ),
            );
          }
          cardAndGames.add(gameDisplay);
        }
      }
      return cardAndGames;
    }

    List<Widget> exophaseGamesWidgetList = fetchExophaseGames();

    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            // toolbarHeight: 40,
            backgroundColor: themeSelector["primary"][settings.get("theme")],
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                  // mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //? Back arrow to return to main menu
                    InkWell(
                      enableFeedback: false,
                      child: Icon(
                        Icons.arrow_back,
                        color: themeSelector["secondary"]
                            [settings.get("theme")],
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                    // Expanded(child: SizedBox()),
                    Row(
                      children: [
                        //? PSN Avatar
                        CachedNetworkImage(
                          imageUrl: exophaseDump['avatar'] ??
                              "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                          height: 35,
                        ),
                        //? PSN ID
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            exophaseDump["psnID"],
                            style: textSelection(theme: "textLightBold"),
                          ),
                        ),
                        //? Country flag
                        CachedNetworkImage(
                            imageUrl:
                                "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${exophaseDump['country']}.png",
                            height: 25),
                      ],
                    ),
                    Container(
                      height: 35,
                      child: levelType(
                          exophaseDump['platinum'],
                          exophaseDump['gold'],
                          exophaseDump['silver'],
                          exophaseDump['bronze']),
                    ),
                  ]),
            ),
          ),
          body: Container(
            decoration: backgroundDecoration(),
            child: Column(
              children: [
                //? This container contains all the trophy data related to the player
                Container(
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.symmetric(
                        vertical: Platform.isWindows ? 15 : 5),
                    color: themeSelector['primary'][settings.get('theme')]
                        .withOpacity(0.7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              child: trophyType('platinum',
                                  quantity: exophaseDump['platinum']),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return TrophyLog(trophyData: {
                                    'website': 'exophase',
                                    'log': 'earned',
                                    'type': 'platinum'
                                  });
                                }),
                              ),
                            ),
                            SizedBox(width: Platform.isWindows ? 20 : 10),
                            InkWell(
                              child: trophyType('gold',
                                  quantity: exophaseDump['gold']),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return TrophyLog(trophyData: {
                                    'website': 'exophase',
                                    'log': 'earned',
                                    'type': 'gold'
                                  });
                                }),
                              ),
                            ),
                            SizedBox(width: Platform.isWindows ? 20 : 10),
                            InkWell(
                              child: trophyType('silver',
                                  quantity: exophaseDump['silver']),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return TrophyLog(trophyData: {
                                    'website': 'exophase',
                                    'log': 'earned',
                                    'type': 'silver'
                                  });
                                }),
                              ),
                            ),
                            SizedBox(width: Platform.isWindows ? 20 : 10),
                            InkWell(
                              child: trophyType('bronze',
                                  quantity: exophaseDump['bronze']),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return TrophyLog(trophyData: {
                                    'website': 'exophase',
                                    'log': 'earned',
                                    'type': 'bronze'
                                  });
                                }),
                              ),
                            ),
                            SizedBox(width: Platform.isWindows ? 20 : 10),
                            InkWell(
                              child: trophyType('total',
                                  quantity:
                                      "${exophaseDump['total'].toString()}"),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return TrophyLog(trophyData: {
                                    'website': 'exophase',
                                    'log': 'earned',
                                    'type': 'all'
                                  });
                                }),
                              ),
                            ),
                            SizedBox(width: Platform.isWindows ? 20 : 10),
                            Tooltip(
                              message: regionalText["games"]["filteredGames"],
                              child: Text(
                                "${regionalText["home"]["games"]} ${_displayedGames.toString()}" +
                                    (_filteredGames > 0
                                        ? " (-$_filteredGames)"
                                        : ""),
                                style: textSelection(),
                              ),
                            ),
                          ],
                        ),
                        if (Platform.isWindows)
                          Divider(
                              color: themeSelector['secondary']
                                  [settings.get('theme')],
                              thickness: 3),
                        //? Bottom row without avatar, has information about games played,
                        //? completion, gameplay hours, country/world rankings, etc
                        //! Will not display if the user is on mobile
                        if (Platform.isWindows)
                          SingleChildScrollView(
                            // padding: EdgeInsets.all(0),
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["games"]}\n${exophaseDump['games'].toString()}",
                                    style: textSelection(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["complete"]}\n${exophaseDump['complete'].toString()} (${exophaseDump['completePercentage']}%)",
                                    style: textSelection(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["incomplete"]}\n${exophaseDump['incomplete'].toString()} (${exophaseDump['incompletePercentage']}%)",
                                    style: textSelection(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["completion"]}\n${exophaseDump['completion']}",
                                    style: textSelection(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (exophaseDump['hours'] != null)
                                  Tooltip(
                                    message: "PS4/PS5",
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 0, horizontal: 10.0),
                                      child: Text(
                                        "${regionalText["home"]["hours"]}\n${exophaseDump['hours']}",
                                        style: textSelection(),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["exp"]}\n${exophaseDump['exp']}",
                                    style: textSelection(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["countryRank"]}\n${exophaseDump['countryRank'] != null ? exophaseDump['countryRank'].toString() + " " : "❌"}${exophaseDump['countryUp'] ?? ""}",
                                    style: textSelection(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["worldRank"]}\n${exophaseDump['worldRank'] != null ? exophaseDump['worldRank'].toString() + " " : "❌"}${exophaseDump['worldUp'] ?? ""}",
                                    style: textSelection(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          )
                      ],
                    )),
                //? This expanded renders the trophy data in grid-like manner, if the user opted for that
                if (exophaseGamesWidgetList.length > 0 &&
                    gameSettings['gamerCard'] == "grid")
                  Expanded(
                    child: StaggeredGridView.countBuilder(
                      key: UniqueKey(),
                      crossAxisCount: Platform.isWindows
                          ? (MediaQuery.of(context).size.width / 150).floor()
                          : (MediaQuery.of(context).size.width / 100).floor(),
                      staggeredTileBuilder: (index) => StaggeredTile.fit(1),
                      itemCount: exophaseGamesWidgetList.length,
                      itemBuilder: (context, index) =>
                          exophaseGamesWidgetList[index],
                    ),
                  ),
                //? This expanded renders the trophy data like a comprehensible list, if the user opted for that
                if (exophaseGamesWidgetList.length > 0 &&
                    gameSettings['gamerCard'] == "list")
                  Expanded(
                    child: ListView.builder(
                      itemCount: exophaseGamesWidgetList.length,
                      itemBuilder: (context, index) =>
                          exophaseGamesWidgetList[index],
                    ),
                  ),
                if (exophaseGamesWidgetList.length > 0 &&
                    gameSettings['gamerCard'] == "block")
                  Expanded(
                    child: StaggeredGridView.countBuilder(
                      key: UniqueKey(),
                      crossAxisCount: Platform.isWindows
                          ? (MediaQuery.of(context).size.width / 250).floor()
                          : (MediaQuery.of(context).size.width / 150).floor(),
                      staggeredTileBuilder: (index) => StaggeredTile.fit(1),
                      itemCount: exophaseGamesWidgetList.length,
                      itemBuilder: (context, index) =>
                          exophaseGamesWidgetList[index],
                    ),
                  ),
                //? This expanded shows an image if there is no trophy data to display
                if (exophaseGamesWidgetList.length == 0)
                  Expanded(
                    child: CachedNetworkImage(
                        placeholder: (context, url) => loadingSelector(),
                        imageUrl:
                            "https://pbs.twimg.com/media/EYfO0SfXkAEA3iY.jpg",
                        width: MediaQuery.of(context).size.width),
                  ),
                //? This Column contains the bottom bar buttons to change settings and display options.
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.symmetric(
                      vertical: Platform.isWindows ? 5 : 3),
                  color: themeSelector["secondary"][settings.get("theme")],
                  child: Column(
                    children: [
                      //? This Row lets you search for specific games.
                      if (gameSettings['search'] == true)
                        Container(
                          padding: EdgeInsets.all(5),
                          height: 30,
                          width: MediaQuery.of(context).size.width / 2.5,
                          child: TextFormField(
                              decoration: InputDecoration(
                                  hintText: regionalText['games']['searchText'],
                                  hintStyle: textSelection(theme: "textDark"),
                                  icon: Icon(Icons.search,
                                      color: themeSelector["primary"]
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
                      //? This Row lets you filter in and out games under specific circumstances.
                      if (gameSettings['filter'] == true)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              regionalText['games']['filter'],
                              style: textSelection(theme: "textDark"),
                              textAlign: TextAlign.center,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                //? Filter out incomplete games and add in completed games if they were filtered
                                Tooltip(
                                  message: regionalText['games']['incomplete'],
                                  child: InkWell(
                                      child: Container(
                                          decoration: BoxDecoration(
                                            //? To paint the border, we check the value of the settings for this website is true.
                                            //? If it's false or null (never set), we will paint red.
                                            border: Border.all(
                                                color: gameSettings[
                                                            'incomplete'] !=
                                                        true
                                                    ? Colors.red
                                                    : Colors.transparent,
                                                width:
                                                    Platform.isWindows ? 5 : 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                          ),
                                          child: Icon(
                                              Icons.check_box_outline_blank,
                                              color: themeSelector["primary"]
                                                  [settings.get("theme")],
                                              size: Platform.isWindows
                                                  ? 30
                                                  : 20)),
                                      onTap: () {
                                        setState(() {
                                          if (gameSettings['incomplete'] !=
                                              true) {
                                            gameSettings['incomplete'] = true;
                                          } else {
                                            //? since complete and incomplete filters are mutually exclusive,
                                            //? activating one on must turn off the other
                                            gameSettings['incomplete'] = false;
                                            gameSettings['complete'] = true;
                                          }
                                        });
                                      }),
                                ),
                                //? Filter out complete games and add in incompleted games if they were filtered
                                Tooltip(
                                  message: regionalText['games']['complete'],
                                  child: InkWell(
                                      child: Container(
                                          decoration: BoxDecoration(
                                            //? To paint the border, we check the value of the settings for this website is true.
                                            //? If it's false or null (never set), we will paint red.
                                            border: Border.all(
                                                color:
                                                    gameSettings['complete'] !=
                                                            true
                                                        ? Colors.red
                                                        : Colors.transparent,
                                                width:
                                                    Platform.isWindows ? 5 : 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                          ),
                                          child: Icon(Icons.check_box,
                                              color: themeSelector["primary"]
                                                  [settings.get("theme")],
                                              size: Platform.isWindows
                                                  ? 30
                                                  : 20)),
                                      onTap: () {
                                        setState(() {
                                          if (gameSettings['complete'] !=
                                              true) {
                                            gameSettings['complete'] = true;
                                          } else {
                                            //? since complete and incomplete filters are mutually exclusive,
                                            //? activating one on must turn off the other
                                            gameSettings['complete'] = false;
                                            gameSettings['incomplete'] = true;
                                          }
                                          settings.put(
                                              'gameSettings', gameSettings);
                                        });
                                      }),
                                ),
                                //? Filter out backlog (0%) games
                                Tooltip(
                                  message: regionalText['games']['backlog'],
                                  child: InkWell(
                                      child: Container(
                                          decoration: BoxDecoration(
                                            //? To paint the border, we check the value of the settings for this website is true.
                                            //? If it's false or null (never set), we will paint red.
                                            border: Border.all(
                                                color:
                                                    gameSettings['zero'] != true
                                                        ? Colors.red
                                                        : Colors.transparent,
                                                width:
                                                    Platform.isWindows ? 5 : 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                          ),
                                          child: Icon(Icons.event_note,
                                              color: themeSelector["primary"]
                                                  [settings.get("theme")],
                                              size: Platform.isWindows
                                                  ? 30
                                                  : 20)),
                                      onTap: () {
                                        setState(() {
                                          if (gameSettings['zero'] != true) {
                                            gameSettings['zero'] = true;
                                          } else {
                                            gameSettings['zero'] = false;
                                          }
                                          settings.put(
                                              'gameSettings', gameSettings);
                                        });
                                      }),
                                ),
                                //? Filter out games without tracked time (PS3/PSV)
                                if (gameSettings['gamerCard'] != "grid")
                                  Tooltip(
                                    message: regionalText['games']['timed'],
                                    child: InkWell(
                                        child: Container(
                                            decoration: BoxDecoration(
                                              //? To paint the border, we check the value of the settings for this website is true.
                                              //? If it's false or null (never set), we will paint red.
                                              border: Border.all(
                                                  color:
                                                      gameSettings['timed'] !=
                                                              false
                                                          ? Colors.green
                                                          : Colors.transparent,
                                                  width: Platform.isWindows
                                                      ? 5
                                                      : 2),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(5)),
                                            ),
                                            child: Icon(Icons.timer_off,
                                                color: themeSelector["primary"]
                                                    [settings.get("theme")],
                                                size: Platform.isWindows
                                                    ? 30
                                                    : 20)),
                                        onTap: () {
                                          setState(() {
                                            if (gameSettings['timed'] != true) {
                                              gameSettings['timed'] = true;
                                            } else {
                                              gameSettings['timed'] = false;
                                            }
                                            settings.put(
                                                'gameSettings', gameSettings);
                                          });
                                        }),
                                  ),
                                //? Filter out platinum achieved games
                                Tooltip(
                                  message: regionalText['games']
                                      ['mustPlatinum'],
                                  child: InkWell(
                                      child: Container(
                                        // height: Platform.isWindows ? 50 : 25,
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: gameSettings[
                                                          'mustPlatinum'] !=
                                                      false
                                                  ? Colors.red
                                                  : Colors.transparent,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Stack(
                                            alignment:
                                                AlignmentDirectional.center,
                                            children: [
                                              trophyType('platinum'),
                                              Icon(
                                                Icons.not_interested,
                                                color: Colors.red,
                                                size: Platform.isWindows
                                                    ? 35
                                                    : 20,
                                              )
                                            ]),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (gameSettings['mustPlatinum'] !=
                                              true) {
                                            gameSettings['mustPlatinum'] = true;
                                            gameSettings['mustNotPlatinum'] =
                                                false;
                                          } else {
                                            gameSettings['mustPlatinum'] =
                                                false;
                                          }
                                          settings.put(
                                              'gameSettings', gameSettings);
                                        });
                                      }),
                                ),
                                //? Filter out games where a platinum was not earned
                                Tooltip(
                                  message: regionalText['games']
                                      ['mustNotPlatinum'],
                                  child: InkWell(
                                      child: Container(
                                        // width: 50,
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: gameSettings[
                                                          'mustNotPlatinum'] !=
                                                      false
                                                  ? Colors.red
                                                  : Colors.transparent,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Stack(
                                            alignment:
                                                AlignmentDirectional.center,
                                            children: [
                                              trophyType('platinum'),
                                              Icon(
                                                Icons.not_interested,
                                                color: Colors.transparent,
                                                size: Platform.isWindows
                                                    ? 35
                                                    : 20,
                                              )
                                            ]),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (gameSettings['mustNotPlatinum'] !=
                                              true) {
                                            gameSettings['mustNotPlatinum'] =
                                                true;
                                            gameSettings['mustPlatinum'] =
                                                false;
                                          } else {
                                            gameSettings['mustNotPlatinum'] =
                                                false;
                                          }
                                          settings.put(
                                              'gameSettings', gameSettings);
                                        });
                                      }),
                                ),
                              ],
                            ),
                          ],
                        ),
                      //? This Row lets you filter in and out specific consoles.
                      if (gameSettings['togglePlatforms'] == true)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              regionalText['games']['togglePlatforms'],
                              style: textSelection(theme: "textDark"),
                              textAlign: TextAlign.center,
                            ),
                            //? Filter out PS Vita games
                            Tooltip(
                              message: regionalText['games']['psv'],
                              child: InkWell(
                                  child: Container(
                                      height: Platform.isWindows ? 50 : 25,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color: gameSettings['psv'] != true
                                                ? Colors.red
                                                : Colors.green,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: Image.asset(img['psv'],
                                          width: Platform.isWindows ? 40 : 20)),
                                  onTap: () {
                                    setState(() {
                                      if (gameSettings['psv'] != true) {
                                        gameSettings['psv'] = true;
                                      } else {
                                        gameSettings['psv'] = false;
                                      }
                                      settings.put(
                                          'gameSettings', gameSettings);
                                    });
                                  }),
                            ),
                            //? Filter out PS3 games
                            Tooltip(
                              message: regionalText['games']['ps3'],
                              child: InkWell(
                                  child: Container(
                                      height: Platform.isWindows ? 50 : 25,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color: gameSettings['ps3'] != true
                                                ? Colors.red
                                                : Colors.green,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: Image.asset(img['ps3'],
                                          width: Platform.isWindows ? 40 : 20)),
                                  onTap: () {
                                    setState(() {
                                      if (gameSettings['ps3'] != true) {
                                        gameSettings['ps3'] = true;
                                      } else {
                                        gameSettings['ps3'] = false;
                                      }
                                      settings.put(
                                          'gameSettings', gameSettings);
                                    });
                                  }),
                            ),
                            //? Filter out PS4 games
                            Tooltip(
                              message: regionalText['games']['ps4'],
                              child: InkWell(
                                  child: Container(
                                      height: Platform.isWindows ? 50 : 25,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color: gameSettings['ps4'] != true
                                                ? Colors.red
                                                : Colors.green,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: Image.asset(img['ps4'],
                                          width: Platform.isWindows ? 40 : 20)),
                                  onTap: () {
                                    setState(() {
                                      if (gameSettings['ps4'] != true) {
                                        gameSettings['ps4'] = true;
                                      } else {
                                        gameSettings['ps4'] = false;
                                      }
                                      settings.put(
                                          'gameSettings', gameSettings);
                                    });
                                  }),
                            ),
                            //? Filter out PS5 games
                            Tooltip(
                              message: regionalText['games']['ps5'],
                              child: InkWell(
                                  child: Container(
                                      height: Platform.isWindows ? 50 : 25,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color: gameSettings['ps5'] != true
                                                ? Colors.red
                                                : Colors.green,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: Image.asset(img['ps5'],
                                          width: Platform.isWindows ? 40 : 20)),
                                  onTap: () {
                                    setState(() {
                                      if (gameSettings['ps5'] != true) {
                                        gameSettings['ps5'] = true;
                                      } else {
                                        gameSettings['ps5'] = false;
                                      }
                                      settings.put(
                                          'gameSettings', gameSettings);
                                    });
                                  }),
                            ),
                          ],
                        ),
                      //? This Row lets you sort games in different orders.
                      if (gameSettings['sort'] == true)
                        Container(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: Text(
                                    regionalText['games']['sort'],
                                    style: textSelection(theme: "textDark"),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 3),
                                    //? Sort games by Last played
                                    Tooltip(
                                      message: regionalText['games']
                                          ['lastPlayed'],
                                      child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: gameSettings['sorting'] ==
                                                      'lastPlayed'
                                                  ? Colors.green
                                                  : Colors.transparent,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: InkWell(
                                          child: Text(
                                            "📆⬆️",
                                            style: textSelection(
                                                theme: "textDark"),
                                            textAlign: TextAlign.center,
                                          ),
                                          onTap: () {
                                            if (gameSettings['sorting'] !=
                                                "lastPlayed") {
                                              setState(() {
                                                gameSettings['sorting'] =
                                                    "lastPlayed";
                                              });
                                              settings.put(
                                                  'gameSettings', gameSettings);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    //? Sort games by First played
                                    Tooltip(
                                      message: regionalText['games']
                                          ['firstPlayed'],
                                      child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: gameSettings['sorting'] ==
                                                      'firstPlayed'
                                                  ? Colors.green
                                                  : Colors.transparent,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: InkWell(
                                          child: Text(
                                            "📆⬇️",
                                            style: textSelection(
                                                theme: "textDark"),
                                            textAlign: TextAlign.center,
                                          ),
                                          onTap: () {
                                            if (gameSettings['sorting'] !=
                                                "firstPlayed") {
                                              setState(() {
                                                gameSettings['sorting'] =
                                                    "firstPlayed";
                                              });
                                              settings.put(
                                                  'gameSettings', gameSettings);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    //? Sort games by ascending completion
                                    Tooltip(
                                      message: regionalText['games']
                                          ['completionAscending'],
                                      child: InkWell(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            //? To paint the border, we check the value of the settings for this website is true.
                                            //? If it's false or null (never set), we will paint red.
                                            border: Border.all(
                                                color: gameSettings[
                                                            'sorting'] ==
                                                        'completionAscending'
                                                    ? Colors.green
                                                    : Colors.transparent,
                                                width:
                                                    Platform.isWindows ? 5 : 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                          ),
                                          child: Text(
                                            "%⬆️",
                                            style: textSelection(
                                                theme: "textDark"),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        onTap: () {
                                          if (gameSettings['sorting'] !=
                                              "completionAscending") {
                                            setState(() {
                                              gameSettings['sorting'] =
                                                  "completionAscending";
                                            });
                                            settings.put(
                                                'gameSettings', gameSettings);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    //? Sort games by descending completion
                                    Tooltip(
                                      message: regionalText['games']
                                          ['completionDescending'],
                                      child: InkWell(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            //? To paint the border, we check the value of the settings for this website is true.
                                            //? If it's false or null (never set), we will paint red.
                                            border: Border.all(
                                                color: gameSettings[
                                                            'sorting'] ==
                                                        'completionDescending'
                                                    ? Colors.green
                                                    : Colors.transparent,
                                                width:
                                                    Platform.isWindows ? 5 : 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                          ),
                                          child: Text(
                                            "%⬇️",
                                            style: textSelection(
                                                theme: "textDark"),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        onTap: () {
                                          if (gameSettings['sorting'] !=
                                              "completionDescending") {
                                            setState(() {
                                              gameSettings['sorting'] =
                                                  "completionDescending";
                                            });
                                            settings.put(
                                                'gameSettings', gameSettings);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    //? Sort games by ascending Alphabetical (A to Z)
                                    Tooltip(
                                      message: regionalText['games']
                                          ['alphabeticalAscending'],
                                      child: InkWell(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            //? To paint the border, we check the value of the settings for this website is true.
                                            //? If it's false or null (never set), we will paint red.
                                            border: Border.all(
                                                color: gameSettings[
                                                            'sorting'] ==
                                                        'alphabeticalAscending'
                                                    ? Colors.green
                                                    : Colors.transparent,
                                                width:
                                                    Platform.isWindows ? 5 : 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                          ),
                                          child: Text(
                                            "Abc⬇️",
                                            style: textSelection(
                                                theme: "textDark"),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        onTap: () {
                                          if (gameSettings['sorting'] !=
                                              "alphabeticalAscending") {
                                            setState(() {
                                              gameSettings['sorting'] =
                                                  "alphabeticalAscending";
                                            });
                                            settings.put(
                                                'gameSettings', gameSettings);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    //? Sort games by descending Alphabetical (Z to A)
                                    Tooltip(
                                      message: regionalText['games']
                                          ['alphabeticalDescending'],
                                      child: InkWell(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            //? To paint the border, we check the value of the settings for this website is true.
                                            //? If it's false or null (never set), we will paint red.
                                            border: Border.all(
                                                color: gameSettings[
                                                            'sorting'] ==
                                                        'alphabeticalDescending'
                                                    ? Colors.green
                                                    : Colors.transparent,
                                                width:
                                                    Platform.isWindows ? 5 : 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                          ),
                                          child: Text(
                                            "Zyx⬆️",
                                            style: textSelection(
                                                theme: "textDark"),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        onTap: () {
                                          if (gameSettings['sorting'] !=
                                              "alphabeticalDescending") {
                                            setState(() {
                                              gameSettings['sorting'] =
                                                  "alphabeticalDescending";
                                            });
                                            settings.put(
                                                'gameSettings', gameSettings);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    //? Sort games by ascending EXP
                                    Tooltip(
                                      message: regionalText['games']
                                          ['expAscending'],
                                      child: InkWell(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            //? To paint the border, we check the value of the settings for this website is true.
                                            //? If it's false or null (never set), we will paint red.
                                            border: Border.all(
                                                color:
                                                    gameSettings['sorting'] ==
                                                            'expAscending'
                                                        ? Colors.green
                                                        : Colors.transparent,
                                                width:
                                                    Platform.isWindows ? 5 : 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                          ),
                                          child: Text(
                                            "EXP⬆️",
                                            style: textSelection(
                                                theme: "textDark"),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        onTap: () {
                                          if (gameSettings['sorting'] !=
                                              "expAscending") {
                                            setState(() {
                                              gameSettings['sorting'] =
                                                  "expAscending";
                                            });
                                            settings.put(
                                                'gameSettings', gameSettings);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    //? Sort games by descending EXP
                                    Tooltip(
                                      message: regionalText['games']
                                          ['expDescending'],
                                      child: InkWell(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            //? To paint the border, we check the value of the settings for this website is true.
                                            //? If it's false or null (never set), we will paint red.
                                            border: Border.all(
                                                color:
                                                    gameSettings['sorting'] ==
                                                            'expDescending'
                                                        ? Colors.green
                                                        : Colors.transparent,
                                                width:
                                                    Platform.isWindows ? 5 : 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                          ),
                                          child: Text(
                                            "EXP⬇️",
                                            style: textSelection(
                                                theme: "textDark"),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        onTap: () {
                                          if (gameSettings['sorting'] !=
                                              "expDescending") {
                                            setState(() {
                                              gameSettings['sorting'] =
                                                  "expDescending";
                                            });
                                            settings.put(
                                                'gameSettings', gameSettings);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    //? Sort games by ascending time tracked (when avaiable)
                                    Tooltip(
                                      message: regionalText['games']
                                          ['timeAscending'],
                                      child: InkWell(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            //? To paint the border, we check the value of the settings for this website is true.
                                            //? If it's false or null (never set), we will paint red.
                                            border: Border.all(
                                                color:
                                                    gameSettings['sorting'] ==
                                                            'timeAscending'
                                                        ? Colors.green
                                                        : Colors.transparent,
                                                width:
                                                    Platform.isWindows ? 5 : 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                          ),
                                          child: Text(
                                            "⏰⬆️",
                                            style: textSelection(
                                                theme: "textDark"),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        onTap: () {
                                          if (gameSettings['sorting'] !=
                                              "timeAscending") {
                                            setState(() {
                                              gameSettings['sorting'] =
                                                  "timeAscending";
                                            });
                                            settings.put(
                                                'gameSettings', gameSettings);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    //? Sort games by descending time tracked (when avaiable)
                                    Tooltip(
                                      message: regionalText['games']
                                          ['timeDescending'],
                                      child: InkWell(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            //? To paint the border, we check the value of the settings for this website is true.
                                            //? If it's false or null (never set), we will paint red.
                                            border: Border.all(
                                                color:
                                                    gameSettings['sorting'] ==
                                                            'timeDescending'
                                                        ? Colors.green
                                                        : Colors.transparent,
                                                width:
                                                    Platform.isWindows ? 5 : 2),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                          ),
                                          child: Text(
                                            "⏰⬇️",
                                            style: textSelection(
                                                theme: "textDark"),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        onTap: () {
                                          if (gameSettings['sorting'] !=
                                              "timeDescending") {
                                            setState(() {
                                              gameSettings['sorting'] =
                                                  "timeDescending";
                                            });
                                            settings.put(
                                                'gameSettings', gameSettings);
                                          }
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
                      if (gameSettings['display'] == true)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 10),
                            Text(
                              regionalText['games']['display'],
                              style: textSelection(theme: "textDark"),
                              textAlign: TextAlign.center,
                            ),
                            if (gameSettings['gamerCard'] != "list")
                              Tooltip(
                                message: regionalText['games']['list'],
                                child: InkWell(
                                    child: Icon(Icons.list,
                                        color: themeSelector["primary"]
                                            [settings.get("theme")],
                                        size: Platform.isWindows ? 35 : 17),
                                    hoverColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                    onTap: () => {
                                          setState(() {
                                            gameSettings['gamerCard'] = "list";
                                          }),
                                          settings.put(
                                              'gameSettings', gameSettings)
                                        }),
                              ),
                            //? Option to use view trophy lists as a block
                            if (gameSettings['gamerCard'] != "block")
                              Tooltip(
                                message: regionalText['games']['block'],
                                child: InkWell(
                                    child: Icon(
                                      Icons.view_compact,
                                      color: themeSelector["primary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 30 : 15,
                                    ),
                                    hoverColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                    onTap: () => {
                                          setState(() {
                                            gameSettings['gamerCard'] = "block";
                                          }),
                                          settings.put(
                                              'gameSettings', gameSettings)
                                        }),
                              ),
                            //? Option to use view trophy lists as a grid
                            if (gameSettings['gamerCard'] != "grid")
                              Tooltip(
                                message: regionalText['games']['grid'],
                                child: InkWell(
                                    child: Icon(Icons.view_comfy,
                                        color: themeSelector["primary"]
                                            [settings.get("theme")],
                                        size: Platform.isWindows ? 30 : 15),
                                    hoverColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                    onTap: () => {
                                          setState(() {
                                            gameSettings['gamerCard'] = "grid";
                                          }),
                                          settings.put(
                                              'gameSettings', gameSettings)
                                        }),
                              ),
                          ],
                        ),
                      //? This row contains the toggles to display the other option rows above.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            regionalText['games']['options'],
                            style: textSelection(theme: "textDark"),
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
                                        color: gameSettings['search'] != true
                                            ? Colors.transparent
                                            : Colors.green,
                                        width: Platform.isWindows ? 5 : 2),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                  child: Icon(Icons.search,
                                      color: themeSelector["primary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 30 : 17),
                                ),
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                onTap: () => {
                                      setState(() {
                                        if (gameSettings['search'] != true) {
                                          gameSettings['search'] = true;
                                        } else {
                                          gameSettings['search'] = false;
                                          searchQuery = [];
                                        }
                                      }),
                                      settings.put('gameSettings', gameSettings)
                                    }),
                          ),
                          //? Filter
                          Tooltip(
                            message: regionalText['games']['filter'],
                            child: InkWell(
                                child: Container(
                                  decoration: BoxDecoration(
                                    //? To paint the border, we check the value of the settings for this website is true.
                                    //? If it's false or null (never set), we will paint red.
                                    border: Border.all(
                                        color: gameSettings['filter'] != true
                                            ? Colors.transparent
                                            : Colors.green,
                                        width: Platform.isWindows ? 5 : 2),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                  child: Icon(Icons.filter_alt,
                                      color: themeSelector["primary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 30 : 17),
                                ),
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                onTap: () => {
                                      setState(() {
                                        if (gameSettings['filter'] != true) {
                                          gameSettings['filter'] = true;
                                          gameSettings['togglePlatforms'] =
                                              false;
                                          gameSettings['sort'] = false;
                                          gameSettings['display'] = false;
                                        } else {
                                          gameSettings['filter'] = false;
                                        }
                                      }),
                                      settings.put('gameSettings', gameSettings)
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
                                            gameSettings['togglePlatforms'] !=
                                                    true
                                                ? Colors.transparent
                                                : Colors.green,
                                        width: Platform.isWindows ? 5 : 2),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                  child: Icon(Icons.sports_esports,
                                      color: themeSelector["primary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 30 : 17),
                                ),
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                onTap: () => {
                                      setState(() {
                                        if (gameSettings['togglePlatforms'] !=
                                            true) {
                                          gameSettings['filter'] = false;
                                          gameSettings['togglePlatforms'] =
                                              true;
                                          gameSettings['sort'] = false;
                                          gameSettings['display'] = false;
                                        } else {
                                          gameSettings['togglePlatforms'] =
                                              false;
                                        }
                                      }),
                                      settings.put('gameSettings', gameSettings)
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
                                        color: gameSettings['sort'] != true
                                            ? Colors.transparent
                                            : Colors.green,
                                        width: Platform.isWindows ? 5 : 2),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                  child: Icon(Icons.sort_by_alpha,
                                      color: themeSelector["primary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 30 : 17),
                                ),
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                onTap: () => {
                                      setState(() {
                                        if (gameSettings['sort'] != true) {
                                          gameSettings['filter'] = false;
                                          gameSettings['togglePlatforms'] =
                                              false;
                                          gameSettings['sort'] = true;
                                          gameSettings['display'] = false;
                                        } else {
                                          gameSettings['sort'] = false;
                                        }
                                      }),
                                      settings.put('gameSettings', gameSettings)
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
                                        color: gameSettings['display'] != true
                                            ? Colors.transparent
                                            : Colors.green,
                                        width: Platform.isWindows ? 5 : 2),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                  child: Icon(
                                      gameSettings['gamerCard'] == "list"
                                          ? Icons.list
                                          : gameSettings['gamerCard'] == "block"
                                              ? Icons.view_compact
                                              : Icons.view_comfy,
                                      color: themeSelector["primary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 30 : 17),
                                ),
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                onTap: () => {
                                      setState(() {
                                        if (gameSettings['display'] != true) {
                                          gameSettings['filter'] = false;
                                          gameSettings['togglePlatforms'] =
                                              false;
                                          gameSettings['sort'] = false;
                                          gameSettings['display'] = true;
                                        } else {
                                          gameSettings['display'] = false;
                                        }
                                      }),
                                      settings.put('gameSettings', gameSettings)
                                    }),
                          ),
                          SizedBox(width: 5),
                          //? Reset settings button
                          Tooltip(
                            message: regionalText['home']['undo'],
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  gameSettings = {
                                    'psv': true,
                                    'ps3': true,
                                    'ps4': true,
                                    'ps5': true,
                                    'incomplete': true,
                                    'complete': true,
                                    'zero': true,
                                    'timed': false,
                                    'mustPlatinum': false,
                                    'mustNotPlatinum': false,
                                    'sorting': "lastPlayed",
                                    'gamerCard': gameSettings['gamerCard'],
                                    'search': false,
                                    'filter': false,
                                    'togglePlatforms': false,
                                    'sort': false,
                                    'display': false
                                  };
                                  searchQuery = [];
                                });
                                settings.put('gameSettings', gameSettings);
                              },
                              child: Container(
                                child: Icon(Icons.undo,
                                    color: themeSelector["primary"]
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
          )),
    );
  }
}

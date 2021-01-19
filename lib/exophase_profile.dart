import 'dart:io' show Platform;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'multicolorcircle.dart';
import 'main.dart';
import 'package:flutter/material.dart';

class ExophaseProfile extends StatefulWidget {
  ExophaseProfile({Key key}) : super(key: key);
  @override
  _ExophaseProfileState createState() => _ExophaseProfileState();
}

class _ExophaseProfileState extends State<ExophaseProfile> {
  Map exophaseSettings = settings.get('exophaseSettings');

  @override
  Widget build(BuildContext context) {
    Map exophaseDump = settings.get('exophaseDump');
    Map exophaseGames = settings.get('exophaseGames');

    List<Widget> fetchExophaseGames() {
      List<Widget> cardAndGames = [];
      if (exophaseSettings == null) {
        exophaseSettings = {
          'psv': true,
          'ps3': true,
          'ps4': true,
          'ps5': true,
          'incomplete': true,
          'complete': true,
          'zero': true,
          'timed': false,
          'gamerCard': "grid",
          'mustPlatinum': false,
          'mustNotPlatinum': false,
        };
      }
      for (var i = 1; i < exophaseGames.length; i++) {
        int shouldDisplay = 0;
        if (exophaseSettings['ps4'] == true &&
            exophaseGames[i]['gamePS4'] == true) {
          shouldDisplay++;
        }
        if (exophaseSettings['ps3'] == true &&
            exophaseGames[i]['gamePS3'] == true) {
          shouldDisplay++;
        }
        if (exophaseSettings['ps5'] == true &&
            exophaseGames[i]['gamePS5'] == true) {
          shouldDisplay++;
        }
        if (exophaseSettings['psv'] == true &&
            exophaseGames[i]['gameVita'] == true) {
          shouldDisplay++;
        }
        if (shouldDisplay == 0) {
          continue;
        } else if (exophaseSettings['zero'] == false &&
            exophaseGames[i]['gamePercentage'] == 0) {
          continue;
        } else if (exophaseSettings['incomplete'] == false &&
            exophaseGames[i]['gamePercentage'] < 100) {
          continue;
        } else if (exophaseSettings['complete'] == false &&
            exophaseGames[i]['gamePercentage'] == 100) {
          continue;
        } else if (exophaseSettings['timed'] == true &&
            exophaseGames[i]['gameTime'] == null) {
          continue;
        } else if (exophaseSettings['mustPlatinum'] == true &&
            exophaseGames[i]['gamePlatinum'] == null) {
          continue;
        } else if (exophaseSettings['mustNotPlatinum'] == true &&
            exophaseGames[i]['gamePlatinum'] != null) {
          continue;
        } else {
          Container gameDisplay;
          if (exophaseSettings['gamerCard'] == "block") {
            gameDisplay = Container(
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
                        color: exophaseGames[i]['gamePercentage'] < 30
                            ? Colors.red
                            : exophaseGames[i]['gamePercentage'] == 100
                                ? Colors.green
                                : Colors.yellow,
                        width: Platform.isWindows ? 4 : 2.5),
                    boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)]),
                margin: EdgeInsets.symmetric(
                    vertical: Platform.isWindows ? 5 : 2,
                    horizontal: Platform.isWindows ? 5 : 2),
                padding: EdgeInsets.only(
                    top: 2,
                    bottom: exophaseGames[i]['gamePercentage'] > 0 ? 10 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //? Game name
                    Padding(
                      padding: EdgeInsets.all(Platform.isWindows ? 5 : 2),
                      child: Text(exophaseGames[i]['gameName'],
                          style: textSelection("textLightBold"),
                          textAlign: TextAlign.center),
                    ),
                    //? Spacing to separate the text/platforms/points from the image
                    //? Game image
                    Image.network(
                      exophaseGames[i]['gameImage'],
                      scale: 0.4,
                    ),
                    //? Spacing to separate the text/platforms/points from the image
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (exophaseGames[i]['gameVita'] == true)
                          Image.asset(
                            img['psv'],
                            width: 40,
                          ),
                        if (exophaseGames[i]['gamePS3'] == true)
                          Image.asset(
                            img['ps3'],
                            width: 40,
                          ),
                        if (exophaseGames[i]['gamePS4'] == true)
                          Image.asset(
                            img['ps4'],
                            width: 40,
                          ),
                        if (exophaseGames[i]['gamePS5'] == true)
                          Image.asset(
                            img['ps5'],
                            width: 40,
                          ),
                      ],
                    ),
                    //? Last played tracked date
                    Text(exophaseGames[i]['gameLastPlayed'],
                        style: textSelection("")),
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
                                  Image.network(
                                      "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                      scale: Platform.isWindows ? 8 : 10),
                                  SizedBox(width: Platform.isWindows ? 5 : 3),
                                  //? EXP earned from this game
                                  Text(
                                    exophaseGames[i]['gameEXP'].toString(),
                                    style: textSelection(""),
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
                                Text(exophaseGames[i]['gameRatio'],
                                    style: textSelection("")),
                              ],
                            ),
                            if (exophaseGames[i]['gameTime'] != null)
                              SizedBox(height: Platform.isWindows ? 3 : 2),
                            if (exophaseGames[i]['gameTime'] != null)
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
                                    exophaseGames[i]['gameTime'],
                                    style: textSelection(""),
                                  )
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (exophaseGames[i]['gamePercentage'] > 0)
                      Divider(
                          color: themeSelector['secondary']
                              [settings.get('theme')],
                          thickness: 2,
                          indent: 5,
                          endIndent: 5,
                          height: 5),
                    if (exophaseGames[i]['gamePercentage'] > 0)
                      SizedBox(height: 7),
                    //? Row with the trophy distribution and the multicolored circle
                    if (exophaseGames[i]['gamePercentage'] > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //? This contains bronze, silver, gold, platinum
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              //? Second column displays platinum and silver trophies, if available
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (exophaseGames[i]['gamePlatinum'] != null)
                                    trophyType("platinum",
                                        quantity: exophaseGames[i]
                                            ['gamePlatinum']),
                                  SizedBox(height: 5),
                                  if (exophaseGames[i]['gameSilver'] != null)
                                    trophyType("silver",
                                        quantity: exophaseGames[i]
                                            ['gameSilver'])
                                ],
                              ),
                              //? This sized box has height to make the Columns before and after
                              //? align their trophy icons at the bottom
                              SizedBox(
                                  width: Platform.isWindows ? 5 : 3,
                                  height: 65),
                              //? Third column displays gold and bronze trophies, if available
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (exophaseGames[i]['gameGold'] != null)
                                    trophyType("gold",
                                        quantity: exophaseGames[i]['gameGold']),
                                  SizedBox(height: 5),
                                  if (exophaseGames[i]['gameBronze'] != null)
                                    trophyType("bronze",
                                        quantity: exophaseGames[i]
                                            ['gameBronze'])
                                ],
                              ),
                            ],
                          ),

                          SizedBox(width: 10),
                          //? This is the created MultiColorCircle class
                          MultiColorCircle(
                            //? This needs to have an unique key otherwise the filtering function
                            //? will glitch the rebuild and not display the correct percentage at the correct location.
                            key: UniqueKey(),
                            diameter: Platform.isWindows ? 55 : 40,
                            width: Platform.isWindows ? 10 : 7,
                            colors: [
                              Colors.blue,
                              Colors.yellow,
                              Colors.grey,
                              Colors.brown
                            ],
                            unfilled: Colors.grey.withOpacity(0.5),
                            //? This takes an array of doubles that is returned by the function below.
                            percentages: trophyPointsDistribution(
                                exophaseGames[i]['gamePlatinum'] ?? 0,
                                exophaseGames[i]['gameGold'] ?? 0,
                                exophaseGames[i]['gameSilver'] ?? 0,
                                exophaseGames[i]['gameBronze'] ?? 0,
                                exophaseGames[i]['gamePercentage']),
                            centerText: Text(
                              exophaseGames[i]['gamePercentage'].toString() +
                                  "%",
                              style: textSelection(""),
                            ),
                          ),
                        ],
                      ),
                  ],
                ));
          } else if (exophaseSettings['gamerCard'] == "list") {
            gameDisplay = Container(
              height: Platform.isWindows
                  ? 95
                  : 58, //exophaseGames[i]['gamePS5'] == true ? 150 : 95 //! Already prepared the code for the other websites with larger images.
              decoration: BoxDecoration(
                  color: themeSelector["primary"][settings.get("theme")]
                      .withOpacity(0.85),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  border: Border.all(
                      color: exophaseGames[i]['gamePercentage'] < 30
                          ? Colors.red
                          : exophaseGames[i]['gamePercentage'] == 100
                              ? Colors.green
                              : Colors.yellow,
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
                    child: Image.network(
                      exophaseGames[i]['gameImage'],
                      scale: 0.8,
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
                          vertical: Platform.isWindows ? 8.0 : 3.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          //? Game name
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(exophaseGames[i]['gameName'],
                                style: textSelection("")),
                          ),
                          //? Game platforms and Exophase EXP
                          SizedBox(height: 1),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (exophaseGames[i]['gameVita'] == true)
                                  Image.asset(
                                    img['psv'],
                                    width: Platform.isWindows ? 40 : 30,
                                  ),
                                if (exophaseGames[i]['gamePS3'] == true)
                                  Image.asset(
                                    img['ps3'],
                                    width: Platform.isWindows ? 40 : 30,
                                  ),
                                if (exophaseGames[i]['gamePS4'] == true)
                                  Image.asset(
                                    img['ps4'],
                                    width: Platform.isWindows ? 40 : 30,
                                  ),
                                if (exophaseGames[i]['gamePS5'] == true)
                                  Image.asset(
                                    img['ps5'],
                                    width: Platform.isWindows ? 40 : 30,
                                  ), //? Game points earned through Exophase's scoring
                                SizedBox(width: Platform.isWindows ? 5 : 3),
                                Tooltip(
                                  message: "EXP",
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      //? Exophase's favicon used as EXP icon since the EXP icon is
                                      //? way too transparent to be used consistently
                                      Image.network(
                                          "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                          scale: Platform.isWindows ? 8 : 10),
                                      SizedBox(
                                          width: Platform.isWindows ? 5 : 3),
                                      //? EXP earned from this game
                                      Text(
                                        exophaseGames[i]['gameEXP'].toString(),
                                        style: textSelection(""),
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
                            child: Text(exophaseGames[i]['gameLastPlayed'],
                                style: textSelection("")),
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
                                            width: Platform.isWindows ? 5 : 2),
                                        Text(exophaseGames[i]['gameRatio'],
                                            style: textSelection("")),
                                      ],
                                    ),
                                  ),
                                  if (exophaseGames[i]['gameTime'] != null)
                                    SizedBox(
                                        height: Platform.isWindows ? 3 : 2),
                                  if (exophaseGames[i]['gameTime'] != null)
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.hourglass_bottom,
                                            color: themeSelector["secondary"]
                                                [settings.get("theme")],
                                            size: Platform.isWindows ? 30 : 14,
                                          ),
                                          Text(
                                            exophaseGames[i]['gameTime'],
                                            style: textSelection(""),
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
                              height: Platform.isWindows ? 48 : 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (exophaseGames[i]['gamePlatinum'] != null)
                                    trophyType("platinum",
                                        quantity: exophaseGames[i]
                                            ['gamePlatinum'],
                                        size: "small"),
                                  SizedBox(height: Platform.isWindows ? 5 : 2),
                                  if (exophaseGames[i]['gameSilver'] != null)
                                    trophyType("silver",
                                        quantity: exophaseGames[i]
                                            ['gameSilver'],
                                        size: "small")
                                ],
                              ),
                            ),
                            //? Third column displays gold and bronze trophies, if available
                            Container(
                              width: Platform.isWindows ? 55 : 40,
                              height: Platform.isWindows ? 48 : 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (exophaseGames[i]['gameGold'] != null)
                                    trophyType("gold",
                                        quantity: exophaseGames[i]['gameGold'],
                                        size: "small"),
                                  SizedBox(height: Platform.isWindows ? 5 : 2),
                                  if (exophaseGames[i]['gameBronze'] != null)
                                    trophyType("bronze",
                                        quantity: exophaseGames[i]
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
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                            child: Tooltip(
                              message: exophaseGames[i]['gamePercentage']
                                      .toString() +
                                  "%",
                              child: Row(
                                children: [
                                  //? Platinum points distribution
                                  if (exophaseGames[i]['gamePlatinum'] != null)
                                    Container(
                                      color: Colors.blue,
                                      height: Platform.isWindows ? 10 : 5,
                                      width: (Platform.isWindows ? 2 : 1.2) *
                                          trophyPointsDistribution(
                                              exophaseGames[i]
                                                      ['gamePlatinum'] ??
                                                  0,
                                              exophaseGames[i]['gameGold'] ?? 0,
                                              exophaseGames[i]['gameSilver'] ??
                                                  0,
                                              exophaseGames[i]['gameBronze'] ??
                                                  0,
                                              exophaseGames[i]
                                                  ['gamePercentage'])[0],
                                    ),
                                  //? Gold points distribution
                                  if (exophaseGames[i]['gameGold'] != null)
                                    Container(
                                      color: Colors.yellow,
                                      height: Platform.isWindows ? 10 : 5,
                                      width: (Platform.isWindows ? 2 : 1.2) *
                                          trophyPointsDistribution(
                                              exophaseGames[i]
                                                      ['gamePlatinum'] ??
                                                  0,
                                              exophaseGames[i]['gameGold'] ?? 0,
                                              exophaseGames[i]['gameSilver'] ??
                                                  0,
                                              exophaseGames[i]['gameBronze'] ??
                                                  0,
                                              exophaseGames[i]
                                                  ['gamePercentage'])[1],
                                    ),
                                  //? Silver points distribution
                                  if (exophaseGames[i]['gameSilver'] != null)
                                    Container(
                                      color: Colors.grey,
                                      height: Platform.isWindows ? 10 : 5,
                                      width: (Platform.isWindows ? 2 : 1.2) *
                                          trophyPointsDistribution(
                                              exophaseGames[i]
                                                      ['gamePlatinum'] ??
                                                  0,
                                              exophaseGames[i]['gameGold'] ?? 0,
                                              exophaseGames[i]['gameSilver'] ??
                                                  0,
                                              exophaseGames[i]['gameBronze'] ??
                                                  0,
                                              exophaseGames[i]
                                                  ['gamePercentage'])[2],
                                    ),
                                  //? Bronze points distribution
                                  if (exophaseGames[i]['gameBronze'] != null)
                                    Container(
                                      color: Colors.brown,
                                      height: Platform.isWindows ? 10 : 5,
                                      width: (Platform.isWindows ? 2 : 1.2) *
                                          trophyPointsDistribution(
                                              exophaseGames[i]
                                                      ['gamePlatinum'] ??
                                                  0,
                                              exophaseGames[i]['gameGold'] ?? 0,
                                              exophaseGames[i]['gameSilver'] ??
                                                  0,
                                              exophaseGames[i]['gameBronze'] ??
                                                  0,
                                              exophaseGames[i]
                                                  ['gamePercentage'])[3],
                                    ),
                                  Container(
                                    height: Platform.isWindows ? 10 : 5,
                                    width: (Platform.isWindows ? 2 : 1.2) *
                                        (100 -
                                                exophaseGames[i]
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
            );
          } else {
            //? Grid display
            gameDisplay = Container(
              decoration: BoxDecoration(
                  color: themeSelector["primary"][settings.get("theme")]
                      .withOpacity(0.85),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  border: Border.all(
                      color: exophaseGames[i]['gamePercentage'] < 30
                          ? Colors.red
                          : exophaseGames[i]['gamePercentage'] == 100
                              ? Colors.green
                              : Colors.yellow,
                      width: Platform.isWindows ? 4.0 : 3.0),
                  boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)]),
              margin: EdgeInsets.all(Platform.isWindows ? 5.0 : 3.0),
              child: Tooltip(
                message: exophaseGames[i]['gameName'],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(7)),
                      child: Image.network(
                        exophaseGames[i]['gameImage'],
                        scale: 0.8,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (exophaseGames[i]['gameVita'] == true)
                          Image.asset(
                            img['psv'],
                            width: 35,
                          ),
                        if (exophaseGames[i]['gamePS3'] == true)
                          Image.asset(
                            img['ps3'],
                            width: 35,
                          ),
                        if (exophaseGames[i]['gamePS4'] == true)
                          Image.asset(
                            img['ps4'],
                            width: 35,
                          ),
                        if (exophaseGames[i]['gamePS5'] == true)
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
                        message:
                            exophaseGames[i]['gamePercentage'].toString() + "%",
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //? Platinum points distribution
                            if (exophaseGames[i]['gamePlatinum'] != null)
                              Container(
                                color: Colors.blue,
                                height: Platform.isWindows ? 10 : 7,
                                width: trophyPointsDistribution(
                                    exophaseGames[i]['gamePlatinum'] ?? 0,
                                    exophaseGames[i]['gameGold'] ?? 0,
                                    exophaseGames[i]['gameSilver'] ?? 0,
                                    exophaseGames[i]['gameBronze'] ?? 0,
                                    exophaseGames[i]['gamePercentage'])[0],
                              ),
                            //? Gold points distribution
                            if (exophaseGames[i]['gameGold'] != null)
                              Container(
                                color: Colors.yellow,
                                height: Platform.isWindows ? 10 : 7,
                                width: trophyPointsDistribution(
                                    exophaseGames[i]['gamePlatinum'] ?? 0,
                                    exophaseGames[i]['gameGold'] ?? 0,
                                    exophaseGames[i]['gameSilver'] ?? 0,
                                    exophaseGames[i]['gameBronze'] ?? 0,
                                    exophaseGames[i]['gamePercentage'])[1],
                              ),
                            //? Silver points distribution
                            if (exophaseGames[i]['gameSilver'] != null)
                              Container(
                                color: Colors.grey,
                                height: Platform.isWindows ? 10 : 7,
                                width: trophyPointsDistribution(
                                    exophaseGames[i]['gamePlatinum'] ?? 0,
                                    exophaseGames[i]['gameGold'] ?? 0,
                                    exophaseGames[i]['gameSilver'] ?? 0,
                                    exophaseGames[i]['gameBronze'] ?? 0,
                                    exophaseGames[i]['gamePercentage'])[2],
                              ),
                            //? Bronze points distribution
                            if (exophaseGames[i]['gameBronze'] != null)
                              Container(
                                color: Colors.brown,
                                height: Platform.isWindows ? 10 : 7,
                                width: trophyPointsDistribution(
                                    exophaseGames[i]['gamePlatinum'] ?? 0,
                                    exophaseGames[i]['gameGold'] ?? 0,
                                    exophaseGames[i]['gameSilver'] ?? 0,
                                    exophaseGames[i]['gameBronze'] ?? 0,
                                    exophaseGames[i]['gamePercentage'])[3],
                              ),
                            Container(
                              height: Platform.isWindows ? 10 : 7,
                              width: (100 - exophaseGames[i]['gamePercentage'])
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
            );
          }
          cardAndGames.add(gameDisplay);
        }
      }
      return cardAndGames;
    }

    List exophaseGamesList = fetchExophaseGames();

    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 40,
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
                        Image.network(
                          exophaseDump['avatar'] ??
                              "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                          height: 30,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            exophaseDump["psnID"],
                            style: textSelection("textLightBold"),
                          ),
                        ),
                        //? Country flag
                        Image.network(
                            "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${exophaseDump['country']}.png",
                            height: 20),
                      ],
                    ),
                    levelType(exophaseDump['platinum'], exophaseDump['gold'],
                        exophaseDump['silver'], exophaseDump['bronze']),
                  ]),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
              themeSelector["primary"][settings.get("theme")].withOpacity(0.4),
              themeSelector["secondary"][settings.get("theme")]
                  .withOpacity(0.4),
            ])),
            child: Column(
              children: [
                //? This container contains all the trophy data related to the player
                Container(
                    // height: 150,
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
                            trophyType('platinum',
                                quantity: exophaseDump['platinum']),
                            SizedBox(width: Platform.isWindows ? 20 : 10),
                            trophyType('gold', quantity: exophaseDump['gold']),
                            SizedBox(width: Platform.isWindows ? 20 : 10),
                            trophyType('silver',
                                quantity: exophaseDump['silver']),
                            SizedBox(width: Platform.isWindows ? 20 : 10),
                            trophyType('bronze',
                                quantity: exophaseDump['bronze']),
                            SizedBox(width: Platform.isWindows ? 20 : 10),
                            trophyType('total',
                                quantity:
                                    "${exophaseDump['total'].toString()}"),
                          ],
                        ),
                        if (Platform.isWindows)
                          Divider(
                              color: themeSelector['secondary']
                                  [settings.get('theme')],
                              thickness: 3),
                        //? Bottom row without avatar, has information about games played,
                        //? completion, gameplay hours, country/world rankings, etc
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
                                    style: textSelection(""),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["complete"]}\n${exophaseDump['complete'].toString()} (${exophaseDump['completePercentage']}%)",
                                    style: textSelection(""),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["incomplete"]}\n${exophaseDump['incomplete'].toString()} (${exophaseDump['incompletePercentage']}%)",
                                    style: textSelection(""),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["completion"]}\n${exophaseDump['completion']}",
                                    style: textSelection(""),
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
                                        style: textSelection(""),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["exp"]}\n${exophaseDump['exp']}",
                                    style: textSelection(""),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["countryRank"]}\n${exophaseDump['countryRank'] != null ? exophaseDump['countryRank'].toString() + " " : "❌"}${exophaseDump['countryUp'] ?? ""}",
                                    style: textSelection(""),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10.0),
                                  child: Text(
                                    "${regionalText["home"]["worldRank"]}\n${exophaseDump['worldRank'] != null ? exophaseDump['worldRank'].toString() + " " : "❌"}${exophaseDump['worldUp'] ?? ""}",
                                    style: textSelection(""),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          )
                      ],
                    )),
                //? This expanded renders the trophy data in grid-like manner, if the user opted for that
                if (exophaseGamesList.length > 0 &&
                    exophaseSettings['gamerCard'] == "grid")
                  Expanded(
                    child: StaggeredGridView.countBuilder(
                      crossAxisCount: Platform.isWindows
                          ? (MediaQuery.of(context).size.width / 150).floor()
                          : 3,
                      staggeredTileBuilder: (index) => StaggeredTile.fit(1),
                      itemCount: exophaseGamesList.length,
                      itemBuilder: (context, index) => exophaseGamesList[index],
                    ),
                  ),
                //? This expanded renders the trophy data like a comprehensible list, if the user opted for that
                if (exophaseGamesList.length > 0 &&
                    exophaseSettings['gamerCard'] == "list")
                  Expanded(
                    child: ListView.builder(
                      itemCount: exophaseGamesList.length,
                      itemBuilder: (context, index) => exophaseGamesList[index],
                    ),
                  ),
                if (exophaseGamesList.length > 0 &&
                    exophaseSettings['gamerCard'] == "block")
                  Expanded(
                    child: StaggeredGridView.countBuilder(
                      crossAxisCount: Platform.isWindows
                          ? (MediaQuery.of(context).size.width / 250).floor()
                          : 2,
                      staggeredTileBuilder: (index) => StaggeredTile.fit(1),
                      itemCount: exophaseGamesList.length,
                      itemBuilder: (context, index) => exophaseGamesList[index],
                    ),
                  ),
                //? This expanded shows an image if there is no trophy data to display
                if (exophaseGamesList.length == 0)
                  Expanded(
                    child: Image.network(
                      "https://pbs.twimg.com/media/EYfO0SfXkAEA3iY.jpg",
                      scale: 0.2,
                    ),
                  ),
                //? This Wrap contains the bottom bar buttons to change settings and display options.
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.symmetric(
                      vertical: Platform.isWindows ? 5 : 3),
                  color: themeSelector["secondary"][settings.get("theme")],
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    direction: Axis.horizontal,
                    children: [
                      //? These let you filter in and out specific types of games
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Text(
                              regionalText['exophase']['filter'],
                              style: textSelection("textDark"),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              //? Filter out incomplete games and add in completed games if they were filtered
                              Tooltip(
                                message: regionalText['exophase']['incomplete'],
                                child: InkWell(
                                    child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: exophaseSettings[
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
                                            size:
                                                Platform.isWindows ? 30 : 20)),
                                    onTap: () {
                                      setState(() {
                                        if (exophaseSettings['incomplete'] !=
                                            true) {
                                          exophaseSettings['incomplete'] = true;
                                        } else {
                                          //? since complete and incomplete filters are mutually exclusive,
                                          //? activating one on must turn off the other
                                          exophaseSettings['incomplete'] =
                                              false;
                                          exophaseSettings['complete'] = true;
                                        }
                                      });
                                    }),
                              ),
                              //? Filter out complete games and add in incompleted games if they were filtered
                              Tooltip(
                                message: regionalText['exophase']['complete'],
                                child: InkWell(
                                    child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: exophaseSettings[
                                                          'complete'] !=
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
                                            size:
                                                Platform.isWindows ? 30 : 20)),
                                    onTap: () {
                                      setState(() {
                                        if (exophaseSettings['complete'] !=
                                            true) {
                                          exophaseSettings['complete'] = true;
                                        } else {
                                          //? since complete and incomplete filters are mutually exclusive,
                                          //? activating one on must turn off the other
                                          exophaseSettings['complete'] = false;
                                          exophaseSettings['incomplete'] = true;
                                        }
                                        settings.put('exophaseSettings',
                                            exophaseSettings);
                                      });
                                    }),
                              ),
                              //? Filter out backlog (0%) games
                              Tooltip(
                                message: regionalText['exophase']['backlog'],
                                child: InkWell(
                                    child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: exophaseSettings['zero'] !=
                                                      true
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
                                            size:
                                                Platform.isWindows ? 30 : 20)),
                                    onTap: () {
                                      setState(() {
                                        if (exophaseSettings['zero'] != true) {
                                          exophaseSettings['zero'] = true;
                                        } else {
                                          exophaseSettings['zero'] = false;
                                        }
                                        settings.put('exophaseSettings',
                                            exophaseSettings);
                                      });
                                    }),
                              ),
                              //? Filter out games without tracked time (PS3/PSV)
                              if (exophaseSettings['gamerCard'] != "grid")
                                Tooltip(
                                  message: regionalText['exophase']['timed'],
                                  child: InkWell(
                                      child: Container(
                                          decoration: BoxDecoration(
                                            //? To paint the border, we check the value of the settings for this website is true.
                                            //? If it's false or null (never set), we will paint red.
                                            border: Border.all(
                                                color:
                                                    exophaseSettings['timed'] !=
                                                            false
                                                        ? Colors.green
                                                        : Colors.transparent,
                                                width:
                                                    Platform.isWindows ? 5 : 2),
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
                                          if (exophaseSettings['timed'] !=
                                              true) {
                                            exophaseSettings['timed'] = true;
                                          } else {
                                            exophaseSettings['timed'] = false;
                                          }
                                          settings.put('exophaseSettings',
                                              exophaseSettings);
                                        });
                                      }),
                                ),
                              //? Filter out platinum achieved games
                              Tooltip(
                                message: regionalText['exophase']
                                    ['mustPlatinum'],
                                child: InkWell(
                                    child: Container(
                                      // height: Platform.isWindows ? 50 : 25,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color: exophaseSettings[
                                                        'mustPlatinum'] !=
                                                    false
                                                ? Colors.red
                                                : Colors.transparent,
                                            width: Platform.isWindows ? 5 : 2),
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
                                              size:
                                                  Platform.isWindows ? 35 : 20,
                                            )
                                          ]),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (exophaseSettings['mustPlatinum'] !=
                                            true) {
                                          exophaseSettings['mustPlatinum'] =
                                              true;
                                          exophaseSettings['mustNotPlatinum'] =
                                              false;
                                        } else {
                                          exophaseSettings['mustPlatinum'] =
                                              false;
                                        }
                                        settings.put('exophaseSettings',
                                            exophaseSettings);
                                      });
                                    }),
                              ),
                              //? Filter out games where a platinum was not earned
                              Tooltip(
                                message: regionalText['exophase']
                                    ['mustNotPlatinum'],
                                child: InkWell(
                                    child: Container(
                                      // width: 50,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color: exophaseSettings[
                                                        'mustNotPlatinum'] !=
                                                    false
                                                ? Colors.red
                                                : Colors.transparent,
                                            width: Platform.isWindows ? 5 : 2),
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
                                              size:
                                                  Platform.isWindows ? 35 : 20,
                                            )
                                          ]),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (exophaseSettings[
                                                'mustNotPlatinum'] !=
                                            true) {
                                          exophaseSettings['mustNotPlatinum'] =
                                              true;
                                          exophaseSettings['mustPlatinum'] =
                                              false;
                                        } else {
                                          exophaseSettings['mustNotPlatinum'] =
                                              false;
                                        }
                                        settings.put('exophaseSettings',
                                            exophaseSettings);
                                      });
                                    }),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 10),
                          Text(
                            regionalText['exophase']['togglePlatforms'],
                            style: textSelection("textDark"),
                            textAlign: TextAlign.center,
                          ),
                          //? Filter out PS Vita games
                          Tooltip(
                            message: regionalText['exophase']['psv'],
                            child: InkWell(
                                child: Container(
                                    height: Platform.isWindows ? 50 : 25,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: exophaseSettings['psv'] != true
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
                                    if (exophaseSettings['psv'] != true) {
                                      exophaseSettings['psv'] = true;
                                    } else {
                                      exophaseSettings['psv'] = false;
                                    }
                                    settings.put(
                                        'exophaseSettings', exophaseSettings);
                                  });
                                }),
                          ),
                          //? Filter out PS3 games
                          Tooltip(
                            message: regionalText['exophase']['ps3'],
                            child: InkWell(
                                child: Container(
                                    height: Platform.isWindows ? 50 : 25,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: exophaseSettings['ps3'] != true
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
                                    if (exophaseSettings['ps3'] != true) {
                                      exophaseSettings['ps3'] = true;
                                    } else {
                                      exophaseSettings['ps3'] = false;
                                    }
                                    settings.put(
                                        'exophaseSettings', exophaseSettings);
                                  });
                                }),
                          ),
                          //? Filter out PS4 games
                          Tooltip(
                            message: regionalText['exophase']['ps4'],
                            child: InkWell(
                                child: Container(
                                    height: Platform.isWindows ? 50 : 25,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: exophaseSettings['ps4'] != true
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
                                    if (exophaseSettings['ps4'] != true) {
                                      exophaseSettings['ps4'] = true;
                                    } else {
                                      exophaseSettings['ps4'] = false;
                                    }
                                    settings.put(
                                        'exophaseSettings', exophaseSettings);
                                  });
                                }),
                          ),
                          //? Filter out PS5 games
                          Tooltip(
                            message: regionalText['exophase']['ps5'],
                            child: InkWell(
                                child: Container(
                                    height: Platform.isWindows ? 50 : 25,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: exophaseSettings['ps5'] != true
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
                                    if (exophaseSettings['ps5'] != true) {
                                      exophaseSettings['ps5'] = true;
                                    } else {
                                      exophaseSettings['ps5'] = false;
                                    }
                                    settings.put(
                                        'exophaseSettings', exophaseSettings);
                                  });
                                }),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 10),
                          //? These let you change the view style for the trophy lists
                          Text(
                            regionalText['exophase']['viewType'],
                            style: textSelection("textDark"),
                            textAlign: TextAlign.center,
                          ),
                          if (exophaseSettings['gamerCard'] != "list")
                            Tooltip(
                              message: regionalText['exophase']['list'],
                              child: InkWell(
                                  child: Icon(Icons.list,
                                      color: themeSelector["primary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 35 : 17),
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onTap: () => {
                                        setState(() {
                                          exophaseSettings['gamerCard'] =
                                              "list";
                                        }),
                                        settings.put('exophaseSettings',
                                            exophaseSettings)
                                      }),
                            ),
                          //? Option to use view trophy lists as a block
                          if (exophaseSettings['gamerCard'] != "block")
                            Tooltip(
                              message: regionalText['exophase']['block'],
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
                                          exophaseSettings['gamerCard'] =
                                              "block";
                                        }),
                                        settings.put('exophaseSettings',
                                            exophaseSettings)
                                      }),
                            ),
                          //? Option to use view trophy lists as a grid
                          if (exophaseSettings['gamerCard'] != "grid")
                            Tooltip(
                              message: regionalText['exophase']['grid'],
                              child: InkWell(
                                  child: Icon(Icons.view_comfy,
                                      color: themeSelector["primary"]
                                          [settings.get("theme")],
                                      size: Platform.isWindows ? 30 : 15),
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onTap: () => {
                                        setState(() {
                                          exophaseSettings['gamerCard'] =
                                              "grid";
                                        }),
                                        settings.put('exophaseSettings',
                                            exophaseSettings)
                                      }),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

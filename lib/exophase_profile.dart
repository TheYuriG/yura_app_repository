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
          print(exophaseGames[i]['gameName'] + " skipped! (PS4)");
          continue;
        } else if (exophaseSettings['zero'] == false &&
            exophaseGames[i]['gamePercentage'] == 0) {
          print(exophaseGames[i]['gameName'] + " skipped! (0%)");
          continue;
        } else if (exophaseSettings['incomplete'] == false &&
            exophaseGames[i]['gamePercentage'] < 100) {
          print(exophaseGames[i]['gameName'] + " skipped! (incomplete)");
          continue;
        } else if (exophaseSettings['complete'] == false &&
            exophaseGames[i]['gamePercentage'] == 100) {
          print(exophaseGames[i]['gameName'] + " skipped! (complete)");
          continue;
        } else if (exophaseSettings['timed'] == true &&
            exophaseGames[i]['gameTime'] == null) {
          print(exophaseGames[i]['gameName'] + " skipped! (no tracked time)");
          continue;
        } else if (exophaseSettings['mustPlatinum'] == true &&
            exophaseGames[i]['gamePlatinum'] == null) {
          print(exophaseGames[i]['gameName'] +
              " skipped! (didn't earn platinum)");
          continue;
        } else if (exophaseSettings['mustNotPlatinum'] == true &&
            exophaseGames[i]['gamePlatinum'] != null) {
          print(exophaseGames[i]['gameName'] + " skipped! (got the platinum)");
          continue;
        } else {
          Container gameDisplay;
          if (exophaseSettings['gamerCard'] == "block") {
          } else if (exophaseSettings['gamerCard'] == "list") {
          } else {
            gameDisplay = Container(
              // width: 150,
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
                      width: 4),
                  boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5)]),
              margin: EdgeInsets.all(5),
              child: Tooltip(
                message: exophaseGames[i]['gameName'] +
                    " (${exophaseGames[i]['gamePercentage'].toString()}%)",
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(7)),
                      child: Image.network(
                        exophaseGames[i]['gameImage'], scale: 0.5,
                        // width: 150,
                      ),
                    ),
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
                          )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        trophyType("total"),
                        SizedBox(width: 5),
                        Text(exophaseGames[i]['gameRatio'],
                            style: textSelection("")),
                      ],
                    ),
                    SizedBox()
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
            centerTitle: true,
            title: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.network(
                    exophaseDump['avatar'] ??
                        "https://i.psnprofiles.com/avatars/m/Gfba90ec21.png",
                    height: 30,
                  ),
                  SizedBox(width: 5),
                  Text(
                    exophaseDump["psnID"],
                    style: textSelection("textLightBold"),
                  ),
                  SizedBox(width: 5),
                  //? Country flag
                  Image.network(
                      "https://raw.githubusercontent.com/hjnilsson/country-flags/master/png100px/${exophaseDump['country']}.png",
                      height: 20),
                ]),
            backgroundColor: themeSelector["primary"][settings.get("theme")],
            //? Back arrow to return to main menu
            leading: InkWell(
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: Icon(
                Icons.arrow_back,
                color: themeSelector["secondary"][settings.get("theme")],
              ),
              onTap: () => Navigator.pop(context),
            ),
            //? actions is replaced by your level and progression.
            actions: [
              Row(
                children: [
                  Image.asset(
                    img['oldLevel'],
                    height: 25,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                      "${exophaseDump['level'].toString()} (${exophaseDump['levelProgress']})",
                      style: textSelection("")),
                  SizedBox(
                    width: 10,
                  )
                ],
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
              Colors.white,
              themeSelector["secondary"][settings.get("theme")],
            ])),
            child: Column(
              children: [
                //? This container contains all the trophy data related to the player
                Container(
                    // height: 150,
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    color: themeSelector['primary'][settings.get('theme')],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            trophyType('platinum',
                                quantity: exophaseDump['platinum']),
                            SizedBox(width: 20),
                            trophyType('gold', quantity: exophaseDump['gold']),
                            SizedBox(width: 20),
                            trophyType('silver',
                                quantity: exophaseDump['silver']),
                            SizedBox(width: 20),
                            trophyType('bronze',
                                quantity: exophaseDump['bronze']),
                            SizedBox(width: 20),
                            trophyType('total',
                                quantity:
                                    "${exophaseDump['total'].toString()}"),
                          ],
                        ),
                        // SizedBox(height: 15),
                        Divider(
                            color: themeSelector['secondary']
                                [settings.get('theme')],
                            thickness: 3),
                        //? Bottom row without avatar, has information about games played,
                        //? completion, gameplay hours, country/world rankings, etc
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
                //? This expanded contains the trophy lists information
                if (exophaseGamesList.length > 0)
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 0,
                          crossAxisCount: settings.get('gamerCard') ??
                                  "gridView" == "gridView"
                              ? (MediaQuery.of(context).size.width / 150)
                                  .floor()
                              : 1),
                      itemCount: exophaseGamesList.length,
                      itemBuilder: (context, index) => exophaseGamesList[index],
                    ),
                  ),
                if (exophaseGamesList.length == 0)
                  Expanded(
                    child: Image.network(
                      "https://pbs.twimg.com/media/EYfO0SfXkAEA3iY.jpg",
                      scale: 0.2,
                    ),
                  ),
                //? This Wrap contains the bottom bar buttons to change settings and display options.
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runAlignment: WrapAlignment.center,
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
                                              width: 5),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Icon(
                                            Icons.check_box_outline_blank,
                                            color: themeSelector["primary"]
                                                [settings.get("theme")],
                                            size: 40)),
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
                                              width: 5),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Icon(Icons.check_box,
                                            color: themeSelector["primary"]
                                                [settings.get("theme")],
                                            size: 40)),
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
                                              width: 5),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Icon(Icons.event_note,
                                            color: themeSelector["primary"]
                                                [settings.get("theme")],
                                            size: 40)),
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
                                                width: 5),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5)),
                                          ),
                                          child: Icon(Icons.timer,
                                              color: themeSelector["primary"]
                                                  [settings.get("theme")],
                                              size: 40)),
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
                              //? Filter out PS Vita games
                              Tooltip(
                                message: regionalText['exophase']['psv'],
                                child: InkWell(
                                    child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: exophaseSettings['psv'] !=
                                                      true
                                                  ? Colors.red
                                                  : Colors.transparent,
                                              width: 5),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child:
                                            Image.asset(img['psv'], width: 40)),
                                    onTap: () {
                                      setState(() {
                                        if (exophaseSettings['psv'] != true) {
                                          exophaseSettings['psv'] = true;
                                        } else {
                                          exophaseSettings['psv'] = false;
                                        }
                                        settings.put('exophaseSettings',
                                            exophaseSettings);
                                      });
                                    }),
                              ),
                              //? Filter out PS3 games
                              Tooltip(
                                message: regionalText['exophase']['ps3'],
                                child: InkWell(
                                    child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: exophaseSettings['ps3'] !=
                                                      true
                                                  ? Colors.red
                                                  : Colors.transparent,
                                              width: 5),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child:
                                            Image.asset(img['ps3'], width: 40)),
                                    onTap: () {
                                      setState(() {
                                        if (exophaseSettings['ps3'] != true) {
                                          exophaseSettings['ps3'] = true;
                                        } else {
                                          exophaseSettings['ps3'] = false;
                                        }
                                        settings.put('exophaseSettings',
                                            exophaseSettings);
                                      });
                                    }),
                              ),
                              //? Filter out PS4 games
                              Tooltip(
                                message: regionalText['exophase']['ps4'],
                                child: InkWell(
                                    child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: exophaseSettings['ps4'] !=
                                                      true
                                                  ? Colors.red
                                                  : Colors.transparent,
                                              width: 5),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child:
                                            Image.asset(img['ps4'], width: 40)),
                                    onTap: () {
                                      setState(() {
                                        if (exophaseSettings['ps4'] != true) {
                                          exophaseSettings['ps4'] = true;
                                        } else {
                                          exophaseSettings['ps4'] = false;
                                        }
                                        settings.put('exophaseSettings',
                                            exophaseSettings);
                                      });
                                    }),
                              ),
                              //? Filter out PS5 games
                              Tooltip(
                                message: regionalText['exophase']['ps5'],
                                child: InkWell(
                                    child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: exophaseSettings['ps5'] !=
                                                      true
                                                  ? Colors.red
                                                  : Colors.transparent,
                                              width: 5),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child:
                                            Image.asset(img['ps5'], width: 40)),
                                    onTap: () {
                                      setState(() {
                                        if (exophaseSettings['ps5'] != true) {
                                          exophaseSettings['ps5'] = true;
                                        } else {
                                          exophaseSettings['ps5'] = false;
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
                                      // height: 50,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color: exophaseSettings[
                                                        'mustPlatinum'] !=
                                                    false
                                                ? Colors.red
                                                : Colors.transparent,
                                            width: 5),
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
                                              size: 35,
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
                                            width: 5),
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
                      // SizedBox(width: 10),
                      // //? These let you change the view style for the trophy lists
                      // Row(
                      //   crossAxisAlignment: CrossAxisAlignment.center,
                      //   mainAxisSize: MainAxisSize.min,
                      //   children: [
                      //     Text(
                      //       regionalText['exophase']['viewType'],
                      //       style: textSelection("textDark"),
                      //       textAlign: TextAlign.center,
                      //     ),
                      //     Row(
                      //       children: [
                      //         //? Option to use view trophy lists as a list
                      //         if (exophaseSettings['gamerCard'] != "list")
                      //           Tooltip(
                      //             message: regionalText['exophase']['list'],
                      //             child: InkWell(
                      //                 child: Icon(Icons.list,
                      //                     color: themeSelector["primary"]
                      //                         [settings.get("theme")],
                      //                     size: 48),
                      //                 hoverColor: Colors.transparent,
                      //                 splashColor: Colors.transparent,
                      //                 onTap: () => {
                      //                       setState(() {
                      //                         exophaseSettings['gamerCard'] =
                      //                             "list";
                      //                       }),
                      //                       settings.put('exophaseSettings',
                      //                           exophaseSettings)
                      //                     }),
                      //           ), //? Option to use view trophy lists as a block
                      //         if (exophaseSettings['gamerCard'] != "block")
                      //           Tooltip(
                      //             message: regionalText['exophase']['block'],
                      //             child: InkWell(
                      //                 child: Icon(
                      //                   Icons.view_compact,
                      //                   color: themeSelector["primary"]
                      //                       [settings.get("theme")],
                      //                   size: 40,
                      //                 ),
                      //                 hoverColor: Colors.transparent,
                      //                 splashColor: Colors.transparent,
                      //                 onTap: () => {
                      //                       setState(() {
                      //                         exophaseSettings['gamerCard'] =
                      //                             "block";
                      //                       }),
                      //                       settings.put('exophaseSettings',
                      //                           exophaseSettings)
                      //                     }),
                      //           ), //? Option to use view trophy lists as a grid
                      //         if (exophaseSettings['gamerCard'] != "grid")
                      //           Tooltip(
                      //             message: regionalText['exophase']['grid'],
                      //             child: InkWell(
                      //                 child: Icon(Icons.view_comfy,
                      //                     color: themeSelector["primary"]
                      //                         [settings.get("theme")],
                      //                     size: 40),
                      //                 hoverColor: Colors.transparent,
                      //                 splashColor: Colors.transparent,
                      //                 onTap: () => {
                      //                       setState(() {
                      //                         exophaseSettings['gamerCard'] =
                      //                             "grid";
                      //                       }),
                      //                       settings.put('exophaseSettings',
                      //                           exophaseSettings)
                      //                     }),
                      //           ),
                      //       ],
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

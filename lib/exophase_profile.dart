import 'main.dart';
import 'package:flutter/material.dart';

class ExophaseProfile extends StatefulWidget {
  ExophaseProfile({Key key}) : super(key: key);
  @override
  _ExophaseProfileState createState() => _ExophaseProfileState();
}

class _ExophaseProfileState extends State<ExophaseProfile> {
  @override
  Widget build(BuildContext context) {
    Map exophaseDump = settings.get('exophaseDump');
    Map exophaseGames = settings.get('exophaseGames');

    List<Widget> fetchExophaseGames() {
      List<Widget> cardAndGames = [];
      for (var i = 1; i < exophaseGames.length; i++) {
        Container gameDisplay;
        if (settings.get('gamerCard') == "bigImage") {
        } else if (settings.get('gamerCard') == "squareImage") {
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
                Container(
                    height: 150,
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
                          padding: EdgeInsets.all(0),
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
                                    padding: const EdgeInsets.all(10.0),
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
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 0,
                        crossAxisCount: settings.get('gamerCard') ??
                                "gridView" == "gridView"
                            ? (MediaQuery.of(context).size.width / 150).floor()
                            : 1),
                    itemCount: exophaseGamesList.length,
                    itemBuilder: (context, index) => exophaseGamesList[index],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

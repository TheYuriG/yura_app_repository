import 'dart:ui';
import 'dart:io' show Platform;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yura_trophy/trophy_list.dart';
import 'main.dart';
import 'package:flutter/material.dart';

class TrophyLog extends StatefulWidget {
  final Map<String, String> trophyData;

  TrophyLog({this.trophyData}) {
    assert(trophyData != null);
  }
  @override
  _TrophyLogState createState() => _TrophyLogState(trophyData);
}

class _TrophyLogState extends State<TrophyLog> {
  Debouncer debounce = Debouncer(milliseconds: 1000);
  //? Stored list of pending trophies
  Map trophyPending = settings.get('trophyPending') ??
      {
        'psnProfiles': {},
        'psnTrophyLeaders': {},
        'exophase': {},
        'trueTrophies': {},
        'psn100': {}
      };
//? Stored list of earned trophies
  Map trophyEarned = settings.get('trophyEarned') ??
      {
        'psnProfiles': {},
        'psnTrophyLeaders': {},
        'exophase': {},
        'trueTrophies': {},
        'psn100': {}
      };

//? These integers will store how many games were filtered and how many are being displayed currently.
  int _displayedTrophies = 0;

  List searchQuery = [];

  //? Sets the settings here to be used throughout the trophy page.
  Map trophyLog = settings.get('trophyLog') ??
      {
        //! Filter options
        "showHidden":
            false, //? This will force secret trophies to not display on the unearned advisor
        //! Trophy rarity filtering
        'prestige': true, //? This will display trophies with rarity 1-%
        'ultraRare': //? This will display trophies with rarity 1% - 5%
            false,
        'veryRare': true, //? This will  display trophies with rarity 5% - 10%
        'rare': true, //? This will  display trophies with rarity 10% - 25%
        'uncommon': true, //? This will  display trophies with rarity 25% - 50%
        'common': true, //? This will display trophies with rarity 50+%
        //! Trophy type filtering
        'platinum': true, //? This will display platinum trophies
        'gold': true, //? This will display gold trophies
        'silver': true, //? This will display silver trophies
        'bronze': true, //? This will display bronze trophies
        //! Platform filtering
        'psv': true, //? This will display trophies from vita games
        'ps3': true, //? This will display trophies from ps3 games
        'ps4': true, //? This will display trophies from ps4 games
        'ps5': true, //? This will display trophies from ps5 games
        //! Settings options
        'type': false, //? This will show the type filtering menu
        'rarity': false, //? This will show the rarity filtering menu
        'platform': false, //? This will show the platform filtering menu
        //! Options menu
        'search': false,
        "filter": false,
        "sort": false,
        "display": false,
        "settings": false,
        //! Display setting
        "trophyDisplay": "grid",
        "sorting":
            "newTimestamp", //? This will sort all trophies by their timestamp, starting with the most recent trophies until the first trophies
      };

  final Map<String, String> trophyData;

  //? Parses trophy list data and returns the trophy list in the proper display mode.
  Widget trophyLogDisplay() {
    Widget listDisplay;
    List trophiesArray = [];

    _displayedTrophies = 0;
    if (trophyData['type'] == 'platinum') {
      trophyLog['platinum'] = true;
      trophyLog['gold'] = false;
      trophyLog['silver'] = false;
      trophyLog['bronze'] = false;
      trophyData['type'] = null;
    } else if (trophyData['type'] == 'gold') {
      trophyLog['platinum'] = false;
      trophyLog['gold'] = true;
      trophyLog['silver'] = false;
      trophyLog['bronze'] = false;
      trophyData['type'] = null;
    } else if (trophyData['type'] == 'silver') {
      trophyLog['platinum'] = false;
      trophyLog['gold'] = false;
      trophyLog['silver'] = true;
      trophyLog['bronze'] = false;
      trophyData['type'] = null;
    } else if (trophyData['type'] == 'bronze') {
      trophyLog['platinum'] = false;
      trophyLog['gold'] = false;
      trophyLog['silver'] = false;
      trophyLog['bronze'] = true;
      trophyData['type'] = null;
    } else if (trophyData['type'] == 'all') {
      trophyLog['platinum'] = true;
      trophyLog['gold'] = true;
      trophyLog['silver'] = true;
      trophyLog['bronze'] = true;
      trophyData['type'] = null;
    }
    //? Stores all the trophy widgets, being them in a List or Grid.
    List<Widget> trophyWidgets = [];

    if (trophyEarned[trophyData['website']] != []) {
      //? Transforms the Map into a List for the sort functions.
      if (trophyData['log'] == "earned") {
        trophyEarned[trophyData['website']].forEach((k, v) {
          v.forEach((key, item) {
            trophiesArray.add(item);
          });
        });
      } else if (trophyData['log'] == "pending") {
        trophyPending[trophyData['website']].forEach((k, v) {
          v.forEach((key, item) {
            trophiesArray.add(item);
          });
        });
      }

      //? Alphabetical sorting in ascending manner (A trophies before Z trophies).
      if (trophyLog['sorting'] == "alphabeticalZ") {
        trophiesArray.sort((a, b) => (a['name'] ?? "")
            .toLowerCase()
            .compareTo((b['name'] ?? "").toLowerCase()));
      }
      //? Alphabetical sorting in descending manner (Z trophies before A trophies).
      else if (trophyLog['sorting'] == "Zalphabetical") {
        trophiesArray.sort((a, b) => (b['name'] ?? "")
            .toLowerCase()
            .compareTo((a['name'] ?? "").toLowerCase()));
      }
      //? Rarity sorting in ascending manner (low % trophies before high % trophies).
      else if (trophyLog['sorting'] == "upRarity") {
        trophiesArray.sort((a, b) => a['rarity'] == b['rarity']
            ? a['timestamp'] > b['timestamp']
                ? 1 //? If two trophies have the same rarity, sort them by earned date
                : -1
            : (a['rarity'] ?? 0) > (b['rarity'] ?? 0)
                ? 1
                : -1);
      }
      //? Rarity sorting in descending manner (high % trophies before low % trophies).
      else if (trophyLog['sorting'] == "downRarity") {
        trophiesArray.sort((a, b) => a['rarity'] == b['rarity']
            ? a['timestamp'] > b['timestamp']
                ? 1 //? If two trophies have the same rarity, sort them by earned date
                : -1
            : (a['rarity'] ?? 0) > (b['rarity'] ?? 0)
                ? -1
                : 1);
      }
      //? Trophy type sorting in descending manner (Platinum > Gold > Silver > Bronze).
      else if (trophyLog['sorting'] == "upType") {
        trophiesArray.sort((a, b) {
          //? Checks the trophy type and returns a value based on that, so that the trophies can be sorted based on their weight.
          int _value(String type) {
            if (type == "platinum") {
              return 4;
            } else if (type == "gold") {
              return 3;
            } else if (type == "silver") {
              return 2;
            } else {
              return 1;
            }
          }

          int trophyA = _value(a['type']);
          int trophyB = _value(b['type']);
          return trophyA == trophyB
              ? a['rarity'] > b['rarity']
                  ? 1
                  : -1
              : trophyA > trophyB
                  ? 1
                  : -1;
        });
      }
      //? Trophy type sorting in descending manner (Platinum > Gold > Silver > Bronze).
      else if (trophyLog['sorting'] == "downType") {
        trophiesArray.sort((a, b) {
          //? Checks the trophy type and returns a value based on that, so that the trophies can be sorted based on their weight.
          int _value(String type) {
            if (type == "platinum") {
              return 4;
            } else if (type == "gold") {
              return 3;
            } else if (type == "silver") {
              return 2;
            } else {
              return 1;
            }
          }

          int trophyA = _value(a['type']);
          int trophyB = _value(b['type']);
          return trophyA == trophyB
              ? a['rarity'] > b['rarity']
                  ? 1
                  : -1
              : trophyA > trophyB
                  ? -1
                  : 1;
        });
      }
      //? Timestamp sorting by oldest trophy first
      else if (trophyLog['sorting'] == "oldTimestamp") {
        trophiesArray.sort((a, b) =>
            (a['timestamp'] ?? 999999999999) > (b['timestamp'] ?? 999999999999)
                ? 1
                : -1);
      }
      //? Timestamp sorting by newest trophy first
      else if (trophyLog['sorting'] == "newTimestamp") {
        trophiesArray.sort((a, b) =>
            (a['timestamp'] ?? 999999999999) > (b['timestamp'] ?? 999999999999)
                ? -1
                : 1);
      }
    }

    for (var i = 0; i < trophiesArray.length; i++) {
      if (
          //? Skip if the user is filtering secret trophies and the trophy is marked as hidden
          (trophyData['log'] == 'pending' &&
                  trophiesArray[i]['hidden'] == true &&
                  trophyLog['showHidden'] == false) ||
              //? Skip if the user is filtering Prestige trophies (1-%)
              (trophiesArray[i]['rarity'] < 1 &&
                  trophyLog['prestige'] == false) ||
              //? Skip if the user is filtering Ultra Rare trophies and the trophy has between 1% and 5%
              (trophiesArray[i]['rarity'] >= 1 &&
                  trophiesArray[i]['rarity'] < 5 &&
                  trophyLog['ultraRare'] == false) ||
              //? Skip if the user is filtering Very Rare trophies and the trophy has between 5% and 10%
              (trophiesArray[i]['rarity'] >= 5 &&
                  trophiesArray[i]['rarity'] < 10 &&
                  trophyLog['veryRare'] == false) ||
              //? Skip if the user is filtering Rare trophies and the trophy has between 10% and 25%
              (trophiesArray[i]['rarity'] >= 10 &&
                  trophiesArray[i]['rarity'] < 25 &&
                  trophyLog['rare'] == false) ||
              //? Skip if the user is filtering Uncommon trophies and the trophy has between 25% and 50%
              (trophiesArray[i]['rarity'] >= 25 &&
                  trophiesArray[i]['rarity'] < 50 &&
                  trophyLog['uncommon'] == false) ||
              //? Skip if the user is filtering Common trophies and the trophy has more than 50% rarity
              (trophiesArray[i]['rarity'] >= 50 &&
                  trophyLog['common'] == false) ||
              //? Skip if the user is filtering platinum trophies
              (trophiesArray[i]['type'] == 'platinum' &&
                  trophyLog['platinum'] == false) ||
              //? Skip if the user is filtering gold trophies
              (trophiesArray[i]['type'] == 'gold' &&
                  trophyLog['gold'] == false) ||
              //? Skip if the user is filtering silver trophies
              (trophiesArray[i]['type'] == 'silver' &&
                  trophyLog['silver'] == false) ||
              //? Skip if the user is filtering bronze trophies
              (trophiesArray[i]['type'] == 'bronze' &&
                  trophyLog['bronze'] == false)) {
        continue;
      }

      //? Platform filtering
      int shouldDisplay = 0;
      if (trophiesArray[i]['gameData']['gameVita'] == true &&
          trophyLog['psv'] == true) {
        // print('psv trophy');
        shouldDisplay++;
      }
      if (trophiesArray[i]['gameData']['gamePS3'] == true &&
          trophyLog['ps3'] == true) {
        // print('ps3 trophy');
        shouldDisplay++;
      }
      if (trophiesArray[i]['gameData']['gamePS4'] == true &&
          trophyLog['ps4'] == true) {
        // print('ps4 trophy');
        shouldDisplay++;
      }
      if (trophiesArray[i]['gameData']['gamePS5'] == true &&
          trophyLog['ps5'] == true) {
        // print('ps5 trophy');
        shouldDisplay++;
      }
      if (shouldDisplay == 0) {
        continue;
      }

      //? This will filter out trophies based on search criteria
      if (searchQuery.length > 0) {
        int o = 0;
        searchQuery.forEach((searchWord) {
          if (trophiesArray[i]['name'].toLowerCase().contains(searchWord)) {
            o++;
          }
        });
        if (o != searchQuery.length) {
          continue;
        }
      }

//! TODO finish the data processing for this
      // Map<String, int> counters = {
      //   'prestige': 0,
      //   'ultraRare': 0,
      //   'veryRare': 0,
      //   'rare': 0,
      //   'uncommon': 0,
      //   'common': 0,
      //   'platinum': 0,
      //   'gold': 0,
      //   'silver': 0,
      //   'bronze': 0
      // };

      // //? Tracks if this strophy is prestige
      // if (trophiesArray[i]['rarity'] < 1) {
      //   counters['prestige']++;
      // }
      // //? Tracks if this strophy is ultra rare
      // else if (trophiesArray[i]['rarity'] >= 1 &&
      //     trophiesArray[i]['rarity'] < 5) {
      //   counters['ultraRare']++;
      // }
      // //? Tracks if this strophy is very rare
      // else if (trophiesArray[i]['rarity'] >= 5 &&
      //     trophiesArray[i]['rarity'] < 10) {
      //   counters['veryRare']++;
      // }
      // //? Tracks if this strophy is rare
      // else if (trophiesArray[i]['rarity'] >= 10 &&
      //     trophiesArray[i]['rarity'] < 25) {
      //   counters['rare']++;
      // }
      // //? Tracks if this strophy is uncommon
      // else if (trophiesArray[i]['rarity'] >= 25 &&
      //     trophiesArray[i]['rarity'] < 50) {
      //   counters['uncommon']++;
      // }
      // //? Tracks if this strophy is common
      // else if (trophiesArray[i]['rarity'] >= 50) {
      //   counters['common']++;
      // }
      // //? Tracks if this strophy is a platinum
      // if (trophiesArray[i]['type'] == 'platinum') {
      //   counters['platinum']++;
      // }
      // //? Tracks if this strophy is gold
      // else if (trophiesArray[i]['type'] == 'gold') {
      //   counters['gold']++;
      // }
      // //? Tracks if this strophy is silver
      // else if (trophiesArray[i]['type'] == 'silver') {
      //   counters['silver']++;
      // }
      // //? Tracks if this strophy is bronze
      // else if (trophiesArray[i]['type'] == 'bronze') {
      //   counters['bronze']++;
      // }

      _displayedTrophies++;
      if (trophyLog['trophyDisplay'] == "grid") {
        trophyWidgets.add(InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return TrophyList(trophyListData: trophiesArray[i]['gameData']);
            }),
          ),
          child: Tooltip(
            message:
                '${trophiesArray[i]['name']} (${trophiesArray[i]['rarity']}%)',
            child: Container(
              margin: EdgeInsets.all(Platform.isWindows ? 2 : 0.5),
              decoration: BoxDecoration(
                  color: themeSelector["primary"][settings.get("theme")]
                      .withOpacity(0.8),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  border: Border.all(
                      width: Platform.isWindows ? 5 : 3,
                      color: trophiesArray[i]['timestamp'] != null
                          ? Colors.green
                          : Colors.red)),
              height: Platform.isWindows ? 80 : 50,
              width: Platform.isWindows ? 80 : 50,
              child: CachedNetworkImage(
                  imageUrl: trophiesArray[i]['image'], fit: BoxFit.fill),
            ),
          ),
        ));
      } else if (trophyLog['trophyDisplay'] == "list") {
        trophyWidgets.add(Container(
            margin: EdgeInsets.symmetric(
                vertical: Platform.isWindows ? 1 : 0.5,
                horizontal: Platform.isWindows ? 5 : 3),
            decoration: BoxDecoration(
                color: themeSelector["primary"][settings.get("theme")]
                    .withOpacity(0.8),
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border.all(
                    width: Platform.isWindows ? 5 : 3,
                    color: trophiesArray[i]['timestamp'] != null
                        ? Colors.green
                        : Colors.red)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                //? Trophy image
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return TrophyList(
                          trophyListData: trophiesArray[i]['gameData']);
                    }),
                  ),
                  child: Container(
                    height: Platform.isWindows ? 85 : 60,
                    width: Platform.isWindows ? 85 : 60,
                    child: CachedNetworkImage(
                      fit: BoxFit.fill,
                      imageUrl: trophiesArray[i]['image'],
                    ),
                  ),
                ),
                //? Column with trophy type, name, rarity, exp + description + earned timestamp
                Container(
                  width: MediaQuery.of(context).size.width -
                      (Platform.isWindows ? 260 : 80),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.all(Platform.isWindows ? 10.0 : 5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //? Trophy type, name, rarity, exp
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              //? Trophy type
                              trophyType(trophiesArray[i]['type'],
                                  size: "small"),
                              SizedBox(width: 3),
                              //? Trophy name
                              Text(
                                trophiesArray[i]['name'],
                                style: textSelection(theme: "textLightBold"),
                                textAlign: TextAlign.left,
                              ),
                              //? Trophy rarity, if avaiable
                              if (trophiesArray[i]['rarity'] != null)
                                Text(
                                  " (${trophiesArray[i]['rarity']}%)",
                                  style: textSelection(theme: "textLightBold"),
                                  textAlign: TextAlign.left,
                                ),
                              //? Trophy EXP for exophase
                              if (trophiesArray[i]['exp'] != null)
                                Row(
                                  children: [
                                    SizedBox(width: 3),
                                    CachedNetworkImage(
                                        imageUrl:
                                            "https://www.exophase.com/assets/zeal/_icons/favicon.ico",
                                        height: Platform.isWindows ? 15 : 10),
                                    Text(
                                      " ${trophiesArray[i]['exp']}",
                                      style:
                                          textSelection(theme: "textLightBold"),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          //? Trophy description
                          Container(
                            child: Text(
                              trophiesArray[i]['description'],
                              style: textSelection(),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          //? Trophy timestamp
                          if (trophiesArray[i]['timestamp'] != null)
                            Container(
                              child: Text(
                                trophiesArray[i]['parsedTimestamp'].toString(),
                                style: textSelection(),
                                textAlign: TextAlign.left,
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: SizedBox()),
                if (Platform.isWindows)
                  Tooltip(
                    message:
                        "${trophiesArray[i]['gameData']['gameName']} (${trophiesArray[i]['gameData']['gamePercentage'].toString()}%)",
                    child: Container(
                      height: Platform.isWindows ? 85 : 60,
                      child: CachedNetworkImage(
                        fit: BoxFit.fitHeight,
                        imageUrl: trophiesArray[i]['gameData']['gameImage'],
                      ),
                    ),
                  )
              ],
            )));
      }
    }

    //? Properly contains all trophy data inside it's proper viewMode
    if (trophyLog['trophyDisplay'] == "grid") {
      listDisplay = SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          children: trophyWidgets,
        ),
      );
    } else if (trophyLog['trophyDisplay'] == "list") {
      listDisplay = Container(
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          itemCount: trophyWidgets.length,
          itemBuilder: (context, index) => trophyWidgets[index],
        ),
      );
    }
    return
        // Column(      children: [
        //! TODO add 2 containers here which will process the counters created above
        listDisplay
        // ,      ],    )
        ;
  }

  //? This boolean stores if the update has started or not.
  bool updateStart = false;

  _TrophyLogState(this.trophyData);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Container(
        decoration: backgroundDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //? This contains all trophy data, including the top banner and the trophy list.
            Container(
              child: Expanded(child: trophyLogDisplay()),
            ),
            //? This is the bottom bar containing the filters and sorting options for the trophy list.
            Container(
              width: MediaQuery.of(context).size.width,
              padding:
                  EdgeInsets.symmetric(vertical: Platform.isWindows ? 5 : 3),
              color: themeSelector["secondary"][settings.get("theme")],
              child: Column(
                children: [
                  //? This Row lets you search for specific games.
                  if (trophyLog['search'] == true)
                    Container(
                      padding: EdgeInsets.all(5),
                      height: 30,
                      width: MediaQuery.of(context).size.width / 2.5,
                      child: TextFormField(
                          decoration: InputDecoration(
                              hintText: regionalText['log']['searchText'],
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
                    ), //? Filter trophies by their type
                  if (trophyLog['type'] == true)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            regionalText['log']['type'],
                            style: textSelection(theme: "textDark"),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //? Filter Platinum trophies
                            Tooltip(
                              message: regionalText['log']['platinum'],
                              child: InkWell(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['platinum'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          trophyType('platinum', size: 'big'),
                                          if (trophyLog['platinum'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 30 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['platinum'] != true) {
                                        trophyLog['platinum'] = true;
                                      } else {
                                        trophyLog['platinum'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                            //? Filter Gold trophies
                            Tooltip(
                              message: regionalText['log']['gold'],
                              child: InkWell(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['gold'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          trophyType('gold', size: 'big'),
                                          if (trophyLog['gold'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 30 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['gold'] != true) {
                                        trophyLog['gold'] = true;
                                      } else {
                                        trophyLog['gold'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                            //? Filter Silver trophies
                            Tooltip(
                              message: regionalText['log']['silver'],
                              child: InkWell(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['silver'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          trophyType('silver', size: 'big'),
                                          if (trophyLog['silver'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 30 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['silver'] != true) {
                                        trophyLog['silver'] = true;
                                      } else {
                                        trophyLog['silver'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                            //? Filter Bronze trophies
                            Tooltip(
                              message: regionalText['log']['bronze'],
                              child: InkWell(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['bronze'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          trophyType('bronze', size: 'big'),
                                          if (trophyLog['bronze'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 30 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['bronze'] != true) {
                                        trophyLog['bronze'] = true;
                                      } else {
                                        trophyLog['bronze'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  //? Filter trophies by their rarity
                  if (trophyLog['rarity'] == true)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            regionalText['log']['rarity'],
                            style: textSelection(theme: "textDark"),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //? Filter prestige trophies
                            Tooltip(
                              message: regionalText['log']['prestige'],
                              child: InkWell(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['prestige'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Image.asset(
                                            img['rarity7'],
                                            fit: BoxFit.fitHeight,
                                            height:
                                                Platform.isWindows ? 35 : 17,
                                          ),
                                          if (trophyLog['prestige'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 35 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['prestige'] != true) {
                                        trophyLog['prestige'] = true;
                                      } else {
                                        trophyLog['prestige'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                            //? Filter ultra rare trophies
                            Tooltip(
                              message: regionalText['log']['ultraRare'],
                              child: InkWell(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['ultraRare'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Image.asset(
                                            img['rarity6'],
                                            fit: BoxFit.fitHeight,
                                            height:
                                                Platform.isWindows ? 35 : 17,
                                          ),
                                          if (trophyLog['ultraRare'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 35 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['ultraRare'] != true) {
                                        trophyLog['ultraRare'] = true;
                                      } else {
                                        trophyLog['ultraRare'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                            //? Filter very rare trophies
                            Tooltip(
                              message: regionalText['log']['veryRare'],
                              child: InkWell(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['veryRare'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Image.asset(
                                            img['rarity5'],
                                            fit: BoxFit.fitHeight,
                                            height:
                                                Platform.isWindows ? 35 : 17,
                                          ),
                                          if (trophyLog['veryRare'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 35 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['veryRare'] != true) {
                                        trophyLog['veryRare'] = true;
                                      } else {
                                        trophyLog['veryRare'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                            //? Filter rare trophies
                            Tooltip(
                              message: regionalText['log']['rare'],
                              child: InkWell(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['rare'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Image.asset(
                                            img['rarity4'],
                                            fit: BoxFit.fitHeight,
                                            height:
                                                Platform.isWindows ? 35 : 17,
                                          ),
                                          if (trophyLog['rare'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 35 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['rare'] != true) {
                                        trophyLog['rare'] = true;
                                      } else {
                                        trophyLog['rare'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                            //? Filter uncommon trophies
                            Tooltip(
                              message: regionalText['log']['uncommon'],
                              child: InkWell(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['uncommon'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Image.asset(
                                            img['rarity3'],
                                            fit: BoxFit.fitHeight,
                                            height:
                                                Platform.isWindows ? 35 : 17,
                                          ),
                                          if (trophyLog['uncommon'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 35 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['uncommon'] != true) {
                                        trophyLog['uncommon'] = true;
                                      } else {
                                        trophyLog['uncommon'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                            //? Filter common trophies
                            Tooltip(
                              message: regionalText['log']['common'],
                              child: InkWell(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['common'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Image.asset(
                                            img['rarity1'],
                                            fit: BoxFit.fitHeight,
                                            height:
                                                Platform.isWindows ? 35 : 17,
                                          ),
                                          if (trophyLog['common'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 35 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['common'] != true) {
                                        trophyLog['common'] = true;
                                      } else {
                                        trophyLog['common'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  //? Filter trophies by their platform
                  if (trophyLog['platform'] == true)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            regionalText['log']['platform'],
                            style: textSelection(theme: "textDark"),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //? Filter Vita trophies
                            Tooltip(
                              message: regionalText['log']['psv'],
                              child: InkWell(
                                  child: Container(
                                    height: Platform.isWindows ? 40 : 17,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['psv'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Image.asset(
                                            img['psv'],
                                            fit: BoxFit.fitHeight,
                                            width: Platform.isWindows ? 35 : 17,
                                          ),
                                          if (trophyLog['psv'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 30 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['psv'] != true) {
                                        trophyLog['psv'] = true;
                                      } else {
                                        trophyLog['psv'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                            //? Filter PS3 trophies
                            Tooltip(
                              message: regionalText['log']['ps3'],
                              child: InkWell(
                                  child: Container(
                                    height: Platform.isWindows ? 40 : 17,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['ps3'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Image.asset(
                                            img['ps3'],
                                            fit: BoxFit.fitHeight,
                                            width: Platform.isWindows ? 35 : 17,
                                          ),
                                          if (trophyLog['ps3'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 30 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['ps3'] != true) {
                                        trophyLog['ps3'] = true;
                                      } else {
                                        trophyLog['ps3'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                            //? Filter PS4 trophies
                            Tooltip(
                              message: regionalText['log']['ps4'],
                              child: InkWell(
                                  child: Container(
                                    height: Platform.isWindows ? 40 : 17,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['ps4'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Image.asset(
                                            img['ps4'],
                                            fit: BoxFit.fitHeight,
                                            width: Platform.isWindows ? 35 : 17,
                                          ),
                                          if (trophyLog['ps4'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 30 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['ps4'] != true) {
                                        trophyLog['ps4'] = true;
                                      } else {
                                        trophyLog['ps4'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                            //? Filter PS5 trophies
                            Tooltip(
                              message: regionalText['log']['ps5'],
                              child: InkWell(
                                  child: Container(
                                    height: Platform.isWindows ? 40 : 17,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color: trophyLog['ps5'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Stack(
                                        alignment: AlignmentDirectional.center,
                                        children: [
                                          Image.asset(
                                            img['ps5'],
                                            fit: BoxFit.fitHeight,
                                            width: Platform.isWindows ? 35 : 17,
                                          ),
                                          if (trophyLog['ps5'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 30 : 17,
                                            )
                                        ]),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['ps5'] != true) {
                                        trophyLog['ps5'] = true;
                                      } else {
                                        trophyLog['ps5'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  //? This Row lets you sort trophies in a specific order.
                  if (trophyLog['sort'] == true)
                    Container(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Text(
                                regionalText['trophies']['sort'],
                                style: textSelection(theme: "textDark"),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 3),
                                //? Sort trophies by trophy value (platinum > gold > silver > bronze)
                                Tooltip(
                                  message: regionalText['trophies']['value'],
                                  child: InkWell(
                                    child: Container(
                                      alignment: Alignment.center,
                                      // height: Platform.isWindows ? 35 : 17,
                                      // width: Platform.isWindows ? 35 : 17,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        //? If it's false or null (never set), we will paint red.
                                        border: Border.all(
                                            color: trophyLog['sorting']
                                                    .contains('Type')
                                                ? Colors.green
                                                : Colors.transparent,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: trophyType(
                                          trophyLog['sorting'] != "upType"
                                              ? "platinum"
                                              : 'bronze',
                                          size: "big"),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (trophyLog['sorting'] !=
                                            "downType") {
                                          trophyLog['sorting'] = "downType";
                                        } else {
                                          trophyLog['sorting'] = "upType";
                                        }
                                      });
                                    },
                                  ),
                                ),

                                SizedBox(width: 3),
                                //? Sort trophies by ascending Alphabetical (A to Z)
                                Tooltip(
                                  message: regionalText['trophies']
                                      ['alphabetical'],
                                  child: InkWell(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        border: Border.all(
                                            color: trophyLog['sorting']
                                                    .contains('alphabetical')
                                                ? Colors.green
                                                : Colors.transparent,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: Text(
                                        trophyLog['sorting'] != "Zalphabetical"
                                            ? "ABC"
                                            : "ZYX",
                                        style: textSelection(theme: "textDark"),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (trophyLog['sorting'] !=
                                            "alphabeticalZ") {
                                          trophyLog['sorting'] =
                                              "alphabeticalZ"; //? A to Z sorting
                                        } else {
                                          trophyLog['sorting'] =
                                              "Zalphabetical"; //? Z to A sorting
                                        }
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 3),
                                //? Sort games by descending Alphabetical (Z to A)
                                Tooltip(
                                  message: regionalText['trophies']['rarity'],
                                  child: InkWell(
                                    child: Container(
                                      height: Platform.isWindows ? 35 : 17,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        border: Border.all(
                                            color: trophyLog['sorting']
                                                    .contains('Rarity')
                                                ? Colors.green
                                                : Colors.transparent,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: Image.asset(
                                        img[trophyLog['sorting'] == "downRarity"
                                            ? 'rarity1'
                                            : 'rarity7'],
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (trophyLog['sorting'] !=
                                            "upRarity") {
                                          trophyLog['sorting'] = "upRarity";
                                        } else {
                                          trophyLog['sorting'] = "downRarity";
                                        }
                                      });
                                    },
                                  ),
                                ),
                                //? Sort trophies by earned timestamp
                                if (trophyData['log'] == "earned")
                                  Tooltip(
                                    message: regionalText['trophies']
                                        ['earnedTimestamp'],
                                    child: Container(
                                      width: Platform.isWindows ? 35 : 17,
                                      decoration: BoxDecoration(
                                        //? To paint the border, we check the value of the settings for this website is true.
                                        border: Border.all(
                                            color: trophyLog['sorting']
                                                    .contains('Timestamp')
                                                ? Colors.green
                                                : Colors.transparent,
                                            width: Platform.isWindows ? 5 : 2),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: InkWell(
                                        child: Text(
                                          trophyLog['sorting'] != "oldTimestamp"
                                              ? "🆕"
                                              : "⌛",
                                          textAlign: TextAlign.center,
                                          style: textSelection(
                                              theme: "textLightBold"),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            if (trophyLog['sorting'] !=
                                                "newTimestamp") {
                                              trophyLog['sorting'] =
                                                  "newTimestamp";
                                            } else {
                                              trophyLog['sorting'] =
                                                  "oldTimestamp";
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  //? This Row lets you filter in and out specific types of trophies.
                  if (trophyLog['settings'] == true)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            regionalText['trophies']['settings'],
                            style: textSelection(theme: "textDark"),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: regionalText['trophies'][
                                  trophyData['log'] != 'earned'
                                      ? 'earned'
                                      : 'unearned'],
                              child: InkWell(
                                  child: Container(
                                      decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color:
                                                  trophyData['log'] == 'earned'
                                                      ? Colors.green
                                                      : Colors.red,
                                              width:
                                                  Platform.isWindows ? 5 : 2)),
                                      child: Icon(
                                          trophyData['log'] == 'earned'
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          color: themeSelector["primary"]
                                              [settings.get("theme")],
                                          size: Platform.isWindows ? 35 : 17)),
                                  onTap: () {
                                    setState(() {
                                      if (trophyData['log'] == 'earned') {
                                        trophyData['log'] = 'pending';
                                      } else {
                                        trophyData['log'] = 'earned';
                                      }
                                    });
                                    settings.put('trophyLog', trophyLog);
                                  }),
                            ),

                            //? Filter hidden trophies
                            if (trophyData['log'] == "pending")
                              Tooltip(
                                message: regionalText['trophies']['hidden'],
                                child: InkWell(
                                    child: Container(
                                        decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: trophyLog['showHidden'] !=
                                                      true
                                                  ? Colors.red
                                                  : Colors.green,
                                              width:
                                                  Platform.isWindows ? 5 : 2),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                        child: Icon(
                                            trophyLog['showHidden'] != true
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: themeSelector["primary"]
                                                [settings.get("theme")],
                                            size:
                                                Platform.isWindows ? 35 : 17)),
                                    onTap: () {
                                      setState(() {
                                        if (trophyLog['showHidden'] != true) {
                                          trophyLog['showHidden'] = true;
                                        } else {
                                          trophyLog['showHidden'] = false;
                                        }
                                        settings.put('trophyLog', trophyLog);
                                      });
                                    }),
                              ),
                            Tooltip(
                              message: regionalText['trophies']['localization'],
                              child: InkWell(
                                  child: Container(
                                    // height: 40,
                                    // height: Platform.isWindows ? 50 : 25,
                                    decoration: BoxDecoration(
                                      //? To paint the border, we check the value of the settings for this website is true.
                                      //? If it's false or null (never set), we will paint red.
                                      border: Border.all(
                                          color:
                                              trophyLog['localization'] == true
                                                  ? Colors.green
                                                  : Colors.red,
                                          width: Platform.isWindows ? 5 : 2),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Icon(Icons.public,
                                        color: themeSelector["primary"]
                                            [settings.get("theme")],
                                        size: Platform.isWindows ? 35 : 17),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['localization'] != true) {
                                        trophyLog['localization'] = true;
                                      } else {
                                        trophyLog['localization'] = false;
                                      }
                                      settings.put('trophyLog', trophyLog);
                                    });
                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  //? This Row lets you change the view style for the trophy lists
                  if (trophyLog['display'] == true)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 10),
                        Text(
                          regionalText['trophies']['display'],
                          style: textSelection(theme: "textDark"),
                          textAlign: TextAlign.center,
                        ),
                        //? Option to use view trophy lists as a list
                        if (trophyLog['trophyDisplay'] != "list")
                          Tooltip(
                            message: regionalText['trophies']['list'],
                            child: InkWell(
                                child: Icon(Icons.list,
                                    color: themeSelector["primary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 35 : 17),
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                onTap: () => {
                                      setState(() {
                                        trophyLog['trophyDisplay'] = "list";
                                      }),
                                      settings.put('trophyLog', trophyLog)
                                    }),
                          ),
                        //? Option to use view trophy lists as a grid
                        if (trophyLog['trophyDisplay'] != "grid")
                          Tooltip(
                            message: regionalText['trophies']['grid'],
                            child: InkWell(
                                child: Icon(Icons.view_comfy,
                                    color: themeSelector["primary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 35 : 17),
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                onTap: () => {
                                      setState(() {
                                        trophyLog['trophyDisplay'] = "grid";
                                      }),
                                      settings.put('trophyLog', trophyLog)
                                    }),
                          ),
                      ],
                    ),
                  //? This Row contains the toggles to display the items above
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        regionalText['trophies']['options'],
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
                                    color: trophyLog['search'] != true
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
                                    if (trophyLog['search'] != true) {
                                      trophyLog['search'] = true;
                                    } else {
                                      trophyLog['search'] = false;
                                      searchQuery = [];
                                    }
                                  }),
                                  settings.put('trophyLog', trophyLog)
                                }),
                      ),

                      //? Trophy type filter
                      Tooltip(
                        message: regionalText['log']['type'],
                        child: InkWell(
                            child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  border: Border.all(
                                      color: trophyLog['type'] != true
                                          ? Colors.transparent
                                          : Colors.green,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: trophyType("platinum", size: "big")),
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () => {
                                  setState(() {
                                    if (trophyLog['type'] != true) {
                                      trophyLog['type'] = true;
                                      trophyLog['rarity'] = false;
                                      trophyLog['platform'] = false;
                                      trophyLog['sort'] = false;
                                      trophyLog['settings'] = false;
                                      trophyLog['display'] = false;
                                    } else {
                                      trophyLog['type'] = false;
                                    }
                                  }),
                                  settings.put('trophyLog', trophyLog)
                                }),
                      ),
                      //? Trophy rarity filter
                      Tooltip(
                        message: regionalText['trophies']['rarity'],
                        child: InkWell(
                            child: Container(
                              decoration: BoxDecoration(
                                //? To paint the border, we check the value of the settings for this website is true.
                                //? If it's false or null (never set), we will paint red.
                                border: Border.all(
                                    color: trophyLog['rarity'] != true
                                        ? Colors.transparent
                                        : Colors.green,
                                    width: Platform.isWindows ? 5 : 2),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                              ),
                              child: Image.asset(
                                img['rarity7'],
                                fit: BoxFit.cover,
                                height: Platform.isWindows ? 30 : 17,
                              ),
                            ),
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () => {
                                  setState(() {
                                    if (trophyLog['rarity'] != true) {
                                      trophyLog['type'] = false;
                                      trophyLog['rarity'] = true;
                                      trophyLog['platform'] = false;
                                      trophyLog['sort'] = false;
                                      trophyLog['settings'] = false;
                                      trophyLog['display'] = false;
                                    } else {
                                      trophyLog['rarity'] = false;
                                    }
                                  }),
                                  settings.put('trophyLog', trophyLog)
                                }),
                      ),
                      //? Platform filter
                      Tooltip(
                        message: regionalText['log']['platform'],
                        child: InkWell(
                            child: Container(
                              height: Platform.isWindows ? 40 : 17,
                              decoration: BoxDecoration(
                                //? To paint the border, we check the value of the settings for this website is true.
                                //? If it's false or null (never set), we will paint red.
                                border: Border.all(
                                    color: trophyLog['platform'] == true
                                        ? Colors.green
                                        : Colors.transparent,
                                    width: Platform.isWindows ? 5 : 2),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                              ),
                              child: Image.asset(
                                img['ps5'],
                                fit: BoxFit.fitWidth,
                                width: Platform.isWindows ? 35 : 17,
                              ),
                            ),
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () => {
                                  setState(() {
                                    if (trophyLog['platform'] != true) {
                                      trophyLog['type'] = false;
                                      trophyLog['rarity'] = false;
                                      trophyLog['platform'] = true;
                                      trophyLog['sort'] = false;
                                      trophyLog['settings'] = false;
                                      trophyLog['display'] = false;
                                    } else {
                                      trophyLog['platform'] = false;
                                    }
                                  }),
                                  settings.put('trophyLog', trophyLog)
                                }),
                      ),
                      //? Sorting
                      Tooltip(
                        message: regionalText['trophies']['sort'],
                        child: InkWell(
                            child: Container(
                              decoration: BoxDecoration(
                                //? To paint the border, we check the value of the settings for this website is true.
                                //? If it's false or null (never set), we will paint red.
                                border: Border.all(
                                    color: trophyLog['sort'] != true
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
                                    if (trophyLog['sort'] != true) {
                                      trophyLog['type'] = false;
                                      trophyLog['rarity'] = false;
                                      trophyLog['platform'] = false;
                                      trophyLog['sort'] = true;
                                      trophyLog['settings'] = false;
                                      trophyLog['display'] = false;
                                    } else {
                                      trophyLog['sort'] = false;
                                    }
                                  }),
                                  settings.put('trophyLog', trophyLog)
                                }),
                      ),
                      //? Settings
                      Tooltip(
                        message: regionalText['trophies']['settings'],
                        child: InkWell(
                            child: Container(
                              decoration: BoxDecoration(
                                //? To paint the border, we check the value of the settings for this website is true.
                                //? If it's false or null (never set), we will paint red.
                                border: Border.all(
                                    color: trophyLog['settings'] != true
                                        ? Colors.transparent
                                        : Colors.green,
                                    width: Platform.isWindows ? 5 : 2),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                              ),
                              child: Icon(Icons.settings,
                                  color: themeSelector["primary"]
                                      [settings.get("theme")],
                                  size: Platform.isWindows ? 30 : 17),
                            ),
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () => {
                                  setState(() {
                                    if (trophyLog['settings'] != true) {
                                      trophyLog['type'] = false;
                                      trophyLog['rarity'] = false;
                                      trophyLog['platform'] = false;
                                      trophyLog['sort'] = false;
                                      trophyLog['settings'] = true;
                                      trophyLog['display'] = false;
                                    } else {
                                      trophyLog['settings'] = false;
                                    }
                                  }),
                                  settings.put('trophyLog', trophyLog)
                                }),
                      ),
                      //? Display
                      Tooltip(
                        message: regionalText['trophies']['display'],
                        child: InkWell(
                            child: Container(
                              decoration: BoxDecoration(
                                //? To paint the border, we check the value of the settings for this website is true.
                                //? If it's false or null (never set), we will paint red.
                                border: Border.all(
                                    color: trophyLog['display'] != true
                                        ? Colors.transparent
                                        : Colors.green,
                                    width: Platform.isWindows ? 5 : 2),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                              ),
                              child: Icon(
                                  trophyLog['trophyDisplay'] == "list"
                                      ? Icons.list
                                      : trophyLog['trophyDisplay'] == "minimal"
                                          ? Icons.more_vert
                                          : Icons.view_comfy,
                                  color: themeSelector["primary"]
                                      [settings.get("theme")],
                                  size: Platform.isWindows ? 30 : 17),
                            ),
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () => {
                                  setState(() {
                                    if (trophyLog['display'] != true) {
                                      trophyLog['type'] = false;
                                      trophyLog['rarity'] = false;
                                      trophyLog['platform'] = false;
                                      trophyLog['sort'] = false;
                                      trophyLog['settings'] = false;
                                      trophyLog['display'] = true;
                                    } else {
                                      trophyLog['display'] = false;
                                    }
                                  }),
                                  settings.put('trophyLog', trophyLog)
                                }),
                      ),
                      SizedBox(width: 5),
                      //? Reset settings button
                      Tooltip(
                        message: regionalText['home']['undo'],
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              trophyLog = {
                                "showHidden": trophyLog['showHidden'],
                                'prestige': true,
                                'ultraRare': true,
                                'veryRare': true,
                                'rare': true,
                                'uncommon': true,
                                'common': true,
                                'platinum': true,
                                'gold': true,
                                'silver': true,
                                'bronze': true,
                                'psv': true,
                                'ps3': true,
                                'ps4': true,
                                'ps5': true,
                                "sorting": "newTimestamp",
                                "trophyDisplay": trophyLog['trophyDisplay'],
                                'search': false,
                                'type': false,
                                'rarity': false,
                                'platform': false,
                                "filter": false,
                                "sort": false,
                                "settings": false,
                                "display": false,
                              };

                              searchQuery = [];
                            });
                            settings.put('trophyLog', trophyLog);
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        titleSpacing: 0,
        toolbarHeight: 40,
        centerTitle: true,
        backgroundColor: themeSelector["primary"][settings.get("theme")],
        title: Text(
          regionalText['log'][trophyData['log'] == 'earned'
                      ? 'earnedTitle'
                      : 'unearnedTitle']
                  .replaceAll("PSNID", settings.get('psnID')) +
              " ($_displayedTrophies)",
          style: textSelection(theme: "textLightBold"),
        ),
      ),
    ));
  }
}

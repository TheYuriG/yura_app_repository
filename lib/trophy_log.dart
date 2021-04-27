import 'dart:ui';
import 'dart:io' show Platform;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:yura_trophy/pull_all_trophies.dart';
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
  //? Initializes the data set
  final Map<String, String> trophyData;

  //? The Debouncer (class created above) is now instantiated here so the search is delayed until the user stops typing.
  Debouncer debounce = Debouncer(milliseconds: 1000);
  //? Another debouncer to close the menus after 20 seconds
  Debouncer menuCloser = Debouncer(milliseconds: 15000);

  //? These integers will store how many games were filtered and how many are being displayed currently.
  int _displayedTrophies = 0;

  List searchQuery = [];

  //? Sets the settings here to be used throughout the trophy page.
  Map trophyLog = settings.get('trophyLog') ??
      {
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
        //! Display setting
        "trophyDisplay": "grid", //? Display trophies in a grid-like manner.
        "showHidden": false, //? Hide secret trophies from trophy advisor
        "DLC": true, //? Show DLC trophies
        "sorting":
            "newTimestamp", //? This will sort all trophies by their timestamp, starting with the most recent trophies until the first trophies
      };
  Map openMenus = {
    //! Settings options
    'type': false, //? This will show the type filtering menu
    'rarity': false, //? This will show the rarity filtering menu
    'platform': false, //? This will show the platform filtering menu
    //! Options menu
    'search': false,
    "filter": false,
    'date': false,
    "sort": false,
    "display": false,
    "settings": false,
  };

  //? These variables are declared here so they can be populated inside trophyLogDisplay()
  //? After being populated, they can then be passed to another page or used outside of the function.
  //? Counters tracks the trophy type distribution and trophy rarity distribution.
  Map<String, int> counters;
  //? Times tracks the distribution of trophies over time, accross days, months, years, etc.
  Map<String, Map<String, int>> times;

  //? These variables will store the date options for the date filtering menu, so you can only select options with avaiable trophies
  List<int> days;
  List<int> months;
  List<int> years;
  List<int> hours;
  List<int> minutes;

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

    //? Transforms the Map into a List for the sort functions.
    if (trophyData['log'] == "earned") {
      //? Stored list of earned trophies
      Map trophyEarned = settings.get('trophyEarned') ??
          {
            'psnProfiles': {},
            'psnTrophyLeaders': {},
            'exophase': {},
            'trueTrophies': {},
            'psn100': {}
          };
      trophyEarned[trophyData['website']].forEach((k, v) {
        v.forEach((key, item) {
          trophiesArray.add(item);
        });
      });
    } else if (trophyData['log'] == "pending") {
      //? Stored list of pending trophies
      Map trophyPending = settings.get('trophyPending') ??
          {
            'psnProfiles': {},
            'psnTrophyLeaders': {},
            'exophase': {},
            'trueTrophies': {},
            'psn100': {}
          };
      trophyPending[trophyData['website']].forEach((k, v) {
        v.forEach((key, item) {
          trophiesArray.add(item);
        });
      });
    }

    //? Alphabetical sorting in ascending manner (A trophies before Z trophies).
    if (trophyLog['sorting'] == "alphabeticalZ") {
      trophiesArray.sort((a, b) => (a['name'].replaceAll('"', '') ?? "")
          .toLowerCase()
          .compareTo((b['name'].replaceAll('"', '') ?? "").toLowerCase()));
    }
    //? Alphabetical sorting in descending manner (Z trophies before A trophies).
    else if (trophyLog['sorting'] == "Zalphabetical") {
      trophiesArray.sort((a, b) => (b['name'].replaceAll('"', '') ?? "")
          .toLowerCase()
          .compareTo((a['name'].replaceAll('"', '') ?? "").toLowerCase()));
    }
    //? Rarity sorting in ascending manner (low % trophies before high % trophies).
    else if (trophyLog['sorting'] == "upRarity") {
      trophiesArray.sort((a, b) => a['rarity'] == b['rarity'] &&
              trophyData['log'] == "earned"
          ? a['timestamp'] > b['timestamp']
              ? 1 //? If two trophies have the same rarity, sort them by earned date, if looking through earned trophies
              : -1
          : (a['rarity'] ?? 0) > (b['rarity'] ?? 0)
              ? 1
              : -1);
    }
    //? Rarity sorting in descending manner (high % trophies before low % trophies).
    else if (trophyLog['sorting'] == "downRarity") {
      trophiesArray.sort((a, b) => a['rarity'] == b['rarity'] &&
              trophyData['log'] == "earned"
          ? a['timestamp'] > b['timestamp']
              ? 1 //? If two trophies have the same rarity, sort them by earned date, if looking through earned trophies
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
    //? Timestamp sorting by oldest trophy first. Disabled for pending trophies
    else if (trophyLog['sorting'].contains("Timestamp") &&
        trophyData['log'] == "earned") {
      trophiesArray.sort((a, b) {
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
        return (a['timestamp'] ?? 999999999999) ==
                (b['timestamp'] ?? 999999999999)
            ? trophyA > trophyB
                ? 1
                : -1
            : (a['timestamp'] ?? 999999999999) >
                    (b['timestamp'] ?? 999999999999)
                ? 1
                : -1;
      });
      // ? Trophy advisor sorting by trophy ID
      // ? Not working, order seems really funky
      // } else if (trophyLog['sorting'].contains("Timestamp") &&
      //     trophyData['log'] == "pending") {
      //   trophiesArray.sort((a, b) {
      //     return a['gameData']['gameName'] == b['gameData']['gameName']
      //         ? b['id'].compareTo(a['id'])
      //         : 0;
      //   });
    }

    counters = {
      'prestige': 0,
      'ultraRare': 0,
      'veryRare': 0,
      'rare': 0,
      'uncommon': 0,
      'common': 0,
      'platinum': 0,
      'gold': 0,
      'silver': 0,
      'bronze': 0,
    };

    times = {
      'year': {},
      'month': {},
      'day': {},
      'weekday': {},
      'hour': {},
      'minute': {}
    };

    int previousUnfilteredArrayItem = 0;
    for (var i = 0; i < trophiesArray.length; i++) {
      //? Trophies filter
      if (
          //? Skip if the user is filtering Prestige trophies (1-%)
          (trophiesArray[i]['rarity'] < 1 && trophyLog['prestige'] == false) ||
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
                  trophyLog['bronze'] == false) ||
              //? Skip if the user is filtering DLC trophies
              (trophiesArray[i]['dlc'] == true && trophyLog['DLC'] == false)) {
        continue;
      }

      //? Platform filtering
      int shouldDisplay = 0;
      if (trophiesArray[i]['gameData']['gameVita'] == true &&
          trophyLog['psv'] == true) {
        shouldDisplay++;
      }
      if (trophiesArray[i]['gameData']['gamePS3'] == true &&
          trophyLog['ps3'] == true) {
        shouldDisplay++;
      }
      if (trophiesArray[i]['gameData']['gamePS4'] == true &&
          trophyLog['ps4'] == true) {
        shouldDisplay++;
      }
      if (trophiesArray[i]['gameData']['gamePS5'] == true &&
          trophyLog['ps5'] == true) {
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

      //? Track year/month/day and weekday/hour/minute of this trophy
      if (trophyData['log'] == 'earned' && openMenus['date'] == true) {
        DateTime thisTrophy = DateTime.fromMillisecondsSinceEpoch(
            (trophiesArray[i]['timestamp'] ?? 0) * 1000);
        if ((trophyLog['year'] != null &&
                trophyLog['year'] != thisTrophy.year) ||
            (trophyLog['month'] != null &&
                trophyLog['month'] != thisTrophy.month) ||
            (trophyLog['day'] != null && trophyLog['day'] != thisTrophy.day) ||
            (trophyLog['weekday'] != null &&
                trophyLog['weekday'] != thisTrophy.weekday) ||
            (trophyLog['hour'] != null &&
                trophyLog['hour'] != thisTrophy.hour) ||
            (trophyLog['minute'] != null &&
                trophyLog['minute'] != thisTrophy.minute)) {
          continue;
        } else {
          if (times['year'][thisTrophy.year.toString()] == null) {
            times['year'][thisTrophy.year.toString()] = 1;
          } else {
            times['year'][thisTrophy.year.toString()]++;
          }

          if (times['month'][thisTrophy.month.toString()] == null) {
            times['month'][thisTrophy.month.toString()] = 1;
          } else {
            times['month'][thisTrophy.month.toString()]++;
          }

          if (times['day'][thisTrophy.day.toString()] == null) {
            times['day'][thisTrophy.day.toString()] = 1;
          } else {
            times['day'][thisTrophy.day.toString()]++;
          }

          if (times['weekday'][thisTrophy.weekday.toString()] == null) {
            times['weekday'][thisTrophy.weekday.toString()] = 1;
          } else {
            times['weekday'][thisTrophy.weekday.toString()]++;
          }

          if (times['hour'][thisTrophy.hour.toString()] == null) {
            times['hour'][thisTrophy.hour.toString()] = 1;
          } else {
            times['hour'][thisTrophy.hour.toString()]++;
          }
          if (times['minute'][thisTrophy.minute.toString()] == null) {
            times['minute'][thisTrophy.minute.toString()] = 1;
          } else {
            times['minute'][thisTrophy.minute.toString()]++;
          }
        }
      }

      //? Tracks if this trophy is prestige
      if (trophiesArray[i]['rarity'] < 1) {
        counters['prestige']++;
      }
      //? Tracks if this trophy is ultra rare
      else if (trophiesArray[i]['rarity'] >= 1 &&
          trophiesArray[i]['rarity'] < 5) {
        counters['ultraRare']++;
      }
      //? Tracks if this trophy is very rare
      else if (trophiesArray[i]['rarity'] >= 5 &&
          trophiesArray[i]['rarity'] < 10) {
        counters['veryRare']++;
      }
      //? Tracks if this trophy is rare
      else if (trophiesArray[i]['rarity'] >= 10 &&
          trophiesArray[i]['rarity'] < 25) {
        counters['rare']++;
      }
      //? Tracks if this trophy is uncommon
      else if (trophiesArray[i]['rarity'] >= 25 &&
          trophiesArray[i]['rarity'] < 50) {
        counters['uncommon']++;
      }
      //? Tracks if this trophy is common
      else if (trophiesArray[i]['rarity'] >= 50) {
        counters['common']++;
      }
      //? Tracks if this trophy is a platinum
      if (trophiesArray[i]['type'] == 'platinum') {
        counters['platinum']++;
      }
      //? Tracks if this trophy is gold
      else if (trophiesArray[i]['type'] == 'gold') {
        counters['gold']++;
      }
      //? Tracks if this trophy is silver
      else if (trophiesArray[i]['type'] == 'silver') {
        counters['silver']++;
      }
      //? Tracks if this trophy is bronze
      else if (trophiesArray[i]['type'] == 'bronze') {
        counters['bronze']++;
      }

      _displayedTrophies++;
      if (_displayedTrophies > 1000 &&
          (trophyLog['sorting'] != "newTimestamp" ||
              trophyData['log'] == 'pending')) {
        continue;
      }
      if (trophyLog['trophyDisplay'] == "grid") {
        trophyWidgets.add(InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return TrophyList(trophyListData: trophiesArray[i]['gameData']);
            }),
          ),
          child: Tooltip(
            message: (trophyData['log'] == 'pending' &&
                    trophiesArray[i]['hidden'] == true &&
                    trophyLog['showHidden'] == false)
                ? regionalText["trophies"]["hiddenTrophy"]
                : '${trophiesArray[i]['name']} (${trophiesArray[i]['rarity']}%)' +
                    (trophiesArray[i]['dlc'] == true ? " (DLC)" : ""),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(children: [
                  Container(
                    height: Platform.isWindows ? 85 : 60,
                    width: Platform.isWindows ? 85 : 60,
                    child: CachedNetworkImage(
                      fit: BoxFit.fill,
                      imageUrl: (trophyData['log'] == 'pending' &&
                              trophiesArray[i]['hidden'] == true &&
                              trophyLog['showHidden'] == false)
                          ? "https://www.exophase.com/assets/zeal/images/default_hidden.png"
                          : trophiesArray[i]['image'],
                    ),
                  ),
                  if (trophiesArray[i]['dlc'] == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Icon(Icons.brightness_1,
                          color: themeSelector["primary"]
                              [settings.get("theme")],
                          size: Platform.isWindows ? 28 : 15),
                    ),
                  if (trophiesArray[i]['dlc'] == true)
                    Positioned(
                      right: Platform.isWindows ? 2 : 1,
                      bottom: Platform.isWindows ? 2 : 1,
                      child: Icon(Icons.brightness_1,
                          color: themeSelector["secondary"]
                              [settings.get("theme")],
                          size: Platform.isWindows ? 24 : 13),
                    ),
                  if (trophiesArray[i]['dlc'] == true)
                    Positioned(
                      right: Platform.isWindows ? 4 : 2,
                      bottom: Platform.isWindows ? 4 : 2,
                      child: Icon(Icons.download_sharp,
                          color: themeSelector["primary"]
                              [settings.get("theme")],
                          size: Platform.isWindows ? 20 : 12),
                    ),
                ]),
              ),
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
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.horizontal(left: Radius.circular(5)),
                    child: Stack(children: [
                      Container(
                        height: Platform.isWindows ? 85 : 60,
                        width: Platform.isWindows ? 85 : 60,
                        child: CachedNetworkImage(
                          fit: BoxFit.fill,
                          imageUrl: (trophyData['log'] == 'pending' &&
                                  trophiesArray[i]['hidden'] == true &&
                                  trophyLog['showHidden'] == false)
                              ? "https://www.exophase.com/assets/zeal/images/default_hidden.png"
                              : trophiesArray[i]['image'],
                        ),
                      ),
                      if (trophiesArray[i]['dlc'] == true)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(Icons.brightness_1,
                              color: themeSelector["primary"]
                                  [settings.get("theme")],
                              size: Platform.isWindows ? 28 : 15),
                        ),
                      if (trophiesArray[i]['dlc'] == true)
                        Positioned(
                          right: Platform.isWindows ? 2 : 1,
                          bottom: Platform.isWindows ? 2 : 1,
                          child: Icon(Icons.brightness_1,
                              color: themeSelector["secondary"]
                                  [settings.get("theme")],
                              size: Platform.isWindows ? 24 : 13),
                        ),
                      if (trophiesArray[i]['dlc'] == true)
                        Positioned(
                          right: Platform.isWindows ? 4 : 2,
                          bottom: Platform.isWindows ? 4 : 2,
                          child: Icon(Icons.download_sharp,
                              color: themeSelector["primary"]
                                  [settings.get("theme")],
                              size: Platform.isWindows ? 20 : 12),
                        ),
                    ]),
                  ),
                ),
                //? Column with trophy type, name, rarity, exp + description + earned timestamp
                Expanded(
                  child: Container(
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
                                  (trophyData['log'] == 'pending' &&
                                          trophiesArray[i]['hidden'] == true &&
                                          trophyLog['showHidden'] == false)
                                      ? "???"
                                      : trophiesArray[i]['name'],
                                  style: textSelection(theme: "textLightBold"),
                                  textAlign: TextAlign.left,
                                ),
                                //? Trophy rarity, if avaiable
                                if (trophiesArray[i]['rarity'] != null)
                                  rarityType(
                                      rarity: trophiesArray[i]['rarity'],
                                      size: 'small',
                                      style: textSelection(
                                          theme: "textLightBold")),
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
                                        style: textSelection(
                                            theme: "textLightBold"),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            //? Trophy description
                            Container(
                              child: Text(
                                (trophyData['log'] == 'pending' &&
                                        trophiesArray[i]['hidden'] == true &&
                                        trophyLog['showHidden'] == false)
                                    ? regionalText["trophies"]["hiddenTrophy"]
                                    : trophiesArray[i]['description'],
                                style: textSelection(),
                                textAlign: TextAlign.left,
                                maxLines: 2,
                              ),
                            ),
                            //? Trophy timestamp + (gap if sorting == oldTimestamp)
                            if (trophiesArray[i]['timestamp'] != null)
                              Container(
                                child: Row(
                                  children: [
                                    Text(
                                      settings.get('localization') ?? true
                                          ? DateFormat.yMMMMEEEEd(
                                                  Platform.localeName)
                                              .add_Hms()
                                              .format(DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      trophiesArray[i]
                                                              ['timestamp'] *
                                                          1000))
                                          : DateFormat.yMMMMEEEEd().add_Hms().format(
                                              DateTime.fromMillisecondsSinceEpoch(
                                                  trophiesArray[i]['timestamp'] *
                                                      1000)),
                                      style: textSelection(),
                                      textAlign: TextAlign.left,
                                    ),
                                    //? Trophy gap if sorting == "oldTimestamp"
                                    if (trophyLog['sorting']
                                            .contains("Timestamp") &&
                                        trophyWidgets.isNotEmpty &&
                                        trophiesArray[
                                                    previousUnfilteredArrayItem]
                                                ['timestamp'] !=
                                            null &&
                                        trophiesArray[
                                                    previousUnfilteredArrayItem]
                                                ['timestamp'] !=
                                            trophiesArray[i]['timestamp'])
                                      Row(
                                        children: [
                                          SizedBox(width: 5),
                                          timeGap(
                                              trophiesArray[
                                                      previousUnfilteredArrayItem]
                                                  ['timestamp'],
                                              trophiesArray[i]['timestamp'])
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 5),
                if (Platform.isWindows &&
                    trophyLog['sorting'] != "oldTimestamp")
                  Tooltip(
                    message:
                        "${trophiesArray[i]['gameData']['gameName']} (${trophiesArray[i]['gameData']['gamePercentage'].toString()}%)",
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(5)),
                      child: Container(
                        height: Platform.isWindows ? 85 : 60,
                        child: CachedNetworkImage(
                          fit: BoxFit.fitHeight,
                          imageUrl: trophiesArray[i]['gameData']['gameImage'],
                        ),
                      ),
                    ),
                  )
              ],
            )));
      }
      previousUnfilteredArrayItem = i;
    }

    if (trophyLog['sorting'] == "newTimestamp") {
      trophyWidgets = trophyWidgets.reversed.toList();
    }

    //? Properly contains all trophy data inside it's proper viewMode
    if (trophyLog['trophyDisplay'] == "grid") {
      listDisplay = StaggeredGridView.countBuilder(
        // key: UniqueKey(),
        crossAxisCount: Platform.isWindows
            ? (MediaQuery.of(context).size.width / 80).floor()
            : (MediaQuery.of(context).size.width / 50).floor(),
        staggeredTileBuilder: (index) => StaggeredTile.fit(1),
        itemCount: trophyWidgets.length,
        itemBuilder: (context, index) => trophyWidgets[index],
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
    if (openMenus['date'] == true) {
      days = times['day'].entries.map((e) => int.parse(e.key)).toList();
      days.sort();
      months = times['month'].entries.map((e) => int.parse(e.key)).toList();
      months.sort();
      years = times['year'].entries.map((e) => int.parse(e.key)).toList();
      years.sort();
      hours = times['hour'].entries.map((e) => int.parse(e.key)).toList();
      hours.sort();
      minutes = times['minute'].entries.map((e) => int.parse(e.key)).toList();
      minutes.sort();
    }

    return Column(
      children: [
        //?  Trophy type counter
        if (_displayedTrophies > 0)
          Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: Platform.isWindows ? 50 : 30),
                if (counters['platinum'] > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child:
                        trophyType('platinum', quantity: counters['platinum']),
                  ),
                if (counters['gold'] > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: trophyType('gold', quantity: counters['gold']),
                  ),
                if (counters['silver'] > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: trophyType('silver', quantity: counters['silver']),
                  ),
                if (counters['bronze'] > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: trophyType('bronze', quantity: counters['bronze']),
                  ),
              ],
            ),
          ),
        //? Divider between trophy type and trophy rarity
        if (_displayedTrophies > 0)
          Divider(
              color: themeSelector['secondary'][settings.get('theme')],
              thickness: 2,
              indent: MediaQuery.of(context).size.width / 4,
              endIndent: MediaQuery.of(context).size.width / 4,
              height: 0),
        //? Trophy rarity
        if (_displayedTrophies > 0)
          Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: Platform.isWindows ? 30 : 25),
                if (counters['prestige'] > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: rarityType(
                        type: 'rarity7', quantity: counters['prestige']),
                  ),
                if (counters['ultraRare'] > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: rarityType(
                        type: 'rarity6', quantity: counters['ultraRare']),
                  ),
                if (counters['veryRare'] > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: rarityType(
                        type: 'rarity5', quantity: counters['veryRare']),
                  ),
                if (counters['rare'] > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child:
                        rarityType(type: 'rarity4', quantity: counters['rare']),
                  ),
                if (counters['uncommon'] > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: rarityType(
                        type: 'rarity3', quantity: counters['uncommon']),
                  ),
                if (counters['common'] > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: rarityType(
                        type: 'rarity1', quantity: counters['common']),
                  ),
              ],
            ),
          ),
        if (settings.get('trophyDataUpToDate') != true)
          Padding(
            padding: EdgeInsets.all(Platform.isWindows ? 5 : 3),
            child: InkWell(
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: boxDeco('thin'),
                child: Text(
                  regionalText["games"]["getAllTrophies"],
                  style: textSelection(),
                ),
              ),
              onTap: () {
                //? Pops the current log/advisor and then updates the trophies
                Navigator.pop(context);
                return Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    List data = [];
                    settings
                        .get('${trophyData['website']}Games')
                        .forEach((element) {
                      if (element['gamePercentage'] > 0) {
                        data.add({
                          'gameWebsite': trophyData['website'],
                          'gameLink': element['gameLink'],
                          'gamePercentage': element['gamePercentage'],
                          'gameID': element['gameID'],
                          'gameName': element['gameName'],
                          'gameImage': element['gameImage'],
                          'gamePS3': element['gamePS3'] == true ? true : false,
                          'gamePS4': element['gamePS4'] == true ? true : false,
                          'gamePS5': element['gamePS5'] == true ? true : false,
                          'gameVita':
                              element['gameVita'] == true ? true : false,
                        });
                      }
                    });
                    return PullTrophies(
                        pullTrophiesData: data.reversed.toList());
                  }),
                );
              },
            ),
          ),
        Expanded(child: Container(child: listDisplay)),
      ],
    );
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
            //? This contains all trophy data, distribution, rarity and the trophies themselves
            Container(
              child: Expanded(child: trophyLogDisplay()),
            ),
            //? This is the bottom bar containing the filters and sorting options for the trophy list.
            Container(
              width: MediaQuery.of(context).size.width,
              color: themeSelector["primary"][settings.get("theme")],
              child: Column(
                children: [
                  //? This Row lets you search for specific games.
                  if (openMenus['search'] == true)
                    Container(
                      padding: EdgeInsets.all(5),
                      height: Platform.isWindows ? 35 : 25,
                      width: MediaQuery.of(context).size.width / 3,
                      child: Center(
                        child: Container(
                          height: 20,
                          child: TextFormField(
                              style: textSelection(),
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: regionalText['log']['searchText'],
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
                    ), //? Filter trophies by their type
                  //? This row lets you toggle between earned trophies and pending trophies
                  if (openMenus['type'] == true)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          regionalText['log']['type'],
                          style: textSelection(),
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: Platform.isWindows ? 40 : 25),
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
                                          trophyType('platinum',
                                              size: 'big', tooltip: false),
                                          if (trophyLog['platinum'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 30 : 20,
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
                                          trophyType('gold',
                                              size: 'big', tooltip: false),
                                          if (trophyLog['gold'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 30 : 20,
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
                                          trophyType('silver',
                                              size: 'big', tooltip: false),
                                          if (trophyLog['silver'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 30 : 20,
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
                                          trophyType('bronze',
                                              size: 'big', tooltip: false),
                                          if (trophyLog['bronze'] == false)
                                            Icon(
                                              Icons.not_interested,
                                              color: Colors.red,
                                              size:
                                                  Platform.isWindows ? 30 : 20,
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
                  if (openMenus['rarity'] == true)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: Platform.isWindows ? 40 : 25),
                        Text(
                          regionalText['log']['rarity'],
                          style: textSelection(),
                          textAlign: TextAlign.center,
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
                                                Platform.isWindows ? 35 : 20,
                                          ),
                                          if (trophyLog['prestige'] == false)
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
                                                Platform.isWindows ? 35 : 20,
                                          ),
                                          if (trophyLog['ultraRare'] == false)
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
                                                Platform.isWindows ? 35 : 20,
                                          ),
                                          if (trophyLog['veryRare'] == false)
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
                                                Platform.isWindows ? 35 : 20,
                                          ),
                                          if (trophyLog['rare'] == false)
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
                                                Platform.isWindows ? 35 : 20,
                                          ),
                                          if (trophyLog['uncommon'] == false)
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
                                                Platform.isWindows ? 35 : 20,
                                          ),
                                          if (trophyLog['common'] == false)
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
                  if (openMenus['platform'] == true)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: Platform.isWindows ? 40 : 25),
                        Center(
                          child: Text(
                            regionalText['log']['platform'],
                            style: textSelection(),
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
                                    height: Platform.isWindows ? 35 : 22,
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
                                    height: Platform.isWindows ? 35 : 22,
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
                                    height: Platform.isWindows ? 35 : 22,
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
                                    height: Platform.isWindows ? 35 : 22,
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
                  //? Filter trophies by specific date
                  if (openMenus['date'] == true &&
                      trophyData['log'] == 'earned')
                    Container(
                      height: Platform.isWindows ? 40 : 35,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          //? Weekdays selector
                          DropdownButton<String>(
                            hint: Text(
                                trophyLog['weekday'] != null
                                    ? DateFormat.EEEE(Platform.localeName)
                                        .format(DateTime(
                                            4, 0, trophyLog['weekday']))
                                    : regionalText['log']['weekdays'],
                                style: textSelection()),
                            icon: Icon(Icons.arrow_upward,
                                color: themeSelector["secondary"]
                                    [settings.get("theme")],
                                size: 20),
                            style: textSelection(theme: "textDark"),
                            underline: Container(
                              height: 2,
                              color: themeSelector["secondary"]
                                  [settings.get("theme")],
                            ),
                            onChanged: (String newValue) {
                              setState(() {
                                trophyLog['weekday'] = int.parse(newValue);
                              });
                            },
                            items: <int>[
                              1,
                              2,
                              3,
                              4,
                              5,
                              6,
                              7,
                            ].map<DropdownMenuItem<String>>((int value) {
                              return DropdownMenuItem<String>(
                                value: value.toString(),
                                child: Text(DateFormat.EEEE(Platform.localeName)
                                    .format(DateTime(4, 0, value))),
                              );
                            }).toList(),
                          ),
                          //? This SizedBox is placed here to separate the weekdays from the other items
                          SizedBox(),
                          //? Days selector
                          DropdownButton<String>(
                            hint: Text(
                                trophyLog['day'] != null
                                    ? trophyLog['day'].toString()
                                    : regionalText['log']['days'],
                                style: textSelection()),
                            icon: Icon(Icons.arrow_upward,
                                color: themeSelector["secondary"]
                                    [settings.get("theme")],
                                size: 20),
                            style: textSelection(theme: "textDark"),
                            underline: Container(
                              height: 2,
                              color: themeSelector["secondary"]
                                  [settings.get("theme")],
                            ),
                            onChanged: (String newValue) {
                              setState(() {
                                trophyLog['day'] = int.parse(newValue);
                              });
                            },
                            items:
                                days.map<DropdownMenuItem<String>>((int value) {
                              return DropdownMenuItem<String>(
                                value: value.toString(),
                                child: Text(value.toString()),
                              );
                            }).toList(),
                          ),
                          //? Months selector
                          DropdownButton<String>(
                            hint: Text(
                                trophyLog['month'] != null
                                    ? DateFormat.MMMM(Platform.localeName)
                                        .format(DateTime(1, trophyLog['month']))
                                    : regionalText['log']['months'],
                                style: textSelection()),
                            icon: Icon(Icons.arrow_upward,
                                color: themeSelector["secondary"]
                                    [settings.get("theme")],
                                size: 20),
                            style: textSelection(theme: "textDark"),
                            underline: Container(
                              height: 2,
                              color: themeSelector["secondary"]
                                  [settings.get("theme")],
                            ),
                            onChanged: (String newValue) {
                              setState(() {
                                trophyLog['month'] = int.parse(newValue);
                              });
                            },
                            items: months
                                .map<DropdownMenuItem<String>>((int value) {
                              return DropdownMenuItem<String>(
                                value: value.toString(),
                                child: Text(DateFormat.MMMM(Platform.localeName)
                                    .format(DateTime(1, value))),
                              );
                            }).toList(),
                          ),
                          //? Years selector
                          DropdownButton<String>(
                            hint: Text(
                                trophyLog['year'] != null
                                    ? trophyLog['year'].toString()
                                    : regionalText['log']['years'],
                                style: textSelection()),
                            icon: Icon(Icons.arrow_upward,
                                color: themeSelector["secondary"]
                                    [settings.get("theme")],
                                size: 20),
                            style: textSelection(theme: "textDark"),
                            underline: Container(
                              height: 2,
                              color: themeSelector["secondary"]
                                  [settings.get("theme")],
                            ),
                            onChanged: (String newValue) {
                              setState(() {
                                trophyLog['year'] = int.parse(newValue);
                              });
                            },
                            items: years
                                .map<DropdownMenuItem<String>>((int value) {
                              return DropdownMenuItem<String>(
                                value: value.toString(),
                                child: Text(value.toString()),
                              );
                            }).toList(),
                          ),
                          //? This SizedBox is placed here to separate the hours and minutes from the other items
                          SizedBox(height: Platform.isWindows ? 40 : 25),
                          //? Hours selector
                          DropdownButton<String>(
                            hint: Text(
                                trophyLog['hour'] != null
                                    ? trophyLog['hour'].toString()
                                    : regionalText['log']['hours'],
                                style: textSelection()),
                            icon: Icon(Icons.arrow_upward,
                                color: themeSelector["secondary"]
                                    [settings.get("theme")],
                                size: 20),
                            style: textSelection(theme: "textDark"),
                            underline: Container(
                              height: 2,
                              color: themeSelector["secondary"]
                                  [settings.get("theme")],
                            ),
                            onChanged: (String newValue) {
                              setState(() {
                                trophyLog['hour'] = int.parse(newValue);
                              });
                            },
                            items: hours
                                .map<DropdownMenuItem<String>>((int value) {
                              return DropdownMenuItem<String>(
                                value: value.toString(),
                                child: Text(value.toString()),
                              );
                            }).toList(),
                          ),
                          //? Minutes selector
                          DropdownButton<String>(
                            hint: Text(
                                trophyLog['minute'] != null
                                    ? trophyLog['minute'].toString()
                                    : regionalText['log']['minutes'],
                                style: textSelection()),
                            icon: Icon(Icons.arrow_upward,
                                color: themeSelector["secondary"]
                                    [settings.get("theme")],
                                size: 20),
                            style: textSelection(theme: "textDark"),
                            underline: Container(
                              height: 2,
                              color: themeSelector["secondary"]
                                  [settings.get("theme")],
                            ),
                            onChanged: (String newValue) {
                              setState(() {
                                trophyLog['minute'] = int.parse(newValue);
                              });
                            },
                            items: minutes
                                .map<DropdownMenuItem<String>>((int value) {
                              return DropdownMenuItem<String>(
                                value: value.toString(),
                                child: Text(value.toString()),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  //? This Row lets you sort trophies in a specific order.
                  if (openMenus['sort'] == true)
                    Container(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: Platform.isWindows ? 40 : 25),
                            Text(
                              regionalText['trophies']['sort'],
                              style: textSelection(),
                              textAlign: TextAlign.center,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 3),
                                //? Sort trophies by how long ago the game was played
                                if (trophyData['log'] == "pending")
                                  Tooltip(
                                    message: regionalText['log']
                                        ['sortByRecentGame'],
                                    child: Container(
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
                                        child: Icon(
                                            trophyLog['sorting'] !=
                                                    "oldTimestamp"
                                                ? Icons.fiber_new
                                                : Icons.elderly,
                                            color: themeSelector["secondary"]
                                                [settings.get("theme")],
                                            size: Platform.isWindows ? 30 : 22),
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
                                //? Sort trophies by earned timestamp
                                if (trophyData['log'] == "earned")
                                  Tooltip(
                                    message: regionalText['trophies']
                                        ['earnedTimestamp'],
                                    child: Container(
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
                                        child: Icon(
                                            trophyLog['sorting'] !=
                                                    "oldTimestamp"
                                                ? Icons.fiber_new
                                                : Icons.elderly,
                                            color: themeSelector["secondary"]
                                                [settings.get("theme")],
                                            size: Platform.isWindows ? 30 : 22),
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
                                //? Sort trophies by trophy value (platinum > gold > silver > bronze)
                                Tooltip(
                                  message: regionalText['trophies']['value'],
                                  child: InkWell(
                                    child: Container(
                                      height: Platform.isWindows ? 35 : 22,
                                      alignment: Alignment.center,
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
                                          size: "big",
                                          tooltip: false),
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
                                      height: Platform.isWindows ? 35 : 22,
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
                                      child: Center(
                                        child: Text(
                                          trophyLog['sorting'] !=
                                                  "Zalphabetical"
                                              ? "ABC"
                                              : "ZYX",
                                          style: textSelection(),
                                          textAlign: TextAlign.center,
                                        ),
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
                                //? Sort games by ascending rarity
                                Tooltip(
                                  message: regionalText['trophies']['rarity'],
                                  child: InkWell(
                                    child: Container(
                                      height: Platform.isWindows ? 35 : 22,
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
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  //? This Row lets you filter in and out specific types of trophies.
                  if (openMenus['settings'] == true)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: Platform.isWindows ? 40 : 25),
                        Text(
                          regionalText['trophies']['settings'],
                          style: textSelection(),
                          textAlign: TextAlign.center,
                        ),
                        //? Switch between earned and pending trophies
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            //? Adding a DLC toggle
                            Tooltip(
                              message: regionalText['trophies']['earned'],
                              child: InkWell(
                                  child: Container(
                                      height: Platform.isWindows ? 45 : 22,
                                      decoration: BoxDecoration(
                                          //? To paint the border, we check the value of the settings for this website is true.
                                          //? If it's false or null (never set), we will paint red.
                                          border: Border.all(
                                              color: trophyLog['DLC'] == true
                                                  ? Colors.green
                                                  : Colors.red,
                                              width:
                                                  Platform.isWindows ? 5 : 2)),
                                      child: Center(
                                        child: Text(
                                          "DLC",
                                          style: textSelection(),
                                          textAlign: TextAlign.center,
                                        ),
                                      )),
                                  onTap: () {
                                    setState(() {
                                      if (trophyLog['DLC'] == true) {
                                        trophyLog['DLC'] = false;
                                      } else {
                                        trophyLog['DLC'] = true;
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
                                            color: themeSelector["secondary"]
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
                          ],
                        ),
                      ],
                    ), //? This Row contains the toggles to display the items above
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: Platform.isWindows ? 40 : 25),
                      Text(
                        regionalText['trophies']['options'],
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
                      //? Trophy type filter
                      Tooltip(
                        message: regionalText['log']['type'],
                        child: InkWell(
                            child: Container(
                                height: Platform.isWindows ? 35 : 22,
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  border: Border.all(
                                      color: openMenus['type'] != true
                                          ? Colors.transparent
                                          : Colors.green,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: trophyType("platinum",
                                    size: "big", tooltip: false)),
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () {
                              setState(() {
                                if (openMenus['type'] != true) {
                                  openMenus['type'] = true;
                                  openMenus['rarity'] = false;
                                  openMenus['platform'] = false;
                                  openMenus['sort'] = false;
                                  openMenus['settings'] = false;
                                } else {
                                  openMenus['type'] = false;
                                }
                                menuCloser.run(() {
                                  if (mounted) {
                                    setState(() {
                                      openMenus['type'] = false;
                                    });
                                  }
                                });
                              });
                            }),
                      ),
                      //? Trophy rarity filter
                      Tooltip(
                        message: regionalText['trophies']['rarity'],
                        child: InkWell(
                            child: Container(
                              height: Platform.isWindows ? 35 : 22,
                              decoration: BoxDecoration(
                                //? To paint the border, we check the value of the settings for this website is true.
                                //? If it's false or null (never set), we will paint red.
                                border: Border.all(
                                    color: openMenus['rarity'] != true
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
                            onTap: () {
                              setState(() {
                                if (openMenus['rarity'] != true) {
                                  openMenus['type'] = false;
                                  openMenus['rarity'] = true;
                                  openMenus['platform'] = false;
                                  openMenus['sort'] = false;
                                  openMenus['settings'] = false;
                                } else {
                                  openMenus['rarity'] = false;
                                }
                                menuCloser.run(() {
                                  if (mounted) {
                                    setState(() {
                                      openMenus['rarity'] = false;
                                    });
                                  }
                                });
                              });
                            }),
                      ),
                      //? Platform filter
                      Tooltip(
                        message: regionalText['log']['platform'],
                        child: InkWell(
                            child: Container(
                              height: Platform.isWindows ? 35 : 22,
                              decoration: BoxDecoration(
                                //? To paint the border, we check the value of the settings for this website is true.
                                //? If it's false or null (never set), we will paint red.
                                border: Border.all(
                                    color: openMenus['platform'] == true
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
                            onTap: () {
                              setState(() {
                                if (openMenus['platform'] != true) {
                                  openMenus['type'] = false;
                                  openMenus['rarity'] = false;
                                  openMenus['platform'] = true;
                                  openMenus['sort'] = false;
                                  openMenus['settings'] = false;
                                } else {
                                  openMenus['platform'] = false;
                                }
                                menuCloser.run(() {
                                  if (mounted) {
                                    setState(() {
                                      openMenus['platform'] = false;
                                    });
                                  }
                                });
                              });
                            }),
                      ),
                      //? Date and Time
                      if (trophyData['log'] == 'earned')
                        Tooltip(
                          message: regionalText['log']['date'],
                          child: InkWell(
                              child: Container(
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  //? If it's false or null (never set), we will paint red.
                                  border: Border.all(
                                      color: openMenus['date'] != true
                                          ? Colors.transparent
                                          : Colors.green,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Icon(Icons.date_range,
                                    color: themeSelector["secondary"]
                                        [settings.get("theme")],
                                    size: Platform.isWindows ? 30 : 17),
                              ),
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () {
                                setState(() {
                                  if (openMenus['date'] != true) {
                                    openMenus['type'] = false;
                                    openMenus['rarity'] = false;
                                    openMenus['platform'] = false;
                                    openMenus['sort'] = false;
                                    openMenus['date'] = true;
                                    openMenus['settings'] = false;
                                  } else {
                                    openMenus['date'] = false;
                                    trophyLog['minute'] = null;
                                    trophyLog['hour'] = null;
                                    trophyLog['day'] = null;
                                    trophyLog['weekday'] = null;
                                    trophyLog['month'] = null;
                                    trophyLog['year'] = null;
                                  }
                                });
                              }),
                        ),
                      //? Sorting
                      Tooltip(
                        message: regionalText['trophies']['sort'],
                        child: InkWell(
                            child: Container(
                              height: Platform.isWindows ? 35 : 22,
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
                                  openMenus['type'] = false;
                                  openMenus['rarity'] = false;
                                  openMenus['platform'] = false;
                                  openMenus['sort'] = true;
                                  openMenus['settings'] = false;
                                } else {
                                  openMenus['sort'] = false;
                                }
                                menuCloser.run(() {
                                  if (mounted) {
                                    setState(() {
                                      openMenus['sort'] = false;
                                    });
                                  }
                                });
                              });
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
                                    color: openMenus['settings'] != true
                                        ? Colors.transparent
                                        : Colors.green,
                                    width: Platform.isWindows ? 5 : 2),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                              ),
                              child: Icon(Icons.settings,
                                  color: themeSelector["secondary"]
                                      [settings.get("theme")],
                                  size: Platform.isWindows ? 30 : 17),
                            ),
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () {
                              setState(() {
                                if (openMenus['settings'] != true) {
                                  openMenus['type'] = false;
                                  openMenus['rarity'] = false;
                                  openMenus['platform'] = false;
                                  openMenus['sort'] = false;
                                  openMenus['settings'] = true;
                                } else {
                                  openMenus['settings'] = false;
                                }
                                menuCloser.run(() {
                                  if (mounted) {
                                    setState(() {
                                      openMenus['settings'] = false;
                                    });
                                  }
                                });
                              });
                            }),
                      ),
                      //? Display
                      Tooltip(
                        message: regionalText['trophies']['display'],
                        child: InkWell(
                            child: Container(
                              child: Icon(
                                  trophyLog['trophyDisplay'] != "list"
                                      ? Icons.list
                                      : Icons.view_comfy,
                                  color: themeSelector["secondary"]
                                      [settings.get("theme")],
                                  size: Platform.isWindows ? 30 : 22),
                            ),
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () {
                              setState(() {
                                if (trophyLog['trophyDisplay'] == 'list') {
                                  trophyLog['trophyDisplay'] = "grid";
                                } else {
                                  trophyLog['trophyDisplay'] = "list";
                                }
                                menuCloser.run(() {
                                  if (mounted) {
                                    setState(() {});
                                  }
                                  settings.put('trophyLog', trophyLog);
                                });
                              });
                            }),
                      ),
                      //? Reset settings button
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Tooltip(
                          message: regionalText['home']['undo'],
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                trophyLog = {
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
                                  "showHidden": trophyLog['showHidden'],
                                  "DLC": true,
                                };
                                openMenus = {
                                  'type': false,
                                  'rarity': false,
                                  'platform': false,
                                  'search': false,
                                  "filter": false,
                                  'date': false,
                                  "sort": false,
                                  "display": false,
                                  "settings": false,
                                };
                                searchQuery = [];
                              });
                              settings.put('trophyLog', trophyLog);
                            },
                            child: Container(
                              child: Icon(Icons.undo,
                                  color: themeSelector["secondary"]
                                      [settings.get("theme")],
                                  size: Platform.isWindows ? 30 : 22),
                            ),
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

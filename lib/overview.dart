import 'dart:ui';
import 'dart:io' show Platform;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'package:flutter/material.dart';

class Overview extends StatefulWidget {
  final String website;

  Overview(this.website) {
    assert(website != null);
  }
  @override
  _OverviewState createState() => _OverviewState(website);
}

class _OverviewState extends State<Overview> {
  //? The Debouncer (class created above) is now instantiated here so the search is delayed until the user stops typing.
  Debouncer debounce = Debouncer(milliseconds: 1000);
  //? Another debouncer to close the menus after 20 seconds
  Debouncer menuCloser = Debouncer(milliseconds: 15000);

  //? Sets the settings here to be used throughout the trophy page.
  Map overview = settings.get('overview') ??
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
      };
  Map openMenus = {
    //! Settings options
    'type': false, //? This will show the type filtering menu
    'rarity': false, //? This will show the rarity filtering menu
    'platform': false, //? This will show the platform filtering menu
    'YoY': false,
    'MoM': false
  };

  //? These variables are declared here so they can be populated inside overviewDisplay()
  //? After being populated, they can then be passed to another page or used outside of the function.
  //? Counters tracks the trophy type distribution and trophy rarity distribution.
  Map<String, int> counters;
  //? Times tracks the distribution of trophies over time, accross days, months, years, etc.
  Map<String, Map<String, int>> times;

  //? These variables will store the date options for the date filtering menu, so you can only select options with avaiable trophies
  List<int> months;
  List<int> years;

  //? These variables store the score for each individual subtype so they can be compared when the next overview is rendered
  Map monthScore = {'trophy': 0, 'rarity': 0};
  Map yearScore = {'trophy': 0, 'rarity': 0};

  //? Parses trophy list data and returns the trophy list in the proper display mode.
  Widget overviewDisplay({String when = 'currentMonth', int year, int month}) {
    List trophiesArray = [];

    //? Stores the current date object
    DateTime assignedDay = DateTime(year - (when == 'previousYear' ? 1 : 0),
        month - (when == 'previousMonth' ? 1 : 0));

    //? Stores all the trophy widgets, being them in a List or Grid.
    List<Widget> trophyWidgets = [];

    //? Transforms the Map into a List for the sort functions.
    Map trophyEarned = settings.get('trophyEarned') ??
        {
          'psnProfiles': {},
          'psnTrophyLeaders': {},
          'exophase': {},
          'trueTrophies': {},
          'psn100': {}
        };
    trophyEarned[website].forEach((k, v) {
      v.forEach((key, item) {
        trophiesArray.add(item);
      });
    });
    trophiesArray.sort((a, b) => a['rarity'] == b['rarity']
        ? a['timestamp'] < b['timestamp']
            ? 1 //? If two trophies have the same rarity, sort them by earned date, if looking through earned trophies
            : -1
        : (a['rarity'] ?? 0) < (b['rarity'] ?? 0)
            ? -1
            : 1);

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
    };

    for (var i = 0; i < trophiesArray.length; i++) {
      DateTime thisTrophy = DateTime.fromMillisecondsSinceEpoch(
          (trophiesArray[i]['timestamp'] ?? 0) * 1000);
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
      if (openMenus['date'] == true) {
        months = times['month'].entries.map((e) => int.parse(e.key)).toList();
        months.sort();
        years = times['year'].entries.map((e) => int.parse(e.key)).toList();
        years.sort();
      }
      //? Filter if the trophy doesn't fall into the right date range
      if ((when == "currentMonth" &&
              (thisTrophy.year != assignedDay.year ||
                  thisTrophy.month != assignedDay.month)) ||
          (when == "previousMonth" &&
              (thisTrophy.year != assignedDay.year ||
                  thisTrophy.month != assignedDay.month)) ||
          (when == "currentYear" && thisTrophy.year != assignedDay.year) ||
          (when == "previousYear" && thisTrophy.year != assignedDay.year)) {
        continue;
      }

      //? Trophies rarity/type filter
      if (
          //? Skip if the user is filtering Prestige trophies (1-%)
          (trophiesArray[i]['rarity'] < 1 && overview['prestige'] == false) ||
              //? Skip if the user is filtering Ultra Rare trophies and the trophy has between 1% and 5%
              (trophiesArray[i]['rarity'] >= 1 &&
                  trophiesArray[i]['rarity'] < 5 &&
                  overview['ultraRare'] == false) ||
              //? Skip if the user is filtering Very Rare trophies and the trophy has between 5% and 10%
              (trophiesArray[i]['rarity'] >= 5 &&
                  trophiesArray[i]['rarity'] < 10 &&
                  overview['veryRare'] == false) ||
              //? Skip if the user is filtering Rare trophies and the trophy has between 10% and 25%
              (trophiesArray[i]['rarity'] >= 10 &&
                  trophiesArray[i]['rarity'] < 25 &&
                  overview['rare'] == false) ||
              //? Skip if the user is filtering Uncommon trophies and the trophy has between 25% and 50%
              (trophiesArray[i]['rarity'] >= 25 &&
                  trophiesArray[i]['rarity'] < 50 &&
                  overview['uncommon'] == false) ||
              //? Skip if the user is filtering Common trophies and the trophy has more than 50% rarity
              (trophiesArray[i]['rarity'] >= 50 &&
                  overview['common'] == false) ||
              //? Skip if the user is filtering platinum trophies
              (trophiesArray[i]['type'] == 'platinum' &&
                  overview['platinum'] == false) ||
              //? Skip if the user is filtering gold trophies
              (trophiesArray[i]['type'] == 'gold' &&
                  overview['gold'] == false) ||
              //? Skip if the user is filtering silver trophies
              (trophiesArray[i]['type'] == 'silver' &&
                  overview['silver'] == false) ||
              //? Skip if the user is filtering bronze trophies
              (trophiesArray[i]['type'] == 'bronze' &&
                  overview['bronze'] == false)) {
        continue;
      }

      //? Platform filtering
      int shouldDisplay = 0;
      if (trophiesArray[i]['gameData']['gameVita'] == true &&
          overview['psv'] == true) {
        shouldDisplay++;
      }
      if (trophiesArray[i]['gameData']['gamePS3'] == true &&
          overview['ps3'] == true) {
        shouldDisplay++;
      }
      if (trophiesArray[i]['gameData']['gamePS4'] == true &&
          overview['ps4'] == true) {
        shouldDisplay++;
      }
      if (trophiesArray[i]['gameData']['gamePS5'] == true &&
          overview['ps5'] == true) {
        shouldDisplay++;
      }
      if (shouldDisplay == 0) {
        continue;
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

      if (trophyWidgets.length == 0) {
        trophyWidgets.add(
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border.all(width: 2, color: Colors.white)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                //? Trophy image
                ClipRRect(
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(8)),
                  child: Stack(children: [
                    Container(
                      height: Platform.isWindows ? 85 : 60,
                      width: Platform.isWindows ? 85 : 60,
                      child: CachedNetworkImage(
                        fit: BoxFit.fill,
                        imageUrl: trophiesArray[i]['image'],
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
                                  trophiesArray[i]['name'],
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
                                trophiesArray[i]['description'],
                                style: textSelection(),
                                textAlign: TextAlign.left,
                                maxLines: 2,
                              ),
                            ),
                            //? Trophy timestamp
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
                if (Platform.isWindows)
                  Tooltip(
                    message:
                        "${trophiesArray[i]['gameData']['gameName']} (${trophiesArray[i]['gameData']['gamePercentage'].toString()}%)",
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(8)),
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
            ),
          ),
        );
      }
    }

    //? Calculates the score for the current period
    int currentTrophyPoints = (counters['platinum'] *
            (settings.get('levelType') == "new" ? 20 : 12)) +
        (counters['gold'] * 6) +
        (counters['silver'] * 2) +
        (counters['bronze'] * 1);
    int currentRarityPoints = (counters['prestige'] * 16) +
        (counters['ultraRare'] * 8) +
        (counters['veryRare'] * 4) +
        (counters['rare'] * 2) +
        (counters['uncommon'] * 1);
    int previousTrophyPoints;
    int previousRarityPoints;

    //? Stores the current period statistic to be compared with in the next build
    if (when == 'previousMonth' || when == 'currentMonth') {
      previousTrophyPoints = monthScore['trophy'];
      previousRarityPoints = monthScore['rarity'];
      monthScore['trophy'] = currentTrophyPoints;
      monthScore['rarity'] = currentRarityPoints;
    }
    if (when == 'previousYear' || when == 'currentYear') {
      previousTrophyPoints = yearScore['trophy'];
      previousRarityPoints = yearScore['rarity'];
      yearScore['trophy'] = currentTrophyPoints;
      yearScore['rarity'] = currentRarityPoints;
    }

    //? Builds the widget to be displayed
    if (trophyWidgets.length == 1) {
      return Container(
        margin: EdgeInsets.all(5),
        // padding: EdgeInsets.all(5),
        decoration: boxDeco(),
        child: Column(
          children: [
            SizedBox(height: 7),
            Text(
              (when.contains("Month")
                  ? settings.get('localization') ?? true
                      ? DateFormat.yMMMM(Platform.localeName)
                          .format(assignedDay)
                      : DateFormat.yMMMM().format(assignedDay)
                  : DateFormat.y(Platform.localeName).format(assignedDay)),
              style: textSelection(theme: "textLightBold"),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  //? Trophy type counter
                  Container(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (counters['platinum'] > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: trophyType('platinum',
                                quantity: counters['platinum']),
                          ),
                        if (counters['gold'] > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child:
                                trophyType('gold', quantity: counters['gold']),
                          ),
                        if (counters['silver'] > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: trophyType('silver',
                                quantity: counters['silver']),
                          ),
                        if (counters['bronze'] > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: trophyType('bronze',
                                quantity: counters['bronze']),
                          ),
                        Tooltip(
                          message: regionalText['overview']['trophyScore'],
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              children: [
                                Icon(Icons.timeline,
                                    color: themeSelector["secondary"]
                                        [settings.get("theme")]),
                                SizedBox(width: 5),
                                Text(
                                  currentTrophyPoints.toString(),
                                  style: textSelection(),
                                ),
                                if (when.contains('current'))
                                  Row(
                                    children: [
                                      SizedBox(width: 5),
                                      Icon(
                                          currentTrophyPoints >
                                                  previousTrophyPoints
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          color: themeSelector["secondary"]
                                              [settings.get("theme")]),
                                    ],
                                  )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  //? Trophy rarity
                  Container(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (counters['prestige'] > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: rarityType(
                                type: 'rarity7',
                                quantity: counters['prestige']),
                          ),
                        if (counters['ultraRare'] > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: rarityType(
                                type: 'rarity6',
                                quantity: counters['ultraRare']),
                          ),
                        if (counters['veryRare'] > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: rarityType(
                                type: 'rarity5',
                                quantity: counters['veryRare']),
                          ),
                        if (counters['rare'] > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: rarityType(
                                type: 'rarity4', quantity: counters['rare']),
                          ),
                        if (counters['uncommon'] > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: rarityType(
                                type: 'rarity3',
                                quantity: counters['uncommon']),
                          ),
                        if (counters['common'] > 0)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: rarityType(
                                type: 'rarity1', quantity: counters['common']),
                          ),
                        Tooltip(
                          message: regionalText['overview']['rarityScore'],
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              children: [
                                Icon(Icons.timeline,
                                    color: themeSelector["secondary"]
                                        [settings.get("theme")]),
                                SizedBox(width: 5),
                                Text(
                                  currentRarityPoints.toString(),
                                  style: textSelection(),
                                ),
                                if (when.contains('current'))
                                  Row(
                                    children: [
                                      SizedBox(width: 5),
                                      Icon(
                                          currentRarityPoints >
                                                  previousRarityPoints
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          color: themeSelector["secondary"]
                                              [settings.get("theme")]),
                                    ],
                                  )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            //? Overview name
            Text(
              regionalText['overview']['rarestTrophy'],
              style: textSelection(),
              textAlign: TextAlign.left,
            ),
            trophyWidgets[0],
          ],
        ),
      );
    }

    return Container();
  }

  //? This boolean stores if the update has started or not.
  bool updateStart = false;

  //? Initialize the website
  final String website;
  _OverviewState(this.website);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
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
          regionalText['overview']['appBar']
              .replaceAll("PSNID", settings.get('psnID')),
          style: textSelection(theme: "textLightBold"),
        ),
      ),
      body: Container(
        decoration: backgroundDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //? This contains the overviews
            //? First is the default overview, should you not select Year over Year or Month over Month periods
            if (openMenus['YoY'] == false && openMenus['MoM'] == false)
              Container(
                child: Expanded(
                    child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      overviewDisplay(
                          when: 'previousMonth',
                          year: overview['year'] ?? DateTime.now().year,
                          month: overview['month'] ?? DateTime.now().month),
                      overviewDisplay(
                          when: 'currentMonth',
                          year: overview['year'] ?? DateTime.now().year,
                          month: overview['month'] ?? DateTime.now().month),
                      if (overview['month'] != null &&
                          overview['month'] != DateTime.now().month &&
                          (overview['year'] == null ||
                              overview['year'] == DateTime.now().year))
                        overviewDisplay(
                            when: 'currentMonth',
                            year: DateTime.now().year,
                            month: DateTime.now().month),
                      overviewDisplay(
                          when: 'previousYear',
                          year: overview['year'] ?? DateTime.now().year,
                          month: overview['month'] ?? DateTime.now().month),
                      overviewDisplay(
                          when: 'currentYear',
                          year: overview['year'] ?? DateTime.now().year,
                          month: overview['month'] ?? DateTime.now().month),
                      if (overview['year'] != null &&
                          overview['year'] != DateTime.now().year &&
                          (overview['month'] == null ||
                              overview['month'] == DateTime.now().month))
                        overviewDisplay(
                            when: 'currentYear',
                            year: DateTime.now().year,
                            month: DateTime.now().month),
                    ],
                  ),
                )),
              ),
            //? First is the default overview, should you not select Year over Year or Month over Month periods
            if (openMenus['MoM'] == true)
              Container(
                child: Expanded(
                    child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      for (var i = 11; i >= 0; i--)
                        overviewDisplay(
                            when: 'currentMonth',
                            year: DateTime.now().year,
                            month: DateTime.now().month - i),
                    ],
                  ),
                )),
              ),
            //? First is the default overview, should you not select Year over Year or Month over Month periods
            if (openMenus['YoY'] == true)
              Container(
                child: Expanded(
                    child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      for (var i = 0; i < (years ?? []).length; i++)
                        overviewDisplay(
                            when: 'currentYear',
                            year: years[i],
                            month: DateTime.now().month),
                    ],
                  ),
                )),
              ),
            //? This is the bottom bar containing the filters and sorting options for the trophy list.
            Container(
              width: MediaQuery.of(context).size.width,
              color: themeSelector["primary"][settings.get("theme")],
              child: Column(
                children: [
                  //? Filter trophies by specific date
                  if (openMenus['date'] == true)
                    Container(
                      height: Platform.isWindows ? 40 : 35,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //? Enable MoM overview
                          Tooltip(
                            message: regionalText['overview']['MoM'],
                            child: InkWell(
                              child: Container(
                                height: Platform.isWindows ? 35 : 22,
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  border: Border.all(
                                      color: openMenus['MoM'] == true
                                          ? Colors.green
                                          : Colors.transparent,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Center(
                                  child: Text(
                                    regionalText['log']['months'] +
                                        "/" +
                                        regionalText['log']['months'],
                                    style: textSelection(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  if (openMenus['MoM'] == true) {
                                    openMenus['MoM'] = false;
                                  } else {
                                    openMenus['YoY'] = false;
                                    overview['month'] = null;
                                    overview['year'] = null;
                                    openMenus['MoM'] = true;
                                  }
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 20),
                          //? Months selector
                          DropdownButton<String>(
                            hint: Text(
                                overview['month'] != null
                                    ? DateFormat.MMMM(Platform.localeName)
                                        .format(DateTime(1, overview['month']))
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
                                overview['month'] = int.parse(newValue);
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
                          SizedBox(width: 20),
                          //? Enable YoY overview
                          Tooltip(
                            message: regionalText['overview']['YoY'],
                            child: InkWell(
                              child: Container(
                                height: Platform.isWindows ? 35 : 22,
                                decoration: BoxDecoration(
                                  //? To paint the border, we check the value of the settings for this website is true.
                                  border: Border.all(
                                      color: openMenus['YoY'] == true
                                          ? Colors.green
                                          : Colors.transparent,
                                      width: Platform.isWindows ? 5 : 2),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
                                ),
                                child: Center(
                                  child: Text(
                                    regionalText['log']['years'] +
                                        "/" +
                                        regionalText['log']['years'],
                                    style: textSelection(),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  if (openMenus['YoY'] == true) {
                                    openMenus['YoY'] = false;
                                  } else {
                                    openMenus['MoM'] = false;
                                    overview['month'] = null;
                                    overview['year'] = null;
                                    openMenus['YoY'] = true;
                                  }
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 20),
                          //? Years selector
                          DropdownButton<String>(
                            hint: Text(
                                overview['year'] != null
                                    ? overview['year'].toString()
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
                                overview['year'] = int.parse(newValue);
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
                        ],
                      ),
                    ),
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
                                          color: overview['platinum'] == true
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
                                          if (overview['platinum'] == false)
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
                                      if (overview['platinum'] != true) {
                                        overview['platinum'] = true;
                                      } else {
                                        overview['platinum'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['gold'] == true
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
                                          if (overview['gold'] == false)
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
                                      if (overview['gold'] != true) {
                                        overview['gold'] = true;
                                      } else {
                                        overview['gold'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['silver'] == true
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
                                          if (overview['silver'] == false)
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
                                      if (overview['silver'] != true) {
                                        overview['silver'] = true;
                                      } else {
                                        overview['silver'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['bronze'] == true
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
                                          if (overview['bronze'] == false)
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
                                      if (overview['bronze'] != true) {
                                        overview['bronze'] = true;
                                      } else {
                                        overview['bronze'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['prestige'] == true
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
                                          if (overview['prestige'] == false)
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
                                      if (overview['prestige'] != true) {
                                        overview['prestige'] = true;
                                      } else {
                                        overview['prestige'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['ultraRare'] == true
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
                                          if (overview['ultraRare'] == false)
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
                                      if (overview['ultraRare'] != true) {
                                        overview['ultraRare'] = true;
                                      } else {
                                        overview['ultraRare'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['veryRare'] == true
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
                                          if (overview['veryRare'] == false)
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
                                      if (overview['veryRare'] != true) {
                                        overview['veryRare'] = true;
                                      } else {
                                        overview['veryRare'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['rare'] == true
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
                                          if (overview['rare'] == false)
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
                                      if (overview['rare'] != true) {
                                        overview['rare'] = true;
                                      } else {
                                        overview['rare'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['uncommon'] == true
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
                                          if (overview['uncommon'] == false)
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
                                      if (overview['uncommon'] != true) {
                                        overview['uncommon'] = true;
                                      } else {
                                        overview['uncommon'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['common'] == true
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
                                          if (overview['common'] == false)
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
                                      if (overview['common'] != true) {
                                        overview['common'] = true;
                                      } else {
                                        overview['common'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['psv'] == true
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
                                          if (overview['psv'] == false)
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
                                      if (overview['psv'] != true) {
                                        overview['psv'] = true;
                                      } else {
                                        overview['psv'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['ps3'] == true
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
                                          if (overview['ps3'] == false)
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
                                      if (overview['ps3'] != true) {
                                        overview['ps3'] = true;
                                      } else {
                                        overview['ps3'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['ps4'] == true
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
                                          if (overview['ps4'] == false)
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
                                      if (overview['ps4'] != true) {
                                        overview['ps4'] = true;
                                      } else {
                                        overview['ps4'] = false;
                                      }
                                      settings.put('overview', overview);
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
                                          color: overview['ps5'] == true
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
                                          if (overview['ps5'] == false)
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
                                      if (overview['ps5'] != true) {
                                        overview['ps5'] = true;
                                      } else {
                                        overview['ps5'] = false;
                                      }
                                      settings.put('overview', overview);
                                    });
                                  }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  //? Contains all the buttons to open menus
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        regionalText['trophies']['options'],
                        style: textSelection(),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: Platform.isWindows ? 40 : 25),
                      //? Date and Time
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
                                  openMenus['date'] = true;
                                } else {
                                  openMenus['date'] = false;
                                  openMenus['month'] = null;
                                  openMenus['year'] = null;
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
                              });
                              menuCloser.run(() {
                                if (mounted) {
                                  setState(() {
                                    openMenus['type'] = false;
                                  });
                                }
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
                              });
                              menuCloser.run(() {
                                if (mounted) {
                                  setState(() {
                                    openMenus['rarity'] = false;
                                  });
                                }
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
                              });
                              menuCloser.run(() {
                                if (mounted) {
                                  setState(() {
                                    openMenus['platform'] = false;
                                  });
                                }
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
                                overview = {
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
                                };
                                openMenus = {
                                  'search': false,
                                  'type': false,
                                  'rarity': false,
                                  'platform': false,
                                  'date': false,
                                  'YoY': false,
                                  'MoM': false
                                };
                              });
                              settings.put('overview', overview);
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
    ));
  }
}

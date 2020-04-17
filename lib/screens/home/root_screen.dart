import 'package:dadguide2/components/firebase/ads.dart';
import 'package:dadguide2/components/firebase/analytics.dart';
import 'package:dadguide2/components/ui/navigation.dart';
import 'package:dadguide2/components/updates/data_update.dart';
import 'package:dadguide2/data/tables.dart';
import 'package:dadguide2/l10n/localizations.dart';
import 'package:dadguide2/screens/dungeon/dungeon_list_tab.dart';
import 'package:dadguide2/screens/dungeon_info/dungeon_info_subtab.dart';
import 'package:dadguide2/screens/dungeon_info/sub_dungeon_sheet.dart';
import 'package:dadguide2/screens/egg_machine/egg_machine_subtab.dart';
import 'package:dadguide2/screens/event/event_tab.dart';
import 'package:dadguide2/screens/exchange/exchange_subtab.dart';
import 'package:dadguide2/screens/monster/monster_list_tab.dart';
import 'package:dadguide2/screens/monster/monster_search_modal.dart';
import 'package:dadguide2/screens/monster_compare/monster_compare.dart';
import 'package:dadguide2/screens/monster_info/monster_info_subtab.dart';
import 'package:dadguide2/screens/settings/settings_tab.dart';
import 'package:dadguide2/theme/style.dart';
import 'package:flutter/material.dart';

/// Paths to the various screens that the user can navigate to.
///
/// The root screen is actually a single route; hitting the back button does not move the user
/// between views.
///
/// All other screens are nested under the root, and respect the back button all the way up to the
/// root screen.
class TabNavigatorRoutes {
  static const String root = '/';
  static const String monsterList = MonsterListArgs.routeName;
  static const String monsterDetail = MonsterDetailArgs.routeName;
  static const String dungeonDetail = DungeonDetailArgs.routeName;
  static const String subDungeonSelection = SubDungeonSelectionArgs.routeName;
  static const String filterMonsters = FilterMonstersArgs.routeName;
  static const String eggMachines = EggMachineArgs.routeName;
  static const String exchanges = ExchangeArgs.routeName;
  static const String monsterCompare = MonsterCompareArgs.routeName;
}

/// Each tab is represented by a TabNavigator with a different rootItem. The tabs all have the
/// ability to go to the various sub screens, although some will never use it (e.g. settings).
///
/// Each TabNavigator wraps its own Navigator, allowing for independent back-stacks. Clicking
/// between tabs will wipe out the back-stack.
class TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget rootItem;

  TabNavigator({this.navigatorKey, this.rootItem});

  @override
  Widget build(BuildContext context) {
    return Navigator(
        key: navigatorKey,
        initialRoute: TabNavigatorRoutes.root,
        onGenerateRoute: (routeSettings) {
          switch (routeSettings.name) {
            case TabNavigatorRoutes.root:
              // The root tab is wrapped by a DataUpdaterWidget which will force a refresh if an
              // update ever occurs while the tab is loaded.
              return MaterialPageRoute(builder: (context) => DataUpdaterWidget(rootItem));
            case TabNavigatorRoutes.monsterDetail:
              MonsterDetailArgs args = routeSettings.arguments;
              return MaterialPageRoute(builder: (context) => MonsterDetailScreen(args));
            case TabNavigatorRoutes.monsterList:
              var args = routeSettings.arguments as MonsterListArgs;
              return MaterialPageRoute<Monster>(builder: (context) => MonsterTab(args: args));
            case TabNavigatorRoutes.dungeonDetail:
              var args = routeSettings.arguments as DungeonDetailArgs;
              return MaterialPageRoute(builder: (context) => DungeonDetailScreen(args));
            case TabNavigatorRoutes.subDungeonSelection:
              var args = routeSettings.arguments as SubDungeonSelectionArgs;
              return MaterialPageRoute(builder: (context) => SelectSubDungeonScreen(args));
            case TabNavigatorRoutes.filterMonsters:
              var args = routeSettings.arguments as FilterMonstersArgs;
              return MaterialPageRoute(builder: (context) => FilterMonstersScreen(args));
            case TabNavigatorRoutes.eggMachines:
              var args = routeSettings.arguments as EggMachineArgs;
              return MaterialPageRoute(builder: (context) => EggMachineScreen(args));
            case TabNavigatorRoutes.exchanges:
              var args = routeSettings.arguments as ExchangeArgs;
              return MaterialPageRoute(builder: (context) => ExchangeScreen(args));
            case TabNavigatorRoutes.monsterCompare:
              var args = routeSettings.arguments as MonsterCompareArgs;
              return MaterialPageRoute(builder: (context) => MonsterCompareScreen(args));
            default:
              throw 'Unexpected route';
          }
        });
  }
}

/// Controls the display of the tabs, including tracking which tab is currently visible.
class StatefulHomeScreen extends StatefulWidget {
  StatefulHomeScreen({Key key}) : super(key: key);

  @override
  _StatefulHomeScreenState createState() => _StatefulHomeScreenState();
}

class _StatefulHomeScreenState extends State<StatefulHomeScreen> {
  static final eventNavKey = GlobalKey<NavigatorState>();
  static final monsterNavKey = GlobalKey<NavigatorState>();
  static final dungeonNavKey = GlobalKey<NavigatorState>();
  // The utils tab is currently disabled due to lack of content.
  // static final utilsNavKey = GlobalKey<NavigatorState>();
  static final settingsNavKey = GlobalKey<NavigatorState>();

  static List<TabNavigator> _widgetOptions = [
    TabNavigator(
      navigatorKey: eventNavKey,
      rootItem: EventTab(key: PageStorageKey('EventTab')),
    ),
    TabNavigator(
      navigatorKey: monsterNavKey,
      rootItem: MonsterTab(
        args: MonsterListArgs(MonsterListAction.showDetails),
        key: PageStorageKey('MonsterTab'),
      ),
    ),
    TabNavigator(
      navigatorKey: dungeonNavKey,
      rootItem: DungeonTab(key: PageStorageKey('DungeonTab')),
    ),
//    TabNavigator(
//      navigatorKey: utilsNavKey,
//      rootItem: UtilsScreen(key: PageStorageKey('UtilsTab')),
//    ),
    TabNavigator(
      navigatorKey: settingsNavKey,
      rootItem: SettingsScreen(key: PageStorageKey('SettingsTab')),
    ),
  ];

  /// The currently selected tab.
  int _selectedIndex = 0;

  /// Bottom ad to display.
  BannerAdManager adManager = new BannerAdManager();

  @override
  void initState() {
    super.initState();
    _recordCurrentScreenEvent();
    adManager.init();
  }

  @override
  void dispose() {
    if (adManager != null) {
      adManager.dispose();
      adManager = null;
    }
    super.dispose();
  }

  /// Triggered whenever a user clicks on a new tab. Swaps the currently displayed tab UI.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _recordCurrentScreenEvent();
    });
  }

  /// Records a screen view of the currently visible widget.
  void _recordCurrentScreenEvent() =>
      screenChangeEvent(_widgetOptions[_selectedIndex].rootItem.runtimeType.toString());

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Only respect the back button if the currently visible tab's navigator says its ok.
      onWillPop: () async =>
          !await _widgetOptions[_selectedIndex].navigatorKey.currentState.maybePop(),
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              body: SafeArea(child: _widgetOptions[_selectedIndex]),
              // Prevent the tabs at the bottom from floating above the keyboard.
              resizeToAvoidBottomInset: false,
              bottomNavigationBar: BottomNavOptions(_selectedIndex, _onItemTapped),
            ),
          ),
          // Reserve room for the banner ad.
          AdAvailabilitySpacerWidget(),
        ],
      ),
    );
  }
}

/// Tabs at the bottom that switch views.
class BottomNavOptions extends StatelessWidget {
  final int selectedIdx;
  final void Function(int) onTap;

  BottomNavOptions(this.selectedIdx, this.onTap);

  @override
  Widget build(BuildContext context) {
    var loc = DadGuideLocalizations.of(context);

    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          title: Text(loc.tabEvent),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.format_line_spacing),
          title: Text(loc.tabMonster),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          title: Text(loc.tabDungeon),
        ),
//        BottomNavigationBarItem(
//          icon: Icon(Icons.move_to_inbox),
//          title: Text('Util'),
//        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          title: Text(loc.tabSetting),
        ),
      ],
      currentIndex: selectedIdx,
      selectedItemColor: Colors.blue,
      unselectedItemColor: grey(context, 1000),
      showUnselectedLabels: true,
      onTap: onTap,
    );
  }
}

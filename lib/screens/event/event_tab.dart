import 'package:dadguide2/components/enums.dart';
import 'package:dadguide2/components/images.dart';
import 'package:dadguide2/components/navigation.dart';
import 'package:dadguide2/components/settings_manager.dart';
import 'package:dadguide2/data/data_objects.dart';
import 'package:dadguide2/data/database.dart';
import 'package:dadguide2/data/tables.dart';
import 'package:dadguide2/screens/event/update_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'event_search_bloc.dart';

DateTime _toStartOfDay(DateTime time) {
  return DateTime(time.year, time.month, time.day);
}

var _currentEventDate = _toStartOfDay(DateTime.now());
final _dateFormatter = DateFormat.MMMMd();

class EventTab extends StatelessWidget {
  EventTab({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('adding an eventtab');
    return DefaultTabController(
      length: 4,
      initialIndex: 0,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: EventListHeader(),
        ),
        body: ChangeNotifierProvider(
          builder: (context) => ScheduleDisplayState(),
          child: Column(children: <Widget>[
            Expanded(child: EventListTabs()),
            DateSelectBar(),
          ]),
        ),
      ),
    );
  }
}

class EventListHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: Row(
        children: <Widget>[
          InkWell(
              onTap: () => print('hi'),
              child: SizedBox(width: 60, height: 40, child: Icon(Icons.event))),
          Flexible(
            child: TabBar(tabs: [
              Tab(text: 'All'),
              Tab(text: 'Guerrilla'),
              Tab(text: 'Special'),
              Tab(text: 'News'),
            ]),
          ),
        ],
      ),
    );
  }
}

class EventListTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TabBarView(children: <Widget>[
      EventList(ScheduleTabKey.all),
      EventList(ScheduleTabKey.guerrilla),
      EventList(ScheduleTabKey.special),
      EventList(ScheduleTabKey.news),
    ]);
  }
}

class EventList extends StatelessWidget {
  final ScheduleTabKey _tabKey;

  EventList(this._tabKey);

  @override
  Widget build(BuildContext context) {
    var displayState = Provider.of<ScheduleDisplayState>(context);

    return ChangeNotifierProvider(
        key: UniqueKey(),
        builder: (context) => ScheduleTabState(displayState.servers, displayState.starters, _tabKey,
            _currentEventDate, displayState.hideClosed),
        child: EventListContents());
  }
}

class EventListContents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var displayState = Provider.of<ScheduleTabState>(context);
    return StreamBuilder<List<ListEvent>>(
        stream: displayState.searchBloc.searchResults,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            Fimber.e('Error loading data', ex: snapshot.error);
            return Center(child: Icon(Icons.error));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var data = snapshot.data;
          return data == null
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) => EventListRow(data[index]),
                );
        });
  }
}

void launchDialog(BuildContext context) async {
  showDialog(
      context: context,
      builder: (innerContext) {
        return SimpleDialog(
          title: const Text('Utilities'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(innerContext);
                await DatabaseHelper.instance.reloadDb();
              },
              child: const Text('Reload DB'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(innerContext);
                await showUpdateDialog(context);
              },
              child: const Text('Trigger Update'),
            ),
          ],
        );
      });
}

class EventSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blue,
//      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.new_releases),
            color: Colors.red,
            onPressed: () => launchDialog(context),
            padding: EdgeInsets.all(0),
          ),
          Expanded(child: Center(child: Text('All'))),
          Expanded(child: Center(child: Text('Guerrilla'))),
          Expanded(child: Center(child: Text('Special'))),
          Expanded(child: Center(child: Text('News'))),
        ],
      ),
    );
  }
}

class DateSelectBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var displayState = Provider.of<ScheduleDisplayState>(context);

    return Container(
      color: Colors.grey[400],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 20,
              child: FlatButton(
                onPressed: () => DatePicker.showDatePicker(
                  context,
                  currentTime: _currentEventDate,
                  minTime: DateTime.now().subtract(Duration(days: 1)),
                  maxTime: _currentEventDate.add(Duration(days: 30)),
                  onConfirm: (d) => displayState.currentEventDate = d,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.event),
                    SizedBox(width: 4),
                    Text(_dateFormatter.format(_currentEventDate)),
                  ],
                ),
              ),
            ),
            Spacer(),
            SizedBox(
              height: 20,
              child: FlatButton(
                onPressed: null,
                child: Icon(MaterialCommunityIcons.getIconData('file-document-box-outline')),
              ),
            ),
            SizedBox(
              height: 20,
              child: FlatButton(
                onPressed: null,
                child: Icon(MaterialCommunityIcons.getIconData('egg')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventListRow extends StatelessWidget {
  final ListEvent _model;
  const EventListRow(this._model, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var se = _model;
    return InkWell(
      onTap: goToDungeonFn(context, _model.dungeon?.dungeonId, 0),
      child: Container(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            children: <Widget>[
              PadIcon(se.iconId),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(se.headerText()),
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.caption,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text(se.underlineText(DateTime.now()))]),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}

class ScheduleDisplayState with ChangeNotifier {
  List<Country> servers = [Prefs.eventCountry];
  List<StarterDragon> starters = Prefs.eventStarters;
  bool hideClosed = Prefs.eventHideClosed;

  void set currentEventDate(DateTime date) {
    _currentEventDate = _toStartOfDay(date);
    notifyListeners();
  }
}

class ScheduleTabState with ChangeNotifier {
  final searchBloc = EventSearchBloc();

  final List<Country> servers;
  final List<StarterDragon> starters;
  final ScheduleTabKey tab;
  final DateTime dateStart;
  final bool hideClosed;

  ScheduleTabState(this.servers, this.starters, this.tab, this.dateStart, this.hideClosed) {
    search();
  }

  void search() {
    searchBloc.search(EventSearchArgs.from(
        servers, starters, tab, dateStart, dateStart.add(Duration(days: 1)), hideClosed));
  }
}

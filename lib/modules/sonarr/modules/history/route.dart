import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/sonarr.dart';

class SonarrHistoryRoute extends StatefulWidget {
    @override
    State<SonarrHistoryRoute> createState() => _State();
}

class _State extends State<SonarrHistoryRoute> with AutomaticKeepAliveClientMixin {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
    
    @override
    bool get wantKeepAlive => true;

    @override
    void initState() {
        super.initState();
        SchedulerBinding.instance.scheduleFrameCallback((_) => _refresh());
    }

    Future<void> _refresh() async {
        SonarrState _state = Provider.of<SonarrState>(context, listen: false);
        _state.resetHistory();
        await _state.history;
    }

    @override
    Widget build(BuildContext context) {
        super.build(context);
        return Scaffold(
            key: _scaffoldKey,
            body: _body,
        );
    }

    Widget get _body => LSRefreshIndicator(
        refreshKey: _refreshKey,
        onRefresh: _refresh,
        child: Selector<SonarrState, Future<SonarrHistory>>(
            selector: (_, state) => state.history,
            builder: (context, future, _) => FutureBuilder(
                future: future,
                builder: (context, AsyncSnapshot<SonarrHistory> snapshot) {
                    if(snapshot.hasError) {
                        if(snapshot.connectionState != ConnectionState.waiting) {
                            LunaLogger().error('Unable to fetch Sonarr history', snapshot.error, StackTrace.current);
                        }
                        return LSErrorMessage(onTapHandler: () async => _refreshKey.currentState.show());
                    }
                    if(snapshot.hasData) {
                        return snapshot.data.records.length == 0
                            ? _noHistory()
                            : _history(snapshot.data);
                    }
                    return LSLoader();
                },
            ),
        ),
    );

    Widget _noHistory() => LSGenericMessage(
        text: 'No History Found',
        showButton: true,
        buttonText: 'Refresh',
        onTapHandler: () async => _refreshKey.currentState.show(),
    );

    Widget _history(SonarrHistory history) => LSListView(
        children: List.generate(
            history.records.length,
            (index) => SonarrHistoryTile(record: history.records[index]),
        ),
    );
}
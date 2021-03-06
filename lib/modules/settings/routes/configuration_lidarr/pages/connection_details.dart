import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/modules/lidarr.dart';
import 'package:lunasea/modules/settings.dart';

class SettingsConfigurationLidarrConnectionDetailsRouter extends LunaPageRouter {
    SettingsConfigurationLidarrConnectionDetailsRouter() : super('/settings/configuration/lidarr/connection');

    @override
    void defineRoute(FluroRouter router) => super.noParameterRouteDefinition(router, _SettingsConfigurationLidarrRoute());
}

class _SettingsConfigurationLidarrRoute extends StatefulWidget {
    @override
    State<_SettingsConfigurationLidarrRoute> createState() => _State();
}

class _State extends State<_SettingsConfigurationLidarrRoute> with LunaScrollControllerMixin {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldKey,
            appBar: _appBar(),
            body: _body(),
        );
    }

    Widget _appBar() {
        return LunaAppBar(
            title: 'Connection Details',
            scrollControllers: [scrollController],
        );
    }

    Widget _body() {
        return ValueListenableBuilder(
            valueListenable: Database.profilesBox.listenable(),
            builder: (context, box, _) => LunaListView(
                controller: scrollController,
                children: [
                    _host(),
                    _apiKey(),
                    _customHeaders(),
                    _testConnection(),
                ],
            ),
        );
    }

    Widget _host() {
        String host = Database.currentProfileObject.lidarrHost;
        return LunaListTile(
            context: context,
            title: LunaText.title(text: 'Host'),
            subtitle: LunaText.subtitle(text: (host ?? '').isEmpty ? 'Not Set' : host),
            trailing: LunaIconButton(icon: Icons.arrow_forward_ios_rounded),
            onTap: () async {
                List<dynamic> _values = await SettingsDialogs.editHost(context, 'Lidarr Host', prefill: Database.currentProfileObject.lidarrHost ?? '');
                if(_values[0]) {
                    Database.currentProfileObject.lidarrHost = _values[1];
                    Database.currentProfileObject.save();
                    context.read<LidarrState>().reset();
                }
            },
        );
    }

    Widget _apiKey() {
        String apiKey = Database.currentProfileObject.lidarrKey;
        return LunaListTile(
            context: context,
            title: LunaText.title(text: 'API Key'),
            subtitle: LunaText.subtitle(text: (apiKey ?? '').isEmpty ? 'Not Set' : '••••••••••••'),
            trailing: LunaIconButton(icon: Icons.arrow_forward_ios_rounded),
            onTap: () async {
                Tuple2<bool, String> _values = await LunaDialogs().editText(context, 'Lidarr API Key', prefill: Database.currentProfileObject.lidarrKey ?? '');
                if(_values.item1) {
                    Database.currentProfileObject.lidarrKey = _values.item2;
                    Database.currentProfileObject.save();
                    context.read<LidarrState>().reset();
                }
            },
        );
    }

    Widget _testConnection() {
        return LunaButtonContainer(
            children: [
                LunaButton(
                    text: 'Test Connection',
                    onTap: () async {
                        ProfileHiveObject _profile = Database.currentProfileObject;
                        if(_profile.lidarrHost == null || _profile.lidarrHost.isEmpty) {
                            showLunaErrorSnackBar(
                                context: context,
                                title: 'Host Required',
                                message: 'Host is required to connect to Lidarr',
                            );
                            return;
                        }
                        if(_profile.lidarrKey == null || _profile.lidarrKey.isEmpty) {
                            showLunaErrorSnackBar(
                                context: context,
                                title: 'API Key Required',
                                message: 'API key is required to connect to Lidarr',
                            );
                            return;
                        }
                        LidarrAPI.from(Database.currentProfileObject).testConnection()
                        .then((_) => showLunaSuccessSnackBar(
                            context: context,
                            title: 'Connected Successfully',
                            message: 'Lidarr is ready to use with ${Constants.APPLICATION_NAME}',
                        )).catchError((error, trace) {
                            LunaLogger().error('Connection Test Failed', error, trace);
                            showLunaErrorSnackBar(
                                context: context,
                                title: 'Connection Test Failed',
                                error: error,
                            );
                        });
                    },
                ),
            ],
        );
    }

    Widget _customHeaders() {
        return LunaListTile(
            context: context,
            title: LunaText.title(text: 'Custom Headers'),
            subtitle: LunaText.subtitle(text: 'Add Custom Headers to Requests'),
            trailing: LunaIconButton(icon: Icons.arrow_forward_ios_rounded),
            onTap: () async => SettingsConfigurationLidarrHeadersRouter().navigateTo(context),
        );
    }
}

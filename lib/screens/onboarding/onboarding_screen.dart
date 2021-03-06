import 'package:dadguide2/components/config/settings_manager.dart';
import 'package:dadguide2/components/ui/task_progress.dart';
import 'package:dadguide2/components/utils/app_reloader.dart';
import 'package:dadguide2/l10n/localizations.dart';
import 'package:dadguide2/screens/onboarding/onboarding_task.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';
import 'package:provider/provider.dart';

/// Displays the first-launch UI where the database and icon pack are downloaded and extracted.
///
/// The user can also select a few settings while they wait.
class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var loc = DadGuideLocalizations.of(context);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.title),
        ),
        body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.onboardingTitle,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  SizedBox(height: 8),
                  Divider(),
                  TaskListProgress(OnboardingTaskManager.instance.task),
                  SizedBox(height: 5),
                  Divider(),
                  ListTile(
                    title: Text(loc.onboardingWaitingTitle),
                    subtitle: Text(loc.onboardingWaitingSubTitle),
                  ),
                  SizedBox(height: 16),
                  DropdownPreference<int>(
                    loc.onboardingDisplayLanguage,
                    PrefKeys.infoLanguage,
                    desc: loc.onboardingDisplayLanguageDesc,
                    defaultVal: Prefs.defaultUiLanguageValue,
                    values: Prefs.languageValues,
                    displayValues: Prefs.languageDisplayValues,
                    onChange: (int v) {
                      Prefs.setAllLanguage(v);
                      Provider.of<ReloadAppChangeNotifier>(context).notify();
                    },
                  ),
                  DropdownPreference<int>(
                    loc.onboardingGameCountry,
                    PrefKeys.gameCountry,
                    desc: loc.onboardingGameCountryDesc,
                    defaultVal: Prefs.defaultGameCountryValue,
                    values: Prefs.countryValues,
                    displayValues: Prefs.countryDisplayValues,
                    onChange: (int v) => Prefs.setAllCountry(v),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';

const String kOptionTimeLimitMs = 'time-limit-ms';
const String kOptionTemplate = 'template';
const String kOptionDevice = 'device';
const String kOptionTraceUtility = 'trace-utility';
const String kFlagVerbose = 'verbose';

abstract class BaseCommand extends Command {
  @protected
  void checkRequiredOption(String option) {
    if (argResults[option] == null) {
      throw Exception('Option $option is required.');
    }
  }

  @protected
  void addTraceUtilityOption() {
    argParser.addOption(
      kOptionTraceUtility,
      abbr: 'u',
      help: 'path to TraceUtility binary (https://github.com/Qusic/TraceUtility)',
    );
  }

  @protected
  bool get verbose => globalResults[kFlagVerbose];
  @protected
  String get traceUtility => argResults[kOptionTraceUtility];
}


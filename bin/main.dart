import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:measure/parser.dart';

const String kOptionTimeLimitMs = 'time-limit-ms';
const String kOptionTemplate = 'template';
const String kOptionDevice = 'device';
const String kOptionTraceUtility = 'trace-utility';
const String kFlagVerbose = 'verbose';

abstract class BaseCommand extends Command {
  void _checkRequiredOption(String option) {
    if (argResults[option] == null) {
      throw Exception('Option $option is required.');
    }
  }

  void _addTraceUtilityOption() {
    argParser.addOption(
      kOptionTraceUtility,
      abbr: 'u',
      help: 'path to TraceUtility binary (https://github.com/Qusic/TraceUtility)',
    );
  }

  bool get _verbose => globalResults[kFlagVerbose];
  String get _traceUtility => argResults[kOptionTraceUtility];
}

// Its parent is IosCpuGpu command.
class IosCpuGpuParse extends BaseCommand {
  @override
  String get name => 'parse';
  @override
  String get description => 'parse an existing instruments trace with CPU/GPU measurements.';

  IosCpuGpuParse() {
    _addTraceUtilityOption();
  }

  @override
  String get usage {
    List<String> lines = super.usage.split('\n');
    lines[0] = 'Usage: measure ioscpugpu -u <trace-utility-path> parse <trace-file-path>';
    return lines.join('\n');
  }

  @override
  Future<void> run() async {
    _checkRequiredOption(kOptionTraceUtility);
    if (argResults.rest.length != 1) {
      print(usage);
      throw Exception('exactly one argument <trace-file-path> expected');
    }
    final String path = argResults.rest[0];

    CpuGpuResult result = Parser(_verbose, _traceUtility).parseCpuGpu(path);
    print('$result');  // TODO NEXT
  }
}

class IosCpuGpuNew extends BaseCommand {
  @override
  String get name => 'new';
  @override
  String get description => 'Take a new measurement on the iOS CPU/GPU percentage (of Flutter Runner).';

  IosCpuGpuNew() {
    argParser.addOption(
      kOptionTimeLimitMs,
      abbr: 'l',
      defaultsTo: '5000',
      help: 'time limit (in ms) to run instruments for measuring',
    );
    argParser.addOption(
      kOptionTemplate,
      abbr: 't',
      help: 'instruments template'
    );
    argParser.addOption(
      kOptionDevice,
      abbr: 'w',
      help: 'device identifier recognizable by instruments (e.g., 00008020-000364CE0AF8003A)',
    );
    _addTraceUtilityOption();
  }

  @override
  Future<void> run() async {
    _checkRequiredOption(kOptionTemplate);
    _checkRequiredOption(kOptionTraceUtility);
    _checkDevice();
    final List<String> args = [
      '-l', argResults[kOptionTimeLimitMs],
      '-t', argResults[kOptionTemplate],
      '-w', _device,
    ];
    if (_verbose) {
      print('instruments args: $args');
    }
    ProcessResult processResult = await Process.runSync('instruments', args);
    _parseTraceFilename(processResult.stdout.toString());

    CpuGpuResult result = Parser(_verbose, _traceUtility).parseCpuGpu(_traceFilename);
    print('$result');  // TODO NEXT
  }
  String _traceFilename;
  Future<void> _parseTraceFilename(String out) async {
    const String kPrefix = 'Instruments Trace Complete: ';
    int prefixIndex = out.indexOf(kPrefix);
    if (prefixIndex == -1) {
      throw Exception('Failed to parse instruments output:\n$out');
    }
    _traceFilename = out.substring(prefixIndex + kPrefix.length).trim();
  }

  String _device;
  void _checkDevice() {
    _device = argResults[kOptionDevice];
    if (_device == null) {
      ProcessResult result = Process.runSync('flutter', ['devices']);
      if (result.stdout.toString().contains('1 connected device')) {
        final List<String> lines = result.stdout.toString().split('\n');
        const String kSeparator = '•';
        for (String line in lines) {
          if (line.contains(kSeparator)) {
            int left = line.indexOf(kSeparator);
            int right = line.indexOf(kSeparator, left + 1);
            _device = line.substring(left + 1, right).trim();
          }
        }
        if (_device == null) {
          print('Failed to parse `flutter devices` output:\n ${result.stdout}');
        }
      } else {
        print('''
Option device is not provided, and `flutter devices` returns either 0 or more
than 1 devices, or errored.

stdout of `flutter devies`:
===========================
${result.stdout}
===========================

stderr of `flutter devies`:
===========================
${result.stderr}
===========================
'''
        );
      }
    }

    if (_device == null) {
      throw Exception('Failed to determine the device.');
    }
  }
}

class IosCpuGpu extends BaseCommand {
  @override
  String get name => 'ioscpugpu';
  @override
  String get description => 'Measure the CPU/GPU percentage (of Flutter Runner).';

  IosCpuGpu() {
    addSubcommand(IosCpuGpuNew());
    addSubcommand(IosCpuGpuParse());
  }
}

main(List<String> args) {
  final CommandRunner runner = CommandRunner('measure', 'Some measuring tools.');
  runner.argParser.addFlag(kFlagVerbose);

  runner.addCommand(IosCpuGpu());
  runner.run(args);
}
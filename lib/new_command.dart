import 'dart:io';

import 'base_command.dart';
import 'parser.dart';

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
    addTraceUtilityOption();
  }

  String get _timeLimit => argResults[kOptionTimeLimitMs];

  @override
  Future<void> run() async {
    checkRequiredOption(kOptionTemplate);
    checkRequiredOption(kOptionTraceUtility);
    _checkDevice();

    print('Running instruments on iOS device $_device for ${_timeLimit}ms');

    final List<String> args = [
      '-l', _timeLimit,
      '-t', argResults[kOptionTemplate],
      '-w', _device,
    ];
    if (verbose) {
      print('instruments args: $args');
    }
    ProcessResult processResult = await Process.runSync('instruments', args);
    _parseTraceFilename(processResult.stdout.toString());

    print('Parsing $_traceFilename');

    CpuGpuResult result = Parser(verbose, traceUtility).parseCpuGpu(_traceFilename);
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

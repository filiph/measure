import 'base_command.dart';
import 'parser.dart';

class IosCpuGpuParse extends BaseCommand {
  @override
  String get name => 'parse';
  @override
  String get description => 'parse an existing instruments trace with CPU/GPU measurements.';

  IosCpuGpuParse() {
    addTraceUtilityOption();
  }

  @override
  String get usage {
    List<String> lines = super.usage.split('\n');
    lines[0] = 'Usage: measure ioscpugpu -u <trace-utility-path> parse <trace-file-path>';
    return lines.join('\n');
  }

  @override
  Future<void> run() async {
    checkRequiredOption(kOptionTraceUtility);
    if (argResults.rest.length != 1) {
      print(usage);
      throw Exception('exactly one argument <trace-file-path> expected');
    }
    final String path = argResults.rest[0];

    CpuGpuResult result = Parser(verbose, traceUtility).parseCpuGpu(path);
    print('$result');  // TODO NEXT
  }
}

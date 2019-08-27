import 'package:args/command_runner.dart';

import 'package:measure/base_command.dart';
import 'package:measure/new_command.dart';
import 'package:measure/parse_command.dart';

class IosCpuGpu extends Command {
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
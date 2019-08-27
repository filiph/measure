import 'dart:io';

class CpuGpuResult {
  CpuGpuResult(this.gpuPercentage, this.cpuPercentage);

  final double gpuPercentage;
  final double cpuPercentage;

  @override
  String toString() {
    return 'gpu: $gpuPercentage%, cpu: $cpuPercentage%';
  }
}

class Parser {
  Parser(this.isVerbose, this.traceUtilityPath);

  final bool isVerbose;
  final String traceUtilityPath;

  CpuGpuResult parseCpuGpu(String filename) {
    ProcessResult result = Process.runSync(traceUtilityPath, [filename]);
    if (result.exitCode != 0) {
      print('TraceUtility stdout:\n${result.stdout.toString}\n\n');
      print('TraceUtility stderr:\n${result.stderr.toString}\n\n');
      throw Exception('TraceUtility failed with exit code ${result.exitCode}');
    }
    final List<String> lines = result.stderr.toString().split('\n');

    // toSet to remove duplicates
    List<String> gpuMeasurements = lines.where((String s) => s.contains('GPU')).toSet().toList();
    List<String> cpuMeasurements = lines.where((String s) => s.contains('Runner')).toSet().toList();
    gpuMeasurements.sort();
    cpuMeasurements.sort();

    if (isVerbose) {
      gpuMeasurements.forEach(print);
      cpuMeasurements.forEach(print);
    }

    return CpuGpuResult(_computeGpuPercent(gpuMeasurements), _computeCpuPercent(cpuMeasurements));
  }

  static final RegExp _percentagePattern = RegExp(r'(\d+(\.\d*)?)%');
  double _parseSingleGpuMeasurement(String line) {
    return double.parse(_percentagePattern.firstMatch(line).group(1));
  }

  double _computeGpuPercent(List<String> gpuMeasurements) {
    return _average(gpuMeasurements.map(_parseSingleGpuMeasurement));
  }

  // The return is a list of 2: the 1st is the time key string, the 2nd is the double percentage
  List<dynamic> _parseSingleCpuMeasurement(String line) {
    final String timeKey = line.substring(0, line.indexOf(','));
    RegExpMatch match = _percentagePattern.firstMatch(line);
    return <dynamic>[timeKey, match == null ? 0 : double.parse(_percentagePattern.firstMatch(line).group(1))];
  }

  double _computeCpuPercent(List<String> cpuMeasurements) {
    Iterable<List<dynamic>> results = cpuMeasurements.map(_parseSingleCpuMeasurement);
    Map<String, double> sums = {};
    for (List<dynamic> pair in results) {
      sums[pair[0]] = 0;
    }
    for (List<dynamic> pair in results) {
      sums[pair[0]] += pair[1];
    }
    if (isVerbose) {
      print('CPU maps: $sums');
    }
    // Exclude the points where percentage is 0 (that's usually the point at t = 0).
    return _average(sums.values.where((double x) => x > 0));
  }

  static double _average(Iterable<double> values) {
    return values.reduce((double a, double b) => a + b) / values.length;
  }
}

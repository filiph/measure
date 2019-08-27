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

  List<String> _gpuMeasurements;
  List<String> _cpuMeasurements;

  CpuGpuResult parseCpuGpu(String filename) {
    ProcessResult result = Process.runSync(traceUtilityPath, [filename]);
    if (result.exitCode != 0) {
      print('TraceUtility stdout:\n${result.stdout.toString}\n\n');
      print('TraceUtility stderr:\n${result.stderr.toString}\n\n');
      throw Exception('TraceUtility failed with exit code ${result.exitCode}');
    }
    final List<String> lines = result.stderr.toString().split('\n');

    // toSet to remove duplicates
    _gpuMeasurements = lines.where((String s) => s.contains('GPU')).toSet().toList();
    _cpuMeasurements = lines.where((String s) => s.contains('Runner')).toSet().toList();
    _gpuMeasurements.sort();
    _cpuMeasurements.sort();

    if (isVerbose) {
      _gpuMeasurements.forEach(print);
      _cpuMeasurements.forEach(print);
    }

    return CpuGpuResult(_computeGpuPercent(), _computeCpuPercent());
  }

  static final RegExp _percentagePattern = RegExp(r'(\d+(\.\d*)?)%');
  double _parseSingleGpuMeasurement(String line) {
    return double.parse(_percentagePattern.firstMatch(line).group(1));
  }

  double _computeGpuPercent() {
    return _average(_gpuMeasurements.map(_parseSingleGpuMeasurement));
  }

  // The return is a list of 2: the 1st is the time key string, the 2nd is the double percentage
  List<dynamic> _parseSingleCpuMeasurement(String line) {
    final String timeKey = line.substring(0, line.indexOf(','));
    RegExpMatch match = _percentagePattern.firstMatch(line);
    return <dynamic>[timeKey, match == null ? 0 : double.parse(_percentagePattern.firstMatch(line).group(1))];
  }

  double _computeCpuPercent() {
    Iterable<List<dynamic>> results = _cpuMeasurements.map(_parseSingleCpuMeasurement);
    Map<String, double> sums = {};
    for (List<dynamic> pair in results) {
      sums[pair[0]] = 0;
    }
    for (List<dynamic> pair in results) {
      sums[pair[0]] += pair[1];
    }

    // This key always has 0% usage. Remove it.
    assert(sums['00:00.000.000'] == 0);
    sums.remove('00:00.000.000');

    if (isVerbose) {
      print('CPU maps: $sums');
    }
    // Exclude the points where percentage is 0 (that's usually the point at t = 0).
    return _average(sums.values);
  }

  double _average(Iterable<double> values) {
    if (values == null || values.length == 0) {
      _gpuMeasurements.forEach(print);
      _cpuMeasurements.forEach(print);
      throw Exception('No valid measurements found.');
    }
    return values.reduce((double a, double b) => a + b) / values.length;
  }
}

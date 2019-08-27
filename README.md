To install, clone this repo on a Mac with Xcode, `dart`, and `flutter`
installed. Then run `pub get`:
```shell
git clone https://github.com/liyuqian/measure.git
cd measure
pub get
```

To run, connect a **single** iPhone, run a Flutter app on it, and
```shell
# assuming that you're in this Github checkout
dart bin/main.dart ioscpugpu new -u resources/TraceUtility -t resources/CpuGpuTemplate.tracetemplate
```

It currently outputs something like
```
gpu: 12.4%, cpu: 22.525%
```

Eventually, we'd like to hook this up to our CI system to continuously monitor
Flutter's CPU/GPU usages, which can be used to infer the energy usage.

For more information, you can install `measure` using pub
```shell
# assuming that you're in this Github checkout
pub global activate --source path ./
```
and run
```shell
measure help
measure help ioscpugpu
measure help ioscpugpu new
measure help ioscpugpu parse
```

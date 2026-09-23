const String kContentEngineVersion = 'v10_0';

enum ContentSessionMode { normal, daily, arena }

class ContentHistoryPolicy {
  final int sessionLimit;
  final int itemLimit;

  const ContentHistoryPolicy({this.sessionLimit = 60, this.itemLimit = 250});
}

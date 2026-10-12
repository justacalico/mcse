import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/state/dirs_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load returns nulls when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final dirs = await DirsState.load();
    expect(dirs.dataDir, isNull);
    expect(dirs.javaDir, isNull);
    expect(dirs.backupsDir, isNull);
  });

  test('load reads saved values', () async {
    SharedPreferences.setMockInitialValues({
      'dir_data': '/mnt/data',
      'dir_java': '/mnt/jdks',
      'dir_backups': '/mnt/zips',
    });
    final dirs = await DirsState.load();
    expect(dirs.dataDir, '/mnt/data');
    expect(dirs.javaDir, '/mnt/jdks');
    expect(dirs.backupsDir, '/mnt/zips');
  });

  test('setters persist and notify', () async {
    SharedPreferences.setMockInitialValues({});
    final dirs = await DirsState.load();
    var notified = 0;
    dirs.addListener(() => notified++);

    await dirs.setDataDir('/a');
    await dirs.setJavaDir('/b');
    await dirs.setBackupsDir('/c');
    expect(dirs.dataDir, '/a');
    expect(dirs.javaDir, '/b');
    expect(dirs.backupsDir, '/c');
    expect(notified, 3);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('dir_data'), '/a');
    expect(prefs.getString('dir_java'), '/b');
    expect(prefs.getString('dir_backups'), '/c');

    await dirs.setDataDir(null);
    await dirs.setJavaDir(null);
    await dirs.setBackupsDir(null);
    expect(dirs.dataDir, isNull);
    expect(dirs.javaDir, isNull);
    expect(dirs.backupsDir, isNull);
    expect(prefs.getString('dir_data'), isNull);
    expect(prefs.getString('dir_java'), isNull);
    expect(prefs.getString('dir_backups'), isNull);
    expect(notified, 6);
  });

  test('setters normalize whitespace and trailing separators', () async {
    SharedPreferences.setMockInitialValues({});
    final dirs = await DirsState.load();
    await dirs.setDataDir('  /a/b/  ');
    expect(dirs.dataDir, '/a/b');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('dir_data'), '/a/b');
    await dirs.setJavaDir('   ');
    expect(dirs.javaDir, isNull);
    expect(prefs.getString('dir_java'), isNull);
    await dirs.setBackupsDir('/');
    expect(dirs.backupsDir, '/');
  });

  test('windows drive root keeps its separator', () async {
    SharedPreferences.setMockInitialValues({});
    final dirs = await DirsState.load();
    await dirs.setDataDir('C:\\');
    expect(dirs.dataDir, 'C:\\');
    await dirs.setDataDir('D:\\games\\');
    expect(dirs.dataDir, 'D:\\games');
  });
}

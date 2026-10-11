import 'package:flutter_test/flutter_test.dart';
import 'package:mcse/utils/version_utils.dart';

void main() {
  group('Version.parse', () {
    test('parses plain and v-prefixed versions', () {
      expect(Version.parse('1.2.3')!.core, [1, 2, 3]);
      expect(Version.parse('v1.2.3')!.core, [1, 2, 3]);
      expect(Version.parse('V2.0.0')!.core, [2, 0, 0]);
    });

    test('rejects malformed input', () {
      for (final s in [
        null,
        '',
        '  ',
        '1.2',
        '1.2.3.4',
        'a.b.c',
        '1.02.3',
        '1.-2.3',
        '1.2.3-',
        '1.2.3-alfa..beta',
        '1.2.3-01',
        '1.2.3-äl',
      ]) {
        expect(Version.parse(s), isNull, reason: s ?? 'null');
      }
    });

    test('parses prerelease and ignores build metadata', () {
      final v = Version.parse('1.2.3-rc.1+build5')!;
      expect(v.pre, ['rc', '1']);
      expect(v.toString(), '1.2.3-rc.1');
    });
  });

  group('Version.compareTo', () {
    test('orders core versions', () {
      expect(Version.parse('1.0.0')!.compareTo(Version.parse('1.0.0')!), 0);
      expect(Version.parse('1.0.0')!.compareTo(Version.parse('2.0.0')!) < 0,
          isTrue);
      expect(Version.parse('1.10.0')!.compareTo(Version.parse('1.9.9')!) > 0,
          isTrue);
      expect(Version.parse('1.0.1')!.compareTo(Version.parse('1.0.0')!) > 0,
          isTrue);
    });

    test('prerelease lower than release', () {
      expect(
          Version.parse('1.0.0-rc.1')!.compareTo(Version.parse('1.0.0')!) < 0,
          isTrue);
      expect(
          Version.parse('1.0.0')!.compareTo(Version.parse('1.0.0-rc.1')!) > 0,
          isTrue);
    });

    test('prerelease comparison rules', () {
      // numeric < alphanumeric
      expect(
          Version.parse('1.0.0-1')!.compareTo(Version.parse('1.0.0-a')!) < 0,
          isTrue);
      expect(
          Version.parse('1.0.0-a')!.compareTo(Version.parse('1.0.0-1')!) > 0,
          isTrue);
      // numeric compare
      expect(
          Version.parse('1.0.0-2')!.compareTo(Version.parse('1.0.0-10')!) < 0,
          isTrue);
      // alpha compare
      expect(
          Version.parse('1.0.0-alpha')!.compareTo(Version.parse('1.0.0-beta')!) <
              0,
          isTrue);
      // shorter prefix < longer
      expect(
          Version.parse('1.0.0-rc')!.compareTo(Version.parse('1.0.0-rc.1')!) <
              0,
          isTrue);
      // equal
      expect(
          Version.parse('1.0.0-rc.1')!
              .compareTo(Version.parse('1.0.0-rc.1')!),
          0);
      // huge numeric identifiers don't overflow
      final big = '9' * 40;
      expect(
          Version.parse('1.0.0-$big')!
              .compareTo(Version.parse('1.0.0-${big}0')!) <
              0,
          isTrue);
    });
  });

  test('equality and hashCode', () {
    expect(Version.parse('1.2.3'), Version.parse('1.2.3'));
    expect(Version.parse('1.2.3'), isNot(Version.parse('1.2.4')));
    expect(Version.parse('1.2.3-a'), Version.parse('1.2.3-a'));
    expect(Version.parse('1.2.3-a'), isNot(Version.parse('1.2.3-b')));
    expect(Version.parse('1.2.3')!.hashCode,
        Version.parse('1.2.3')!.hashCode);
    expect(Version.parse('1.2.3-a')!.hashCode,
        Version.parse('1.2.3-a')!.hashCode);
    expect(Version.parse('1.2.3')!.hashCode,
        isNot(Version.parse('1.2.3-a')!.hashCode));
  });
}

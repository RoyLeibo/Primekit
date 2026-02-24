import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/notifications/notification_channel.dart';

void main() {
  group('NotificationChannel', () {
    const channel = NotificationChannel(
      id: 'my_channel',
      name: 'My Channel',
      description: 'Test channel',
      importance: PkNotificationImportance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    test('constructor sets all fields', () {
      expect(channel.id, equals('my_channel'));
      expect(channel.name, equals('My Channel'));
      expect(channel.description, equals('Test channel'));
      expect(channel.importance, equals(PkNotificationImportance.high));
      expect(channel.playSound, isTrue);
      expect(channel.enableVibration, isTrue);
      expect(channel.enableLights, isTrue);
    });

    test('defaults are sensible', () {
      const defaultChannel = NotificationChannel(id: 'x', name: 'X');
      expect(
        defaultChannel.importance,
        equals(PkNotificationImportance.defaultImportance),
      );
      expect(defaultChannel.playSound, isTrue);
      expect(defaultChannel.enableVibration, isTrue);
      expect(defaultChannel.enableLights, isFalse);
      expect(defaultChannel.description, isNull);
    });

    test('copyWith replaces specified fields', () {
      final copy = channel.copyWith(name: 'Updated', playSound: false);
      expect(copy.id, equals('my_channel')); // unchanged
      expect(copy.name, equals('Updated'));
      expect(copy.playSound, isFalse);
      expect(copy.enableVibration, isTrue); // unchanged
    });

    test('copyWith with no args is equivalent', () {
      final copy = channel.copyWith();
      expect(copy.id, equals(channel.id));
      expect(copy.name, equals(channel.name));
      expect(copy.importance, equals(channel.importance));
    });

    test('toString includes id and name', () {
      expect(channel.toString(), contains('my_channel'));
      expect(channel.toString(), contains('My Channel'));
    });

    group('static channels', () {
      test('general channel has correct defaults', () {
        expect(NotificationChannel.general.id, equals('general'));
        expect(
          NotificationChannel.general.importance,
          equals(PkNotificationImportance.defaultImportance),
        );
      });

      test('marketing channel has low importance', () {
        expect(NotificationChannel.marketing.id, equals('marketing'));
        expect(
          NotificationChannel.marketing.importance,
          equals(PkNotificationImportance.low),
        );
        expect(NotificationChannel.marketing.playSound, isFalse);
      });

      test('alerts channel has high importance', () {
        expect(NotificationChannel.alerts.id, equals('alerts'));
        expect(
          NotificationChannel.alerts.importance,
          equals(PkNotificationImportance.high),
        );
        expect(NotificationChannel.alerts.enableLights, isTrue);
      });
    });
  });
}

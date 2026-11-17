import 'package:flutter_test/flutter_test.dart';
import 'package:satonero_mobile/data/models/cant_do.dart';
import 'package:satonero_mobile/data/models/enums/action.dart';
import 'package:satonero_mobile/data/models/enums/cant_do_reason.dart';
import 'package:satonero_mobile/data/models/mostro_message.dart';
import 'package:satonero_mobile/data/models/payload.dart';
import 'package:satonero_mobile/data/models/text_message.dart';

void main() {
  test('parses a telegram-code restore reply and extracts the code', () {
    final msg = MostroMessage.fromJson({
      'restore': {
        'version': 1,
        'request_id': 12345,
        'trade_index': null,
        'action': 'telegram-code',
        'payload': {'text_message': 'AbC123'},
      },
    });

    expect(msg.action, Action.telegramCode);
    expect(msg.requestId, 12345);
    expect(msg.getPayload<TextMessage>()?.message, 'AbC123');
  });

  test('parses a cant-do reply and surfaces the rate-limit reason', () {
    final msg = MostroMessage.fromJson({
      'cant-do': {
        'version': 1,
        'request_id': 12345,
        'trade_index': null,
        'action': 'cant-do',
        'payload': {'cant_do': 'too_many_requests'},
      },
    });

    expect(msg.action, Action.cantDo);
    expect(
      msg.getPayload<CantDo>()?.cantDoReason,
      CantDoReason.tooManyRequests,
    );
  });

  test('serializes a request-telegram-code message with a null payload', () {
    final msg = MostroMessage<EmptyPayload>(
      action: Action.requestTelegramCode,
      requestId: 42,
    );

    final json = msg.toJson();
    expect(json['action'], 'request-telegram-code');
    expect(json['request_id'], 42);
    expect(json['payload'], isNull);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyworld_app/features/chats/chats_controller.dart';

void main() {
  test('ChatsController starts empty', () {
    final container = ProviderContainer();
    final state = container.read(chatsControllerProvider);
    expect(state.chats, isEmpty);
    expect(state.isLoading, isFalse);
  });
}

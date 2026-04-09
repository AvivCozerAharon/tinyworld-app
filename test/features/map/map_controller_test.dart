import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyworld_app/features/map/map_controller.dart';

void main() {
  test('MapController starts with empty simulations', () {
    final container = ProviderContainer();
    final state = container.read(mapControllerProvider);
    expect(state.activeSimulations, isEmpty);
    expect(state.sessionId, isNull);
  });

  test('MapController adds simulation on sim.started event', () {
    final container = ProviderContainer();
    container.read(mapControllerProvider.notifier).handleEvent({
      'event': 'sim.started',
      'job_id': 'j1',
      'other_user_id': 'u2',
    });
    final state = container.read(mapControllerProvider);
    expect(state.activeSimulations.length, equals(1));
    expect(state.activeSimulations.first.jobId, equals('j1'));
  });
}

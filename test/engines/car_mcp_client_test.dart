import 'package:flutter_test/flutter_test.dart';
import 'package:offline_car_assistant/engines/mcp/car_mcp_client.dart';

void main() {
  test('executes get_car_status tool correctly', () async {
    final client = CarMcpClient();
    final result = await client.executeTool('get_car_status', {});
    expect(result['status'], equals('ok'));
    expect(result['battery_level'], isNotNull);
  });

  test('returns error for unknown tool', () async {
    final client = CarMcpClient();
    final result = await client.executeTool('non_existent_tool', {});
    expect(result['status'], equals('error'));
  });
}

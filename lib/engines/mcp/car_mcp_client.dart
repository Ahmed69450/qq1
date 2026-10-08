class CarMcpClient {
  Future<Map<String, dynamic>> executeTool(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    switch (toolName) {
      case 'get_car_status':
        return {
          'status': 'ok',
          'speed_kmh': 0,
          'battery_level': 85,
          'ac_active': true,
          'doors_locked': true,
        };
      case 'read_screen_context':
        return {
          'status': 'ok',
          'active_app': 'com.byd.assistant',
          'visible_text': 'الشاشة الرئيسية',
        };
      default:
        return {
          'status': 'error',
          'message': 'Tool $toolName not recognized',
        };
    }
  }
}

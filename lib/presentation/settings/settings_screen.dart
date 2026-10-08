import 'package:flutter/material.dart';
import 'model_manager_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('إعدادات المساعد الصوتي'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.psychology, color: Colors.cyanAccent),
            title: const Text('إدارة النماذج الذكية (LLM & ONNX)', style: TextStyle(color: Colors.white)),
            subtitle: const Text('تحديد نماذج GGUF وPiper من الفلاشة أو الذاكرة', style: TextStyle(color: Colors.white54)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ModelManagerScreen()),
              );
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.mic, color: Colors.cyanAccent),
            title: const Text('كلمة التنبيه (Wake Word)', style: TextStyle(color: Colors.white)),
            subtitle: const Text('الافتراضي: "يا سيارة" (تعديل القواعد الصوتية)', style: TextStyle(color: Colors.white54)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.directions_car, color: Colors.cyanAccent),
            title: const Text('مختبر أوامر BYD (Sandbox)', style: TextStyle(color: Colors.white)),
            subtitle: const Text('اختبار إرسال أوامر التكييف والنوافذ والمحاكي', style: TextStyle(color: Colors.white54)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ),
        ],
      ),
    );
  }
}

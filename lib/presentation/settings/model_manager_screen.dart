import 'package:flutter/material.dart';

class ModelManagerScreen extends StatelessWidget {
  const ModelManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة النماذج (Model Manager)'),
        backgroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF222222),
            child: ListTile(
              leading: const Icon(Icons.sd_storage, color: Colors.cyanAccent),
              title: const Text('نموذج LLM (.gguf)', style: TextStyle(color: Colors.white)),
              subtitle: const Text('افتراضي: Qwen2.5-0.5B-Instruct-Q4_K_M.gguf', style: TextStyle(color: Colors.white70)),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text('استيراد من USB'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF222222),
            child: ListTile(
              leading: const Icon(Icons.record_voice_over, color: Colors.cyanAccent),
              title: const Text('نموذج الصوت Piper (.onnx)', style: TextStyle(color: Colors.white)),
              subtitle: const Text('افتراضي: ar_JO-kareem-low.onnx', style: TextStyle(color: Colors.white70)),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text('تغيير الصوت'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

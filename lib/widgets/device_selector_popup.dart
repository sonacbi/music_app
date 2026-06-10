import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class DeviceSelectorPopup extends StatelessWidget {
  final List<BluetoothDevice> devices;
  final Function(BluetoothDevice) onSelect;

  const DeviceSelectorPopup({
    super.key,
    required this.devices,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: 450,
      child: Column(
        children: [
          const Text(
            "Select Device",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (_, i) {
                final d = devices[i];

                return GestureDetector(
                  onTap: () async {
                    // 🔥 연결 애니메이션
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 10),
                              Text(
                                "Connecting...",
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                        );
                      },
                    );

                    await Future.delayed(const Duration(milliseconds: 800));

                    Navigator.pop(context); // dialog
                    Navigator.pop(context); // popup

                    onSelect(d);

                    // 성공 애니메이션
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Connected Successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      d.name ?? "Unknown",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../common/device_registry.dart';
import '../../models/device.dart';

/// [DeviceSelector] 下拉选择设备组件，自动读取设备列表。
class DeviceSelector extends StatelessWidget {
  /// [label] 输入提示文案。
  final String label;

  /// [onChanged] 选中设备后的回调。
  final void Function(Device?)? onChanged;

  /// 构造 [DeviceSelector]，可监听选中事件。
  const DeviceSelector({
    super.key,
    required this.label,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final registry = DeviceRegistry.instance;
    return ValueListenableBuilder<List<Device>>(
      valueListenable: registry.devices,
      builder: (context, devices, _) {
        return ValueListenableBuilder<Device?>(
          valueListenable: registry.selectedDevice,
          builder: (context, selected, __) {
            return DropdownButtonFormField<Device>(
              decoration: InputDecoration(labelText: label),
              value: selected != null && devices.any((d) => d.id == selected.id)
                  ? selected
                  : null,
              hint: const Text('请先在“设备管理”页刷新设备列表'),
              items: devices
                  .map(
                    (d) => DropdownMenuItem<Device>(
                      value: d,
                      child: Text(d.id),
                    ),
                  )
                  .toList(),
              onChanged: (device) {
                registry.selectDevice(device);
                onChanged?.call(device);
              },
            );
          },
        );
      },
    );
  }
}

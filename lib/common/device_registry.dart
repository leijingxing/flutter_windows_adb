import 'package:flutter/foundation.dart';

import '../models/device.dart';

/// [DeviceRegistry] 持有设备列表与当前选择的设备，便于各页面共享。
class DeviceRegistry {
  /// 单例实例，方便全局访问。
  static final DeviceRegistry instance = DeviceRegistry._internal();

  /// [devices] 最新的设备列表监听器。
  final ValueNotifier<List<Device>> devices = ValueNotifier<List<Device>>([]);

  /// [selectedDevice] 当前选中的设备监听器。
  final ValueNotifier<Device?> selectedDevice = ValueNotifier<Device?>(null);

  DeviceRegistry._internal();

  /// [updateDevices] 更新设备列表并校正当前选中状态。
  void updateDevices(List<Device> newDevices) {
    // 去重，避免 Dropdown 识别到相同 value 造成冲突。
    final Map<String, Device> unique = {for (final d in newDevices) d.id: d};
    final List<Device> distinct = unique.values.toList();
    devices.value = distinct;
    final currentId = selectedDevice.value?.id;
    if (currentId == null) return;
    final stillExists = distinct.any((d) => d.id == currentId);
    if (!stillExists) {
      selectedDevice.value = null;
    }
  }

  /// [selectDevice] 选中指定设备。
  void selectDevice(Device? device) {
    selectedDevice.value = device;
  }
}

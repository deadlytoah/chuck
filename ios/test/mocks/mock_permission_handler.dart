import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Mock implementation of PermissionHandlerPlatform for testing
class MockPermissionHandlerPlatform extends PermissionHandlerPlatform
    with MockPlatformInterfaceMixin {
  PermissionStatus _cameraStatus = PermissionStatus.granted;

  /// Configure the permission status that will be returned for camera
  void setCameraPermissionStatus(PermissionStatus status) {
    _cameraStatus = status;
  }

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    if (permission == Permission.camera) {
      return _cameraStatus;
    }
    return PermissionStatus.denied;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
      List<Permission> permissions) async {
    final result = <Permission, PermissionStatus>{};
    for (final permission in permissions) {
      if (permission == Permission.camera) {
        result[permission] = _cameraStatus;
      } else {
        result[permission] = PermissionStatus.denied;
      }
    }
    return result;
  }

  @override
  Future<ServiceStatus> checkServiceStatus(Permission permission) async {
    return ServiceStatus.enabled;
  }

  @override
  Future<bool> openAppSettings() async {
    return true;
  }

  @override
  Future<bool> shouldShowRequestPermissionRationale(
      Permission permission) async {
    return false;
  }
}

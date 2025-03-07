import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:arkit_plugin/src/geometries/arkit_geometry.dart';
import 'package:arkit_plugin/src/light/arkit_light.dart';
import 'package:arkit_plugin/src/physics/arkit_physics_body.dart';
import 'package:arkit_plugin/src/utils/json_converters.dart';
import 'package:arkit_plugin/src/utils/matrix4_ext.dart';
import 'package:flutter/widgets.dart';
import 'package:arkit_plugin/src/utils/random_string.dart' as random_string;
import 'package:vector_math/vector_math_64.dart';

/// ARKitNode is the model class for node-tree objects.
/// It encapsulates the position, rotations, and other transforms of a node, which define a coordinate system.
/// The coordinate systems of all the sub-nodes are relative to the one of their parent node.
class ARKitNode {
  ARKitNode({
    this.anchor,
    this.geometry,
    this.physicsBody,
    this.light,
    this.renderingOrder = defaultRenderingOrderValue,
    bool isHidden = defaultIsHiddenValue,
    Vector3? position,
    Vector3? scale,
    Vector4? rotation,
    Vector3? eulerAngles,
    String? name,
    Matrix4? transformation,
  })  : name = name ?? random_string.randomString(),
        isHidden = ValueNotifier(isHidden),
        transformNotifier = ValueNotifier(createTransformMatrix(transformation, position, scale, rotation, eulerAngles));

  static const bool defaultIsHiddenValue = false;
  static const int defaultRenderingOrderValue = 0;

  /// Anchor of this node
  final ARKitAnchor? anchor;

  /// Returns the geometry attached to the receiver.
  final ARKitGeometry? geometry;

  /// Determines the receiver's transform.
  /// The transform is the combination of the position, rotation and scale defined below.
  /// So when the transform is set, the receiver's position, rotation and scale are changed to match the new transform.
  Matrix4 get transform => transformNotifier.value;

  set transform(Matrix4 matrix) {
    transformNotifier.value = matrix;
  }

  /// Determines the receiver's position.
  Vector3 get position => transform.getTranslation();

  set position(Vector3 value) {
    final old = Matrix4.fromFloat64List(transform.storage);
    final newT = old.clone();
    newT.setTranslation(value);
    transform = newT;
  }

  /// Determines the receiver's scale.
  Vector3 get scale => transform.matrixScale;

  set scale(Vector3 value) {
    transform = Matrix4.compose(position, Quaternion.fromRotation(rotation), value);
  }

  /// Determines the receiver's rotation.
  Matrix3 get rotation => transform.getRotation();

  set rotation(Matrix3 value) {
    transform = Matrix4.compose(position, Quaternion.fromRotation(value), scale);
  }

  /// Determines the receiver's euler angles.
  /// The order of components in this vector matches the axes of rotation:
  /// 1. Pitch (the x component) is the rotation about the node's x-axis (in radians)
  /// 2. Yaw   (the y component) is the rotation about the node's y-axis (in radians)
  /// 3. Roll  (the z component) is the rotation about the node's z-axis (in radians)
  Vector3 get eulerAngles => transform.matrixEulerAngles;

  set eulerAngles(Vector3 value) {
    final old = Matrix4.fromFloat64List(transform.storage);
    final newT = old.clone();
    newT.matrixEulerAngles = value;
    transform = newT;
  }

  final ValueNotifier<Matrix4> transformNotifier;

  /// Determines the name of the receiver.
  /// Will be autogenerated if not defined.
  final String name;

  /// The description of the physics body of the receiver.
  final ARKitPhysicsBody? physicsBody;

  /// Determines the light attached to the receiver.
  final ARKitLight? light;

  /// Determines the rendering order of the receiver.
  /// Nodes with greater rendering orders are rendered last.
  /// Defaults to 0.
  final int renderingOrder;

  /// Determines the visibility of the node’s contents.
  /// Defaults to false.
  final ValueNotifier<bool> isHidden;

  static const _boolValueNotifierConverter = ValueNotifierConverter();
  static const _matrixValueNotifierConverter = MatrixValueNotifierConverter();

  Map<String, dynamic> toMap() => <String, dynamic>{
        'dartType': runtimeType.toString(),
        'geometry': geometry?.toJson(),
        'transform': _matrixValueNotifierConverter.toJson(transformNotifier),
        'physicsBody': physicsBody?.toJson(),
        'light': light?.toJson(),
        'name': name,
        'renderingOrder': renderingOrder,
        'isHidden': _boolValueNotifierConverter.toJson(isHidden),
      }..removeWhere((String k, dynamic v) => v == null);
}

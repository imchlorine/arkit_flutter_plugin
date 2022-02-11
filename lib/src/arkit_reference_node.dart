import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:vector_math/vector_math_64.dart';

///  Node that references an external serialized node graph.
class ARKitReferenceNode extends ARKitNode {
  ARKitReferenceNode({
    required this.url,
    ARKitAnchor? anchor,
    ARKitPhysicsBody? physicsBody,
    ARKitLight? light,
    Vector3? position,
    Vector3? scale,
    Vector3? eulerAngles,
    String? name,
    int renderingOrder = ARKitNode.defaultRenderingOrderValue,
    bool isHidden = ARKitNode.defaultIsHiddenValue,
  }) : super(
          anchor: anchor,
          physicsBody: physicsBody,
          light: light,
          position: position,
          scale: scale,
          eulerAngles: eulerAngles,
          name: name,
          renderingOrder: renderingOrder,
          isHidden: isHidden,
        );

  /// URL location of the Node
  /// Defaults to path from Main Bundle
  /// If path from main bundle fails, will search as full file path
  final String url;

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'url': url,
      }..addAll(super.toMap());
}

import ARKit

func createGeometry(_ arguments: Dictionary<String, Any>?, withDevice device: MTLDevice?) -> SCNGeometry? {
  if let arguments = arguments {
    
    var geometry: SCNGeometry?
    let dartType = arguments["dartType"] as! String
    
    switch dartType {
    case "ARKitSphere":
      geometry = createSphere(arguments)
      break
    case "ARKitPlane":
      geometry = createPlane(arguments)
      break
    case "ARKitText":
      geometry = createText(arguments)
      break
    case "ARKitBox":
      geometry = createBox(arguments)
      break
    case "ARKitLine":
      geometry = createLine(arguments)
      break
    case "ARKitCylinder":
      geometry = createCylinder(arguments)
      break
    case "ARKitCone":
      geometry = createCone(arguments)
      break
    case "ARKitPyramid":
      geometry = createPyramid(arguments)
      break
    case "ARKitTube":
      geometry = createTube(arguments)
      break
    case "ARKitTorus":
      geometry = createTorus(arguments)
      break
    case "ARKitCapsule":
      geometry = createCapsule(arguments)
      break
    case "ARKitFace":
      #if !DISABLE_TRUEDEPTH_API
      geometry = createFace(device)
      #else
      // error
      #endif
      break
    default:
      // error
      break
    }
    
    if let materials = arguments["materials"] as? Array<Dictionary<String, Any>> {
      geometry?.materials = parseMaterials(materials)
    }
    
    return geometry
  } else {
    return nil
  }
}

func parseMaterials(_ array: Array<Dictionary<String, Any>>) -> Array<SCNMaterial> {
  return array.map { parseMaterial($0) }
}

fileprivate func parseMaterial(_ dict: Dictionary<String, Any>) -> SCNMaterial {
  let material = SCNMaterial()
  
  material.shininess = CGFloat(dict["shininess"] as! Double)
  material.transparency = CGFloat(dict["transparency"] as! Double)
  material.lightingModel = parseLightingModel(dict["lightingModelName"] as? Int)
  material.fillMode = SCNFillMode(rawValue: UInt(dict["fillMode"] as! Int))!
  material.cullMode = SCNCullMode(rawValue: dict["cullMode"] as! Int)!
  material.transparencyMode = SCNTransparencyMode(rawValue: dict["transparencyMode"] as! Int)!
  material.locksAmbientWithDiffuse = dict["locksAmbientWithDiffuse"] as! Bool
  material.writesToDepthBuffer = dict["writesToDepthBuffer"] as! Bool
  material.colorBufferWriteMask = parseColorBufferWriteMask(dict["colorBufferWriteMask"] as? Int)
  material.blendMode = SCNBlendMode.init(rawValue: dict["blendMode"] as! Int)!
  material.isDoubleSided = dict["doubleSided"] as! Bool
  
  material.diffuse.contents = parsePropertyContents(dict["diffuse"])
  material.ambient.contents = parsePropertyContents(dict["ambient"])
  material.specular.contents = parsePropertyContents(dict["specular"])
  material.emission.contents = parsePropertyContents(dict["emission"])
  material.transparent.contents = parsePropertyContents(dict["transparent"])
  material.reflective.contents = parsePropertyContents(dict["reflective"])
  material.multiply.contents = parsePropertyContents(dict["multiply"])
  material.normal.contents = parsePropertyContents(dict["normal"])
  material.displacement.contents = parsePropertyContents(dict["displacement"])
  material.ambientOcclusion.contents = parsePropertyContents(dict["ambientOcclusion"])
  material.selfIllumination.contents = parsePropertyContents(dict["selfIllumination"])
  material.metalness.contents = parsePropertyContents(dict["metalness"])
  material.roughness.contents = parsePropertyContents(dict["roughness"])
  
  return material
}

fileprivate func parseLightingModel(_ mode: Int?) -> SCNMaterial.LightingModel {
  switch mode {
  case 0:
    return .phong
  case 1:
    return .blinn
  case 2:
    return .lambert
  case 3:
    return .constant
  case 4:
    return .physicallyBased
  case 5:
    if #available(iOS 13.0, *) {
      return .shadowOnly
    } else {
      // error
      return .blinn
    }
  default:
    return .blinn
  }
}

fileprivate func parseColorBufferWriteMask(_ mode: Int?) -> SCNColorMask {
  switch mode {
  case 0:
    return .init()
  case 8:
    return .red
  case 4:
    return .green
  case 2:
    return .blue
  case 1:
    return .alpha
  case 15:
    return .all
  default:
    return .all
  }
}

fileprivate func parsePropertyContents(_ dict: Any?) -> Any? {
  guard let dict = dict as? Dictionary<String, Any> else {
    return nil
  }
  
  if let imageName = dict["image"] as? String {
    return getImageByName(imageName)
  }
  if let color = dict["color"] as? Int {
    return UIColor(rgb: UInt(color))
  }
  if let value = dict["value"] as? Double {
    return value
  }
  if let width = dict["width"] as? Int,
     let height = dict["height"] as? Int,
     let autoplay = dict["autoplay"] as? Bool,
     let isMuted = dict["isMuted"] as? Bool,
     let id = dict["id"] as? String {
    var videoNode:SKVideoNode
    var player: AVPlayer
    var asset: AVURLAsset
    if let url = dict["url"] as? String,
              let videoUrl = URL(string: url) {
      asset = AVURLAsset(url:videoUrl)
      player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
      _ = VideoLooper(player)
      videoNode = SKVideoNode(avPlayer: player)
    } else {
      return nil
    }

    VideoArkitPlugin.nodes[id] = videoNode
    if (autoplay) {
      player.play()
      player.isMuted = isMuted
      videoNode.play()
    }

    let transform = asset.tracks(withMediaType: AVMediaType.video)[0].preferredTransform
    let videoAngleInDegree = atan2(transform.b, transform.a) * 180 / .pi
    let naturalSize = asset.tracks(withMediaType: AVMediaType.video)[0].naturalSize
    var size = naturalSize
    if (videoAngleInDegree == 90 || videoAngleInDegree == 270) {
        size = CGSize(width: naturalSize.height, height: naturalSize.width)
    }
    // let skScene = SKScene(size: CGSize(width: width, height: height))
    let skScene = SKScene(size: naturalSize)
    skScene.scaleMode = .aspectFit
    skScene.addChild(videoNode)

    
    videoNode.position = CGPoint(x: skScene.size.width/2, y: skScene.size.height/2)
    videoNode.size = skScene.size
  
    videoNode.zRotation = CGFloat(-videoAngleInDegree) * .pi / 180

    return skScene
  }
  return nil
}


class VideoLooper {
    var playerObserver: Any?
    
    init(_ player: AVPlayer) {
        player.actionAtItemEnd = .none

        playerObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: nil) { notification in
                if let playerItem: AVPlayerItem = notification.object as? AVPlayerItem {
                    playerItem.seek(to: CMTime.zero, completionHandler: nil)
                }
            }
    }
}


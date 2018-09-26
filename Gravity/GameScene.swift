//
//  GameScene.swift
//  Gravity
//
//  Created by François Combe on 17/09/2018.
//  Copyright © 2018 francois. All rights reserved.
//

import SpriteKit
import GameplayKit

struct Constants {
    static let changeLevelText = "Press 'enter' to try an other level"
    static let changeLevelFontSize: CGFloat = 30
    
    static let retryLevelText = "Press 'space' to retry"
    static let retryLevelFontSize: CGFloat = 50
    
    static let victoryText = "Toutou Youtou"
    static let victoryFontSize: CGFloat = 120
    
    static let mariachiMusicURL = URL(string: Bundle.main.path(forResource: "mariachi", ofType: "wav")!)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var rocketSprite = SKSpriteNode()
    var planetSprite = SKSpriteNode()
    var gravityField = SKFieldNode()
    var cheeseSprite = SKSpriteNode()
    var angleLabel = SKLabelNode()
    var powerLabel = SKLabelNode()
    
    var backgroundMusic = SKAudioNode()
    
    var rocketInitPosition: CGPoint!
    var cheeseInitPosition: CGPoint!
    
    override func sceneDidLoad() {
        physicsWorld.contactDelegate = self
        startAnotherGame()
    }
    
    func setupRocket() {
        let rocketTexture = SKTexture(imageNamed: "rocket")
        rocketSprite = SKSpriteNode(texture: rocketTexture, size: CGSize(width: 100, height: 100))
        rocketSprite.position = rocketInitPosition
        rocketSprite.physicsBody = SKPhysicsBody(texture: rocketTexture, size: rocketSprite.size)
        rocketSprite.physicsBody!.contactTestBitMask = rocketSprite.physicsBody!.collisionBitMask
        rocketSprite.name = "rocket"
        self.addChild(rocketSprite)
    }
    
    func setupPlanet() {
        let planetTexture = SKTexture(imageNamed: "planet")
        planetSprite = SKSpriteNode(texture: planetTexture, size: CGSize(width: 200, height: 200))
        planetSprite.position = CGPoint(x: 0, y: 0)
        planetSprite.physicsBody = SKPhysicsBody(texture: planetTexture, size: planetSprite.size)
        planetSprite.physicsBody?.isDynamic = false
        planetSprite.name = "planet"
        self.addChild(planetSprite)

    }
    
    func setupCheese() {
        let cheeseTexture = SKTexture(imageNamed: "cheese")
        cheeseSprite = SKSpriteNode(texture: cheeseTexture, size: CGSize(width: 60, height: 60))
        cheeseSprite.position = cheeseInitPosition
        cheeseSprite.name = "cheese"
        cheeseSprite.run(SKAction.repeatForever(SKAction.sequence([SKAction.resize(toWidth: 80, height: 80, duration: 0.5),
                                                                   SKAction.resize(toWidth: 60, height: 60, duration: 0.5)])))
        self.addChild(cheeseSprite)
    }
    
    func setupGravity() {
        gravityField = SKFieldNode.radialGravityField()
        gravityField.position = CGPoint(x: 0, y: 0)
        gravityField.strength = 10
        self.addChild(gravityField)
        gravityField.isEnabled = false
    }
    
    func setupLabels() {
        deltaX = 0
        deltaY = 0
        
        angleLabel = SKLabelNode(text: "Angle: - ")
        angleLabel.fontSize = 30
        angleLabel.position = CGPoint(x: 250, y: -200)
        angleLabel.horizontalAlignmentMode = .left
        self.addChild(angleLabel)
        
        powerLabel = SKLabelNode(text: "Power: - ")
        powerLabel.fontSize = 30
        powerLabel.position = CGPoint(x: 250, y: -240)
        powerLabel.horizontalAlignmentMode = .left
        self.addChild(powerLabel)
    }
    
    func setupBackgroundMusic() {
        backgroundMusic = SKAudioNode(url: URL(string: Bundle.main.path(forResource: "interstellar", ofType: "mp3")!)!)
        backgroundMusic.name = "background music"
        addChild(backgroundMusic)
    }
    
    func getRandomRocketPosition() -> CGPoint {
        let random = CGPoint.random(minX: -480, maxX: 0, minY: -320, maxY: 0)
        if (pow(random.x, 2) + pow(random.y, 2)) < pow(150, 2) {
            return getRandomRocketPosition()
        } else {
//            print(random.debugDescription, String((pow(random.x, 2) + pow(random.y, 2))))
            return random
        }
    }
    
    func getRandomCheesePosition() -> CGPoint {
        let axis = CGLine(xCoefficient: rocketInitPosition.x, yCoefficient: rocketInitPosition.y, offset: 0)
        let random = CGFloat.random(in: 0..<250)
        let point = CGPoint(x: 150 + cos(axis.yCoefficient / axis.xCoefficient) * random, y: 150 + sin(axis.xCoefficient / axis.yCoefficient) * random)
        return point
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if rocketSprite.parent != nil {
            if contact.bodyA.node?.name == "rocket", contact.bodyB.node?.name == "planet"{
                destroyRocket(at: contact.contactPoint)
            } else if contact.bodyA.node?.name == "planet", contact.bodyB.node?.name == "rocket"{
                destroyRocket(at: contact.contactPoint)
            }
        }

    }
    
    func showExplosion(at pos: CGPoint) {
        let explosionSprite = SKSpriteNode(imageNamed: "explosion")
        explosionSprite.size = CGSize(width: 1, height: 1)
        explosionSprite.position = pos
        explosionSprite.run(SKAction.sequence([SKAction.resize(toWidth: 90, height: 90, duration: 0.05),
                                               SKAction.resize(toWidth: 100, height: 100, duration: 1.5),
                                               SKAction.fadeOut(withDuration: 0.5),
                                               SKAction.removeFromParent()]))
        self.addChild(explosionSprite)
    }
    
    func showLabels() {
        let retryLabel = SKLabelNode(text: Constants.retryLevelText)
        retryLabel.fontSize = Constants.retryLevelFontSize
        retryLabel.position = CGPoint(x: 0, y: 250)
        retryLabel.name = "retry label"
        self.addChild(retryLabel)
        
        let changeLevelLabel = SKLabelNode(text: Constants.changeLevelText)
        changeLevelLabel.fontSize = Constants.changeLevelFontSize
        changeLevelLabel.position = CGPoint(x: 0, y: 200)
        self.addChild(changeLevelLabel)
    }
    
    var labelsAreVisible: Bool {
        if childNode(withName: "retry label") != nil {
            return true
        } else {
            return false
        }
    }
    
    func showVictoryLabel() {
        let label = SKLabelNode(text: Constants.victoryText)
        label.fontSize = Constants.victoryFontSize
        label.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
        self.addChild(label)
    }
    
    func playMariachiMusic() {
        let music = SKAudioNode(url: Constants.mariachiMusicURL!)
        backgroundMusic.removeFromParent()
        addChild(music)
        
    }
    
    var backgroundMusicIsPlaying: Bool {
        return backgroundMusic.parent != nil
    }
    
    func restartGame() {
        self.removeChildren()
        outOfBoundsDate = nil
        haveBeenImpulsed = false
        
        setupRocket()
        setupPlanet()
        setupGravity()
        setupCheese()
        setupLabels()
        if !backgroundMusicIsPlaying {
            setupBackgroundMusic()
        }
    }
    
    func startAnotherGame() {
        rocketInitPosition = getRandomRocketPosition()
        cheeseInitPosition = getRandomCheesePosition()
        restartGame()
    }
    
    var deltaX: CGFloat = 0
    var deltaY: CGFloat = 0
    
    func applyImpulse() {
        rocketSprite.physicsBody?.applyImpulse(CGVector(dx: -deltaX/5, dy: deltaY/5))
        gravityField.isEnabled = true
    }
    
    func destroyRocket(at pos: CGPoint) {
        rocketSprite.removeFromParent()
        showExplosion(at: pos)
        showLabels()
    }
    
    func haveGrabbedTheCheese() {
        cheeseInitPosition = CGPoint(x: 0, y: 0)
        backgroundMusic.removeFromParent()
        cheeseSprite.removeFromParent()
        playMariachiMusic()
        showVictoryLabel()
    }
    
    override func mouseDragged(with event: NSEvent) {
        deltaX += event.deltaX
        deltaY += event.deltaY
        
        let angle = atan2(-deltaY, deltaX) + 90 * CGFloat.pi / 180
        rocketSprite.zRotation = angle
        
        let power = (deltaX.abs() + deltaY.abs()).rounded()
        
        angleLabel.text = "Angle: " + String((angle * 100).rounded() / 100)
        powerLabel.text = "Power: " + String(power)
    }
    
    var haveBeenImpulsed = false
    
    override func mouseUp(with event: NSEvent) {
        if !haveBeenImpulsed {
            self.applyImpulse()
            haveBeenImpulsed = true
        }
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 0x31: // enter or space
            restartGame()
        case 36:
            startAnotherGame()
        default:
            print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }
    
    var outOfBoundsDate: Date?
    
    override func update(_ currentTime: TimeInterval) {
        if let velocity = rocketSprite.physicsBody?.velocity, velocity.dx != 0, velocity.dy != 0 {
            let angle = atan2(velocity.dy, velocity.dx) - 90 * CGFloat.pi / 180
            rocketSprite.zRotation = angle
        }
        
        if CGPoint.distance(pointA: rocketSprite.position, pointB: cheeseInitPosition) < 40 {
            haveGrabbedTheCheese()
        }
        
        let rocketPositionInViewCoordinates = convertPoint(toView: rocketSprite.position)
        if !self.view!.frame.contains(rocketPositionInViewCoordinates), !labelsAreVisible {
            if let date = outOfBoundsDate {
                if date.timeIntervalSinceNow < -2 {
                    showLabels()
                }
            } else {
                outOfBoundsDate = Date()
            }
        }
    }
    
    func removeChildren() {
        var childrenToRemove = [SKNode]()
        for node in children {
            if node.name != "background music" {
                childrenToRemove.append(node)
            }
        }
        removeChildren(in: childrenToRemove)
    }
}

extension String {
    init(_ cgFloat: CGFloat) {
        self = String(Double(cgFloat))
    }
}

extension CGFloat {
    func abs() -> CGFloat {
        return Swift.abs(self)
    }
}

extension CGPoint {
    static func random(minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) -> CGPoint {
        let randomX = CGFloat.random(in: minX..<maxX)
        let randomY = CGFloat.random(in: minY..<maxY)
        return CGPoint(x: randomX, y: randomY)
    }
    
    static func distance(pointA: CGPoint, pointB: CGPoint) -> CGFloat {
        let xDistance = pointA.x - pointB.x
        let yDistance = pointA.y - pointB.y
        let squaredSum = pow(xDistance, 2) + pow(yDistance, 2)
        return sqrt(squaredSum)
    }
}

struct CGLine {
    var xCoefficient: CGFloat
    var yCoefficient: CGFloat
    var offset: CGFloat
    
    init(xCoefficient: CGFloat, yCoefficient: CGFloat, offset: CGFloat) {
        self.xCoefficient = xCoefficient
        self.yCoefficient = yCoefficient
        self.offset = offset
    }
    
    func getPoint(x: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: xCoefficient / yCoefficient * x + offset / yCoefficient)
    }
}

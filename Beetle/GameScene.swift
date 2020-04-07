//
//  GameScene.swift
//  Beetle
//
//  Created by Muskan on 1/22/17.
//  Copyright © 2017 Muskan. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {

    var gameStarted = false
    var died = false
    let coinSound = SKAction.playSoundFileNamed("CoinSound.mp3", waitForCompletion: false)

    var score = 0
    var scoreLbl = SKLabelNode()
    var highscoreLbl = SKLabelNode()
    var taptoplayLbl = SKLabelNode()
    var restartBtn = SKSpriteNode()
    var pauseBtn = SKSpriteNode()
    var logoImg = SKSpriteNode()
    var wallPair = SKNode()
    var moveAndRemove = SKAction()

    var birdSprites = [SKTexture]()
    var bird = SKSpriteNode()
    var repeatActionbird = SKAction()
    var backgrounds = [SKSpriteNode]()

    override func didMove(to _: SKView) {
        self.createScene()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        if self.gameStarted == false {
            self.gameStarted = true
            self.bird.physicsBody?.affectedByGravity = true
            createPauseBtn()
            self.logoImg.run(SKAction.scale(to: 0.5, duration: 0.3), completion: {
                self.logoImg.removeFromParent()
            })
            self.taptoplayLbl.removeFromParent()
            self.bird.run(self.repeatActionbird)

            let spawn = SKAction.run {
                self.wallPair = self.createWalls()
                self.addChild(self.wallPair)
            }

            self.run(.repeatForever(.sequence([spawn, .wait(forDuration: 1.5)])))

            let distance = CGFloat(self.frame.width + self.wallPair.frame.width)
            let movePipes = SKAction.moveBy(x: -distance - 50, y: 0, duration: TimeInterval(0.008 * distance))
            let removePipes = SKAction.removeFromParent()
            self.moveAndRemove = SKAction.sequence([movePipes, removePipes])

            self.bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            self.bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 40))
        } else {
            if !self.died {
                self.bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                self.bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 40))
            }
        }

        for touch in touches {
            let location = touch.location(in: self)
            if self.died {
                if self.restartBtn.contains(location) {
                    if UserDefaults.standard.object(forKey: "highestScore") != nil {
                        let hscore = UserDefaults.standard.integer(forKey: "highestScore")
                        if hscore < Int(self.scoreLbl.text!)! {
                            UserDefaults.standard.set(self.scoreLbl.text, forKey: "highestScore")
                        }
                    } else {
                        UserDefaults.standard.set(0, forKey: "highestScore")
                    }
                    self.restartScene()
                }
            } else {
                if self.pauseBtn.contains(location) {
                    if !self.isPaused {
                        self.isPaused = true
                        self.pauseBtn.texture = SKTexture(imageNamed: "play")
                    } else {
                        self.isPaused = false
                        self.pauseBtn.texture = SKTexture(imageNamed: "pause")
                    }
                }
            }
        }
    }

    func restartScene() {
        self.removeAllChildren()
        self.removeAllActions()
        self.died = false
        self.gameStarted = false
        self.score = 0
        self.createScene()
    }

    func createScene() {
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody?.categoryBitMask = CollisionBitMask.groundCategory
        self.physicsBody?.collisionBitMask = CollisionBitMask.birdCategory
        self.physicsBody?.contactTestBitMask = CollisionBitMask.birdCategory
        self.physicsBody?.isDynamic = false
        self.physicsBody?.affectedByGravity = false

        self.physicsWorld.contactDelegate = self
        self.backgroundColor = SKColor(red: 80.0 / 255.0, green: 192.0 / 255.0, blue: 203.0 / 255.0, alpha: 1.0)

        self.backgrounds = (0...1).map { (i) in
            let background = SKSpriteNode(imageNamed: "bg")
            background.anchorPoint = CGPoint(x: 0, y: 0)
            background.position = CGPoint(x: CGFloat(i) * self.frame.width, y: 0)
            background.name = "background"
            background.size = self.size
            self.addChild(background)
            return background
        }

        // SET UP THE BIRD SPRITES FOR ANIMATION
        let birdAtlas = SKTextureAtlas(named: "player")
        self.birdSprites = birdAtlas.textureNames.sorted().map { birdAtlas.textureNamed($0) }

        self.bird = createBird()
        self.addChild(self.bird)

        // ANIMATE THE BIRD AND REPEAT THE ANIMATION FOREVER
        let animatebird = SKAction.animate(with: self.birdSprites, timePerFrame: 0.1)
        self.repeatActionbird = SKAction.repeatForever(animatebird)

        self.scoreLbl = createScoreLabel()
        self.addChild(self.scoreLbl)

        self.highscoreLbl = createHighscoreLabel()
        self.addChild(self.highscoreLbl)

        createLogo()

        self.taptoplayLbl = createTaptoplayLabel()
        self.addChild(self.taptoplayLbl)
    }

    override func update(_: TimeInterval) {
        // Called before each frame is rendered
        if self.gameStarted, !self.died {
            self.backgrounds.forEach { bg in
                bg.position = CGPoint(x: bg.position.x - 2, y: bg.position.y)
                if bg.position.x <= -bg.size.width {
                    bg.position = CGPoint(x: bg.position.x + bg.size.width * 2, y: bg.position.y)
                }
            }
        }
    }
}

extension GameScene: SKPhysicsContactDelegate {

    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB

        if firstBody.categoryBitMask == CollisionBitMask.birdCategory && secondBody.categoryBitMask == CollisionBitMask.pillarCategory || firstBody.categoryBitMask == CollisionBitMask.pillarCategory && secondBody.categoryBitMask == CollisionBitMask.birdCategory || firstBody.categoryBitMask == CollisionBitMask.birdCategory && secondBody.categoryBitMask == CollisionBitMask.groundCategory || firstBody.categoryBitMask == CollisionBitMask.groundCategory && secondBody.categoryBitMask == CollisionBitMask.birdCategory {
            enumerateChildNodes(withName: "wallPair", using: ({
                node, _ in
                node.speed = 0
                self.removeAllActions()
            }))
            if !self.died {
                self.died = true
                createRestartBtn()
                self.pauseBtn.removeFromParent()
                self.bird.removeAllActions()
            }
        } else if firstBody.categoryBitMask == CollisionBitMask.birdCategory, secondBody.categoryBitMask == CollisionBitMask.flowerCategory {
            run(self.coinSound)
            self.score += 1
            self.scoreLbl.text = "\(self.score)"
            secondBody.node?.removeFromParent()
        } else if firstBody.categoryBitMask == CollisionBitMask.flowerCategory, secondBody.categoryBitMask == CollisionBitMask.birdCategory {
            run(self.coinSound)
            self.score += 1
            self.scoreLbl.text = "\(self.score)"
            firstBody.node?.removeFromParent()
        }
    }

}

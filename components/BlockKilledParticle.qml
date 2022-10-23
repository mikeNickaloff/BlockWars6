import QtQuick 2.4
import QtQuick.Particles 2.0
import "../flux"
import QuickFlux 1.1

Item {
    objectName: "Particle scene"
    width: parent.width
    height: parent.height

    function burstAt(xpos, ypos) {
        blockKilledEmitter.burst(5, xpos, ypos)
        blockKilledParticleDebris.burst(5, xpos, ypos)
    }
    ParticleSystem {
        id: particleSystem
        anchors.fill: parent
    }

    ImageParticle {
        objectName: "blockKilledParticle"
        groups: ["blockKilledParticles"]
        source: "file:///home/mike/build/Blockwars5/images/particles/explode1.png"
        color: "#ffce1d"
        colorVariation: 0
        alpha: 0.7
        alphaVariation: 0.7
        redVariation: 0.2
        greenVariation: 0
        blueVariation: 0
        rotation: 13
        rotationVariation: 34
        autoRotation: false
        rotationVelocity: 22
        rotationVelocityVariation: 7
        entryEffect: ImageParticle.Scale
        system: particleSystem
    }

    ImageParticle {
        objectName: "blockKilledParticleDebris"
        groups: ["blockKilledParticlesDebris"]
        source: "file:///home/mike/build/Blockwars5/images/particles/sparks_multi.png"
        color: "#ffe200"
        colorVariation: 0
        alpha: 0.8
        alphaVariation: 0
        redVariation: 0
        greenVariation: 0
        blueVariation: 0.8
        rotation: 36
        rotationVariation: 0
        autoRotation: false
        rotationVelocity: 28
        rotationVelocityVariation: 32
        entryEffect: ImageParticle.Fade
        system: particleSystem
    }

    Emitter {
        id: blockKilledEmitter
        objectName: "blockKilledParticleEmitter"
        x: 0
        y: 0
        width: 30
        height: 30
        enabled: false
        group: "blockKilledParticles"
        emitRate: 3
        maximumEmitted: 100
        startTime: 0
        lifeSpan: 450
        lifeSpanVariation: 50
        size: 7
        sizeVariation: 10
        endSize: 134
        velocityFromMovement: 11
        system: particleSystem
        velocity: AngleDirection {
            angle: 11
            angleVariation: 10
            magnitude: 15
            magnitudeVariation: 0
        }
        acceleration: PointDirection {
            x: 12
            xVariation: 2
            y: 17
            yVariation: 0
        }
        shape: EllipseShape {
            fill: true
        }
    }

    Emitter {
        objectName: "blockKilledParticleDebris"
        id: blockKilledParticleDebris

        x: 0
        y: 0
        width: 20
        height: 20
        enabled: false
        group: "blockKilledParticlesDebris"
        emitRate: 3
        maximumEmitted: 100
        startTime: 100
        lifeSpan: 700
        lifeSpanVariation: 0
        size: 0
        sizeVariation: 0
        endSize: 117
        velocityFromMovement: 59
        system: particleSystem
        velocity: CumulativeDirection {}
        acceleration: AngleDirection {
            angle: -1
            angleVariation: 1
            magnitude: 24
            magnitudeVariation: 10
        }
        shape: EllipseShape {
            fill: false
        }
    }
}

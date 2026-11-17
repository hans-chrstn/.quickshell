import QtQuick
import qs.core

SpringAnimation {
    property string phase: "morph"

    spring: phase === "enter" ? Design.springEnterStrength : phase === "exit" ? Design.springExitStrength : Design.springMorphStrength
    damping: phase === "enter" ? Design.springEnterDamping : phase === "exit" ? Design.springExitDamping : Design.springMorphDamping
    mass: phase === "enter" ? Design.springEnterMass : phase === "exit" ? Design.springExitMass : Design.springMorphMass
    epsilon: Design.springPixelEpsilon
}

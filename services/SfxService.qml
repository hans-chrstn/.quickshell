pragma Singleton
import QtQuick
import QtMultimedia
import Quickshell

Singleton {
    id: root

    SoundEffect {
        id: onSfx
        source: Quickshell.shellPath("assets/sfx/on.wav")
        volume: 0.5
    }

    SoundEffect {
        id: offSfx
        source: Quickshell.shellPath("assets/sfx/off.wav")
        volume: 0.5
    }

    SoundEffect {
        id: button1Sfx
        source: Quickshell.shellPath("assets/sfx/button1.wav")
        volume: 0.4
    }

    SoundEffect {
        id: button2Sfx
        source: Quickshell.shellPath("assets/sfx/button2.wav")
        volume: 0.4
    }

    SoundEffect {
        id: completeSfx
        source: Quickshell.shellPath("assets/sfx/complete.wav")
        volume: 0.5
    }

    function playOn() { onSfx.play() }
    function playOff() { offSfx.play() }
    function playButton1() { button1Sfx.play() }
    function playButton2() { button2Sfx.play() }
    function playComplete() { completeSfx.play() }
}

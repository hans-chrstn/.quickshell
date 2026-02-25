pragma Singleton
import QtQuick
import QtMultimedia
import Quickshell

Singleton {
    id: root

    SoundEffect {
        id: expandSound
        source: Quickshell.shellPath("assets/audio/on.wav")
        volume: 0.5
    }

    SoundEffect {
        id: collapseSound
        source: Quickshell.shellPath("assets/audio/off.wav")
        volume: 0.5
    }

    SoundEffect {
        id: clickSound
        source: Quickshell.shellPath("assets/audio/button1.wav")
        volume: 0.4
    }

    SoundEffect {
        id: toggleSound
        source: Quickshell.shellPath("assets/audio/button2.wav")
        volume: 0.4
    }

    SoundEffect {
        id: successSound
        source: Quickshell.shellPath("assets/audio/complete.wav")
        volume: 0.5
    }

    function playExpand() { expandSound.play() }
    function playCollapse() { collapseSound.play() }
    function playClick() { clickSound.play() }
    function playToggle() { toggleSound.play() }
    function playSuccess() { successSound.play() }
}

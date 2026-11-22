import QtQuick
import Quickshell.Io
import qs.services.api
import "."

Item {
    id: root

    function requestToggle(): void { BibliotecaBridge.toggle(); }

    // caelestia shell bibliotecaGaming toggle
    IpcHandler {
        target: "bibliotecaGaming"
        function open(): void { BibliotecaBridge.open(); }
        function close(): void { BibliotecaBridge.close(); }
        function toggle(): void { BibliotecaBridge.toggle(); }
    }

    Component.onCompleted: {
        CaelestiaApi.shortcuts.register("bibliotecaGaming", "Abrir la biblioteca gaming / Open the game library", "Meta+J", root.requestToggle);
    }
}

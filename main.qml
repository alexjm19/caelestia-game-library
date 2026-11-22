import QtQuick
import Quickshell.Io
import qs.services.api
import "."

Item {
    id: root

    function requestToggle(): void { BibliotecaBridge.toggle(); }

    // caelestia shell bibliotecaSteam toggle
    IpcHandler {
        target: "bibliotecaSteam"
        function open(): void { BibliotecaBridge.open(); }
        function close(): void { BibliotecaBridge.close(); }
        function toggle(): void { BibliotecaBridge.toggle(); }
    }

    Component.onCompleted: {
        CaelestiaApi.shortcuts.register("bibliotecaSteam", "Abrir la biblioteca gaming", "Meta+J", root.requestToggle);
    }
}

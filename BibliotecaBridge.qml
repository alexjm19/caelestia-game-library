pragma Singleton

import QtQuick
import Quickshell

// Estado compartido del panel (abierto/cerrado) entre el botón de cada barra y el IPC.
Singleton {
    id: root

    signal openStateRequested(bool open)

    property int _seq: 0
    function newId(): string { _seq += 1; return "w-" + _seq; }

    property int shownCount: 0
    readonly property bool popoutShown: shownCount > 0
    property var _shown: new Set()
    function setShown(id: string, shown: bool): void {
        if (shown) _shown.add(id); else _shown.delete(id);
        shownCount = _shown.size;
    }

    function toggle(): void { openStateRequested(!popoutShown); }
    function open(): void { openStateRequested(true); }
    function close(): void { openStateRequested(false); }

    readonly property string dir: {
        var s = String(Qt.resolvedUrl("."));
        if (s.indexOf("file://") === 0) s = s.substring(7);
        if (s.length && s.charAt(s.length - 1) !== "/") s += "/";
        return decodeURIComponent(s);
    }
    readonly property string lister: dir + "bin/listar-juegos"
}

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import "."

Item {
    id: root

    property var screen
    property var popouts

    readonly property string widgetId: "bibliotecaGaming"
    property string _key: ""
    readonly property bool active: popouts ? (popouts.currentName === widgetId && popouts.hasCurrent === true) : false

    implicitWidth: 32
    implicitHeight: 32

    onActiveChanged: if (_key) BibliotecaBridge.setShown(_key, active)
    Component.onCompleted: { _key = BibliotecaBridge.newId(); BibliotecaBridge.setShown(_key, active); }
    Component.onDestruction: BibliotecaBridge.setShown(_key, false)

    function _centerAlongBar(): real {
        var p = root.mapToItem(null, root.width / 2, root.height / 2);
        var vertical = Config.bar.position === "left" || Config.bar.position === "right";
        return vertical ? p.y : p.x;
    }

    function setOpen(open: bool): void {
        if (!popouts) return;
        if (open) popouts.currentCenter = _centerAlongBar();
        popouts.currentName = open ? widgetId : "";
        popouts.hasCurrent = open;
        // Panel para elegir: se queda abierto hasta clic fuera, otro clic en el botón o que otra
        // ventana tome el foco (el juego al lanzarse). Sin esto, caelestia lo trata como popout de
        // hover y lo cierra a los 150 ms si el ratón sale de la barra mientras el panel aún crece.
        // Va después de currentName porque cambiarlo pone staysOpen a false.
        if (open) popouts.staysOpen = true;
    }

    function handleHover(_pos, _isHorizontal, shellPopouts): void {
        var p = shellPopouts ?? popouts;
        if (!p || p.currentName !== widgetId || p.hasCurrent !== true) return;
        p.currentCenter = _centerAlongBar();
    }

    // Con el atajo o el IPC solo se abre en la pantalla donde está el ratón.
    function _isActiveScreen(): bool {
        var s = screen ?? (popouts ? popouts.screen : null);
        if (!s) return true;
        var name = Kwin.cursorOutputName();
        return !name || name === s.name;
    }

    Connections {
        target: BibliotecaBridge
        function onOpenStateRequested(open) { if (!open || root._isActiveScreen()) root.setOpen(open); }
    }

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3onSurface
        opacity: root.active ? 0.14 : (mouse.containsMouse ? 0.08 : 0)
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    MaterialIcon {
        anchors.centerIn: parent
        text: "sports_esports"
        color: root.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
        fontScale: 1.25
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.setOpen(!root.active)
    }
}

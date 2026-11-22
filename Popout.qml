pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml
import QtCore
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import "."

// Panel de la biblioteca: buscador + cuadrícula de portadas. Un clic (o Intro) lanza el juego.
Item {
    id: root

    Settings {
        id: cfg
        category: "Plugin_biblioteca-gaming"
        property string ocultar: ""
        property int columnas: 5
        property int filas: 3
        property bool cerrarAlLanzar: true
        // Última tienda elegida en los chips ("" = todas). Se recuerda entre aperturas y reinicios.
        property string tienda: ""
        // Ids marcados con el corazón, separados por comas. Se recuerdan entre reinicios.
        property string favoritos: ""
        // recientes | nombre | tienda
        property string orden: "recientes"
        property bool soloFavoritos: false
        // Auto | Español | English
        property string idioma: "Auto"
    }

    Binding {
        target: BibliotecaIdioma
        property: "preferencia"
        value: cfg.idioma
    }

    readonly property bool opened: visible && BibliotecaBridge.popoutShown
    readonly property int cols: Math.max(3, Math.min(8, cfg.columnas || 5))
    readonly property real cardW: 128
    readonly property real coverH: cardW * 1.5
    readonly property real cardH: coverH + 34
    readonly property int filasVisibles: Math.max(1, Math.min(6, cfg.filas || 3))
    readonly property real anchoBarra: 14
    readonly property real huecoCelda: Math.max(Tokens.spacing.medium, 18)
    property var juegos: []
    property string filtro: ""
    property int seleccion: 0
    property bool cargando: false

    // Filtro por tienda: "" = todas. Solo se ofrecen las tiendas que tienen juegos.
    // Se lee de cfg.tienda (persistente); si esa tienda ya no tiene juegos se muestran todas,
    // sin borrar la preferencia guardada.
    readonly property string tienda: tiendas.indexOf(cfg.tienda) !== -1 ? cfg.tienda : ""
    readonly property var nombresTienda: ({ "Steam": "Steam", "Heroic": "Heroic", "Lutris": "Lutris", "App": BibliotecaIdioma.t("Otros") })
    readonly property var iconosTienda: ({ "": "apps", "Steam": "videogame_asset", "Heroic": "shield", "Lutris": "wine_bar", "App": "extension" })
    readonly property var tiendas: ["Steam", "Heroic", "Lutris", "App"].filter(t => juegos.some(j => j.source === t))
    function cuantos(t: string): int { return t ? juegos.filter(j => j.source === t).length : juegos.length; }

    // Favoritos: ids separados por comas en Settings, para que sobrevivan a reinicios del shell.
    readonly property var favoritosIds: String(cfg.favoritos || "").split(",").map(s => s.trim()).filter(s => s !== "")
    readonly property int totalFavoritos: juegos.filter(j => esFavorito(j.id)).length
    function esFavorito(id: string): bool { return favoritosIds.indexOf(id) !== -1; }
    function alternarFavorito(id: string): void {
        const lista = favoritosIds.slice();
        const i = lista.indexOf(id);
        if (i === -1) lista.push(id); else lista.splice(i, 1);
        cfg.favoritos = lista.join(",");
    }

    readonly property var ordenes: ["recientes", "nombre", "tienda"]
    readonly property string orden: ordenes.indexOf(cfg.orden) !== -1 ? cfg.orden : "recientes"

    // Los favoritos van siempre primero, sea cual sea el criterio de orden.
    readonly property var visibles: {
        const f = filtro.trim().toLowerCase();
        const lista = juegos.filter(j => (!tienda || j.source === tienda)
            && (!cfg.soloFavoritos || esFavorito(j.id))
            && (!f || j.name.toLowerCase().indexOf(f) !== -1));
        const porNombre = (a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase());
        const rangoTienda = { "Steam": 0, "Heroic": 1, "Lutris": 2, "App": 3 };
        lista.sort((a, b) => {
            const fa = esFavorito(a.id) ? 0 : 1;
            const fb = esFavorito(b.id) ? 0 : 1;
            if (fa !== fb) return fa - fb;
            if (orden === "nombre") return porNombre(a, b);
            if (orden === "tienda") return ((rangoTienda[a.source] ?? 9) - (rangoTienda[b.source] ?? 9)) || porNombre(a, b);
            return ((b.lastPlayed || 0) - (a.lastPlayed || 0)) || porNombre(a, b);
        });
        return lista;
    }
    onVisiblesChanged: seleccion = 0

    implicitWidth: cols * (cardW + huecoCelda) + anchoBarra + Tokens.padding.extraLarge * 2
    implicitHeight: columna.implicitHeight + Tokens.padding.extraLarge * 2

    function recargar(): void {
        if (lister.running) return;
        cargando = true;
        lister.command = [BibliotecaBridge.lister, "--ocultar", String(cfg.ocultar || "")];
        lister.running = true;
    }

    function lanzar(j: var): void {
        if (!j) return;
        Quickshell.execDetached(j.launch);
        Toaster.toast(BibliotecaIdioma.t("Lanzando"), j.name, "sports_esports", Toast.Info);
        if (cfg.cerrarAlLanzar) BibliotecaBridge.close();
    }

    Process {
        id: lister
        stdinEnabled: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try { root.juegos = JSON.parse(text); } catch (e) { root.juegos = []; }
                root.cargando = false;
            }
        }
    }

    onOpenedChanged: if (opened) { buscador.text = ""; recargar(); buscador.forceActiveFocus(); }
    Component.onCompleted: recargar()

    ColumnLayout {
        id: columna
        anchors.fill: parent
        anchors.margins: Tokens.padding.extraLarge
        spacing: Tokens.spacing.large

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: "sports_esports"
                color: Colours.palette.m3primary
                fontScale: 1.4
            }
            StyledText {
                text: BibliotecaIdioma.t("Juegos")
                font: Tokens.font.title.medium
                color: Colours.palette.m3onSurface
            }
            StyledText {
                Layout.fillWidth: true
                text: root.cargando ? BibliotecaIdioma.t("buscando…")
                    : root.visibles.length === root.juegos.length ? BibliotecaIdioma.t("%1 instalados").replace("%1", root.juegos.length)
                    : BibliotecaIdioma.t("%1 de %2").replace("%1", root.visibles.length).replace("%2", root.juegos.length)
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        // Filtros por tienda (solo si hay más de una)
        RowLayout {
            Layout.fillWidth: true
            visible: root.tiendas.length > 1
            spacing: Tokens.spacing.small

            Repeater {
                model: [""].concat(root.tiendas)
                delegate: ToggleButton {
                    required property string modelData
                    label: (modelData ? root.nombresTienda[modelData] : BibliotecaIdioma.t("Todas")) + " · " + root.cuantos(modelData)
                    icon: root.iconosTienda[modelData] ?? "apps"
                    toggled: root.tienda === modelData
                    onClicked: cfg.tienda = modelData
                }
            }
            Item { Layout.fillWidth: true }
        }

        StyledTextField {
            id: buscador
            Layout.fillWidth: true
            placeholderText: BibliotecaIdioma.t("Buscar juego")
            leadingIcon: "search"
            onTextChanged: root.filtro = text
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) BibliotecaBridge.close();
                else if (event.key === Qt.Key_Right) root.seleccion = Math.min(root.seleccion + 1, root.visibles.length - 1);
                else if (event.key === Qt.Key_Left) root.seleccion = Math.max(root.seleccion - 1, 0);
                else if (event.key === Qt.Key_Down) root.seleccion = Math.min(root.seleccion + root.cols, root.visibles.length - 1);
                else if (event.key === Qt.Key_Up) root.seleccion = Math.max(root.seleccion - root.cols, 0);
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.lanzar(root.visibles[root.seleccion]);
                else return;
                event.accepted = true;
            }
        }

        // Orden de la lista y filtro de favoritos. La preferencia se guarda en Settings.
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            ToggleButton {
                label: BibliotecaIdioma.t("Recientes")
                icon: "history"
                tooltip: BibliotecaIdioma.t("Ordenar por fecha de la última sesión")
                toggled: root.orden === "recientes"
                onClicked: cfg.orden = "recientes"
            }
            ToggleButton {
                label: BibliotecaIdioma.t("Nombre")
                icon: "sort_by_alpha"
                tooltip: BibliotecaIdioma.t("Ordenar por nombre")
                toggled: root.orden === "nombre"
                onClicked: cfg.orden = "nombre"
            }
            ToggleButton {
                label: BibliotecaIdioma.t("Tienda")
                icon: "storefront"
                tooltip: BibliotecaIdioma.t("Agrupar por tienda")
                toggled: root.orden === "tienda"
                onClicked: cfg.orden = "tienda"
            }
            Item { Layout.fillWidth: true }
            ToggleButton {
                label: BibliotecaIdioma.t("Favoritos · %1").replace("%1", root.totalFavoritos)
                icon: "favorite"
                accent: "Error"
                tooltip: BibliotecaIdioma.t("Mostrar solo los juegos marcados con el corazón")
                toggled: cfg.soloFavoritos
                onClicked: cfg.soloFavoritos = !cfg.soloFavoritos
            }
        }

        StyledText {
            visible: !root.cargando && root.visibles.length === 0
            Layout.fillWidth: true
            text: root.juegos.length
                ? (cfg.soloFavoritos && root.totalFavoritos === 0 ? BibliotecaIdioma.t("Aún no hay favoritos: pulsa el corazón de un juego") : BibliotecaIdioma.t("Ningún juego coincide"))
                : BibliotecaIdioma.t("No se han encontrado juegos")
            color: Colours.palette.m3onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
        }

        GridView {
            id: rejilla
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(Math.ceil(root.visibles.length / root.cols), root.filasVisibles) * cellHeight
            rightMargin: root.anchoBarra
            visible: root.visibles.length > 0
            clip: true
            cellWidth: root.cardW + root.huecoCelda
            cellHeight: root.cardH + root.huecoCelda
            boundsBehavior: Flickable.StopAtBounds
            model: root.visibles
            currentIndex: root.seleccion
            // La selección con el teclado siempre queda a la vista
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

            // Barra de desplazamiento (también se baja con la rueda o arrastrando)
            StyledScrollBar.vertical: StyledScrollBar {
                flickable: rejilla
            }

            delegate: Item {
                id: carta
                required property var modelData
                required property int index
                readonly property bool marcada: index === root.seleccion || zona.containsMouse || hoverCorazon.hovered
                readonly property bool esFavorito: root.esFavorito(modelData.id)
                // La celda entera: la tarjeta va centrada para que el anillo y el zoom no se
                // recorten contra el borde de la rejilla (que tiene clip).
                width: rejilla.cellWidth
                height: rejilla.cellHeight

                Item {
                    id: tarjeta
                    // Por encima del MouseArea de la celda: si no, el clic del corazón nunca llega
                    // (el z de los hijos no sale del orden de su padre).
                    z: 1
                    anchors.centerIn: parent
                    width: root.cardW
                    height: root.cardH
                    scale: carta.marcada ? 1.03 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    // Sombra bajo la portada; sube al marcarla
                    Elevation {
                        anchors.fill: portada
                        radius: portada.radius
                        level: carta.marcada ? 3 : 1
                    }

                    // Portada recortada con esquinas redondeadas, sin borde dentro: el borde
                    // dentro del recorte quedaba tapado por la imagen y cortado al escalar.
                    StyledClippingRect {
                        id: portada
                        width: parent.width
                        height: root.coverH
                        radius: Tokens.rounding.large
                        color: Colours.palette.m3surfaceContainerHigh

                        // Portada vertical (Steam, Heroic, Lutris)
                        Image {
                            anchors.fill: parent
                            visible: !!carta.modelData.cover
                            source: carta.modelData.cover ? "file://" + carta.modelData.cover : ""
                            sourceSize: Qt.size(256, 384)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            mipmap: true
                        }
                        // Sin portada: icono centrado
                        Image {
                            anchors.centerIn: parent
                            width: parent.width * 0.55
                            height: width
                            visible: !carta.modelData.cover && !!carta.modelData.icon
                            source: (!carta.modelData.cover && carta.modelData.icon) ? "file://" + carta.modelData.icon : ""
                            sourceSize: Qt.size(128, 128)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                        MaterialIcon {
                            anchors.centerIn: parent
                            visible: !carta.modelData.cover && !carta.modelData.icon
                            text: "sports_esports"
                            fontScale: 2.2
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }

                    // Contorno fino siempre visible, por encima de la imagen y fuera del recorte:
                    // separa las portadas oscuras del fondo.
                    StyledRect {
                        anchors.fill: portada
                        radius: portada.radius
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.alpha(Colours.palette.m3outlineVariant, carta.marcada ? 0 : 0.6)
                    }

                    // Anillo de selección separado de la portada, con esquinas concéntricas
                    StyledRect {
                        readonly property real hueco: 4
                        x: portada.x - hueco
                        y: portada.y - hueco
                        width: portada.width + hueco * 2
                        height: portada.height + hueco * 2
                        radius: portada.radius + hueco
                        color: "transparent"
                        border.width: 2
                        border.color: Colours.palette.m3primary
                        opacity: carta.marcada ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }

                    // Corazón de favorito: siempre visible en los marcados y al pasar por la tarjeta
                    // en el resto. Va por encima del MouseArea de la celda para que el clic no lance el juego.
                    Item {
                        id: corazon
                        z: 10
                        anchors.top: portada.top
                        anchors.right: portada.right
                        anchors.margins: 6
                        width: 30
                        height: 30
                        opacity: carta.esFavorito || carta.marcada || hoverCorazon.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }

                        StyledRect {
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.92)
                            border.width: 1
                            border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.7)
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "favorite"
                            fill: carta.esFavorito ? 1 : 0
                            color: carta.esFavorito ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                            fontScale: 1
                        }

                        HoverHandler {
                            id: hoverCorazon
                            cursorShape: Qt.PointingHandCursor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.alternarFavorito(carta.modelData.id)
                        }
                    }

                    StyledText {
                        anchors.top: portada.bottom
                        anchors.topMargin: Tokens.spacing.small + 4
                        width: parent.width
                        text: carta.modelData.name
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        font: Tokens.font.label.medium
                        color: carta.marcada ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    }
                }

                MouseArea {
                    id: zona
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.seleccion = carta.index
                    onClicked: root.lanzar(carta.modelData)
                }
            }
        }
    }
}

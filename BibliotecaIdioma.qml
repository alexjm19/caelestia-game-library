pragma Singleton

import QtQuick
import Caelestia

// Traducciones del panel. El español es el idioma fuente y el inglés va en el mapa:
// así el plugin no depende del traductor global de caelestia (que carga un solo
// catálogo `caelestia_*.qm` y no puede fusionar el de un plugin).
QtObject {
    id: root

    // "Auto" sigue el idioma activo del shell; "Español"/"English" lo fuerzan.
    property string preferencia: "Auto"

    readonly property string codigo: {
        if (preferencia === "Español")
            return "es";
        if (preferencia === "English")
            return "en";
        const activo = String(Translations.activeLanguage || "");
        if (activo)
            return activo.indexOf("es") === 0 ? "es" : "en";
        return Qt.locale().name.indexOf("es") === 0 ? "es" : "en";
    }

    readonly property var ingles: ({
            "Juegos": "Games",
            "buscando…": "searching…",
            "%1 instalados": "%1 installed",
            "%1 de %2": "%1 of %2",
            "Todas": "All",
            "Otros": "Others",
            "Buscar juego": "Search games",
            "Recientes": "Recent",
            "Nombre": "Name",
            "Tienda": "Store",
            "Favoritos · %1": "Favorites · %1",
            "Ordenar por fecha de la última sesión": "Sort by last played",
            "Ordenar por nombre": "Sort by name",
            "Agrupar por tienda": "Group by store",
            "Mostrar solo los juegos marcados con el corazón": "Show only games marked with a heart",
            "Aún no hay favoritos: pulsa el corazón de un juego": "No favorites yet: click the heart on a game",
            "Ningún juego coincide": "No games match",
            "No se han encontrado juegos": "No games found",
            "Lanzando": "Launching"
        })

    function t(texto: string): string {
        return root.codigo === "en" ? (root.ingles[texto] ?? texto) : texto;
    }
}

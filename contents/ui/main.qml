import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    // ── Reglas predefinidas ───────────────────────────────────────────────────
    readonly property var defaultRules: [
        { name: "Vídeo",                matchType: "extension", pattern: "mp4, avi, mkv, mov, wmv, flv, webm, m4v, 3gp, ts",                                                                                                                                             destination: "", enabled: false, icon: "video-x-generic" },
        { name: "Audio",                matchType: "extension", pattern: "mp3, flac, wav, aac, ogg, m4a, wma, opus, aiff",                                                                                                                                                destination: "", enabled: false, icon: "audio-x-generic" },
        { name: "Imágenes",             matchType: "extension", pattern: "jpg, jpeg, png, gif, webp, bmp, tiff, heic, svg, raw",                                                                                                                                          destination: "", enabled: false, icon: "image-x-generic" },
        { name: "Documentos",           matchType: "extension", pattern: "pdf, doc, docx, xls, xlsx, ppt, pptx, txt, odt, ods, odp, rtf, csv",                                                                                                                           destination: "", enabled: false, icon: "x-office-document" },
        { name: "Ebooks",               matchType: "extension", pattern: "epub, mobi, azw, azw3, fb2, djvu",                                                                                                                                                              destination: "", enabled: false, icon: "application-epub+zip" },
        { name: "Archivos comprimidos", matchType: "extension", pattern: "zip, rar, 7z, tar, gz, bz2, xz",                                                                                                                                                               destination: "", enabled: false, icon: "application-zip" },
        { name: "APKs",                 matchType: "extension", pattern: "apk, xapk, apks",                                                                                                                                                                              destination: "", enabled: false, icon: "application-vnd.android.package-archive" },
        { name: "Código fuente",        matchType: "extension", pattern: "py, sh, bash, c, cpp, h, hpp, kt, kts, java, js, ts, html, css, xml, json, yaml, yml, toml, ini, cfg, conf, sql, rb, php, swift, go, rs, lua, r, m, cs, vb, dart, gradle",                   destination: "", enabled: false, icon: "text-x-script" },
        { name: "Binarios",             matchType: "extension", pattern: "exe, msi, dmg, pkg, deb, rpm, appimage, run, bin, out, elf, so, dll, jar, war",                                                                                                                destination: "", enabled: false, icon: "application-x-executable" }
    ]

    // ── Compact (ícono del panel) ─────────────────────────────────────────────
    compactRepresentation: Item {
        implicitWidth:  Kirigami.Units.iconSizes.medium
        implicitHeight: Kirigami.Units.iconSizes.medium

        DropArea {
            id: dropArea
            anchors.fill: parent
            keys: ["text/uri-list"]

            // Sin parámetro — evita "Too many arguments"
            onEntered: { dropHighlight.visible = true }
            onExited:  { dropHighlight.visible = false }
            onDropped: (drop) => {
                dropHighlight.visible = false
                if (drop.hasUrls) processDroppedFiles(drop.urls)
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: dropArea.containsDrag ? "folder-open" : "folder-symbolic"
            opacity: dropArea.containsDrag ? 0.6 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        Rectangle {
            id: dropHighlight
            anchors.fill: parent
            color:   Kirigami.Theme.highlightColor
            opacity: 0.35
            radius:  4
            visible: false
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton)
                    contextMenu.open(mouse.x, mouse.y)
            }
        }

        PlasmaComponents.Menu {
            id: contextMenu
            PlasmaComponents.MenuItem {
                text: i18n("Configurar Magic Folder…")
                icon.name: "configure"
                onClicked: plasmoid.internalAction("configure").trigger()
            }
        }
    }

    // ── Full representation ───────────────────────────────────────────────────
    fullRepresentation: Item {
        implicitWidth:  Kirigami.Units.gridUnit * 20
        implicitHeight: Kirigami.Units.gridUnit * 14

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                level: 2
                text: "Magic Folder"
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                text: i18n("Soltá archivos sobre el ícono del panel para moverlos automáticamente.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                text: {
                    var active = 0
                    for (var i = 0; i < rulesModel.count; i++)
                        if (rulesModel.get(i).enabled) active++
                    return i18n("Reglas activas: %1 de %2", active, rulesModel.count)
                }
                opacity: 0.7
            }

            Item { Layout.fillHeight: true }

            PlasmaComponents.Button {
                text: i18n("Configurar reglas…")
                icon.name: "configure"
                Layout.alignment: Qt.AlignRight
                onClicked: plasmoid.internalAction("configure").trigger()
            }
        }
    }

    // ── Modelo de reglas ──────────────────────────────────────────────────────
    ListModel { id: rulesModel }

    function initRules() {
        var raw = plasmoid.configuration.rules
        if (!raw || raw === "[]" || raw === "") {
            plasmoid.configuration.rules = JSON.stringify(defaultRules)
        }
        loadRules()
    }

    function loadRules() {
        rulesModel.clear()
        var raw = plasmoid.configuration.rules
        if (!raw || raw === "") return
        try {
            var arr = JSON.parse(raw)
            for (var i = 0; i < arr.length; i++) rulesModel.append(arr[i])
        } catch(e) {
            console.warn("MagicFolder: error al parsear reglas:", e)
        }
    }

    // ── Procesar archivos soltados ────────────────────────────────────────────
    function processDroppedFiles(urls) {
        loadRules()
        var messages = []
        var hasErrors = false
        var strategy = plasmoid.configuration.conflictStrategy

        for (var i = 0; i < urls.length; i++) {
            var url      = urls[i].toString()
            var filename = decodeURIComponent(url.split("/").pop())
            var ext      = filename.includes(".") ? filename.split(".").pop().toLowerCase() : ""
            var dest     = findDestination(ext)

            if (dest) {
                executable.moveFile(url, dest, filename, strategy)
                messages.push("✓ " + filename + " → " + dest.split("/").pop())
            } else {
                hasErrors = true
                messages.push("? " + filename + " (sin regla)")
            }
        }

        if (plasmoid.configuration.showNotifications)
            showNotification(messages.join("\n"), hasErrors)
    }

    function findDestination(ext) {
        for (var i = 0; i < rulesModel.count; i++) {
            var rule = rulesModel.get(i)
            if (!rule.enabled || !rule.destination) continue
            var exts = rule.pattern.toLowerCase()
                           .split(",")
                           .map(function(s){ return s.trim().replace(/^\./, "") })
            if (exts.indexOf(ext) !== -1) return rule.destination
        }
        return null
    }

    // ── Notificación via notify-send ──────────────────────────────────────────
    function showNotification(message, hasErrors) {
        var icon = hasErrors ? "dialog-warning" : "folder-symbolic"
        // Escapamos el mensaje para passarlo como argumento
        var safeMsg = message.replace(/\\/g, "\\\\").replace(/"/g, '\\"')
        notifSource.connectSource(
            "notify-send --icon=" + icon + " --app-name=MagicFolder --expire-time=4000 \"Magic Folder\" \"" + safeMsg + "\""
        )
    }

    Plasma5Support.DataSource {
        id: notifSource
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName) => { disconnectSource(sourceName) }
    }

    // ── Ejecutor de mv ────────────────────────────────────────────────────────
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        function moveFile(srcUrl, destFolder, filename, strategy) {
            var src  = srcUrl.replace(/^file:\/\//, "")
            var dest = destFolder.replace(/^file:\/\//, "")

            function esc(s) { return "'" + s.replace(/'/g, "'\\''") + "'" }

            var cmd
            if (strategy === 0) {
                cmd = "[ ! -e " + esc(dest + "/" + filename) + " ] && mv -- " +
                      esc(src) + " " + esc(dest + "/" + filename) + " || true"
            } else if (strategy === 2) {
                cmd = "mv -f -- " + esc(src) + " " + esc(dest + "/" + filename)
            } else {
                // Mantener ambos: renombrar _1, _2, …
                cmd = [
                    "(src=" + esc(src),
                    "dest=" + esc(dest),
                    "name=" + esc(filename),
                    "if echo \"$name\" | grep -q '\\.'; then base=\"${name%.*}\"; ext=\".${name##*.}\"; else base=\"$name\"; ext=''; fi",
                    "target=\"$dest/$name\"; n=1",
                    "while [ -e \"$target\" ]; do target=\"$dest/${base}_${n}${ext}\"; n=$((n+1)); done",
                    "mv -- \"$src\" \"$target\")"
                ].join("; ")
            }

            connectSource(cmd)
        }

        onNewData: (sourceName, data) => {
            if (data["exit code"] !== 0)
                console.warn("MagicFolder: error en mv:", data["stderr"])
            disconnectSource(sourceName)
        }
    }

    Component.onCompleted: initRules()

    Connections {
        target: plasmoid.configuration
        function onRulesChanged() { loadRules() }
    }
}

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

// En Plasma 6 las páginas de config deben declarar las propiedades cfg_*
// que quieran leer/escribir. El sistema las inyecta automáticamente.
Kirigami.ScrollablePage {
    id: configRulesPage

    // Propiedades cfg_* requeridas por Plasma 6
    // Plasma inyecta tanto cfg_X como cfg_XDefault — hay que declarar ambas
    property string cfg_rules:                    ""
    property string cfg_rulesDefault:             ""
    property bool   cfg_showNotifications:        true
    property bool   cfg_showNotificationsDefault: true
    property bool   cfg_showErrorDetails:         true
    property bool   cfg_showErrorDetailsDefault:  true
    property int    cfg_conflictStrategy:         1
    property int    cfg_conflictStrategyDefault:  1

    // Modelo interno de reglas
    ListModel { id: rulesModel }

    function loadFromConfig() {
        rulesModel.clear()
        if (!cfg_rules || cfg_rules === "") return
        try {
            var arr = JSON.parse(cfg_rules)
            for (var i = 0; i < arr.length; i++) rulesModel.append(arr[i])
        } catch(e) { console.warn("MagicFolder configRules: parse error", e) }
    }

    function saveToConfig() {
        var arr = []
        for (var i = 0; i < rulesModel.count; i++) arr.push(rulesModel.get(i))
        cfg_rules = JSON.stringify(arr)
    }

    Component.onCompleted: loadFromConfig()

    actions: [
        Kirigami.Action {
            text: i18n("Agregar regla")
            icon.name: "list-add"
            onTriggered: ruleDialog.openNew()
        }
    ]

    // ── Lista de reglas ───────────────────────────────────────────────────────
    // Usamos ListView (requerido por SwipeListItem) dentro del ScrollablePage
    ListView {
        id: rulesList
        implicitHeight: contentHeight
        model: rulesModel
        spacing: 2

        // Mensaje cuando no hay reglas
        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            visible: rulesModel.count === 0
            text: i18n("No hay reglas definidas")
            explanation: i18n("Hacé clic en \"Agregar regla\" para comenzar")
            icon.name: "folder-symbolic"
        }

        delegate: Kirigami.SwipeListItem {
            id: delegateItem
            width: rulesList.width

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                // Switch de activación
                QQC2.Switch {
                    id: ruleSwitch
                    checked: model.enabled
                    enabled: model.destination !== ""
                    onToggled: {
                        rulesModel.setProperty(index, "enabled", checked)
                        saveToConfig()
                    }
                    QQC2.ToolTip {
                        visible: ruleSwitch.hovered
                        text: model.destination === ""
                            ? i18n("Configurá una carpeta destino primero")
                            : (ruleSwitch.checked ? i18n("Desactivar") : i18n("Activar"))
                    }
                }

                // Ícono de categoría
                Kirigami.Icon {
                    source: model.icon || "folder-symbolic"
                    width:  Kirigami.Units.iconSizes.smallMedium
                    height: Kirigami.Units.iconSizes.smallMedium
                    opacity: model.enabled ? 1.0 : 0.5
                }

                // Nombre + destino + extensiones
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    QQC2.Label {
                        text: model.name
                        font.bold: model.enabled
                        Layout.fillWidth: true
                    }

                    QQC2.Label {
                        text: model.destination !== ""
                            ? model.destination
                            : i18n("⚠ Sin carpeta destino — hacé clic en editar")
                        color: model.destination !== ""
                            ? Kirigami.Theme.textColor
                            : Kirigami.Theme.neutralTextColor
                        opacity: model.destination !== "" ? 0.65 : 1.0
                        elide: Text.ElideLeft
                        Layout.fillWidth: true
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }

                    QQC2.Label {
                        text: model.pattern
                        opacity: 0.4
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        font.pointSize: Kirigami.Theme.smallFont.pointSize - 1
                    }
                }
            }

            actions: [
                Kirigami.Action {
                    icon.name: "edit-entry"
                    text: i18n("Editar")
                    onTriggered: ruleDialog.openEdit(index)
                },
                Kirigami.Action {
                    icon.name: "arrow-up"
                    text: i18n("Subir")
                    enabled: index > 0
                    onTriggered: { rulesModel.move(index, index - 1, 1); saveToConfig() }
                },
                Kirigami.Action {
                    icon.name: "arrow-down"
                    text: i18n("Bajar")
                    enabled: index < rulesModel.count - 1
                    onTriggered: { rulesModel.move(index, index + 1, 1); saveToConfig() }
                },
                Kirigami.Action {
                    icon.name: "edit-delete"
                    text: i18n("Eliminar")
                    onTriggered: { rulesModel.remove(index); saveToConfig() }
                }
            ]
        }
    }

    // ── Diálogo agregar/editar ────────────────────────────────────────────────
    Kirigami.Dialog {
        id: ruleDialog

        property int editIndex: -1

        title: editIndex === -1 ? i18n("Agregar regla") : i18n("Editar regla")
        preferredWidth: Kirigami.Units.gridUnit * 30
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        onAccepted: {
            if (!nameField.text || !patternField.text) return
            var rule = {
                name:        nameField.text,
                matchType:   "extension",
                pattern:     patternField.text,
                destination: destinationField.text,
                enabled:     destinationField.text !== "",
                icon:        iconField.text || "folder-symbolic"
            }
            if (editIndex === -1) {
                rulesModel.append(rule)
            } else {
                rulesModel.set(editIndex, rule)
            }
            saveToConfig()
        }

        function openNew() {
            editIndex = -1
            nameField.text = ""
            patternField.text = ""
            destinationField.text = ""
            iconField.text = ""
            open()
        }

        function openEdit(idx) {
            editIndex = idx
            var r = rulesModel.get(idx)
            nameField.text        = r.name
            patternField.text     = r.pattern
            destinationField.text = r.destination
            iconField.text        = r.icon || ""
            open()
        }

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            Kirigami.FormLayout {
                Layout.fillWidth: true

                QQC2.TextField {
                    id: nameField
                    Kirigami.FormData.label: i18n("Nombre:")
                    placeholderText: i18n("Ej: Vídeos")
                    Layout.fillWidth: true
                }

                QQC2.TextField {
                    id: patternField
                    Kirigami.FormData.label: i18n("Extensiones:")
                    placeholderText: i18n("mp4, mkv, avi")
                    Layout.fillWidth: true
                }

                RowLayout {
                    Kirigami.FormData.label: i18n("Carpeta destino:")
                    Layout.fillWidth: true

                    QQC2.TextField {
                        id: destinationField
                        placeholderText: i18n("/home/usuario/Vídeos")
                        Layout.fillWidth: true
                    }

                    QQC2.Button {
                        icon.name: "folder-open"
                        text: i18n("Explorar…")
                        onClicked: folderDialog.open()
                    }
                }

                QQC2.TextField {
                    id: iconField
                    Kirigami.FormData.label: i18n("Ícono (opcional):")
                    placeholderText: i18n("video-x-generic")
                    Layout.fillWidth: true
                }
            }

            QQC2.Label {
                text: i18n("Íconos sugeridos: video-x-generic · audio-x-generic · image-x-generic · x-office-document · application-zip · text-x-script · application-x-executable · application-epub+zip")
                wrapMode: Text.WordWrap
                opacity: 0.6
                Layout.fillWidth: true
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }
    }

    FolderDialog {
        id: folderDialog
        onAccepted: {
            destinationField.text = selectedFolder.toString().replace(/^file:\/\//, "")
        }
    }
}

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Kirigami.ScrollablePage {
    id: configRulesPage

    property string cfg_rules:                    ""
    property string cfg_rulesDefault:             ""
    property bool   cfg_showNotifications:        true
    property bool   cfg_showNotificationsDefault: true
    property bool   cfg_showErrorDetails:         true
    property bool   cfg_showErrorDetailsDefault:  true
    property int    cfg_conflictStrategy:         1
    property int    cfg_conflictStrategyDefault:  1

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
            text: i18n("Add rule")
            icon.name: "list-add"
            onTriggered: ruleDialog.openNew()
        }
    ]

    ListView {
        id: rulesList
        implicitHeight: contentHeight
        model: rulesModel
        spacing: 2

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            visible: rulesModel.count === 0
            text: i18n("No rules defined")
            explanation: i18n("Click \"Add rule\" to get started")
            icon.name: "folder-symbolic"
        }

        delegate: Kirigami.SwipeListItem {
            id: delegateItem
            width: rulesList.width

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

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
                            ? i18n("Set a destination folder first")
                            : (ruleSwitch.checked ? i18n("Disable rule") : i18n("Enable rule"))
                    }
                }

                Kirigami.Icon {
                    source: model.icon || "folder-symbolic"
                    width:  Kirigami.Units.iconSizes.smallMedium
                    height: Kirigami.Units.iconSizes.smallMedium
                    opacity: model.enabled ? 1.0 : 0.5
                }

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
                            : i18n("⚠ No destination folder — click edit")
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
                    text: i18n("Edit")
                    onTriggered: ruleDialog.openEdit(index)
                },
                Kirigami.Action {
                    icon.name: "arrow-up"
                    text: i18n("Move up")
                    enabled: index > 0
                    onTriggered: { rulesModel.move(index, index - 1, 1); saveToConfig() }
                },
                Kirigami.Action {
                    icon.name: "arrow-down"
                    text: i18n("Move down")
                    enabled: index < rulesModel.count - 1
                    onTriggered: { rulesModel.move(index, index + 1, 1); saveToConfig() }
                },
                Kirigami.Action {
                    icon.name: "edit-delete"
                    text: i18n("Delete")
                    onTriggered: { rulesModel.remove(index); saveToConfig() }
                }
            ]
        }
    }

    // ── Add / Edit dialog ─────────────────────────────────────────────────────
    Kirigami.Dialog {
        id: ruleDialog
        property int editIndex: -1

        title: editIndex === -1 ? i18n("Add rule") : i18n("Edit rule")
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
            if (editIndex === -1) rulesModel.append(rule)
            else rulesModel.set(editIndex, rule)
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
                    Kirigami.FormData.label: i18n("Name:")
                    placeholderText: i18n("E.g.: Videos")
                    Layout.fillWidth: true
                }
                QQC2.TextField {
                    id: patternField
                    Kirigami.FormData.label: i18n("Extensions:")
                    placeholderText: i18n("mp4, mkv, avi")
                    Layout.fillWidth: true
                }
                RowLayout {
                    Kirigami.FormData.label: i18n("Destination folder:")
                    Layout.fillWidth: true
                    QQC2.TextField {
                        id: destinationField
                        placeholderText: i18n("/home/user/Videos")
                        Layout.fillWidth: true
                    }
                    QQC2.Button {
                        icon.name: "folder-open"
                        text: i18n("Browse…")
                        onClicked: folderDialog.open()
                    }
                }
                QQC2.TextField {
                    id: iconField
                    Kirigami.FormData.label: i18n("Icon (optional):")
                    placeholderText: i18n("video-x-generic")
                    Layout.fillWidth: true
                }
            }

            QQC2.Label {
                text: i18n("Suggested icons: video-x-generic · audio-x-generic · image-x-generic · x-office-document · application-zip · text-x-script · application-x-executable · application-epub+zip")
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

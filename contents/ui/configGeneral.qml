import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Kirigami.ScrollablePage {

    property string cfg_rules:                    ""
    property string cfg_rulesDefault:             ""
    property bool   cfg_showNotifications:        true
    property bool   cfg_showNotificationsDefault: true
    property bool   cfg_showErrorDetails:         true
    property bool   cfg_showErrorDetailsDefault:  true
    property int    cfg_conflictStrategy:         1
    property int    cfg_conflictStrategyDefault:  1

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {

            QQC2.CheckBox {
                Kirigami.FormData.label: i18n("Notifications:")
                text: i18n("Show notification after each operation")
                checked: cfg_showNotifications
                onToggled: cfg_showNotifications = checked
            }

            QQC2.ComboBox {
                Kirigami.FormData.label: i18n("If the file already exists:")
                model: [
                    i18n("Skip (don't move)"),
                    i18n("Keep both (rename: file_1.ext)"),
                    i18n("Overwrite")
                ]
                currentIndex: cfg_conflictStrategy
                onActivated: cfg_conflictStrategy = currentIndex
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Warning
            text: i18n("⚠  Files are moved permanently. Verify your rules and destination folders before using them with important files.")
            visible: true
        }

        QQC2.Button {
            text: i18n("Restore default rules")
            icon.name: "edit-reset"
            onClicked: resetDialog.open()
        }

        Kirigami.Dialog {
            id: resetDialog
            title: i18n("Restore default rules?")
            standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
            onAccepted: { cfg_rules = "" }
            QQC2.Label {
                text: i18n("This will delete all custom rules and restore the 9 default categories (disabled, no destination set). Continue?")
                wrapMode: Text.WordWrap
                width: Kirigami.Units.gridUnit * 22
            }
        }
    }
}

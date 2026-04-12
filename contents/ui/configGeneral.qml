import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Kirigami.ScrollablePage {

    property bool cfg_showNotifications:        true
    property bool cfg_showNotificationsDefault: true
    property bool cfg_showErrorDetails:         true
    property bool cfg_showErrorDetailsDefault:  true
    property int  cfg_conflictStrategy:         1
    property int  cfg_conflictStrategyDefault:  1

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {

            QQC2.CheckBox {
                Kirigami.FormData.label: i18n("Notificaciones:")
                text: i18n("Mostrar notificación luego de cada operación")
                checked: cfg_showNotifications
                onToggled: cfg_showNotifications = checked
            }

            // Conflict strategy — default index 1 = "Mantener ambos"
            QQC2.ComboBox {
                Kirigami.FormData.label: i18n("Si el archivo ya existe:")
                // 0 = Omitir, 1 = Mantener ambos (renombrar), 2 = Sobreescribir
                model: [
                    i18n("Omitir (no mover)"),
                    i18n("Mantener ambos (renombrar: archivo_1.ext)"),
                    i18n("Sobreescribir")
                ]
                currentIndex: cfg_conflictStrategy
                onActivated: cfg_conflictStrategy = currentIndex
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Warning
            text: i18n("⚠  Los archivos se mueven de forma permanente. Verificá bien las reglas y carpetas destino antes de usarlas con archivos importantes.")
            visible: true
        }

        // Reset to defaults button
        QQC2.Button {
            text: i18n("Restaurar reglas predeterminadas")
            icon.name: "edit-reset"
            onClicked: resetDialog.open()
        }

        Kirigami.Dialog {
            id: resetDialog
            title: i18n("¿Restaurar reglas predeterminadas?")
            standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
            onAccepted: {
                // Clear rules so initRules() seeds defaults on next load
                plasmoid.configuration.rules = ""
            }
            QQC2.Label {
                text: i18n("Esto eliminará todas las reglas personalizadas y restaurará las 9 categorías predefinidas (desactivadas). ¿Continuar?")
                wrapMode: Text.WordWrap
                width: Kirigami.Units.gridUnit * 22
            }
        }
    }
}

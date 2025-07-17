/* =============================================================================
   File name     : coordinate_converter.qml
   Description   : Ce plugin QField permet de tansformer des coordonnées DMS ou DDM en destination. Et de transformer des coordonnées Lambert93 en DMS ou DDM. This plugin lets you set a destination from DMS or DDM coordinates, and convert Lambert93 coordinates to DMS or DDM.
   Author        : BOYER Antoine
   Creation date : 02/07/2024
   Version       : 1.1
   Licence       : GPL v3
============================================================================= */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.qfield
import org.qgis
import Theme

Item {
    id: plugin

    // Propriétés principales
    property var mainWindow: iface.mainWindow()
    property var mapSettings: iface.mapCanvas().mapSettings
    property var geometryHighlighter: iface.findItemByObjectName('geometryHighlighter')
    property var canvasEPSG: parseInt(mapSettings.project.crs.authid.split(":")[1])
    property bool showPanel: false
    property int tabIndex: 0 // 0 = DMS, 1 = Lambert, 2 = DDM, 3 = Lambert DDM Opens the tab on the DMS to destination window

    Component.onCompleted: iface.addItemToPluginsToolbar(goToDMSbutton) // Adds the plugin button to the QField ui

    QfToolButton { // Bouton de lancement du plugin
        id: goToDMSbutton
        iconSource: 'icon.svg'
        bgcolor: "white"
        round: true
        ToolTip.visible: hovered
        onClicked: plugin.showPanel = !plugin.showPanel // When the user clicks on the button it displays the ui of the plugin
    }

    Rectangle { // Main window
        id: mainPanel
        visible: plugin.showPanel
        parent: iface.mapCanvas()
        anchors.centerIn: parent
        width: parent.width < 400 ? parent.width * 0.98 : 400
        height: parent.height < 400 ? parent.height * 0.95 : 360
        color: "#f8f9f9"
        border.color: "#616161"
        border.width: 2
        radius: 10
        z: 9999

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 6 // Réduit pour gagner de la place
            anchors.rightMargin: 6
            spacing: 8

            // Grid (2x2) des quatre menus du plugin
            GridLayout {
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                // Les boutons de menu prennent la largeur de leur colonne, mais n'excèdent jamais 180px
                Button {
                    text: qsTr("DMS → Destination")
                    checkable: true
                    checked: plugin.tabIndex === 0
                    onClicked: plugin.tabIndex = 0
                    Layout.fillWidth: true
                    Layout.maximumWidth: 180
                }
                Button {
                    text: qsTr("DDM → Destination")
                    checkable: true
                    checked: plugin.tabIndex === 2
                    onClicked: plugin.tabIndex = 2
                    Layout.fillWidth: true
                    Layout.maximumWidth: 180
                }
                Button {
                    text: qsTr("Lambert93 → DMS")
                    checkable: true
                    checked: plugin.tabIndex === 1
                    onClicked: plugin.tabIndex = 1
                    Layout.fillWidth: true
                    Layout.maximumWidth: 180
                    Layout.row: 1
                    Layout.column: 0
                }
                Button {
                    text: qsTr("Lambert93 → DDM")
                    checkable: true
                    checked: plugin.tabIndex === 3
                    onClicked: plugin.tabIndex = 3
                    Layout.fillWidth: true
                    Layout.maximumWidth: 180
                    Layout.row: 1
                    Layout.column: 1
                }
            }

            // DMS → Destination
            Item {
                visible: plugin.tabIndex === 0
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 0
                    anchors.rightMargin: 0
                    spacing: 8

                    Label {
                        text: qsTr("Transformer des coordonnées DMS en destination")
                        font.bold: true
                        Layout.alignment: Qt.AlignLeft
                    }

                    // Saisie DMS
                    GridLayout {
                        columns: 7
                        rowSpacing: 6
                        columnSpacing: 6

                        // Latitude
                        Label { text: qsTr("Latitude"); Layout.row: 0; Layout.column: 0; Layout.alignment: Qt.AlignLeft }
                        ComboBox { id: latCombo; model: [qsTr("N"), qsTr("S")]; Layout.preferredWidth: 60; Layout.row: 0; Layout.column: 1 }
                        TextField {
                            id: latDeg
                            placeholderText: qsTr("°")
                            Layout.preferredWidth: 40
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 0; Layout.column: 2
                            validator: IntValidator { bottom: 0; top: 90 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            onTextChanged: if (text.length === 2) latMin.forceActiveFocus()
                            Keys.onReturnPressed: latMin.forceActiveFocus()
                        }
                        TextField {
                            id: latMin
                            placeholderText: qsTr("'")
                            Layout.preferredWidth: 40
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 0; Layout.column: 3
                            validator: IntValidator { bottom: 0; top: 59 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            onTextChanged: if (text.length === 2) latSec.forceActiveFocus()
                            Keys.onReturnPressed: latSec.forceActiveFocus()
                        }
                        TextField {
                            id: latSec
                            placeholderText: qsTr("\"")
                            Layout.preferredWidth: 40
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 0; Layout.column: 4
                            validator: IntValidator { bottom: 0; top: 59 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            onTextChanged: if (text.length === 2) latSecDec.forceActiveFocus()
                            Keys.onReturnPressed: latSecDec.forceActiveFocus()
                        }
                        Label { text: qsTr(","); font.pixelSize: 18; verticalAlignment: Text.AlignVCenter; Layout.row: 0; Layout.column: 5 }
                        TextField {
                            id: latSecDec
                            Layout.preferredWidth: 50
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 0; Layout.column: 6
                            validator: IntValidator { bottom: 0; top: 99 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            Keys.onReturnPressed: lonDeg.forceActiveFocus()
                        }
                        // Longitude
                        Label { text: qsTr("Longitude"); Layout.row: 1; Layout.column: 0; Layout.alignment: Qt.AlignLeft }
                        ComboBox { id: lonCombo; model: [qsTr("E"), qsTr("W")]; Layout.preferredWidth: 60; Layout.row: 1; Layout.column: 1 }
                        TextField {
                            id: lonDeg
                            placeholderText: qsTr("°")
                            Layout.preferredWidth: 40
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 1; Layout.column: 2
                            validator: IntValidator { bottom: 0; top: 180 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            onTextChanged: if (text.length === 2) lonMin.forceActiveFocus()
                            Keys.onReturnPressed: lonMin.forceActiveFocus()
                        }
                        TextField {
                            id: lonMin
                            placeholderText: qsTr("'")
                            Layout.preferredWidth: 40
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 1; Layout.column: 3
                            validator: IntValidator { bottom: 0; top: 59 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            onTextChanged: if (text.length === 2) lonSec.forceActiveFocus()
                            Keys.onReturnPressed: lonSec.forceActiveFocus()
                        }
                        TextField {
                            id: lonSec
                            placeholderText: qsTr("\"")
                            Layout.preferredWidth: 40
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 1; Layout.column: 4
                            validator: IntValidator { bottom: 0; top: 59 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            onTextChanged: if (text.length === 2) lonSecDec.forceActiveFocus()
                            Keys.onReturnPressed: lonSecDec.forceActiveFocus()
                        }
                        Label { text: qsTr(","); font.pixelSize: 18; verticalAlignment: Text.AlignVCenter; Layout.row: 1; Layout.column: 5 }
                        TextField {
                            id: lonSecDec
                            Layout.preferredWidth: 50
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 1; Layout.column: 6
                            validator: IntValidator { bottom: 0; top: 99 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            Keys.onReturnPressed: latCombo.forceActiveFocus()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Button {
                            text: qsTr("Définir comme destination")
                            Layout.fillWidth: true
                            enabled: 
                                latDeg.acceptableInput &&
                                latMin.acceptableInput &&
                                lonDeg.acceptableInput &&
                                lonMin.acceptableInput
                            onClicked: {
                                let lat_deg = parseInt(latDeg.text)
                                let lat_min = parseInt(latMin.text || "0")
                                let lat_sec_full = parseFloat(latSec.text || "0") + parseFloat("0." + (latSecDec.text || "0"))
                                let lon_deg = parseInt(lonDeg.text)
                                let lon_min = parseInt(lonMin.text || "0")
                                let lon_sec_full = parseFloat(lonSec.text || "0") + parseFloat("0." + (lonSecDec.text || "0"))

                                if (isNaN(lat_deg) || isNaN(lon_deg)) {
                                    mainWindow.displayToast(qsTr("Merci d'entrer au moins une valeur pour les degrés (°)."))
                                    return
                                }

                                function dmsToDecimal(deg, min, sec, sens) {
                                    let decimal = deg + (min / 60.0) + (sec / 3600.0)
                                    if (sens === qsTr("S") || sens === qsTr("W")) decimal = -decimal
                                    return decimal
                                }
                                let lat = dmsToDecimal(lat_deg, lat_min, lat_sec_full, latCombo.currentText)
                                let lon = dmsToDecimal(lon_deg, lon_min, lon_sec_full, lonCombo.currentText)

                                var crsIN = CoordinateReferenceSystemUtils.fromDescription("EPSG:4326")
                                var crsOUT = CoordinateReferenceSystemUtils.fromDescription("EPSG:" + canvasEPSG)
                                var pt = GeometryUtils.point(lon, lat)
                                var projected = GeometryUtils.reprojectPoint(pt, crsIN, crsOUT)

                                let navigation = iface.findItemByObjectName('navigation');
                                if (navigation) {
                                    navigation.destination = projected
                                    mainWindow.displayToast(qsTr("Destination définie selon les coordonnées DMS entrées."));
                                } else {
                                    mainWindow.displayToast(qsTr("Navigation non disponible. Vérifier que la position est activée sur votre appareil."));
                                }
                                plugin.showPanel = false
                            }
                        }
                        Button {
                            text: qsTr("Effacer")
                            Layout.fillWidth: true
                            onClicked: {
                                latDeg.text = ""
                                latMin.text = ""
                                latSec.text = ""
                                latSecDec.text = ""
                                lonDeg.text = ""
                                lonMin.text = ""
                                lonSec.text = ""
                                lonSecDec.text = ""
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Button {
                            text: qsTr("Quitter")
                            Layout.alignment: Qt.AlignRight
                            onClicked: plugin.showPanel = false
                        }
                    }
                }
            }

            // DDM → Destination
            Item {
                visible: plugin.tabIndex === 2
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 0
                    anchors.rightMargin: 0
                    spacing: 8

                    Label {
                        text: qsTr("Transformer des coordonnées DDM en destination")
                        font.bold: true
                        Layout.alignment: Qt.AlignLeft
                    }

                    GridLayout {
                        columns: 7
                        rowSpacing: 6
                        columnSpacing: 6

                        // Latitude
                        Label { text: qsTr("Latitude"); Layout.row: 0; Layout.column: 0; Layout.alignment: Qt.AlignLeft }
                        ComboBox { id: ddmLatCombo; model: [qsTr("N"), qsTr("S")]; Layout.preferredWidth: 60; Layout.row: 0; Layout.column: 1 }
                        TextField {
                            id: ddmLatDeg
                            placeholderText: qsTr("°")
                            Layout.preferredWidth: 40
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 0; Layout.column: 2
                            validator: IntValidator { bottom: 0; top: 90 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            onTextChanged: if (text.length === 2) ddmLatMin.forceActiveFocus()
                            Keys.onReturnPressed: ddmLatMin.forceActiveFocus()
                        }
                        TextField {
                            id: ddmLatMin
                            placeholderText: ""
                            Layout.preferredWidth: 40
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 0; Layout.column: 3
                            validator: IntValidator { bottom: 0; top: 59 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            onTextChanged: if (text.length === 2) ddmLatDec.forceActiveFocus()
                            Keys.onReturnPressed: ddmLatDec.forceActiveFocus()
                        }
                        Label { text: qsTr("."); font.pixelSize: 18; verticalAlignment: Text.AlignVCenter; Layout.row: 0; Layout.column: 4 }
                        TextField {
                            id: ddmLatDec
                            placeholderText: ""
                            Layout.preferredWidth: 65
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 0; Layout.column: 5
                            validator: IntValidator { bottom: 0; top: 999 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            Keys.onReturnPressed: ddmLonDeg.forceActiveFocus()
                        }
                        // Longitude
                        Label { text: qsTr("Longitude"); Layout.row: 1; Layout.column: 0; Layout.alignment: Qt.AlignLeft }
                        ComboBox { id: ddmLonCombo; model: [qsTr("E"), qsTr("W")]; Layout.preferredWidth: 60; Layout.row: 1; Layout.column: 1 }
                        TextField {
                            id: ddmLonDeg
                            placeholderText: qsTr("°")
                            Layout.preferredWidth: 40
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 1; Layout.column: 2
                            validator: IntValidator { bottom: 0; top: 180 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            onTextChanged: if (text.length === 2) ddmLonMin.forceActiveFocus()
                            Keys.onReturnPressed: ddmLonMin.forceActiveFocus()
                        }
                        TextField {
                            id: ddmLonMin
                            placeholderText: ""
                            Layout.preferredWidth: 40
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 1; Layout.column: 3
                            validator: IntValidator { bottom: 0; top: 59 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            onTextChanged: if (text.length === 2) ddmLonDec.forceActiveFocus()
                            Keys.onReturnPressed: ddmLonDec.forceActiveFocus()
                        }
                        Label { text: qsTr("."); font.pixelSize: 18; verticalAlignment: Text.AlignVCenter; Layout.row: 1; Layout.column: 4 }
                        TextField {
                            id: ddmLonDec
                            placeholderText: ""
                            Layout.preferredWidth: 65
                            inputMethodHints: Qt.ImhDigitsOnly
                            Layout.row: 1; Layout.column: 5
                            validator: IntValidator { bottom: 0; top: 999 }
                            property bool isError: !acceptableInput && text.length > 0
                            background: Rectangle {
                                color: "white"
                                border.color: parent.isError ? "red" : "#cccccc"
                                border.width: 1
                                radius: 4
                            }
                            Keys.onReturnPressed: ddmLatCombo.forceActiveFocus()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Button {
                            text: qsTr("Définir comme destination")
                            Layout.fillWidth: true
                            enabled:
                                ddmLatDeg.acceptableInput &&
                                ddmLatMin.acceptableInput &&
                                ddmLonDeg.acceptableInput &&
                                ddmLonMin.acceptableInput
                            onClicked: {
                                let lat_deg = parseInt(ddmLatDeg.text)
                                let lat_min = parseInt(ddmLatMin.text || "0")
                                let lat_dec = parseInt(ddmLatDec.text || "0")
                                let lon_deg = parseInt(ddmLonDeg.text)
                                let lon_min = parseInt(ddmLonMin.text || "0")
                                let lon_dec = parseInt(ddmLonDec.text || "0")

                                if (isNaN(lat_deg) || isNaN(lon_deg)) {
                                    mainWindow.displayToast(qsTr("Merci d'entrer au moins une valeur pour les degrés (°)."))
                                    return
                                }

                                function ddmToDecimal(deg, min, dec, sens) {
                                    let minutes = min + (dec / Math.pow(10, dec.toString().length));
                                    let decimal = deg + (minutes / 60.0)
                                    if (sens === qsTr("S") || sens === qsTr("W")) decimal = -decimal
                                    return decimal
                                }
                                let lat = ddmToDecimal(lat_deg, lat_min, lat_dec, ddmLatCombo.currentText)
                                let lon = ddmToDecimal(lon_deg, lon_min, lon_dec, ddmLonCombo.currentText)

                                var crsIN = CoordinateReferenceSystemUtils.fromDescription("EPSG:4326")
                                var crsOUT = CoordinateReferenceSystemUtils.fromDescription("EPSG:" + canvasEPSG)
                                var pt = GeometryUtils.point(lon, lat)
                                var projected = GeometryUtils.reprojectPoint(pt, crsIN, crsOUT)

                                let navigation = iface.findItemByObjectName('navigation');
                                if (navigation) {
                                    navigation.destination = projected
                                    mainWindow.displayToast(qsTr("Destination définie selon les coordonnées DDM entrées."));
                                } else {
                                    mainWindow.displayToast(qsTr("Navigation non disponible. Vérifier que la position est activée sur votre appareil."));
                                }
                                plugin.showPanel = false
                            }
                        }
                        Button {
                            text: qsTr("Effacer")
                            Layout.fillWidth: true
                            onClicked: {
                                ddmLatDeg.text = ""
                                ddmLatMin.text = ""
                                ddmLatDec.text = ""
                                ddmLonDeg.text = ""
                                ddmLonMin.text = ""
                                ddmLonDec.text = ""
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Button {
                            text: qsTr("Quitter")
                            Layout.alignment: Qt.AlignRight
                            onClicked: plugin.showPanel = false
                        }
                    }
                }
            }

            // Lambert93 → DMS
            Item {
                visible: plugin.tabIndex === 1
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 0
                    anchors.rightMargin: 0
                    spacing: 8

                    Label {
                        text: qsTr("Coller des coordonnées Lambert-93")
                        font.bold: true
                        Layout.alignment: Qt.AlignLeft
                    }

                    TextField {
                        id: lambertInput
                        placeholderText: qsTr("Ex. : 554554,188, 6478746,743 – EPSG:2154: RGF93 v1 / Lambert-93")
                        Layout.fillWidth: true
                        onEditingFinished: lambertToDMS()
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Button {
                            text: qsTr("Convertir en DMS")
                            Layout.fillWidth: true
                            onClicked: lambertToDMS()
                        }
                        Button {
                            text: qsTr("Effacer")
                            Layout.fillWidth: true
                            onClicked: {
                                lambertInput.text = "";
                                dmsResult.text = "";
                            }
                        }
                    }
                    Label {
                        id: dmsResult
                        text: ""
                        font.pixelSize: 15
                        wrapMode: Text.Wrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Button {
                            text: qsTr("Copier les coordonnées obtenues")
                            Layout.fillWidth: true
                            enabled: dmsResult.text !== ""
                            onClicked: {
                                let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
                                textEdit.text = dmsResult.text;
                                textEdit.selectAll();
                                textEdit.copy();
                                textEdit.destroy();
                                mainWindow.displayToast(qsTr("Coordonnées DMS copiées dans le presse-papier."));
                            }
                        }
                        Button {
                            text: qsTr("Quitter")
                            Layout.alignment: Qt.AlignRight
                            onClicked: plugin.showPanel = false
                        }
                    }
                }
            }

            // Lambert93 → DDM
            Item {
                visible: plugin.tabIndex === 3
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 0
                    anchors.rightMargin: 0
                    spacing: 8

                    Label {
                        text: qsTr("Coller des coordonnées Lambert-93")
                        font.bold: true
                        Layout.alignment: Qt.AlignLeft
                    }

                    TextField {
                        id: lambertInputDDM
                        placeholderText: qsTr("Ex. : 554554,188, 6478746,743 – EPSG:2154: RGF93 v1 / Lambert-93")
                        Layout.fillWidth: true
                        onEditingFinished: lambertToDDM()
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Button {
                            text: qsTr("Convertir en DDM")
                            Layout.fillWidth: true
                            onClicked: lambertToDDM()
                        }
                        Button {
                            text: qsTr("Effacer")
                            Layout.fillWidth: true
                            onClicked: {
                                lambertInputDDM.text = "";
                                ddmResult.text = "";
                            }
                        }
                    }
                    Label {
                        id: ddmResult
                        text: ""
                        font.pixelSize: 15
                        wrapMode: Text.Wrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Button {
                            text: qsTr("Copier les coordonnées obtenues")
                            Layout.fillWidth: true
                            enabled: ddmResult.text !== ""
                            onClicked: {
                                let textEdit = Qt.createQmlObject('import QtQuick; TextEdit { }', plugin);
                                textEdit.text = ddmResult.text;
                                textEdit.selectAll();
                                textEdit.copy();
                                textEdit.destroy();
                                mainWindow.displayToast(qsTr("Coordonnées DDM copiées dans le presse-papier."));
                            }
                        }
                        Button {
                            text: qsTr("Quitter")
                            Layout.alignment: Qt.AlignRight
                            onClicked: plugin.showPanel = false
                        }
                    }
                }
            }
        }
    }

    // Function to transform Lambert93 → DMS
    function lambertToDMS() {
        var input = lambertInput.text.trim();
        var match = input.match(/^([0-9.]+)[ ,;]+([0-9.]+)/);
        if (!match) {
            dmsResult.text = qsTr("Format de coordonnées Lambert 93 invalide.");
            return;
        }
        var x = parseFloat(match[1]);
        var y = parseFloat(match[2]);
        if (isNaN(x) || isNaN(y)) {
            dmsResult.text = qsTr("Coordonnées invalides");
            return;
        }

        var crsIN = CoordinateReferenceSystemUtils.fromDescription("EPSG:2154");
        var crsOUT = CoordinateReferenceSystemUtils.fromDescription("EPSG:4326");
        var point = GeometryUtils.point(x, y);
        var lonlat = GeometryUtils.reprojectPoint(point, crsIN, crsOUT);

        function toDMS(coord, isLat) {
            var abs = Math.abs(coord);
            var deg = Math.floor(abs);
            var min = Math.floor((abs - deg) * 60);
            var sec = ((abs - deg) * 60 - min) * 60;
            var dir = isLat
                ? (coord >= 0 ? qsTr("N") : qsTr("S"))
                : (coord >= 0 ? qsTr("E") : qsTr("W"));
            return deg + "° " + min + "' " + sec.toFixed(2) + "\" " + dir;
        }
        var dmsLat = toDMS(lonlat.y, true);
        var dmsLon = toDMS(lonlat.x, false);

        dmsResult.text = qsTr("Latitude") + " : " + dmsLat + "\n" + qsTr("Longitude") + " : " + dmsLon;
    }

    // Function to transform Lambert93 → DDM
    function lambertToDDM() {
        var input = lambertInputDDM.text.trim();
        var match = input.match(/^([0-9.]+)[ ,;]+([0-9.]+)/);
        if (!match) {
            ddmResult.text = qsTr("Format de coordonnées Lambert 93 invalide.");
            return;
        }
        var x = parseFloat(match[1]);
        var y = parseFloat(match[2]);
        if (isNaN(x) || isNaN(y)) {
            ddmResult.text = qsTr("Coordonnées invalides");
            return;
        }

        var crsIN = CoordinateReferenceSystemUtils.fromDescription("EPSG:2154");
        var crsOUT = CoordinateReferenceSystemUtils.fromDescription("EPSG:4326");
        var point = GeometryUtils.point(x, y);
        var lonlat = GeometryUtils.reprojectPoint(point, crsIN, crsOUT);

        function toDDM(coord, isLat) {
            var abs = Math.abs(coord);
            var deg = Math.floor(abs);
            var minDec = (abs - deg) * 60;
            var dir = isLat
                ? (coord >= 0 ? qsTr("N") : qsTr("S"))
                : (coord >= 0 ? qsTr("E") : qsTr("W"));
            return dir + " " + deg + "°" + minDec.toFixed(3) + "'";
        }
        var ddmLat = toDDM(lonlat.y, true);
        var ddmLon = toDDM(lonlat.x, false);

        ddmResult.text = qsTr("Latitude") + " : " + ddmLat + "\n" + qsTr("Longitude") + " : " + ddmLon;
    }
}
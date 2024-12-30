/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Vehicle
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.SettingsManager

Control {
    id:         control
    topPadding: _majorTickSize

    property real   from:           0
    property real   to:             100
    property real   stepSize:       10
    property string unitsString
    property int    decimalPlaces:  1

    property string _displayText:           ""

    property var    _unitsSettings:         QGroundControl.settingsManager.unitsSettings
    property real   _indicatorCenterPos:    sliderFlickable.width / 2

    property real   _majorTickSize:         ScreenTools.defaultFontPixelHeight
    property real   _majorTickSpacing:      ScreenTools.defaultFontPixelWidth * 4
    property real   _tickValueEdgeMargin:   ScreenTools.defaultFontPixelWidth / 2
    property real   _minorTickSize:        _majorTickSize / 2
    property real   _sliderValuePerPixel:   stepSize / _majorTickSpacing

    property int    _minorTickValueStep:    stepSize / 2

    property real   _sliderValue:           _firstPixelValue - ((sliderFlickable.contentY + _indicatorCenterPos) * _sliderValuePerPixel)

    // Calculate the full range of the slider. We have been given a min/max but that is for clamping the selected slider values.
    // We need expand that range to take into account additional values that must be displayed above/below the value indicator
    // when it is at min/max.

    // Add additional major ticks above/below min/max to ensure we can display the full visual range of the slider
    property int    _majorTicksVisibleAboveIndicator:   Math.floor(_indicatorCenterPos / _majorTickSpacing)
    property int    _majorTickAdjustment:               _majorTicksVisibleAboveIndicator * stepSize

    // Calculate the next major tick above/below min/max
    property int    _majorTickMaxValue:     Math.ceil((to + _majorTickAdjustment)/ stepSize) * stepSize 
    property int    _majorTickMinValue:     Math.floor((from - _majorTickAdjustment)/ stepSize) * stepSize

    // Now calculate the position we draw the first tick mark such that we are not allowed to flick above the max value
    property real   _firstTickPixelOffset:  _indicatorCenterPos - ((_majorTickMaxValue - to) / _sliderValuePerPixel)
    property real   _firstPixelValue:       _majorTickMaxValue + (_firstTickPixelOffset * _sliderValuePerPixel)

    // Calculate the slider height such that we can flick below the min value
    property real   _sliderContentSize:          (_firstPixelValue - from) / _sliderValuePerPixel + (sliderFlickable.height - _indicatorCenterPos)

    property int     _cMajorTicks:          (_majorTickMaxValue - _majorTickMinValue) / stepSize + 1

    property var qgcPal: QGroundControl.globalPalette

    Component.onCompleted: {
        //setCurrentValue(0, false)
    }

    function setCurrentValue(currentValue, animate = true) {
        // Position the slider such that the indicator is pointing to the current value
        var contentY = (_firstPixelValue - currentValue) / _sliderValuePerPixel - _indicatorCenterPos
        if (animate) {
            flickableAnimation.from = sliderFlickable.contentY
            flickableAnimation.to = contentY
            flickableAnimation.start()
        } else {
            sliderFlickable.contentY = contentY
        }
    }

    function _clampedSliderValue(value) {
        return Math.min(Math.max(value.toFixed(decimalPlaces), from), to)
    }

    function getOutputValue() {
        return _clampedSliderValue(_sliderValue)
    }

    QGCPalette {
        id:                 qgcPal
        colorGroupEnabled:  control.enabled
    }

    DeadMouseArea {
        anchors.fill: parent
    }

    background: Rectangle {
        implicitHeight: _majorTickSize + tickValueMargin + ScreenTools.defaultFontPixelHeight
        color:          qgcPal.window

        property real tickValueMargin: ScreenTools.defaultFontPixelHeight / 3

        Component.onCompleted: console.log("Background: ", width, height, implicitHeight)

        QGCFlickable {
            id:                 sliderFlickable
            anchors.fill:       parent
            contentWidth:       sliderContainer.width
            contentHeight:      sliderContainer.height
            flickDeceleration:  0.5
            flickableDirection: Flickable.HorizontalFlick

            Component.onCompleted: console.log("Flickable: ", width, height, contentWidth, contentHeight)

            Item {
                id:     sliderContainer
                width:  _sliderContentSize
                height: sliderFlickable.height

                Component.onCompleted: console.log("Slider container: ", width, height)

                // Major tick marks
                Repeater {
                    model: _cMajorTicks

                    Item {
                        width:      1
                        height:     sliderContainer.height
                        x:          _majorTickSpacing * index + _firstTickPixelOffset
                        opacity:    tickValue < from || tickValue > to ? 0.5 : 1

                        Component.onCompleted: console.log("Major tick: ", tickValue, x, y, width, height, _majorTickSize)

                        property real tickValue: _majorTickMinValue + (stepSize * index)

                        Rectangle {
                            id:     majorTickMark
                            width:  1
                            height: _majorTickSize
                            color:  qgcPal.text
                        }

                        QGCLabel {
                            anchors.bottomMargin:       _tickValueEdgeMargin
                            anchors.bottom:             parent.bottom
                            anchors.horizontalCenter:   majorTickMark.horizontalCenter
                            text:                       parent.tickValue
                        }
                    }
                }

                // Minor tick marks
                Repeater {
                    model: _cMajorTicks * 2

                    Rectangle {
                        x:          _majorTickSpacing / 2 * index +  + _firstTickPixelOffset
                        width:      1
                        height:     _minorTickSize
                        color:      qgcPal.text
                        opacity:    tickValue < from || tickValue > to ? 0.5 : 1
                        visible:    index % 2 === 1

                        property real tickValue: _majorTickMaxValue - ((stepSize  / 2) * index)
                    }
                }
            }
        }
    }

    contentItem: Item {
        implicitHeight: valueIndicator.height

        Canvas {
            id:                         valueIndicator
            anchors.horizontalCenter:   parent.horizontalCenter
            width:                      valueLabel.contentWidth + (indicatorValueMargins * 2)
            height:                     valueLabel.contentHeight + (indicatorValueMargins * 2) + pointerSize

            property real indicatorValueMargins:    ScreenTools.defaultFontPixelWidth / 2
            property real indicatorHeight:          valueLabel.contentHeight
            property real pointerSize:            ScreenTools.defaultFontPixelWidth

            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = qgcPal.text
                ctx.fillStyle = qgcPal.window
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.moveTo(width / 2, 0)
                ctx.lineTo(width / 2 + pointerSize, pointerSize)
                ctx.lineTo(width - 1, pointerSize)
                ctx.lineTo(width - 1, height - 1)
                ctx.lineTo(1, height - 1)
                ctx.lineTo(1, pointerSize)
                ctx.lineTo(width / 2 - pointerSize, pointerSize)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
            }

            QGCLabel {
                id:                         valueLabel
                anchors.bottomMargin:       parent.indicatorValueMargins
                anchors.bottom:             parent.bottom
                anchors.horizontalCenter:   parent.horizontalCenter
                horizontalAlignment:        Text.AlignHCenter
                verticalAlignment:          Text.AlignBottom
                text:                       _clampedSliderValue(_sliderValue) + (unitsString !== "" ? " " + unitsString : "")
            }
        }
    }
}

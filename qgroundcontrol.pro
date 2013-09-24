# -------------------------------------------------
# QGroundControl - Micro Air Vehicle Groundstation
# Please see our website at <http://qgroundcontrol.org>
# Maintainer:
# Lorenz Meier <lm@inf.ethz.ch>
# (c) 2009-2011 QGroundControl Developers
# This file is part of the open groundstation project
# QGroundControl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# QGroundControl is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with QGroundControl. If not, see <http://www.gnu.org/licenses/>.
# -------------------------------------------------


# Qt configuration
CONFIG += qt \
    thread

QT += network \
    opengl \
    svg \
    xml \
    webkit \
    sql \
    declarative

greaterThan(QT_MAJOR_VERSION, 4) {
    QT +=  multimedia
} else {
    QT += phonon
}

TEMPLATE = app
TARGET = apmplanner2
BASEDIR = $${IN_PWD}
linux-g++|linux-g++-64{
    debug {
        TARGETDIR = $${OUT_PWD}/debug
        BUILDDIR = $${OUT_PWD}/build-debug
    }
    release {
        TARGETDIR = $${OUT_PWD}/release
        BUILDDIR = $${OUT_PWD}/build-release
    }
} else {
    TARGETDIR = $${OUT_PWD}
    BUILDDIR = $${OUT_PWD}/build
}
win32-x-g++|win64-x-g++ {
    CONFIG += exceptions rtti
    DEFINES += UINT8_MAX=0xFF
    DEFINES += UINT16_MAX=0xFFFF
    DEFINES += INT32_MIN=0x80000000
    DEFINES += INT32_MAX=0x7FFFFFFF
    DEFINES += UINT32_MAX=0xFFFFFFFF
    DEFINES += GIT_COMMIT=$$system(git describe --dirty=-DEV --always)
    DEFINES += GIT_HASH=$$system(git log -n 1 --pretty=format:%H)
} else:win32 {
    DEFINES += GIT_COMMIT=$$system(\"c:/program files (x86)/git/bin/git.exe\" describe --dirty=-DEV --always)
    DEFINES += GIT_HASH=$$system(\"c:/program files (x86)/git/bin/git.exe\" log -n 1 --pretty=format:%H)
    QMAKE_INCDIR_QT = $$(QTDIR)/include
    QMAKE_LIBDIR_QT = $$(QTDIR)/lib
    QMAKE_UIC = "$$(QTDIR)/bin/uic.exe"
    QMAKE_MOC = "$$(QTDIR)/bin/moc.exe"
    QMAKE_RCC = "$$(QTDIR)/bin/rcc.exe"
    QMAKE_QMAKE = "$$(QTDIR)/bin/qmake.exe"

	# Build QAX for GoogleEarth API access
	!exists( $(QTDIR)/src/activeqt/Makefile ) {
		message( Making QAx (ONE TIME) )
		system( cd $$(QTDIR)\\src\\activeqt && $$(QTDIR)\\bin\\qmake.exe )
		system( cd $$(QTDIR)\\src\\activeqt\\container && $$(QTDIR)\\bin\\qmake.exe )
		system( cd $$(QTDIR)\\src\\activeqt\\control && $$(QTDIR)\\bin\\qmake.exe )
		system( cd $$(QTDIR)\\src\\activeqt && nmake )
	}
}
unix {
        DEFINES += GIT_COMMIT=$$system(git describe --dirty=-DEV --always)
        DEFINES += GIT_HASH=$$system(git log -n 1 --pretty=format:%H)
}
include (QsLog/QsLog.pri)

LANGUAGE = C++
OBJECTS_DIR = $${BUILDDIR}/obj
MOC_DIR = $${BUILDDIR}/moc
UI_DIR = $${BUILDDIR}/ui
RCC_DIR = $${BUILDDIR}/rcc
MAVLINK_CONF = ""
MAVLINKPATH = $$BASEDIR/libs/mavlink/include/mavlink/v1.0
DEFINES += MAVLINK_NO_DATA




#################################################################
# EXTERNAL LIBRARY CONFIGURATION

# AGLLIB math library
INCLUDEPATH += libs/alglib/src
HEADERS +=     libs/alglib/src/ap.h \
    libs/alglib/src/alglibinternal.h\
    libs/alglib/src/interpolation.h \
    libs/alglib/src/optimization.h \
    libs/alglib/src/linalg.h \
    libs/alglib/src/alglibmisc.h \
    libs/alglib/src/diffequations.h \
    libs/alglib/src/integration.h \
    libs/alglib/src/solvers.h \
    libs/alglib/src/specialfunctions.cpp

SOURCES +=     libs/alglib/src/ap.cpp \
    libs/alglib/src/alglibinternal.cpp \
    libs/alglib/src/interpolation.cpp \
    libs/alglib/src/optimization.cpp \
    libs/alglib/src/linalg.cpp \
    libs/alglib/src/alglibmisc.cpp \
    libs/alglib/src/diffequations.cpp \
    libs/alglib/src/integration.cpp \
    libs/alglib/src/solvers.cpp \
    libs/alglib/src/specialfunctions.cpp

# EIGEN matrix library (header-only)
INCLUDEPATH += libs/eigen

# OPMapControl library (from OpenPilot)
include(libs/utils/utils_external.pri)
include(libs/opmapcontrol/opmapcontrol_external.pri)
DEPENDPATH += \
    libs/utils \
    libs/utils/src \
    libs/opmapcontrol \
    libs/opmapcontrol/src \
    libs/opmapcontrol/src/mapwidget

INCLUDEPATH += \
    libs/utils \
    libs \
    libs/opmapcontrol \

# If the user config file exists, it will be included.
# if the variable MAVLINK_CONF contains the name of an
# additional project, QGroundControl includes the support
# of custom MAVLink messages of this project. It will also
# create a QGC_USE_{AUTOPILOT_NAME}_MESSAGES macro for use
# within the actual code.
exists(user_config.pri) { 
    include(user_config.pri)
    message("----- USING CUSTOM USER QGROUNDCONTROL CONFIG FROM user_config.pri -----")
    message("Adding support for additional MAVLink messages for: " $$MAVLINK_CONF)
    message("------------------------------------------------------------------------")
} else {
    MAVLINK_CONF += ardupilotmega
}
INCLUDEPATH += $$MAVLINKPATH
isEmpty(MAVLINK_CONF) { 
    INCLUDEPATH += $$MAVLINKPATH/common
} else {
    INCLUDEPATH += $$MAVLINKPATH/$$MAVLINK_CONF
    #DEFINES += 'MAVLINK_CONF="$${MAVLINK_CONF}.h"'
    DEFINES += $$sprintf('QGC_USE_%1_MESSAGES', $$upper($$MAVLINK_CONF))
}

# Include general settings for QGroundControl
# necessary as last include to override any non-acceptable settings
# done by the plugins above
include(qgroundcontrol.pri)

# Include MAVLink generator
# has been deprecated
DEPENDPATH += \
    src/apps/mavlinkgen

INCLUDEPATH += \
    src/apps/mavlinkgen \
    src/apps/mavlinkgen/ui \
    src/apps/mavlinkgen/generator

include(src/apps/mavlinkgen/mavlinkgen.pri)

# Include QWT plotting library
include(libs/qwt/qwt.pri)

DEPENDPATH += . \
    plugins

INCLUDEPATH += .

greaterThan(QT_MAJOR_VERSION, 4) {
# Include serial port library (QSerialPort)
    QT += serialport
} else {
    include(libs/serialport/apmserial.pri)
}


## Serial port detection (ripped-off from qextserialport library)
#macx|macx-g++|macx-g++42::SOURCES += libs/qextserialport/qextserialenumerator_osx.cpp
#linux-g++::SOURCES += libs/qextserialport/qextserialenumerator_unix.cpp
#linux-g++-64::SOURCES += libs/qextserialport/qextserialenumerator_unix.cpp
#win32-msvc2008|win32-msvc2010|win32-msvc2012::SOURCES += libs/qextserialport/qextserialenumerator_win.cpp

# Input
FORMS += src/ui/MainWindow.ui \
    src/ui/CommSettings.ui \
    src/ui/SerialSettings.ui \
    src/ui/UASControl.ui \
    src/ui/UASList.ui \
    src/ui/UASInfo.ui \
    src/ui/Linechart.ui \
    src/ui/UASView.ui \
    src/ui/ParameterInterface.ui \
    src/ui/WaypointList.ui \    
    src/ui/ObjectDetectionView.ui \
    src/ui/JoystickWidget.ui \
    src/ui/DebugConsole.ui \
    src/ui/HDDisplay.ui \
    src/ui/MAVLinkSettingsWidget.ui \
    src/ui/AudioOutputWidget.ui \
    src/ui/QGCSensorSettingsWidget.ui \
    src/ui/watchdog/WatchdogControl.ui \
    src/ui/watchdog/WatchdogProcessView.ui \
    src/ui/watchdog/WatchdogView.ui \
    src/ui/QGCFirmwareUpdate.ui \
    src/ui/QGCPxImuFirmwareUpdate.ui \
    src/ui/QGCDataPlot2D.ui \
    src/ui/QGCRemoteControlView.ui \
    src/ui/QMap3D.ui \
    src/ui/QGCWebView.ui \
    src/ui/map3D/QGCGoogleEarthView.ui \
    src/ui/SlugsDataSensorView.ui \
    src/ui/SlugsHilSim.ui \
    src/ui/SlugsPadCameraControl.ui \
    src/ui/uas/QGCUnconnectedInfoWidget.ui \
    src/ui/designer/QGCToolWidget.ui \
    src/ui/designer/QGCParamSlider.ui \
    src/ui/designer/QGCActionButton.ui \
    src/ui/designer/QGCCommandButton.ui \
    src/ui/QGCMAVLinkLogPlayer.ui \
    src/ui/QGCWaypointListMulti.ui \
    src/ui/QGCUDPLinkConfiguration.ui \
    src/ui/QGCSettingsWidget.ui \
    src/ui/UASControlParameters.ui \
    src/ui/map/QGCMapTool.ui \
    src/ui/map/QGCMapToolBar.ui \
    src/ui/QGCMAVLinkInspector.ui \
    src/ui/WaypointViewOnlyView.ui \    
    src/ui/WaypointEditableView.ui \    
    src/ui/UnconnectedUASInfoWidget.ui \
    src/ui/mavlink/QGCMAVLinkMessageSender.ui \
    src/ui/firmwareupdate/QGCFirmwareUpdateWidget.ui \
    src/ui/QGCPluginHost.ui \
    src/ui/firmwareupdate/QGCPX4FirmwareUpdate.ui \
    src/ui/mission/QGCMissionOther.ui \
    src/ui/mission/QGCMissionNavWaypoint.ui \
    src/ui/mission/QGCMissionDoJump.ui \
    src/ui/mission/QGCMissionConditionDelay.ui \
    src/ui/mission/QGCMissionNavLoiterUnlim.ui \
    src/ui/mission/QGCMissionNavLoiterTurns.ui \
    src/ui/mission/QGCMissionNavLoiterTime.ui \
    src/ui/mission/QGCMissionNavReturnToLaunch.ui \
    src/ui/mission/QGCMissionNavLand.ui \
    src/ui/mission/QGCMissionNavTakeoff.ui \
    src/ui/mission/QGCMissionNavSweep.ui \
    src/ui/mission/QGCMissionDoStartSearch.ui \
    src/ui/mission/QGCMissionDoFinishSearch.ui \
    src/ui/QGCVehicleConfig.ui \
    src/ui/QGCHilConfiguration.ui \
    src/ui/QGCHilFlightGearConfiguration.ui \
    src/ui/QGCHilJSBSimConfiguration.ui \
    src/ui/QGCHilXPlaneConfiguration.ui \
    src/ui/designer/QGCComboBox.ui \
    src/ui/designer/QGCTextLabel.ui \
    src/ui/uas/UASQuickView.ui \
    src/ui/uas/UASQuickViewItemSelect.ui \
    src/ui/uas/UASActionsWidget.ui \
    src/ui/QGCTabbedInfoView.ui \
    src/ui/UASRawStatusView.ui \
    src/ui/uas/QGCMessageView.ui \
    src/ui/configuration/ApmHardwareConfig.ui \
    src/ui/configuration/ApmSoftwareConfig.ui \
    src/ui/configuration/FrameTypeConfig.ui \
    src/ui/configuration/CompassConfig.ui \
    src/ui/configuration/AccelCalibrationConfig.ui \
    src/ui/configuration/RadioCalibrationConfig.ui \
    src/ui/configuration/FlightModeConfig.ui \
    src/ui/configuration/Radio3DRConfig.ui \
    src/ui/configuration/BatteryMonitorConfig.ui \
    src/ui/configuration/SonarConfig.ui \
    src/ui/configuration/AirspeedConfig.ui \
    src/ui/configuration/OpticalFlowConfig.ui \
    src/ui/configuration/OsdConfig.ui \
    src/ui/configuration/AntennaTrackerConfig.ui \
    src/ui/configuration/CameraGimbalConfig.ui \
    src/ui/configuration/BasicPidConfig.ui \
    src/ui/configuration/StandardParamConfig.ui \
    src/ui/configuration/GeoFenceConfig.ui \
    src/ui/configuration/FailSafeConfig.ui \
    src/ui/configuration/AdvancedParamConfig.ui \
    src/ui/configuration/ArduCopterPidConfig.ui \
    src/ui/configuration/ApmPlaneLevel.ui \
    src/ui/configuration/ParamWidget.ui \
    src/ui/configuration/ArduPlanePidConfig.ui \
    src/ui/configuration/AdvParameterList.ui \
    src/ui/configuration/ArduRoverPidConfig.ui \
    src/ui/configuration/terminalconsole.ui \
    src/ui/configuration/SerialSettingsDialog.ui \
    src/ui/configuration/ApmFirmwareConfig.ui \
    src/ui/DebugOutput.ui

INCLUDEPATH += src \
    src/ui \
    src/ui/linechart \
    src/ui/uas \
    src/ui/map \
    src/uas \
    src/comm \
    include/ui \
    src/input \
    src/lib/qmapcontrol \
    src/ui/mavlink \
    src/ui/param \
    src/ui/watchdog \
    src/ui/map3D \
    src/ui/mission \
    src/ui/designer \
    src/ui/configuration
HEADERS += src/MG.h \
    src/QGCCore.h \
    src/uas/UASInterface.h \
    src/uas/UAS.h \
    src/uas/UASManager.h \
    src/comm/LinkManager.h \
    src/comm/LinkInterface.h \
    src/comm/SerialLinkInterface.h \
    src/comm/SerialLink.h \
    src/comm/ProtocolInterface.h \
    src/comm/MAVLinkProtocol.h \
    src/comm/QGCFlightGearLink.h \
    src/comm/QGCJSBSimLink.h \
    src/comm/QGCXPlaneLink.h \
    src/ui/CommConfigurationWindow.h \
    src/ui/SerialConfigurationWindow.h \
    src/ui/MainWindow.h \
    src/ui/uas/UASControlWidget.h \
    src/ui/uas/UASListWidget.h \
    src/ui/uas/UASInfoWidget.h \
    src/ui/HUD.h \
    src/ui/linechart/LinechartWidget.h \
    src/ui/linechart/LinechartPlot.h \
    src/ui/linechart/Scrollbar.h \
    src/ui/linechart/ScrollZoomer.h \
    src/configuration.h \
    src/ui/uas/UASView.h \
    src/ui/CameraView.h \
    src/comm/MAVLinkSimulationLink.h \
    src/comm/UDPLink.h \
    src/ui/ParameterInterface.h \
    src/ui/WaypointList.h \
    src/Waypoint.h \   
    src/ui/ObjectDetectionView.h \
    src/input/JoystickInput.h \
    src/ui/JoystickWidget.h \
    src/ui/DebugConsole.h \
    src/ui/HDDisplay.h \
    src/ui/MAVLinkSettingsWidget.h \
    src/ui/AudioOutputWidget.h \
    src/GAudioOutput.h \
    src/LogCompressor.h \
    src/ui/QGCParamWidget.h \
    src/ui/QGCSensorSettingsWidget.h \
    src/ui/linechart/Linecharts.h \
    src/uas/SlugsMAV.h \
    src/uas/PxQuadMAV.h \
    src/uas/ArduPilotMegaMAV.h \
    src/uas/senseSoarMAV.h \
    src/ui/watchdog/WatchdogControl.h \
    src/ui/watchdog/WatchdogProcessView.h \
    src/ui/watchdog/WatchdogView.h \
    src/uas/UASWaypointManager.h \
    src/ui/HSIDisplay.h \
    src/QGC.h \
    src/ui/QGCFirmwareUpdate.h \
    src/ui/QGCPxImuFirmwareUpdate.h \
    src/ui/QGCDataPlot2D.h \
    src/ui/linechart/IncrementalPlot.h \
    src/ui/QGCRemoteControlView.h \
    src/ui/RadioCalibration/RadioCalibrationData.h \
    src/ui/RadioCalibration/RadioCalibrationWindow.h \
    src/ui/RadioCalibration/AirfoilServoCalibrator.h \
    src/ui/RadioCalibration/SwitchCalibrator.h \
    src/ui/RadioCalibration/CurveCalibrator.h \
    src/ui/RadioCalibration/AbstractCalibrator.h \
    src/comm/QGCMAVLink.h \
    src/ui/QGCWebView.h \
    src/ui/map3D/QGCWebPage.h \
    src/ui/SlugsDataSensorView.h \
    src/ui/SlugsHilSim.h \
    src/ui/SlugsPadCameraControl.h \
    src/ui/QGCMainWindowAPConfigurator.h \
    src/comm/MAVLinkSwarmSimulationLink.h \
    src/ui/uas/QGCUnconnectedInfoWidget.h \
    src/ui/designer/QGCToolWidget.h \
    src/ui/designer/QGCParamSlider.h \
    src/ui/designer/QGCCommandButton.h \
    src/ui/designer/QGCToolWidgetItem.h \
    src/ui/QGCMAVLinkLogPlayer.h \
    src/comm/MAVLinkSimulationWaypointPlanner.h \
    src/comm/MAVLinkSimulationMAV.h \
    src/uas/QGCMAVLinkUASFactory.h \
    src/ui/QGCWaypointListMulti.h \
    src/ui/QGCUDPLinkConfiguration.h \
    src/ui/QGCSettingsWidget.h \
    src/ui/uas/UASControlParameters.h \
    src/uas/QGCUASParamManager.h \
    src/ui/map/QGCMapWidget.h \
    src/ui/map/MAV2DIcon.h \
    src/ui/map/Waypoint2DIcon.h \
    src/ui/map/QGCMapTool.h \
    src/ui/map/QGCMapToolBar.h \
    src/QGCGeo.h \
    src/ui/QGCToolBar.h \
    src/ui/QGCStatusBar.h \
    src/ui/QGCMAVLinkInspector.h \
    src/ui/MAVLinkDecoder.h \
    src/ui/WaypointViewOnlyView.h \
    src/ui/WaypointEditableView.h \    
    src/ui/UnconnectedUASInfoWidget.h \
    src/ui/QGCRGBDView.h \
    src/ui/mavlink/QGCMAVLinkMessageSender.h \
    src/ui/firmwareupdate/QGCFirmwareUpdateWidget.h \
    src/ui/QGCPluginHost.h \
    src/ui/firmwareupdate/QGCPX4FirmwareUpdate.h \
    src/ui/mission/QGCMissionOther.h \
    src/ui/mission/QGCMissionNavWaypoint.h \
    src/ui/mission/QGCMissionDoJump.h \
    src/ui/mission/QGCMissionConditionDelay.h \
    src/ui/mission/QGCMissionNavLoiterUnlim.h \
    src/ui/mission/QGCMissionNavLoiterTurns.h \
    src/ui/mission/QGCMissionNavLoiterTime.h \
    src/ui/mission/QGCMissionNavReturnToLaunch.h \
    src/ui/mission/QGCMissionNavLand.h \
    src/ui/mission/QGCMissionNavTakeoff.h \
    src/ui/mission/QGCMissionNavSweep.h \
    src/ui/mission/QGCMissionDoStartSearch.h \
    src/ui/mission/QGCMissionDoFinishSearch.h \
    src/ui/QGCVehicleConfig.h \
    src/comm/QGCHilLink.h \
    src/ui/QGCHilConfiguration.h \
    src/ui/QGCHilFlightGearConfiguration.h \
    src/ui/QGCHilJSBSimConfiguration.h \
    src/ui/QGCHilXPlaneConfiguration.h \
    src/ui/designer/QGCComboBox.h \
    src/ui/designer/QGCTextLabel.h \
    src/ui/submainwindow.h \
    src/ui/dockwidgettitlebareventfilter.h \
    src/ui/uas/UASQuickView.h \
    src/ui/uas/UASQuickViewItem.h \
    src/ui/uas/UASQuickViewItemSelect.h \
    src/ui/uas/UASQuickViewTextItem.h \
    src/ui/uas/UASQuickViewGaugeItem.h \
    src/ui/uas/UASActionsWidget.h \
    src/ui/designer/QGCRadioChannelDisplay.h \
    src/ui/QGCTabbedInfoView.h \
    src/ui/UASRawStatusView.h \
    src/ui/PrimaryFlightDisplay.h \
    src/ui/uas/QGCMessageView.h \
    src/ui/configuration/ApmHardwareConfig.h \
    src/ui/configuration/ApmSoftwareConfig.h \
    src/ui/configuration/FrameTypeConfig.h \
    src/ui/configuration/CompassConfig.h \
    src/ui/configuration/AccelCalibrationConfig.h \
    src/ui/configuration/RadioCalibrationConfig.h \
    src/ui/configuration/FlightModeConfig.h \
    src/ui/configuration/Radio3DRConfig.h \
    src/ui/configuration/BatteryMonitorConfig.h \
    src/ui/configuration/SonarConfig.h \
    src/ui/configuration/AirspeedConfig.h \
    src/ui/configuration/OpticalFlowConfig.h \
    src/ui/configuration/OsdConfig.h \
    src/ui/configuration/AntennaTrackerConfig.h \
    src/ui/configuration/CameraGimbalConfig.h \
    src/ui/configuration/AP2ConfigWidget.h \
    src/ui/configuration/BasicPidConfig.h \
    src/ui/configuration/StandardParamConfig.h \
    src/ui/configuration/GeoFenceConfig.h \
    src/ui/configuration/FailSafeConfig.h \
    src/ui/configuration/AdvancedParamConfig.h \
    src/ui/configuration/ArduCopterPidConfig.h \
    src/ui/apmtoolbar.h \
    src/ui/configuration/ApmPlaneLevel.h \
    src/ui/configuration/ParamWidget.h \
    src/ui/configuration/ArduPlanePidConfig.h \
    src/ui/configuration/AdvParameterList.h \
    src/ui/configuration/ArduRoverPidConfig.h \
    src/ui/configuration/console.h \
    src/ui/configuration/SerialSettingsDialog.h \
    src/ui/configuration/terminalconsole.h \
    src/ui/configuration/ApmHighlighter.h \
    src/ui/configuration/ApmFirmwareConfig.h \
    src/ui/designer/QGCMouseWheelEventFilter.h \
    src/ui/DebugOutput.h \
    src/ui/configuration/APDoubleSpinBox.h \
    src/ui/configuration/APSpinBox.h



# Google Earth is only supported on Mac OS and Windows with Visual Studio Compiler
macx|macx-g++|macx-g++42|win32-msvc2008|win32-msvc2010|win32-msvc2012::HEADERS += src/ui/map3D/QGCGoogleEarthView.h
contains(DEPENDENCIES_PRESENT, osg) { 
    message("Including headers for OpenSceneGraph")
    
    # Enable only if OpenSceneGraph is available
    HEADERS += src/ui/map3D/gpl.h \
        src/ui/map3D/CameraParams.h \
        src/ui/map3D/ViewParamWidget.h \
        src/ui/map3D/SystemContainer.h \
        src/ui/map3D/SystemViewParams.h \
        src/ui/map3D/GlobalViewParams.h \
        src/ui/map3D/SystemGroupNode.h \
        src/ui/map3D/Q3DWidget.h \
        src/ui/map3D/GCManipulator.h \
        src/ui/map3D/ImageWindowGeode.h \
        src/ui/map3D/PixhawkCheetahNode.h \
        src/ui/map3D/Pixhawk3DWidget.h \
        src/ui/map3D/Q3DWidgetFactory.h \
        src/ui/map3D/WebImageCache.h \
        src/ui/map3D/WebImage.h \
        src/ui/map3D/TextureCache.h \
        src/ui/map3D/Texture.h \
        src/ui/map3D/Imagery.h \
        src/ui/map3D/HUDScaleGeode.h \
        src/ui/map3D/WaypointGroupNode.h \
        src/ui/map3D/TerrainParamDialog.h \
        src/ui/map3D/ImageryParamDialog.h
}
contains(DEPENDENCIES_PRESENT, protobuf):contains(MAVLINK_CONF, pixhawk) {
    message("Including headers for Protocol Buffers")

    # Enable only if protobuf is available
    HEADERS += libs/mavlink/include/mavlink/v1.0/pixhawk/pixhawk.pb.h \
        src/ui/map3D/ObstacleGroupNode.h \
        src/ui/map3D/GLOverlayGeode.h
}
contains(DEPENDENCIES_PRESENT, libfreenect) { 
    message("Including headers for libfreenect")
    
    # Enable only if libfreenect is available
    HEADERS += src/input/Freenect.h
}
SOURCES += src/main.cc \
    src/QGCCore.cc \
    src/uas/UASManager.cc \
    src/uas/UAS.cc \
    src/comm/LinkManager.cc \
    src/comm/LinkInterface.cpp \
    src/comm/SerialLink.cc \
    src/comm/MAVLinkProtocol.cc \
    src/comm/QGCFlightGearLink.cc \
    src/comm/QGCJSBSimLink.cc \
    src/comm/QGCXPlaneLink.cc \
    src/ui/CommConfigurationWindow.cc \
    src/ui/SerialConfigurationWindow.cc \
    src/ui/MainWindow.cc \
    src/ui/uas/UASControlWidget.cc \
    src/ui/uas/UASListWidget.cc \
    src/ui/uas/UASInfoWidget.cc \
    src/ui/HUD.cc \
    src/ui/linechart/LinechartWidget.cc \
    src/ui/linechart/LinechartPlot.cc \
    src/ui/linechart/Scrollbar.cc \
    src/ui/linechart/ScrollZoomer.cc \
    src/ui/uas/UASView.cc \
    src/ui/CameraView.cc \
    src/comm/MAVLinkSimulationLink.cc \
    src/comm/UDPLink.cc \
    src/ui/ParameterInterface.cc \
    src/ui/WaypointList.cc \
    src/Waypoint.cc \
    src/ui/ObjectDetectionView.cc \
    src/input/JoystickInput.cc \
    src/ui/JoystickWidget.cc \
    src/ui/DebugConsole.cc \
    src/ui/HDDisplay.cc \
    src/ui/MAVLinkSettingsWidget.cc \
    src/ui/AudioOutputWidget.cc \
    src/GAudioOutput.cc \
    src/LogCompressor.cc \
    src/ui/QGCParamWidget.cc \
    src/ui/QGCSensorSettingsWidget.cc \
    src/ui/linechart/Linecharts.cc \
    src/uas/SlugsMAV.cc \
    src/uas/PxQuadMAV.cc \
    src/uas/ArduPilotMegaMAV.cc \
    src/uas/senseSoarMAV.cpp \
    src/ui/watchdog/WatchdogControl.cc \
    src/ui/watchdog/WatchdogProcessView.cc \
    src/ui/watchdog/WatchdogView.cc \
    src/uas/UASWaypointManager.cc \
    src/ui/HSIDisplay.cc \
    src/QGC.cc \
    src/ui/QGCFirmwareUpdate.cc \
    src/ui/QGCPxImuFirmwareUpdate.cc \
    src/ui/QGCDataPlot2D.cc \
    src/ui/linechart/IncrementalPlot.cc \
    src/ui/QGCRemoteControlView.cc \
    src/ui/RadioCalibration/RadioCalibrationWindow.cc \
    src/ui/RadioCalibration/AirfoilServoCalibrator.cc \
    src/ui/RadioCalibration/SwitchCalibrator.cc \
    src/ui/RadioCalibration/CurveCalibrator.cc \
    src/ui/RadioCalibration/AbstractCalibrator.cc \
    src/ui/RadioCalibration/RadioCalibrationData.cc \
    src/ui/QGCWebView.cc \
    src/ui/map3D/QGCWebPage.cc \
    src/ui/SlugsDataSensorView.cc \
    src/ui/SlugsHilSim.cc \
    src/ui/SlugsPadCameraControl.cpp \
    src/ui/QGCMainWindowAPConfigurator.cc \
    src/comm/MAVLinkSwarmSimulationLink.cc \
    src/ui/uas/QGCUnconnectedInfoWidget.cc \
    src/ui/designer/QGCToolWidget.cc \
    src/ui/designer/QGCParamSlider.cc \
    src/ui/designer/QGCCommandButton.cc \
    src/ui/designer/QGCToolWidgetItem.cc \
    src/ui/QGCMAVLinkLogPlayer.cc \
    src/comm/MAVLinkSimulationWaypointPlanner.cc \
    src/comm/MAVLinkSimulationMAV.cc \
    src/uas/QGCMAVLinkUASFactory.cc \
    src/ui/QGCWaypointListMulti.cc \
    src/ui/QGCUDPLinkConfiguration.cc \
    src/ui/QGCSettingsWidget.cc \
    src/ui/uas/UASControlParameters.cpp \
    src/uas/QGCUASParamManager.cc \
    src/ui/map/QGCMapWidget.cc \
    src/ui/map/MAV2DIcon.cc \
    src/ui/map/Waypoint2DIcon.cc \
    src/ui/map/QGCMapTool.cc \
    src/ui/map/QGCMapToolBar.cc \
    src/ui/QGCToolBar.cc \
    src/ui/QGCStatusBar.cc \
    src/ui/QGCMAVLinkInspector.cc \
    src/ui/MAVLinkDecoder.cc \
    src/ui/WaypointViewOnlyView.cc \
    src/ui/WaypointEditableView.cc \
    src/ui/UnconnectedUASInfoWidget.cc \
    src/ui/QGCRGBDView.cc \
    src/ui/mavlink/QGCMAVLinkMessageSender.cc \
    src/ui/firmwareupdate/QGCFirmwareUpdateWidget.cc \
    src/ui/QGCPluginHost.cc \
    src/ui/firmwareupdate/QGCPX4FirmwareUpdate.cc \
    src/ui/mission/QGCMissionOther.cc \
    src/ui/mission/QGCMissionNavWaypoint.cc \
    src/ui/mission/QGCMissionDoJump.cc \
    src/ui/mission/QGCMissionConditionDelay.cc \
    src/ui/mission/QGCMissionNavLoiterUnlim.cc \
    src/ui/mission/QGCMissionNavLoiterTurns.cc \
    src/ui/mission/QGCMissionNavLoiterTime.cc \
    src/ui/mission/QGCMissionNavReturnToLaunch.cc \
    src/ui/mission/QGCMissionNavLand.cc \
    src/ui/mission/QGCMissionNavTakeoff.cc \
    src/ui/mission/QGCMissionNavSweep.cc \
    src/ui/mission/QGCMissionDoStartSearch.cc \
    src/ui/mission/QGCMissionDoFinishSearch.cc \
    src/ui/QGCVehicleConfig.cc \
    src/ui/QGCHilConfiguration.cc \
    src/ui/QGCHilFlightGearConfiguration.cc \
    src/ui/QGCHilJSBSimConfiguration.cc \
    src/ui/QGCHilXPlaneConfiguration.cc \
    src/ui/designer/QGCComboBox.cc \
    src/ui/designer/QGCTextLabel.cc \
    src/ui/submainwindow.cpp \
    src/ui/dockwidgettitlebareventfilter.cpp \
    src/ui/uas/UASQuickViewItem.cc \
    src/ui/uas/UASQuickView.cc \
    src/ui/uas/UASQuickViewTextItem.cc \
    src/ui/uas/UASQuickViewGaugeItem.cc \
    src/ui/uas/UASQuickViewItemSelect.cc \
    src/ui/uas/UASActionsWidget.cpp \
    src/ui/designer/QGCRadioChannelDisplay.cpp \
    src/ui/QGCTabbedInfoView.cpp \
    src/ui/UASRawStatusView.cpp \
    src/ui/PrimaryFlightDisplay.cc \
    src/ui/uas/QGCMessageView.cc \
    src/ui/configuration/ApmHardwareConfig.cc \
    src/ui/configuration/ApmSoftwareConfig.cc \
    src/ui/configuration/FrameTypeConfig.cc \
    src/ui/configuration/CompassConfig.cc \
    src/ui/configuration/AccelCalibrationConfig.cc \
    src/ui/configuration/RadioCalibrationConfig.cc \
    src/ui/configuration/FlightModeConfig.cc \
    src/ui/configuration/Radio3DRConfig.cc \
    src/ui/configuration/BatteryMonitorConfig.cc \
    src/ui/configuration/SonarConfig.cc \
    src/ui/configuration/AirspeedConfig.cc \
    src/ui/configuration/OpticalFlowConfig.cc \
    src/ui/configuration/OsdConfig.cc \
    src/ui/configuration/AntennaTrackerConfig.cc \
    src/ui/configuration/CameraGimbalConfig.cc \
    src/ui/configuration/AP2ConfigWidget.cc \
    src/ui/configuration/BasicPidConfig.cc \
    src/ui/configuration/StandardParamConfig.cc \
    src/ui/configuration/GeoFenceConfig.cc \
    src/ui/configuration/FailSafeConfig.cc \
    src/ui/configuration/AdvancedParamConfig.cc \
    src/ui/configuration/ArduCopterPidConfig.cc \
    src/ui/apmtoolbar.cpp \
    src/ui/configuration/ApmPlaneLevel.cc \
    src/ui/configuration/ParamWidget.cc \
    src/ui/configuration/ArduPlanePidConfig.cc \
    src/ui/configuration/AdvParameterList.cc \
    src/ui/configuration/ArduRoverPidConfig.cc \
    src/ui/configuration/terminalconsole.cpp \
    src/ui/configuration/console.cpp \
    src/ui/configuration/SerialSettingsDialog.cc \
    src/ui/configuration/ApmHighlighter.cc \
    src/ui/configuration/ApmFirmwareConfig.cc \
    src/ui/designer/QGCMouseWheelEventFilter.cc \
    src/ui/DebugOutput.cc \
    src/ui/configuration/APDoubleSpinBox.cc \
    src/ui/configuration/APSpinBox.cc \

# Enable Google Earth only on Mac OS and Windows with Visual Studio compiler
macx|macx-g++|macx-g++42|win32-msvc2008|win32-msvc2010|win32-msvc2012::SOURCES += src/ui/map3D/QGCGoogleEarthView.cc

# Enable OSG only if it has been found
contains(DEPENDENCIES_PRESENT, osg) { 
    message("Including sources for OpenSceneGraph")
    
    # Enable only if OpenSceneGraph is available
    SOURCES += src/ui/map3D/gpl.cc \
        src/ui/map3D/CameraParams.cc \
        src/ui/map3D/ViewParamWidget.cc \
        src/ui/map3D/SystemContainer.cc \
        src/ui/map3D/SystemViewParams.cc \
        src/ui/map3D/GlobalViewParams.cc \
        src/ui/map3D/SystemGroupNode.cc \
        src/ui/map3D/Q3DWidget.cc \
        src/ui/map3D/ImageWindowGeode.cc \
        src/ui/map3D/GCManipulator.cc \
        src/ui/map3D/PixhawkCheetahNode.cc \
        src/ui/map3D/Pixhawk3DWidget.cc \
        src/ui/map3D/Q3DWidgetFactory.cc \
        src/ui/map3D/WebImageCache.cc \
        src/ui/map3D/WebImage.cc \
        src/ui/map3D/TextureCache.cc \
        src/ui/map3D/Texture.cc \
        src/ui/map3D/Imagery.cc \
        src/ui/map3D/HUDScaleGeode.cc \
        src/ui/map3D/WaypointGroupNode.cc \
        src/ui/map3D/TerrainParamDialog.cc \
        src/ui/map3D/ImageryParamDialog.cc

    contains(DEPENDENCIES_PRESENT, osgearth) { 
        message("Including sources for osgEarth")
        
        # Enable only if OpenSceneGraph is available
        SOURCES +=
    }
}
contains(DEPENDENCIES_PRESENT, protobuf):contains(MAVLINK_CONF, pixhawk) {
    message("Including sources for Protocol Buffers")

    # Enable only if protobuf is available
    SOURCES += libs/mavlink/share/mavlink/src/v1.0/pixhawk/pixhawk.pb.cc \
        src/ui/map3D/ObstacleGroupNode.cc \
        src/ui/map3D/GLOverlayGeode.cc
}
contains(DEPENDENCIES_PRESENT, libfreenect) { 
    message("Including sources for libfreenect")
    
    # Enable only if libfreenect is available
    SOURCES += src/input/Freenect.cc
}

# Add icons and other resources
RESOURCES += qgroundcontrol.qrc

# Include RT-LAB Library
win32:exists(src/lib/opalrt/OpalApi.h):exists(C:/OPAL-RT/RT-LAB7.2.4/Common/bin) { 
    message("Building support for Opal-RT")
    LIBS += -LC:/OPAL-RT/RT-LAB7.2.4/Common/bin \
        -lOpalApi
    INCLUDEPATH += src/lib/opalrt
    HEADERS += src/comm/OpalRT.h \
        src/comm/OpalLink.h \
        src/comm/Parameter.h \
        src/comm/QGCParamID.h \
        src/comm/ParameterList.h \
        src/ui/OpalLinkConfigurationWindow.h
    SOURCES += src/comm/OpalRT.cc \
        src/comm/OpalLink.cc \
        src/comm/Parameter.cc \
        src/comm/QGCParamID.cc \
        src/comm/ParameterList.cc \
        src/ui/OpalLinkConfigurationWindow.cc
    FORMS += src/ui/OpalLinkSettings.ui
    DEFINES += OPAL_RT
}
TRANSLATIONS += es-MX.ts \
    en-US.ts

# xbee support
# libxbee only supported by linux and windows systems
win32-msvc2008|win32-msvc2010|win32-msvc2012|linux {
    HEADERS += src/comm/XbeeLinkInterface.h \
        src/comm/XbeeLink.h \
        src/comm/HexSpinBox.h \
        src/ui/XbeeConfigurationWindow.h \
        src/comm/CallConv.h
    SOURCES += src/comm/XbeeLink.cpp \
        src/comm/HexSpinBox.cpp \
        src/ui/XbeeConfigurationWindow.cpp
    DEFINES += XBEELINK
    INCLUDEPATH += libs/thirdParty/libxbee
# TO DO: build library when it does not exist already
    LIBS += -llibs/thirdParty/libxbee/lib/libxbee
}

###################################################################
#### --- 3DConnexion 3d Mice support (e.g. spacenavigator) --- ####
###################################################################

# xdrvlib only supported by linux (theoretical all X11) systems
# You have to install the official 3DxWare driver for linux to use 3D mouse support on linux systems!
linux-g++|linux-g++-64{
    exists(/usr/local/lib/libxdrvlib.so){
        message("Including support for Magellan 3DxWare for linux system.")
        SOURCES  += src/input/Mouse6dofInput.cpp
        HEADERS  += src/input/Mouse6dofInput.h
        LIBS += -L/usr/local/lib/ -lxdrvlib
        INCLUDEPATH *= /usr/local/include
        DEFINES += MOUSE_ENABLED_LINUX \
                    ParameterCheck                      # Hack: Has to be defined for magellan usage
    }
}

# Support for Windows systems
# You have to install the official 3DxWare driver for Windows to use the 3D mouse support on Windows systems!
win32-msvc2008|win32-msvc2010|win32-msvc2012 {
    message("Including support for 3DxWare for Windows system.")
    SOURCES  += libs/thirdParty/3DMouse/win/MouseParameters.cpp \
                libs/thirdParty/3DMouse/win/Mouse3DInput.cpp \
                src/input/Mouse6dofInput.cpp
    HEADERS  += libs/thirdParty/3DMouse/win/I3dMouseParams.h \
                libs/thirdParty/3DMouse/win/MouseParameters.h \
                libs/thirdParty/3DMouse/win/Mouse3DInput.h \
                src/input/Mouse6dofInput.h
    INCLUDEPATH += libs/thirdParty/3DMouse/win
    DEFINES += MOUSE_ENABLED_WIN
}

unix:!macx:!symbian: LIBS += -losg

OTHER_FILES += \
    dongfang_notes.txt \
    src/ui/dongfang-scrapyard.txt \
    qml/components/DigitalDisplay.qml \
    qml/components/StatusDisplay.qml \
    qml/components/ModeDisplay.qml \
    qml/components/HeartbeatDisplay.qml

OTHER_FILES += \
    qml/ApmToolBar.qml \
    qml/components/Button.qml \
    qml/components/TextButton.qml \
    qml/resources/apmplanner/toolbar/connect.png \
    qml/resources/apmplanner/toolbar/flightplanner.png \
    qml/resources/apmplanner/toolbar/helpwizard.png \
    qml/resources/apmplanner/toolbar/light_initialsetup_icon.png \
    qml/resources/apmplanner/toolbar/terminal.png \
    qml/resources/apmplanner/toolbar/simulation.png \
    qml/resources/apmplanner/toolbar/light_tuningconfig_icon.png \
    qml/resources/apmplanner/toolbar/flightdata.png \
    qml/resources/apmplanner/toolbar/disconnect.png \
    qml/resources/apmplanner/toolbar/donate.png \


#qmlcomponents.path    += $${DESTDIR}$${TARGET}/components
#qmlcomponents.files   += ./components/Button.qml

#sources.files       += ApmToolBar.qml
#sources.path        += $$DESTDIR/qml
#target.path         += apmplanner2
#INSTALLS            += sources target

message( BASEDIR $$BASEDIR DESTDIR $$DESTDIR TARGET $$TARGET TARGETDIR $$TARGETDIR)

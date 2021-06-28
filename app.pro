NAME = qrclip

openrepos {
    PREFIX = openrepos
    DEFINES += OPENREPOS
} else {
    PREFIX = harbour
}

TARGET = $${PREFIX}-$${NAME}
CONFIG += sailfishapp link_pkgconfig
PKGCONFIG += sailfishapp
QT += qml quick concurrent

QMAKE_CXXFLAGS += -Wno-unused-parameter -Wno-psabi
QMAKE_CFLAGS += -Wno-unused-parameter

app_settings {
    # This path is hardcoded in jolla-settings
    TRANSLATIONS_PATH = /usr/share/translations
} else {
    TRANSLATIONS_PATH = /usr/share/$${TARGET}/translations
}

CONFIG(debug, debug|release) {
    DEFINES += DEBUG HARBOUR_DEBUG
}

# Directories
HARBOUR_LIB_REL = harbour-lib
HARBOUR_LIB_DIR = $${_PRO_FILE_PWD_}/$${HARBOUR_LIB_REL}
HARBOUR_LIB_INCLUDE = $${HARBOUR_LIB_DIR}/include
HARBOUR_LIB_SRC = $${HARBOUR_LIB_DIR}/src
HARBOUR_LIB_QML = $${HARBOUR_LIB_DIR}/qml

LIBQRENCODE_DIR = $${_PRO_FILE_PWD_}/libqrencode

# Libraries
LIBS +=  libqrencode.a -ldl

OTHER_FILES += \
    *.desktop \
    qml/*.qml \
    qml/images/*.svg \
    qml/images/*.png \
    icons/*.svg \
    translations/*.ts

INCLUDEPATH += \
    src \
    $${LIBQRENCODE_DIR}

HEADERS += \
    src/FileUtils.h

SOURCES += \
    src/main.cpp \
    src/FileUtils.cpp

# harbour-lib

INCLUDEPATH += \
    $${HARBOUR_LIB_DIR}/include

HEADERS += \
    $${HARBOUR_LIB_INCLUDE}/HarbourBase32.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourClipboard.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourDebug.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourQrCodeGenerator.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourQrCodeImageProvider.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourSystem.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourTask.h

SOURCES += \
    $${HARBOUR_LIB_SRC}/HarbourBase32.cpp \
    $${HARBOUR_LIB_SRC}/HarbourClipboard.cpp \
    $${HARBOUR_LIB_SRC}/HarbourQrCodeGenerator.cpp \
    $${HARBOUR_LIB_SRC}/HarbourQrCodeImageProvider.cpp \
    $${HARBOUR_LIB_SRC}/HarbourSystem.cpp \
    $${HARBOUR_LIB_SRC}/HarbourTask.cpp

HARBOUR_QML_COMPONENTS = \
    $${HARBOUR_LIB_QML}/HarbourHighlightIcon.qml

qml_components.files = $${HARBOUR_QML_COMPONENTS}
qml_components.path = /usr/share/$${TARGET}/qml/harbour
INSTALLS += qml_components

# Icons
ICON_SIZES = 86 108 128 172 256
for(s, ICON_SIZES) {
    icon_target = icon$${s}
    icon_dir = icons/$${s}x$${s}
    $${icon_target}.files = $${icon_dir}/$${TARGET}.png
    $${icon_target}.path = /usr/share/icons/hicolor/$${s}x$${s}/apps
    equals(PREFIX, "openrepos") {
        $${icon_target}.extra = cp $${icon_dir}/harbour-$${NAME}.png $$eval($${icon_target}.files)
        $${icon_target}.CONFIG += no_check_exist
    }
    INSTALLS += $${icon_target}
}

# Desktop file
equals(PREFIX, "openrepos") {
    desktop.extra = sed s/harbour/openrepos/g harbour-$${NAME}.desktop > $${TARGET}.desktop
    desktop.CONFIG += no_check_exist
}

TRANSLATION_IDBASED=-idbased
TRANSLATION_SOURCES = \
  $${_PRO_FILE_PWD_}/qml

defineTest(addTrFile) {
    rel = translations/$${1}
    OTHER_FILES += $${rel}.ts
    export(OTHER_FILES)

    in = $${_PRO_FILE_PWD_}/$$rel
    out = $${OUT_PWD}/$$rel

    s = $$replace(1,-,_)
    lupdate_target = lupdate_$$s
    qm_target = qm_$$s

    $${lupdate_target}.commands = lupdate -noobsolete -locations none $${TRANSLATION_SOURCES} -ts \"$${in}.ts\" && \
        mkdir -p \"$${OUT_PWD}/translations\" &&  [ \"$${in}.ts\" != \"$${out}.ts\" ] && \
        cp -af \"$${in}.ts\" \"$${out}.ts\" || :

    $${qm_target}.path = $$TRANSLATIONS_PATH
    $${qm_target}.depends = $${lupdate_target}
    $${qm_target}.commands = lrelease $$TRANSLATION_IDBASED \"$${out}.ts\" && \
        $(INSTALL_FILE) \"$${out}.qm\" $(INSTALL_ROOT)$${TRANSLATIONS_PATH}/

    QMAKE_EXTRA_TARGETS += $${lupdate_target} $${qm_target}
    INSTALLS += $${qm_target}

    export($${lupdate_target}.commands)
    export($${qm_target}.path)
    export($${qm_target}.depends)
    export($${qm_target}.commands)
    export(QMAKE_EXTRA_TARGETS)
    export(INSTALLS)
}

LANGUAGES = fr pl pt ru sv zh_CN

addTrFile($${TARGET})
for(l, LANGUAGES) {
    addTrFile($${TARGET}-$$l)
}

qm.path = $$TRANSLATIONS_PATH
qm.CONFIG += no_check_exist
INSTALLS += qm

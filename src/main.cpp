/*
 * Copyright (C) 2019 Jolla Ltd.
 * Copyright (C) 2019 Slava Monich <slava@monich.com>
 *
 * You may use this file under the terms of BSD license as follows:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer
 *      in the documentation and/or other materials provided with the
 *      distribution.
 *   3. Neither the names of the copyright holders nor the names of its
 *      contributors may be used to endorse or promote products derived
 *      from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "FileUtils.h"

#include "HarbourClipboard.h"
#include "HarbourImageProvider.h"
#include "HarbourQrCodeGenerator.h"
#include "HarbourQrCodeImageProvider.h"
#include "HarbourDebug.h"

#include <sailfishapp.h>

#include <QGuiApplication>
#include <QtQuick>

#ifdef OPENREPOS
#  define QRCLIP_APP_NAME  "openrepos-qrclip"
#else
#  define QRCLIP_APP_NAME  "harbour-qrclip"
#endif

#define QRCLIP_QML_IMPORT  "harbour.qrclip"
#define QRCLIP_DCONF_ROOT  "/apps/" QRCLIP_APP_NAME "/"

static void register_types(const char* uri, int v1 = 1, int v2 = 0)
{
    qmlRegisterSingletonType<FileUtils>(uri, v1, v2, "FileUtils", FileUtils::createSingleton);
    qmlRegisterSingletonType<HarbourClipboard>(uri, v1, v2, "HarbourClipboard", HarbourClipboard::createSingleton);
    qmlRegisterSingletonType<HarbourQrCodeGenerator>(uri, v1, v2, "HarbourQrCodeGenerator", HarbourQrCodeGenerator::createSingleton);
}

int main(int argc, char *argv[])
{
    QGuiApplication* app = SailfishApp::application(argc, argv);

    app->setApplicationName(QRCLIP_APP_NAME);
    register_types(QRCLIP_QML_IMPORT, 1, 0);

    // Load translations
    QLocale locale;
    QTranslator* tr = new QTranslator(app);
#ifdef OPENREPOS
    // OpenRepos build has settings applet
    const QString transDir("/usr/share/translations");
#else
    const QString transDir = SailfishApp::pathTo("translations").toLocalFile();
#endif
    const QString transFile(QRCLIP_APP_NAME);
    if (tr->load(locale, transFile, "-", transDir) ||
        tr->load(transFile, transDir)) {
        app->installTranslator(tr);
    } else {
        HDEBUG("Failed to load translator for" << locale);
        delete tr;
    }

    // Create the view
    QQuickView* view = SailfishApp::createView();
    QQmlContext* context = view->rootContext();
    QQmlEngine* engine = context->engine();

    engine->addImageProvider("harbour", new HarbourImageProvider);
    engine->addImageProvider("qrcode", new HarbourQrCodeImageProvider);

    // Initialize the view and show it
    view->setTitle(qtTrId("qrclip-app_name"));
    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->showFullScreen();

    int ret = app->exec();

    delete view;
    delete app;
    return ret;
}

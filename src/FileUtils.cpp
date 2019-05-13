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

#include "HarbourQrCodeImageProvider.h"
#include "HarbourBase32.h"
#include "HarbourDebug.h"

#include <QQmlEngine>

#include <QPainter>
#include <QStandardPaths>
#include <QFile>
#include <QDir>

FileUtils::FileUtils(QObject* aParent) :
    QObject(aParent)
{
}

// Callback for qmlRegisterSingletonType<FileUtils>
QObject* FileUtils::createSingleton(QQmlEngine* aEngine, QJSEngine*)
{
    return new FileUtils(aEngine);
}

QString FileUtils::saveToGallery(QString aBase32, QString aSubDir, QString aBaseName)
{
    const QByteArray bits(HarbourBase32::fromBase32(aBase32.toLocal8Bit()));
    HDEBUG(aBase32 << "=>" << bits.size() << "bytes");
    QImage qrcode(HarbourQrCodeImageProvider::createImage(bits));
    if (!qrcode.isNull()) {
        // Draw one-pixel white square around QR code
        const int w = qrcode.width() + 2;
        const int h = qrcode.height() + 2;
        QImage img(w, h, QImage::Format_ARGB32);
        QPainter painter(&img);
        painter.fillRect(0, 0, w, h, Qt::white);
        painter.drawImage(1, 1, qrcode);
        painter.end();

        // Write the file
        QString destDir = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
        if (!destDir.isEmpty()) {
            if (!aSubDir.isEmpty()) {
                destDir += QDir::separator() + aSubDir;
            }
            if (aBaseName.isEmpty()) aBaseName = QLatin1String("image");
            if (QFile::exists(destDir) || QDir(destDir).mkpath(destDir)) {
                static const QString suffix(".png");
                static const QString prefix(destDir + QDir::separator() + aBaseName);
                QString destFile = prefix + suffix;
                for (int i = 1; QFile::exists(destFile); i++) {
                    destFile = prefix + QString().sprintf("-%03d", i) + suffix;
                }
                if (img.save(destFile)) {
                    HDEBUG(destFile);
                    return destFile;
                } else {
                    HWARN("Cannot save" << qPrintable(destFile));
                }
            } else {
                HWARN("Cannot create directory" << qPrintable(destDir));
            }
        }
    }
    return QString();
}

/*
 * Copyright (C) 2021 Jolla Ltd.
 * Copyright (C) 2021 Slava Monich <slava@monich.com>
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

#include "QrCodeModel.h"

#include "HarbourQrCodeGenerator.h"
#include "HarbourBase32.h"
#include "HarbourTask.h"
#include "HarbourDebug.h"

// ==========================================================================
// QrCodeModel::Task
// ==========================================================================

class QrCodeModel::Task : public HarbourTask
{
    Q_OBJECT

public:
    Task(QThreadPool* aPool, QString aText);
    void performTask() Q_DECL_OVERRIDE;

public:
    QString iText;
    QString iCode[HarbourQrCodeGenerator::ECLevelCount];
};

QrCodeModel::Task::Task(QThreadPool* aPool, QString aText) :
    HarbourTask(aPool),
    iText(aText)
{
}

void QrCodeModel::Task::performTask()
{
    for (int i = 0; i < HarbourQrCodeGenerator::ECLevelCount && !isCanceled(); i++) {
        iCode[i] = HarbourBase32::toBase32(HarbourQrCodeGenerator::generate(iText,
            (HarbourQrCodeGenerator::ECLevel)i));
    }
}

// ==========================================================================
// QrCodeModel::Private
// ==========================================================================

class QrCodeModel::Private : public QObject
{
    Q_OBJECT

public:
    enum Role {
        QrCodeRole = Qt::UserRole,
        EcLevelRole
    };

    Private(QrCodeModel* aParent);
    ~Private();

    QrCodeModel* parentModel() const;
    int count() const;
    QString defaultCode() const;
    const QString* codeAt(int aRow, HarbourQrCodeGenerator::ECLevel* aLevel = Q_NULLPTR) const;
    void setText(QString aValue);

public Q_SLOTS:
    void onTaskDone();

public:
    QThreadPool* iThreadPool;
    Task* iTask;
    QString iText;
    QString iCode[HarbourQrCodeGenerator::ECLevelCount];
};

QrCodeModel::Private::Private(QrCodeModel* aParent) :
    QObject(aParent),
    iThreadPool(new QThreadPool(this)),
    iTask(Q_NULLPTR)
{
    // Serialize the tasks for this model:
    iThreadPool->setMaxThreadCount(1);
}

QrCodeModel::Private::~Private()
{
    if (iTask) iTask->release();
    iThreadPool->waitForDone();
}

inline QrCodeModel* QrCodeModel::Private::parentModel() const
{
    return qobject_cast<QrCodeModel*>(parent());
}

int QrCodeModel::Private::count() const
{
    int row = 0;
    for (int i = 0; i < HarbourQrCodeGenerator::ECLevelCount; i++) {
        if (!iCode[i].isEmpty()) {
            row++;
        }
    }
    return row;
}

const QString* QrCodeModel::Private::codeAt(int aRow, HarbourQrCodeGenerator::ECLevel* aLevel) const
{
    int row = 0;
    for (int i = 0; i < HarbourQrCodeGenerator::ECLevelCount; i++) {
        const QString* code = iCode + i;
        if (!code->isEmpty()) {
            if (row == aRow) {
                if (aLevel) {
                    *aLevel = (HarbourQrCodeGenerator::ECLevel)i;
                }
                return code;
            }
            row++;
        }
    }
    if (aLevel) {
        *aLevel = HarbourQrCodeGenerator::ECLevelDefault;
    }
    return Q_NULLPTR;
}

QString QrCodeModel::Private::defaultCode() const
{
    const QString* code = codeAt(0);
    return code ? QString(*code) : QString();
}

void QrCodeModel::Private::setText(QString aText)
{
    if (iText != aText) {
        iText = aText;
        QrCodeModel* model = parentModel();
        if (iText.isEmpty()) {
            // No text - no code. Just clear the model
            const QString prevCode(defaultCode());
            for (int i = 0; i < HarbourQrCodeGenerator::ECLevelCount; i++) {
                iCode[i].clear();
            }
            if (iTask) {
                // Cancel the task
                iTask->release();
                iTask = Q_NULLPTR;
                Q_EMIT model->runningChanged();
            }
            if (!prevCode.isEmpty()) {
                // It's empty now
                Q_EMIT model->qrcodeChanged();
            }
        } else {
            // We actually need to generate a new code
            const bool wasRunning = (iTask != Q_NULLPTR);
            if (iTask) iTask->release();
            iTask = new Task(iThreadPool, iText);
            iTask->submit(this, SLOT(onTaskDone()));
            if (!wasRunning) {
                Q_EMIT model->runningChanged();
            }
        }
        Q_EMIT model->textChanged();
    }
}

void QrCodeModel::Private::onTaskDone()
{
    if (sender() == iTask) {
        Task* task = iTask;
        iTask = Q_NULLPTR;

        QModelIndex parent;
        QrCodeModel* model = parentModel();
        const QString prevCode(defaultCode());
        for (int i = 0, pos = 0; i < HarbourQrCodeGenerator::ECLevelCount; i++) {
            QString* modelValue = iCode + i;
            const QString* newValue = task->iCode + i;
            if (modelValue->compare(*newValue) != 0) {
                if (modelValue->isEmpty()) {
                    // Inserting a new value
                    model->beginInsertRows(parent, pos, pos);
                    *modelValue = *newValue;
                    model->endInsertRows();
                    pos++;
                } else if (newValue->isEmpty()) {
                    // Removing the old value
                    model->beginRemoveRows(parent, pos, pos);
                    modelValue->clear();
                    model->endRemoveRows();
                    // Current position remains the same
                } else {
                    // The value has changed
                    *modelValue = *newValue;
                    QVector<int> roles;
                    roles.append(QrCodeRole);
                    const QModelIndex index(model->index(pos));
                    model->dataChanged(index, index, roles);
                    pos++;
                }
            }
        }

        task->release();
        if (defaultCode() != prevCode) {
            Q_EMIT model->qrcodeChanged();
        }
        Q_EMIT model->runningChanged();
    }
}

// ==========================================================================
// QrCodeModel
// ==========================================================================

QrCodeModel::QrCodeModel(QObject* aParent) :
    QAbstractListModel(aParent),
    iPrivate(new Private(this))
{
}

QrCodeModel::~QrCodeModel()
{
    delete iPrivate;
}

// Callback for qmlRegisterSingletonType<QrCodeModel>
QObject* QrCodeModel::createSingleton(QQmlEngine* aEngine, QJSEngine*)
{
    return new QrCodeModel(); // Singleton doesn't need a parent
}

QString QrCodeModel::getText() const
{
    return iPrivate->iText;
}

void QrCodeModel::setText(QString aValue)
{
    iPrivate->setText(aValue);
}

QString QrCodeModel::getQrCode() const
{
    return iPrivate->defaultCode();
}

bool QrCodeModel::isRunning() const
{
    return iPrivate->iTask != Q_NULLPTR;
}

QHash<int,QByteArray> QrCodeModel::roleNames() const
{
    QHash<int,QByteArray> roles;
    roles.insert(Private::QrCodeRole, "qrcode");
    roles.insert(Private::EcLevelRole, "eclevel");
    return roles;
}

int QrCodeModel::rowCount(const QModelIndex& aParent) const
{
    return iPrivate->count();
}

QVariant QrCodeModel::data(const QModelIndex& aIndex, int aRole) const
{
    const int row = aIndex.row();
    HarbourQrCodeGenerator::ECLevel ecLevel;
    const QString* qrCode = iPrivate->codeAt(row, &ecLevel);
    if (qrCode) {
        switch ((Private::Role)aRole) {
        case Private::QrCodeRole: return *qrCode;
        case Private::EcLevelRole: return ecLevel;
        }
    }
    return QVariant();
}

#include "QrCodeModel.moc"

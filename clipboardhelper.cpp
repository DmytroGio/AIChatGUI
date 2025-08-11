#include "clipboardhelper.h"

ClipboardHelper::ClipboardHelper(QObject *parent)
    : QObject(parent)
    , m_clipboard(QGuiApplication::clipboard())
{
}

void ClipboardHelper::copyText(const QString &text)
{
    m_clipboard->setText(text, QClipboard::Clipboard);
}

QString ClipboardHelper::getText()
{
    return m_clipboard->text(QClipboard::Clipboard);
}

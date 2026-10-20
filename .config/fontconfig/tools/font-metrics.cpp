// Build:
//   g++ -O2 -fPIC font-metrics.cpp -o font-metrics $(pkg-config --cflags --libs Qt6Gui)
// Run (needs a QGuiApplication; offscreen works headless):
//   QT_QPA_PLATFORM=offscreen ./font-metrics "Sans Serif" monospace
//
// Reproduces exactly how KDecoration3 turns the window-title font into the
// Breeze title-bar height:
//
//   int gridUnit = QFontMetrics(font).boundingRect('M').height();
//   if (gridUnit % 2 != 0) gridUnit++;
//   int smallSpacing = qMax(2, gridUnit / 4);
//   int buttonSize   = gridUnit * 2;                 // default button size
//   int titleBar     = qMax(fm.height(), buttonSize) + smallSpacing * 4;

#include <QFont>
#include <QFontInfo>
#include <QFontMetrics>
#include <QFontMetricsF>
#include <QGuiApplication>
#include <QScreen>
#include <QTextStream>

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QTextStream out(stdout);

    out << "logicalDpi=" << app.primaryScreen()->logicalDotsPerInch() << "\n";
    out << QString("%1\t%2\t%3\t%4\t%5\t%6\t%7\t%8\t%9\t%10\n")
               .arg("resolved family", 24)
               .arg("pt", 3)
               .arg("capM", 5)
               .arg("grid", 5)
               .arg("small", 6)
               .arg("button", 7)
               .arg("titleBar", 9)
               .arg("LatinM", 7)
               .arg("CJK", 6)
               .arg("CJK/Latin", 9);

    for (int i = 1; i < argc; ++i) {
        QFont f(QString::fromUtf8(argv[i]), 11); // 11 pt, as in KDE's kdeglobals
        QFontMetrics fm(f);
        QFontMetricsF fmf(f);
        QFontInfo fi(f);

        int capM = fm.boundingRect(QLatin1Char('M')).height();
        int grid = capM + (capM % 2);
        int small = qMax(2, grid / 4);
        int button = grid * 2;
        int titleBar = qMax(fm.height(), button) + small * 4;

        qreal wM = fmf.horizontalAdvance(QStringLiteral("M"));
        qreal wCJK = fmf.horizontalAdvance(QString::fromUtf8("\u4E2D"));

        out << QString("%1\t%2\t%3\t%4\t%5\t%6\t%7\t%8\t%9\t%10\n")
                   .arg(fi.family(), 24)
                   .arg(f.pointSize())
                   .arg(capM)
                   .arg(grid)
                   .arg(small)
                   .arg(button)
                   .arg(titleBar)
                   .arg(wM, 7, 'f', 2)
                   .arg(wCJK, 6, 'f', 2)
                   .arg(wM > 0 ? wCJK / wM : 0.0, 9, 'f', 2);
    }
    return 0;
}

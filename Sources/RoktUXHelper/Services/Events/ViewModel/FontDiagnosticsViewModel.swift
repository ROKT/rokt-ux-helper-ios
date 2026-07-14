import Foundation

class FontDiagnosticsViewModel {
    init(processedFontDiagnostics: Set<FontDiagnostics> = Set<FontDiagnostics>()) {
        self.processedFontDiagnostics = processedFontDiagnostics
    }

    var processedFontDiagnostics = Set<FontDiagnostics>()

    func insertProcessedFontDiagnostics(_ fontFamily: String) -> Bool {
        let pendingFontDiagnostics = FontDiagnostics(fontFamily: fontFamily)
        return processedFontDiagnostics.insert(pendingFontDiagnostics).inserted
    }
}

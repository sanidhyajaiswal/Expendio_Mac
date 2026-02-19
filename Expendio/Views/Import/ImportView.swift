import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    let profileId: UUID
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [ExpenseCategory]
    @Query private var profiles: [Profile]
    
    @State private var isDragOver = false
    @State private var parsedExpenses: [ParsedExpense] = []
    @State private var importStatus: ImportStatus = .idle
    @State private var errorMessage: String?
    @State private var importedCount = 0
    @State private var dashOffset: CGFloat = 0
    
    enum ImportStatus { case idle, previewing, importing, done, error }
    
    init(profileId: UUID) {
        self.profileId = profileId
        let pid = profileId
        _categories = Query(filter: #Predicate<ExpenseCategory> { $0.profileId == pid })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Import").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                    Text("Import expenses from Splitwise CSV").font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                }; Spacer()
            }.padding(.horizontal, 32).padding(.top, 28).padding(.bottom, 24)
            
            ScrollView {
                VStack(spacing: 20) {
                    if importStatus == .idle || importStatus == .error { dropZone }
                    if let err = errorMessage { errorBanner(err) }
                    if importStatus == .previewing { previewSection }
                    if importStatus == .done { successBanner }
                }.padding(.horizontal, 32).padding(.bottom, 32)
            }
        }.background(AppTheme.background)
    }
    
    private var dropZone: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.down.fill").font(.system(size: 48)).foregroundColor(isDragOver ? AppTheme.accent : AppTheme.textMuted).scaleEffect(isDragOver ? 1.15 : 1.0).animation(.spring(response: 0.3), value: isDragOver)
            VStack(spacing: 6) { Text("Drop Splitwise CSV here").font(.system(size: 18, weight: .semibold)).foregroundColor(AppTheme.textPrimary); Text("or click to browse").font(.system(size: 14)).foregroundColor(AppTheme.textSecondary) }
            Button { openFilePicker() } label: { HStack(spacing: 6) { Image(systemName: "folder"); Text("Browse Files") }.gradientButton() }.buttonStyle(.plain)
        }.frame(maxWidth: .infinity).frame(height: 260)
        .background(RoundedRectangle(cornerRadius: 20).fill(isDragOver ? AppTheme.accent.opacity(0.05) : AppTheme.surface.opacity(0.5)).overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10, 6], dashPhase: dashOffset)).foregroundStyle(isDragOver ? AppTheme.accent : AppTheme.border)))
        .onDrop(of: [UTType.commaSeparatedText, UTType.fileURL], isTargeted: $isDragOver) { providers in handleDrop(providers); return true }
        .onAppear { withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { dashOffset = 32 } }
    }
    
    private var previewSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) { Text("Preview").font(.system(size: 18, weight: .semibold)).foregroundColor(AppTheme.textPrimary); Text("\(parsedExpenses.count) expenses found").font(.system(size: 13)).foregroundColor(AppTheme.textSecondary) }
                Spacer()
                HStack(spacing: 12) {
                    Button("Cancel") { importStatus = .idle; parsedExpenses = [] }.font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textSecondary).padding(.horizontal, 16).padding(.vertical, 8).background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.surfaceElevated)).buttonStyle(.plain)
                    Button { performImport() } label: { HStack(spacing: 6) { Image(systemName: "square.and.arrow.down"); Text("Import All") }.gradientButton() }.buttonStyle(.plain)
                }
            }
            VStack(spacing: 0) {
                HStack { Text("DATE").frame(width: 100, alignment: .leading); Text("DESCRIPTION").frame(maxWidth: .infinity, alignment: .leading); Text("CATEGORY").frame(width: 140, alignment: .leading); Text("AMOUNT").frame(width: 100, alignment: .trailing) }.font(.system(size: 11, weight: .semibold)).foregroundColor(AppTheme.textMuted).padding(.horizontal, 16).padding(.vertical, 10).background(AppTheme.surface.opacity(0.5))
                Divider().overlay(AppTheme.border.opacity(0.3))
                ForEach(Array(parsedExpenses.prefix(50).enumerated()), id: \.offset) { _, exp in
                    HStack { Text(exp.date, format: .dateTime.month(.abbreviated).day().year()).frame(width: 100, alignment: .leading); Text(exp.description).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading); Text(exp.category).frame(width: 140, alignment: .leading); Text("\(exp.currency) \(String(format: "%.0f", exp.cost))").fontWeight(.semibold).frame(width: 100, alignment: .trailing) }.font(.system(size: 13)).foregroundColor(AppTheme.textSecondary).padding(.horizontal, 16).padding(.vertical, 8)
                    Divider().overlay(AppTheme.border.opacity(0.15))
                }
                if parsedExpenses.count > 50 { Text("... and \(parsedExpenses.count - 50) more").font(.system(size: 12)).foregroundColor(AppTheme.textMuted).padding(.vertical, 12) }
            }.glassCard(padding: 0)
        }
    }
    
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) { Image(systemName: "exclamationmark.triangle.fill").foregroundColor(AppTheme.danger); Text(message).font(.system(size: 13)).foregroundColor(AppTheme.textPrimary); Spacer(); Button { errorMessage = nil } label: { Image(systemName: "xmark").font(.system(size: 11)).foregroundColor(AppTheme.textSecondary) }.buttonStyle(.plain) }
            .padding(16).background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.danger.opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.danger.opacity(0.3), lineWidth: 1)))
    }
    
    private var successBanner: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 48)).foregroundColor(AppTheme.success)
            Text("Import Complete!").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
            Text("\(importedCount) expenses imported successfully").font(.system(size: 14)).foregroundColor(AppTheme.textSecondary)
            Button { importStatus = .idle; parsedExpenses = []; importedCount = 0 } label: { Text("Import More").gradientButton() }.buttonStyle(.plain).padding(.top, 8)
        }.frame(maxWidth: .infinity).padding(.vertical, 60).glassCard()
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [UTType.commaSeparatedText, UTType(filenameExtension: "csv")!]; panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { loadCSV(from: url) }
    }
    private func handleDrop(_ providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in guard let d = data as? Data, let url = URL(dataRepresentation: d, relativeTo: nil) else { return }; DispatchQueue.main.async { loadCSV(from: url) } }
    }
    private var activeProfileName: String {
        profiles.first { $0.id == profileId }?.name ?? ""
    }
    private func loadCSV(from url: URL) { do { parsedExpenses = try SplitwiseImporter.parseCSV(at: url, profileName: activeProfileName); importStatus = .previewing; errorMessage = nil } catch { errorMessage = error.localizedDescription; importStatus = .error } }
    private func performImport() { importStatus = .importing; importedCount = SplitwiseImporter.importExpenses(parsedExpenses, into: modelContext, categories: categories, profileId: profileId); importStatus = .done }
}

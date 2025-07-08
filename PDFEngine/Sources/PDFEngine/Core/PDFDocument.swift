import SwiftUI
import PDFKit
import CoreGraphics
import AppKit
import UniformTypeIdentifiers
import Logging
import DataLayer

// MARK: - FileDocument wrapper used by .fileExporter
public struct GeneratedPDFDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.pdf] }
    public var data: Data
    
    public init(data: Data = Data()) {
        self.data = data
    }
    
    public init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Page Content Struct (utilisé par les vues PDF)
public struct InvoicePageContent {
    public var facture: FactureDTO
    public var entreprise: EntrepriseDTO?
    public var client: ClientDTO?
    public var lines: [LigneFactureDTO]
    public var isFirstPage: Bool
    public var isLastPage: Bool
    
    public init(facture: FactureDTO, entreprise: EntrepriseDTO? = nil, client: ClientDTO? = nil, lines: [LigneFactureDTO], isFirstPage: Bool, isLastPage: Bool) {
        self.facture = facture
        self.entreprise = entreprise
        self.client = client
        self.lines = lines
        self.isFirstPage = isFirstPage
        self.isLastPage = isLastPage
    }
}
import Foundation
import SwiftData
import Combine
import UIKit

@Observable
final class TimerManager {
    private(set) var activeSession: Session?
    private(set) var elapsedSeconds: Int = 0

    // Set to non-nil to present the save/edit sheet; cleared after save or discard.
    var sessionToSave: Session?

    private var pendingStartType: SittingType?
    private let modelContext: ModelContext
    private var timerCancellable: AnyCancellable?
    private var foregroundObserver: AnyCancellable?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        restoreActiveSession()
        observeForeground()
    }

    // MARK: - Public API

    /// Starts a timer for `type`. If another type is already running, stops it first and
    /// presents the save sheet; the new timer starts after the user saves or discards.
    func startTimer(for type: SittingType) {
        if activeSession != nil {
            stopTimer(thenStart: type)
        } else {
            beginSession(type: type)
        }
    }

    /// Stops the active timer and presents the save/edit sheet.
    /// `nextType`, if provided, will start automatically after the user saves/discards.
    func stopTimer(thenStart nextType: SittingType? = nil) {
        guard let session = activeSession else { return }
        session.stopTime = Date()
        stopTicking()
        activeSession = nil
        pendingStartType = nextType
        try? modelContext.save()
        sessionToSave = session
    }

    func saveSession(_ session: Session, startTime: Date, stopTime: Date) {
        session.startTime = startTime
        session.stopTime = stopTime
        try? modelContext.save()
        afterSaveOrDiscard()
    }

    func discardSession(_ session: Session) {
        modelContext.delete(session)
        try? modelContext.save()
        afterSaveOrDiscard()
    }

    // MARK: - Private

    private func afterSaveOrDiscard() {
        sessionToSave = nil
        if let next = pendingStartType {
            pendingStartType = nil
            beginSession(type: next)
        }
    }

    private func beginSession(type: SittingType) {
        let session = Session(startTime: Date(), type: type)
        modelContext.insert(session)
        try? modelContext.save()
        activeSession = session
        startTicking()
    }

    private func restoreActiveSession() {
        var descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.stopTime == nil },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let session = try? modelContext.fetch(descriptor).first else { return }
        activeSession = session
        elapsedSeconds = Int(Date().timeIntervalSince(session.startTime))
        startTicking()
    }

    private func startTicking() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let session = self.activeSession else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(session.startTime))
            }
    }

    private func stopTicking() {
        timerCancellable?.cancel()
        timerCancellable = nil
        elapsedSeconds = 0
    }

    private func observeForeground() {
        foregroundObserver = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self, let session = self.activeSession else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(session.startTime))
            }
    }
}

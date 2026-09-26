//
//  BroadcastBonjourServiceView+TxtRecords.swift
//  KozBon
//
//  Copyright © 2016-present Kozinga. All rights reserved.
//

import SwiftUI
import BonjourCore
import BonjourLocalization
import BonjourModels
import BonjourScanning

// MARK: - BroadcastBonjourServiceView + TXT Records

/// The TXT-record list and its removal path.
///
/// A same-type extension rather than a separate view, so it keeps
/// reading `viewModel` state directly (see the note at the top of
/// `BroadcastBonjourServiceView.swift`). Split out to keep that
/// type's body under the length limit.
extension BroadcastBonjourServiceView {

    @ViewBuilder
    func txtRecordsSection() -> some View {
        Section {
            ForEach(viewModel.dataRecords, id: \.key) { dataRecord in
                TitleDetailStackView(
                    title: dataRecord.key,
                    detail: dataRecord.value
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        removeDataRecord(dataRecord)
                    } label: {
                        Label(Strings.Buttons.remove, systemImage: Iconography.remove)
                    }
                    .accessibilityLabel(Strings.Accessibility.remove(dataRecord.key))
                    .accessibilityHint(Strings.Accessibility.deleteTxtRecordHint)
                    .tint(.red)
                }
                // Swipe actions are gesture-only — mirror delete so
                // VoiceOver / Switch Control users can remove records.
                .accessibilityActions {
                    Button(Strings.Accessibility.remove(dataRecord.key)) {
                        removeDataRecord(dataRecord)
                    }
                }
            }

            Button {
                isCreateTxtRecordViewPresented = true
            } label: {
                Label(Strings.Buttons.addTxtRecord, systemImage: Iconography.add)
            }
            .accessibilityHint(Strings.Accessibility.addTxtRecordHint)
        } header: {
            Text(Strings.Sections.txtRecords)
                .accessibilityAddTraits(.isHeader)
        } footer: {
            // TXT-record-specific explanation rather than form-wide
            // tips. The other fields (Service Type, Port, Domain) all
            // have their own per-field hints in their section footers
            // now, so this footer can stay focused on the section it
            // sits under: what TXT records are, when to add them, and
            // when to leave the list empty.
            Text(Strings.Guidance.txtRecord)
        }
    }

    // MARK: - TXT Record Removal

    /// Removes the given TXT record with the standard animation.
    /// Shared by the swipe-delete button and its VoiceOver
    /// accessibility-action mirror so the two paths can't drift.
    private func removeDataRecord(_ dataRecord: BonjourService.TxtDataRecord) {
        guard let indexToRemove = viewModel.dataRecords.firstIndex(where: { record in
            record.key == dataRecord.key
        }) else { return }
        withAnimation(reduceMotion ? nil : .default) {
            // `Array.remove(at:)` returns the removed element;
            // Xcode 27's `#NoUsage` diagnostic flags discarded
            // results from `withAnimation` single-expression
            // closures. Discard explicitly.
            _ = viewModel.dataRecords.remove(at: indexToRemove)
        }
    }
}

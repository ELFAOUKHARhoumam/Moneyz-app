import SwiftUI
import SwiftData

// MARK: - ArchivedPeopleView
// Gap 10 fix: PersonProfile.isArchived existed in the model and BudgetRepository.archivePerson
// set it, but no UI showed archived people or let users unarchive them. Archived people
// disappeared silently with no recovery path — effectively a silent delete.
//
// This view is accessible from BudgetView via a "Show Archived" toolbar button, only
// shown when at least one archived person exists. This keeps the main budget list clean
// while providing a clear recovery path.

@MainActor
struct ArchivedPeopleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: SettingsStore

    @Query(
        filter: #Predicate<PersonProfile> { $0.isArchived == true },
        sort: [SortDescriptor<PersonProfile>(\.name)]
    )
    private var archivedPeople: [PersonProfile]

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            if archivedPeople.isEmpty {
                EmptyStateView(
                    systemImage: "archivebox",
                    titleKey: "budget.archived.empty.title",
                    messageKey: "budget.archived.empty.message"
                )
                .padding(20)
            } else {
                List {
                    Section {
                        ForEach(archivedPeople, id: \.id) { person in
                            archivedPersonRow(person)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        }
                    } header: {
                        Text(AppLocalizer.string("budget.archived.hint"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 6)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(Text(AppLocalizer.string("budget.archived.title")))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(AppLocalizer.string("common.done")) { dismiss() }
            }
        }
    }

    // MARK: - Row

    private func archivedPersonRow(_ person: PersonProfile) -> some View {
        HStack(spacing: 14) {
            PremiumTheme.IconBadge(
                systemImage: "person.fill",
                colors: [Color.secondary.opacity(0.5), Color.secondary.opacity(0.3)],
                size: 44,
                symbolSize: 16
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("\(person.emoji) \(person.name)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if let budget = person.activeBudget {
                    Text(
                        CurrencyFormatter.string(
                            from: budget.amountMinor,
                            currencyCode: settings.currencyCode,
                            locale: settings.locale
                        )
                        + " / " + AppLocalizer.string(budget.period.localizedKey)
                    )
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button {
                unarchive(person)
            } label: {
                Label(AppLocalizer.string("budget.archived.restore"), systemImage: "arrow.uturn.backward.circle.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .premiumCapsule()
        }
        .padding(PremiumTheme.Spacing.md)
        .premiumCard(cornerRadius: PremiumTheme.CornerRadius.md, padding: 0)
    }

    // MARK: - Unarchive

    private func unarchive(_ person: PersonProfile) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            person.isArchived = false
            do {
                try modelContext.save()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                // Surface silently — the person remains archived and reappears on next launch.
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}

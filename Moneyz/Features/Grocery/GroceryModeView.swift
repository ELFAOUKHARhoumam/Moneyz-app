import SwiftUI
import SwiftData

@MainActor
struct GroceryModeView: View {
    init() {
        _viewModel = StateObject(wrappedValue: GroceryViewModel())
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: [SortDescriptor<GroceryList>(\.updatedAt, order: .reverse)])
    private var lists: [GroceryList]

    @Query(sort: [SortDescriptor<GroceryPresetItem>(\.lastUsedAt, order: .reverse), SortDescriptor<GroceryPresetItem>(\.createdAt, order: .reverse)])
    private var presets: [GroceryPresetItem]

    @StateObject private var viewModel: GroceryViewModel

    private var currentList: GroceryList? {
        viewModel.currentList(from: lists)
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if let currentList {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(currentList.title)
                                    .font(.title2.weight(.bold))
                                Spacer()
                                Button {
                                    viewModel.startNewList(from: currentList, in: modelContext)
                                } label: {
                                    Label(AppLocalizer.string("grocery.newWeek"), systemImage: "arrow.clockwise")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .buttonStyle(.plain)
                                .premiumCapsule()
                            }

                            Text(currentList.updatedAt, format: .dateTime.day().month().year())
                                .font(.caption)
                                .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
                        }
                        .premiumCard(cornerRadius: 26, padding: 18)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(AppLocalizer.string("grocery.quickAdd"))
                                .font(.headline)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(presets, id: \.id) { preset in
                                        Button {
                                            viewModel.quickAdd(preset: preset, to: currentList, in: modelContext)
                                        } label: {
                                            Text("\(preset.emoji) \(preset.name)")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .buttonStyle(.plain)
                                        .premiumCapsule()
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .premiumCard(cornerRadius: 26, padding: 18)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(AppLocalizer.string("grocery.addItem"))
                                .font(.headline)

                            VStack(spacing: 12) {
                                TextField(AppLocalizer.string("grocery.itemName"), text: $viewModel.itemName)
                                    .textFieldStyle(.roundedBorder)

                                HStack {
                                    TextField(AppLocalizer.string("grocery.group"), text: $viewModel.groupName)
                                        .textFieldStyle(.roundedBorder)

                                    TextField(AppLocalizer.string("grocery.emoji"), text: $viewModel.emoji)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 72)
                                }

                                Toggle(AppLocalizer.string("grocery.saveReusable"), isOn: $viewModel.saveAsPreset)

                                Button {
                                    viewModel.addCustomItem(to: currentList, in: modelContext)
                                } label: {
                                    Label(AppLocalizer.string("grocery.addToList"), systemImage: "plus.circle.fill")
                                }
                                .premiumPrimaryButton()
                            }
                        }
                        .premiumCard(cornerRadius: 26, padding: 18)

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(PremiumTheme.Palette.danger)
                        }

                        let groupedItems = viewModel.groupedItems(for: currentList)
                        if groupedItems.isEmpty {
                            EmptyStateView(
                                systemImage: "cart",
                                titleKey: "grocery.empty.title",
                                messageKey: "grocery.empty.message"
                            )
                        } else {
                            ForEach(groupedItems, id: \.group) { group in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(group.group)
                                        .font(.headline)
                                        .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

                                    ForEach(group.items, id: \.id) { item in
                                        Button {
                                            viewModel.toggle(item, in: modelContext)
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                                    .font(.title3)
                                                    .foregroundStyle(item.isChecked ? PremiumTheme.Palette.success : .secondary)

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("\(item.emoji) \(item.name)")
                                                        .font(.body.weight(.semibold))
                                                        .strikethrough(item.isChecked)

                                                    if !item.note.isEmpty {
                                                        Text(item.note)
                                                            .font(.caption)
                                                            .foregroundStyle(.secondary)
                                                    }
                                                }

                                                Spacer()
                                            }
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)

                                        if item.id != group.items.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                                .premiumCard(cornerRadius: 24, padding: 16)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text(AppLocalizer.string("grocery.presetManager"))
                                .font(.headline)

                            TextField(AppLocalizer.string("grocery.itemName"), text: $viewModel.presetName)
                                .textFieldStyle(.roundedBorder)

                            HStack {
                                TextField(AppLocalizer.string("grocery.group"), text: $viewModel.presetGroupName)
                                    .textFieldStyle(.roundedBorder)

                                TextField(AppLocalizer.string("grocery.emoji"), text: $viewModel.presetEmoji)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 72)
                            }

                            Button {
                                viewModel.addPreset(in: modelContext)
                            } label: {
                                Label(AppLocalizer.string("grocery.savePreset"), systemImage: "square.and.arrow.down")
                            }
                            .premiumPrimaryButton()
                        }
                        .premiumCard(cornerRadius: 26, padding: 18)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(Text(AppLocalizer.string("grocery.title")))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(AppLocalizer.string("common.done")) {
                    dismiss()
                }
            }
        }
        .task {
            viewModel.ensureActiveList(from: lists, in: modelContext)
        }
        .onChange(of: lists.count) { _, _ in
            viewModel.ensureActiveList(from: lists, in: modelContext)
        }
    }
}

@MainActor
private struct GroceryModeViewPreviewHost: View {
    var body: some View {
        NavigationStack {
            GroceryModeView()
        }
        .modelContainer(PreviewContainer.modelContainer)
    }
}

#Preview {
    GroceryModeViewPreviewHost()
}

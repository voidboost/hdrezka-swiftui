import SwiftUI

extension View {
    func dataStateOverlay<T: Collection & Equatable>(
        _ state: DataState<T>,
        empty description: String,
        _ subdescription: String? = nil,
        retriesWhenEmpty: Bool = true,
        padding: EdgeInsets = EdgeInsets(top: 18, leading: 36, bottom: 18, trailing: 36),
        retry: @escaping () -> Void
    ) -> some View {
        overlay {
            Group {
                if let error = state.error {
                    ErrorStateView(error, retry)
                } else if let data = state.data, data.isEmpty {
                    EmptyStateView(description, subdescription, retriesWhenEmpty ? retry : nil)
                } else if state.isLoading {
                    LoadingStateView()
                }
            }
            .padding(padding)
        }
    }
}

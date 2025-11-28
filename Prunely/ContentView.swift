//
//  ContentView.swift
//  Prunely
//

import SwiftUI
import Photos

enum LibraryTab: String, CaseIterable {
    case months = "Months"
    case utilities = "Utilities"
    case albums = "Albums"
    
    var icon: String {
        switch self {
        case .months: return "calendar"
        case .utilities: return "folder.fill"
        case .albums: return "photo.on.rectangle"
        }
    }
}

struct ContentView: View {
    @StateObject private var photoLibrary = PhotoLibraryManager()
    @State private var selectedTab: LibraryTab = .months
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Persistent Top Bar with Tabs
                TopBar(selectedTab: $selectedTab)

                // Main Content
                Group {
                    switch photoLibrary.authorizationStatus {
                    case .authorized, .limited:
                        TabContentView(selectedTab: selectedTab, photoLibrary: photoLibrary)
                        
                    case .denied, .restricted:
                        VStack(spacing: 20) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.red)
                            Text("Photo Library Access Denied")
                                .font(.title2)
                            Text("Enable access in System Settings > Privacy & Security > Photos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                        
                    case .notDetermined:
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 60))
                                .foregroundStyle(.blue)
                            Text("Prunely needs access to your Photos")
                                .font(.title2)
                            Button("Grant Access") {
                                photoLibrary.requestAccess()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                        
                    @unknown default:
                        Text("Unknown status")
                    }
                }
            }
            .frame(minWidth: 600, minHeight: 400)
            .toolbar(.hidden)
        }
        .onAppear {
            photoLibrary.checkAuthorizationStatus()
            if photoLibrary.authorizationStatus == .authorized || photoLibrary.authorizationStatus == .limited {
                photoLibrary.fetchAlbums()
            }
        }
    }
}

struct TopBar: View {
    @Binding var selectedTab: LibraryTab
    
    var body: some View {
        HStack {
            // App name
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.green)
                Text("Prunely")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Tab buttons
            HStack(spacing: 4) {
                ForEach(LibraryTab.allCases, id: \.self) { tab in
                    TabButton(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }
            
            Spacer()
            
            // Placeholder for symmetry
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.clear)
                Text("Prunely")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

struct TabButton: View {
    let tab: LibraryTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12))
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.accentColor.opacity(0.15) :
                isHovered ? Color.primary.opacity(0.08) : Color.clear
            )
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct TabContentView: View {
    let selectedTab: LibraryTab
    @ObservedObject var photoLibrary: PhotoLibraryManager
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch selectedTab {
                case .months:
                    MonthsGridView(photoLibrary: photoLibrary, columns: columns)
                case .utilities:
                    UtilitiesGridView(photoLibrary: photoLibrary, columns: columns)
                case .albums:
                    AlbumsGridView(photoLibrary: photoLibrary, columns: columns)
                }
            }
            .padding(20)
        }
    }
}

struct MonthsGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    let columns: [GridItem]
    
    var body: some View {
        if photoLibrary.monthAlbums.isEmpty {
            EmptyStateView(title: "No Photos", message: "Your photo library is empty")
        } else {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(photoLibrary.monthAlbums) { monthAlbum in
                    NavigationLink(destination: MonthAlbumDetailView(monthAlbum: monthAlbum, photoLibrary: photoLibrary)) {
                        MonthAlbumThumbnail(monthAlbum: monthAlbum, photoLibrary: photoLibrary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct UtilitiesGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    let columns: [GridItem]
    
    var body: some View {
        if photoLibrary.utilityAlbums.isEmpty {
            EmptyStateView(title: "No Utility Albums", message: "No system albums found")
        } else {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(photoLibrary.utilityAlbums, id: \.localIdentifier) { album in
                    NavigationLink(destination: AlbumDetailView(album: album, photoLibrary: photoLibrary)) {
                        AlbumThumbnail(album: album, photoLibrary: photoLibrary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct AlbumsGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    let columns: [GridItem]
    
    var body: some View {
        if photoLibrary.userAlbums.isEmpty {
            EmptyStateView(title: "No Albums", message: "You haven't created any albums yet")
        } else {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(photoLibrary.userAlbums, id: \.localIdentifier) { album in
                    NavigationLink(destination: AlbumDetailView(album: album, photoLibrary: photoLibrary)) {
                        AlbumThumbnail(album: album, photoLibrary: photoLibrary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

struct MonthAlbumThumbnail: View {
    let monthAlbum: MonthAlbum
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @State private var coverImage: NSImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image
            Group {
                if let image = coverImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Month name
            Text(monthAlbum.title)
                .font(.headline)
                .lineLimit(1)
            
            // Photo count
            Text("\(monthAlbum.photoCount) photos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            loadCoverImage()
        }
    }
    
    private func loadCoverImage() {
        guard let coverAsset = monthAlbum.coverPhoto else { return }
        photoLibrary.loadThumbnail(for: coverAsset, size: CGSize(width: 320, height: 320)) { image in
            DispatchQueue.main.async {
                self.coverImage = image
            }
        }
    }
}

struct AlbumThumbnail: View {
    let album: PHAssetCollection
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @State private var coverImage: NSImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image
            Group {
                if let image = coverImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Album name
            Text(album.localizedTitle ?? "Untitled")
                .font(.headline)
                .lineLimit(1)
            
            // Photo count
            Text("\(photoLibrary.getPhotoCount(for: album)) photos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            loadCoverImage()
        }
    }
    
    private func loadCoverImage() {
        guard let coverAsset = photoLibrary.getCoverPhoto(for: album) else { return }
        photoLibrary.loadThumbnail(for: coverAsset, size: CGSize(width: 320, height: 320)) { image in
            DispatchQueue.main.async {
                self.coverImage = image
            }
        }
    }
}

#Preview {
    ContentView()
}

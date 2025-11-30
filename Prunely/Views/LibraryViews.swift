//
//  LibraryViews.swift
//  Prunely
//

import SwiftUI
import Photos

struct MediaGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    let columns: [GridItem]
    
    @State private var selectedAlbum: PHAssetCollection?
    
    private var albumsWithUnreviewedPhotos: [PHAssetCollection] {
        photoLibrary.utilityAlbums.filter { album in
            let allPhotos = photoLibrary.fetchPhotos(in: album)
            return allPhotos.contains { asset in
                !decisionStore.isReviewed(asset.localIdentifier)
            }
        }
    }
    
    var body: some View {
        if albumsWithUnreviewedPhotos.isEmpty {
            EmptyStateView(title: "All Done!", message: "You've reviewed all media albums")
        } else {
            VStack(spacing: 10) {
                VStack(spacing: 4) {
                    Text("Media")
                        .font(.system(size: 28, weight: .semibold))
                    
                    Text("\(albumsWithUnreviewedPhotos.count) albums")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albumsWithUnreviewedPhotos, id: \.localIdentifier) { album in
                        AlbumThumbnail(album: album, photoLibrary: photoLibrary, decisionStore: decisionStore)
                            .onTapGesture {
                                selectedAlbum = album
                            }
                    }
                }
            }
            .navigationDestination(item: $selectedAlbum) { album in
                // Pass all photos - filtering handled by PhotoReviewView toggle
                let allPhotos = photoLibrary.fetchPhotos(in: album)
                PhotoReviewView(
                    albumTitle: album.localizedTitle ?? "Album",
                    photos: allPhotos,
                    photoLibrary: photoLibrary,
                    decisionStore: decisionStore
                )
            }
        }
    }
}

struct AlbumsGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    let columns: [GridItem]
    
    @State private var selectedAlbum: PHAssetCollection?
    
    private var albumsWithUnreviewedPhotos: [PHAssetCollection] {
        photoLibrary.userAlbums.filter { album in
            let allPhotos = photoLibrary.fetchPhotos(in: album)
            return allPhotos.contains { asset in
                !decisionStore.isReviewed(asset.localIdentifier)
            }
        }
    }
    
    var body: some View {
        if albumsWithUnreviewedPhotos.isEmpty {
            EmptyStateView(title: "All Done!", message: "You've reviewed all your albums")
        } else {
            VStack(spacing: 10) {
                VStack(spacing: 4) {
                    Text("Albums")
                        .font(.system(size: 28, weight: .semibold))
                    
                    Text("\(albumsWithUnreviewedPhotos.count) albums")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albumsWithUnreviewedPhotos, id: \.localIdentifier) { album in
                        AlbumThumbnail(album: album, photoLibrary: photoLibrary, decisionStore: decisionStore)
                            .onTapGesture {
                                selectedAlbum = album
                            }
                    }
                }
            }
            .navigationDestination(item: $selectedAlbum) { album in
                // Pass all photos - filtering handled by PhotoReviewView toggle
                let allPhotos = photoLibrary.fetchPhotos(in: album)
                PhotoReviewView(
                    albumTitle: album.localizedTitle ?? "Album",
                    photos: allPhotos,
                    photoLibrary: photoLibrary,
                    decisionStore: decisionStore
                )
            }
        }
    }
}

struct MonthsGridView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    let columns: [GridItem]
    
    @State private var selectedMonthAlbum: MonthAlbum?
    
    private var albumsWithUnreviewedPhotos: [MonthAlbum] {
        photoLibrary.monthAlbums.filter { monthAlbum in
            monthAlbum.photos.contains { asset in
                !decisionStore.isReviewed(asset.localIdentifier)
            }
        }
    }
    
    var body: some View {
        if albumsWithUnreviewedPhotos.isEmpty {
            EmptyStateView(title: "All Done!", message: "You've reviewed all photos in your library")
        } else {
            VStack(spacing: 10) {
                VStack(spacing: 4) {
                    Text("Months")
                        .font(.system(size: 28, weight: .semibold))
                    
                    Text("\(albumsWithUnreviewedPhotos.count) albums")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albumsWithUnreviewedPhotos) { monthAlbum in
                        MonthAlbumThumbnail(monthAlbum: monthAlbum, photoLibrary: photoLibrary, decisionStore: decisionStore)
                            .onTapGesture {
                                selectedMonthAlbum = monthAlbum
                            }
                    }
                }
            }
            .navigationDestination(
                isPresented: Binding<Bool>(
                    get: { selectedMonthAlbum != nil },
                    set: { if !$0 { selectedMonthAlbum = nil } }
                )
            ) {
                if let monthAlbum = selectedMonthAlbum {
                    // Pass all photos - filtering handled by PhotoReviewView toggle
                    PhotoReviewView(
                        albumTitle: monthAlbum.title,
                        photos: monthAlbum.photos,
                        photoLibrary: photoLibrary,
                        decisionStore: decisionStore
                    )
                }
            }
        }
    }
}

struct MonthAlbumThumbnail: View {
    let monthAlbum: MonthAlbum
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    @State private var coverImage: NSImage?
    @State private var isHovered = false
    
    private var unreviewedCount: Int {
        monthAlbum.photos.filter { asset in
            !decisionStore.isReviewed(asset.localIdentifier)
        }.count
    }
    
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
                .padding(.bottom, 0)
            
            // Photo count (unreviewed)
            Text("\(unreviewedCount) photos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.primary.opacity(0.03) : Color.clear)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(color: .black.opacity(isHovered ? 0.15 : 0), radius: 10, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
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
    @ObservedObject var decisionStore: PhotoDecisionStore
    @State private var coverImage: NSImage?
    @State private var isHovered = false
    
    private var unreviewedCount: Int {
        let allPhotos = photoLibrary.fetchPhotos(in: album)
        return allPhotos.filter { asset in
            !decisionStore.isReviewed(asset.localIdentifier)
        }.count
    }
    
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
                .padding(.bottom, 0)
            
            // Photo count (unreviewed)
            Text("\(unreviewedCount) photos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.primary.opacity(0.03) : Color.clear)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(color: .black.opacity(isHovered ? 0.15 : 0), radius: 10, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
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


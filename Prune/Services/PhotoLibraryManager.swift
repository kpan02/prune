//
//  PhotoLibraryManager.swift
//  Prune
//

import AppKit
import Combine
import OSLog
import Photos
import PhotosUI

struct MonthAlbum: Identifiable {
    let id: String
    let title: String
    let date: Date
    let photos: [PHAsset]

    var coverPhoto: PHAsset? {
        photos.first
    }

    var photoCount: Int {
        photos.count
    }
}

@MainActor
class PhotoLibraryManager: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var monthAlbums: [MonthAlbum] = []
    @Published var utilityAlbums: [PHAssetCollection] = []
    @Published var userAlbums: [PHAssetCollection] = []

    private let imageManager = PHCachingImageManager()
    private var albumPhotosCache: [String: [PHAsset]] = [:]
    private let logger = Logger(subsystem: "com.prune.app", category: "PhotoLibraryManager")
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    override init() {
        super.init()
        checkAuthorizationStatus()
        PHPhotoLibrary.shared().register(self)
    }

    nonisolated deinit {
        unregisterObserver()
    }

    private nonisolated func unregisterObserver() {
        if let observer = self as AnyObject as? PHPhotoLibraryChangeObserver {
            PHPhotoLibrary.shared().unregisterChangeObserver(observer)
        } else {
            assertionFailure("PhotoLibraryManager should always conform to PHPhotoLibraryChangeObserver")
        }
    }

    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            Task { @MainActor in
                self.authorizationStatus = status
                if status == .authorized || status == .limited {
                    self.fetchAlbums()
                }
            }
        }
    }

    func fetchAlbums() {
        albumPhotosCache.removeAll()
        fetchMonthAlbums()
        fetchUtilityAndUserAlbums()
    }

    private func fetchMonthAlbums() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let results = PHAsset.fetchAssets(with: fetchOptions)

        // Group photos by month
        var groupedPhotos: [String: (date: Date, photos: [PHAsset])] = [:]
        let calendar = Calendar.current

        results.enumerateObjects { asset, _, _ in
            guard let creationDate = asset.creationDate else { return }

            let components = calendar.dateComponents([.year, .month], from: creationDate)
            guard let year = components.year, let month = components.month else { return }

            let key = "\(year)-\(String(format: "%02d", month))"

            if groupedPhotos[key] == nil {
                // Use first day of month for sorting
                let monthDate = calendar.date(from: components) ?? creationDate
                groupedPhotos[key] = (date: monthDate, photos: [])
            }
            groupedPhotos[key]?.photos.append(asset)
        }

        // Convert to MonthAlbum array and sort by date (newest first)
        monthAlbums = groupedPhotos.map { key, value in
            MonthAlbum(
                id: key,
                title: dateFormatter.string(from: value.date),
                date: value.date,
                photos: value.photos
            )
        }.sorted { $0.date > $1.date }
    }

    private func fetchUtilityAndUserAlbums() {
        var utilities: [PHAssetCollection] = []
        var user: [PHAssetCollection] = []

        // Fetch utility albums (Recents, Favorites, Screenshots, etc.)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: nil
        )
        smartAlbums.enumerateObjects { collection, _, _ in
            // Only include albums that have photos (images only)
            let imageFetchOptions = PHFetchOptions()
            imageFetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let assetCount = PHAsset.fetchAssets(in: collection, options: imageFetchOptions).count
            if assetCount > 0 {
                utilities.append(collection)
            }
        }

        // Fetch user-created albums (excluding shared albums)
        let albums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )
        albums.enumerateObjects { collection, _, _ in
            // Skip shared albums
            if collection.assetCollectionSubtype == .albumCloudShared {
                return
            }
            let imageFetchOptions = PHFetchOptions()
            imageFetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let assetCount = PHAsset.fetchAssets(in: collection, options: imageFetchOptions).count
            if assetCount > 0 {
                user.append(collection)
            }
        }

        utilityAlbums = utilities
        userAlbums = user
    }

    func fetchPhotos(in album: PHAssetCollection) -> [PHAsset] {
        // Return cached photos if available
        if let cached = albumPhotosCache[album.localIdentifier] {
            return cached
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let results = PHAsset.fetchAssets(in: album, options: fetchOptions)

        var assets: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        // Cache results for subsequent calls
        albumPhotosCache[album.localIdentifier] = assets

        return assets
    }

    func loadThumbnail(for asset: PHAsset, size: CGSize, completion: @escaping (NSImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic

        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    func loadHighQualityImage(for asset: PHAsset, completion: @escaping (NSImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true // Allow downloading from iCloud if needed
        options.resizeMode = .fast

        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 2000, height: 2000),
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            // Check for errors
            if let error = info?[PHImageErrorKey] as? Error {
                self.logger.error("Error loading image: \(error.localizedDescription, privacy: .public)")
                completion(nil)
                return
            }

            // Check if this is a degraded/low-quality version
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false

            // Only complete with high-quality images or if we got an error
            if !isDegraded || image == nil {
                completion(image)
            }
        }
    }

    func getCoverPhoto(for album: PHAssetCollection) -> PHAsset? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1

        let results = PHAsset.fetchAssets(in: album, options: fetchOptions)
        return results.firstObject
    }

    /// Gets the file size of a photo asset.
    ///
    /// **Type Conversion Complexity:**
    /// The `PHAssetResource.value(forKey: "fileSize")` method returns different types depending on:
    /// - Platform (macOS vs iOS)
    /// - Photo source (local vs iCloud)
    /// - Photo format (HEIC, JPEG, RAW, etc.)
    ///
    /// This method attempts multiple type conversions to handle all cases:
    /// - `NSNumber` (most common on macOS)
    /// - `Int` (32-bit platforms or certain formats)
    /// - `Int64` (64-bit platforms)
    /// - `UInt64` (unsigned representation)
    ///
    /// Returns `nil` if the file size cannot be determined (e.g., iCloud-only photos
    /// that haven't been downloaded, or unsupported formats).
    ///
    /// - Parameter asset: The photo asset to get the file size for
    /// - Returns: The file size in bytes, or `nil` if unavailable
    func getFileSize(for asset: PHAsset) -> Int64? {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first else { return nil }

        // Try multiple type conversions for fileSize (can be NSNumber, Int, Int64, etc.)
        // This handles platform differences and various photo formats
        if let fileSizeValue = resource.value(forKey: "fileSize") {
            if let number = fileSizeValue as? NSNumber {
                return number.int64Value
            } else if let intValue = fileSizeValue as? Int {
                return Int64(intValue)
            } else if let int64Value = fileSizeValue as? Int64 {
                return int64Value
            } else if let uint64Value = fileSizeValue as? UInt64 {
                return Int64(uint64Value)
            }
        }
        return nil
    }

    /// Fetches photos by their local identifiers, filtering out any that no longer exist.
    ///
    /// **Orphaned IDs occur when:**
    /// - Photos are deleted outside of the app (e.g., in Photos app, iCloud sync)
    /// - Photos are removed from the library entirely
    /// - Photos are moved to different albums or collections (though IDs usually persist)
    ///
    /// **Returns:**
    /// - `photos`: Array of valid `PHAsset` objects that were found
    /// - `orphanedIDs`: Set of photo IDs that were requested but no longer exist in the library
    ///
    /// Callers should handle orphaned IDs by removing them from their data structures
    /// (e.g., `PhotoDecisionStore` removes them from archived/trashed sets).
    ///
    /// - Parameter photoIDs: Set of local identifiers to fetch
    /// - Returns: Tuple containing valid photos and orphaned IDs
    func fetchPhotos(byIDs photoIDs: Set<String>) -> (photos: [PHAsset], orphanedIDs: Set<String>) {
        guard !photoIDs.isEmpty else {
            return ([], [])
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let results = PHAsset.fetchAssets(withLocalIdentifiers: Array(photoIDs), options: fetchOptions)

        var validPhotos: [PHAsset] = []
        var foundIDs: Set<String> = []

        results.enumerateObjects { asset, _, _ in
            validPhotos.append(asset)
            foundIDs.insert(asset.localIdentifier)
        }

        // Find orphaned IDs (IDs that were requested but not found)
        let orphanedIDs = photoIDs.subtracting(foundIDs)

        return (validPhotos, orphanedIDs)
    }

    func toggleFavorite(for asset: PHAsset, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = !asset.isFavorite
        } completionHandler: { success, error in
            if let error = error {
                self.logger.error("Failed to toggle favorite: \(error.localizedDescription, privacy: .public)")
            }
            Task { @MainActor in
                completion(success)
            }
        }
    }

    // MARK: - PHPhotoLibraryChangeObserver

    /// Called when the photo library changes (photos added, deleted, modified, etc.).
    ///
    /// **Current Implementation:**
    /// - Only refreshes the album list by calling `fetchAlbums()`
    /// - Does not handle individual asset property changes (e.g., favorite status)
    ///
    /// **Limitations:**
    /// - Individual asset changes (like favorite toggles) are not automatically reflected
    /// - Views must manually refetch assets to see property updates
    /// - This is why `PhotoReviewView.handleToggleFavorite()` manually refetches the asset
    ///
    /// **Future Enhancement:**
    /// Could inspect `PHChange` details to update specific assets or albums more granularly,
    /// but the current approach of full refresh is simpler and sufficient for most use cases.
    func photoLibraryDidChange(_: PHChange) {
        Task { @MainActor in
            self.fetchAlbums()
        }
    }
}

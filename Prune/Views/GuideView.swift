//
//  GuideView.swift
//  Prune
//

import SwiftUI
import AppKit

struct GuideView: View {
    // MARK: - Layout Constants
    
    // Font Sizes
    private let sectionHeadingSize: CGFloat = 26
    private let subsectionHeadingSize: CGFloat = 22
    private let subheadingSize: CGFloat = 20
    private let bodyTextSize: CGFloat = 16
    
    // Spacing
    private let sectionSpacing: CGFloat = 40
    private let sectionInternalSpacing: CGFloat = 12
    private let bulletListSpacing: CGFloat = 8
    private let nestedBulletSpacing: CGFloat = 4
    private let subsectionTopPadding: CGFloat = 8
    private let githubLinkTopPadding: CGFloat = 8
    private let hStackSpacing: CGFloat = 8
    
    // Layout
    private let maxContentWidth: CGFloat = 700
    private let logoSize: CGFloat = 120
    
    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .leading, spacing: sectionSpacing) {
                Spacer()
                    .frame(height: 30) // top padding

                // Welcome to Prune
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    // Logo
                    HStack {
                        Spacer()
                        Group {
                            if let appIcon = NSImage(named: "AppIcon") ?? NSImage(named: NSImage.applicationIconName) {
                                Image(nsImage: appIcon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: logoSize, height: logoSize)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 30)
                    
                    Text("Welcome to Prune")
                        .font(.system(size: 35, weight: .semibold))
                    
                    Text("Prune is a macOS app designed to help you review and clean your photo library efficiently. Review photos one by one, decide what to keep or delete, and track your progress. Nothing is permanently deleted until you're ready.")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Requirements
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Requirements")
                        .font(.system(size: sectionHeadingSize, weight: .semibold))
                    
                    Text("Prune only works with photos in your Mac's Photos library. Please enable iCloud Photos to sync your iPhone photos to your Mac.")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Note: Prune only reviews photos. Videos are excluded.")
                        .font(.system(size: 14))
                        .italic()
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Photo Library Views
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Photo Library Views")
                        .font(.system(size: sectionHeadingSize, weight: .semibold))
                    
                    Text("Prune organizes your photos in three ways to suit different workflows:")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(alignment: .leading, spacing: bulletListSpacing) {
                        Text("**Media**: Default Apple albums like Recents, Favorites, Screenshots")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("**Albums**: User-created albums")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("**Months**: Your entire photo library organized by month and year")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 0)
                }
                
                // Photo Review Mode
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Photo Review Mode")
                        .font(.system(size: sectionHeadingSize, weight: .semibold))
                    
                    Text("Click any album from any of the three library views to start reviewing photos.")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("How it works")
                        .font(.system(size: subheadingSize, weight: .semibold))
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                        VStack(alignment: .leading, spacing: nestedBulletSpacing) {
                            Text("• Review each photo in sequence using the **Keep** or **Delete** actions")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("  - Photos you keep go to **Archive**; photos you delete go to **Trash**")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Text("• Use **arrow keys** to navigate quickly (← → to move, ↑ to Keep, ↓ to Delete).")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("• Change your mind? **Clear** any decision anytime")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("• Enable **Hide Reviewed** to focus only on photos you haven't reviewed yet")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("• Use the filmstrip to browse all photos, see your decisions, and jump to any photo without leaving the flow")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 0)
                }
                
                // Managing Your Decisions
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Managing Your Decisions")
                        .font(.system(size: sectionHeadingSize, weight: .semibold))
                    
                    Text("Prune has two holding areas for your review decisions. Nothing is permanently deleted until you choose.")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Archive subsection
                    VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                        Text("Archive")
                            .font(.system(size: subsectionHeadingSize, weight: .semibold))
                            .padding(.top, subsectionTopPadding)
                        
                        Text("Photos you mark as **Keep** during review go to Archive")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        VStack(alignment: .leading, spacing: bulletListSpacing) {
                            Text("• Archived photos are automatically hidden when you enable **Hide Reviewed** in the photo review mode")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("• Restore individual photos from Archive, or restore all to reset your entire progress")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("• To unarchive specific months or albums: go to the Months or Albums view, toggle **Hide Reviewed Albums** (top right), then hover over the album to reveal the **Unarchive Album** button.")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, 0)
                    }
                    
                    // Trash subsection
                    VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                        Text("Trash")
                            .font(.system(size: subsectionHeadingSize, weight: .semibold))
                            .padding(.top, subsectionTopPadding)
                        
                        Text("Photos you mark as **Delete** during review go to Trash")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        VStack(alignment: .leading, spacing: bulletListSpacing) {
                            Text("• Restore individual photos or restore all from Trash")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("• **Empty Trash** to permanently delete all trashed photos. They'll be sent to Recently Deleted in your Photos library (standard Photos behavior)")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, 0)
                    }
                }
                
                // Dashboard
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Dashboard")
                        .font(.system(size: sectionHeadingSize, weight: .semibold))
                    
                    Text("Track your review progress and library statistics.")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Data & Privacy
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Data & Privacy")
                        .font(.system(size: sectionHeadingSize, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                        Text("Prune needs Photos library access to read and manage your photos. You can control this anytime in System Settings > Privacy & Security > Photos.")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Prune does not store or share any of your photos. It accesses them directly from your Photos library using Apple's Photos framework.")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Prune stores your review decisions (which photos you've kept or deleted) locally on your Mac. All data is stored in ~/Library/Application Support/Prune/decisions.json and never leaves your device. This data file only stores the ID of your reviewed photos; it does not store the image itself or any of its metadata.")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // GitHub link
                HStack(alignment: .top, spacing: hStackSpacing) {
                    Text("🤓")
                        .font(.system(size: bodyTextSize))
                    HStack(spacing: nestedBulletSpacing) {
                        Text("Interested in this project? Check out the repo here:")
                            .font(.system(size: bodyTextSize))
                        Link("https://github.com/kpan02/prune", destination: URL(string: "https://github.com/kpan02/prune")!)
                            .font(.system(size: bodyTextSize))
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, githubLinkTopPadding)
            }
            .frame(maxWidth: maxContentWidth) // Constrain width for centered, readable content
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GuideView()
}


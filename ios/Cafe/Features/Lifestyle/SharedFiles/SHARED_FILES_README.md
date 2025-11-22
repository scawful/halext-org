# Shared Files Feature

A comprehensive file storage and sharing system for the Cafe iOS app with iCloud sync and Files app integration.

## Features

### File Management
- **Upload Files**: Support for all document types (PDFs, images, documents, videos, audio, archives, code files)
- **Download Files**: Quick access to download and view files
- **Delete Files**: Remove files with confirmation
- **File Preview**: Quick Look integration for supported file types
- **Thumbnails**: Automatic thumbnail generation for images

### View Modes
- **Grid View**: Visual card-based layout
- **List View**: Compact list layout
- **Toggle**: Easy switching between views

### Organization
- **Categories**: Automatic categorization (Documents, Images, Videos, Audio, Archives, Code)
- **Tags**: Custom tagging system for better organization
- **Search**: Real-time search by filename and tags
- **Sort Options**:
  - Name (A-Z, Z-A)
  - Date (Newest, Oldest)
  - Size (Smallest, Largest)
  - Category

### iCloud Integration
- **CloudKit Sync**: Automatic syncing across devices
- **Sync Status**: Real-time sync status indicators
- **Offline Support**: Access files locally when offline
- **Account Status**: iCloud availability monitoring

### Files App Integration
- **Document Picker**: Choose files from Files app
- **Export**: Save files to Files app
- **Share Sheet**: Share files via iOS share sheet
- **Open in Place**: Work with files directly in their storage location

### Sharing & Permissions
- **User Sharing**: Share files with specific users
- **Public Access**: Make files publicly accessible
- **Shared With List**: View who has access to files
- **Upload Metadata**: Track who uploaded and when

## Architecture

### Models
- `SharedFile`: Main file model with CloudKit support
- `FileCategory`: Categorization system
- `SyncStatus`: Sync state tracking
- `FileSortOption`: Sorting options
- `FileViewMode`: View mode selection

### Managers
- `CloudKitManager`: Handles all CloudKit operations
  - Upload/download files
  - Fetch all files
  - Update file metadata
  - Delete files
  - Share files
  - Account status monitoring

- `LocalFileStorageManager`: Local file persistence
  - Save files to documents directory
  - Load/save file metadata
  - JSON-based metadata storage

### ViewModels
- `SharedFilesViewModel`: Business logic layer
  - File operations (upload, download, delete)
  - Filtering and sorting
  - Search functionality
  - Sync management
  - Error handling

### Views
- `SharedFilesView`: Main file browser
  - Grid/list toggle
  - Search bar
  - Sort and filter controls
  - Stats header
  - iCloud status indicator

- `FileDetailView`: Detailed file view
  - File preview
  - Information display
  - Actions (download, export, delete)
  - Sharing controls
  - Metadata display

## Setup

### iCloud Entitlements
The app includes the following iCloud capabilities:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.org.halext.Cafe</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
<key>com.apple.developer.ubiquity-container-identifiers</key>
<array>
    <string>iCloud.org.halext.Cafe</string>
</array>
```

### Required Configurations
1. **Xcode Project**: Enable iCloud capability in Signing & Capabilities
2. **CloudKit Container**: Use `iCloud.org.halext.Cafe`
3. **CloudKit Schema**: Create `SharedFile` record type with fields:
   - name (String)
   - fileExtension (String)
   - size (Int64)
   - mimeType (String)
   - category (String)
   - tags (List<String>)
   - uploadedBy (String)
   - uploadedByUserId (Int64)
   - uploadedAt (Date)
   - modifiedAt (Date)
   - sharedWith (List<String>)
   - isPublic (Int64)
   - fileData (Asset)
   - thumbnailData (Bytes)

## Usage

### Accessing Shared Files
Navigate to **More** tab → **Shared Files**

### Uploading Files
1. Tap the **+** button in toolbar
2. Select **Choose from Files**
3. Pick one or more files
4. Files are automatically uploaded and synced

### Viewing Files
- Tap any file card to view details
- Use **Quick Look** button for preview
- View file information, sharing, and metadata

### Searching and Filtering
- Use search bar for real-time filtering
- Tap filter button to select category
- Tap sort button to change sort order

### Sharing Files
1. Open file details
2. Tap **Manage** in Sharing section
3. Add usernames to share with
4. Toggle public access if needed

### Exporting Files
1. Open file details
2. Tap **Export to Files** action
3. Choose destination in Files app

## File Categories

Files are automatically categorized:

- **Documents**: PDF, DOC, DOCX, TXT, RTF, MD, Pages
- **Images**: JPG, PNG, HEIC, GIF, WebP, SVG, BMP
- **Videos**: MP4, MOV, AVI, MKV, WMV, FLV
- **Audio**: MP3, WAV, M4A, FLAC, AAC, OGG
- **Archives**: ZIP, RAR, 7Z, TAR, GZ
- **Code**: Swift, Python, Java, JS, HTML, CSS, JSON, XML
- **Other**: All other file types

## Sync Behavior

### Automatic Sync
- Files uploaded are automatically synced to iCloud
- Changes sync across all devices in real-time
- Offline changes sync when connection restored

### Sync Status
- **Pending**: Waiting to sync
- **Syncing**: Currently syncing
- **Synced**: Successfully synced
- **Failed**: Sync error occurred
- **Not Available**: iCloud not available

### Offline Mode
- All files accessible locally
- Upload queue when offline
- Automatic sync on reconnection

## Error Handling

The system includes comprehensive error handling for:
- iCloud account unavailable
- Network connectivity issues
- File access permissions
- Storage quota limits
- Invalid file formats

## Performance Considerations

- **Lazy Loading**: Files loaded on-demand
- **Thumbnail Caching**: Image thumbnails cached locally
- **Incremental Sync**: Only changed files synced
- **Background Upload**: Large files uploaded in background

## Future Enhancements

Potential improvements for future versions:
- Folder organization
- Version history
- Collaborative editing
- Advanced permissions (read-only, edit)
- File comments
- Activity feed
- Bulk operations
- Smart folders
- Integration with other features (attach to tasks, events)
- File encryption
- Storage analytics

## Troubleshooting

### iCloud Not Available
1. Check Settings → [Your Name] → iCloud
2. Ensure iCloud Drive is enabled
3. Verify storage quota
4. Check network connection

### Files Not Syncing
1. Check iCloud status indicator
2. Force refresh by pulling down
3. Check file size limits
4. Verify account permissions

### Upload Failed
1. Check network connection
2. Verify file size < 25MB recommended
3. Check iCloud storage quota
4. Try uploading smaller file first

## Technical Details

### Storage Locations
- **Local**: `Documents/SharedFiles/`
- **Metadata**: `Documents/shared_files_metadata.json`
- **Cloud**: iCloud.org.halext.Cafe container

### Supported File Sizes
- Recommended: < 25MB per file
- Maximum: Limited by iCloud storage quota

### Security
- Files encrypted at rest in iCloud
- Keychain integration for credentials
- App sandbox isolation
- Secure CloudKit connections

# AltStore/Sidestore Limitations

This document outlines features that are unavailable or limited when the app is installed via AltStore or Sidestore (unofficial distribution methods).

## Unavailable Features

### CloudKit Sync
- **Status**: Completely unavailable
- **Reason**: CloudKit containers require App Store distribution with proper entitlements
- **Impact**: 
  - iCloud-based data sync does not work
  - Social features that relied on CloudKit need backend API alternatives
- **Workaround**: All social features now use backend API (`/api/social/*` endpoints)

### Remote Push Notifications (APNs)
- **Status**: May not work reliably
- **Reason**: APNs requires proper provisioning profiles and App Store distribution
- **Impact**: 
  - Push notifications for new messages, tasks, etc. may not be delivered
  - Background updates may be limited
- **Workaround**: 
  - Local notifications still work
  - WebSocket connections provide real-time updates when app is active
  - Manual refresh available in UI

### Background Tasks
- **Status**: Limited
- **Reason**: Background execution is restricted for non-App Store apps
- **Impact**:
  - Background sync may be interrupted
  - Presence updates may stop when app is backgrounded
- **Workaround**: 
  - Presence updates resume when app enters foreground
  - WebSocket connections reconnect automatically

## Working Features

### Backend API Integration
- ✅ All REST API endpoints work normally
- ✅ WebSocket connections work normally
- ✅ Authentication and authorization work normally

### Local Features
- ✅ Local notifications work
- ✅ Local data storage works
- ✅ Offline mode works (with limitations)

### Social Features (Backend-Powered)
- ✅ Social circles (`/api/social/circles`)
- ✅ Pulses/activity feed (`/api/social/circles/{id}/pulses`)
- ✅ Presence tracking (`/api/users/{username}/presence`)
- ✅ Real-time messaging via WebSocket

## Migration Notes

### From CloudKit to Backend API

The app has been migrated from CloudKit-based social features to backend API:

1. **Presence Tracking**: Now uses `/api/users/me/presence` and `/api/users/{username}/presence`
2. **Social Circles**: Uses `/api/social/circles` endpoints
3. **Activity Feed**: Uses `/api/social/circles/{id}/pulses`

### Deprecated Features

The following CloudKit-based features are deprecated and should not be used:
- `SocialManager` CloudKit methods (use backend API instead)
- `SocialPresenceManager` CloudKit integration (now uses backend API)
- `CloudKitManager` (disabled)

## Testing Considerations

When testing with AltStore/Sidestore:
1. Verify backend API endpoints are accessible
2. Test WebSocket connections
3. Verify presence updates work via backend API
4. Test social circles and pulses
5. Note that CloudKit-dependent features will fail gracefully

## Future Improvements

- [ ] Add backend endpoints for shared tasks (currently CloudKit-only)
- [ ] Add backend endpoints for connections/invites (currently CloudKit-only)
- [ ] Enhance presence system with WebSocket real-time updates
- [ ] Add offline queue for presence updates


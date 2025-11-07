# Deploy Firebase Security Rules

## Quick Fix: Deploy Rules via Firebase Console

### Option 1: Firebase Console (Easiest - Recommended)

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `ecocollect-app`
3. **Deploy Storage Rules**:
   - Go to **Storage** > **Rules** tab
   - Copy the contents of `storage.rules` file
   - Paste into the rules editor
   - Click **Publish**

4. **Deploy Firestore Rules**:
   - Go to **Firestore Database** > **Rules** tab
   - Copy the contents of `firestore.rules` file
   - Paste into the rules editor
   - Click **Publish**

### Option 2: Firebase CLI (Command Line)

If you have Firebase CLI installed:

```bash
# Install Firebase CLI if you haven't
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (if not already done)
firebase init

# Deploy Storage rules
firebase deploy --only storage

# Deploy Firestore rules
firebase deploy --only firestore:rules
```

## What These Rules Do

### Storage Rules (`storage.rules`)
- ✅ Allows authenticated users to upload images to `waste_images/` folder
- ✅ Limits uploads to 5MB max
- ✅ Only allows image file types
- ✅ Allows anyone to read images (for displaying in the app)

### Firestore Rules (`firestore.rules`)
- ✅ Users can read/write their own user profile
- ✅ Authenticated users can create waste reports
- ✅ Users can only read/update/delete their own reports
- ✅ Public read access for truck locations (for tracking)
- ✅ Authenticated users can write truck locations (for testing)

## Testing

After deploying the rules:
1. Restart your Flutter app
2. Try submitting a waste report with an image
3. The "Permission denied" error should be gone!

## Important Notes

- Rules take effect immediately after publishing
- Make sure you're logged in when testing (authentication required)
- The rules allow authenticated users to upload images up to 5MB


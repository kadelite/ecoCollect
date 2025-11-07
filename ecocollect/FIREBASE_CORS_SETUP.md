# Firebase Storage CORS Configuration Guide

## Problem
When running the Flutter web app, you may encounter CORS (Cross-Origin Resource Sharing) errors when trying to upload images to Firebase Storage. This happens because Firebase Storage needs to be configured to allow uploads from your web domain.

## Solution

### Option 1: Configure CORS in Firebase Storage (Recommended)

1. **Create a CORS configuration file** named `cors.json`:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE", "HEAD"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Authorization"]
  }
]
```

2. **Apply the CORS configuration** using Google Cloud SDK (gcloud):

   - Install Google Cloud SDK if you haven't already: https://cloud.google.com/sdk/docs/install
   - Authenticate: `gcloud auth login`
   - Set your project: `gcloud config set project ecocollect-app`
   - Apply CORS: `gsutil cors set cors.json gs://ecocollect-app.firebasestorage.app`

### Option 2: Use Firebase Console (Alternative)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `ecocollect-app`
3. Navigate to **Cloud Storage** > **Buckets**
4. Click on your storage bucket
5. Go to **Permissions** tab
6. Add CORS configuration in the bucket settings

### Option 3: Temporary Workaround (Already Implemented)

The app now includes a fallback mechanism:
- If CORS upload fails, images are stored as base64 strings directly in Firestore
- This works without CORS configuration but is less efficient for large images
- Reports will still be submitted successfully

## Firebase Storage Security Rules

Also ensure your Firebase Storage security rules allow uploads:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /waste_images/{imageId} {
      // Allow authenticated users to upload images
      allow write: if request.auth != null;
      // Allow anyone to read images
      allow read: if true;
    }
  }
}
```

## Testing

After configuring CORS, test the upload:
1. Run the app: `flutter run -d chrome`
2. Try submitting a waste report with an image
3. Check the browser console for any CORS errors

## Note

The current implementation will automatically fall back to base64 storage if CORS upload fails, so your app will continue to work even without CORS configuration, though direct Storage uploads are preferred for better performance.


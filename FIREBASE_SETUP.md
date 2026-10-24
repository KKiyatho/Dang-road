# Firebase Setup

The app uses the existing `dang-dcd02` Firebase project for email/password authentication, meetup sharing, dog profiles, and walk records.

## One-time Console setup

1. In Firebase Console, open **Authentication > Sign-in method** and enable **Email/Password**.
2. Open **Firestore Database** and create a production-mode database in a region appropriate for Korean users.
3. Under **Authentication > Settings > Authorized domains**, verify `localhost`, add the deployed host `witty-hill-03dbc8b00.2.azurestaticapps.net`, and add any custom domain.
4. Install the Firebase CLI, sign in, and deploy the repository's restrictive Firestore rules:

```powershell
firebase login
firebase deploy --only firestore:rules
```

Run the deploy command from the repository root. The `.firebaserc` file selects `dang-dcd02` by default; verify the selected project before deployment if your Firebase Console shows a different project.

## Data boundaries

- A user can read and change only their own dog profile and walk records.
- Authenticated users can browse coarse-region meetup posts.
- Meetup creation is restricted to the signed-in creator; joining can only append the current user's ID and is capped by the meetup capacity.
- The app does not write precise user coordinates or meetup coordinates to Firestore.
- The rules do not implement content reporting, moderation, account deletion, or meetup cancellation. Those are still required before a public launch.

## Platform notes

Firebase options currently exist only for web. Run FlutterFire configuration for Android/iOS before enabling authentication on those platforms. Web geolocation requires HTTPS (localhost is allowed for development) and explicit browser permission.

Weather and air-quality values come from Open-Meteo. Map tiles and mapped footways come from OpenStreetMap/Overpass; both are public services without an app key and are subject to their usage policies and availability. Google Maps is not required for this implementation.
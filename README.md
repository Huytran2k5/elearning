# 🎓 IT Faculty E-Learning Management App

A cross-platform learning management application (Android, Windows & Web) for the IT Faculty. Built with **Flutter**, using **Firebase** as Backend and integrated with Cloudinary and Firebase Email Trigger services.

## 🚀 Key Features

* **Cross-platform:** Works seamlessly on Android, Windows Desktop, and Web.
* **User Role Management:**
    * **Instructor (Admin):**
        * Manage Course Catalog and Class Groups.
        * Manage Students (Manual entry or bulk CSV import).
        * Create Assignments and Multiple-choice Quizzes.
        * Grade assignments, track submission progress, export reports to Excel/CSV.
        * Automatically send email notifications to students for new assignments.
    * **Student:**
        * Personal dashboard showing upcoming deadlines and grade statistics.
        * Submit assignments (Direct file upload).
        * Take timed quizzes with automatic grading.
        * View learning materials.
* **Interaction:** Real-time 1-on-1 chat between Instructors and Students.
* **Storage:** Integrated with Cloudinary for unlimited assignment files and avatar storage.
* **🌐 Offline Mode & Caching:**
    * Automatically cache data when online for offline viewing.
    * Queue operations when offline (submit assignments, comments) and auto-sync when back online.
    * Real-time connection status banner display.
    * Firestore persistence enabled with unlimited cache.

## 🛠️ System Requirements

To run this project, your computer needs:

1.  **Flutter SDK:** Version 3.24.x or higher.
2.  **Dart SDK:** Version 3.5.x or higher.
3.  **Android Studio:**
    * Android SDK Platform API 35 (Android 15).
    * Java JDK 17 (configured in Gradle).
4.  **Visual Studio 2022 (Community):**
    * Must include **"Desktop development with C++"** workload for Windows builds.

## ⚙️ Installation & Configuration Guide

### Step 1: Prepare Source Code

Extract the project into a folder (Note: Folder path should not contain spaces or special characters).

Open Terminal at the root directory and run:
```bash
flutter pub get
````

### Step 2: Firebase Configuration (Required)

This project uses Firebase as the main database.

1.  Go to [Firebase Console](https://console.firebase.google.com/) and create a new project.
2.  Enable **Authentication** (Email/Password).
3.  Create **Firestore Database** (Start in test mode).
4.  Run the following command to link the project (requires Firebase CLI installed):
    ```bash
    flutterfire configure
    ```
    *(Select platforms: Android, Windows, and Web)*.

### Step 3: Cloudinary Configuration (For image/file upload)

1.  Register an account at [Cloudinary](https://cloudinary.com/).
2.  Go to **Settings -\> Upload -\> Upload presets**.
3.  Create new or edit preset to **"Unsigned"** mode.
4.  Open `lib/core/services/cloudinary_service.dart` and update:
    ```dart
    final String cloudName = "YOUR_CLOUD_NAME";
    final String uploadPreset = "YOUR_UNSIGNED_PRESET_NAME";
    ```

### Step 4: Email Configuration (Firebase Trigger Email)

For automated email notifications and account creation:

1.  Install **Trigger Email from Firestore** extension from Firebase Console.
2.  Configure the extension with your SMTP settings or use SendGrid/Mailgun.
3.  The system will automatically queue emails in the `mail` collection.

-----

## ▶️ Running the Application

**📱 Run on Android (Emulator or Physical Device):**

1.  Open Android emulator (AVD) or connect Android device (with USB Debugging enabled).
2.  Run command:
    ```bash
    flutter run
    ```
    ```bash
    flutter run
    ```

**💻 Run on Windows Desktop:**

1.  Ensure Visual Studio C++ is installed.
2.  Run command:
    ```bash
    flutter run -d windows
    ```

**💻 Run on Web:**

1.  Ensure Chrome or Edge is installed.
2.  Run command:
    ```bash
    flutter run -d chrome
    # Or
    flutter run -d edge
    ```

-----

## 🌐 Deploy to Web (GitHub Pages)

### Step 1: Build for production

```bash
flutter build web --release --base-href "/elearning/"
```

*Note: Replace `/elearning/` with your repository name.*

### Step 2: Deploy to GitHub Pages
git init
git add -A
git commit -m "Deploy to GitHub Pages"
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -f origin master:gh-pages
cd ../..
```

### Bước 3: Enable GitHub Pages

1. Vào repository trên GitHub
### Step 3: Enable GitHub Pages

1. Go to your repository on GitHub
2. **Settings** → **Pages**
3. Source: **Deploy from a branch**
4. Branch: **gh-pages** → Folder: **/ (root)**
5. Click **Save**

**Live URL:** `https://YOUR_USERNAME.github.io/YOUR_REPO/`

### Automatic Deployment (Optional)

Create file `.github/workflows/deploy.yml`:

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
      - run: flutter pub get
      - run: flutter build web --release --base-href "/elearning/"
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
```

-----

## 🔑 Login Accounts

### 1\. Instructor Account (Default)

To set up initial Admin privileges, create an account in Firebase Authentication and Firestore Database matching the following credentials (or modify in `auth_service.dart`):

  * **Instructor Account (Admin):**

      * **User:** `admin`
      * **Password:** `admin`
        *(System will automatically map to email `admin@elearning.com` / password `adminPassword123`)*

### 2\. Student Account

  * Created through Instructor's **"Import CSV"** feature.
  * Or manually added by Instructor in class detail screen.
  * Default password when auto-created: `123456`.

-----

## ⚠️ Common Issues & Solutions

**1. Error `The query requires an index`:**

  * When opening assignment/student lists and seeing endless loading or red errors.
  * **Solution:** Check Console (Run tab), copy the `https://console.firebase...` link printed, paste in browser to auto-create Index.

**2. Error `MissingPluginException`:**

  * Common when adding new libraries but using Hot Restart.
  * **Solution:** Completely stop the app, run `flutter clean`, then run `flutter run` again.

**3. Error `Upload failed (401 Unknown API Key)`:**

  * **Solution:** Re-check Cloudinary Preset on the web, ensure **Signing Mode** is set to **Unsigned**.

**4. Error "No internet connection" when offline:**

  * **Normal:** App will display orange banner "Offline mode" and load data from cache.
  * **If no data shows:** You need to be online at least once to cache initial data.
  * **Actions when offline:** Queued and auto-synced when back online (check console log to monitor).

-----

## 📱 Offline Mode Features

### How it works:

1. **Network Detection:**
   - Automatically detects network status in real-time
   - Displays notification banner at the top of each screen

2. **Data Caching (SharedPreferences):**
   - User profile
   - Enrolled courses list
   - Active semester
   - Recent announcements
   - Class group lists

3. **Firestore Offline Persistence:**
   - Automatically caches all queries
   - Unlimited cache size
   - Data available even when restarting app offline

4. **Sync Queue:**
   - Queues operations when offline:
     * Submit assignments
     * Post comments
     * Mark as viewed
   - Auto-sync when online with retry logic
   - Automatically removes actions older than 7 days

### Testing Offline Mode:

```bash
# 1. Run app and load complete data
flutter run -d edge

# 2. Turn off WiFi/Internet

# 3. Try these actions:
#    - View dashboard (still shows cached data)
#    - View courses (loads from cache)
#    - Post comment (queued)
#    - Submit assignment (queued)

# 4. Turn WiFi back on
#    → Banner changes to "Syncing..."
#    → Data automatically syncs to Firestore
```

-----

## 👨‍💻 Project Information

  * **Project:** Building E-Learning Management System (LMS).
  * **Technology:** Flutter, Firebase, Cloudinary.
  * **Developed by:** Nguyen Duc Anh, Tran Duc Huy
  * **Department:** Information Technology.
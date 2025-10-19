# 📍 LocReminder

A simple, open-source location-based alarm app built with Flutter. Never miss your bus stop again.

---

### Overview

LocReminder is an Android app designed for one simple purpose: to wake you up when you're approaching your destination.

Have you ever wanted to sleep on a bus or train but were too afraid of missing your stop? With LocReminder, you can set an alarm for a specific location. The app will track your device's GPS in the background and trigger a loud alarm when you get near, so you can rest peacefully.

This project is open-source and perfect for beginners looking to understand how Flutter integrates with native device features like GPS and background services.

---

### ✨ Features

* **Set Pin on Map:** Easily drop a pin on a map to set your destination.
* **Background Geofencing:** The app monitors your location even when it's closed or your phone is locked.
* **Loud Alarm & Vibration:** Triggers your phone's default alarm sound and vibrates to ensure you wake up.
* **Simple & Clean UI:** No clutter. Just a map, a button, and peace of mind.
* **Zero-Cost & Open-Source:** 100% free and open for contributions.

---

### 🛠️ Built With

* **Flutter:** For the cross-platform UI and business logic.
* **Dart:** The language of Flutter.
* **Google Maps API:** To display the map and allow location selection.
* **Geofencing:** To create a virtual perimeter around the destination.
* **Background Services:** To run location checks when the app is not active.

---

### 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

#### Prerequisites

Before you begin, ensure you have the following installed on your system:
* [Flutter SDK](https://flutter.dev/docs/get-started/install)
* [Android Studio](https://developer.android.com/studio) (for the Android SDK and emulators)
* [VS Code](https://code.visualstudio.com/) (or your preferred editor)
* [Git](https://git-scm.com/downloads)

#### Installation & Setup

1.  **Clone the repository:**
    ```sh
    git clone [https://github.com/zaifears/locreminder.git](https://github.com/zaifears/locreminder.git)
    ```

2.  **Navigate to the project directory:**
    ```sh
    cd locreminder
    ```

3.  **Install dependencies:**
    This command downloads all the necessary Flutter packages.
    ```sh
    flutter pub get
    ```

4.  **Add your Google Maps API Key:**
    This app requires a Google Maps API key to function.
    * Go to the Google Cloud Console and create a key.
    * Enable the "Maps SDK for Android".
    * Open the file `android/app/src/main/AndroidManifest.xml`.
    * Find the line that says `"YOUR_API_KEY_HERE"` and replace it with your actual key:
        ```xml
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_API_KEY_HERE" />
        ```

5.  **Run the app:**
    Make sure you have an emulator running or a physical Android device connected.
    ```sh
    flutter run
    ```

---

### 🤝 How to Contribute

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  **Fork the Project**
2.  **Create your Feature Branch** (`git checkout -b feature/AmazingFeature`)
3.  **Commit your Changes** (`git commit -m 'Add some AmazingFeature'`)
4.  **Push to the Branch** (`git push origin feature/AmazingFeature`)
5.  **Open a Pull Request**

Don't forget to give the project a star! ⭐

---

### 📜 License

This project is unlicensed and free to the public. It is distributed as public domain. You are free to use, modify, and distribute the code for any purpose, commercial or non-commercial, without any restrictions.

See the `UNLICENSE` file for more information.

---

### 📬 Contact

zaifears - [@your-twitter-handle](https://twitter.com/your-twitter-handle) - your-email@example.com

Project Link: [https://github.com/zaifears/locreminder](https://github.com/zaifears/locreminder)
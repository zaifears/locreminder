# Publishing LocReminder on F-Droid

A complete walkthrough, written to be followed without prior F-Droid
knowledge. Read the whole of Step 0 before starting — it explains one
decision that is hard to undo later.

**Roughly how long:** 1–2 hours of your time, then 2–6 weeks of waiting
for a volunteer reviewer.

---

## Step 0 — Understand what F-Droid does

F-Droid does **not** accept your APK file. It does something different:

1. You give them a link to your source code and a build recipe.
2. Their server downloads your source and **builds the app itself**.
3. They **sign the result with F-Droid's key**, not yours.
4. That APK goes into the F-Droid app store.

Three consequences:

**Your source must build without any manual steps.** Already true — CI
builds it on every push.

**No proprietary dependencies.** Already true as of v1.6.0, when Google
Play Services was removed.

**F-Droid's APK and your GitHub APK are not interchangeable.** Because
they carry different signatures, Android treats them as different apps.
A user with one installed must uninstall it — losing their saved alarms —
before installing the other.

Since **F-Droid is our only channel**, the rule from now on is simple:

> APKs in GitHub Releases are for testing only. The README points people
> to F-Droid. Anyone who tests a GitHub build should expect to uninstall
> it once the F-Droid version is live.

---

## Step 1 — Take screenshots

F-Droid shows 2–8 screenshots. Without them the listing looks abandoned.

1. Install the current build on your phone.
2. Capture these five (power + volume-down on most phones):
   - The map with an active alarm, so the circle and pin are visible
   - The search screen with results showing
   - The full-screen alarm ringing (use **Run alarm test**)
   - The Alarm reliability screen
   - Settings, showing the alarm-sound picker
3. Copy them to your PC and rename them `1.png`, `2.png`, `3.png`,
   `4.png`, `5.png`. The order is the order F-Droid displays them.
4. Put them in this exact folder:

   ```
   A:\locreminder\fastlane\metadata\android\en-US\images\phoneScreenshots\
   ```

5. Commit and push:

   ```bash
   git add fastlane/
   git commit -m "Add screenshots for F-Droid listing"
   git push origin main
   ```

F-Droid reads this folder automatically. There is nothing to upload
anywhere — the descriptions and changelogs in `fastlane/metadata/` are
picked up the same way.

---

## Step 2 — Tag the release

F-Droid builds from a **git tag**, not from the tip of `main`. Without a
tag there is nothing for it to build.

```bash
cd A:\locreminder
git tag -a v1.6.0 -m "LocReminder 1.6.0"
git push origin v1.6.0
```

Check the tag arrived:

```bash
git ls-remote --tags origin
```

You should see `refs/tags/v1.6.0`.

> **Version numbers must only ever go up.** `versionCode` is the number
> after the `+` in `pubspec.yaml` — currently `7`. Every future release
> must increase it, or F-Droid will reject the update.

---

## Step 3 — Create a GitLab account

F-Droid's submission process lives on GitLab, not GitHub.

1. Go to <https://gitlab.com/users/sign_up> and register.
2. Confirm your email address.
3. Sign in.

---

## Step 4 — Fork the fdroiddata repository

1. Open <https://gitlab.com/fdroid/fdroiddata>.
2. Click **Fork** (top right).
3. Choose your own username as the namespace, leave visibility Public,
   click **Fork project**.
4. Wait — it is a large repository and the fork takes a minute or two.

You now have `https://gitlab.com/YOUR-USERNAME/fdroiddata`.

---

## Step 5 — Add the metadata file

The recipe is already written for you at
`A:\locreminder\fdroid\com.zaifears.locreminder.yml`. You are going to
copy its contents into your fork.

Doing this in the GitLab web interface is easiest — no cloning required:

1. Open your fork: `https://gitlab.com/YOUR-USERNAME/fdroiddata`
2. Click into the **`metadata`** folder.
3. Click the **`+`** button near the top → **New file**.
4. Name the file **exactly**:

   ```
   com.zaifears.locreminder.yml
   ```

   The filename must match the app's application ID character for
   character, or the build will not be found.

5. Open `A:\locreminder\fdroid\com.zaifears.locreminder.yml` on your PC,
   copy everything, and paste it into the GitLab editor.
6. In the **Commit message** box, write:

   ```
   New App: LocReminder
   ```

7. Under **Target branch**, replace `master` with:

   ```
   locreminder
   ```

   This creates a new branch, which is what a merge request needs.

8. Tick **Start a new merge request with these changes**.
9. Click **Commit changes**.

---

## Step 6 — Open the merge request

GitLab takes you straight to the merge-request form.

1. **Title:** `New App: LocReminder`
2. **Description:** paste this:

   ```
   LocReminder is a location-based alarm: it rings a real alarm when you
   arrive near a destination you have set, so you can sleep or read on a
   journey without watching for your stop.

   - Fully free software, MIT licensed.
   - No Google Play Services and no proprietary dependencies.
   - No analytics, no advertising, no network backend. Maps and place
     search come from OpenStreetMap.
   - Privacy policy: https://github.com/zaifears/locreminder/blob/main/PRIVACY.md
   ```

3. Leave the rest at its defaults.
4. Click **Create merge request**.

Done. The rest is waiting.

---

## Step 7 — The review

**What happens automatically:** within minutes, GitLab CI runs checks on
your metadata file. Watch the **Pipelines** tab of your merge request.

- **Green tick** — metadata is valid, now wait for a human.
- **Red cross** — click the failed job to read the log. It usually names
  the exact line at fault. Fix the file (edit it in your fork on the
  branch you created) and the pipeline re-runs by itself.

**What happens next:** a volunteer reviewer builds the app on their
machine, checks the source for anything non-free, and either merges it or
comments asking for changes.

**How long:** typically 2–6 weeks. It is volunteer work, so it is not
predictable. Comments arrive by email, and replying promptly is the main
thing that keeps it moving.

**If you are asked for changes:** reply in the merge-request thread, make
the change (in this repo if it is a code issue, or in the metadata file
in your fork if it is a recipe issue), and say so in a comment.

Once merged, the app appears on F-Droid within a day or two, at:

```
https://f-droid.org/packages/com.zaifears.locreminder/
```

---

## Step 8 — After it is live

Update the README's download button to point at the F-Droid page instead
of GitHub Releases, and add the official badge:

```markdown
[![Get it on F-Droid](https://fdroid.gitlab.io/artwork/badge/get-it-on.png)](https://f-droid.org/packages/com.zaifears.locreminder/)
```

---

## Releasing a new version later

Much shorter than the first time:

1. Change `version:` in `pubspec.yaml` — **both** parts, e.g.
   `1.7.0+8`. The number after `+` must increase.
2. Add a `fastlane/metadata/android/en-US/changelogs/8.txt` — the
   filename is the new `versionCode`, and its text is what users see in
   the F-Droid "What's New" section.
3. Add a section to `CHANGELOG.md`.
4. Commit, push, then tag:

   ```bash
   git tag -a v1.7.0 -m "LocReminder 1.7.0"
   git push origin v1.7.0
   ```

Because the metadata sets `UpdateCheckMode: Tags` and
`AutoUpdateMode: Version`, **F-Droid notices the new tag by itself** and
builds it. No new merge request is needed.

---

## Common reasons submissions get rejected

| Reason | Where we stand |
|---|---|
| Non-free dependencies | Resolved — Play Services removed in v1.6.0 |
| No recognised licence | Resolved — MIT, in `LICENSE` |
| No privacy policy | Resolved — `PRIVACY.md` |
| Build fails on their server | CI builds the same commands on every push |
| Tracking or analytics libraries | None have ever been added |
| Downloading binaries at build time | Nothing does this |

The one genuinely unpredictable part is their build server reproducing
the build. If it fails there but passes in CI, the reviewer's log will
say why, and the fix goes in the `Builds:` section of the metadata file.

---

## Glossary

| Term | Meaning |
|---|---|
| **fdroiddata** | The repository holding a metadata file for every app on F-Droid |
| **Metadata file** | The recipe telling F-Droid how to build your app |
| **Merge request** | GitLab's name for a pull request |
| **versionCode** | The integer after `+` in `pubspec.yaml`; must always increase |
| **srclib** | A shared dependency F-Droid provides — here, the Flutter SDK |
| **Anti-feature** | A warning label, e.g. for non-free dependencies. LocReminder has none |

---

## Signing key

From v1.6.6 releases are signed with the project's own key
(`CN=Shahoriar Hossain, O=LocReminder, C=BD`, valid to 2054). Everything
before that was signed with Android's shared debug key by mistake, so those
APKs prove nothing about who built them.

The certificate's SHA-256, which is what `AllowedAPKSigningKeys` wants if
reproducible builds are ever enabled:

```
e594d95da857cb75c7abf991915722086671815b7ee105cf9e224bec48858115
```

Recompute it from any release with:

```bash
apksigner verify --print-certs app-release.apk
```

> Losing the keystore or its password means never being able to update the
> app for anyone who installed it from GitHub — Android refuses an update
> signed with a different key, and there is no recovery path.

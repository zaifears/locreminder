# F-Droid merge request description

The text below is what goes in the **description** of the fdroiddata merge
request. It is F-Droid's own **App inclusion** template, filled in for this
app.

Reviewers look for this checklist. A merge request without it gets sent back
with a note asking for it, which is what happened to MR !46299.

## How to use it

1. Open the merge request on GitLab and click **Edit**.
2. Select **App inclusion** from the **Description template** dropdown, so
   GitLab records that the template was used.
3. Replace the box's contents with everything between the `<!-- BEGIN -->`
   and `<!-- END -->` markers below.
4. **Save only after the pipeline is green.** One box claims all pipelines
   pass, and a reviewer checks.

## Before ticking "all pipelines pass"

The `checkupdates` job fails whenever the metadata on the merge request
branch has fallen behind the tags on GitHub. Update
`metadata/com.zaifears.locreminder.yml` on the fork first, let the pipeline
re-run, and only then save this description. See **Releasing a new version
later** in [FDROID-SUBMISSION.md](FDROID-SUBMISSION.md).

## Why each box is ticked, or is not

| Box | State | Why |
|---|---|---|
| Inclusion criteria | ticked | MIT, no proprietary dependencies, no Google Play Services, no ads, no analytics, no backend. |
| Author notified | ticked | The submitter is the author. |
| Related issues referenced | ticked | Searched the rfp and fdroiddata trackers: no issue exists for this app, so there is nothing to reference and the `Closes` lines are removed. |
| Builds and pipelines pass | ticked **only once true** | `fdroid build` passes. `checkupdates` passes only while the metadata matches the latest tag. |
| Issue tracker and contact | ticked | `IssueTracker` and `AuthorEmail` are both set in the metadata. |
| Fastlane metadata upstream | ticked | `fastlane/metadata/android/en-US/` holds the title, descriptions, per-versionCode changelogs, icon and six screenshots. |
| Tagged releases, auto update | ticked | `UpdateCheckMode: Tags`, `AutoUpdateMode: Version`. |
| Submodules instead of srclibs | **not applicable** | The box is about external source repos the app vendors in. This app vendors none; its only srclib is the Flutter SDK toolchain, which F-Droid provides. |
| Reproducible builds | ticked | `Binaries` and `AllowedAPKSigningKeys` are set, and releases are compiled in F-Droid's own buildserver image at F-Droid's paths so the rebuild matches. |
| Multiple APKs | **not ticked** | One universal APK. Splitting is possible but has not been done. |

The two unticked boxes are both in the template's **Suggested** section,
which the template introduces with "These suggestions may be difficult to
apply on your app." They are not requirements and they are not failures.
Every box under **Required** and **Strongly Recommended** is ticked.

Do not tick a box to make the list look complete. An unticked box with a
reason beside it costs nothing; a false tick costs the reviewer's trust.

---

<!-- BEGIN -->

LocReminder is a location-based alarm: it rings a real alarm when you arrive
near a destination you have set, so you can sleep or read on a journey
without watching for your stop.

- Fully free software, MIT licensed.
- No Google Play Services and no proprietary dependencies.
- No analytics, no advertising, no network backend. Maps and place search
  come from OpenStreetMap.
- Privacy policy: https://github.com/zaifears/locreminder/blob/main/PRIVACY.md

I am the app's author, submitting my own app.

## Required

* [x] The app complies with the [inclusion criteria](https://f-droid.org/docs/Inclusion_Policy)
* [x] The original app author has been notified (and does not oppose the inclusion) <!-- I am the author. -->
* [x] All related [fdroiddata](https://gitlab.com/fdroid/fdroiddata/issues) and [RFP issues](https://gitlab.com/fdroid/rfp/issues) have been referenced in this merge request <!-- There are no rfp or fdroiddata issues for this app. -->
* [x] Builds with `fdroid build` and all pipelines pass
* [x] There is an issue tracker and contact info of the author so that we can report bugs and contact the author.

## Strongly Recommended

* [x] The upstream app source code repo contains the app metadata _(summary/description/images/changelog/etc)_ in a [Fastlane](https://gitlab.com/snippets/1895688) or [Triple-T](https://gitlab.com/snippets/1901490) folder structure
* [x] Releases are tagged and auto update is enabled

## Suggested

* [ ] External repos are added as git submodules instead of srclibs <!-- Not applicable: the app vendors no external source repos. Its only srclib is the Flutter SDK itself, which F-Droid provides and which cannot be a submodule of the app repo. -->
* [x] Enable [Reproducible Builds](https://f-droid.org/docs/Reproducible_Builds)
* [ ] Multiple apks for native code <!-- One universal APK for now. -->

<!-- END -->

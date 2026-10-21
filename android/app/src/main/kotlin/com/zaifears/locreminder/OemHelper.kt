package com.zaifears.locreminder

import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Log

/**
 * Opens the manufacturer-specific screens that actually govern whether a
 * background app keeps running and whether its full-screen alarm can appear
 * over the lock screen.
 *
 * Stock Android's battery-optimisation and full-screen intent checks are not
 * the whole story on Xiaomi/Redmi/Poco (MIUI & HyperOS), Samsung, Oppo, Vivo,
 * OnePlus and Huawei devices:
 *
 * 1. Each layers its own autostart or "sleeping apps" list on top of Doze.
 * 2. Xiaomi (MIUI 14 / HyperOS, e.g. Redmi Note 12 4G) gates lock-screen and
 *    background full-screen alarm activities behind two proprietary AppOps in
 *    `com.miui.securitycenter` ("Show on Lock screen" = op 10020, and
 *    "Display pop-up windows while running in the background" = op 10021)
 *    which are DENIED by default, even when Android 14's standard
 *    `canUseFullScreenIntent()` returns true.
 */
object OemHelper {

    private const val TAG = "OemHelper"

    /**
     * MIUI / HyperOS custom AppOps in `com.miui.securitycenter` that govern
     * whether an Activity with `showWhenLocked` / `fullScreenIntent` is
     * allowed to appear over the lock screen or launch from a service.
     */
    private const val MIUI_OP_SHOW_WHEN_LOCKED = 10020
    private const val MIUI_OP_BACKGROUND_START_ACTIVITY = 10021

    /** Candidate vendor autostart screens, most specific first. */
    private val autoStartCandidates = listOf(
        // Xiaomi / Redmi / Poco (MIUI, HyperOS)
        "com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity",
        "com.miui.securitycenter" to "com.miui.permcenter.permissions.PermissionsEditorActivity",
        "com.miui.securitycenter" to "com.miui.permcenter.permissions.AppPermissionsEditorActivity",
        // Oppo / Realme (ColorOS)
        "com.coloros.safecenter" to "com.coloros.safecenter.permission.startup.StartupAppListActivity",
        "com.coloros.safecenter" to "com.coloros.safecenter.startupapp.StartupAppListActivity",
        "com.oppo.safe" to "com.oppo.safe.permission.startup.StartupAppListActivity",
        // Vivo / iQOO (Funtouch, OriginOS)
        "com.vivo.permissionmanager" to "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
        "com.vivo.permissionmanager" to "com.vivo.permissionmanager.activity.SoftPermissionDetailActivity",
        "com.iqoo.secure" to "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
        // OnePlus (OxygenOS)
        "com.oneplus.security" to "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity",
        // Huawei / Honor (EMUI, MagicOS)
        "com.huawei.systemmanager" to "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
        "com.huawei.systemmanager" to "com.huawei.systemmanager.optimize.process.ProtectActivity",
        "com.hihonor.systemmanager" to "com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
        // Samsung (One UI) device care (modern com.samsung.android.sm + legacy com.samsung.android.lool)
        "com.samsung.android.sm" to "com.samsung.android.sm.battery.ui.BatteryActivity",
        "com.samsung.android.sm" to "com.samsung.android.sm.ui.battery.BatteryActivity",
        "com.samsung.android.sm_cn" to "com.samsung.android.sm.ui.battery.BatteryActivity",
        "com.samsung.android.lool" to "com.samsung.android.sm.ui.battery.BatteryActivity",
        "com.samsung.android.lool" to "com.samsung.android.sm.battery.ui.BatteryActivity",
        // Transsion: Tecno / Infinix / itel (HiOS / XOS)
        "com.transsion.phonemanager" to "com.transsion.phonemanager.settings.AutoStartAppListActivity",
        "com.transsion.phonemanager" to "com.transsion.phonemanager.view.AutoStartAppListActivity",
        "com.transsion.smartpanel" to "com.transsion.smartpanel.settings.AutoStartAppListActivity",
        // Asus
        "com.asus.mobilemanager" to "com.asus.mobilemanager.autostart.AutoStartActivity",
        // Letv
        "com.letv.android.letvsafe" to "com.letv.android.letvsafe.AutobootManageActivity",
    )

    fun manufacturer(): String {
        val m = Build.MANUFACTURER?.lowercase().orEmpty()
        val b = Build.BRAND?.lowercase().orEmpty()
        return if (m.isNotEmpty()) "$m $b".trim() else b
    }

    fun isXiaomi(): Boolean {
        val vendor = manufacturer()
        return XIAOMI_KEYS.any { vendor.contains(it) }
    }

    /**
     * True for vendors known to kill background work beyond stock Android's
     * rules, so the UI can escalate its warnings only where warranted rather
     * than nagging every user.
     */
    fun needsExtraSetup(): Boolean {
        val vendor = manufacturer()
        return AGGRESSIVE_VENDORS.any { vendor.contains(it) }
    }

    /**
     * Checks whether the full-screen alarm is actually allowed to display over
     * the lock screen on this device.
     *
     * Combines two checks:
     * 1. Standard Android 14+ `NotificationManager.canUseFullScreenIntent()`.
     * 2. On Xiaomi / Redmi / Poco (MIUI & HyperOS, including Android 12/13/14+),
     *    Xiaomi's own "Show on Lock screen" (`OP_SHOW_WHEN_LOCKED` = 10020) and
     *    "Display pop-up windows while running in the background"
     *    (`OP_BACKGROUND_START_ACTIVITY` = 10021) permissions, which are off by
     *    default and block the lock-screen alarm even when stock Android's check
     *    reports true.
     */
    fun canUseFullScreenAlarm(context: Context): Boolean {
        val standardAllowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val manager = context.getSystemService(NotificationManager::class.java)
            manager?.canUseFullScreenIntent() ?: false
        } else {
            true
        }

        if (!standardAllowed) return false

        if (isXiaomi()) {
            return canShowOnLockScreenXiaomi(context)
        }

        return true
    }

    /**
     * Queries MIUI / HyperOS AppOps `10020` (Show on Lock screen) and `10021`
     * (Display pop-up windows while running in the background).
     *
     * Degrades to `true` if `com.miui.securitycenter` is not present (e.g.
     * custom AOSP ROMs like LineageOS/PixelOS on Xiaomi hardware) or if the
     * ROM does not expose integer `checkOpNoThrow`.
     */
    fun canShowOnLockScreenXiaomi(context: Context): Boolean {
        if (!hasMiuiSecurityCenter(context)) return true
        return checkMiuiOpAllowed(context, MIUI_OP_SHOW_WHEN_LOCKED) &&
            checkMiuiOpAllowed(context, MIUI_OP_BACKGROUND_START_ACTIVITY)
    }

    private fun hasMiuiSecurityCenter(context: Context): Boolean {
        return try {
            context.packageManager.getPackageInfo("com.miui.securitycenter", 0)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun checkMiuiOpAllowed(context: Context, op: Int): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return true
        return try {
            val method = AppOpsManager::class.java.getMethod(
                "checkOpNoThrow",
                Int::class.javaPrimitiveType,
                Int::class.javaPrimitiveType,
                String::class.java,
            )
            val mode = method.invoke(appOps, op, Process.myUid(), context.packageName) as? Int
            // Custom ROMs (LineageOS, PixelExperience, etc.) on Xiaomi hardware return
            // MODE_ALLOWED or throw IllegalArgumentException for unknown vendor op codes.
            mode == null || mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            true
        }
    }

    /**
     * Opens the exact settings screen needed to allow full-screen / lock-screen
     * alarm display on this phone:
     *
     * - On Android 14+, if standard `canUseFullScreenIntent()` is false, opens
     *   `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT`.
     * - On Xiaomi / Redmi / Poco (MIUI / HyperOS), opens Xiaomi's per-app
     *   "Other permissions" screen (`miui.intent.action.APP_PERM_EDITOR`) where
     *   "Show on Lock screen" and "Display pop-up windows while running in the
     *   background" live.
     * - Otherwise opens vendor lock-screen permission settings, Android 14
     *   full-screen intent settings, or the alarm notification channel settings.
     */
    fun openFullScreenIntentSettings(context: Context): Boolean {
        // 1. If Android 14+ standard full-screen intent is denied, fix that first.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val manager = context.getSystemService(NotificationManager::class.java)
            val standardAllowed = manager?.canUseFullScreenIntent() ?: true
            if (!standardAllowed && launchManageFullScreenIntent(context)) {
                return true
            }
        }

        // 2. On Xiaomi/Redmi/Poco, open "Other permissions" for Show on Lock screen
        //    & Display pop-up windows while running in the background.
        if (isXiaomi() && openXiaomiPermissionEditor(context)) {
            return true
        }

        // 3. On Android 14+, try the standard Full Screen Intent settings screen even
        //    if the user opened it manually to double-check.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            launchManageFullScreenIntent(context)
        ) {
            return true
        }

        // 4. Try vendor lock-screen / permission editor screens (Vivo, Oppo, etc.)
        if (openLockScreenPermissionSettings(context)) {
            return true
        }

        // 5. Fall back to the alarm notification channel or app notification settings.
        return openAlarmChannelSettings(context)
    }

    private fun launchManageFullScreenIntent(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return false
        val withPkg = Intent(
            Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
            Uri.parse("package:${context.packageName}"),
        ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }

        if (tryStartActivity(context, withPkg)) return true

        val general = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return tryStartActivity(context, general)
    }

    /**
     * Opens Xiaomi's per-app "Other permissions" screen where "Show on Lock screen"
     * and "Display pop-up windows while running in the background" are toggled on
     * MIUI 12/13/14 and HyperOS 1/2 (including Redmi Note 12 4G).
     */
    fun openXiaomiPermissionEditor(context: Context): Boolean {
        val pkg = context.packageName
        val candidates = listOf(
            Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                component = ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.permissions.PermissionsEditorActivity",
                )
                putExtra("extra_pkgname", pkg)
                putExtra("package_name", pkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                component = ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.permissions.AppPermissionsEditorActivity",
                )
                putExtra("extra_pkgname", pkg)
                putExtra("package_name", pkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            Intent("miui.intent.action.APP_PERM_EDITOR").apply {
                setPackage("com.miui.securitycenter")
                putExtra("extra_pkgname", pkg)
                putExtra("package_name", pkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
        for (intent in candidates) {
            if (tryStartActivity(context, intent)) return true
        }
        return false
    }

    /**
     * Opens vendor lock-screen / pop-up permission screens (Xiaomi, Vivo, Oppo/Realme, etc.).
     */
    fun openLockScreenPermissionSettings(context: Context): Boolean {
        if (isXiaomi() && openXiaomiPermissionEditor(context)) return true

        val pkg = context.packageName
        val vendorLockScreenIntents = listOf(
            // Vivo / iQOO per-app permission detail (Display on lock screen / Pop-up window)
            Intent().apply {
                component = ComponentName(
                    "com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.SoftPermissionDetailActivity",
                )
                putExtra("packagename", pkg)
                putExtra("package_name", pkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            Intent("permission.intent.action.softPermissionDetail").apply {
                putExtra("packagename", pkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            // ColorOS / Realme / OnePlus permission manager
            Intent().apply {
                component = ComponentName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.PermissionManagerActivity",
                )
                putExtra("package_name", pkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
        for (intent in vendorLockScreenIntents) {
            if (tryStartActivity(context, intent)) return true
        }
        return false
    }

    /**
     * Opens the system settings screen for the Location Alarms notification
     * channel (`locreminder_alarm_channel`), where users on MIUI/HyperOS,
     * Samsung One UI, ColorOS, etc. can enable "Lock screen notifications"
     * and "Floating / Banner notifications".
     */
    fun openAlarmChannelSettings(context: Context): Boolean {
        NotificationHelper.ensureAlarmChannel(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelIntent = Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                putExtra(Settings.EXTRA_CHANNEL_ID, NotificationHelper.ALARM_CHANNEL_ID)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (tryStartActivity(context, channelIntent)) return true

            val appNotifIntent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (tryStartActivity(context, appNotifIntent)) return true
        }
        return openAppSettings(context)
    }

    /**
     * Opens the vendor's autostart / background-activity screen. Returns
     * false when no vendor screen launches, letting the caller fall back to
     * the standard app settings page rather than showing a dead button.
     */
    fun openAutoStartSettings(context: Context): Boolean {
        for ((pkg, cls) in autoStartCandidates) {
            val intent = Intent().apply {
                component = ComponentName(pkg, cls)
                putExtra("extra_pkgname", context.packageName)
                putExtra("package_name", context.packageName)
                putExtra("package", context.packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            // Continue trying remaining candidates if an activity resolves in
            // PackageManager but throws SecurityException on launch (e.g.
            // AutoStartManagementActivity on HyperOS / MIUI 14).
            if (tryStartActivity(context, intent)) return true
        }
        if (isXiaomi() && openXiaomiPermissionEditor(context)) return true
        return false
    }

    /** Stock Android's per-app battery-optimisation screen. */
    fun openBatterySettings(context: Context): Boolean {
        val intent = Intent(
            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Uri.parse("package:${context.packageName}"),
        ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }

        return if (tryStartActivity(context, intent)) {
            true
        } else {
            openAppSettings(context)
        }
    }

    fun openAppSettings(context: Context): Boolean {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:${context.packageName}"),
        ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }

        return tryStartActivity(context, intent)
    }

    private fun tryStartActivity(context: Context, intent: Intent): Boolean {
        // Attempt startActivity directly rather than gating on resolveActivity:
        // on Android 11+ (API 30+), package visibility filtering can cause
        // resolveActivity(intent, 0) to return null for vendor activities that
        // startActivity(intent) can launch without issue.
        return try {
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.w(TAG, "Screen ${intent.component ?: intent.action} could not launch", e)
            false
        }
    }

    private val XIAOMI_KEYS = listOf("xiaomi", "redmi", "poco", "blackshark")

    // Kept in step with the vendor table in oem_service.dart, which is what
    // actually decides whether the user is shown extra steps. This list only
    // gates the native side's own checks.
    private val AGGRESSIVE_VENDORS = listOf(
        "xiaomi", "redmi", "poco", "blackshark",
        "samsung",
        "oppo", "realme",
        "vivo", "iqoo",
        "oneplus",
        "huawei", "honor",
        "meizu", "asus",
        "tecno", "infinix", "itel",
        "lenovo", "zte", "nubia", "letv", "leeco",
    )
}

package com.zaifears.locreminder

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log

/**
 * Opens the manufacturer-specific screens that actually govern whether a
 * background app keeps running.
 *
 * Stock Android's battery-optimisation exemption is not the whole story on
 * Xiaomi, Samsung, Oppo, Vivo, OnePlus and Huawei devices: each layers its
 * own autostart or "sleeping apps" list on top, and an app absent from it
 * gets killed no matter what the platform APIs say. There is no API to opt
 * out of that — the user has to toggle it — so the least we can do is take
 * them directly to the right screen.
 *
 * Component names are undocumented vendor internals that move between OS
 * versions, so every candidate is checked with the package manager before
 * use and the whole thing degrades to the standard app-settings page.
 */
object OemHelper {

    private const val TAG = "OemHelper"

    /** Candidate vendor screens, most specific first. */
    private val autoStartCandidates = listOf(
        // Xiaomi / Redmi / Poco (MIUI, HyperOS)
        "com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity",
        // Oppo / Realme (ColorOS)
        "com.coloros.safecenter" to "com.coloros.safecenter.permission.startup.StartupAppListActivity",
        "com.coloros.safecenter" to "com.coloros.safecenter.startupapp.StartupAppListActivity",
        "com.oppo.safe" to "com.oppo.safe.permission.startup.StartupAppListActivity",
        // Vivo / iQOO (Funtouch, OriginOS)
        "com.vivo.permissionmanager" to "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
        "com.iqoo.secure" to "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
        // OnePlus (OxygenOS)
        "com.oneplus.security" to "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity",
        // Huawei / Honor (EMUI, MagicOS)
        "com.huawei.systemmanager" to "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
        "com.huawei.systemmanager" to "com.huawei.systemmanager.optimize.process.ProtectActivity",
        // Samsung (One UI) device care
        "com.samsung.android.lool" to "com.samsung.android.sm.ui.battery.BatteryActivity",
        "com.samsung.android.lool" to "com.samsung.android.sm.battery.ui.BatteryActivity",
        // Asus
        "com.asus.mobilemanager" to "com.asus.mobilemanager.autostart.AutoStartActivity",
        // Letv
        "com.letv.android.letvsafe" to "com.letv.android.letvsafe.AutobootManageActivity",
    )

    fun manufacturer(): String = Build.MANUFACTURER?.lowercase().orEmpty()

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
     * Opens the vendor's autostart / background-activity screen. Returns
     * false when no vendor screen resolves, letting the caller fall back to
     * the standard app settings page rather than showing a dead button.
     */
    fun openAutoStartSettings(context: Context): Boolean {
        for ((pkg, cls) in autoStartCandidates) {
            val intent = Intent().apply {
                component = ComponentName(pkg, cls)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (context.packageManager.resolveActivity(intent, 0) != null) {
                return try {
                    context.startActivity(intent)
                    true
                } catch (e: Exception) {
                    Log.w(TAG, "Vendor screen $pkg/$cls resolved but would not launch", e)
                    false
                }
            }
        }
        return false
    }

    /** Stock Android's per-app battery-optimisation screen. */
    fun openBatterySettings(context: Context): Boolean {
        val intent = Intent(
            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Uri.parse("package:${context.packageName}"),
        ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }

        return try {
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.w(TAG, "Could not open battery optimisation settings", e)
            openAppSettings(context)
        }
    }

    fun openAppSettings(context: Context): Boolean {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:${context.packageName}"),
        ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }

        return try {
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Could not open app settings", e)
            false
        }
    }

    private val AGGRESSIVE_VENDORS = listOf(
        "xiaomi", "redmi", "poco",
        "samsung",
        "oppo", "realme",
        "vivo", "iqoo",
        "oneplus",
        "huawei", "honor",
        "meizu", "asus", "letv", "tecno", "infinix", "itel",
    )
}

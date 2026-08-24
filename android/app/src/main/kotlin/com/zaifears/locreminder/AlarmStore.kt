package com.zaifears.locreminder

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * A saved destination alarm, mirrored on the native side so the
 * BroadcastReceiver / BootReceiver can act without the Flutter engine running.
 */
data class AlarmEntry(
    val id: String,
    val label: String,
    val latitude: Double,
    val longitude: Double,
    val radius: Double,
    /**
     * Weekdays this alarm is armed on, 1 = Monday through 7 = Sunday, matching
     * Dart's `DateTime.weekday`. Empty means it fires once and is deleted,
     * which is what every alarm saved before repeats existed becomes.
     */
    val repeatDays: Set<Int> = emptySet(),
) {
    val repeats: Boolean get() = repeatDays.isNotEmpty()

    /** Whether this alarm is allowed to ring on [isoWeekday] (1 = Monday). */
    fun ringsOn(isoWeekday: Int): Boolean =
        repeatDays.isEmpty() || isoWeekday in repeatDays
}

/**
 * Plain SharedPreferences-backed store, independent from the
 * shared_preferences Flutter plugin's own storage so native code never
 * depends on the Dart side being alive to read alarm metadata.
 */
class AlarmStore(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun loadAll(): List<AlarmEntry> {
        val raw = prefs.getString(KEY_ENTRIES, null) ?: return emptyList()
        val array = JSONArray(raw)
        return (0 until array.length()).map { i ->
            val obj = array.getJSONObject(i)
            AlarmEntry(
                id = obj.getString("id"),
                label = obj.getString("label"),
                latitude = obj.getDouble("latitude"),
                longitude = obj.getDouble("longitude"),
                radius = obj.getDouble("radius"),
                repeatDays = obj.optJSONArray("repeatDays").toWeekdaySet(),
            )
        }
    }

    fun getById(id: String): AlarmEntry? = loadAll().find { it.id == id }

    fun save(entry: AlarmEntry) {
        val entries = loadAll().filterNot { it.id == entry.id } + entry
        persist(entries)
    }

    fun remove(id: String) {
        persist(loadAll().filterNot { it.id == id })
    }

    fun clear() {
        prefs.edit().remove(KEY_ENTRIES).apply()
    }

    private fun persist(entries: List<AlarmEntry>) {
        val array = JSONArray()
        entries.forEach { e ->
            val obj = JSONObject()
            obj.put("id", e.id)
            obj.put("label", e.label)
            obj.put("latitude", e.latitude)
            obj.put("longitude", e.longitude)
            obj.put("radius", e.radius)
            obj.put("repeatDays", JSONArray(e.repeatDays.sorted()))
            array.put(obj)
        }
        prefs.edit().putString(KEY_ENTRIES, array.toString()).apply()
    }

    companion object {
        // Legacy name kept deliberately: renaming it would orphan the
        // alarms of anyone upgrading from an earlier version.
        private const val PREFS_NAME = "locreminder_geofences"
        private const val KEY_ENTRIES = "entries"
    }
}

/**
 * Reads a weekday array, dropping anything outside 1..7.
 *
 * Absent on every record written before repeats existed, and null is the
 * honest answer for those: they were one-shot alarms, and an empty set is
 * exactly that.
 *
 * Top-level rather than a member of the companion: a member extension needs
 * both its receivers in scope at the call site, which is a subtlety this does
 * not need to depend on.
 */
private fun JSONArray?.toWeekdaySet(): Set<Int> {
    if (this == null) return emptySet()
    val days = mutableSetOf<Int>()
    for (i in 0 until length()) {
        val day = optInt(i, -1)
        if (day in 1..7) days.add(day)
    }
    return days
}

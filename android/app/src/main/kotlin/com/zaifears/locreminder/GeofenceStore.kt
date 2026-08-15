package com.zaifears.locreminder

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * A saved destination alarm, mirrored on the native side so the
 * BroadcastReceiver / BootReceiver can act without the Flutter engine running.
 */
data class GeofenceEntry(
    val id: String,
    val label: String,
    val latitude: Double,
    val longitude: Double,
    val radius: Double,
)

/**
 * Plain SharedPreferences-backed store, independent from the
 * shared_preferences Flutter plugin's own storage so native code never
 * depends on the Dart side being alive to read geofence metadata.
 */
class GeofenceStore(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun loadAll(): List<GeofenceEntry> {
        val raw = prefs.getString(KEY_ENTRIES, null) ?: return emptyList()
        val array = JSONArray(raw)
        return (0 until array.length()).map { i ->
            val obj = array.getJSONObject(i)
            GeofenceEntry(
                id = obj.getString("id"),
                label = obj.getString("label"),
                latitude = obj.getDouble("latitude"),
                longitude = obj.getDouble("longitude"),
                radius = obj.getDouble("radius"),
            )
        }
    }

    fun getById(id: String): GeofenceEntry? = loadAll().find { it.id == id }

    fun save(entry: GeofenceEntry) {
        val entries = loadAll().filterNot { it.id == entry.id } + entry
        persist(entries)
    }

    fun remove(id: String) {
        persist(loadAll().filterNot { it.id == id })
    }

    fun clear() {
        prefs.edit().remove(KEY_ENTRIES).apply()
    }

    private fun persist(entries: List<GeofenceEntry>) {
        val array = JSONArray()
        entries.forEach { e ->
            val obj = JSONObject()
            obj.put("id", e.id)
            obj.put("label", e.label)
            obj.put("latitude", e.latitude)
            obj.put("longitude", e.longitude)
            obj.put("radius", e.radius)
            array.put(obj)
        }
        prefs.edit().putString(KEY_ENTRIES, array.toString()).apply()
    }

    companion object {
        private const val PREFS_NAME = "locreminder_geofences"
        private const val KEY_ENTRIES = "entries"
    }
}

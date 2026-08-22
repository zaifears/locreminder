package com.zaifears.locreminder

import android.content.Context

/**
 * Remembers, across process death, which alarms the user has been seen
 * outside of.
 *
 * An alarm rings on *crossing into* its radius, so an alarm set for where you
 * are standing must stay quiet until you leave and return. Deciding that
 * needs a memory of where the user has been, and until 1.7.0 that memory was
 * two ordinary fields on [LocationWatchService].
 *
 * That was the bug behind a missed alarm. The watch service is START_STICKY,
 * so when an aggressive OEM memory manager killed the app mid-journey — most
 * likely of all right after a full-screen alarm took over the screen — the
 * system brought the service straight back with both fields reset. The next
 * fix therefore looked like the very first one, and any *other* alarm the
 * user happened to already be approaching was filed as "we started inside
 * this one" and suppressed. It then stayed silent for the rest of the trip
 * and rang on the return leg, when the user finally left the radius and
 * re-entered it.
 *
 * Persisting the state fixes it at the root: a restart no longer erases what
 * the service already knew about an alarm.
 */
class ArrivalState(context: Context) {

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /**
     * Whether [id] must be exited before it may ring, recording the first
     * sighting as a side effect.
     *
     * Called only for a fix that actually places the user inside the radius.
     * The first time an alarm is ever seen, being inside means the user set it
     * for where they already are, so it is suppressed. Every time after that
     * the answer comes from what was persisted, which is what makes it
     * survive a restart.
     */
    fun shouldSuppress(id: String): Boolean {
        val seen = read(KEY_SEEN)
        if (id !in seen) {
            write(KEY_SEEN, seen + id)
            write(KEY_SUPPRESSED, read(KEY_SUPPRESSED) + id)
            return true
        }
        return id in read(KEY_SUPPRESSED)
    }

    /** Records that the user is outside [id], which clears any suppression. */
    fun markOutside(id: String) {
        val seen = read(KEY_SEEN)
        if (id !in seen) write(KEY_SEEN, seen + id)

        val suppressed = read(KEY_SUPPRESSED)
        if (id in suppressed) write(KEY_SUPPRESSED, suppressed - id)
    }

    /**
     * Drops state for alarms that no longer exist, so deleting and re-adding
     * an alarm for the same place behaves like the new alarm it is rather
     * than inheriting the old one's suppression.
     */
    fun forgetAllExcept(liveIds: Collection<String>) {
        val live = liveIds.toSet()
        for (key in arrayOf(KEY_SEEN, KEY_SUPPRESSED)) {
            val kept = read(key).intersect(live)
            if (kept.size != read(key).size) write(key, kept)
        }
    }

    private fun read(key: String): Set<String> =
        prefs.getStringSet(key, emptySet())?.toSet() ?: emptySet()

    private fun write(key: String, value: Set<String>) {
        // A fresh set every time, deliberately: SharedPreferences does not
        // copy the set it is handed, so mutating a previously stored instance
        // corrupts the in-memory cache without ever reaching disk.
        prefs.edit().putStringSet(key, HashSet(value)).apply()
    }

    private companion object {
        const val PREFS_NAME = "locreminder_arrival_state"
        const val KEY_SEEN = "seen"
        const val KEY_SUPPRESSED = "suppressed"
    }
}

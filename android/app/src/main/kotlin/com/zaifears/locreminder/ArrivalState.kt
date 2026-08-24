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

    /**
     * Puts [id] back to needing an exit before it may ring again.
     *
     * Only repeating alarms need this, and they need it badly. A one-shot
     * alarm is deleted the moment it rings, so nothing can ring it twice. A
     * repeating one stays in the store, and the user is still standing inside
     * its radius when it finishes ringing — so the very next fix would find
     * them inside, with no suppression recorded, and ring it again. And the
     * fix after that. Re-suppressing on the way out of the ring is what makes
     * "every Tuesday" mean once each Tuesday rather than continuously for as
     * long as the user stays put.
     */
    fun suppressUntilExit(id: String) {
        write(KEY_SEEN, read(KEY_SEEN) + id)
        write(KEY_SUPPRESSED, read(KEY_SUPPRESSED) + id)
    }

    /**
     * Whether [id] has already rung today.
     *
     * The second guard on a repeating alarm, covering what suppression cannot:
     * leaving the radius and coming back the same afternoon is a genuine
     * re-entry, so suppression clears and the alarm would ring a second time.
     * Once a day is what a daily reminder means.
     *
     * Keyed on the local calendar date, so the boundary is the user's
     * midnight — the one they would expect — rather than 24 hours after the
     * last ring.
     */
    fun hasRungToday(id: String, today: String): Boolean =
        prefs.getString("$KEY_LAST_RUNG_PREFIX$id", null) == today

    /**
     * Records that [id] rang on [today].
     *
     * Deliberately separate from [hasRungToday], which is a pure read. Folding
     * the write into the check looked tidier and was wrong: the check runs
     * before the suppression test, so an alarm that was inspected and then
     * held back — the user was already standing inside it — would be filed as
     * having rung without making a sound. Arriving properly later the same day
     * then found the day already used up, and the alarm stayed silent. Only
     * actually ringing may mark the day.
     */
    fun markRungToday(id: String, today: String) {
        prefs.edit().putString("$KEY_LAST_RUNG_PREFIX$id", today).apply()
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

        // The per-alarm "last rang" keys are separate entries rather than a
        // set, so they need sweeping separately or a deleted alarm leaves one
        // behind for good. Harmless individually; unbounded over years of use.
        val stale = prefs.all.keys.filter {
            it.startsWith(KEY_LAST_RUNG_PREFIX) &&
                it.removePrefix(KEY_LAST_RUNG_PREFIX) !in live
        }
        if (stale.isNotEmpty()) {
            prefs.edit().apply { stale.forEach { remove(it) } }.apply()
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
        const val KEY_LAST_RUNG_PREFIX = "last_rung_"
    }
}

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Glance: line 1 = running job + estimated completion time,
//         line 2 = queue status ("N in queue").
// Completion = started_at + print_time_seconds (estimate from the queue item;
// the live printer ETA would need /printers/{id}/status - see README TODO).
(:glance)
class QueueGlanceView extends WatchUi.GlanceView {
    var line1 as String = "Loading...";
    var line2 as String = "";

    function initialize() {
        GlanceView.initialize();
    }

    function onShow() as Void {
        BambuddyApi.getQueue(method(:onQueue));
    }

    function onQueue(code as Number, data as Dictionary or String or Array or Null) as Void {
        if (code != 200 || !(data instanceof Array)) {
            line1 = "Bambuddy";
            line2 = "Error " + code;
            WatchUi.requestUpdate();
            return;
        }
        var pending = 0;
        var running = null;
        for (var i = 0; i < data.size(); i++) {
            var item = data[i] as Dictionary;
            if (item["status"].equals("printing")) { running = item; }
            else if (item["status"].equals("pending")) { pending++; }
        }
        if (running == null) {
            line1 = "Idle";
        } else {
            var name = running["archive_name"] != null ? running["archive_name"] : running["library_file_name"];
            line1 = (name != null ? name : "Job " + running["id"]) + etaText(running);
        }
        line2 = pending + " in queue";
        WatchUi.requestUpdate();
    }

    // " - done 14:32", or "" if the estimate is unknown.
    function etaText(item as Dictionary) as String {
        var start = parseIso(item["started_at"]);
        var secs = item["print_time_seconds"];
        if (start == null || secs == null) { return ""; }
        var info = Gregorian.info(start.add(new Time.Duration(secs)), Time.FORMAT_SHORT);
        return " - done " + info.hour.format("%02d") + ":" + info.min.format("%02d");
    }

    // Parses "YYYY-MM-DDTHH:MM:SS[...]" (server sends UTC) into a Moment.
    function parseIso(s as String or Null) as Time.Moment? {
        if (s == null || s.length() < 19) { return null; }
        return Gregorian.moment({
            :year => s.substring(0, 4).toNumber(), :month => s.substring(5, 7).toNumber(),
            :day => s.substring(8, 10).toNumber(), :hour => s.substring(11, 13).toNumber(),
            :minute => s.substring(14, 16).toNumber(), :second => s.substring(17, 19).toNumber()
        });
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var h = dc.getHeight();
        dc.drawText(0, h * 0.28, Graphics.FONT_GLANCE, line1, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, h * 0.72, Graphics.FONT_GLANCE, line2, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

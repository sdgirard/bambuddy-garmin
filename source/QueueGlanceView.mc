import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Glance: line 1 = running job + estimated completion time,
//         line 2 = queue status ("N in queue").
// Completion = now + remaining_time (minutes) from GET /printers/{id}/status (live).
// Falls back to started_at + print_time_seconds if the status call fails.
(:glance)
class QueueGlanceView extends WatchUi.GlanceView {
    var line1 as String = "Loading...";
    var line2 as String = "";
    var running as Dictionary? = null;
    var pending as Number = 0;

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
        pending = 0;
        running = null;
        for (var i = 0; i < data.size(); i++) {
            var item = data[i] as Dictionary;
            if (item["status"].equals("printing")) { running = item; }
            else if (item["status"].equals("pending")) { pending++; }
        }
        line2 = pending + " in queue";
        if (running == null) {
            line1 = "Idle";
        } else if (running["printer_id"] != null) {
            line1 = jobName() + etaText();
            BambuddyApi.getPrinterStatus(running["printer_id"], method(:onStatus));
        } else {
            line1 = jobName() + etaText();
        }
        WatchUi.requestUpdate();
    }

    function onStatus(code as Number, data as Dictionary or String or Array or Null) as Void {
        if (code == 200 && data instanceof Dictionary && data["remaining_time"] != null) {
            var eta = Time.now().add(new Time.Duration((data["remaining_time"] as Number) * 60));
            line1 = jobName() + " " + clock(eta);
            if (data["progress"] != null) { line2 = (data["progress"] as Number).toNumber() + "% - " + pending + " in queue"; }
            WatchUi.requestUpdate();
        }
    }

    function jobName() as String {
        var name = running["archive_name"] != null ? running["archive_name"] : running["library_file_name"];
        return name != null ? name : "Job " + running["id"];
    }

    function clock(m as Time.Moment) as String {
        var t = Gregorian.info(m, Time.FORMAT_SHORT);
        return "done " + t.hour.format("%02d") + ":" + t.min.format("%02d");
    }

    // Fallback estimate: " done 14:32", or "" if unknown.
    function etaText() as String {
        var item = running as Dictionary;
        var start = parseIso(item["started_at"]);
        var secs = item["print_time_seconds"];
        if (start == null || secs == null) { return ""; }
        return " " + clock(start.add(new Time.Duration(secs)));
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

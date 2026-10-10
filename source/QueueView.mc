import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Shows one queue item at a time. Swipe/up/down = next/prev, select = start,
// menu (hold) = stop. Fields used: id, status, archive_name, position.
class QueueView extends WatchUi.View {
    var items as Array = [];
    var index as Number = 0;
    var message as String = "Loading...";

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        refresh();
    }

    function refresh() as Void {
        message = "Loading...";
        BambuddyApi.getQueue(method(:onQueue));
        WatchUi.requestUpdate();
    }

    function onQueue(code as Number, data as Dictionary or String or Array or Null) as Void {
        if (code == 200 && data instanceof Array) {
            items = [];
            for (var i = 0; i < data.size(); i++) {
                if ((data[i] as Dictionary)["status"].equals("pending")) { items.add(data[i]); }
            }
            index = 0;
            message = items.size() == 0 ? "Queue empty" : "";
        } else {
            message = "Error " + code;
        }
        WatchUi.requestUpdate();
    }

    function current() as Dictionary? {
        return (items.size() > 0) ? items[index] as Dictionary : null;
    }

    function move(delta as Number) as Void {
        if (items.size() > 0) {
            index = (index + delta + items.size()) % items.size();
            WatchUi.requestUpdate();
        }
    }

    function onResult(code as Number, data as Dictionary or String or Array or Null) as Void {
        message = (code == 200) ? "OK" : "Error " + code;
        WatchUi.requestUpdate();
        refresh();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var item = current();
        if (item == null) {
            dc.drawText(cx, cy, Graphics.FONT_SMALL, message, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }
        var name = item["archive_name"] != null ? item["archive_name"] : "Item " + item["id"];
        dc.drawText(cx, cy - 30, Graphics.FONT_XTINY, (index + 1) + "/" + items.size(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, cy, Graphics.FONT_SMALL, name, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy + 30, Graphics.FONT_XTINY, item["status"] + (message.equals("") ? "" : " - " + message), Graphics.TEXT_JUSTIFY_CENTER);
    }
}

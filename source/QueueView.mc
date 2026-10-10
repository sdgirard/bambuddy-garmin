import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Shows one queue item at a time. Swipe/up/down = next/prev, select = start,
// menu (hold) = stop. Fields used: id, status, archive_name, position.
class QueueView extends WatchUi.View {
    var items as Array = [];
    var index as Number = 0;
    var message as String = "Loading...";
    var nextItem as Dictionary? = null;

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
                var st = (data[i] as Dictionary)["status"];
                if (st.equals("pending") || st.equals("printing")) { items.add(data[i]); }
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

    // Next job = first pending item in queue order.
    function nextPending() as Dictionary? {
        for (var i = 0; i < items.size(); i++) {
            if ((items[i] as Dictionary)["status"].equals("pending")) { return items[i] as Dictionary; }
        }
        return null;
    }

    // "Plate cleared -> start next": ack plate, then start the item if it is staged.
    function startNext() as Void {
        var item = nextPending();
        if (item == null) { message = "Nothing queued"; WatchUi.requestUpdate(); return; }
        if (item["printer_id"] == null) { message = "Assign printer first"; WatchUi.requestUpdate(); return; }
        nextItem = item;
        message = "Starting...";
        WatchUi.requestUpdate();
        BambuddyApi.getPrinterStatus(item["printer_id"], method(:onNextStatus));
    }

    function onNextStatus(code as Number, data as Dictionary or String or Array or Null) as Void {
        if (code != 200 || !(data instanceof Dictionary)) { onResult(code, null); return; }
        if (data["awaiting_plate_clear"] == true) {
            BambuddyApi.clearPlate(nextItem["printer_id"], method(:onNextCleared));
        } else {
            onNextCleared(200, null);
        }
    }

    function onNextCleared(code as Number, data as Dictionary or String or Array or Null) as Void {
        if (code != 200) { onResult(code, null); return; }
        if (nextItem["manual_start"] == true) {
            BambuddyApi.startItem(nextItem["id"], method(:onResult));
        } else {
            onResult(200, null);  // scheduler starts it now that the plate is acked
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

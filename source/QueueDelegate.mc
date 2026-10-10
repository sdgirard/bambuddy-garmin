import Toybox.Lang;
import Toybox.WatchUi;

class QueueDelegate extends WatchUi.BehaviorDelegate {
    var view as QueueView;

    function initialize(v as QueueView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onNextPage() as Boolean { view.move(1); return true; }
    function onPreviousPage() as Boolean { view.move(-1); return true; }

    // Select/tap: start the shown item.
    function onSelect() as Boolean {
        var item = view.current();
        if (item != null) { BambuddyApi.startItem(item["id"], view.method(:onResult)); }
        return true;
    }

    // Hold menu button: stop the shown item.
    function onMenu() as Boolean {
        var item = view.current();
        if (item != null) { BambuddyApi.stopItem(item["id"], view.method(:onResult)); }
        return true;
    }
}

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

    // Select/tap or menu button: action menu (avoids accidental starts).
    function onSelect() as Boolean { return openMenu(); }
    function onMenu() as Boolean { return openMenu(); }

    function openMenu() as Boolean {
        var menu = new WatchUi.Menu2({:title => "Bambuddy"});
        menu.addItem(new WatchUi.MenuItem("Start next", "Plate cleared", :startNext, {}));
        if (view.current() != null) {
            menu.addItem(new WatchUi.MenuItem("Start this", null, :startThis, {}));
            menu.addItem(new WatchUi.MenuItem("Stop this", null, :stopThis, {}));
        }
        menu.addItem(new WatchUi.MenuItem("Refresh", null, :refresh, {}));
        WatchUi.pushView(menu, new ActionMenuDelegate(view), WatchUi.SLIDE_UP);
        return true;
    }
}

class ActionMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view as QueueView;

    function initialize(v as QueueView) {
        Menu2InputDelegate.initialize();
        view = v;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :startNext) {
            // Physical action: confirm before telling Bambuddy the plate is clear.
            var next = view.nextPending();
            var name = (next != null && next["archive_name"] != null) ? next["archive_name"] : "next job";
            WatchUi.pushView(new WatchUi.Confirmation("Plate clear? Start " + name),
                new NextConfirmDelegate(view), WatchUi.SLIDE_IMMEDIATE);
            return;
        }
        var cur = view.current();
        if (id == :startThis && cur != null) { BambuddyApi.startItem(cur["id"], view.method(:onResult)); }
        else if (id == :stopThis && cur != null) { BambuddyApi.stopItem(cur["id"], view.method(:onResult)); }
        else if (id == :refresh) { view.refresh(); }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class NextConfirmDelegate extends WatchUi.ConfirmationDelegate {
    var view as QueueView;

    function initialize(v as QueueView) {
        ConfirmationDelegate.initialize();
        view = v;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) { view.startNext(); }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);  // close action menu
        return true;
    }
}

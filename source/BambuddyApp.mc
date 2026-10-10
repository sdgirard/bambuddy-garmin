import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class BambuddyApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new QueueView();
        return [view, new QueueDelegate(view)];
    }

    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}

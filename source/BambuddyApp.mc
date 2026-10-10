import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
class BambuddyApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new QueueView();
        return [view, new QueueDelegate(view)];
    }

    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new QueueGlanceView()];
    }

    function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }
}

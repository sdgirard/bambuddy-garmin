import Toybox.Application.Properties;
import Toybox.Communications;
import Toybox.Lang;

// Thin client for the Bambuddy REST API (FastAPI, /api/v1, X-API-Key auth).
// Endpoints: GET /queue/, POST /queue/{id}/start, POST /queue/{id}/stop
(:glance)
module BambuddyApi {
    function baseUrl() as String {
        var url = Properties.getValue("serverUrl") as String;
        return url + "/api/v1";
    }

    function options(method as Communications.HttpRequestMethod) as Dictionary {
        return {
            :method => method,
            :headers => {
                "X-API-Key" => Properties.getValue("apiKey"),
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
    }

    function getQueue(cb as Method) as Void {
        Communications.makeWebRequest(baseUrl() + "/queue/", {},
            options(Communications.HTTP_REQUEST_METHOD_GET), cb);
    }

    function getPrinterStatus(id as Number, cb as Method) as Void {
        Communications.makeWebRequest(baseUrl() + "/printers/" + id + "/status", {},
            options(Communications.HTTP_REQUEST_METHOD_GET), cb);
    }

    function startItem(id as Number, cb as Method) as Void {
        Communications.makeWebRequest(baseUrl() + "/queue/" + id + "/start", {},
            options(Communications.HTTP_REQUEST_METHOD_POST), cb);
    }

    function stopItem(id as Number, cb as Method) as Void {
        Communications.makeWebRequest(baseUrl() + "/queue/" + id + "/stop", {},
            options(Communications.HTTP_REQUEST_METHOD_POST), cb);
    }
}

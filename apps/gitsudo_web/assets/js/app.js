// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: {} })

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

import InPlaceEditor from "./svelte/InPlaceEditor.svelte"
import RepoLabels from "./svelte/RepoLabels.svelte"
import TeamPermissionsEditor from "./svelte/TeamPermissionsEditor.svelte"
import CollaboratorsEditor from "./svelte/CollaboratorsEditor.svelte"

import component from "svelte-tag"

new component({ component: InPlaceEditor, tagname: "svelte-in-place-editor", attributes: ["org", "id", "text"] });
new component({ component: RepoLabels, tagname: "svelte-repo-labels", attributes: ["org", "repo"] });
new component({ component: TeamPermissionsEditor, tagname: "svelte-team-permissions-editor", attributes: ["org", "id", "labelid", "teampermissions"] });
new component({ component: CollaboratorsEditor, tagname: "svelte-collaborators-editor", attributes: ["org", "id", "label", "collaborators"] });

window.replace = (elementId, component) => {
    el = document.getElementById(elementId)
    replacement = document.createElement("svelte-in-place-editor")
    el.getAttributeNames().filter(attr => attr.startsWith("data-"))
        .forEach(attr => {
            const name = attr.substring(5);
            replacement.setAttribute(name, el.getAttribute(attr))
        });
    el.replaceWith(replacement);
}

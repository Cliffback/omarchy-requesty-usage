import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  // Injected by omarchy-shell (the plugin service loader).
  property var shell: null

  // Resolves next to this file, so the service works from any install path.
  readonly property string scriptPath: {
    var url = Qt.resolvedUrl("scripts/update-requesty").toString()
    if (url.indexOf("file://") === 0) url = decodeURIComponent(url.substring(7))
    return url
  }

  // The script caches the API responses internally, so the wall-clock cadence
  // here is cheap: without a resolvable credential it exits immediately, and a
  // failed fetch leaves the previous record untouched.
  readonly property int intervalSec: 300

  function refresh(force) {
    if (updateProc.running) return
    var command = ["bash", "-c", "[[ -x \"$1\" ]] && { p=$1; shift; exec \"$p\" \"$@\"; }", "bash", root.scriptPath]
    if (force === true) command.push("--force")
    updateProc.command = command
    updateProc.running = true
  }

  IpcHandler {
    target: "cliffback.requesty"

    function refresh(): string { root.refresh(true); return "ok" }
  }

  Timer {
    interval: root.intervalSec * 1000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: updateProc

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim() !== "") console.warn("requesty", text.trim())
    }
  }
}

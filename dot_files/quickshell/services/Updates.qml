pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// System image update checker for bootc / rpm-ostree systems.
//
// Flow (all unprivileged, no polkit prompts):
//   1. `rpm-ostree status --json` -> booted image ref + digest, staged deployment
//   2. `skopeo inspect` on that ref -> digest currently published in the registry
//   3. Compare: same digest = up to date; staged digest matches = reboot to apply;
//      otherwise an update is available.
Singleton {
    id: root

    property bool checking: false
    property int updateCount: 0
    property var updates: []
    property string lastChecked: ""
    property string error: ""

    // Image info
    property string imageRef: ""        // e.g. ghcr.io/binarypie/hypercube:latest
    property string bootedDigest: ""
    property string remoteDigest: ""
    property bool rebootRequired: false // a newer deployment is already staged

    property bool needsAttention: updateCount > 0 || rebootRequired

    // Turn an ostree container ref into something skopeo understands.
    //   ostree-image-signed:docker://ghcr.io/x/y:tag   -> ghcr.io/x/y:tag
    //   ostree-unverified-registry:ghcr.io/x/y:tag     -> ghcr.io/x/y:tag
    //   ostree-remote-image:remote:docker://ghcr.io/.. -> ghcr.io/..
    function normalizeRef(ref: string): string {
        if (!ref) return ""
        const docker = ref.indexOf("docker://")
        if (docker !== -1) return ref.substring(docker + 9)
        const registry = ref.lastIndexOf("registry:")
        if (registry !== -1) return ref.substring(registry + 9)
        return ""
    }

    function finish(err: string) {
        root.error = err
        root.checking = false
        root.lastChecked = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm")

        const list = []
        if (root.updateCount > 0) list.push("New image available: " + root.imageRef)
        if (root.rebootRequired) list.push("Update staged — reboot to apply")
        root.updates = list
    }

    property string stagedDigest: ""

    Process {
        id: statusProcess
        command: ["rpm-ostree", "status", "--json"]
        stdout: StdioCollector {
            id: statusOut
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.finish("rpm-ostree status failed (" + exitCode + ")")
                return
            }
            try {
                const data = JSON.parse(statusOut.text)
                const deployments = data.deployments || []
                const booted = deployments.find(d => d.booted)
                const staged = deployments.find(d => d.staged)

                if (!booted) {
                    root.finish("No booted deployment found")
                    return
                }

                root.imageRef = root.normalizeRef(booted["container-image-reference"] || "")
                root.bootedDigest = booted["container-image-reference-digest"] || ""
                root.stagedDigest = staged ? (staged["container-image-reference-digest"] || "") : ""
                root.rebootRequired = !!staged

                if (!root.imageRef) {
                    root.updateCount = 0
                    root.finish("Booted deployment is not a container image")
                    return
                }

                inspectProcess.command = ["skopeo", "inspect", "--retry-times", "2",
                                          "--format", "{{.Digest}}",
                                          "docker://" + root.imageRef]
                inspectProcess.running = true
            } catch (e) {
                root.finish("Failed to parse rpm-ostree status: " + e)
            }
        }
    }

    Process {
        id: inspectProcess
        stdout: StdioCollector {
            id: inspectOut
        }
        stderr: StdioCollector {
            id: inspectErr
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                // Offline or registry error: still report a staged update if any
                root.updateCount = 0
                const msg = inspectErr.text.trim().split("\n").pop() || ("exit " + exitCode)
                root.finish("Registry check failed: " + msg)
                return
            }

            root.remoteDigest = inspectOut.text.trim()

            if (root.remoteDigest === root.bootedDigest) {
                // Running the latest image; anything staged is stale/rollback
                root.updateCount = 0
                root.rebootRequired = false
            } else if (root.remoteDigest === root.stagedDigest) {
                // Latest image already downloaded and staged
                root.updateCount = 0
                root.rebootRequired = true
            } else {
                root.updateCount = 1
            }
            root.finish("")
        }
    }

    function checkUpdates() {
        if (root.checking) return
        root.checking = true
        root.error = ""
        statusProcess.running = true
    }

    // Auto-check: shortly after startup (network may not be up yet), then every 6 hours
    Timer {
        interval: 6 * 60 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.checkUpdates()
    }

    Timer {
        interval: 30 * 1000
        running: true
        repeat: false
        onTriggered: root.checkUpdates()
    }

    function summary(): string {
        if (checking) return "Checking for updates..."
        if (error) return error
        if (rebootRequired) return "Update staged — reboot to apply"
        if (updateCount > 0) return "New system image available"
        return "System is up to date"
    }
}

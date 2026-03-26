/*! coi-service-worker v0.1.7 - Guido Zuidhof and contributors, licensed under MIT */
let coepCredentialless = false;
if (typeof window === 'undefined') {
    self.addEventListener("install", () => self.skipWaiting());
    self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));

    self.addEventListener("message", (ev) => {
        if (ev.data && ev.data.type === "deregister") {
            self.registration
                .unregister()
                .then(() => {
                    return self.clients.matchAll();
                })
                .then((clients) => {
                    clients.forEach((client) => client.navigate(client.url));
                });
        }
    });

    self.addEventListener("fetch", function (event) {
        if (
            event.request.cache === "only-if-cached" &&
            event.request.mode !== "same-origin"
        ) {
            return;
        }

        event.respondWith(
            fetch(event.request)
                .then((response) => {
                    if (response.status === 0) {
                        return response;
                    }

                    const newHeaders = new Headers(response.headers);
                    newHeaders.set(
                        "Cross-Origin-Embedder-Policy",
                        coepCredentialless ? "credentialless" : "require-corp"
                    );
                    newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");

                    return new Response(response.body, {
                        status: response.status,
                        statusText: response.statusText,
                        headers: newHeaders,
                    });
                })
                .catch((e) => console.error(e))
        );
    });
} else {
    (() => {
        const reloadedBySelf = window.sessionStorage.getItem("coiReloadedBySelf");
        window.sessionStorage.removeItem("coiReloadedBySelf");
        const coepDegrading = reloadedBySelf === "coepdegrade";

        // You can customize the behavior of this script through a global `cpiConfig` variable.
        const n = {
            shouldRegister: () => !reloadedBySelf,
            shouldDeregister: () => false,
            coepCredentialless: () => true,
            coepDegrade: () => true,
            doReload: () => window.location.reload(),
            quiet: false,
            ...window.coi,
        };

        if (n.shouldDeregister()) {
            if (window.navigator && window.navigator.serviceWorker) {
                window.navigator.serviceWorker.controller &&
                    window.navigator.serviceWorker.controller.postMessage({
                        type: "deregister",
                    });
            }
            return;
        }

        if (
            !window.crossOriginIsolated &&
            !window.SharedArrayBuffer &&
            window.navigator &&
            window.navigator.serviceWorker
        ) {
            if (n.shouldRegister()) {
                window.navigator.serviceWorker
                    .register(window.document.currentScript.src)
                    .then(
                        (registration) => {
                            !n.quiet &&
                                console.log(
                                    "COOP/COEP Service Worker registered",
                                    registration.scope
                                );

                            registration.addEventListener("updatefound", () => {
                                !n.quiet &&
                                    console.log(
                                        "Reloading page to make use of updated COI Service Worker."
                                    );

                                window.sessionStorage.setItem(
                                    "coiReloadedBySelf",
                                    "coiReload"
                                );
                                n.doReload();
                            });

                            if (registration.active && !window.navigator.serviceWorker.controller) {
                                !n.quiet &&
                                    console.log(
                                        "Reloading page to make use of COI Service Worker."
                                    );

                                window.sessionStorage.setItem(
                                    "coiReloadedBySelf",
                                    "coiReload"
                                );
                                n.doReload();
                            }
                        },
                        (err) => {
                            !n.quiet &&
                                console.error(
                                    "COOP/COEP Service Worker failed to register:",
                                    err
                                );
                        }
                    );
            }

            coepCredentialless = n.coepCredentialless();

            if (coepDegrading) {
                !n.quiet &&
                    console.log(
                        "Processing COEP degrade. (This may be conveniently audited with `document.reloadedBySelf`.)"
                    );
                document.reloadedBySelf = true;
            }

            if (
                n.coepDegrade() &&
                !(coepDegrading && window.SharedArrayBuffer)
            ) {
                window.sessionStorage.setItem(
                    "coiReloadedBySelf",
                    "coepdegrade"
                );
                n.doReload();
            }
        }
    })();
}

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      // Mount Flutter inside the constrained div (mobile frame on desktop)
      hostElement: document.querySelector("#flutter_target"),
    });
    await appRunner.runApp();
  },
});

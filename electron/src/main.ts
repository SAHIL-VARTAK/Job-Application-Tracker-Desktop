import { app, BrowserWindow } from "electron";
import path from "node:path";

function createWindow(): void {
  const window = new BrowserWindow({
    width: 1280,
    height: 800,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  const frontendPath = path.resolve(
    app.getAppPath(),
    "../workspace/Job-Application-Tracker-UI/dist/index.html"
  );

  console.log("Frontend path:", frontendPath);

  window.loadFile(frontendPath);
}

app.whenReady().then(() => {
  createWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});
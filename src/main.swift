import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    let printerName = "HP_LaserJet_Pro_M102a"
    var currentStatusText = "Проверка..."
    var isPrinterOnline = false
    var isPrinting = false
    var activeJobs: [(id: String, user: String, size: String, date: String)] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIcon(state: .checking)
        
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        
        refreshPrinterStatus()
        
        // Periodic background poll
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.refreshPrinterStatus()
        }
    }
    
    enum State {
        case ready, printing, offline, checking
    }
    
    func updateStatusIcon(state: State) {
        guard let button = statusItem.button else { return }
        
        let symbolName: String
        switch state {
        case .ready:
            symbolName = "printer.fill"
        case .printing:
            symbolName = "printer.fill"
        case .offline:
            symbolName = "printer.slash.fill"
        case .checking:
            symbolName = "printer"
        }
        
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "HP LaserJet Pro M102a") {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            let configuredImage = image.withSymbolConfiguration(config) ?? image
            button.image = configuredImage
            button.imagePosition = .imageLeft
        } else {
            button.title = "🖨 HP"
        }
    }
    
    func refreshPrinterStatus() {
        DispatchQueue.global(qos: .background).async {
            let lpstatOutput = self.runShell("lpstat -p \(self.printerName) 2>&1")
            let jobsOutput = self.runShell("lpstat -o \(self.printerName) 2>&1")
            
            var newJobs: [(id: String, user: String, size: String, date: String)] = []
            let jobLines = jobsOutput.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            for line in jobLines {
                if line.contains(self.printerName) {
                    let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                    if parts.count >= 4 {
                        let id = String(parts[0])
                        let user = String(parts[1])
                        let size = String(parts[2]) + " B"
                        let date = parts.dropFirst(3).joined(separator: " ")
                        newJobs.append((id: id, user: user, size: size, date: date))
                    }
                }
            }
            
            let isOnline: Bool
            let isPrint: Bool
            let statusText: String
            
            if lpstatOutput.contains("свободен") || lpstatOutput.contains("is idle") || lpstatOutput.contains("ready") {
                isOnline = true
                isPrint = false
                statusText = "Готов к печати"
            } else if lpstatOutput.contains("сейчас печатает") || lpstatOutput.contains("is printing") || !newJobs.isEmpty {
                isOnline = true
                isPrint = true
                statusText = "Идет печать..."
            } else if lpstatOutput.contains("отключен") || lpstatOutput.contains("disabled") || lpstatOutput.contains("No such") {
                isOnline = false
                isPrint = false
                statusText = "Принтер отключен или не найден"
            } else {
                isOnline = true
                isPrint = false
                statusText = "Подключен"
            }
            
            DispatchQueue.main.async {
                self.isPrinterOnline = isOnline
                self.isPrinting = isPrint
                self.currentStatusText = statusText
                self.activeJobs = newJobs
                
                if !isOnline {
                    self.updateStatusIcon(state: .offline)
                } else if isPrint {
                    self.updateStatusIcon(state: .printing)
                } else {
                    self.updateStatusIcon(state: .ready)
                }
            }
        }
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        
        // 1. Header with model name
        let titleItem = NSMenuItem(title: "HP LaserJet Pro M102a", action: nil, keyEquivalent: "")
        titleItem.attributedTitle = NSAttributedString(string: "HP LaserJet Pro M102a", attributes: [
            .font: NSFont.boldSystemFont(ofSize: 13)
        ])
        menu.addItem(titleItem)
        
        // Status indicator
        let statusDot = isPrinterOnline ? (isPrinting ? "🟠" : "🟢") : "🔴"
        let statusItemMenu = NSMenuItem(title: "  \(statusDot) \(currentStatusText)", action: nil, keyEquivalent: "")
        statusItemMenu.isEnabled = false
        menu.addItem(statusItemMenu)
        
        let portItem = NSMenuItem(title: "  🔌 Подключение: USB (Hi-Speed)", action: nil, keyEquivalent: "")
        portItem.isEnabled = false
        menu.addItem(portItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. Jobs section
        let jobsHeader = NSMenuItem(title: "Очередь печати (\(activeJobs.count))", action: nil, keyEquivalent: "")
        jobsHeader.attributedTitle = NSAttributedString(string: "Очередь печати (\(activeJobs.count))", attributes: [
            .font: NSFont.boldSystemFont(ofSize: 12)
        ])
        menu.addItem(jobsHeader)
        
        if activeJobs.isEmpty {
            let emptyItem = NSMenuItem(title: "  Нет активных заданий", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for job in activeJobs {
                let jobItem = NSMenuItem(title: "  📄 \(job.id) (\(job.size))", action: nil, keyEquivalent: "")
                let jobSubmenu = NSMenu()
                let cancelItem = NSMenuItem(title: "Отменить это задание", action: #selector(cancelJobClicked(_:)), keyEquivalent: "")
                cancelItem.target = self
                cancelItem.representedObject = job.id
                jobSubmenu.addItem(cancelItem)
                jobItem.submenu = jobSubmenu
                menu.addItem(jobItem)
            }
            
            let clearAllItem = NSMenuItem(title: "  🗑 Отменить все задания", action: #selector(clearAllJobs), keyEquivalent: "")
            clearAllItem.target = self
            menu.addItem(clearAllItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Quick Actions
        let actionsHeader = NSMenuItem(title: "Действия", action: nil, keyEquivalent: "")
        actionsHeader.attributedTitle = NSAttributedString(string: "Действия", attributes: [
            .font: NSFont.boldSystemFont(ofSize: 12)
        ])
        menu.addItem(actionsHeader)
        
        let testPrintItem = NSMenuItem(title: "🖨  Напечатать тестовую страницу", action: #selector(printTestPage), keyEquivalent: "t")
        testPrintItem.target = self
        menu.addItem(testPrintItem)
        
        let openQueueItem = NSMenuItem(title: "📋  Открыть системную очередь...", action: #selector(openSystemQueue), keyEquivalent: "o")
        openQueueItem.target = self
        menu.addItem(openQueueItem)
        
        let prefsItem = NSMenuItem(title: "⚙️  Настройки принтеров macOS...", action: #selector(openMacSettings), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        let cupsWebItem = NSMenuItem(title: "🌐  Панель управления CUPS (Web)...", action: #selector(openCupsWeb), keyEquivalent: "")
        cupsWebItem.target = self
        menu.addItem(cupsWebItem)
        
        let diagItem = NSMenuItem(title: "🔍  Диагностика USB и состояния...", action: #selector(runDiagnostics), keyEquivalent: "d")
        diagItem.target = self
        menu.addItem(diagItem)
        
        let restartCupsItem = NSMenuItem(title: "🔄  Перезапустить службу печати", action: #selector(restartCupsService), keyEquivalent: "r")
        restartCupsItem.target = self
        menu.addItem(restartCupsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. App controls
        let refreshItem = NSMenuItem(title: "Обновить статус", action: #selector(manualRefresh), keyEquivalent: "")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        let autoLaunchItem = NSMenuItem(title: "Запускать при входе в macOS", action: #selector(toggleAutoLaunch(_:)), keyEquivalent: "")
        autoLaunchItem.target = self
        autoLaunchItem.state = isAutoLaunchEnabled() ? .on : .off
        menu.addItem(autoLaunchItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Завершить", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    @objc func manualRefresh() {
        refreshPrinterStatus()
    }
    
    @objc func printTestPage() {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.runShell("lp -d \(self.printerName) /usr/share/cups/data/testprint")
            DispatchQueue.main.async {
                self.showAlert(title: "Тестовая страница отправлена", message: "Задание на печать тестовой страницы успешно отправлено в очередь принтера HP LaserJet Pro M102a.")
                self.refreshPrinterStatus()
            }
        }
    }
    
    @objc func openSystemQueue() {
        _ = runShell("open /System/Library/PreferencePanes/PrintAndScan.prefPane 2>/dev/null || open 'x-apple.systempreferences:com.apple.Print-Scan-Settings.extension'")
    }
    
    @objc func openMacSettings() {
        _ = runShell("open 'x-apple.systempreferences:com.apple.Print-Scan-Settings.extension' 2>/dev/null || open /System/Library/PreferencePanes/PrintAndScan.prefPane")
    }
    
    @objc func openCupsWeb() {
        if let url = URL(string: "http://localhost:631/printers/\(printerName)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func cancelJobClicked(_ sender: NSMenuItem) {
        guard let jobId = sender.representedObject as? String else { return }
        _ = runShell("cancel \(jobId)")
        refreshPrinterStatus()
    }
    
    @objc func clearAllJobs() {
        _ = runShell("cancel -a \(printerName)")
        refreshPrinterStatus()
        showAlert(title: "Очередь очищена", message: "Все активные задания для принтера были отменены.")
    }
    
    @objc func restartCupsService() {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.runShell("cupsenable \(self.printerName); cupsaccept \(self.printerName)")
            DispatchQueue.main.async {
                self.showAlert(title: "Служба очереди обновлена", message: "Очередь печати \(self.printerName) разблокирована и готова к приему заданий.")
                self.refreshPrinterStatus()
            }
        }
    }
    
    @objc func runDiagnostics() {
        let usbInfo = runShell("system_profiler SPUSBDataType 2>/dev/null | grep -A 8 -i 'LaserJet' || echo 'Принтер не обнаружен на USB шине'")
        let cupsInfo = runShell("lpstat -p \(printerName) -l 2>&1")
        
        let diagReport = """
        === Статус CUPS ===
        \(cupsInfo.trimmingCharacters(in: .whitespacesAndNewlines))
        
        === USB Подключение ===
        \(usbInfo.trimmingCharacters(in: .whitespacesAndNewlines))
        """
        
        showAlert(title: "Диагностика HP LaserJet Pro M102a", message: diagReport)
    }
    
    @objc func toggleAutoLaunch(_ sender: NSMenuItem) {
        let appPath = Bundle.main.bundlePath
        let plistName = "com.custom.hp.laserjet.menubar.plist"
        let launchAgentsDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
        let plistURL = launchAgentsDir.appendingPathComponent(plistName)
        
        if isAutoLaunchEnabled() {
            try? FileManager.default.removeItem(at: plistURL)
            showAlert(title: "Автозапуск отключен", message: "Приложение больше не будет автоматически запускаться при входе в систему.")
        } else {
            try? FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>com.custom.hp.laserjet.menubar</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(appPath)/Contents/MacOS/HP LaserJet Manager</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>KeepAlive</key>
                <false/>
            </dict>
            </plist>
            """
            try? plistContent.write(to: plistURL, atomically: true, encoding: .utf8)
            showAlert(title: "Автозапуск включен", message: "Приложение будет автоматически запускаться в строке меню при входе в систему.")
        }
    }
    
    func isAutoLaunchEnabled() -> Bool {
        let plistURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents/com.custom.hp.laserjet.menubar.plist")
        return FileManager.default.fileExists(atPath: plistURL.path)
    }
    
    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func runShell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

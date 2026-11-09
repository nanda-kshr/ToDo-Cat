import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    MenuBarCompanionManager.shared.start()
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Keep app running in the menu bar when the window is closed
    return !MenuBarCompanionManager.shared.isEnabled
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

// MARK: - Task Item Model
struct MenuTaskItem {
  let id: String
  let title: String
  var completed: Bool
  let priority: String
}

// MARK: - Flipped Coordinate View
class FlippedView: NSView {
  override var isFlipped: Bool { true }
}

// MARK: - Custom Checkbox Button
class TaskCheckboxButton: NSButton {
  var taskId: String = ""
  var isTaskCompleted: Bool = false {
    didSet { needsDisplay = true }
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    isBordered = false
    title = ""
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    isBordered = false
    title = ""
  }

  override func draw(_ dirtyRect: NSRect) {
    let circleRect = bounds.insetBy(dx: 2, dy: 2)
    let path = NSBezierPath(ovalIn: circleRect)
    if isTaskCompleted {
      // TodoCat muted sage green
      NSColor(red: 0.28, green: 0.65, blue: 0.45, alpha: 0.95).setFill()
      path.fill()

      let checkPath = NSBezierPath()
      checkPath.move(to: NSPoint(x: circleRect.minX + circleRect.width * 0.28, y: circleRect.midY))
      checkPath.line(to: NSPoint(x: circleRect.minX + circleRect.width * 0.44, y: circleRect.minY + circleRect.height * 0.28))
      checkPath.line(to: NSPoint(x: circleRect.minX + circleRect.width * 0.74, y: circleRect.minY + circleRect.height * 0.72))
      checkPath.lineWidth = 1.6
      checkPath.lineCapStyle = .round
      checkPath.lineJoinStyle = .round
      NSColor.white.setStroke()
      checkPath.stroke()
    } else {
      NSColor.tertiaryLabelColor.setStroke()
      path.lineWidth = 1.5
      path.stroke()
    }
  }
}

// MARK: - Cute Menu Bar Popover View Controller
class MenuBarPopoverViewController: NSViewController {
  weak var manager: MenuBarCompanionManager?

  let popoverWidth: CGFloat = 270
  let popoverHeight: CGFloat = 310

  private var countBadgeLabel: NSTextField!
  private var countBadgeView: NSView!
  private var runnerSegment: NSSegmentedControl!
  private var scrollView: NSScrollView!
  private var taskContentView: FlippedView!

  private var currentTasks: [MenuTaskItem] = []
  private var currentActiveCount: Int = 0
  private var currentRunner: String = "cat"

  override func loadView() {
    let effectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: popoverWidth, height: popoverHeight))
    effectView.material = .popover
    effectView.blendingMode = .behindWindow
    effectView.state = .active
    self.view = effectView

    // Header
    let headerHeight: CGFloat = 38
    let header = NSView(frame: NSRect(x: 0, y: popoverHeight - headerHeight, width: popoverWidth, height: headerHeight))

    let titleLabel = NSTextField(labelWithString: "TodoCat")
    titleLabel.font = .systemFont(ofSize: 13, weight: .bold)
    titleLabel.textColor = .labelColor
    titleLabel.frame = NSRect(x: 12, y: 9, width: 60, height: 20)
    header.addSubview(titleLabel)

    let badgeView = NSView(frame: NSRect(x: 76, y: 10, width: 62, height: 18))
    badgeView.wantsLayer = true
    badgeView.layer?.cornerRadius = 9
    badgeView.layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.15).cgColor

    let badgeLabel = NSTextField(labelWithString: "0 active")
    badgeLabel.font = .systemFont(ofSize: 10, weight: .semibold)
    badgeLabel.textColor = .systemOrange
    badgeLabel.alignment = .center
    badgeLabel.frame = NSRect(x: 4, y: 1, width: 54, height: 16)
    badgeView.addSubview(badgeLabel)
    header.addSubview(badgeView)
    self.countBadgeView = badgeView
    self.countBadgeLabel = badgeLabel

    let quitBtn = NSButton(title: "Quit", target: self, action: #selector(onQuitClicked))
    quitBtn.font = .systemFont(ofSize: 11, weight: .regular)
    quitBtn.bezelStyle = .inline
    quitBtn.isBordered = false
    quitBtn.contentTintColor = .secondaryLabelColor
    quitBtn.frame = NSRect(x: popoverWidth - 44, y: 9, width: 34, height: 20)
    header.addSubview(quitBtn)

    let headerLine = NSBox(frame: NSRect(x: 0, y: 0, width: popoverWidth, height: 0.5))
    headerLine.boxType = .custom
    headerLine.borderColor = .clear
    headerLine.fillColor = NSColor.separatorColor.withAlphaComponent(0.4)
    header.addSubview(headerLine)

    effectView.addSubview(header)

    // Scrollable Task List
    let footerHeight: CGFloat = 38
    let scrollHeight = popoverHeight - headerHeight - footerHeight
    let scroll = NSScrollView(frame: NSRect(x: 0, y: footerHeight, width: popoverWidth, height: scrollHeight))
    scroll.hasVerticalScroller = true
    scroll.autohidesScrollers = true
    scroll.drawsBackground = false
    scroll.borderType = .noBorder

    let doc = FlippedView(frame: NSRect(x: 0, y: 0, width: popoverWidth, height: scrollHeight))
    scroll.documentView = doc
    effectView.addSubview(scroll)
    self.scrollView = scroll
    self.taskContentView = doc

    // Footer
    let footer = NSView(frame: NSRect(x: 0, y: 0, width: popoverWidth, height: footerHeight))
    let footerLine = NSBox(frame: NSRect(x: 0, y: footerHeight - 0.5, width: popoverWidth, height: 0.5))
    footerLine.boxType = .custom
    footerLine.borderColor = .clear
    footerLine.fillColor = NSColor.separatorColor.withAlphaComponent(0.4)
    footer.addSubview(footerLine)

    let seg = NSSegmentedControl(labels: ["Cat", "Bunny"], trackingMode: .selectOne, target: self, action: #selector(onRunnerSegmentChanged(_:)))
    seg.controlSize = .small
    seg.frame = NSRect(x: 12, y: 8, width: 100, height: 22)
    footer.addSubview(seg)
    self.runnerSegment = seg

    let openBtn = NSButton(title: "Open App ↗", target: self, action: #selector(onOpenClicked))
    openBtn.font = .systemFont(ofSize: 11, weight: .medium)
    openBtn.bezelStyle = .roundRect
    openBtn.frame = NSRect(x: popoverWidth - 92, y: 7, width: 80, height: 24)
    footer.addSubview(openBtn)

    effectView.addSubview(footer)
  }

  func update(tasks: [MenuTaskItem], activeCount: Int, runner: String) {
    self.currentTasks = tasks
    self.currentActiveCount = activeCount
    self.currentRunner = runner

    guard isViewLoaded else { return }

    // 1. Badge updates
    if activeCount > 0 {
      countBadgeLabel.stringValue = "\(activeCount) active"
      countBadgeLabel.textColor = .systemOrange
      countBadgeView.layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.15).cgColor
    } else {
      countBadgeLabel.stringValue = "Caught up"
      countBadgeLabel.textColor = NSColor(red: 0.28, green: 0.65, blue: 0.45, alpha: 1.0)
      countBadgeView.layer?.backgroundColor = NSColor(red: 0.28, green: 0.65, blue: 0.45, alpha: 0.15).cgColor
    }

    // 2. Runner segment
    runnerSegment.selectedSegment = (runner == "bunny") ? 1 : 0

    // 3. Render task rows
    renderTasks()
  }

  private func renderTasks() {
    taskContentView.subviews.forEach { $0.removeFromSuperview() }

    if currentTasks.isEmpty {
      let emptyBox = NSView(frame: NSRect(x: 0, y: 0, width: popoverWidth, height: scrollView.frame.height))

      let emptyLabel = NSTextField(labelWithString: "All caught up")
      emptyLabel.font = .systemFont(ofSize: 12, weight: .semibold)
      emptyLabel.textColor = .secondaryLabelColor
      emptyLabel.alignment = .center
      emptyLabel.frame = NSRect(x: 10, y: scrollView.frame.height / 2 - 12, width: popoverWidth - 20, height: 18)
      emptyBox.addSubview(emptyLabel)

      let emptySub = NSTextField(labelWithString: "Enjoy your focus time")
      emptySub.font = .systemFont(ofSize: 10, weight: .regular)
      emptySub.textColor = .tertiaryLabelColor
      emptySub.alignment = .center
      emptySub.frame = NSRect(x: 10, y: scrollView.frame.height / 2 + 8, width: popoverWidth - 20, height: 16)
      emptyBox.addSubview(emptySub)

      taskContentView.addSubview(emptyBox)
      taskContentView.frame = NSRect(x: 0, y: 0, width: popoverWidth, height: scrollView.frame.height)
      return
    }

    let rowHeight: CGFloat = 32.0
    let totalHeight = max(scrollView.frame.height, CGFloat(currentTasks.count) * rowHeight + 8.0)
    taskContentView.frame = NSRect(x: 0, y: 0, width: popoverWidth, height: totalHeight)

    for (index, task) in currentTasks.enumerated() {
      let rowY = 4.0 + CGFloat(index) * rowHeight

      // Checkbox
      let check = TaskCheckboxButton(frame: NSRect(x: 12, y: rowY + 6, width: 18, height: 18))
      check.taskId = task.id
      check.isTaskCompleted = task.completed
      check.target = self
      check.action = #selector(onCheckboxTapped(_:))
      taskContentView.addSubview(check)

      // Title
      let titleField = NSTextField(labelWithString: task.title)
      titleField.frame = NSRect(x: 36, y: rowY + 6, width: popoverWidth - 54, height: 18)
      titleField.lineBreakMode = .byTruncatingTail

      if task.completed {
        let attr = NSMutableAttributedString(string: task.title)
        attr.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: task.title.count))
        attr.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: NSRange(location: 0, length: task.title.count))
        titleField.attributedStringValue = attr
        titleField.font = .systemFont(ofSize: 12, weight: .regular)
      } else {
        titleField.font = .systemFont(ofSize: 12, weight: .medium)
        titleField.textColor = .labelColor
      }
      taskContentView.addSubview(titleField)

      // Row click area: click row to open app
      let rowClickBtn = NSButton(frame: NSRect(x: 34, y: rowY, width: popoverWidth - 34, height: rowHeight))
      rowClickBtn.isTransparent = true
      rowClickBtn.target = self
      rowClickBtn.action = #selector(onRowClicked)
      taskContentView.addSubview(rowClickBtn)

      // Divider line
      if index < currentTasks.count - 1 {
        let line = NSBox(frame: NSRect(x: 36, y: rowY + rowHeight - 0.5, width: popoverWidth - 48, height: 0.5))
        line.boxType = .custom
        line.borderColor = .clear
        line.fillColor = NSColor.separatorColor.withAlphaComponent(0.3)
        taskContentView.addSubview(line)
      }
    }
  }

  @objc private func onCheckboxTapped(_ sender: TaskCheckboxButton) {
    sender.isTaskCompleted.toggle()
    manager?.toggleTask(id: sender.taskId, completed: sender.isTaskCompleted)
  }

  @objc private func onRowClicked() {
    manager?.openAppWindow()
    manager?.closePopover()
  }

  @objc private func onOpenClicked() {
    manager?.openAppWindow()
    manager?.closePopover()
  }

  @objc private func onQuitClicked() {
    manager?.quitApp()
  }

  @objc private func onRunnerSegmentChanged(_ sender: NSSegmentedControl) {
    let runner = (sender.selectedSegment == 1) ? "bunny" : "cat"
    manager?.setRunnerFromMenu(runner)
  }
}

// MARK: - Menu Bar Companion Manager
class MenuBarCompanionManager: NSObject, NSPopoverDelegate {
  static let shared = MenuBarCompanionManager()

  private var statusItem: NSStatusItem?
  private var timer: Timer?
  private var channel: FlutterMethodChannel?
  private weak var mainWindow: NSWindow?

  private let popover = NSPopover()
  private var popoverController: MenuBarPopoverViewController?
  private var lastClosedTime: Date = .distantPast

  private(set) var isEnabled: Bool = true
  private var currentRunner: String = "cat"
  private var isWhite: Bool = false
  private var isSleeping: Bool = false
  private var speedPercent: Int = 15
  private var speedMessage: String = "All caught up"
  private var activeCount: Int = 0
  private var todayTotalCount: Int = 0
  private var taskItems: [MenuTaskItem] = []

  private var currentFrameIndex: Int = 0
  private var cachedFrames: [NSImage] = []
  private var cachedFolder: String = ""
  private var cachedState: String = ""

  func setup(with messenger: FlutterBinaryMessenger, window: NSWindow?) {
    self.mainWindow = window
    let chan = FlutterMethodChannel(name: "com.todocat.app/macos_menu_bar", binaryMessenger: messenger)
    self.channel = chan

    chan.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(false)
        return
      }

      switch call.method {
      case "updateMenuBar":
        if let args = call.arguments as? [String: Any] {
          self.updateState(from: args)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Arguments must be a Map", details: nil))
        }

      case "setEnabled":
        if let args = call.arguments as? [String: Any], let enabled = args["enabled"] as? Bool {
          self.setEnabled(enabled)
          result(true)
        } else {
          result(false)
        }

      case "isEnabled":
        result(self.isEnabled)

      case "openWindow":
        self.openAppWindow()
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func start() {
    guard isEnabled, statusItem == nil else { return }

    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    self.statusItem = item

    if let button = item.button {
      button.imagePosition = .imageOnly
      button.imageScaling = .scaleProportionallyDown
      button.toolTip = "TodoCat"
      button.target = self
      button.action = #selector(handleStatusItemClick(_:))
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    // Configure NSPopover
    popover.behavior = .transient
    popover.animates = true
    popover.delegate = self
    let controller = MenuBarPopoverViewController()
    controller.manager = self
    self.popoverController = controller
    popover.contentViewController = controller

    if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
      self.isWhite = true
    }

    reloadFrames()
    restartTimer()
  }

  func setEnabled(_ enabled: Bool) {
    self.isEnabled = enabled
    if enabled {
      if statusItem == nil {
        start()
      } else {
        reloadFrames()
        restartTimer()
      }
    } else {
      timer?.invalidate()
      timer = nil
      closePopover()
      if let item = statusItem {
        NSStatusBar.system.removeStatusItem(item)
        statusItem = nil
      }
    }
  }

  private func updateState(from args: [String: Any]) {
    let runner = (args["runner"] as? String) ?? currentRunner
    let speed = (args["speedPercent"] as? Int) ?? speedPercent
    let msg = (args["speedMessage"] as? String) ?? speedMessage
    let catWhite = (args["isWhite"] as? Bool) ?? isWhite
    let sleeping = (args["isSleeping"] as? Bool) ?? (speed <= 0)
    let active = (args["activeCount"] as? Int) ?? activeCount
    let total = (args["todayTotalCount"] as? Int) ?? todayTotalCount

    var parsedTasks: [MenuTaskItem] = []
    if let tasksJson = args["tasksJson"] as? String,
       let data = tasksJson.data(using: .utf8),
       let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
      for item in list {
        if let id = item["id"] as? String,
           let title = item["title"] as? String, !title.isEmpty {
          let completed = (item["completed"] as? Bool) ?? false
          let priority = (item["priority"] as? String) ?? "medium"
          parsedTasks.append(MenuTaskItem(id: id, title: title, completed: completed, priority: priority))
        }
      }
    }

    // Sort incomplete tasks to top
    parsedTasks.sort { (t1, t2) -> Bool in
      if t1.completed != t2.completed {
        return !t1.completed && t2.completed
      }
      return false
    }

    let visualChanged = (runner != currentRunner || catWhite != isWhite || sleeping != isSleeping)
    let speedChanged = (speed != speedPercent)

    self.currentRunner = runner
    self.isWhite = catWhite
    self.isSleeping = sleeping
    self.speedPercent = speed
    self.speedMessage = msg
    self.activeCount = active
    self.todayTotalCount = total
    self.taskItems = parsedTasks

    if visualChanged {
      reloadFrames()
      restartTimer()
    } else if speedChanged {
      restartTimer()
    }

    if popover.isShown {
      popoverController?.update(tasks: taskItems, activeCount: activeCount, runner: currentRunner)
    }
  }

  // MARK: - Popover & Status Item Handlers
  @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
    let event = NSApp.currentEvent
    if event?.type == .rightMouseUp {
      showContextMenu()
      return
    }

    if popover.isShown {
      closePopover()
      return
    }

    // Prevent immediate re-opening on transient dismiss click
    if Date().timeIntervalSince(lastClosedTime) < 0.20 {
      return
    }

    showPopover(sender)
  }

  private func showPopover(_ sender: NSStatusBarButton) {
    popoverController?.update(tasks: taskItems, activeCount: activeCount, runner: currentRunner)
    popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    popover.contentViewController?.view.window?.makeKey()
  }

  func closePopover() {
    popover.performClose(nil)
  }

  func popoverDidClose(_ notification: Notification) {
    lastClosedTime = Date()
  }

  private func showContextMenu() {
    let menu = NSMenu()
    let openItem = NSMenuItem(title: "Open TodoCat", action: #selector(openAppWindow), keyEquivalent: "o")
    openItem.target = self
    menu.addItem(openItem)
    menu.addItem(NSMenuItem.separator())
    let quitItem = NSMenuItem(title: "Quit TodoCat", action: #selector(quitApp), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)
    menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
  }

  // MARK: - Task Actions
  func toggleTask(id: String, completed: Bool) {
    if let idx = taskItems.firstIndex(where: { $0.id == id }) {
      taskItems[idx].completed = completed
      if completed {
        activeCount = max(0, activeCount - 1)
      } else {
        activeCount += 1
      }
    }
    popoverController?.update(tasks: taskItems, activeCount: activeCount, runner: currentRunner)
    channel?.invokeMethod("onTaskToggledFromMenu", arguments: ["taskId": id])
  }

  func setRunnerFromMenu(_ runner: String) {
    guard runner != currentRunner else { return }
    self.currentRunner = runner
    channel?.invokeMethod("onRunnerSelectedFromMenu", arguments: ["runner": runner])
    reloadFrames()
    restartTimer()
    popoverController?.update(tasks: taskItems, activeCount: activeCount, runner: currentRunner)
  }

  // MARK: - Sprites & Animations
  private func reloadFrames() {
    let folder = isWhite ? "\(currentRunner)_white" : currentRunner
    let state = isSleeping ? "sleep" : "run"

    if folder == cachedFolder && state == cachedState && !cachedFrames.isEmpty {
      return
    }

    let count: Int
    if currentRunner == "bunny" {
      count = 5
    } else {
      count = isSleeping ? 6 : 7
    }

    var loaded: [NSImage] = []
    for i in 0..<count {
      let relativePath = "assets/runners/\(folder)/\(state)/\(i).png"
      if let image = loadResizedImage(relativePath: relativePath) {
        loaded.append(image)
      }
    }

    // Fallback if white variant is missing for some frame
    if loaded.isEmpty && isWhite {
      for i in 0..<count {
        let fallbackPath = "assets/runners/\(currentRunner)/\(state)/\(i).png"
        if let image = loadResizedImage(relativePath: fallbackPath) {
          loaded.append(image)
        }
      }
    }

    cachedFolder = folder
    cachedState = state
    cachedFrames = loaded
    currentFrameIndex = 0

    if let first = loaded.first {
      statusItem?.button?.title = ""
      statusItem?.button?.image = first
      statusItem?.button?.imagePosition = .imageOnly
    } else {
      statusItem?.button?.image = nil
      statusItem?.button?.title = "TodoCat"
      statusItem?.button?.imagePosition = .noImage
    }
  }

  private func loadResizedImage(relativePath: String) -> NSImage? {
    guard let path = resolveAssetPath(relativePath) else { return nil }
    guard let img = NSImage(contentsOfFile: path) else { return nil }

    let targetSize = NSSize(width: 28, height: 28)
    img.size = targetSize
    img.isTemplate = false
    return img
  }

  private func resolveAssetPath(_ relativePath: String) -> String? {
    let key = FlutterDartProject.lookupKey(forAsset: relativePath)

    // 1. Direct path inside app bundle using lookup key
    let directAppPath = Bundle.main.bundleURL.appendingPathComponent(key).path
    if FileManager.default.fileExists(atPath: directAppPath) {
      return directAppPath
    }

    // 2. Direct inside app bundle with relativePath
    let appFlutterAssetsPath = Bundle.main.bundleURL
      .appendingPathComponent("Contents/Frameworks/App.framework/Resources/flutter_assets")
      .appendingPathComponent(relativePath).path
    if FileManager.default.fileExists(atPath: appFlutterAssetsPath) {
      return appFlutterAssetsPath
    }

    // 3. Bundle.main
    if let path = Bundle.main.path(forResource: key, ofType: nil) {
      return path
    }

    // 4. Resource URL
    if let resURL = Bundle.main.resourceURL {
      let candidate = resURL.appendingPathComponent(key).path
      if FileManager.default.fileExists(atPath: candidate) {
        return candidate
      }
      let candidateRelative = resURL.appendingPathComponent(relativePath).path
      if FileManager.default.fileExists(atPath: candidateRelative) {
        return candidateRelative
      }
    }

    // 5. Bundle resource path direct
    if let resPath = Bundle.main.resourcePath {
      let candidate = (resPath as NSString).appendingPathComponent(key)
      if FileManager.default.fileExists(atPath: candidate) {
        return candidate
      }
      let candidate2 = (resPath as NSString).appendingPathComponent(relativePath)
      if FileManager.default.fileExists(atPath: candidate2) {
        return candidate2
      }
    }

    // 6. Development environment fallback
    if let devPath = ProcessInfo.processInfo.environment["FLUTTER_APPLICATION_PATH"] {
      let candidate = (devPath as NSString).appendingPathComponent(relativePath)
      if FileManager.default.fileExists(atPath: candidate) {
        return candidate
      }
    }

    return nil
  }

  private func computeTimerInterval() -> TimeInterval {
    let frameCount: Double
    if currentRunner == "bunny" {
      frameCount = 5.0
    } else {
      frameCount = isSleeping ? 6.0 : 7.0
    }

    if isSleeping {
      return 1.80 / frameCount
    }

    let speed = speedPercent <= 0 ? 15 : speedPercent
    let clamped = max(1, min(100, speed))
    let durationSec = max(0.25, min(2.40, 2.40 - (Double(clamped) / 100.0) * 2.15))
    return max(0.025, durationSec / frameCount)
  }

  private func restartTimer() {
    timer?.invalidate()
    timer = nil

    guard isEnabled, !cachedFrames.isEmpty else { return }

    let interval = computeTimerInterval()
    let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
      self?.advanceFrame()
    }
    RunLoop.main.add(t, forMode: .common)
    self.timer = t
  }

  private func advanceFrame() {
    guard !cachedFrames.isEmpty else { return }
    currentFrameIndex = (currentFrameIndex + 1) % cachedFrames.count
    statusItem?.button?.image = cachedFrames[currentFrameIndex]
  }

  @objc func openAppWindow() {
    NSApp.activate(ignoringOtherApps: true)
    if let window = mainWindow ?? NSApp.windows.first(where: { $0 is MainFlutterWindow }) {
      window.makeKeyAndOrderFront(nil)
      window.orderFrontRegardless()
    }
  }

  @objc func quitApp() {
    NSApp.terminate(nil)
  }
}

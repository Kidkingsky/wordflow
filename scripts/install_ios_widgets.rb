#!/usr/bin/env ruby
# Adds a WidgetKit app extension to the temporary Flutter-created Xcode project.
require 'fileutils'
require 'xcodeproj'

root = File.expand_path('..', __dir__)
require 'yaml'

# Single source of truth for the Runner app and WidgetKit extension.
app_version_text = YAML.load_file(File.join(root, 'pubspec.yaml')).fetch('version').to_s
app_version, app_build = app_version_text.split('+', 2)
abort "Invalid pubspec version: #{app_version_text}" unless
  app_version&.match?(/\A\d+\.\d+\.\d+\z/) &&
  app_build&.match?(/\A[1-9]\d*\z/)

ios = File.join(root, 'ios')
widget_source = File.join(root, 'widgetkit')
project_path = File.join(ios, 'Runner.xcodeproj')
abort 'Run flutter create --platforms=ios first' unless File.directory?(project_path)

widget_folder = File.join(ios, 'WordFlowWidgets')
FileUtils.mkdir_p(widget_folder)
FileUtils.cp(File.join(widget_source, 'WordFlowWidgets.swift'), widget_folder)
FileUtils.cp(File.join(widget_source, 'Info.plist'), widget_folder)
FileUtils.cp(File.join(root, 'assets/content/content.json'), File.join(widget_folder, 'content.json'))
FileUtils.cp(File.join(widget_source, 'WordFlowLiveAttributes.swift'), File.join(widget_folder, 'WordFlowLiveAttributes.swift'))
FileUtils.cp(File.join(root, 'ios_native', 'WordFlowLiveActivityBridge.swift'), File.join(ios, 'Runner', 'WordFlowLiveActivityBridge.swift'))

# Experiment: both Runner and WidgetKit request the SAME App Groups entitlement.
FileUtils.cp(File.join(root, 'ios_native', 'WordFlowWidgetSyncBridge.swift'),
             File.join(ios, 'Runner', 'WordFlowWidgetSyncBridge.swift'))
app_group_entitlements = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>com.apple.security.application-groups</key>
    <array><string>group.com.kidkingsky.wordflow</string></array>
  </dict>
  </plist>
XML
File.write(File.join(ios, 'Runner', 'WordFlowAppGroups.entitlements'),
           app_group_entitlements)
File.write(File.join(widget_folder, 'WordFlowAppGroups.entitlements'),
           app_group_entitlements)


# Flutter 3.41+ uses UIScene; the UIApplicationDelegate window is nil on launch.
# Register native channels in the implicit engine callback, not didFinishLaunching.
app_delegate = File.join(ios, 'Runner', 'AppDelegate.swift')
File.write(app_delegate, <<~SWIFT)
  import Flutter
  import UIKit

  @main
  @objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
      override func application(
          _ application: UIApplication,
          didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
      ) -> Bool {
          return super.application(application, didFinishLaunchingWithOptions: launchOptions)
      }

      func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
          GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
          WordFlowLiveActivityBridge.register(messenger: engineBridge.applicationRegistrar.messenger())
          WordFlowWidgetSyncBridge.register(messenger: engineBridge.applicationRegistrar.messenger())
      }
  }
SWIFT


project = Xcodeproj::Project.open(project_path)
runner = project.targets.find { |target| target.name == 'Runner' }
abort 'Missing Runner target' unless runner
unless project.targets.any? { |target| target.name == 'WordFlowWidgets' }
  widget = project.new_target(:app_extension, 'WordFlowWidgets', :ios, '17.0')
  group = project.main_group.new_group('WordFlowWidgets', 'WordFlowWidgets')
  swift_file = group.new_file('WordFlowWidgets.swift')
  attributes_file = group.new_file('WordFlowLiveAttributes.swift')
  json_file = group.new_file('content.json')
  group.new_file('Info.plist')
  widget.add_file_references([swift_file, attributes_file])
  bridge_file = project.main_group.new_file('Runner/WordFlowLiveActivityBridge.swift')
  sync_bridge_file = project.main_group.new_file('Runner/WordFlowWidgetSyncBridge.swift')
  runner.add_file_references([bridge_file, sync_bridge_file, attributes_file])

  resource = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  resource.file_ref = json_file
  widget.resources_build_phase.files << resource

  widget.build_configurations.each do |config|
    config.build_settings.merge!(
      'SWIFT_VERSION' => '5.0',
      'IPHONEOS_DEPLOYMENT_TARGET' => '17.0',
      'TARGETED_DEVICE_FAMILY' => '1,2',
      'PRODUCT_BUNDLE_IDENTIFIER' => 'com.kidkingsky.wordflow.WordFlowWidgets',
      'PRODUCT_NAME' => '$(TARGET_NAME)',
      'INFOPLIST_FILE' => 'WordFlowWidgets/Info.plist',
      'GENERATE_INFOPLIST_FILE' => 'NO',
      'SKIP_INSTALL' => 'YES',
      'DEFINES_MODULE' => 'YES',
      'APPLICATION_EXTENSION_API_ONLY' => 'YES',
      'CODE_SIGN_STYLE' => 'Automatic',
      'CODE_SIGN_ENTITLEMENTS' => 'WordFlowWidgets/WordFlowAppGroups.entitlements',
      'MARKETING_VERSION' => app_version,
      'CURRENT_PROJECT_VERSION' => app_build
    )
  end

  runner.add_dependency(widget)
  embed = runner.new_copy_files_build_phase('Embed App Extensions')
  embed.dst_subfolder_spec = '13'
  embed.dst_path = ''
  embedded = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  embedded.file_ref = widget.product_reference
  embedded.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  embed.files << embedded

  phases = runner.build_phases
  phases.delete(embed)
  first_script = phases.index { |phase| phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) }
  phases.insert(first_script || phases.size, embed)
end

# ActivityKit requires a capability flag in the host application's Info.plist.
app_plist_for_live = File.join(ios, 'Runner', 'Info.plist')
plist_buddy_for_live = '/usr/libexec/PlistBuddy'
if File.file?(app_plist_for_live) && File.executable?(plist_buddy_for_live)
  unless system(plist_buddy_for_live, '-c', 'Print :NSSupportsLiveActivities', app_plist_for_live, out: File::NULL, err: File::NULL)
    abort 'Cannot enable Live Activities' unless system(plist_buddy_for_live, '-c', 'Add :NSSupportsLiveActivities bool YES', app_plist_for_live)
  end
end

runner.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/WordFlowAppGroups.entitlements'
end
project.save

app_plist = File.join(ios, 'Runner', 'Info.plist')
plist_buddy = '/usr/libexec/PlistBuddy'
if File.file?(app_plist) && File.executable?(plist_buddy)
  unless system(plist_buddy, '-c', 'Print :CFBundleURLTypes', app_plist, out: File::NULL, err: File::NULL)
    [
      'Add :CFBundleURLTypes array',
      'Add :CFBundleURLTypes:0 dict',
      'Add :CFBundleURLTypes:0:CFBundleURLName string com.kidkingsky.wordflow',
      'Add :CFBundleURLTypes:0:CFBundleURLSchemes array',
      'Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string wordflow'
    ].each do |command|
      abort "Cannot register widget link: #{command}" unless system(plist_buddy, '-c', command, app_plist)
    end
  end
  # SideStore / AltStore rewrite App Group IDs when re-signing and publish the
  # new IDs here; the app and widget read this key to find the real group.
  unless system(plist_buddy, '-c', 'Print :ALTAppGroups', app_plist, out: File::NULL, err: File::NULL)
    [
      'Add :ALTAppGroups array',
      'Add :ALTAppGroups:0 string group.com.kidkingsky.wordflow'
    ].each do |command|
      abort "Cannot declare ALTAppGroups: #{command}" unless system(plist_buddy, '-c', command, app_plist)
    end
  end
end

podfile = File.join(ios, 'Podfile')
if File.file?(podfile)
  text = File.read(podfile)
  text = text.sub(/^\s*#?\s*platform :ios, ['"][0-9.]+['"]/, "platform :ios, '17.0'")
  File.write(podfile, text)
end
puts 'WordFlow WidgetKit extension installed.'

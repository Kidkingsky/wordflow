#!/usr/bin/env ruby
# Adds a WidgetKit app extension to the temporary Flutter-created Xcode project.
require 'fileutils'
require 'xcodeproj'

root = File.expand_path('..', __dir__)
ios = File.join(root, 'ios')
widget_source = File.join(root, 'widgetkit')
project_path = File.join(ios, 'Runner.xcodeproj')
abort 'Run flutter create --platforms=ios first' unless File.directory?(project_path)

widget_folder = File.join(ios, 'WordFlowWidgets')
FileUtils.mkdir_p(widget_folder)
FileUtils.cp(File.join(widget_source, 'WordFlowWidgets.swift'), widget_folder)
FileUtils.cp(File.join(widget_source, 'Info.plist'), widget_folder)
FileUtils.cp(File.join(root, 'assets/content/content.json'), File.join(widget_folder, 'content.json'))

project = Xcodeproj::Project.open(project_path)
runner = project.targets.find { |target| target.name == 'Runner' }
abort 'Missing Runner target' unless runner
unless project.targets.any? { |target| target.name == 'WordFlowWidgets' }
  widget = project.new_target(:app_extension, 'WordFlowWidgets', :ios, '17.0')
  group = project.main_group.new_group('WordFlowWidgets', 'WordFlowWidgets')
  swift_file = group.new_file('WordFlowWidgets.swift')
  json_file = group.new_file('content.json')
  group.new_file('Info.plist')
  widget.add_file_references([swift_file])

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
      'MARKETING_VERSION' => '0.2.0',
      'CURRENT_PROJECT_VERSION' => '2'
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

runner.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
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
end

podfile = File.join(ios, 'Podfile')
if File.file?(podfile)
  text = File.read(podfile)
  text = text.sub(/^\s*#?\s*platform :ios, ['"][0-9.]+['"]/, "platform :ios, '17.0'")
  File.write(podfile, text)
end
puts 'WordFlow WidgetKit extension installed.'

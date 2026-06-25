require 'xcodeproj'

# Support running from either the repository root or the 'ios' directory
project_path = 'ios/Runner.xcodeproj'
if !File.exist?(project_path) && File.exist?('Runner.xcodeproj')
  project_path = 'Runner.xcodeproj'
end

unless File.exist?(project_path)
  puts "Error: Runner.xcodeproj not found at #{project_path}."
  exit 1
end

project = Xcodeproj::Project.open(project_path)

target_name = 'DeviceActivityMonitor'
existing_target = project.targets.find { |t| t.name == target_name }

if existing_target
  puts "Target '#{target_name}' already exists in Xcode project. Updating build settings..."
  existing_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_NAME'] = 'DeviceActivityMonitor'
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.aasoft.lockapp.DeviceActivityMonitor'
    config.build_settings['INFOPLIST_FILE'] = 'DeviceActivityMonitor/Info.plist'
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'DeviceActivityMonitor/DeviceActivityMonitor.entitlements'
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
    config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
  end
  project.save
  puts "Xcode project target build settings updated successfully."
else
  puts "Creating target '#{target_name}' using project at #{project_path}..."
  # Create the App Extension target (iOS 16.0 is required for Device Activity)
  ext_target = project.new_target(:app_extension, target_name, :ios, '16.0')
  
  # Configure build settings for all build configurations
  ext_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_NAME'] = 'DeviceActivityMonitor'
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.aasoft.lockapp.DeviceActivityMonitor'
    config.build_settings['INFOPLIST_FILE'] = 'DeviceActivityMonitor/Info.plist'
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'DeviceActivityMonitor/DeviceActivityMonitor.entitlements'
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
    config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
  end
  
  # Create a project group for the extension files
  group = project.main_group.find_subpath(target_name, true)
  
  # Add references to the files in the project directory
  swift_ref = group.new_reference('DeviceActivityMonitor/DeviceActivityMonitor.swift')
  entitlements_ref = group.new_reference('DeviceActivityMonitor/DeviceActivityMonitor.entitlements')
  plist_ref = group.new_reference('DeviceActivityMonitor/Info.plist')
  
  # Add DeviceActivityMonitor.swift to the compile sources build phase of the extension
  ext_target.add_file_references([swift_ref])
  
  # Find the main Runner target
  main_target = project.targets.find { |t| t.name == 'Runner' }
  if main_target
    # 1. Add extension target as a dependency of the main Runner target
    puts "Adding target dependency to Runner..."
    dependency = project.new(Xcodeproj::Project::Object::PBXTargetDependency)
    dependency.target = ext_target
    dependency.name = target_name
    main_target.dependencies << dependency
    
    # 2. Add the extension target's product to the "Embed App Extensions" Copy Files phase
    puts "Embedding app extension in Runner..."
    embed_phase = main_target.copy_files_build_phases.find do |p| 
      p.name == 'Embed App Extensions' || p.dst_subfolder_spec.to_s == '13'
    end
    
    unless embed_phase
      embed_phase = main_target.new_copy_files_build_phase('Embed App Extensions')
      embed_phase.dst_subfolder_spec = '13' # Spec 13 is App Extensions
    end
    
    build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.file_ref = ext_target.product_reference
    embed_phase.files << build_file
    
    puts "Extension target successfully linked to Runner target."
  else
    puts "Warning: Main target 'Runner' not found."
  end
  
  # Save the modified Xcode project file
  project.save
  puts "Xcode project configured and saved successfully."
end

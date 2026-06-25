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

ext_target = nil

if existing_target
  puts "Target '#{target_name}' already exists in Xcode project. Updating build settings..."
  ext_target = existing_target
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
end

# Find the main Runner target
main_target = project.targets.find { |t| t.name == 'Runner' }
if main_target
  # 1. Add extension target as a dependency of the main Runner target if not already added
  has_dependency = main_target.dependencies.any? { |d| d.target&.name == target_name }
  unless has_dependency
    puts "Adding target dependency to Runner..."
    dependency = project.new(Xcodeproj::Project::Object::PBXTargetDependency)
    dependency.target = ext_target
    dependency.name = target_name
    main_target.dependencies << dependency
  end
  
  # 2. Add the extension target's product to the "Embed App Extensions" Copy Files phase
  embed_phase = main_target.copy_files_build_phases.find do |p| 
    (p.respond_to?(:name) && p.name == 'Embed App Extensions') || (p.respond_to?(:dst_subfolder_spec) && p.dst_subfolder_spec.to_s == '13')
  end
  
  unless embed_phase
    puts "Creating Embed App Extensions copy phase..."
    embed_phase = main_target.new_copy_files_build_phase('Embed App Extensions')
    embed_phase.dst_subfolder_spec = '13' # Spec 13 is App Extensions
  end
  
  # Add the product file reference to the copy phase if not already present
  has_file = embed_phase.files.any? { |f| f.file_ref&.name == ext_target.product_reference.name }
  unless has_file
    puts "Embedding app extension in Runner..."
    build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.file_ref = ext_target.product_reference
    embed_phase.files << build_file
  end
  
  # 3. Ensure proper order of build phases to prevent Xcode 15+ dependency cycles
  thin_binary_index = main_target.build_phases.index do |p| 
    (p.respond_to?(:name) && p.name == 'Thin Binary') || (p.respond_to?(:shell_script) && p.shell_script&.include?('xcode_backend.sh embed_and_thin'))
  end
  embed_phase_index = main_target.build_phases.index do |p| 
    (p.respond_to?(:name) && p.name == 'Embed App Extensions') || (p.respond_to?(:dst_subfolder_spec) && p.dst_subfolder_spec.to_s == '13')
  end
  
  if thin_binary_index && embed_phase_index && embed_phase_index > thin_binary_index
    puts "Fixing build phase order to prevent dependency cycles..."
    phase = main_target.build_phases.delete_at(embed_phase_index)
    main_target.build_phases.insert(thin_binary_index, phase)
    puts "Reordered Build Phases: Moved 'Embed App Extensions' before 'Thin Binary'."
  end
  
  puts "Extension target successfully linked to Runner target."
else
  puts "Warning: Main target 'Runner' not found."
end

# Save the modified Xcode project file
project.save
puts "Xcode project configured and saved successfully."

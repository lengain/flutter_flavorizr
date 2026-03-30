require 'xcodeproj'
require 'json'
require 'base64'

# Xcode (newer versions) can serialize `shellScript` as an Array in
# `project.pbxproj`, while xcodeproj expects a String. Coerce to String to
# avoid runtime errors when opening the project.
begin
  if defined?(Xcodeproj::Project::ObjectAttributes)
    mod = Xcodeproj::Project::ObjectAttributes
    mod.module_eval do
      unless method_defined?(:__flavorizr_validate_value)
        alias_method :__flavorizr_validate_value, :validate_value

        def validate_value(attribute, value)
          if attribute.respond_to?(:name) &&
             attribute.name.to_s == 'shellScript' &&
             value.is_a?(Array)
            value = value.join("\n")
          end
          __flavorizr_validate_value(attribute, value)
        end
      end
    end
  end
rescue StandardError
  # Best-effort patch; keep scripts working even if xcodeproj internals change.
end

if ARGV.length != 5
  puts 'We need exactly five arguments'
  exit
end

project_path = ARGV[0]
file_path = ARGV[1]
flavor = ARGV[2]
mode = ARGV[3]
additional_build_settings = JSON.parse(Base64.decode64(ARGV[4]))

project = Xcodeproj::Project.open(project_path)
config_name = "#{mode}-#{flavor}"
config_mode = mode.downcase == 'debug' ? :debug : :release
file_ref = project.files.detect { |file| file.path == file_path }

# Build configuration list for PBXNativeTarget "Runner"
native_target = project.native_targets.first
target_config = native_target.add_build_configuration(config_name, config_mode)
target_config.base_configuration_reference = file_ref
target_config.build_settings = {
  'PRODUCT_NAME' => '$(TARGET_NAME)',
}

# Build configuration list for PBXProject "Runner"
base_config = project.build_configuration_list.build_configurations.detect { |config| config.name == mode }
build_config = project.add_build_configuration(config_name, config_mode)
build_config.base_configuration_reference = file_ref
build_config.build_settings = base_config.build_settings.clone
build_config.build_settings = build_config.build_settings.merge(additional_build_settings)

project.save
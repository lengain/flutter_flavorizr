require 'xcodeproj'

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

if ARGV.length != 2
  puts 'We need exactly two arguments'
  exit
end

project_path = ARGV[0]
scheme_name = ARGV[1]

project = Xcodeproj::Project.open(project_path)
target = project.targets.first

scheme = Xcodeproj::XCScheme.new
scheme.launch_action.build_configuration = "Debug-#{scheme_name}"
scheme.set_launch_target(target)
scheme.test_action.build_configuration = "Debug-#{scheme_name}"
scheme.profile_action.build_configuration = "Profile-#{scheme_name}"
scheme.analyze_action.build_configuration = "Debug-#{scheme_name}"
scheme.archive_action.build_configuration = "Release-#{scheme_name}"
scheme.save_as(project_path, scheme_name)

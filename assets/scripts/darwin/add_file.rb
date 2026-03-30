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

if ARGV.length < 2 || ARGV.length > 3
  puts 'Wrong number of arguments arguments'
  exit
end

project_path = ARGV[0]
file_path = ARGV[1]
group_name = ARGV.length == 3 ? ARGV[2] : nil

project = Xcodeproj::Project.open(project_path)
group = group_name.nil? ? project.main_group : project.groups.detect { |group| group.name == group_name }

file = group.find_file_by_path(file_path)
if file.nil?
  file = group.new_reference(ARGV[1])
  project.targets[0].resources_build_phase.add_file_reference(file)
  project.save
end

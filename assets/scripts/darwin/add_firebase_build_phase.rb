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
file_path = ARGV[1]

content = File.read(file_path)

project = Xcodeproj::Project.open(project_path)
target = project.targets.first

target.shell_script_build_phases
      .select { |phase| phase.name == 'Firebase Setup' }
      .each { |phase| target.build_phases.delete(phase) }

phase = target.new_shell_script_build_phase('Firebase Setup')
phase.shell_path = '/bin/sh'
phase.shell_script = content
phase.run_only_for_deployment_postprocessing = '0'
phase.output_paths.append('$(SRCROOT)/Runner/GoogleService-Info.plist')

target.build_phases.rotate!(-1)

project.save
